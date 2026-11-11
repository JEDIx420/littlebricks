extends SubViewportContainer

## One-frame still life rendered with the actual tabletop and inventory meshes.
## The isolated world is never added to a building session.
@export_enum("Workshop", "Solo", "Pass", "Online") var composition: int = 0

const CREAM := Color("#f1dcae")
const CORAL := Color("#bd634e")
const GOLD := Color("#e3a84a")
const BLUE := Color("#568898")
const TEAL := Color("#548779")
const DARK_TEAL := Color("#39635f")

var _preview: SubViewport
var _world: Node3D
var _camera: Camera3D
var _catalog := PartCatalog.new()
var _table: TableView

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	stretch = true
	stretch_shrink = 1
	if DisplayServer.get_name() == "headless" or not _catalog.load_catalog():
		return

	_preview = SubViewport.new()
	_preview.world_3d = World3D.new()
	_preview.disable_3d = false
	_preview.gui_disable_input = true
	_preview.msaa_3d = Viewport.MSAA_2X
	add_child(_preview)
	_world = Node3D.new()
	_preview.add_child(_world)
	_build_lighting()
	_camera = Camera3D.new()
	_world.add_child(_camera)
	_camera.current = true
	if composition == 0:
		_build_workshop()
	else:
		_build_mode_still_life()
	resized.connect(_frame)
	visibility_changed.connect(_frame)
	_frame()

func _frame() -> void:
	if not _preview or not is_visible_in_tree():
		return
	if composition == 0:
		var wide := size.x / maxf(size.y, 1.0) > 1.35
		_camera.fov = 39.0
		_camera.position = Vector3(23, 18, 29) if wide else Vector3(28, 20, 35)
		_camera.look_at(Vector3(0, 2.0, -1.5))
	else:
		_camera.fov = 38.0
		_camera.position = Vector3(5.6, 5.8, 7.7)
		_camera.look_at(Vector3(0, 0.96, 0.45))
	_preview.render_target_update_mode = SubViewport.UPDATE_ONCE

func show_cabin_palette(cabin: bool) -> void:
	if not _table:
		return
	var plate_color := Color("#80906c") if cabin else Color("#668475")
	_table.set_palette(Color("#9e6842"), plate_color)
	_frame()

func _build_lighting() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#e9ddc6")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.86, 0.92, 1.0)
	environment.ambient_light_energy = 0.32
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	_world.add_child(world_environment)

	var sunlight := DirectionalLight3D.new()
	sunlight.rotation_degrees = Vector3(-41, -36, 0)
	sunlight.light_color = Color(1, 0.88, 0.72)
	sunlight.light_energy = 0.63
	sunlight.shadow_enabled = true
	sunlight.shadow_opacity = 0.72
	sunlight.directional_shadow_max_distance = 75
	_world.add_child(sunlight)

	var bounce := DirectionalLight3D.new()
	bounce.rotation_degrees = Vector3(-24, 129, 0)
	bounce.light_color = Color(0.83, 0.91, 1.0)
	bounce.light_energy = 0.14
	_world.add_child(bounce)

func _build_workshop() -> void:
	_table = TableView.new()
	var table_mesh := MeshInstance3D.new()
	table_mesh.name = "TableMesh"
	_table.add_child(table_mesh)
	var plate_mesh := MeshInstance3D.new()
	plate_mesh.name = "BaseplateMesh"
	_table.add_child(plate_mesh)
	var studs := MultiMeshInstance3D.new()
	studs.name = "StudsMultiMesh"
	_table.add_child(studs)
	_world.add_child(_table)

	# The sample cabin uses the same units and standard parts as the builder.
	for x in [-4.0, 0.0, 4.0]:
		_part("plate_4x8", CREAM, Vector3(x, 0.1, 0.0))
	for layer in range(4):
		var y := 0.5 + layer * 1.2
		var paint := DARK_TEAL if layer == 0 else CREAM
		for x in [-4.5, -0.5, 3.5]:
			_part("brick_1x4", paint, Vector3(x, y, -3.5), 1)
		for x in [-5.5, 5.5]:
			_part("brick_1x4", paint, Vector3(x, y, -1.0))
			_part("brick_1x2", paint, Vector3(x, y, 2.0))
		for x in [-4.0, 4.0]:
			_part("brick_1x2", paint, Vector3(x, y, 3.5), 1)
		# Open front windows and doorway sit between the framed columns.
		if layer == 0 or layer == 3:
			for x in [-2.0, 2.0]:
				_part("brick_1x2", TEAL if layer == 0 else CREAM, Vector3(x, y, 3.5), 1)
		if layer == 3:
			_part("brick_1x2", CREAM, Vector3(0.0, y, 3.5), 1)

	for course in range(3):
		var z := 3.0 - float(course)
		var y := 5.3 + float(course) * 1.2
		for x in [-4.0, 0.0, 4.0]:
			_part("brick_2x4", CORAL, Vector3(x, y, z), 1)
			_part("brick_2x4", CORAL, Vector3(x, y, -z), 1)
	for x in [-4.0, 0.0, 4.0]:
		_part("tile_1x4", GOLD, Vector3(x, 8.9, 0.5), 1)
		_part("tile_1x4", GOLD, Vector3(x, 8.9, -0.5), 1)
	_part("brick_2x2", DARK_TEAL, Vector3(-3.0, 7.7, -2.0))
	_part("brick_2x2", DARK_TEAL, Vector3(-3.0, 8.9, -2.0))
	_part("tile_2x2", CREAM, Vector3(-3.0, 10.1, -2.0))

	for x in [-2.0, 2.0]:
		_part("plate_2x2", TEAL, Vector3(x, 0.1, 5.0))
		_part("flower_1x1", GOLD, Vector3(x - 0.5, 0.5, 5.5))
	_part("tile_2x2", CREAM, Vector3(0, 0.1, 5))
	_part("tile_2x2", CREAM, Vector3(0, 0.1, 8))
	_part("brick_2x4", BLUE, Vector3(8.0, 0.1, 5.0), 1)
	_part("brick_1x4", GOLD, Vector3(-7.5, 0.1, 3.0))
	_part("brick_round_1x1", CORAL, Vector3(7.5, 0.1, 8.5))
	_part("brick_2x2", CREAM, Vector3(-6.0, 0.1, 7.0))

func _build_mode_still_life() -> void:
	var base := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(100, 0.4, 100)
	base.mesh = mesh
	base.position.y = -0.2
	var material := StandardMaterial3D.new()
	var backdrops: Array[Color] = [Color("#c78865"), Color("#719b8e"), Color("#c7a359")]
	material.albedo_color = backdrops[composition - 1]
	material.roughness = 0.84
	base.material_override = material
	_world.add_child(base)

	match composition:
		1:
			_part("brick_2x4", CORAL, Vector3(0.0, 0.0, 0.0), 1)
			_part("brick_2x2", CREAM, Vector3(-0.5, 1.2, 0.0))
			_part("brick_1x2", TEAL, Vector3(1.5, 0.0, 2.0), 1)
		2:
			_part("brick_2x4", BLUE, Vector3(-1.0, 0.0, 0.0))
			_part("brick_2x4", GOLD, Vector3(1.0, 0.0, 0.0))
			_part("brick_2x4", CREAM, Vector3(0.0, 1.2, 0.0), 1)
			_part("brick_1x2", CORAL, Vector3(-1.5, 0.0, 3.0), 1)
		3:
			_part("brick_2x2", TEAL, Vector3(-1.5, 0.0, 0.0))
			_part("brick_2x2", TEAL, Vector3(-1.5, 1.2, 0.0))
			_part("brick_2x2", CORAL, Vector3(1.5, 0.0, 0.0))
			_part("brick_2x2", CORAL, Vector3(1.5, 1.2, 0.0))
			_part("brick_2x4", CREAM, Vector3(0.0, 2.4, 0.0), 1)
			_part("brick_1x2", BLUE, Vector3(1.5, 0.0, 2.5), 1)

func _part(part_id: String, color: Color, location: Vector3, turn: int = 0) -> void:
	var definition := _catalog.get_part(part_id)
	if definition.is_empty():
		return
	var part := PartMeshBuilder.build_part_node(definition, color)
	part.position = location
	part.rotation.y = turn * PI / 2.0
	_world.add_child(part)
