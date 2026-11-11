extends SceneTree

## Dedicated regression suite for LB-037: Finish Agreement, Exploration & Save/Resume.

const AppRootScene = preload("res://client/scenes/app_root.tscn")
const SessionManager = preload("res://core/session_manager.gd")
const SaveManager = preload("res://core/save_manager.gd")
const MainScene = preload("res://client/scenes/main.tscn")
const ExplorationController = preload("res://client/scripts/exploration_controller.gd")
const ToyExplorer = preload("res://client/scripts/toy_explorer.gd")

func _init() -> void:
	print("--- Running LittleBricks Finish, Exploration & Recovery Suite (LB-037) ---")
	
	var app_root = AppRootScene.instantiate()
	root.add_child(app_root)
	app_root._ready()
	
	# =========================================================================
	# Test Group 1: 2-Player Finish Agreement Consensus
	# =========================================================================
	print("\n[Group 1: 2-Player Unanimous Finish Agreement]")
	
	# Start 2-player pass & play session
	app_root.start_session({
		"mode": "pass_and_play",
		"theme_id": "harbour",
		"creation_name": "Agreement_Castle",
		"players": ["Alice", "Bob"],
		"timer_enabled": false
	})
	
	var session = app_root.active_session
	var table = app_root.current_view
	assert_true(session != null, "Active session exists")
	assert_eq(session.players.size(), 2, "2 players registered")
	
	# Alice places a piece from her hand
	var alice_piece = session.players[0]["hand"][0]["part_id"]
	table._select_piece_from_slot(0, alice_piece, Color.RED)
	table.current_grid_pos = Vector2i(8, 8)
	table.current_layer_plate = 0
	table._validate_and_update_ghost()
	table._on_place_pressed()
	
	# Alice votes ready to finish
	session.set_ready_to_explore("p_1", true)
	assert_eq(session.phase, SessionManager.SessionPhase.BUILDING, "Building phase persists with 1/2 ready")
	
	# Bob places a piece from his hand (should invalidate Alice's vote)
	var bob_piece = session.players[1]["hand"][0]["part_id"]
	table._select_piece_from_slot(0, bob_piece, Color.BLUE)
	table.current_grid_pos = Vector2i(16, 8)
	table.current_layer_plate = 0
	table._validate_and_update_ghost()
	table._on_place_pressed()
	
	assert_false(session.players[0]["is_ready_to_explore"], "Alice's ready vote cleared on new placement")
	assert_false(session.players[1]["is_ready_to_explore"], "Bob's ready vote cleared on new placement")
	
	# Alice places arch doorway from her hand (slot 0)
	session.players[0]["hand"][0]["part_id"] = "arch_1x4"
	table._select_piece_from_slot(0, "arch_1x4", Color.WHITE)
	table.current_grid_pos = Vector2i(12, 12)
	table.current_layer_plate = 0
	table._validate_and_update_ghost()
	table._on_place_pressed()
	
	# Both players now vote ready to finish
	session.set_ready_to_explore("p_1", true)
	session.set_ready_to_explore("p_2", true)
	assert_eq(session.phase, SessionManager.SessionPhase.EXPLORATION, "Unanimous agreement transitions to EXPLORATION")
	print("PASS: Unanimous finish agreement, 3 placements and vote invalidation on new placement verified.")
	
	# =========================================================================
	# Test Group 2: Doorway Building, Clearances & Exploration World
	# =========================================================================
	print("\n[Group 2: Doorway Building, Clearances & Exploration]")
	
	# Transition through AppRoot to Exploration (Showcase Overlay -> Explore)
	app_root._on_table_finish_requested()
	var showcase = app_root.current_view.find_child("ShowcaseOverlay", true, false)
	if showcase:
		showcase.explore_requested.emit()
	assert_true(app_root.current_view is ExplorationController, "AppRoot entered ExplorationScene")
	var exp_view = app_root.current_view as ExplorationController
	
	assert_true(exp_view.world_colliders_container.get_child_count() > 0, "Static collision hierarchy generated")
	assert_true(exp_view.visual_pieces_container.get_child_count() >= 3, "Visual brick geometry instantiated")
	assert_true(exp_view.explorer_instance != null, "ToyExplorer character spawned")
	print("PASS: Doorway construction and exploration world generated cleanly.")
	
	# =========================================================================
	# Test Group 3: Explorer POV Toggling & Spawn Reset
	# =========================================================================
	print("\n[Group 3: Explorer POV Modes & Reset Figure]")
	var explorer = exp_view.explorer_instance
	var initial_spawn = explorer.position
	
	# Default mode is 3rd person
	assert_eq(explorer.camera_mode, ToyExplorer.CameraMode.THIRD_PERSON, "Default camera mode is 3rd Person")
	
	# Toggle to 1st person
	exp_view._on_toggle_pov()
	assert_eq(explorer.camera_mode, ToyExplorer.CameraMode.FIRST_PERSON, "Camera mode toggled to 1st Person")
	
	# Toggle back to 3rd person
	exp_view._on_toggle_pov()
	assert_eq(explorer.camera_mode, ToyExplorer.CameraMode.THIRD_PERSON, "Camera mode toggled back to 3rd Person")
	
	# Move explorer and reset figure
	explorer.position += Vector3(5.0, 0.0, 5.0)
	exp_view._on_reset_figure()
	assert_true(explorer.position.distance_to(initial_spawn) < 0.1, "Reset figure restored character to safe spawn")
	print("PASS: POV toggling and Reset Figure work reliably.")
	
	# =========================================================================
	# Test Group 4: Return to Table & Revision Increment
	# =========================================================================
	print("\n[Group 4: Return to Building & Revision Increment]")
	assert_eq(session.build_revision, 1, "Initial build revision is 1")
	
	# Trigger return to table
	exp_view._on_return_to_table()
	var returned_table = app_root.current_view
	assert_true(returned_table != null, "Returned to table scene successfully")
	assert_eq(session.build_revision, 2, "Build revision bumped to 2 on return")
	assert_eq(session.phase, SessionManager.SessionPhase.BUILDING, "Session phase reset to BUILDING")
	assert_eq(returned_table.placed_pieces_data.size(), 3, "All 3 placed bricks preserved on table")
	print("PASS: Return to table increments revision and preserves all placements.")
	
	# =========================================================================
	# Test Group 5: Save, Leave, and Continue Full Journey Roundtrip
	# =========================================================================
	print("\n[Group 5: Full Journey Save, Leave & Resume]")
	
	# Save & Leave
	app_root.save_and_leave()
	assert_true(app_root.active_session == null, "Active session closed on leave")
	
	var save_file = "user://saves/Agreement_Castle.json"
	assert_true(FileAccess.file_exists(save_file), "Autosave file exists on disk")
	
	# Reopen creation via Continue
	app_root.continue_latest_save()
	assert_true(app_root.active_session != null, "Continue restored active session")
	assert_eq(app_root.active_session.placements.size(), 3, "Continue restored all 3 placements")
	assert_eq(app_root.active_session.players.size(), 2, "Continue preserved 2-player roster")
	print("PASS: Full roundtrip Save -> Leave -> Continue verified.")
	
	print("\nALL LB-037 FINISH, EXPLORATION & RECOVERY CHECKS PASSED.")
	app_root.queue_free()
	quit(0)

func assert_true(val: bool, msg: String) -> void:
	if not val:
		print("ASSERTION FAILED (expected true): %s" % msg)
		quit(1)

func assert_false(val: bool, msg: String) -> void:
	if val:
		print("ASSERTION FAILED (expected false): %s" % msg)
		quit(1)

func assert_eq(a, b, msg: String) -> void:
	if a != b:
		print("ASSERTION FAILED (%s != %s): %s" % [str(a), str(b), msg])
		quit(1)
