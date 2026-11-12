extends SceneTree

const Target = preload("res://client/scripts/brick_surface_target.gd")
const Rules = preload("res://core/placement_rules.gd")
const MeshBuilder = preload("res://core/part_mesh_builder.gd")

var failed: bool = false

func _init() -> void:
	var rules := Rules.new()
	var board: Array = [_placement("brick_2x4", 8, 8), _placement("stairs_2x4", 12, 12), _placement("arch_1x4", 15, 14), _placement("tile_1x1", 23, 23)]
	_expect(_down(rules, board, Vector3(-7.5, 20, -7.5)).get("layer_plate") == 3, "Brick top snaps to its body plane")
	_expect(_down(rules, board, Vector3(-3.5, 20, -3.5)).get("layer_plate") == 2, "First stair tread uses its own height")
	_expect(_down(rules, board, Vector3(-3.5, 20, -0.5)).get("layer_plate") == 6, "Top stair tread uses its own height")
	_expect(_down(rules, board, Vector3(8.5, 20, 8.5)).get("layer_plate") == 0, "Exposed base returns directly to height zero")
	_expect(not _down(rules, board, Vector3(17.0, 20, 3.0)).get("valid", false), "Misses stay off the board")

	var opening := Target.resolve(Vector3(-2, 0.48, 0), Vector3(1, -0.2, 0), rules, board, "brick_1x1", 0)
	_expect(opening.get("layer_plate") == 0, "A ray through the arch opening reaches the baseplate")
	var locked := Target.resolve(Vector3(-7.5, 20, -7.5), Vector3.DOWN, rules, board, "brick_1x1", 0, 9)
	_expect(locked.get("layer_plate") == 9, "Manual height uses the chosen plane")
	_expect(not rules.validate_placement("brick_1x1", 23, 23, 1, 0, board).get("valid"), "A smooth tile exposes no usable top connector")
	_expect(rules.validate_placement("brick_1x1", 12, 12, 2, 0, board).get("valid"), "The first stair tread can support a brick")
	_expect(not rules.validate_placement("brick_1x1", 12, 12, 6, 0, board).get("valid"), "Air above the first stair tread cannot support a brick")
	_expect(rules.get_absolute_top_studs("brick_corner_3x3", 10, 10, 0, 0).size() == 5, "L-shaped 3x3 corner has five studs")
	_expect(rules.get_absolute_bottom_sockets("slope_inverted_2x2", 10, 10, 0, 0) == [Vector3i(10, 0, 11), Vector3i(11, 0, 11)], "Inverted slope sockets are exact lattice addresses")

	_check_bounds(rules, "brick_corner_3x3", Vector3(3, 1.38, 3))
	_check_bounds(rules, "slope_2x4_45", Vector3(2, 1.2, 4))
	_check_bounds(rules, "slope_curved_1x4", Vector3(1, 0.8, 4))
	_check_bounds(rules, "window_1x2x2", Vector3(1, 2.6, 2))
	_check_bounds(rules, "tile_1x6", Vector3(1, 0.4, 6))
	_expect(rules.get_absolute_top_studs("toy_explorer_pippin", 10, 10, 0, 0).is_empty(), "Figures are decorative and cannot support bricks")
	if not failed:
		print("PASS: representative part silhouettes and physical snap targets")
	quit(1 if failed else 0)

func _placement(id: String, x: int, z: int) -> Dictionary:
	return {"part_id": id, "grid_x": x, "grid_z": z, "layer_plate": 0, "rotation_step": 0}

func _down(rules: Rules, board: Array, origin: Vector3) -> Dictionary:
	return Target.resolve(origin, Vector3.DOWN, rules, board, "brick_1x1", 0)

func _check_bounds(rules: Rules, id: String, expected: Vector3) -> void:
	var node: Node3D = MeshBuilder.build_part_node(rules.catalog.get_part(id), Color.SKY_BLUE)
	var bounds := _mesh_bounds(node, Transform3D.IDENTITY)
	_expect(bounds.size.distance_to(expected) < 0.10, "%s bounds %s match %s" % [id, bounds.size, expected])
	node.free()

func _mesh_bounds(node: Node3D, parent: Transform3D) -> AABB:
	var transform: Transform3D = parent * node.transform
	var result := AABB()
	if node is MeshInstance3D:
		result = transform * node.get_aabb()
	for child in node.get_children():
		if child is Node3D:
			result = result.merge(_mesh_bounds(child, transform))
	return result

func _expect(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failed = true
