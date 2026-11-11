extends Node
class_name AppRoot

## Root application lifecycle controller and scene router (LB-034).
## Owns active SessionManager, persistent AudioDirector, HapticsAdapter,
## seamless screen navigation, and save/resume state across views.

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
const SettingsModalScene = preload("res://client/scenes/settings_modal.tscn")

@onready var view_container: Control = $ViewContainer

var audio: AudioDirector
var haptics: HapticsAdapter
var settings: SettingsManager
var active_session: SessionManager = null
var current_view: Node = null
var current_session_config: Dictionary = {}
var settings_dialog: SettingsModal = null

func _ready() -> void:
	if not view_container:
		view_container = get_node_or_null("ViewContainer")
		
	audio = AudioDirector.new()
	add_child(audio)
	
	haptics = HapticsAdapter.new()
	settings = SettingsManager.new()
	
	# Apply initial audio settings
	audio.set_mute(not settings.sound_enabled)
	audio.set_volumes(settings.master_volume, 0.7, 0.9, 0.5)
	
	navigate_to_welcome()

func _clear_current_view() -> void:
	if current_view:
		current_view.queue_free()
		current_view = null

func navigate_to_welcome() -> void:
	_clear_current_view()
	audio.play_menu_music()
	
	var welcome = WelcomeScene.instantiate()
	view_container.add_child(welcome)
	if not welcome.is_node_ready():
		welcome._ready()
	current_view = welcome
	
	welcome.play_pressed.connect(navigate_to_mode_select)
	welcome.continue_pressed.connect(continue_latest_save)
	welcome.my_builds_pressed.connect(open_my_builds)
	welcome.settings_pressed.connect(open_settings)
	welcome.mute_toggled.connect(func(muted): audio.set_mute(muted))

func navigate_to_mode_select() -> void:
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
	setup_view.back_pressed.connect(navigate_to_mode_select)
	setup_view.start_session_requested.connect(start_session)

func start_session(config: Dictionary) -> void:
	current_session_config = config
	var mode_str = config.get("mode", "solo")
	var g_mode = SessionManager.GameMode.SOLO_CREATIVE
	if mode_str == "pass_and_play":
		g_mode = SessionManager.GameMode.PASS_AND_PLAY
	elif mode_str == "online":
		g_mode = SessionManager.GameMode.ONLINE_ROOM
		
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
		
	_clear_current_view()
	audio.play_building_music()
	audio.set_theme_ambience(theme)
	
	# Instantiate 3D tabletop
	var table = MainTableScene.instantiate()
	add_child(table)
	current_view = table
	if not table.is_node_ready():
		table._ready()
	
	# Pass active session and audio/haptics to tabletop
	if table.has_method("attach_session"):
		table.attach_session(active_session, audio, haptics)
		
	if table.has_signal("finish_requested"):
		table.finish_requested.connect(_on_table_finish_requested)
	if table.has_signal("leave_requested"):
		table.leave_requested.connect(save_and_leave)
	if table.has_signal("settings_requested"):
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
		
	var res = SaveManager.load_from_file(newest_file)
	if not res.get("success", false):
		navigate_to_mode_select()
		return
		
	var data = res["data"]
	active_session = SessionManager.new()
	var p_names: Array[String] = []
	for pl in data.get("players", []):
		p_names.append(pl.get("name", "Player"))
	if p_names.is_empty(): p_names = ["Builder"]
	
	active_session.setup_session(
		data.get("mode", 0) as SessionManager.GameMode,
		p_names,
		data.get("theme_id", "harbour"),
		data.get("timer_enabled", false)
	)
	
	# Restore saved placements
	for p in data.get("placements", []):
		var col_hex = p.get("color_hex", "ffffff")
		active_session.placements.append({
			"placement_id": p.get("placement_id", ""),
			"sequence": p.get("sequence", 0),
			"player_id": p.get("player_id", "p0"),
			"part_id": p.get("part_id", "brick_2x4"),
			"grid_x": p.get("grid_x", 16),
			"grid_z": p.get("grid_z", 16),
			"layer_plate": p.get("layer_plate", 0),
			"rotation_step": p.get("rotation_step", 0),
			"color": Color.from_string(col_hex, Color.WHITE)
		})
		
	_clear_current_view()
	audio.play_building_music()
	audio.set_theme_ambience(active_session.theme_id)
	
	var table = MainTableScene.instantiate()
	add_child(table)
	current_view = table
	if not table.is_node_ready():
		table._ready()
	
	if table.has_method("attach_session"):
		table.attach_session(active_session, audio, haptics)
	if table.has_signal("finish_requested"):
		table.finish_requested.connect(_on_table_finish_requested)
	if table.has_signal("leave_requested"):
		table.leave_requested.connect(save_and_leave)
	if table.has_signal("settings_requested"):
		table.settings_requested.connect(open_settings)

func _on_table_finish_requested() -> void:
	if not active_session:
		return
	_clear_current_view()
	audio.play_chime()
	
	var exp_view = ExplorationScene.instantiate()
	add_child(exp_view)
	current_view = exp_view
	if not exp_view.is_node_ready():
		exp_view._ready()
	
	if exp_view.has_method("setup_exploration"):
		exp_view.setup_exploration(active_session.placements, active_session.theme_id)
	if exp_view.has_signal("return_to_table"):
		exp_view.return_to_table.connect(_on_return_to_table_requested)

func _on_return_to_table_requested(save_state: bool) -> void:
	if save_state:
		_save_active_session()
	if active_session:
		active_session.return_to_building_new_revision()
	# Restore table
	_clear_current_view()
	audio.play_building_music()
	
	var table = MainTableScene.instantiate()
	add_child(table)
	current_view = table
	if not table.is_node_ready():
		table._ready()
	
	if table.has_method("attach_session"):
		table.attach_session(active_session, audio, haptics)
	if table.has_signal("finish_requested"):
		table.finish_requested.connect(_on_table_finish_requested)
	if table.has_signal("leave_requested"):
		table.leave_requested.connect(save_and_leave)
	if table.has_signal("settings_requested"):
		table.settings_requested.connect(open_settings)

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
	SaveManager.save_to_file(data, save_path)

func open_my_builds() -> void:
	# Opens save browser / creations list
	navigate_to_mode_select()

func open_settings() -> void:
	if not settings_dialog:
		settings_dialog = SettingsModalScene.instantiate() as SettingsModal
		add_child(settings_dialog)
		settings_dialog._ready()
	settings_dialog.setup(settings, audio, haptics)
	settings_dialog.visible = true
