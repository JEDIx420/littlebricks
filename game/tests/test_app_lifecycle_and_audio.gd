extends SceneTree

## Dedicated regression suite for Application Lifecycle, Session Routing & Audio (LB-034, LB-035, LB-039).

const AppRootScene = preload("res://client/scenes/app_root.tscn")
const SessionManager = preload("res://core/session_manager.gd")
const SaveManager = preload("res://core/save_manager.gd")
const WelcomeScreen = preload("res://client/scripts/welcome_screen.gd")
const ModeSelectScreen = preload("res://client/scripts/mode_select.gd")
const SetupScreen = preload("res://client/scripts/setup_screen.gd")
const ExplorationController = preload("res://client/scripts/exploration_controller.gd")

var _failed := false

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	print("--- Running LittleBricks Application Lifecycle & Audio Suite (LB-034/LB-035/LB-039) ---")
	
	var app_root = AppRootScene.instantiate()
	root.add_child(app_root)
	
	# =========================================================================
	# Test Group 1: Startup & Welcome Screen (LB-035)
	# =========================================================================
	print("\n[Group 1: Startup & Welcome Screen]")
	assert_true(app_root.current_view is WelcomeScreen, "Initial screen must be WelcomeScreen")
	var welcome = app_root.current_view as WelcomeScreen
	assert_true(welcome.btn_play != null and welcome.btn_play.visible, "Play button must be visible")
	print("PASS: Startup loads WelcomeScreen cleanly.")
	
	# =========================================================================
	# Test Group 2: AudioDirector & Assets (LB-039)
	# =========================================================================
	print("\n[Group 2: AudioDirector & Audio Assets]")
	var audio = app_root.audio
	assert_true(audio != null, "AudioDirector must be initialized")
	assert_true(audio.SOUNDS["music_menu"] is AudioStreamOggVorbis, "Welcome score must load")
	assert_true(audio.SOUNDS["music_building"] is AudioStreamOggVorbis, "Building score must load")
	assert_true(not audio.has_node("AmbiencePlayer"), "The workshop has no environment sound loop")
	
	# Test playback triggers
	audio.play_click("test_evt_1")
	audio.play_click("test_evt_1") # Duplicate test
	audio.play_pickup()
	audio.play_rotate()
	audio.play_reject()
	audio.play_chime()
	audio.play_menu_music()
	print("PASS: Music and brick effects load and play without an environment loop.")
	
	# =========================================================================
	# Test Group 3: Navigation Flow (Welcome -> Mode -> Setup -> Table)
	# =========================================================================
	print("\n[Group 3: Screen Navigation Flow]")
	
	# 1. Welcome -> Play -> ModeSelect
	welcome.play_pressed.emit()
	assert_true(app_root.current_view is ModeSelectScreen, "Must navigate to ModeSelectScreen")
	var mode_view = app_root.current_view as ModeSelectScreen
	
	# 2. ModeSelect -> Back -> Welcome
	mode_view.back_pressed.emit()
	assert_true(app_root.current_view is WelcomeScreen, "Back from ModeSelect must return to WelcomeScreen")
	
	# 3. Welcome -> Play -> ModeSelect -> Solo -> SetupScreen
	(app_root.current_view as WelcomeScreen).play_pressed.emit()
	mode_view = app_root.current_view as ModeSelectScreen
	mode_view.mode_selected.emit("solo")
	assert_true(app_root.current_view is SetupScreen, "Must navigate to SetupScreen for Solo")
	var setup_view = app_root.current_view as SetupScreen
	assert_eq(setup_view.current_mode, "solo", "SetupScreen configured for solo")
	
	# 4. Setup -> Start Building -> Tabletop
	setup_view.start_session_requested.emit({
		"mode": "solo",
		"theme_id": "harbour",
		"creation_name": "Test Castle",
		"players": ["SoloBuilder"],
		"timer_enabled": false
	})
	
	assert_true(app_root.active_session != null, "Active session must be created")
	assert_eq(app_root.active_session.theme_id, "harbour", "Session theme must match setup")
	assert_eq(app_root.active_session.players.size(), 1, "Solo session must have 1 player")
	print("PASS: Navigation from Welcome -> Mode -> Setup -> Tabletop succeeds.")
	
	# =========================================================================
	# Test Group 4: In-Game Building, Exploration, and Return
	# =========================================================================
	print("\n[Group 4: In-Game Tabletop, Exploration, and Return]")
	var table = app_root.current_view
	assert_true(table != null, "Tabletop scene must be instantiated")
	
	# Commit a placement on the table
	table.current_grid_pos = Vector2i(8, 8)
	table.current_layer_plate = 0
	table._validate_and_update_ghost()
	table._on_place_pressed()
	assert_eq(table.placed_pieces_data.size(), 1, "One piece placed on table")
	assert_eq(app_root.active_session.placements.size(), 1, "Session recorded placement")
	
	# Finish opens the showcase. The Explore button enters the build.
	table.btn_finish.pressed.emit()
	var showcase := table.find_child("ShowcaseOverlay", true, false) as ShowcaseOverlay
	if showcase == null:
		push_error("Finish must open the showcase")
		quit(1)
		return
	assert_true(app_root.current_view == table, "The showcase stays over the finished table")
	showcase.btn_explore.pressed.emit()
	assert_true(app_root.current_view is ExplorationController, "Explore must open the exploration scene")

	# Return to Table
	(app_root.current_view as ExplorationController).return_to_table.emit(false)
	var returned_table = app_root.current_view
	assert_true(returned_table != null, "Returned to table scene")
	assert_eq(returned_table.placed_pieces_data.size(), 1, "Placements preserved on return to table")
	print("PASS: Tabletop -> Exploration -> Return to Table preserves full creation state.")
	
	# =========================================================================
	# Test Group 5: Save & Leave -> Continue Creation
	# =========================================================================
	print("\n[Group 5: Save & Leave and Continue]")
	
	# Save & Leave
	app_root.save_and_leave()
	assert_true(app_root.current_view is WelcomeScreen, "Save & Leave must return to WelcomeScreen")
	assert_true(app_root.active_session == null, "Session must be closed after leave")
	
	# Verify save file was written
	var saved_file = "user://saves/Test_Castle.json"
	assert_true(FileAccess.file_exists(saved_file), "Creation save file must exist on disk")
	
	# Test Continue
	app_root.continue_latest_save()
	assert_true(app_root.active_session != null, "Continue must restore active session")
	assert_eq(app_root.active_session.placements.size(), 1, "Continue must restore saved placements")
	var restored_table = app_root.current_view
	assert_eq(restored_table.placed_pieces_data.size(), 1, "Restored table must have 1 piece")
	print("PASS: Save & Leave successfully writes file; Continue restores exact session and table.")
	
	if not _failed:
		print("\nALL LB-034, LB-035, AND LB-039 REGRESSION CHECKS PASSED.")
	app_root.queue_free()
	await create_timer(0.15).timeout
	quit(1 if _failed else 0)

func assert_true(val: bool, msg: String) -> void:
	if not val:
		print("ASSERTION FAILED (expected true): %s" % msg)
		_failed = true

func assert_false(val: bool, msg: String) -> void:
	if val:
		print("ASSERTION FAILED (expected false): %s" % msg)
		_failed = true

func assert_eq(a, b, msg: String) -> void:
	if a != b:
		print("ASSERTION FAILED (%s != %s): %s" % [str(a), str(b), msg])
		_failed = true
