extends SceneTree

## Comprehensive Gate A Verification Suite (PT-01, PT-02, PT-03, PT-05, PT-06)
## Validates real viewport input routing through AppRoot, candidate management,
## camera isolation, stale target clearance, cancellation, and session authority.

const AppRootScene = preload("res://client/scenes/app_root.tscn")
const SessionManager = preload("res://core/session_manager.gd")
const TableView = preload("res://client/scripts/table_view.gd")

func _initialize() -> void:
	# Assertions abort the active coroutine. A watchdog makes a failed
	# assertion fail the process even on engines that otherwise exit zero.
	create_timer(12.0).timeout.connect(func(): quit(1))
	call_deferred("_run")

func _run() -> void:
	print("\n--- Running LittleBricks Gate A Input Ownership & Authority Suite ---")
	root.size = Vector2i(1280, 720)
	var app_root = AppRootScene.instantiate()
	root.add_child(app_root)
	await process_frame

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
	
	await process_frame
	var table = app_root.current_view
	assert(table != null and table.get_script().resource_path.ends_with("main.gd"), "Navigated to Main Table")
	var session: SessionManager = app_root.active_session
	assert(session != null, "Session is attached")
	assert(session.mode == SessionManager.GameMode.SOLO_CREATIVE, "Session is in SOLO_CREATIVE")
	
	# -------------------------------------------------------------------------
	# [PT-01]: 10 Separated Placements across baseplate
	# -------------------------------------------------------------------------
	print("\n[PT-01: Real Pointer & Separated Placements]")
	await _click_control(table.btn_top_view)
	var test_positions := [
		Vector2i(4, 4), Vector2i(9, 4), Vector2i(14, 4), Vector2i(19, 4), Vector2i(24, 4),
		Vector2i(4, 11), Vector2i(9, 11), Vector2i(14, 11), Vector2i(19, 11), Vector2i(24, 11),
	]
	table._select_piece("brick_2x4", Color(0.2, 0.4, 0.8))
	for i in range(test_positions.size()):
		var grid: Vector2i = test_positions[i]
		var pointer := _screen_for_piece(table, "brick_2x4", grid)
		_move_pointer(pointer)
		assert(table.is_current_placement_valid, "Pointer resolves a legal target at %s" % grid)
		_mouse_button(pointer, MOUSE_BUTTON_LEFT, true)
		assert(session.placements.size() == i, "Press alone spends no brick")
		_mouse_button(pointer, MOUSE_BUTTON_LEFT, false)
		assert(session.placements.size() == i + 1, "Release accepts one placement")
		var placement: Dictionary = session.placements.back()
		assert(Vector3i(placement.grid_x, placement.layer_plate, placement.grid_z) == Vector3i(grid.x, 0, grid.y))
		assert(table.placed_pieces_data.size() == i + 1, "Accepted piece is rendered on the table")
	print("PASS: 10 separated placements committed through viewport mouse input.")

	table._select_piece("brick_1x4", Color(0.9, 0.7, 0.1))
	for grid in [Vector2i(4, 4), Vector2i(5, 4)]:
		var pointer := _screen_for_piece(table, "brick_1x4", grid, 3)
		_move_pointer(pointer)
		_mouse_button(pointer, MOUSE_BUTTON_LEFT, true)
		_mouse_button(pointer, MOUSE_BUTTON_LEFT, false)
		var placement: Dictionary = session.placements.back()
		assert(Vector3i(placement.grid_x, placement.layer_plate, placement.grid_z) == Vector3i(grid.x, 3, grid.y))
	assert(session.placements.size() == 12, "Both rows support the narrow brick")
	var empty_ground := _screen_for_piece(table, "brick_1x4", Vector2i(12, 21))
	_move_pointer(empty_ground)
	assert(table.current_layer_plate == 0 and table.is_auto_height, "Moving off the stack returns to the baseplate")
	print("PASS: Narrow brick stacks on both rows and automatically returns to ground.")

	print("\n[PT-02: Camera / UI Ownership]")
	var placements_before_camera: int = session.placements.size()
	assert(table.is_current_placement_valid, "Camera test begins with a valid target")
	await _click_control(table.find_child("BtnCameraDock", true, false))
	await _click_control(table.find_child("BtnOrbitMode", true, false))
	assert(table.camera_rig.is_camera_mode, "Orbit mode selected through the HUD")
	var yaw_before: float = table.camera_rig.yaw
	_mouse_button(empty_ground, MOUSE_BUTTON_LEFT, true)
	assert(table.camera_rig.is_orbiting, "Left press starts orbit in camera mode")
	_move_pointer(empty_ground + Vector2(32, 10), MOUSE_BUTTON_MASK_LEFT)
	var settings_button := table.btn_settings as Control
	_mouse_button(settings_button.get_global_rect().get_center(), MOUSE_BUTTON_LEFT, false)
	assert(not table.camera_rig.is_orbiting, "Releasing camera drag over HUD clears gesture ownership")
	assert(not is_equal_approx(table.camera_rig.yaw, yaw_before), "Camera actually turned")
	assert(session.placements.size() == placements_before_camera, "Camera gesture spends no brick")
	await _click_control(table.btn_camera_mode)
	await _click_control(table.btn_top_view)
	print("PASS: Orbit turns the view without placing and releases over the HUD.")

	print("\n[PT-03: Stale Target Clearance & Toolbar Candidate Preservation]")
	empty_ground = _screen_for_piece(table, "brick_1x4", Vector2i(12, 21))
	_move_pointer(empty_ground)
	assert(table.is_current_placement_valid, "A fresh world hover restores the target after camera mode")
	var outside_board: Vector2 = table.camera_rig.camera.unproject_position(Vector3(22, 0.1, -7))
	_move_pointer(outside_board)
	assert(not table.is_current_placement_valid and not table.has_valid_target_surface)
	assert(not table.ghost_preview.visible and table.btn_place.disabled)
	_press_key(KEY_ENTER)
	assert(session.placements.size() == placements_before_camera, "Off-board miss cannot place through Enter")
	_move_pointer(empty_ground)
	assert(table.is_current_placement_valid and table.ghost_preview.visible and not table.btn_place.disabled)
	await _click_control(table.btn_place)
	assert(session.placements.size() == placements_before_camera + 1, "Place commits the last world candidate through HUD")
	print("PASS: Off-board misses clear the candidate, while the toolbar preserves it.")

	# Catalogue and Settings must own both keyboard and pointer input.
	_move_pointer(_screen_for_piece(table, "brick_1x4", Vector2i(22, 17)))
	assert(table.is_current_placement_valid)
	await _click_control(table.btn_settings)
	assert(app_root.settings_dialog.visible)
	var before_modal: int = session.placements.size()
	_press_key(KEY_ENTER)
	await _click_control(table.find_child("BtnOrbitMode", true, false))
	assert(session.placements.size() == before_modal and not table.camera_rig.is_camera_mode)
	await _click_control(app_root.settings_dialog.find_child("BtnClose", true, false))
	await _click_control(table.btn_all_parts)
	assert(table.catalog_modal.visible)
	await _click_control(table.btn_undo)
	assert(session.placements.size() == before_modal, "Catalogue blocks the Undo action behind it")
	await _click_control(table.btn_close_catalog)
	print("PASS: Settings and Catalogue block input behind their overlays.")

	# -------------------------------------------------------------------------
	# [Cancel / Escape Handling]
	# -------------------------------------------------------------------------
	print("\n[Cancel / Escape Action]")
	_press_key(KEY_ESCAPE)
	assert(table.current_input_state == table.InputState.IDLE, "State is IDLE after cancel")
	assert(table.ghost_preview.visible == false, "Ghost hidden in IDLE state")
	assert(table.btn_place.disabled == true, "Place button disabled in IDLE state")
	
	# Selecting piece from tray restores HOLDING
	await _click_control(table.tray_container.get_child(0))
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
	await process_frame
	print("\nALL GATE A INTEGRATED CHECKS PASSED SUCCESSFULLY.")
	quit(0)

func _screen_for_piece(table: Node, part_id: String, grid: Vector2i, layer: int = 0) -> Vector2:
	var dims: Array = table.catalog.get_part(part_id).dimensions_studs
	return table.camera_rig.camera.unproject_position(TableView.grid_to_world(grid.x, grid.y, layer, dims, 0))

func _dispatch(event: InputEvent) -> void:
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func _move_pointer(pointer: Vector2, button_mask: int = 0) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = pointer
	motion.global_position = pointer
	motion.button_mask = button_mask
	_dispatch(motion)

func _mouse_button(pointer: Vector2, button: int, pressed: bool) -> void:
	var click := InputEventMouseButton.new()
	click.position = pointer
	click.global_position = pointer
	click.button_index = button
	click.button_mask = 1 << (button - 1) if pressed else 0
	click.pressed = pressed
	_dispatch(click)

func _press_key(key: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = key
		event.pressed = pressed
		_dispatch(event)

func _click_control(control: Control) -> void:
	var pointer := control.get_global_rect().get_center()
	_move_pointer(pointer)
	_mouse_button(pointer, MOUSE_BUTTON_LEFT, true)
	_mouse_button(pointer, MOUSE_BUTTON_LEFT, false)
	await process_frame
