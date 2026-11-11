extends Node3D
class_name TableView

const GRID_SIZE: int = 32
const STUD_SPACING: float = 1.0
const STUD_RADIUS: float = 0.3
const STUD_HEIGHT: float = 0.18
const PLATE_HEIGHT: float = 0.4
const FLOOR_Y: float = -23.0
const TABLE_TOP_Y: float = -0.1
const TABLE_HEIGHT: float = TABLE_TOP_Y - FLOOR_Y
const ROOM_WIDTH: float = 142.0
const BACK_WALL: float = -48.0
const ROOM_FRONT: float = 73.0
const ROOM_HEIGHT: float = 68.0
const WOOD_GRAIN = preload("res://client/shaders/workshop_wood.gdshader")

@onready var table_mesh: MeshInstance3D = $TableMesh
@onready var baseplate_mesh: MeshInstance3D = $BaseplateMesh
@onready var studs_multimesh: MultiMeshInstance3D = $StudsMultiMesh

var room_node: Node3D
var _table_wood: ShaderMaterial
var _plate_material: StandardMaterial3D
var _stud_material: StandardMaterial3D
var _table_color := Color("#9e6842")
var _plate_color := Color("#668475")

func _ready() -> void:
	_setup_table()
	_setup_baseplate()
	_generate_studs()
	_setup_room()

func set_palette(table_color: Color, plate_color: Color) -> void:
	_table_color = table_color
	_plate_color = plate_color
	if _table_wood:
		_table_wood.set_shader_parameter("wood", table_color)
	if _plate_material and _stud_material:
		_plate_material.albedo_color = plate_color
		_stud_material.albedo_color = plate_color.lightened(0.06)

func _setup_table() -> void:
	_table_wood = _wood(_table_color, Vector3.RIGHT, 0.48)
	var edge_wood := _wood(Color("#795036"), Vector3.RIGHT, 0.55)
	var leg_wood := _wood(Color("#82583e"), Vector3.UP, 0.58)
	table_mesh.mesh = _beveled_slab(55.0, 44.0, 1.9, 1.6, 0.3)
	table_mesh.position.y = TABLE_TOP_Y - 0.95
	table_mesh.material_override = _table_wood
	_box(self, "LongApron", Vector3(49, 2.6, 1.2), Vector3(0, -3.3, 18.3), edge_wood)
	_box(self, "BackApron", Vector3(49, 2.6, 1.2), Vector3(0, -3.3, -18.3), edge_wood)
	for x in [-24.0, 24.0]:
		_box(self, "SideApron", Vector3(1.2, 2.6, 36), Vector3(x, -3.3, 0), edge_wood)
		for z in [-18.0, 18.0]:
			var leg := MeshInstance3D.new()
			leg.name = "TaperedLeg"
			var shape := CylinderMesh.new()
			shape.top_radius = 1.65
			shape.bottom_radius = 1.13
			shape.height = TABLE_HEIGHT - 1.6
			shape.radial_segments = 12
			shape.rings = 1
			leg.mesh = shape
			leg.material_override = leg_wood
			leg.position = Vector3(x, FLOOR_Y + shape.height * 0.5, z)
			add_child(leg)

	# Physical props sit beyond the build surface and never participate in picking.
	_parts_tray(Vector3(21.7, TABLE_TOP_Y, 9.0), Color("#435d56"), 13.0, 11.0, Color("#c59651"), Color("#b46b57"))
	_parts_tray(Vector3(-22.0, TABLE_TOP_Y, -6.0), Color("#ae684f"), 13.0, -8.0, Color("#d5baa0"), Color("#678f8e"))

func _parts_tray(origin: Vector3, shell: Color, length: float, angle: float, warm_brick: Color, cool_brick: Color) -> void:
	var tray := Node3D.new()
	tray.name = "PartsDish"
	tray.position = origin
	tray.rotation_degrees.y = angle
	add_child(tray)
	var outer := _material(shell, 0.65)
	var interior := _material(shell.lightened(0.12), 0.77)
	var bottom := MeshInstance3D.new()
	bottom.mesh = _beveled_slab(7.7, length, 0.35, 0.65, 0.1)
	bottom.position.y = 0.175
	bottom.material_override = interior
	tray.add_child(bottom)
	for x in [-3.63, 3.63]:
		_box(tray, "Side", Vector3(0.36, 0.9, length - 0.45), Vector3(x, 0.56, 0), outer)
	for z in [-length * 0.5 + 0.23, length * 0.5 - 0.23]:
		_box(tray, "End", Vector3(7.4, 0.9, 0.36), Vector3(0, 0.56, z), outer)

	_loose_brick(tray, "brick-2x4", Vector3(-0.65, 0.35, -2.75), warm_brick, 20.0)
	_loose_brick(tray, "brick-1x2", Vector3(0.85, 0.35, 1.25), cool_brick, -28.0)
	_loose_brick(tray, "brick-slope-2x2", Vector3(-1.25, 0.35, 3.25), Color("#98a491"), -6.0)

func _loose_brick(tray: Node3D, shape: String, at: Vector3, color: Color, turn: float) -> void:
	var packed := load("res://assets/sourced/kenney_bricks/bevel-hq-%s.glb" % shape) as PackedScene
	if packed == null:
		return
	var brick := packed.instantiate() as Node3D
	brick.position = at
	brick.scale = Vector3.ONE * 12.5
	brick.rotation_degrees.y = turn
	var material := _material(color, 0.54)
	for mesh in brick.find_children("*", "MeshInstance3D", true, false):
		(mesh as MeshInstance3D).material_override = material
	tray.add_child(brick)

func _setup_baseplate() -> void:
	# The canonical connector plane and stud centers remain unchanged.
	baseplate_mesh.mesh = _beveled_slab(32.0, 32.0, 0.2, 0.20, 0.04)
	_plate_material = _material(_plate_color, 0.66)
	_plate_material.metallic_specular = 0.28
	baseplate_mesh.material_override = _plate_material

func _generate_studs() -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = GRID_SIZE * GRID_SIZE
	var stud := CylinderMesh.new()
	stud.top_radius = STUD_RADIUS * 0.94
	stud.bottom_radius = STUD_RADIUS
	stud.height = STUD_HEIGHT
	stud.radial_segments = 12
	stud.rings = 1
	mm.mesh = stud
	_stud_material = _material(_plate_material.albedo_color.lightened(0.06), 0.56)
	_stud_material.metallic_specular = 0.32
	studs_multimesh.material_override = _stud_material
	studs_multimesh.multimesh = mm
	# A thousand individual shadow casters are unnecessary on the baseplate.
	studs_multimesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var half_grid := (GRID_SIZE - 1) * 0.5
	for gx in GRID_SIZE:
		for gz in GRID_SIZE:
			var origin := Vector3((gx - half_grid) * STUD_SPACING, 0.1 + STUD_HEIGHT * 0.5, (gz - half_grid) * STUD_SPACING)
			mm.set_instance_transform(gx * GRID_SIZE + gz, Transform3D(Basis.IDENTITY, origin))

func _setup_room() -> void:
	room_node = Node3D.new()
	room_node.name = "CraftRoom"
	add_child(room_node)
	_setup_floor()
	_setup_walls()
	_setup_window()
	_setup_furniture()

func _setup_floor() -> void:
	var depth := ROOM_FRONT - BACK_WALL + 4.0
	var center_z := (ROOM_FRONT + BACK_WALL) * 0.5
	var wood := _wood(Color("#977d66"), Vector3.FORWARD, 0.68)
	wood.set_shader_parameter("floor_boards", true)
	_box(room_node, "OakFloor", Vector3(ROOM_WIDTH + 3.0, 0.45, depth), Vector3(0, FLOOR_Y - 0.225, center_z), wood)
	var rug := MeshInstance3D.new()
	rug.name = "WovenRug"
	rug.mesh = _beveled_slab(67.0, 53.0, 0.13, 2.3, 0.03)
	rug.position = Vector3(0, FLOOR_Y + 0.065, 1.4)
	rug.material_override = _material(Color("#b46b57"), 0.98)
	room_node.add_child(rug)
	var stripe := _material(Color("#ddaa89"), 0.97)
	for z in [-24.1, -23.0, 25.8, 26.9]:
		_box(room_node, "RugStripe", Vector3(62.0, 0.02, 0.36), Vector3(0, FLOOR_Y + 0.133, z), stripe)

func _setup_walls() -> void:
	var plaster := _material(Color("#deccb7"), 0.95)
	var panel := _material(Color("#6d9084"), 0.86)
	var trim := _material(Color("#e6d4b9"), 0.8)
	var floor_trim := _material(Color("#b4ac96"), 0.8)
	var half_width := ROOM_WIDTH * 0.5
	var room_depth := ROOM_FRONT - BACK_WALL
	var height_center := FLOOR_Y + ROOM_HEIGHT * 0.5
	var center_z := (ROOM_FRONT + BACK_WALL) * 0.5

	for x in [-half_width, half_width]:
		_box(room_node, "SideWall", Vector3(1.6, ROOM_HEIGHT, room_depth), Vector3(x, height_center, center_z), plaster)
		_box(room_node, "SidePaneling", Vector3(0.55, 17.0, room_depth - 2.0), Vector3(x - sign(x), FLOOR_Y + 8.5, center_z), panel)
		_box(room_node, "SideDadoRail", Vector3(0.68, 0.64, room_depth - 2.0), Vector3(x - sign(x) * 1.1, FLOOR_Y + 17.0, center_z), trim)
		_box(room_node, "SideSkirting", Vector3(0.65, 1.4, room_depth - 2.0), Vector3(x - sign(x) * 1.1, FLOOR_Y + 0.7, center_z), floor_trim)

	_box(room_node, "FrontWall", Vector3(ROOM_WIDTH, ROOM_HEIGHT, 1.6), Vector3(0, height_center, ROOM_FRONT), plaster)
	_box(room_node, "FrontPaneling", Vector3(ROOM_WIDTH - 1.6, 17.0, 0.48), Vector3(0, FLOOR_Y + 8.5, ROOM_FRONT - 1.0), panel)
	_box(room_node, "FrontDadoRail", Vector3(ROOM_WIDTH - 1.3, 0.64, 0.68), Vector3(0, FLOOR_Y + 17.0, ROOM_FRONT - 1.1), trim)
	_box(room_node, "FrontSkirting", Vector3(ROOM_WIDTH - 1.3, 1.4, 0.68), Vector3(0, FLOOR_Y + 0.7, ROOM_FRONT - 1.1), floor_trim)

	# Split the wall around a real opening so sunlight and the view pass through it.
	var sill_y := 1.0
	var head_y := 32.0
	var window_left := -49.0
	var window_right := -8.0
	_back_wall_section(-half_width, window_left, FLOOR_Y, FLOOR_Y + ROOM_HEIGHT, plaster)
	_back_wall_section(window_right, half_width, FLOOR_Y, FLOOR_Y + ROOM_HEIGHT, plaster)
	_back_wall_section(window_left, window_right, FLOOR_Y, sill_y, plaster)
	_back_wall_section(window_left, window_right, head_y, FLOOR_Y + ROOM_HEIGHT, plaster)
	_box(room_node, "BackPaneling", Vector3(ROOM_WIDTH - 1.6, 17.0, 0.48), Vector3(0, FLOOR_Y + 8.5, BACK_WALL + 1.0), panel)
	_box(room_node, "BackDadoRail", Vector3(ROOM_WIDTH - 1.3, 0.64, 0.68), Vector3(0, FLOOR_Y + 17.0, BACK_WALL + 1.1), trim)
	_box(room_node, "BackSkirting", Vector3(ROOM_WIDTH - 1.3, 1.4, 0.68), Vector3(0, FLOOR_Y + 0.7, BACK_WALL + 1.1), floor_trim)

func _back_wall_section(left: float, right: float, bottom: float, top: float, material: Material) -> void:
	_box(room_node, "BackWall", Vector3(right - left, top - bottom, 1.6), Vector3((left + right) * 0.5, (bottom + top) * 0.5, BACK_WALL), material)

func _setup_window() -> void:
	var frame := _material(Color("#ead8bb"), 0.75)
	var brass := _material(Color("#8c6743"), 0.55)
	var curtain := _material(Color("#b98e71"), 0.95)
	var curtain_highlight := _material(Color("#cba586"), 0.95)
	var center_x := -28.5
	var wall_z := BACK_WALL + 0.9
	for x in [-49.0, -28.5, -8.0]:
		_box(room_node, "WindowMullion", Vector3(0.78, 31.0, 1.5), Vector3(x, 16.5, wall_z), frame)
	for y in [1.0, 17.8, 32.0]:
		_box(room_node, "WindowCrossbar", Vector3(42.0, 0.72, 1.5), Vector3(center_x, y, wall_z), frame)
	_box(room_node, "DeepWindowSill", Vector3(44.5, 0.64, 3.7), Vector3(center_x, 0.85, wall_z + 0.9), frame)
	_box(room_node, "CurtainRod", Vector3(51.0, 0.34, 0.34), Vector3(center_x, 34.0, wall_z + 2.0), brass)
	for side in [-1.0, 1.0]:
		for i in 5:
			var x: float = center_x + side * (17.8 + i * 1.2)
			var fold := MeshInstance3D.new()
			var fabric := CylinderMesh.new()
			fabric.top_radius = 0.9
			fabric.bottom_radius = 1.16
			fabric.height = 31.7 - (i % 2) * 0.35
			fabric.radial_segments = 10
			fabric.rings = 1
			fold.mesh = fabric
			fold.material_override = curtain if i % 2 == 0 else curtain_highlight
			fold.position = Vector3(x, 17.3, wall_z + 2.0 + (i % 2) * 0.32)
			room_node.add_child(fold)

	# A stylized garden horizon provides depth beyond the actual aperture.
	var distant_green := _material(Color("#91ae92"), 0.95)
	distant_green.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for i in 7:
		var hill := MeshInstance3D.new()
		var hill_shape := SphereMesh.new()
		hill_shape.radius = 12.0
		hill_shape.height = 13.0 + (i % 3) * 5.0
		hill_shape.radial_segments = 12
		hill_shape.rings = 5
		hill.mesh = hill_shape
		hill.position = Vector3(-82.0 + 14.0 * i, -5.0 - (i % 2) * 2.8, -73.0)
		hill.material_override = distant_green
		hill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		room_node.add_child(hill)

func _setup_furniture() -> void:
	var shelf_scale := 47.0
	_furniture("bookcaseOpen", Vector3(27, FLOOR_Y, -34), shelf_scale)
	_furniture("books", Vector3(31.0, FLOOR_Y + 0.13 * shelf_scale, -35.8), 38.0)
	_furniture("books", Vector3(37.8, FLOOR_Y + 0.37 * shelf_scale, -35.7), 34.0)
	_furniture("plantSmall1", Vector3(33.3, FLOOR_Y + 0.61 * shelf_scale, -39), 32.0, 20.0)
	_furniture("lampRoundFloor", Vector3(49, FLOOR_Y, -31), 43.0)
	_furniture("chair", Vector3(-30, FLOOR_Y, -24), 35.0, 65.0)
	_furniture("chairCushion", Vector3(-30, FLOOR_Y, -24), 35.0, 65.0)
	_furniture("pottedPlant", Vector3(-48, FLOOR_Y, -41), 29.0, 15.0)
	_furniture("plantSmall1", Vector3(-22, TABLE_TOP_Y, -17.5), 18.0, 20.0)
	_picture(Vector3(6.0, 12.0, BACK_WALL + 1.5), Vector2(11, 14), Color("#d99d66"))
	_picture(Vector3(18.2, 17.0, BACK_WALL + 1.5), Vector2(10, 10), Color("#719a89"))

func _picture(at: Vector3, size: Vector2, accent: Color) -> void:
	_box(room_node, "PrintFrame", Vector3(size.x, size.y, 0.42), at, _material(Color("#825b41"), 0.65))
	_box(room_node, "PrintPaper", Vector3(size.x - 0.8, size.y - 0.8, 0.12), at + Vector3(0, 0, 0.22), _material(Color("#efe1c9"), 0.9))
	var sun := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = size.x * 0.23
	disc.bottom_radius = disc.top_radius
	disc.height = 0.07
	disc.radial_segments = 32
	disc.rings = 1
	sun.mesh = disc
	sun.rotation_degrees.x = 90.0
	sun.position = at + Vector3(size.x * 0.11, size.y * 0.18, 0.30)
	sun.material_override = _material(accent, 0.9)
	room_node.add_child(sun)
	_box(room_node, "PrintStripe", Vector3(size.x * 0.58, 0.45, 0.08), at + Vector3(0, -size.y * 0.16, 0.30), _material(accent.darkened(0.28), 0.92))

func _furniture(asset: String, at: Vector3, scale_factor: float, turn: float = 0.0) -> void:
	var packed := load("res://assets/sourced/kenney_furniture/%s.glb" % asset) as PackedScene
	if packed == null:
		return
	var prop := packed.instantiate() as Node3D
	prop.position = at
	prop.scale = Vector3.ONE * scale_factor
	prop.rotation_degrees.y = turn
	room_node.add_child(prop)

func _box(parent: Node3D, label: String, size: Vector3, at: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = label
	var box := BoxMesh.new()
	box.size = size
	instance.mesh = box
	instance.position = at
	instance.material_override = material
	parent.add_child(instance)
	return instance

func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material

func _wood(color: Color, grain_axis: Vector3, roughness: float) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = WOOD_GRAIN
	material.set_shader_parameter("wood", color)
	material.set_shader_parameter("grain_axis", grain_axis)
	material.set_shader_parameter("matte", roughness)
	return material

## Rounded footprint with a small edge chamfer, keeping the two horizontal faces planar.
func _beveled_slab(width: float, depth: float, height: float, radius: float, bevel: float) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array[PackedVector3Array] = []
	for i in 4:
		var inset := bevel if i == 0 or i == 3 else 0.0
		var y := height * 0.5
		var levels := [-y, -y + bevel, y - bevel, y]
		var ring := PackedVector3Array()
		for corner in 4:
			var corner_angle := corner * PI * 0.5
			var center := Vector2(sign(cos(corner_angle + PI * 0.25)) * (width * 0.5 - radius), sign(sin(corner_angle + PI * 0.25)) * (depth * 0.5 - radius))
			for segment in 5:
				var angle := corner_angle + segment * PI / 8.0
				var point := center + Vector2(cos(angle), sin(angle)) * (radius - inset)
				ring.append(Vector3(point.x, levels[i], point.y))
		rings.append(ring)

	for i in 3:
		for j in rings[i].size():
			var next := (j + 1) % rings[i].size()
			_triangle(surface, rings[i][j], rings[i + 1][next], rings[i + 1][j])
			_triangle(surface, rings[i][j], rings[i][next], rings[i + 1][next])
	for j in rings[3].size():
		var next := (j + 1) % rings[3].size()
		_triangle(surface, Vector3(0, height * 0.5, 0), rings[3][j], rings[3][next])
		_triangle(surface, Vector3(0, -height * 0.5, 0), rings[0][next], rings[0][j])
	surface.generate_normals()
	return surface.commit()

func _triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	surface.set_smooth_group(-1)
	surface.add_vertex(a)
	surface.add_vertex(b)
	surface.add_vertex(c)

static func grid_to_world(gx: int, gz: int, z_plate: int, dims_studs: Array = [1, 3, 1], rot_step: int = 0) -> Vector3:
	return PlacementRules.grid_to_world(gx, gz, z_plate, dims_studs, rot_step)

static func world_to_grid(world_pos: Vector3, dims_studs: Array = [1, 3, 1], rot_step: int = 0) -> Vector2i:
	return PlacementRules.world_to_grid(world_pos, dims_studs, rot_step)
