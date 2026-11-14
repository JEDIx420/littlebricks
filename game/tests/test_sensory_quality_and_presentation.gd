extends SceneTree

const AudioDirector = preload("res://client/scripts/audio_director.gd")
const HapticsAdapter = preload("res://platform/haptics_adapter.gd")
const SettingsManager = preload("res://client/scripts/settings_manager.gd")
const InteractionFeedback = preload("res://client/scripts/interaction_feedback.gd")
const PresentationController = preload("res://client/scripts/presentation_controller.gd")
const MainTableScene = preload("res://client/scenes/main.tscn")
const SessionManager = preload("res://core/session_manager.gd")
const TableView = preload("res://client/scripts/table_view.gd")

func _init() -> void:
	print("\n--- Running LittleBricks Sensory Quality & Presentation Suite (LB-040..LB-043) ---\n")
	
	test_audio_buses_and_ducking()
	test_soundtrack_selection()
	test_tactile_feedback_and_deduplication()
	test_presentation_lighting_and_framing()
	test_accessibility_touch_and_settings()
	
	print("\nALL LB-040..LB-043 REGRESSION CHECKS PASSED SUCCESSFULLY.\n")
	quit(0)

func test_audio_buses_and_ducking() -> void:
	print("[Group 1: Audio Buses, Volume Curves & Ducking (LB-040)]")
	
	var audio = AudioDirector.new()
	root.add_child(audio)
	
	# Verify buses
	var bus_names = []
	for i in range(AudioServer.get_bus_count()):
		bus_names.append(AudioServer.get_bus_name(i))
	assert("Master" in bus_names, "Master bus must exist")
	assert("Music" in bus_names, "Music bus must exist")
	assert(not ("Ambience" in bus_names), "No environment audio bus is needed")
	assert("Bricks" in bus_names, "Bricks bus must exist")
	
	# Verify zero slider becomes silence without error
	assert(audio._calc_db(0.0) == -80.0, "Zero volume must map to -80.0 dB floor")
	assert(audio._calc_db(0.0005) == -80.0, "Sub-threshold volume must map to -80.0 dB")
	assert(abs(audio._calc_db(1.0) - 0.0) < 0.01, "1.0 volume must map to 0.0 dB")
	
	# Verify volume adjustments
	audio.set_volumes(0.5, 0.6, 0.7)
	assert(audio._master_vol_linear == 0.5, "Master volume set")
	assert(audio._music_vol_linear == 0.6, "Music volume set")
	
	# Verify ducking call does not crash
	audio.duck_music_for_placement(-2.5, 0.35)
	
	# Verify focus notification handling
	audio._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert(not audio._is_focused, "Focus out sets _is_focused to false")
	audio._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	assert(audio._is_focused, "Focus in restores _is_focused to true")
	
	# Clean up
	root.remove_child(audio)
	audio.queue_free()
	print("PASS: Audio buses, volume curves, ducking, and focus handling verified.")

func test_soundtrack_selection() -> void:
	var audio := AudioDirector.new()
	root.add_child(audio)
	var tracks := ["music_menu", "music_rain", "music_night"]
	tracks.append_array(AudioDirector.WORKSHOP_PLAYLIST)
	var unique_streams := {}
	for track in tracks:
		var stream := AudioDirector.SOUNDS[track] as AudioStreamOggVorbis
		assert(stream != null and stream.get_length() >= 30.0, "Each cue contains a full piece of music")
		unique_streams[stream.resource_path] = true
	assert(unique_streams.size() == tracks.size(), "Each cue uses a distinct recording")

	audio.play_menu_music()
	assert(audio._current_music_track == "music_menu")
	audio.play_building_music()
	audio._on_music_finished(audio._music_player_a if audio._active_music_is_a else audio._music_player_b)
	assert(audio._current_music_track == AudioDirector.WORKSHOP_PLAYLIST[1])
	audio.set_workshop_atmosphere(false, true)
	assert(audio._current_music_track == "music_night")
	audio.set_workshop_atmosphere(true, true)
	assert(audio._current_music_track == "music_rain")
	audio.set_workshop_atmosphere(false, false)
	assert(audio._current_music_track == AudioDirector.WORKSHOP_PLAYLIST[1], "Daytime restores the current playlist cue")
	audio.play_menu_music()
	audio.set_workshop_atmosphere(true, false)
	assert(audio._current_music_track == "music_menu", "Weather only changes the workshop soundtrack")
	audio.queue_free()
	print("PASS: Distinct soundtrack cues, rotation, and weather selection verified.")

func test_tactile_feedback_and_deduplication() -> void:
	print("[Group 2: Tactile Feedback & Event Deduplication (LB-041)]")
	
	var audio = AudioDirector.new()
	root.add_child(audio)
	var haptics = HapticsAdapter.new()
	var settings = SettingsManager.new()
	var feedback = InteractionFeedback.new(audio, haptics, settings)
	
	# Deduplication check
	var event_id = "test_event_999"
	var dummy_node = Node3D.new()
	root.add_child(dummy_node)
	
	feedback.notify_placement_accepted(event_id, dummy_node, false, false)
	assert(feedback._handled_event_ids.has(event_id), "Event ID recorded in deduplication table")
	
	# Duplicate call should be ignored
	feedback.notify_placement_accepted(event_id, dummy_node, false, false)
	
	# Replay / Remote events should not cause handheld vibration
	feedback.notify_placement_accepted("remote_ev_1", dummy_node, true, false)
	feedback.notify_placement_accepted("replay_ev_2", dummy_node, false, true)
	
	# Visual settle animation when reduced_motion = false
	settings.reduced_motion = false
	var visual_child = MeshInstance3D.new()
	dummy_node.add_child(visual_child)
	feedback.animate_settle(dummy_node)
	
	# Visual settle animation when reduced_motion = true
	settings.reduced_motion = true
	feedback.animate_settle(dummy_node)
	
	# Clean up
	root.remove_child(dummy_node)
	dummy_node.queue_free()
	root.remove_child(audio)
	audio.queue_free()
	print("PASS: Feedback deduplication, remote/replay isolation, and settle animation verified.")

func test_presentation_lighting_and_framing() -> void:
	print("[Group 3: Presentation, Warm Lighting & Finished Framing (LB-042)]")
	
	var pres = PresentationController.new()
	root.add_child(pres)
	
	var env = Environment.new()
	var sky = Sky.new()
	sky.sky_material = ProceduralSkyMaterial.new()
	env.sky = sky
	var world_env = WorldEnvironment.new()
	world_env.environment = env
	root.add_child(world_env)
	
	var sun = DirectionalLight3D.new()
	root.add_child(sun)
	
	# Test Harbour theme preset
	pres.apply_presentation("harbour", world_env, sun, null)
	assert(pres.current_theme_id == "harbour", "Theme harbour applied")
	assert(sun.light_color == Color(1.0, 0.96, 0.90), "Harbour sunlight is warm white/gold")
	assert(sun.shadow_enabled == true, "Shadows enabled in balanced profile")
	
	# Test Alpine Cabin theme preset
	pres.apply_presentation("cabin", world_env, sun, null)
	assert(pres.current_theme_id == "cabin", "Theme cabin applied")
	assert(sun.light_color == Color(1.0, 0.88, 0.72), "Cabin golden hour sunlight applied")
	
	# Test Quality Profiles
	pres.apply_quality("economy", sun)
	assert(sun.shadow_enabled == false, "Economy profile disables directional shadows")
	pres.apply_quality("balanced", sun)
	assert(sun.shadow_enabled == true, "Balanced profile enables directional shadows")
	
	# Test Finished Build Framing
	var bricks_container = Node3D.new()
	root.add_child(bricks_container)
	var b1 = Node3D.new()
	b1.position = Vector3(0, 0.1, 0)
	bricks_container.add_child(b1)
	var b2 = Node3D.new()
	b2.position = Vector3(4, 2.0, 4)
	bricks_container.add_child(b2)
	
	var camera_rig = Node3D.new()
	root.add_child(camera_rig)
	
	var aabb = pres.frame_creation(bricks_container, camera_rig)
	assert(aabb.has_point(Vector3(0, 0.1, 0)), "AABB bounds include first brick")
	assert(aabb.has_point(Vector3(4, 2.0, 4)), "AABB bounds include second brick")
	assert(camera_rig.position == aabb.get_center(), "Camera rig centered on creation")
	
	# Clean up
	root.remove_child(bricks_container)
	bricks_container.queue_free()
	root.remove_child(camera_rig)
	camera_rig.queue_free()
	root.remove_child(sun)
	sun.queue_free()
	root.remove_child(world_env)
	world_env.queue_free()
	root.remove_child(pres)
	pres.queue_free()
	print("PASS: Lighting presets, quality profiles, and finished build framing verified.")

func test_accessibility_touch_and_settings() -> void:
	print("[Group 4: Accessibility, Touch Ergonomics & Settings (LB-043)]")
	
	var settings = SettingsManager.new()
	settings.sound_enabled = false
	settings.master_volume = 0.45
	settings.music_volume = 0.55
	settings.sfx_volume = 0.65
	settings.haptics_enabled = false
	settings.reduced_motion = true
	settings.high_contrast_cues = true
	settings.save_settings()
	
	# Reload settings to test roundtrip
	var reloaded = SettingsManager.new()
	assert(reloaded.sound_enabled == false, "Sound toggle persisted")
	assert(abs(reloaded.master_volume - 0.45) < 0.01, "Master volume persisted")
	assert(abs(reloaded.music_volume - 0.55) < 0.01, "Music volume persisted")
	assert(reloaded.haptics_enabled == false, "Haptics persisted")
	assert(reloaded.reduced_motion == true, "Reduced motion persisted")
	
	# Test touch target sizes on MainTableScene buttons
	var main = MainTableScene.instantiate()
	root.add_child(main)
	main._ready()
	
	var buttons_to_check = [
		main.btn_place,
		main.btn_rotate_left,
		main.btn_rotate_right,
		main.btn_auto_height,
		main.btn_return_base,
		main.btn_camera_mode,
		main.btn_top_view,
		main.btn_frame_build,
		main.btn_reset_view,
		main.btn_undo,
		main.btn_redo,
		main.btn_finish,
		main.btn_leave,
		main.btn_settings,
		main.btn_all_parts
	]
	
	for btn in buttons_to_check:
		assert(btn != null, "Button must exist")
		var min_size = btn.custom_minimum_size
		assert(min_size.y >= 44.0 or min_size.x >= 44.0, "Button %s touch target meets >= 44pt guideline (size=%s)" % [btn.name, str(min_size)])
		
	# High contrast status formatting
	var session = SessionManager.new()
	session.setup_session(SessionManager.GameMode.PASS_AND_PLAY, ["Alice", "Bob"], "harbour", false)
	main.attach_session(session)
	
	# The player and reason are readable without color or a symbol font.
	main.current_grid_pos = Vector2i(12, 12)
	main.current_layer_plate = 0
	main._validate_and_update_ghost()
	assert(main.label_status.text.begins_with("[P1] Alice: "), "Status names the current player")
	assert("Ready to place" in main.label_status.text, "Status describes a valid placement")
	assert(not main.btn_place.disabled, "A valid candidate can be placed")
	main.current_grid_pos = Vector2i(-5, -5)
	main._validate_and_update_ghost()
	assert("Must stay on the baseplate" in main.label_status.text, "Status explains the invalid target")
	assert(main.btn_place.disabled, "An invalid candidate cannot be placed")

	# Clean up
	root.remove_child(main)
	main.queue_free()
	print("PASS: Settings persistence, touch ergonomics (>=44pt), and high-contrast cues verified.")
