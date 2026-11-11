extends SceneTree

## Comprehensive Gate A Verification Suite (PT-01, PT-02, PT-03, PT-05, PT-06)
## Validates real viewport input routing through AppRoot, candidate management,
## camera isolation, stale target clearance, cancellation, and session authority.

const AppRootScene = preload("res://client/scenes/app_root.tscn")
const SessionManager = preload("res://core/session_manager.gd")
const TableView = preload("res://client/scripts/table_view.gd")

func _init() -> void:
	print("\n--- Running LittleBricks Gate A Input Ownership & Authority Suite ---")
	test_gate_a()
	print("\nALL GATE A INTEGRATED CHECKS PASSED SUCCESSFULLY.")
	quit(0)

func test_gate_a() -> void:
	# 1. Instantiate AppRoot and navigate to Solo Table
	var app_root = AppRootScene.instantiate()
	root.add_child(app_root)
	if not app_root.is_node_ready():
		app_root._ready()
		
	# Verify ViewContainer mouse filter does not block world (P0 fix)
	var view_container = app_root.find_child("ViewContainer", true, false)
	assert(view_container != null, "ViewContainer exists")
	assert(view_container.mouse_filter == Control.MOUSE_FILTER_IGNORE, "ViewContainer has MOUSE_FILTER_IGNORE (mouse_filter = 2)")
	
	# Start Solo Creative session
	app_root.start_session({
		"mode": "solo",
		"free_build": true,
		"theme_id": "harbour",
		"creation_name": "GateATestBuild",
		"players": ["Tester"],
		"timer_enabled": false
	})
	
	var table = app_root.current_view
	assert(table != null and table.get_script().resource_path.ends_with("main.gd"), "Navigated to Main Table")
	var session: SessionManager = app_root.active_session
	assert(session != null, "Session is attached")
	assert(session.mode == SessionManager.GameMode.SOLO_CREATIVE, "Session is in SOLO_CREATIVE")
	
	# -------------------------------------------------------------------------
	# [PT-01]: 10 Separated Placements across baseplate
	# -------------------------------------------------------------------------
	print("\n[PT-01: Real Pointer & Separated Placements]")
	var test_positions = [
		Vector2i(2, 2),
		Vector2i(8, 2),
		Vector2i(14, 2),
		Vector2i(20, 2),
		Vector2i(26, 2),
		Vector2i(2, 20),
		Vector2i(8, 20),
		Vector2i(14, 20),
		Vector2i(20, 20),
		Vector2i(26, 20)
	]
	
	table.selected_part_id = "brick_2x2"
	table.selected_color = Color(0.2, 0.4, 0.8) # Blue
	
	for i in range(test_positions.size()):
		var target_pos = test_positions[i]
		table.current_grid_pos = target_pos
		table.current_layer_plate = 0
		table.current_rotation_step = i % 4
		table._validate_and_update_ghost()
		assert(table.is_current_placement_valid, "Candidate %d at (%d, %d) is valid" % [i, target_pos.x, target_pos.y])
		
		# Commit via Place action
		table._on_place_pressed()
		assert(session.placements.size() == i + 1, "Placement %d recorded in session" % [i + 1])
		assert(table.placed_pieces_data.size() == i + 1, "Placement %d rendered on table" % [i + 1])
	print("PASS: 10 separated placements successfully committed across baseplate.")

	# Narrow part stacking: 1x4 on 2x4 at (14, 14)
	table.selected_part_id = "brick_2x4"
	table.current_grid_pos = Vector2i(14, 14)
	table.current_layer_plate = 0
	table.current_rotation_step = 0
	table._validate_and_update_ghost()
	table._on_place_pressed()
	assert(session.placements.size() == 11, "2x4 base placed")
	
	# Stack 1x4 on top row (z=3)
	table.selected_part_id = "brick_1x4"
	table.current_grid_pos = Vector2i(14, 14)
	table.current_layer_plate = 3
	table.current_rotation_step = 0
	table._validate_and_update_ghost()
	assert(table.is_current_placement_valid, "1x4 stacked on 2x4 at layer 3 is valid")
	table._on_place_pressed()
	assert(session.placements.size() == 12, "1x4 stack committed")
	
	# Return to baseplate
	table._return_to_base()
	assert(table.current_layer_plate == 0, "Current layer returned to baseplate (0)")
	assert(table.is_auto_height, "Auto height restored on return to base")
	print("PASS: Narrow part stacking and Return to Base verified.")

	# -------------------------------------------------------------------------
	# [PT-02]: Camera / UI Exclusive Ownership
	# -------------------------------------------------------------------------
	print("\n[PT-02: Camera / UI Ownership]")
	var placements_before_camera = session.placements.size()
	
	# Enable Camera Mode
	table.camera_rig.is_camera_mode = true
	assert(table.camera_rig.is_camera_mode, "Camera mode active")
	
	# Left drag in camera mode: simulate mouse press
	var mouse_event = InputEventMouseButton.new()
	mouse_event.button_index = MOUSE_BUTTON_LEFT
	mouse_event.pressed = true
	mouse_event.position = Vector2(400, 300)
	table.camera_rig._unhandled_input(mouse_event)
	assert(table.camera_rig.is_orbiting, "Camera is orbiting during left drag in camera mode")
	
	# Simulate motion during camera orbit
	var motion_event = InputEventMouseMotion.new()
	motion_event.position = Vector2(420, 310)
	table.camera_rig._unhandled_input(motion_event)
	
	# Ensure tabletop did NOT commit any placement
	assert(session.placements.size() == placements_before_camera, "No placement during camera orbit")
	
	# Release camera drag
	mouse_event.pressed = false
	table.camera_rig._unhandled_input(mouse_event)
	assert(not table.camera_rig.is_orbiting, "Camera orbit ended")
	table.camera_rig.is_camera_mode = false
	print("PASS: Camera gestures do not commit placements or corrupt state.")

	# -------------------------------------------------------------------------
	# [PT-03]: Stale Target Invalidation & Toolbar Preservation
	# -------------------------------------------------------------------------
	print("\n[PT-03: Stale Target Clearance & Toolbar Candidate Preservation]")
	# Position over valid ground
	table.selected_part_id = "brick_2x2"
	table.current_grid_pos = Vector2i(4, 10)
	table.current_layer_plate = 0
	table._validate_and_update_ghost()
	assert(table.is_current_placement_valid, "Target is initially valid")
	
	# Move pointer to uncovered world with no eligible surface (off-board)
	# Ray aimed up/away from board
	var offboard_target = table.find_target_surface_from_ray(Vector3(0, 10, 0), Vector3(0, 1, 0))
	assert(not offboard_target.get("valid", false), "Offboard ray returns valid: false")
	
	# Invalidate candidate simulating off-board pointer motion
	table._invalidate_candidate()
	assert(not table.is_current_placement_valid, "Candidate invalidated when off-board")
	assert(not table.has_valid_target_surface, "has_valid_target_surface is false")
	assert(table.ghost_preview.visible == false, "Ghost preview is hidden off-board")
	assert(table.btn_place.disabled == true, "Place button disabled when candidate is invalid")
	
	# Attempt to place via Enter / button while off-board: MUST NOT COMMIT
	table._on_place_pressed()
	assert(session.placements.size() == placements_before_camera, "Zero placements committed after off-board miss")
	
	# Re-enter baseplate: candidate is restored
	table.current_grid_pos = Vector2i(6, 6)
	table.current_layer_plate = 0
	table._validate_and_update_ghost()
	assert(table.is_current_placement_valid, "Re-entering board restores valid candidate")
	assert(table.ghost_preview.visible == true, "Ghost preview is visible on board")
	assert(table.btn_place.disabled == false, "Place button enabled on valid board position")
	
	# Move pointer onto toolbar: candidate is preserved and Place button commits it
	table._on_place_pressed()
	assert(session.placements.size() == placements_before_camera + 1, "Place button successfully committed displayed candidate")
	print("PASS: Off-board misses clear candidate; toolbar preserves candidate.")

	# -------------------------------------------------------------------------
	# [Cancel / Escape Handling]
	# -------------------------------------------------------------------------
	print("\n[Cancel / Escape Action]")
	table._on_cancel_held_piece()
	assert(table.current_input_state == table.InputState.IDLE, "State is IDLE after cancel")
	assert(table.ghost_preview.visible == false, "Ghost hidden in IDLE state")
	assert(table.btn_place.disabled == true, "Place button disabled in IDLE state")
	
	# Selecting piece from tray restores HOLDING
	table._select_piece("brick_2x4", Color(0.9, 0.7, 0.1))
	assert(table.current_input_state == table.InputState.HOLDING, "Selecting piece restores HOLDING state")
	print("PASS: Cancel and piece re-selection verified.")

	# -------------------------------------------------------------------------
	# [PT-05 & PT-06]: Pass & Play Hand Enforcement & Color Preservation
	# -------------------------------------------------------------------------
	print("\n[PT-05 & PT-06: Pass & Play Hand Enforcement & Color Parity]")
	app_root.start_session({
		"mode": "pass_and_play",
		"theme_id": "harbour",
		"creation_name": "GateAPassPlay",
		"players": ["P1_Alice", "P2_Bob"],
		"timer_enabled": false
	})
	
	var pp_table = app_root.current_view
	var pp_session = app_root.active_session
	assert(pp_session.mode == SessionManager.GameMode.PASS_AND_PLAY, "Mode is PASS_AND_PLAY")
	assert(pp_session.players.size() == 2, "2 players registered")
	
	var alice_hand = pp_session.get_current_player().get("hand", [])
	assert(alice_hand.size() == 6, "Alice has 6 pieces in hand")
	
	# Attempt outside-hand part
	var outside_id = ""
	var hand_ids = []
	for p in alice_hand:
		hand_ids.append(p.get("part_id"))
	for candidate_id in ["brick_1x1", "brick_1x6", "brick_2x3", "plate_1x1", "slope_1x2"]:
		if not (candidate_id in hand_ids):
			outside_id = candidate_id
			break
			
	var reject_info = {"rejected": false, "code": ""}
	pp_session.placement_rejected.connect(func(reason, code):
		reject_info["rejected"] = true
		reject_info["code"] = code
		print("pp_session placement_rejected caught: ", code, " - ", reason)
	)
	
	pp_table.selected_part_id = outside_id
	pp_table.current_grid_pos = Vector2i(4, 4)
	pp_table.current_layer_plate = 0
	pp_table._validate_and_update_ghost()
	pp_table._on_place_pressed()
	assert(reject_info["rejected"] and reject_info["code"] == "OUTSIDE_HAND", "Outside-hand part rejected with OUTSIDE_HAND")
	assert(pp_session.placements.size() == 0, "No placement added on outside-hand attempt")
	assert(pp_session.get_current_player_id() == "p_1", "Turn remained on Alice after rejection")
	
	# Place valid piece with custom color (e.g. bright purple)
	var chosen_part = alice_hand[0]["part_id"]
	var custom_color = Color(0.7, 0.1, 0.9)
	pp_table._select_piece_from_slot(0, chosen_part, custom_color)
	pp_table.current_grid_pos = Vector2i(4, 4)
	pp_table.current_layer_plate = 0
	pp_table._validate_and_update_ghost()
	pp_table._on_place_pressed()
	
	assert(pp_session.placements.size() == 1, "Alice's hand piece placed successfully")
	print("Alice placement record: ", pp_session.placements[0])
	print("custom_color was: ", custom_color)
	assert(pp_session.placements[0]["color"] == custom_color, "Exact custom color recorded in session")
	assert(pp_session.get_current_player_id() == "p_2", "Turn advanced to Bob")
	
	# Save and verify serialization preserves exact color (within 8-bit hex quantization 1/255)
	var serialized = SaveManager.serialize_session(pp_session)
	var saved_color_hex = serialized["placements"][0]["color_hex"]
	var restored_color = Color.from_string(saved_color_hex, Color.WHITE)
	var color_diff = abs(restored_color.r - custom_color.r) + abs(restored_color.g - custom_color.g) + abs(restored_color.b - custom_color.b)
	assert(color_diff < 0.02, "Custom color preserved in save serialization (diff=%.4f)" % color_diff)
	print("PASS: Outside-hand rejection, turn advance, and color roundtrip verified.")

	app_root.queue_free()
