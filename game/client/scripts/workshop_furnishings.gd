extends Node3D

## Furnishings and display builds stay outside the editable board and collision world.
const Catalog := preload("res://core/part_catalog.gd")
const Parts := preload("res://core/part_mesh_builder.gd")
const Rules := preload("res://core/placement_rules.gd")
const Plans := preload("res://core/blueprint_models.gd")
const Wood := preload("res://client/shaders/workshop_wood.gdshader")
const FURNITURE_PATH := "res://assets/sourced/kenney_furniture/"

func furnish(floor_y: float, back_wall: float, front_wall: float, half_width: float) -> void:
	var walnut := _wood(Color("#9b6849"), Vector3.UP)
	var shelf_wood := _wood(Color("#b78057"), Vector3.RIGHT)
	var light_oak := _wood(Color("#bd8d65"), Vector3.UP)
	var brass := _finish(Color("#977c5b"), 0.44)
	var linen := _finish(Color("#547a79"), 0.93)

	var sofa_origin := Vector3(-49.0, floor_y, 24.0)
	var sofa_turn := Basis(Vector3.UP, PI * 0.5)
	_prop("loungeDesignSofa", sofa_origin, 39.0, {"carpetBlue": linen, "metal": brass}, 90.0)
	_prop("pillow", sofa_origin + sofa_turn * Vector3(8.8, 8.7, -10.7), 24.0, {"carpet": _finish(Color("#db9c59"), 0.94)}, 77.0)
	_prop("pillow", sofa_origin + sofa_turn * Vector3(29.0, 8.7, -10.2), 22.0, {"carpet": _finish(Color("#d8816c"), 0.94)}, 101.0)

	_prop("bookcaseClosedDoors", Vector3(33, floor_y, back_wall + 11.0), 39.0, {"wood": light_oak, "metal": brass})
	_prop("cabinetBedDrawer", Vector3(18, floor_y, back_wall + 12.0), 43.0, {"wood": walnut, "metal": brass, "_defaultMat": linen})
	_prop("cabinetBedDrawer", Vector3(5, floor_y, front_wall - 10.0), 42.0, {"wood": walnut, "metal": brass, "_defaultMat": linen}, 180.0)

	var catalog := Catalog.new()
	if catalog.load_catalog():
		_display_shelf(Vector3(20.0, 10.5, back_wall + 7.2), 21.0, shelf_wood, walnut, catalog, "galaxy")
		_display_shelf(Vector3(22.5, 22.3, back_wall + 7.2), 22.0, shelf_wood, walnut, catalog, "harbour")
		_display_shelf(Vector3(44, 8.5, front_wall - 7.2), 24.0, shelf_wood, walnut, catalog, "castle", 180.0)

	_hang_picture(Vector3(57, 16.4, back_wall + 1.6), Vector2(14.0, 18.0), walnut, true)
	_hang_picture(Vector3(2, 7.4, front_wall - 1.7), Vector2(20, 23), walnut, true, 180.0)
	_hang_picture(Vector3(half_width - 1.3, 10.0, -12), Vector2(16, 20), walnut, false, -90.0)
	_hang_picture(Vector3(-half_width + 1.3, 11.0, 7), Vector2(17, 21), walnut, true, 90.0)

func _display_shelf(
		at: Vector3, width: float, shelf_material: Material, support_material: Material,
		catalog: Catalog, theme: String, yaw: float = 0.0
) -> void:
	var shelf := _group("DisplayShelf", at, yaw)
	_box(shelf, "ShelfBoard", Vector3(width, 0.88, 12.3), Vector3.ZERO, shelf_material)
	for x in [-width * 0.34, width * 0.34]:
		var bracket := _box(shelf, "ShelfBracket", Vector3(0.77, 5.8, 0.77), Vector3(x, -2.25, -4.0), support_material)
		bracket.rotation_degrees.x = -32.0
	_box(shelf, "DisplayPlinth", Vector3(11.5, 0.54, 10.0), Vector3(0, 0.7, 0), support_material)

	var model := _group("FinishedBrickBuild", Vector3(0, 0.87, 0), -10.0, shelf)
	for piece: Dictionary in Plans.get_model(theme)["pieces"]:
		var definition := catalog.get_part(piece["part_id"])
		if definition.is_empty():
			continue
		var brick := Parts.build_part_node(definition, piece["color"])
		brick.position = Rules.grid_to_world(piece["grid_x"], piece["grid_z"], piece["layer_plate"], definition["dimensions_studs"], piece["rotation_step"])
		brick.rotation_degrees = Rules.get_rotation_degrees(piece["rotation_step"])
		model.add_child(brick)

func _hang_picture(at: Vector3, size: Vector2, frame: Material, rocket: bool, yaw: float = 0.0) -> void:
	var picture := _group("RocketPrint" if rocket else "HillsidePrint", at, yaw)
	var border := 0.58
	var mat_board := _finish(Color("#f3e2c2"), 0.92)
	_box(picture, "Mount", Vector3(size.x - border, size.y - border, 0.35), Vector3.ZERO, mat_board)
	for side in [-1.0, 1.0]:
		_box(picture, "HorizontalFrame", Vector3(size.x, border, 0.58), Vector3(0, side * (size.y - border) * 0.5, 0.01), frame)
		_box(picture, "VerticalFrame", Vector3(border, size.y - 2 * border, 0.58), Vector3(side * (size.x - border) * 0.5, 0, 0.01), frame)
	var canvas := SurfaceTool.new()
	canvas.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ink := _finish(Color.WHITE, 0.96)
	ink.vertex_color_use_as_albedo = true
	ink.vertex_color_is_srgb = true
	ink.cull_mode = BaseMaterial3D.CULL_DISABLED
	ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	canvas.set_material(ink)
	if rocket:
		_rocket_art(canvas)
	else:
		_hillside_art(canvas)
	var illustration := MeshInstance3D.new()
	illustration.name = "OriginalIllustration"
	illustration.mesh = canvas.commit()
	illustration.position.z = 0.23
	illustration.scale = Vector3(size.x - 2.15, size.y - 2.35, 1.0)
	illustration.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	picture.add_child(illustration)

func _hillside_art(canvas: SurfaceTool) -> void:
	_shape(canvas, Color("#efc697"), [Vector2(-0.5, -0.5), Vector2(0.5, -0.5), Vector2(0.5, 0.5), Vector2(-0.5, 0.5)], 0.0)
	_disc(canvas, Color("#df915a"), Vector2(0.20, 0.22), Vector2(0.13, 0.105), 0.015)
	_shape(canvas, Color("#b58879"), [
		Vector2(-0.5, -0.5), Vector2(0.5, -0.5), Vector2(0.5, 0.02), Vector2(0.18, 0.16),
		Vector2(-0.04, -0.04), Vector2(-0.31, 0.23), Vector2(-0.5, 0.04)
	], 0.03)
	_shape(canvas, Color("#83947f"), [
		Vector2(-0.5, -0.5), Vector2(0.5, -0.5), Vector2(0.5, 0.06), Vector2(0.22, -0.07),
		Vector2(-0.04, -0.10), Vector2(-0.30, -0.24), Vector2(-0.5, -0.12)
	], 0.045)
	_shape(canvas, Color("#456b65"), [
		Vector2(-0.5, -0.5), Vector2(0.5, -0.5), Vector2(0.5, -0.36), Vector2(0.13, -0.29), Vector2(-0.27, -0.31), Vector2(-0.5, -0.19)
	], 0.06)
	for x in [-0.36, -0.21, 0.08, 0.31, 0.41]:
		var y := -0.32 - maxf(x, 0.0) * 0.10
		var height := 0.10 + absf(sin(x * 14.0)) * 0.13
		_shape(canvas, Color("#304f4e"), [
			Vector2(x - height * 0.28, y), Vector2(x + height * 0.28, y), Vector2(x, y + height)
		], 0.075)

func _rocket_art(canvas: SurfaceTool) -> void:
	_shape(canvas, Color("#395362"), [Vector2(-0.5, -0.5), Vector2(0.5, -0.5), Vector2(0.5, 0.5), Vector2(-0.5, 0.5)], 0.0)
	_disc(canvas, Color("#b88f74"), Vector2(-0.27, 0.19), Vector2(0.13, 0.102), 0.015)
	_shape(canvas, Color("#e6af73"), [
		Vector2(-0.44, 0.142), Vector2(-0.14, 0.22), Vector2(-0.09, 0.248), Vector2(-0.39, 0.173)
	], 0.028)
	for at: Vector2 in [Vector2(-0.35, -0.24), Vector2(0.33, -0.09), Vector2(0.36, 0.35), Vector2(-0.39, 0.36), Vector2(0.01, 0.36)]:
		_disc(canvas, Color("#efd8aa"), at, Vector2(0.018, 0.014), 0.03)
	var axis := Vector2(0.48, 0.88)
	var sideways := Vector2(axis.y, -axis.x)
	var tip := Vector2(0.17, 0.28)
	var base := tip - axis * 0.46
	var crown := tip - axis * 0.15
	_shape(canvas, Color("#d68867"), [
		base - axis * 0.085 - sideways * 0.17, base + axis * 0.18, base - axis * 0.085 + sideways * 0.17
	], 0.045)
	_shape(canvas, Color("#eed8a9"), [
		base - sideways * 0.078, base + sideways * 0.078, crown + sideways * 0.072, tip,
		crown - sideways * 0.072
	], 0.06)
	_shape(canvas, Color("#d68867"), [tip, crown - sideways * 0.072, crown + sideways * 0.072], 0.075)
	_disc(canvas, Color("#577f89"), base + axis * 0.22, Vector2(0.042, 0.035), 0.09)
	_shape(canvas, Color("#dcac63"), [
		base - sideways * 0.044, base + sideways * 0.044, base - axis * 0.18
	], 0.075)

func _disc(canvas: SurfaceTool, color: Color, center: Vector2, radius: Vector2, layer: float) -> void:
	var outline := PackedVector2Array()
	for i in range(24):
		outline.append(center + Vector2.from_angle(TAU * float(i) / 24.0) * radius)
	_shape(canvas, color, outline, layer)

func _shape(canvas: SurfaceTool, color: Color, outline: PackedVector2Array, layer: float) -> void:
	for index in Geometry2D.triangulate_polygon(outline):
		var point := outline[index]
		canvas.set_color(color)
		canvas.set_normal(Vector3.BACK)
		canvas.add_vertex(Vector3(point.x, point.y, layer))

func _group(label: String, at: Vector3, yaw: float, parent: Node3D = null) -> Node3D:
	var group := Node3D.new()
	group.name = label
	group.position = at
	group.rotation_degrees.y = yaw
	(self if parent == null else parent).add_child(group)
	return group

func _box(parent: Node3D, label: String, size: Vector3, at: Vector3, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = at
	node.material_override = material
	parent.add_child(node)
	return node

func _prop(asset: String, at: Vector3, scale_factor: float, finishes: Dictionary, turn: float = 0.0) -> void:
	var packed := load(FURNITURE_PATH + asset + ".glb") as PackedScene
	var prop := packed.instantiate() as Node3D
	prop.position = at
	prop.rotation_degrees.y = turn
	prop.scale = Vector3.ONE * scale_factor
	add_child(prop)
	for mesh: MeshInstance3D in prop.find_children("*", "MeshInstance3D", true, false):
		for surface_index in mesh.mesh.get_surface_count():
			var material := mesh.get_active_material(surface_index)
			if material and finishes.has(material.resource_name):
				mesh.set_surface_override_material(surface_index, finishes[material.resource_name])

func _finish(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material

func _wood(color: Color, grain_axis: Vector3) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = Wood
	material.set_shader_parameter("wood", color)
	material.set_shader_parameter("grain_axis", grain_axis)
	material.set_shader_parameter("matte", 0.68)
	return material
