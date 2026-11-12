extends SceneTree

const Catalog = preload("res://core/part_catalog.gd")
const MeshBuilder = preload("res://core/part_mesh_builder.gd")
const Rules = preload("res://core/placement_rules.gd")
const Session = preload("res://core/session_manager.gd")

var failed := false

func _init() -> void:
	var catalogue := Catalog.new()
	if not catalogue.load_catalog():
		quit(1)
		return
	var rules := Rules.new(catalogue)
	for id in ["galaxy", "heroes", "castle"]:
		_check_pack(catalogue, rules, id)
	if not failed:
		print("PASS: themed meshes, connector geometry, and playable themed hands")
	quit(1 if failed else 0)

func _check_pack(catalogue: Catalog, rules: Rules, id: String) -> void:
	var included := catalogue.get_theme_parts(id)
	var accents := catalogue.get_theme_parts(id, false)
	_expect(included.size() > accents.size(), id + " includes basic stock")
	var imported: int = 0
	for part in accents:
		var part_id: String = part["id"]
		var source: String = part.get("sourced_mesh", "")
		if not source.is_empty():
			imported += 1
			var mesh := load("res://" + source) as Mesh
			_expect(mesh != null and mesh.get_faces().size() > 36, part_id + " has imported source geometry")
			if mesh == null:
				continue
			_expect(part["license"] == "CC-BY-4.0", part_id + " retains the source licence")
		var root := MeshBuilder.build_part_node(part, Color.CORNFLOWER_BLUE)
		var bounds := _bounds(root, Transform3D.IDENTITY)
		var dims: Array = part["dimensions_studs"]
		_expect(bounds.size.x <= float(dims[0]) + 0.01 and bounds.size.z <= float(dims[2]) + 0.01, part_id + " fits its declared footprint")
		_expect(is_equal_approx(bounds.position.y, 0.0), part_id + " sits on the base plane")
		for turn in range(4):
			_expect(rules.validate_placement(part_id, 10, 10, 0, turn, []).get("valid"), part_id + " can be placed in every allowed orientation")
		root.free()
	var minimums := {"galaxy": 5, "heroes": 3, "castle": 7}
	_expect(imported >= minimums[id], id + " has a distinct sourced collection")

	var palette: Array[Color] = []
	for swatch in catalogue.get_theme(id)["palette"]:
		palette.append(Color(swatch))
	var session := Session.new(catalogue)
	for seed_value in range(12):
		session._rng.seed = seed_value
		session.setup_session(Session.GameMode.PASS_AND_PLAY, ["Jay", "Guest"], id, false)
		for player in session.players:
			var structural: int = 0
			var themed: bool = false
			for piece in player["hand"]:
				var part := catalogue.get_part(piece["part_id"])
				if part["category"] in ["brick", "plate"]:
					structural += 1
				themed = themed or id in part.get("theme_tags", [])
				_expect(piece["color"] in palette, id + " hand uses its own palette")
			_expect(structural >= 4 and themed, id + " deals usable structural stock and a pack part")

func _bounds(node: Node3D, parent_transform: Transform3D) -> AABB:
	var transform := parent_transform * node.transform
	var result := AABB()
	if node is MeshInstance3D:
		result = transform * node.get_aabb()
	for child in node.get_children():
		if child is Node3D:
			result = result.merge(_bounds(child, transform))
	return result

func _expect(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failed = true
