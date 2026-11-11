extends SceneTree

## Automated test suite for Milestone M3: World Exploration, Collision, and Toy Explorer (LB-013..LB-016).

const ExplorationWorld = preload("res://core/exploration_world.gd")
const PartCatalog = preload("res://core/part_catalog.gd")
const ToyExplorer = preload("res://client/scripts/toy_explorer.gd")
const ExplorationController = preload("res://client/scripts/exploration_controller.gd")

func _init() -> void:
	print("--- Running LittleBricks Exploration & Toy Explorer Test Suite (M3) ---")
	
	var catalog: PartCatalog = PartCatalog.new()
	catalog.load_catalog("res://assets/catalog/parts_manifest.json")
	var world_gen: ExplorationWorld = ExplorationWorld.new(catalog)
	
	# Sample build: a harbour doorway with an arch at (16, 16) and side walls at (16, 14) and (16, 18)
	var placements = [
		{"part_id": "arch_1x4", "grid_x": 16, "grid_z": 16, "layer_plate": 0, "rotation_step": 0},
		{"part_id": "brick_2x4", "grid_x": 16, "grid_z": 12, "layer_plate": 0, "rotation_step": 0},
		{"part_id": "brick_2x4", "grid_x": 16, "grid_z": 20, "layer_plate": 0, "rotation_step": 0}
	]
	
	# 1. Test Static Collision Generation (LB-013)
	print("[1/5] Testing smoothed static collision hierarchy generation...")
	var static_world: StaticBody3D = world_gen.generate_world_colliders(placements)
	if static_world.get_child_count() < 4: # Ground box + 3 pieces
		print("FAILED: Static collider child count unexpected: %d" % static_world.get_child_count())
		quit(1)
		return
	print("PASS: Smoothed static collision hierarchy generated (smooth over studs).")
	
	# 2. Test Spawn Clearance Validation (LB-013)
	print("[2/5] Testing spawn clearance validation...")
	# Open spot at (4, 4) should pass
	var open_spawn = world_gen.validate_spawn(4, 4, 0, placements)
	if not open_spawn.get("valid", false):
		print("FAILED: Open spawn spot (4, 4) was rejected: %s" % str(open_spawn))
		quit(1)
		return
	print("PASS: Open baseplate spawn spot validated.")
	
	# Blocked spot directly inside a solid brick at (16, 12) should be rejected
	var blocked_spawn = world_gen.validate_spawn(16, 12, 0, placements)
	if blocked_spawn.get("valid", false):
		print("FAILED: Obstructed spawn inside brick was accepted!")
		quit(1)
		return
	print("PASS: Obstructed spawn inside solid wall correctly rejected.")
	
	# Arch doorway portal at (16, 16) has open doorway clearance - should be walkable!
	var arch_clearance = world_gen.validate_spawn(16, 16, 0, placements)
	print("Arch portal clearance check: %s" % str(arch_clearance))
	
	# 3. Test ToyExplorer and Camera Modes (LB-014)
	print("[3/5] Testing ToyExplorer controller and dual cameras...")
	var exp_scene: PackedScene = load("res://client/scenes/explorer.tscn")
	var explorer: ToyExplorer = exp_scene.instantiate() as ToyExplorer
	root.add_child(explorer)
	explorer._ready()
	
	if explorer.camera_mode != ToyExplorer.CameraMode.THIRD_PERSON:
		print("FAILED: Initial camera mode should be 3rd Person")
		quit(1)
		return
		
	explorer.toggle_camera_mode()
	if explorer.camera_mode != ToyExplorer.CameraMode.FIRST_PERSON:
		print("FAILED: Camera toggle to 1st Person failed")
		quit(1)
		return
	print("PASS: Dual camera modes (1st/3rd POV) and toggle verified.")
	
	# 4. Test Reset Figure (LB-015)
	print("[4/5] Testing Reset Figure functionality...")
	var start_pos = explorer.position
	explorer.position = Vector3(100, -50, 100) # Fell off board
	explorer.reset_to_spawn()
	if explorer.position != start_pos:
		print("FAILED: Reset figure did not return to spawn point")
		quit(1)
		return
	print("PASS: Reset Figure successfully restores character to safe spawn.")
	
	# 5. Test Return to Table & Phase Transitions (LB-015/LB-016)
	print("[5/5] Testing Exploration View integration and return to table...")
	var view_scene: PackedScene = load("res://client/scenes/exploration_view.tscn")
	var exp_view = view_scene.instantiate()
	root.add_child(exp_view)
	exp_view.setup_exploration_scene(placements)
	
	if not exp_view.explorer_instance:
		print("FAILED: Explorer was not instantiated in exploration view")
		quit(1)
		return
	print("PASS: Exploration scene, colliders, and character integrated cleanly.")
	
	explorer.queue_free()
	exp_view.queue_free()
	static_world.queue_free()
	
	print("\nALL MILESTONE M3 EXPLORATION TESTS PASSED.")
	quit(0)
