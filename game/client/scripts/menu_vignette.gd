extends SubViewportContainer

## Opening tableaux rendered with the actual tabletop and inventory meshes.
## Static viewports sleep between brief camera moves and scene changes.
@export_enum("Workshop", "Solo", "Pass", "Online") var composition: int = 0
@export var opening: bool = false

const Figure = preload("res://client/scripts/minifigure_model.gd")

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
var _display: Node3D
var _wave_arm: Node3D
var _pack_id := ""
var _motion: Tween
var _camera_nudge := 0.0
var _motion_enabled := false

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
	_motion_enabled = not SettingsManager.new().reduced_motion
	_frame()
	if opening and _motion_enabled:
		_camera_nudge = 1.0
		_frame()
		_move_camera(0.0, 1.5)

func set_highlighted(active: bool) -> void:
	if not _camera or not _motion_enabled:
		return
	_move_camera(1.0 if active else 0.0, 0.24)

func _move_camera(to: float, seconds: float) -> void:
	if _motion:
		_motion.kill()
	_motion = create_tween()
	_motion.tween_method(_set_nudge, _camera_nudge, to, seconds).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _set_nudge(amount: float) -> void:
	_camera_nudge = amount
	if _wave_arm:
		_wave_arm.rotation.x = 0.7 + sin(amount * TAU * 1.3) * 0.30
	_frame()

func _frame() -> void:
	if not _preview or not is_visible_in_tree():
		return
	if composition == 0:
		var wide := size.x / maxf(size.y, 1.0) > 1.35
		_camera.fov = 39.0
		var position := Vector3(23, 18, 29) if wide else Vector3(28, 20, 35)
		_camera.position = position + Vector3(3.9, 1.5, 2.7) * _camera_nudge
		_camera.look_at(Vector3(0, 2.0, -1.0))
	else:
		_camera.fov = 38.0
		_camera.position = Vector3(5.6, 5.8, 7.7) + Vector3(0.6, -0.42, -0.30) * _camera_nudge
		_camera.look_at(Vector3(0, 0.96, 0.45))
	_preview.render_target_update_mode = SubViewport.UPDATE_ONCE

func show_pack_palette(pack_id: String) -> void:
	if not _table or _pack_id == pack_id:
		return
	_pack_id = pack_id
	if _display:
		_display.hide()
		_display.queue_free()
	_display = Node3D.new()
	_world.add_child(_display)
	var plate_color := Color("#668475")
	match pack_id:
		"cabin":
			plate_color = Color("#80906c")
			_build_cabin()
		"galaxy":
			plate_color = Color("#656e89")
			_build_hangar()
		"heroes":
			plate_color = Color("#7d7087")
			_build_headquarters()
		"castle":
			plate_color = Color("#73876d")
			_build_keep()
		_:
			plate_color = Color("#577e86")
			_build_harbour()
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

	if opening:
		_display = Node3D.new()
		_world.add_child(_display)
		_build_cabin()
		var figure := Figure.new()
		figure.position = Vector3(5.1, 0.10, 7.4)
		figure.rotation.y = PI + 0.63
		_display.add_child(figure)
		_wave_arm = figure.get_node("RightArm") as Node3D
		_wave_arm.rotation.x = 0.7
	else:
		show_pack_palette("harbour")

func _build_cabin() -> void:
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

func _build_harbour() -> void:
	for x in [-5.5, -3.5, -1.5]:
		_part("plate_2x8", CREAM, Vector3(x, 0.10, 1.0))
	for layer in range(6):
		var color := CREAM if layer % 2 == 0 else CORAL
		_part("brick_2x2", color, Vector3(-3.5, 0.5 + layer * 1.2, -2.0))
	_part("plate_4x4", CORAL, Vector3(-3.5, 7.7, -2.0))
	_part("brick_2x2", GOLD, Vector3(-3.5, 8.1, -2.0))
	_part("plate_4x4", CORAL, Vector3(-3.5, 9.3, -2.0))
	_part("brick_1x2", CORAL, Vector3(3.0, 0.10, 5.0))
	_part("plate_2x6", CORAL, Vector3(3.5, 0.10, 2.0))
	_part("brick_2x4", DARK_TEAL, Vector3(3.5, 0.50, 2.0))
	_part("brick_1x2", CREAM, Vector3(3.0, 1.70, 1.0))
	_part("plate_2x2", GOLD, Vector3(3.5, 1.70, 3.0))
	for offset in [-3.0, 3.0]:
		_part("tile_1x4", BLUE, Vector3(8.0, 0.10, offset), 1)

func _build_hangar() -> void:
	for x in [-4.0, 4.0]:
		_part("plate_4x8", DARK_TEAL, Vector3(x, 0.10, 0.0), 1)
	for z in [-3.0, 1.0]:
		_part("brick_2x4", CREAM, Vector3(0.0, 0.5, z))
	_part("slope_2x4_45", BLUE, Vector3(0, 1.7, -1.5))
	_part("plate_2x6", CREAM, Vector3(-4.0, 0.5, 1.0), 1)
	_part("plate_2x6", CREAM, Vector3(4.0, 0.5, 1.0), 1)
	for x in [-4.5, 4.5]:
		_part("brick_1x4", BLUE, Vector3(x, 0.9, 0.0))
		_part("brick_round_1x1", GOLD, Vector3(x, 0.9, 2.5))
	_part("galaxy_wing_left_2x3", CORAL, Vector3(-4.0, 2.1, 0.5))
	_part("galaxy_wing_right_2x3", CORAL, Vector3(4.0, 2.1, 0.5))
	for x in [-3.0, -1.0, 1.0, 3.0]:
		_part("tile_1x2", GOLD, Vector3(x, 0.1, 5.5), 1)

func _build_headquarters() -> void:
	for layer in range(4):
		for x in [-4.0, 4.0]:
			var y := 0.10 + layer * 1.2
			_part("brick_2x4", BLUE if layer % 2 == 0 else CREAM, Vector3(x, y, -0.5))
			_part("brick_2x4", BLUE if layer % 2 == 0 else CREAM, Vector3(x, y, 3.5))
	_part("brick_2x8", CORAL, Vector3(0, 4.90, -0.5), 1)
	_part("brick_2x8", CORAL, Vector3(0, 4.90, 1.5), 1)
	_part("brick_2x8", CORAL, Vector3(0, 4.90, 3.5), 1)
	_part("heroes_reactor_dish_2x2", GOLD, Vector3(0, 6.10, 0.5))
	_part("brick_2x2", DARK_TEAL, Vector3(-3.0, 0.10, 6.5))
	_part("brick_2x2", DARK_TEAL, Vector3(3.0, 0.10, 6.5))
	_part("tile_2x2", CREAM, Vector3(0, 0.10, 7.0))

func _build_keep() -> void:
	var stone := Color("#b9b6a7")
	for layer in range(5):
		var y := 0.10 + layer * 1.2
		for x in [-5.0, 5.0]:
			_part("brick_2x4", stone if layer % 2 == 0 else CREAM, Vector3(x, y, 1.5))
	for x in [-5.0, 5.0]:
		_part("plate_4x4", stone, Vector3(x, 6.10, 1.5))
		for z in [0.0, 3.0]:
			for offset in [-1.5, 1.5]:
				_part("brick_1x1", stone, Vector3(x + offset, 6.5, z))
		_part("brick_round_1x1", CORAL, Vector3(x + 0.5, 6.50, 0.9))
	for z in [1.0, 2.0]:
		_part("brick_1x8", stone, Vector3(0, 3.7, z), 1)
		_part("brick_1x8", stone, Vector3(0, 4.9, z), 1)
	_part("castle_spindled_fence_1x4", stone, Vector3(0, 6.1, 2.0), 1)
	_part("tile_2x2", CREAM, Vector3(0, 0.10, 5.0))

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
	(_display if _display else _world).add_child(part)
