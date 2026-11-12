extends SceneTree

## Checks the assembled render geometry as well as deterministic placement.
## A valid connector in JSON must coincide with a physical seat and support a
## real stack after every permitted quarter turn.

const Catalog = preload("res://core/part_catalog.gd")
const MeshBuilder = preload("res://core/part_mesh_builder.gd")
const Rules = preload("res://core/placement_rules.gd")
const ANCHOR := Vector2i(9, 11)
const EDGE_TOLERANCE := 0.025
const STUD_MAX_HEIGHT := 0.245

var _failed := false
var _poses_checked := 0
var _connections_checked := 0

func _initialize() -> void:
	var catalogue := Catalog.new()
	if not catalogue.load_catalog():
		quit(1)
		return
	var rules := Rules.new(catalogue)
	for id in catalogue.get_all_part_ids():
		var part := catalogue.get_part(id)
		_check_render(part, catalogue)
		for step in part["allowed_rotations"]:
			_check_pose(part, int(step), rules)
	if not _failed:
		print("PASS: %d rendered parts, %d rotated placements, %d individual socket and stud connections" % [
			catalogue.get_all_part_ids().size(), _poses_checked, _connections_checked,
		])
	quit(1 if _failed else 0)

func _check_render(part: Dictionary, catalogue: Catalog) -> void:
	var id: String = part["id"]
	var dims: Array = part["dimensions_studs"]
	var rendered := MeshBuilder.build_part_node(part, Color.SKY_BLUE)
	var all_faces := PackedVector3Array()
	var body_faces := PackedVector3Array()
	_collect_faces(rendered, Transform3D.IDENTITY, all_faces, body_faces)
	_expect(not all_faces.is_empty(), id + " has geometry")
	if all_faces.is_empty():
		rendered.free()
		return
	var low := all_faces[0]
	var high := all_faces[0]
	for point in all_faces:
		low = low.min(point)
		high = high.max(point)
	var limit := Vector3(float(dims[0]) * 0.5, float(dims[1]) * Rules.PLATE_HEIGHT, float(dims[2]) * 0.5)
	_expect(absf(low.y) <= EDGE_TOLERANCE and high.y <= limit.y + STUD_MAX_HEIGHT, id + " sits on its base and respects its height")
	_expect(low.x >= -limit.x - EDGE_TOLERANCE and high.x <= limit.x + EDGE_TOLERANCE, id + " respects its X footprint")
	_expect(low.z >= -limit.z - EDGE_TOLERANCE and high.z <= limit.z + EDGE_TOLERANCE, id + " respects its Z footprint")

	for stud in catalogue.get_top_stud_layers(id, 0):
		var center := Vector2(stud.x, stud.z)
		var plane := stud.y * Rules.PLATE_HEIGHT
		# Some imported studs are hollow. Probe their ring as well as the centre.
		var cap := _highest_near(all_faces, center, plane + STUD_MAX_HEIGHT, [0.23, 0.27])
		_expect(cap >= plane + 0.12, "%s has a rendered stud at %s" % [id, stud])
		var shoulder := _highest_near(body_faces, center, plane + 0.008, [0.21])
		_expect(shoulder >= plane - 0.045, "%s stud meets its body at %s" % [id, stud])
	for socket in catalogue.get_bottom_sockets(id, 0):
		# An imported hollow underside seats on its surrounding shoulder.
		var seat := _lowest_near(body_faces, socket, [0.08, 0.24, 0.39])
		_expect(seat <= 0.065, "%s has a physical seat at %s" % [id, socket])
	if part["category"] == "character":
		var figure := rendered.get_child(0) as Node3D
		_expect(is_equal_approx(figure.scale.x, figure.scale.y) and is_equal_approx(figure.scale.x, figure.scale.z), id + " keeps the character's natural proportions")
	rendered.free()

func _check_pose(part: Dictionary, turn: int, rules: Rules) -> void:
	var id: String = part["id"]
	var dims: Array = part["dimensions_studs"]
	var footprint := Vector2i(int(dims[0]), int(dims[2]))
	if turn in [1, 3]:
		footprint = Vector2i(footprint.y, footprint.x)
	var edge := Vector2i(Rules.GRID_SIZE, Rules.GRID_SIZE) - footprint
	var record := _placement(id, ANCHOR, 0, turn)
	var pose := Transform3D(
		Basis.from_euler(Rules.get_rotation_degrees(turn) * (PI / 180.0)),
		Rules.grid_to_world(ANCHOR.x, ANCHOR.y, 0, dims, turn)
	)
	_expect(rules.validate_placement(id, edge.x, edge.y, 0, turn, []).valid, id + " fits flush with both board edges")
	_expect(not rules.validate_placement(id, edge.x + 1, edge.y, 0, turn, []).valid, id + " cannot overhang the board")
	_expect(rules.validate_placement("brick_1x1", ANCHOR.x + footprint.x, ANCHOR.y, 0, 0, [record]).valid, id + " allows the next stud beside its footprint")
	_poses_checked += 1

	var expected_bottom: Array[Vector3i] = []
	for socket in part["connectors"]["sockets_bottom"]:
		var coord := _grid_connector(socket, turn, footprint)
		_expect(_at_rendered_stud(pose, socket, coord, 0), id + " rendered socket follows the rotated grid")
		expected_bottom.append(Vector3i(coord.x, 3, coord.y))
		var post := _placement("brick_1x1", coord, 0, 0)
		var result := rules.validate_placement(id, ANCHOR.x, ANCHOR.y, 3, turn, [post])
		_expect(result.valid and result.connected_studs == 1, "%s seats on socket %s in turn %d" % [id, coord, turn])
		_connections_checked += 1
	_expect(rules.get_absolute_bottom_sockets(id, ANCHOR.x, ANCHOR.y, 3, turn) == expected_bottom, id + " bottom sockets rotate onto the exact lattice")

	var expected_top: Array[Vector3i] = []
	for stud in part["connectors"]["studs_top"]:
		var coord := _grid_connector(stud, turn, footprint)
		var height := int(stud[2]) if stud.size() > 2 else int(dims[1])
		_expect(_at_rendered_stud(pose, stud, coord, height), id + " rendered top stud follows the rotated grid")
		expected_top.append(Vector3i(coord.x, height, coord.y))
		var result := rules.validate_placement("brick_1x1", coord.x, coord.y, height, 0, [record])
		_expect(result.valid and result.connected_studs == 1, "%s supports a cap at %s in turn %d" % [id, coord, turn])
		_connections_checked += 1
	_expect(rules.get_absolute_top_studs(id, ANCHOR.x, ANCHOR.y, 0, turn) == expected_top, id + " top studs rotate onto the exact lattice")

func _grid_connector(local: Array, turn: int, footprint: Vector2i) -> Vector2i:
	# Use doubled integer coordinates for the independent parity/rotation oracle.
	var point := Vector2i(roundi(float(local[0]) * 2.0), roundi(float(local[1]) * 2.0))
	for step in range(turn):
		point = Vector2i(-point.y, point.x)
	var doubled := ANCHOR * 2 + footprint - Vector2i.ONE + point
	_expect(doubled.x % 2 == 0 and doubled.y % 2 == 0, "Connector lands on a whole stud address")
	return doubled / 2

func _at_rendered_stud(pose: Transform3D, local: Array, address: Vector2i, layer: int) -> bool:
	var offset := (float(Rules.GRID_SIZE) - 1.0) * 0.5
	var expected := Vector3(float(address.x) - offset, 0.1 + layer * Rules.PLATE_HEIGHT, float(address.y) - offset)
	var point := Vector3(float(local[0]), layer * Rules.PLATE_HEIGHT, float(local[1]))
	return (pose * point).distance_to(expected) < 0.001

func _placement(id: String, anchor: Vector2i, layer: int, turn: int) -> Dictionary:
	return {"part_id": id, "grid_x": anchor.x, "grid_z": anchor.y, "layer_plate": layer, "rotation_step": turn}

func _collect_faces(node: Node3D, parent: Transform3D, all_faces: PackedVector3Array, body_faces: PackedVector3Array) -> void:
	var pose := parent * node.transform
	if node is MeshInstance3D and node.mesh:
		var mesh: Mesh = node.mesh
		var separate_stud := mesh is CylinderMesh and is_equal_approx(mesh.height, MeshBuilder.STUD_HEIGHT) and is_equal_approx(mesh.bottom_radius, MeshBuilder.STUD_RADIUS) and is_equal_approx(mesh.top_radius, MeshBuilder.STUD_RADIUS - 0.016)
		for point in mesh.get_faces():
			var transformed: Vector3 = pose * point
			all_faces.append(transformed)
			if not separate_stud:
				body_faces.append(transformed)
	for child in node.get_children():
		if child is Node3D:
			_collect_faces(child, pose, all_faces, body_faces)

func _highest_near(faces: PackedVector3Array, center: Vector2, origin_y: float, radii: Array) -> float:
	var result := _ray_height(faces, center, origin_y, Vector3.DOWN)
	for radius in radii:
		for direction in range(8):
			var offset := Vector2.from_angle(TAU * float(direction) / 8.0) * float(radius)
			result = maxf(result, _ray_height(faces, center + offset, origin_y, Vector3.DOWN))
	return result

func _lowest_near(faces: PackedVector3Array, center: Vector2, radii: Array) -> float:
	var result := _ray_height(faces, center, -0.04, Vector3.UP)
	for radius in radii:
		for direction in range(8):
			var offset := Vector2.from_angle(TAU * float(direction) / 8.0) * float(radius)
			result = minf(result, _ray_height(faces, center + offset, -0.04, Vector3.UP))
	return result

func _ray_height(faces: PackedVector3Array, position: Vector2, origin_y: float, direction: Vector3) -> float:
	var origin := Vector3(position.x, origin_y, position.y)
	var distance := INF
	for i in range(0, faces.size(), 3):
		var hit = Geometry3D.ray_intersects_triangle(origin, direction, faces[i], faces[i + 1], faces[i + 2])
		if hit != null:
			distance = minf(distance, absf(hit.y - origin_y))
	return origin_y + distance * direction.y

func _expect(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		_failed = true
