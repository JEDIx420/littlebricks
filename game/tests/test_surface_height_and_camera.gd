extends SceneTree

## Dedicated regression suite for Surface Height (LB-053) & Camera/Input Usability (LB-055).
## Verifies acceptance fixtures PC-01, PC-02, PC-03, PC-07, and PC-08.

const MainScene = preload("res://client/scenes/main.tscn")
const TableView = preload("res://client/scripts/table_view.gd")

func _init() -> void:
	print("--- Running LittleBricks Surface Height & Camera Usability Suite (LB-053/LB-055) ---")
	
	var main = MainScene.instantiate()
	root.add_child(main)
	main._ready()
	
	# =========================================================================
	# Test Group 1: PC-01 (10 Consecutive Independent Baseplate Placements)
	# =========================================================================
	print("\n[Group 1: PC-01 Consecutive Independent Baseplate Placements]")
	
	# Verify default state is Auto Height
	assert_true(main.is_auto_height, "Default mode must be Auto Height")
	assert_eq(main.current_layer_plate, 0, "Initial layer must be 0")
	
	# Place 10 bricks at distant baseplate coordinates
	var test_coords = [
		Vector2i(2, 2), Vector2i(10, 2), Vector2i(18, 2), Vector2i(26, 2),
		Vector2i(2, 10), Vector2i(10, 10), Vector2i(18, 10), Vector2i(26, 10),
		Vector2i(2, 18), Vector2i(10, 18)
	]
	
	for i in range(test_coords.size()):
		var target_coord = test_coords[i]
		# Move to coordinate on baseplate
		main.current_grid_pos = target_coord
		main.current_layer_plate = 0
		main._validate_and_update_ghost()
		
		assert_true(main.is_current_placement_valid, "Baseplate placement %d must be VALID" % i)
		assert_eq(main.current_layer_plate, 0, "Placement %d must be at layer 0" % i)
		
		# Commit placement
		var count_before = main.placed_pieces_data.size()
		main._on_place_pressed()
		assert_eq(main.placed_pieces_data.size(), count_before + 1, "Placement %d must be recorded" % i)
		
		# Simulate moving cursor to a distant empty baseplate area (e.g. 30, 20)
		# In Auto Height, pointing at baseplate plane MUST evaluate to layer 0!
		var base_wpos = TableView.grid_to_world(20, 20, 0)
		var from_ray = base_wpos + Vector3(0, 15, 0)
		var dir_ray = Vector3(0, -1, 0)
		var surface = main.find_target_surface_from_ray(from_ray, dir_ray)
		
		assert_true(surface.get("valid", false), "Surface raycast to baseplate must be valid")
		assert_eq(surface.get("layer_plate", -1), 0, "Distant baseplate target must immediately return to layer 0 (PC-01)")
		
	print("PASS: 10 consecutive independent baseplate placements accepted at layer 0 without floating errors.")
	
	# =========================================================================
	# Test Group 2: PC-02 Alternating Baseplate / Brick Top / Plate Top
	# =========================================================================
	print("\n[Group 2: PC-02 Alternating Baseplate and Brick Tops]")
	
	# 1. Baseplate target -> layer 0
	var hit_empty = main.find_target_surface_from_ray(TableView.grid_to_world(0, 28, 0) + Vector3(0, 15, 0), Vector3(0, -1, 0))
	assert_eq(hit_empty.get("layer_plate", -1), 0, "Empty baseplate must target layer 0")
	
	# 2. Pointing at top of placed 2x4 (placed earlier at (2, 2, layer=0, height=3))
	var brick_top_wpos = TableView.grid_to_world(2, 2, 3, [2, 3, 4], 0)
	var hit_brick = main.find_target_surface_from_ray(brick_top_wpos + Vector3(0, 15, 0), Vector3(0, -1, 0))
	assert_true(hit_brick.get("valid", false), "Raycast to brick top must be valid")
	assert_eq(hit_brick.get("layer_plate", -1), 3, "Hovering over 2x4 top must target layer 3")
	
	# 3. Move back to distant baseplate -> immediately returns to layer 0
	var hit_back_to_base = main.find_target_surface_from_ray(TableView.grid_to_world(28, 28, 0) + Vector3(0, 15, 0), Vector3(0, -1, 0))
	assert_eq(hit_back_to_base.get("layer_plate", -1), 0, "Moving off brick must return immediately to layer 0")
	print("PASS: Alternating baseplate and brick tops detects exact surface layers (0 -> 3 -> 0).")
	
	# =========================================================================
	# Test Group 3: PC-03 Auto, Manual, Return to Base
	# =========================================================================
	print("\n[Group 3: PC-03 Auto, Manual, Return to Base]")
	
	# Initially Auto Height
	assert_true(main.is_auto_height, "Must be Auto Height")
	
	# Bump layer (+1) locks into Manual mode
	main._bump_layer(1)
	assert_false(main.is_auto_height, "Bumping layer must switch to Manual mode")
	assert_eq(main.current_layer_plate, 1, "Layer must be 1")
	assert_eq(main.manual_layer_plate, 1, "Manual layer must be 1")
	
	main._bump_layer(2)
	assert_eq(main.current_layer_plate, 3, "Layer must be 3")
	
	main._bump_layer(-1)
	assert_eq(main.current_layer_plate, 2, "Layer must be 2")
	
	# Return to Base clears manual lock
	main._return_to_base()
	assert_true(main.is_auto_height, "Return to Base must restore Auto Height")
	assert_eq(main.current_layer_plate, 0, "Return to Base must set layer to 0")
	assert_eq(main.manual_layer_plate, 0, "Return to Base must clear manual layer")
	print("PASS: Manual mode locks, layer increments/decrements, and Return to Base clears lock.")
	
	# =========================================================================
	# Test Group 4: PC-07 UI Input Isolation
	# =========================================================================
	print("\n[Group 4: PC-07 UI Input Isolation]")
	var placements_before_ui = main.placed_pieces_data.size()
	
	# Simulate clicking buttons via direct method invocation or UI interaction
	main._on_rotate_left()
	assert_eq(main.placed_pieces_data.size(), placements_before_ui, "Rotating must never commit a brick")
	main._on_rotate_right()
	assert_eq(main.placed_pieces_data.size(), placements_before_ui, "Rotating must never commit a brick")
	main._toggle_auto_height()
	assert_eq(main.placed_pieces_data.size(), placements_before_ui, "Toggling height mode must never commit a brick")
	main._return_to_base()
	assert_eq(main.placed_pieces_data.size(), placements_before_ui, "Return to base must never commit a brick")
	
	# Tray piece selection
	main._select_piece("brick_1x4", Color.YELLOW)
	assert_eq(main.placed_pieces_data.size(), placements_before_ui, "Selecting part from tray must never commit a brick")
	assert_eq(main.selected_part_id, "brick_1x4", "Selected part must be brick_1x4")
	print("PASS: UI controls and tray selections do not cause accidental placements.")
	
	# =========================================================================
	# Test Group 5: PC-08 Camera Controller Usability (Orbit, Pan, Zoom, Mode)
	# =========================================================================
	print("\n[Group 5: PC-08 Camera Orbit, Pan, Zoom, and Dedicated Drag Mode]")
	var cam_rig = main.camera_rig
	
	# Default view
	cam_rig.set_default_view()
	assert_eq(cam_rig.yaw, 45.0, "Default yaw must be 45")
	assert_eq(cam_rig.pitch, -38.0, "Default pitch must be -38")
	assert_eq(cam_rig.distance, 24.0, "Default distance must be 24")
	
	# Orbit test
	cam_rig.orbit_by(30.0, -10.0)
	assert_eq(cam_rig.yaw, 75.0, "Orbit yaw must update")
	assert_eq(cam_rig.pitch, -48.0, "Orbit pitch must update")
	
	# Zoom test
	cam_rig.zoom_by(-5.0)
	assert_eq(cam_rig.distance, 19.0, "Zoom distance must decrease")
	
	# Pan test
	var target_before = cam_rig.target
	cam_rig.pan_by(Vector2(50, 50))
	assert_true(cam_rig.target != target_before, "Pan must move camera target")
	
	# Top view preset
	cam_rig.set_top_view()
	assert_eq(cam_rig.yaw, 0.0, "Top view yaw must be 0")
	assert_eq(cam_rig.pitch, -88.0, "Top view pitch must be -88")
	
	# Frame build
	cam_rig.frame_build(Vector3(-5, 0, -5), Vector3(5, 5, 5))
	assert_eq(cam_rig.target, Vector3(0, 2.5, 0), "Frame build target must center on bounding box")
	
	# Dedicated Camera Mode test (BUILD -> ORBIT -> PAN -> BUILD)
	assert_false(cam_rig.is_camera_mode, "Default camera mode must be OFF")
	main._toggle_camera_mode()
	assert_true(cam_rig.is_camera_mode, "Camera mode must be ON after toggle (ORBIT)")
	assert_eq(cam_rig.interaction_mode, CameraController.InteractionMode.ORBIT, "Mode must be ORBIT")
	
	# When camera mode is ON, left-click does not place pieces
	var placements_cam_mode = main.placed_pieces_data.size()
	var left_click = InputEventMouseButton.new()
	left_click.button_index = MOUSE_BUTTON_LEFT
	left_click.pressed = true
	main._unhandled_input(left_click)
	assert_eq(main.placed_pieces_data.size(), placements_cam_mode, "In Camera Mode, left-click must NOT place pieces")
	
	main._toggle_camera_mode()
	assert_true(cam_rig.is_camera_mode, "Mode must cycle to PAN")
	assert_eq(cam_rig.interaction_mode, CameraController.InteractionMode.PAN, "Mode must be PAN")
	
	main._toggle_camera_mode()
	assert_false(cam_rig.is_camera_mode, "Camera mode toggled back OFF (BUILD)")
	assert_eq(cam_rig.interaction_mode, CameraController.InteractionMode.BUILD, "Mode must be BUILD")
	print("PASS: Full camera orbit, pan, zoom, top view, frame build, and Camera Mode verified.")
	
	print("\nALL LB-053 & LB-055 REGRESSION CHECKS PASSED.")
	main.queue_free()
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
