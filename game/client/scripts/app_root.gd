extends Node
class_name AppRoot

## Root application lifecycle controller and scene router (LB-034).
## Owns active SessionManager, persistent AudioDirector, HapticsAdapter,
## seamless screen navigation, and save/resume state across views.

const NetworkClient = preload("res://client/scripts/network_client.gd")
const AudioDirector = preload("res://client/scripts/audio_director.gd")
const HapticsAdapter = preload("res://platform/haptics_adapter.gd")
const SettingsManager = preload("res://client/scripts/settings_manager.gd")
const SettingsModal = preload("res://client/scripts/settings_modal.gd")
const SessionManager = preload("res://core/session_manager.gd")
const SaveManager = preload("res://core/save_manager.gd")

const WelcomeScene = preload("res://client/scenes/welcome_screen.tscn")
const ModeSelectScene = preload("res://client/scenes/mode_select.tscn")
const SetupScene = preload("res://client/scenes/setup_screen.tscn")
const MainTableScene = preload("res://client/scenes/main.tscn")
const ExplorationScene = preload("res://client/scenes/exploration_view.tscn")
const ExplorationController = preload("res://client/scripts/exploration_controller.gd")
const SettingsModalScene = preload("res://client/scenes/settings_modal.tscn")
const MyBuildsGalleryScene = preload("res://client/scenes/my_builds_gallery.tscn")
const ShowcaseOverlayScene = preload("res://client/scenes/showcase_overlay.tscn")
const ShowcaseOverlay = preload("res://client/scripts/showcase_overlay.gd")
const MyBuildsGallery = preload("res://client/scripts/my_builds_gallery.gd")
const ReplayTimeline = preload("res://replay/replay_timeline.gd")
const VideoExporter = preload("res://platform/video_exporter.gd")

@onready var view_container: Control = $ViewContainer

var audio: AudioDirector
var haptics: HapticsAdapter
var settings: SettingsManager
var active_session: SessionManager = null
var current_view: Node = null
var current_session_config: Dictionary = {}
var settings_dialog: SettingsModal = null
var room_connection: NetworkClient
var room_roster: Array = []
var _mobile_web := false

func _ready() -> void:
	_setup_web_touch_viewport()
	if not view_container:
		view_container = get_node_or_null("ViewContainer")
		
	audio = AudioDirector.new()
	add_child(audio)
	
	haptics = HapticsAdapter.new()
	settings = SettingsManager.new()
	settings.settings_changed.connect(_sync_motion_preference)
	_sync_motion_preference()
	
	# Apply initial audio settings
	audio.set_mute(not settings.sound_enabled)
	audio.set_volumes(settings.master_volume, settings.music_volume, settings.sfx_volume)
	
	navigate_to_welcome()

func _sync_motion_preference() -> void:
	if not is_inside_tree():
		return
	var reduced := settings.reduced_motion
	if OS.has_feature("web"):
		var value := "true" if reduced else "false"
		JavaScriptBridge.eval("try { localStorage.setItem('littlebricks-reduced-motion', '%s'); } catch {}" % value)
		reduced = reduced or bool(JavaScriptBridge.eval("matchMedia('(prefers-reduced-motion: reduce)').matches"))
	get_tree().set_meta("littlebricks_reduced_motion", reduced)

func _setup_web_touch_viewport() -> void:
	if not OS.has_feature("web"):
		return
	_mobile_web = bool(JavaScriptBridge.eval("matchMedia('(pointer: coarse)').matches"))
	if not _mobile_web:
		return
	get_window().size_changed.connect(_resize_web_touch_viewport)
	_resize_web_touch_viewport()

func _resize_web_touch_viewport() -> void:
	var width := int(JavaScriptBridge.eval("document.documentElement.clientWidth"))
	var height := int(JavaScriptBridge.eval("document.documentElement.clientHeight"))
	if width > 0 and height > 0:
		var css_size := Vector2i(width, height)
		if get_window().content_scale_size != css_size:
			get_window().content_scale_size = css_size

func _input(event: InputEvent) -> void:
	if audio and event.is_pressed() and (event is InputEventMouseButton or event is InputEventKey or event is InputEventScreenTouch):
		audio.unlock_audio()

func _clear_current_view() -> void:
	if current_view:
		current_view.queue_free()
		current_view = null

func navigate_to_welcome() -> void:
	_close_room_connection()
	_clear_current_view()
	audio.play_menu_music()
	
	var welcome = WelcomeScene.instantiate()
	view_container.add_child(welcome)
	if not welcome.is_node_ready():
		welcome._ready()
	current_view = welcome
	if welcome.has_method("set_mute_state"):
		welcome.set_mute_state(not settings.sound_enabled)
	
	welcome.play_pressed.connect(navigate_to_mode_select)
	welcome.continue_pressed.connect(continue_latest_save)
	welcome.my_builds_pressed.connect(open_my_builds)
	welcome.settings_pressed.connect(open_settings)
	welcome.mute_toggled.connect(func(muted):
		audio.set_mute(muted)
		settings.set_sound_enabled(not muted)
	)

func navigate_to_mode_select() -> void:
	_close_room_connection()
	_clear_current_view()
	var mode_view = ModeSelectScene.instantiate()
	view_container.add_child(mode_view)
	if not mode_view.is_node_ready():
		mode_view._ready()
	current_view = mode_view
	
	mode_view.back_pressed.connect(navigate_to_welcome)
	mode_view.mode_selected.connect(navigate_to_setup)

func navigate_to_setup(mode: String) -> void:
	_clear_current_view()
	var setup_view = SetupScene.instantiate()
	view_container.add_child(setup_view)
	if not setup_view.is_node_ready():
		setup_view._ready()
	current_view = setup_view
	
	setup_view.configure_for_mode(mode)
	if mode == "online":
		setup_view.configure_online_endpoint(_default_room_endpoint())
		setup_view.online_ready_requested.connect(_vote_room_ready)
	setup_view.back_pressed.connect(navigate_to_mode_select)
	setup_view.start_session_requested.connect(start_session)

func start_session(config: Dictionary) -> void:
	if config.get("mode") == "online":
		_connect_room(config)
		return
	_close_room_connection()
	current_session_config = config
	var mode_str = config.get("mode", "solo")
	var is_free_build = config.get("free_build", false) or mode_str == "solo_creative"
	var g_mode = SessionManager.GameMode.SOLO_CHALLENGE
	if mode_str == "solo" or mode_str == "solo_creative":
		if is_free_build:
			g_mode = SessionManager.GameMode.SOLO_CREATIVE
		else:
			g_mode = SessionManager.GameMode.SOLO_CHALLENGE
	elif mode_str == "pass_and_play":
		g_mode = SessionManager.GameMode.PASS_AND_PLAY
		
	var p_names: Array[String] = []
	for p in config.get("players", ["Builder"]):
		p_names.append(str(p))
		
	var theme = config.get("theme_id", "harbour")
	var timer = config.get("timer_enabled", false)
	
	active_session = SessionManager.new()
	active_session.setup_session(g_mode, p_names, theme, timer)
	if config.has("timer_sec"):
		active_session.timer_duration_sec = config["timer_sec"]
		active_session.time_remaining_sec = config["timer_sec"]
		
	_open_active_table()

func _default_room_endpoint() -> String:
	var configured := str(ProjectSettings.get_setting("littlebricks/online/server_url", "")).strip_edges()
	if not configured.is_empty():
		return configured
	if OS.has_feature("web"):
		return "ws://127.0.0.1:9080" if _is_local_web_preview() else ""
	var environment_endpoint := OS.get_environment("LITTLEBRICKS_ROOM_SERVER").strip_edges()
	return environment_endpoint if not environment_endpoint.is_empty() else "ws://127.0.0.1:9080"

func _is_local_web_preview() -> bool:
	var origin := str(JavaScriptBridge.eval("location.origin"))
	return origin.begins_with("http://localhost:") or origin.begins_with("http://127.0.0.1:")

func _connect_room(config: Dictionary) -> void:
	if not current_view is SetupScreen:
		return
	_close_room_connection()
	var endpoint := str(config.get("server_url", "")).strip_edges()
	if not endpoint.begins_with("wss://") and not endpoint.begins_with("ws://"):
		current_view.show_online_error("Enter the room server address, starting with wss://.")
		return
	if OS.has_feature("web") and endpoint.begins_with("ws://") and not _is_local_web_preview():
		current_view.show_online_error("This page needs a secure room server address starting with wss://.")
		return
	current_session_config = config.duplicate()
	current_view.show_online_pending()
	var client := NetworkClient.new()
	room_connection = client
	add_child(client)
	client.connected.connect(func():
		var player_name := str(config.get("player_name", "Builder"))
		if config.get("is_host", false):
			client.create_room(player_name)
		else:
			client.join_room(str(config.get("room_code", "")), player_name, true)
	, CONNECT_ONE_SHOT)
	client.connection_failed.connect(func(_error): _room_connection_failed("Couldn't reach the room server. Check the address and try again."))
	client.join_failed.connect(func(_code, message): _room_connection_failed(message))
	client.disconnected.connect(func(): _room_connection_failed("Connection to the room server was lost."))
	client.join_succeeded.connect(_on_room_joined)
	client.roster_updated.connect(_on_room_roster)
	client.build_started.connect(_on_online_build_started)
	client.room_move_received.connect(_apply_online_move)
	client.placement_rejected.connect(func(_request_id, code, reason):
		if current_view and current_view.has_method("_on_placement_rejected"):
			current_view._on_placement_rejected(reason, code)
	)
	client.phase_updated.connect(_on_online_phase)
	var timeout := Timer.new()
	timeout.one_shot = true
	client.add_child(timeout)
	timeout.timeout.connect(func():
		if client.player_token.is_empty():
			_room_connection_failed("The room server didn't respond. Check the address and try again.")
	)
	client.join_succeeded.connect(func(_data): timeout.stop())
	timeout.start(10.0)
	client.connect_to_server(endpoint)

func _close_room_connection() -> void:
	room_roster.clear()
	if is_instance_valid(room_connection):
		var previous := room_connection
		room_connection = null
		previous.set_block_signals(true)
		previous.disconnect_from_server()
		previous.queue_free()

func _room_connection_failed(message: String) -> void:
	var had_room := is_instance_valid(room_connection) and not room_connection.player_token.is_empty()
	_close_room_connection()
	if current_view is SetupScreen:
		if had_room:
			current_view.configure_for_mode("online")
		current_view.show_online_error(message)
	elif current_view and current_view.has_method("set_online_disconnected"):
		current_view.set_online_disconnected(message)

func _on_room_joined(data: Dictionary) -> void:
	var code := str(data.get("room_code", ""))
	current_session_config["room_code"] = code
	current_session_config["creation_name"] = "Private room " + code
	_on_room_roster([{"name": current_session_config.get("player_name", "Builder"), "id": room_connection.player_id}], "")

func _on_room_roster(players: Array, _current_turn: String) -> void:
	room_roster = players
	if not current_view is SetupScreen:
		if active_session and active_session.phase == SessionManager.SessionPhase.BUILDING:
			for player in players:
				if not player.get("is_online", true):
					_room_connection_failed("%s left the room. You can save the build." % player.get("name", "A player"))
					break
		return
	var ready_count := 0
	var is_ready := false
	for player in players:
		if player.get("is_ready", false):
			ready_count += 1
			if player.get("id") == room_connection.player_id:
				is_ready = true
	current_view.show_online_lobby(room_connection.current_room_code, players, ready_count, is_ready)

func _vote_room_ready(is_ready: bool) -> void:
	if is_instance_valid(room_connection):
		room_connection.vote_ready(is_ready)

func _on_online_build_started(snapshot: Dictionary) -> void:
	active_session = SessionManager.new()
	SaveManager.restore_into_session(active_session, snapshot)
	_open_active_table()

func _submit_online_placement(slot: int, x: int, z: int, layer: int, rotation: int) -> void:
	if not is_instance_valid(room_connection):
		return
	var request_id := "%s-%d" % [room_connection.player_id, Time.get_ticks_usec()]
	room_connection.submit_placement(request_id, slot, x, z, layer, rotation)

func _apply_online_move(data: Dictionary) -> void:
	var placement: Dictionary = data["placement"]
	placement["color"] = Color.from_string(data.get("color_hex", ""), Color.WHITE)
	var replacement: Dictionary = data.get("replacement", {})
	replacement["color"] = Color.from_string(replacement.get("color_hex", ""), Color.WHITE)
	for index in range(active_session.players.size()):
		var player := active_session.players[index]
		if player["id"] == placement["player_id"]:
			player["hand"][int(data["slot_idx"])] = replacement
		if player["id"] == data["next_player_id"]:
			active_session.current_player_idx = index
		player["is_ready_to_explore"] = false
	active_session.placements.append(placement)
	active_session._record_event("PLACEMENT_ACCEPTED", placement)
	active_session.placement_accepted.emit(placement)
	active_session.turn_advanced.emit(active_session.get_current_player_id(), active_session.current_player_idx)

func _on_online_phase(phase: int, ready_count: int, total_players: int) -> void:
	if active_session and current_view and current_view.has_method("set_online_ready_count"):
		current_view.set_online_ready_count(ready_count, total_players)
		if phase != active_session.phase:
			if phase == SessionManager.SessionPhase.EXPLORATION:
				active_session.transition_to_exploration()

func _open_active_table() -> void:
	_clear_current_view()
	var table = MainTableScene.instantiate()
	add_child(table)
	current_view = table
	if not table.is_node_ready():
		table._ready()

	table.attach_session(active_session, audio, haptics, settings, current_session_config.get("workshop_atmosphere", {}))
	if _mobile_web:
		table.camera_rig.frame_plate()
	if is_instance_valid(room_connection):
		table.attach_online_room(room_connection.current_room_code, room_connection.player_id)
		table.online_placement_requested.connect(_submit_online_placement)
		table.online_ready_requested.connect(_vote_room_ready)
	audio.play_building_music()
	table.finish_requested.connect(_on_table_finish_requested)
	table.leave_requested.connect(save_and_leave)
	table.settings_requested.connect(open_settings)

func continue_latest_save() -> void:
	var dir = DirAccess.open("user://saves")
	if not dir:
		navigate_to_mode_select()
		return
		
	dir.list_dir_begin()
	var filename = dir.get_next()
	var newest_time: int = 0
	var newest_file: String = ""
	while filename != "":
		if filename.ends_with(".json") and not filename.ends_with(".tmp"):
			var full_path = "user://saves/" + filename
			var mod_time = FileAccess.get_modified_time(full_path)
			if mod_time > newest_time:
				newest_time = mod_time
				newest_file = full_path
		filename = dir.get_next()
		
	if newest_file.is_empty():
		navigate_to_mode_select()
		return
		
	if not _restore_saved_build(newest_file):
		navigate_to_mode_select()

func _on_table_finish_requested() -> void:
	if not active_session:
		return

	_save_active_session()
	audio.play_chime()
	if not current_view or not current_view.has_method("_on_frame_build"):
		_open_exploration_view()
		return

	var table = current_view
	var ui_root := table.find_child("RootControl", true, false) as Control
	if not ui_root:
		_open_exploration_view()
		return

	table.camera_rig.frame_plate()
	table._on_frame_build()
	table.set_external_modal_open(true)
	var hud_visibility := {}
	for control in ui_root.get_children():
		if control is Control:
			hud_visibility[control] = control.visible
			control.hide()
	var ghost_visible: bool = table.ghost_preview.visible
	table.ghost_preview.hide()

	var showcase := ShowcaseOverlayScene.instantiate() as ShowcaseOverlay
	ui_root.add_child(showcase)
	var c_name: String = current_session_config.get("creation_name", "My Creation")
	showcase.configure_showcase(c_name, active_session.placements.size())
	if is_instance_valid(room_connection):
		var keep := showcase.find_child("BtnKeepBuilding", true, false) as Button
		if keep:
			keep.text = "Save & leave"

	showcase.explore_requested.connect(func():
		showcase.queue_free()
		_open_exploration_view()
	)
	showcase.keep_building_requested.connect(func():
		if is_instance_valid(room_connection):
			save_and_leave()
			return
		if active_session.phase != SessionManager.SessionPhase.BUILDING:
			active_session.return_to_building_new_revision()
		showcase.queue_free()
		table.camera_rig.set_default_view()
	)
	showcase.watch_build_requested.connect(_play_showcase_replay.bind(showcase))
	showcase.video_export_requested.connect(_export_showcase_video.bind(showcase))
	showcase.replay_closed.connect(_stop_showcase_replay.bind(showcase, table))
	showcase.tree_exiting.connect(func():
		if not is_instance_valid(table) or table.is_queued_for_deletion():
			return
		table.placed_bricks_container.show()
		table.ghost_preview.visible = ghost_visible
		table.camera_rig.camera.make_current()
		table.set_external_modal_open(false)
		for control in hud_visibility:
			control.visible = hud_visibility[control]
	)

func _open_exploration_view() -> void:
	_capture_workshop_atmosphere()
	_clear_current_view()
	var exp_view := ExplorationScene.instantiate() as ExplorationController
	add_child(exp_view)
	current_view = exp_view
	if not exp_view.is_node_ready():
		exp_view._ready()
	
	exp_view.setup_exploration(active_session.placements, active_session.theme_id)
	exp_view.presentation.is_reduced_motion = settings.reduced_motion
	exp_view.presentation.atmosphere_changed.connect(func(_mode: String, _label: String):
		var state := exp_view.get_atmosphere_state()
		audio.set_workshop_atmosphere(state.get("is_raining", false), state.get("is_night", false))
	)
	exp_view.restore_atmosphere_state(current_session_config.get("workshop_atmosphere", {}))
	if is_instance_valid(room_connection):
		exp_view.btn_return_table.text = "Save & leave"
		exp_view.btn_return_table.tooltip_text = "Save the build and leave the room (Esc)"
	exp_view.return_to_table.connect(_on_return_to_table_requested)

func _play_showcase_replay(showcase: ShowcaseOverlay) -> ReplayTimeline:
	if not active_session or active_session.placements.is_empty():
		return null
	var table = current_view
	_stop_showcase_replay(showcase, table)
	var timeline := ReplayTimeline.new()
	showcase.add_child(timeline)
	showcase.timeline = timeline
	timeline.load_build_history(active_session.placements)
	timeline.seconds_per_placement = minf(timeline.seconds_per_placement, 24.0 / active_session.placements.size())
	timeline.configure_camera(
		table.camera_rig.camera, table.camera_rig.target, settings.reduced_motion, table.camera_rig.room_bounds)
	timeline.step_played.connect(showcase.update_replay_progress)
	timeline.replay_completed.connect(showcase.notify_replay_finished)
	table.placed_bricks_container.hide()
	timeline.camera.make_current()
	showcase.update_replay_progress(0, active_session.placements.size())
	timeline.play_replay()
	return timeline

func _stop_showcase_replay(showcase: ShowcaseOverlay, table: Node) -> void:
	if is_instance_valid(showcase.timeline):
		showcase.timeline.hide()
		showcase.timeline.queue_free()
		showcase.timeline = null
	table.placed_bricks_container.show()
	table.camera_rig.camera.make_current()

func _export_showcase_video(showcase: ShowcaseOverlay) -> void:
	if showcase.exporting or not active_session or active_session.placements.is_empty():
		return
	if DisplayServer.get_name() == "headless":
		showcase.notify_export_finished("Open the game window to export a film.")
		return
	if OS.has_feature("android") and not Engine.has_singleton("LittleBricksMediaCodec"):
		showcase.notify_export_finished("Video export is unavailable in this Android build.")
		return
	var exporter := VideoExporter.new()
	var fps := 24
	var web := OS.has_feature("web")
	exporter.initialize(960, 540, fps)
	var c_name: String = current_session_config.get("creation_name", "build")
	var safe_name := c_name.validate_filename().strip_edges().replace(" ", "_")
	if safe_name.is_empty():
		safe_name = "build"
	var extension := "webm" if web else "mp4"
	var out_name := "user://saves/%s_film.%s" % [safe_name, extension]
	var timeline := _play_showcase_replay(showcase)
	if not timeline:
		return

	# Run one visible 3D replay. Hide the card so the exported film contains
	# the build and the room, with the same meshes and camera as playback.
	showcase.begin_export()
	timeline.set_process(false)
	await RenderingServer.frame_post_draw
	var estimated_frames := ceili((timeline.seconds_per_placement * timeline.placements_data.size() + timeline.reveal_duration_sec) * fps)
	if not exporter.start_recording(out_name, estimated_frames):
		timeline.set_process(true)
		showcase.notify_export_finished(exporter.last_error)
		return

	if web:
		timeline.set_process(true)
		while timeline.is_playing and not showcase.export_cancelled:
			await get_tree().process_frame
	else:
		while timeline.is_playing and not showcase.export_cancelled:
			timeline.advance_replay(1.0 / fps)
			await RenderingServer.frame_post_draw
			var frame := get_viewport().get_texture().get_image()
			if not frame or frame.is_empty():
				exporter.cancel_recording()
				break
			frame = _prepare_film_frame(frame, Vector2i(exporter.target_width, exporter.target_height))
			if not exporter.push_frame(frame):
				exporter.cancel_recording()
				break

	if showcase.export_cancelled:
		exporter.cancel_recording()
		_stop_showcase_replay(showcase, current_view)
		showcase.notify_export_finished("Export cancelled.")
		return
	var film_path := exporter.finish_recording()
	if film_path.is_empty():
		showcase.notify_export_finished(exporter.last_error if not exporter.last_error.is_empty() else "Could not export the film.")
	elif web:
		showcase.notify_export_finished("Your browser is saving the film.")
	else:
		showcase.notify_export_finished("Saved %s" % film_path.get_file(), ProjectSettings.globalize_path(film_path))

func _prepare_film_frame(image: Image, frame_size: Vector2i) -> Image:
	var src := image.get_size()
	var scale_factor := minf(float(src.x) / frame_size.x, float(src.y) / frame_size.y)
	var crop := Vector2i(Vector2(frame_size) * scale_factor)
	if crop != src:
		image = image.get_region(Rect2i((src - crop) / 2, crop))
	image.resize(frame_size.x, frame_size.y)
	return image

func _on_return_to_table_requested(save_state: bool) -> void:
	if is_instance_valid(room_connection):
		save_and_leave()
		return
	_capture_workshop_atmosphere()
	if save_state:
		_save_active_session()
	if active_session:
		active_session.return_to_building_new_revision()
	_open_active_table()

func save_and_leave() -> void:
	_save_active_session()
	active_session = null
	navigate_to_welcome()

func _save_active_session() -> void:
	if not active_session:
		return
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("saves"):
		dir.make_dir("saves")
		
	var creation_name = current_session_config.get("creation_name", "Creation")
	var safe_name = creation_name.validate_filename().replace(" ", "_")
	var save_path = "user://saves/%s.json" % safe_name
	
	var data = SaveManager.serialize_session(active_session)
	data["creation_name"] = creation_name
	if active_session.mode == SessionManager.GameMode.ONLINE_ROOM:
		data["mode"] = SessionManager.GameMode.SOLO_CREATIVE
		data["phase"] = SessionManager.SessionPhase.BUILDING
		data["players"] = data["players"].slice(0, 1)
		data["current_player_idx"] = 0
	_capture_workshop_atmosphere()
	data["workshop_atmosphere"] = current_session_config.get("workshop_atmosphere", {})
	SaveManager.save_to_file(data, save_path)

func _capture_workshop_atmosphere() -> void:
	if not is_instance_valid(current_view):
		return
	if current_view.has_method("get_workshop_state"):
		current_session_config["workshop_atmosphere"] = current_view.get_workshop_state()
	elif current_view.has_method("get_atmosphere_state"):
		current_session_config["workshop_atmosphere"] = current_view.get_atmosphere_state()

func open_my_builds() -> void:
	# Opens creation library gallery (LB-064)
	_clear_current_view()
	var gallery = MyBuildsGalleryScene.instantiate() as MyBuildsGallery
	view_container.add_child(gallery)
	if not gallery.is_node_ready():
		gallery._ready()
	current_view = gallery
	
	gallery.back_pressed.connect(navigate_to_welcome)
	gallery.start_new_build_requested.connect(navigate_to_mode_select)
	gallery.open_creation_requested.connect(load_specific_save)

func load_specific_save(file_path: String) -> void:
	if not _restore_saved_build(file_path):
		open_my_builds()

func _restore_saved_build(file_path: String) -> bool:
	var result := SaveManager.load_from_file(file_path)
	if not result.get("success", false):
		return false
	var data: Dictionary = result["data"]
	var names: Array[String] = []
	for player in data.get("players", []):
		names.append(player.get("name", "Builder"))
	if names.is_empty():
		return false
	var creation_name: String = data.get("creation_name", file_path.get_file().get_basename().replace("_", " "))
	var theme: String = data.get("theme_id", "harbour")
	current_session_config = {"creation_name": creation_name, "theme_id": theme}
	active_session = SessionManager.new()
	active_session.setup_session(
		int(data.get("mode", SessionManager.GameMode.SOLO_CREATIVE)) as SessionManager.GameMode,
		names, theme, bool(data.get("timer_enabled", false))
	)
	SaveManager.restore_into_session(active_session, data)
	if active_session.phase == SessionManager.SessionPhase.EXPLORATION:
		active_session.return_to_building_new_revision()

	if data.get("workshop_atmosphere") is Dictionary:
		current_session_config["workshop_atmosphere"] = data["workshop_atmosphere"]
	_open_active_table()
	return true

func open_settings() -> void:
	if not settings_dialog:
		var layer := CanvasLayer.new()
		layer.layer = 5
		add_child(layer)
		settings_dialog = SettingsModalScene.instantiate() as SettingsModal
		layer.add_child(settings_dialog)
		settings_dialog.visibility_changed.connect(_on_settings_visibility_changed)
	settings_dialog.setup(settings, audio, haptics)
	settings_dialog.show()
	_on_settings_visibility_changed()

func _on_settings_visibility_changed() -> void:
	if is_instance_valid(current_view) and current_view.has_method("set_external_modal_open"):
		current_view.set_external_modal_open(settings_dialog.visible)
