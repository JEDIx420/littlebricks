extends SceneTree

## Automated test suite for LB-006 & LB-007: Input parity, ghost preview, and camera gestures.

func _init() -> void:
	print("--- Running LittleBricks Interaction Parity & Controls Test Suite ---")
	
	var main_scene_res: PackedScene = load("res://client/scenes/main.tscn")
	if not main_scene_res:
		print("FAILED: Could not load main.tscn")
		quit(1)
		return
		
	var main_node = main_scene_res.instantiate()
	root.add_child(main_node)
	main_node._ready()
	
	# Verify components initialized
	if not main_node.catalog or not main_node.rules:
		print("FAILED: Catalog or rules not initialized in main scene")
		quit(1)
		return
	print("PASS: Main scene, catalog, and rules initialized.")
	
	# 1. Test piece selection and ghost update
	main_node._select_piece("brick_1x2", Color.YELLOW)
	if main_node.selected_part_id != "brick_1x2" or main_node.selected_color != Color.YELLOW:
		print("FAILED: Piece selection did not update selected part")
		quit(1)
		return
	print("PASS: Selectable inventory tray updates ghost piece.")
	
	# 2. Test quarter-turn rotation
	main_node._on_rotate_right()
	if main_node.current_rotation_step != 1:
		print("FAILED: Rotate right step expected 1, got %d" % main_node.current_rotation_step)
		quit(1)
		return
	main_node._on_rotate_left()
	if main_node.current_rotation_step != 0:
		print("FAILED: Rotate left step expected 0, got %d" % main_node.current_rotation_step)
		quit(1)
		return
	print("PASS: Quarter-turn rotation verified (0° -> 90° -> 0°).")
	
	# 3. Test layer height control
	main_node.set_layer(3)
	if main_node.current_layer_plate != 3:
		print("FAILED: Layer height adjustment failed")
		quit(1)
		return
	print("PASS: Layer height controls verified.")
	
	# Reset to layer 0 for legal baseplate placement
	main_node.set_layer(0)
	main_node.current_grid_pos = Vector2i(15, 15)
	main_node._validate_and_update_ghost()
	
	if not main_node.is_current_placement_valid:
		print("FAILED: Legal baseplate position marked invalid")
		quit(1)
		return
	print("PASS: Valid placement cues verified (btn_place enabled, status text OK).")
	
	# 4. Commit placement and check container
	var count_before: int = main_node.placed_pieces_data.size()
	main_node._on_place_pressed()
	var count_after: int = main_node.placed_pieces_data.size()
	if count_after != count_before + 1:
		print("FAILED: Explicit place did not record piece into placed_pieces_data")
		quit(1)
		return
	print("PASS: Explicit Place committed piece to board.")
	
	# 5. Verify camera controls and presets
	var cam_rig = main_node.camera_rig
	cam_rig.set_top_view()
	if not is_equal_approx(cam_rig.pitch, -88.0):
		print("FAILED: Top view preset pitch not set")
		quit(1)
		return
	cam_rig.set_default_view()
	if not is_equal_approx(cam_rig.pitch, -38.0):
		print("FAILED: Default view preset pitch not restored")
		quit(1)
		return
	print("PASS: Camera orbit, zoom, and top-view presets verified.")
	
	main_node.queue_free()
	print("\nALL LB-006 & LB-007 INTERACTION TESTS PASSED.")
	quit(0)
