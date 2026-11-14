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
const ROOM_HEIGHT: float = 102.0
const WOOD_GRAIN = preload("res://client/shaders/workshop_wood.gdshader")
const WINDOW_SKY = preload("res://client/shaders/workshop_sky.gdshader")
const WINDOW_RAIN = preload("res://client/shaders/workshop_rain.gdshader")

@export var workshop_dog_enabled := false

@onready var table_mesh: MeshInstance3D = $TableMesh
@onready var baseplate_mesh: MeshInstance3D = $BaseplateMesh
@onready var studs_multimesh: MultiMeshInstance3D = $StudsMultiMesh

var room_node: Node3D
var _dog: WorkshopDog
var _table_wood: ShaderMaterial
var _plate_material: StandardMaterial3D
var _stud_material: StandardMaterial3D
var _table_color := Color("#9e6842")
var _plate_color := Color("#668475")
var _wall_color := Color("#deccb7")
var _panel_color := Color("#6d9084")
var _rug_color := Color("#b46b57")
var _wall_material: StandardMaterial3D
var _panel_material: StandardMaterial3D
var _rug_material: StandardMaterial3D
var _window_sky: ShaderMaterial
var _rain_layers: Array[MeshInstance3D] = []
var _garden_green: StandardMaterial3D
var _lamp_bulb: StandardMaterial3D
var _workshop_lamp: OmniLight3D
var _desk_lamp: OmniLight3D
var _desk_diffuser: StandardMaterial3D
var _atmosphere := Vector4(1.0, 0.0, 0.0, 0.0)

func _ready() -> void:
	_setup_table()
	_setup_baseplate()
	_generate_studs()
	_setup_room()
	apply_atmosphere(_atmosphere.x, _atmosphere.y, _atmosphere.z, _atmosphere.w)

func set_palette(table_color: Color, plate_color: Color) -> void:
	_table_color = table_color
	_plate_color = plate_color
	if _table_wood:
		_table_wood.set_shader_parameter("wood", table_color)
	if _plate_material and _stud_material:
		_plate_material.albedo_color = plate_color
		_stud_material.albedo_color = plate_color.lightened(0.06)

func set_room_palette(wall_color: Color, panel_color: Color, rug_color: Color) -> void:
	_wall_color = wall_color
	_panel_color = panel_color
	_rug_color = rug_color
	if _wall_material and _panel_material and _rug_material:
		_wall_material.albedo_color = _wall_color
		_panel_material.albedo_color = _panel_color
		_rug_material.albedo_color = _rug_color

func set_reduced_motion(enabled: bool) -> void:
	if _dog:
		_dog.set_reduced_motion(enabled)

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
	_setup_ceiling()
	_setup_window()
	_setup_window_weather()
	_setup_furniture()
	_setup_desk_lamp()
	if workshop_dog_enabled:
		_dog = WorkshopDog.new()
		_dog.name = "WorkshopDog"
		_setup_dog_stool(WorkshopDog.CLIMB_LEFT)
		_setup_dog_stool(WorkshopDog.CLIMB_RIGHT)
		_dog.configure_surfaces(FLOOR_Y, TABLE_TOP_Y)
		room_node.add_child(_dog)

func _setup_dog_stool(location: Vector2) -> void:
	var frame := _wood(Color("#775440"), Vector3.UP, 0.68)
	var cushion := _material(Color("#72837c"), 0.93)
	var seat := MeshInstance3D.new()
	seat.name = "WorkshopStool"
	seat.mesh = _beveled_slab(10.3, 9.8, 1.3, 1.2, 0.24)
	seat.material_override = cushion
	seat.position = Vector3(location.x, FLOOR_Y + WorkshopDog.STOOL_HEIGHT - 0.65, location.y)
	room_node.add_child(seat)
	for x in [-3.7, 3.7]:
		for z in [-3.5, 3.5]:
			var leg := _box(room_node, "WorkshopStoolLeg", Vector3(1.36, WorkshopDog.STOOL_HEIGHT - 0.9, 1.36), Vector3(location.x + x, FLOOR_Y + (WorkshopDog.STOOL_HEIGHT - 0.9) * 0.5, location.y + z), frame)
			leg.rotation_degrees.z = signf(x) * 5.0

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
	_rug_material = _material(_rug_color, 0.98)
	rug.material_override = _rug_material
	room_node.add_child(rug)
	var stripe := _material(Color("#ddaa89"), 0.97)
	for z in [-24.1, -23.0, 25.8, 26.9]:
		_box(room_node, "RugStripe", Vector3(62.0, 0.02, 0.36), Vector3(0, FLOOR_Y + 0.133, z), stripe)

func _setup_walls() -> void:
	_wall_material = _material(_wall_color, 0.95)
	var plaster := _wall_material
	_panel_material = _material(_panel_color, 0.86)
	var panel := _panel_material
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

func _setup_ceiling() -> void:
	var plaster := _material(Color("#d5c7b6"), 0.94)
	var depth := ROOM_FRONT - BACK_WALL + 1.8
	var center_z := (ROOM_FRONT + BACK_WALL) * 0.5
	var ceiling_y := FLOOR_Y + ROOM_HEIGHT
	_box(room_node, "WorkshopCeiling", Vector3(ROOM_WIDTH + 1.8, 1.4, depth), Vector3(0, ceiling_y + 0.7, center_z), plaster)
	var trim := _material(Color("#b59b81"), 0.85)
	for z in [BACK_WALL + 0.85, ROOM_FRONT - 0.85]:
		_box(room_node, "CeilingTrim", Vector3(ROOM_WIDTH, 1.5, 1.6), Vector3(0, ceiling_y - 0.75, z), trim)
	for x in [-ROOM_WIDTH * 0.5 + 0.85, ROOM_WIDTH * 0.5 - 0.85]:
		_box(room_node, "CeilingTrim", Vector3(1.6, 1.5, depth), Vector3(x, ceiling_y - 0.75, center_z), trim)

	# The wall-mounted fixture keeps the board visible from overhead.
	var lamp_position := Vector3(21.0, 3.5, BACK_WALL + 5.8)
	var bronze := _material(Color("#6d5541"), 0.56)
	_box(room_node, "LampMount", Vector3(2.6, 4.8, 0.75), Vector3(lamp_position.x, lamp_position.y + 2.6, BACK_WALL + 1.2), bronze)
	_box(room_node, "LampArm", Vector3(0.62, 0.62, 4.8), Vector3(lamp_position.x, lamp_position.y + 2.6, lamp_position.z - 1.9), bronze)
	var shade := MeshInstance3D.new()
	var shade_mesh := CylinderMesh.new()
	shade_mesh.top_radius = 1.07
	shade_mesh.bottom_radius = 2.45
	shade_mesh.height = 1.8
	shade_mesh.radial_segments = 24
	shade.mesh = shade_mesh
	shade.position = lamp_position + Vector3.UP * 1.65
	shade.material_override = _material(Color("#b88459"), 0.63)
	room_node.add_child(shade)
	_lamp_bulb = _material(Color("#f6dfbc"), 0.55)
	_lamp_bulb.emission_enabled = true
	_lamp_bulb.emission = Color("#ffc174")
	_lamp_bulb.emission_energy_multiplier = 0.0
	_box(room_node, "LampDiffuser", Vector3(2.5, 0.18, 2.5), lamp_position + Vector3.UP * 0.75, _lamp_bulb)
	_workshop_lamp = OmniLight3D.new()
	_workshop_lamp.name = "WorkshopLamp"
	_workshop_lamp.position = lamp_position - Vector3.UP * 0.25
	_workshop_lamp.light_color = Color("#ffce95")
	_workshop_lamp.light_energy = 0.0
	_workshop_lamp.omni_range = 74.0
	_workshop_lamp.omni_attenuation = 1.2
	room_node.add_child(_workshop_lamp)

func _setup_desk_lamp() -> void:
	# Small practical light, clear of the plate, inventory, and overhead camera.
	var finish := _material(Color("#496861"), 0.5)
	var hardware := _material(Color("#73614b"), 0.6)
	var foot := Vector3(23.4, TABLE_TOP_Y, -15.6)
	var elbow := foot + Vector3(0, 8.7, 0)
	var head := elbow + Vector3(-3.5, 0, 2.4)
	_add_lamp_cylinder("DeskLampBase", foot + Vector3.UP * 0.25, 2.0, 2.0, 0.5, finish)
	_add_lamp_cylinder("DeskLampStem", foot + Vector3.UP * 4.55, 0.19, 0.19, 8.3, hardware)
	var arm := _add_lamp_cylinder("DeskLampArm", (elbow + head) * 0.5, 0.16, 0.16, elbow.distance_to(head), hardware)
	arm.quaternion = Quaternion(Vector3.UP, (head - elbow).normalized())
	_add_lamp_cylinder("DeskLampShade", head - Vector3.UP * 0.73, 0.75, 1.73, 1.46, finish)
	_desk_diffuser = _material(Color("#f1ddc0"), 0.69)
	_desk_diffuser.emission_enabled = true
	_desk_diffuser.emission = Color("#ffca8c")
	_desk_diffuser.emission_energy_multiplier = 0.0
	_add_lamp_cylinder("DeskLampDiffuser", head - Vector3.UP * 1.49, 1.48, 1.48, 0.10, _desk_diffuser)
	_desk_lamp = OmniLight3D.new()
	_desk_lamp.name = "DeskLamp"
	_desk_lamp.position = head - Vector3.UP * 1.9
	_desk_lamp.light_color = Color("#ffca8c")
	_desk_lamp.light_energy = 0.0
	_desk_lamp.omni_range = 49.0
	_desk_lamp.omni_attenuation = 1.35
	room_node.add_child(_desk_lamp)

func _add_lamp_cylinder(label: String, at: Vector3, top_radius: float, bottom_radius: float, height: float, material: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = 20
	var part := MeshInstance3D.new()
	part.name = label
	part.mesh = mesh
	part.material_override = material
	part.position = at
	room_node.add_child(part)
	return part

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
	_garden_green = _material(Color("#91ae92"), 0.95)
	_garden_green.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for i in 7:
		var hill := MeshInstance3D.new()
		var hill_shape := SphereMesh.new()
		hill_shape.radius = 12.0
		hill_shape.height = 13.0 + (i % 3) * 5.0
		hill_shape.radial_segments = 12
		hill_shape.rings = 5
		hill.mesh = hill_shape
		hill.position = Vector3(-82.0 + 14.0 * i, -5.0 - (i % 2) * 2.8, -73.0)
		hill.material_override = _garden_green
		hill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		room_node.add_child(hill)

func _setup_window_weather() -> void:
	_window_sky = ShaderMaterial.new()
	_window_sky.shader = WINDOW_SKY
	_weather_quad("GardenSky", Vector3(-28.5, 19, -91.0), Vector2(220, 124), _window_sky)
	for i in 2:
		var material := ShaderMaterial.new()
		material.shader = WINDOW_RAIN
		material.set_shader_parameter("layer_seed", float(i))
		var layer := _weather_quad("OutdoorRain", Vector3(-28.5, 16.5, BACK_WALL - 2.0 - i * 9.0), Vector2(73, 54), material)
		layer.visible = false
		_rain_layers.append(layer)

func _weather_quad(label: String, at: Vector3, size: Vector2, material: Material) -> MeshInstance3D:
	var plane := QuadMesh.new()
	plane.size = size
	var instance := MeshInstance3D.new()
	instance.name = label
	instance.mesh = plane
	instance.position = at
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	room_node.add_child(instance)
	return instance

func apply_atmosphere(daylight: float, sunset: float, rain: float, rain_time: float) -> void:
	_atmosphere = Vector4(daylight, sunset, rain, rain_time)
	if not _window_sky:
		return
	_window_sky.set_shader_parameter("daylight", daylight)
	_window_sky.set_shader_parameter("sunset", sunset)
	_window_sky.set_shader_parameter("rain", rain)
	var garden_day := Color("#8eab8e").lerp(Color("#718483"), rain)
	var garden_night := Color("#263e4a")
	_garden_green.albedo_color = garden_night.lerp(garden_day, daylight)
	for layer in _rain_layers:
		layer.visible = rain > 0.0
		if layer.visible:
			(layer.material_override as ShaderMaterial).set_shader_parameter("rain", rain)
	set_rain_time(rain_time)
	# The practical lights gradually take over as daylight softens.
	var lamplight := (1.0 - smoothstep(0.13, 0.90, daylight)) * 1.05
	lamplight += smoothstep(0.10, 0.92, rain) * 0.40
	_workshop_lamp.light_energy = lamplight * 1.32
	_desk_lamp.light_energy = lamplight * 1.4
	_desk_diffuser.emission_energy_multiplier = lamplight * 1.08
	_lamp_bulb.emission_energy_multiplier = lamplight * 0.92

func set_rain_time(rain_time: float) -> void:
	_atmosphere.w = rain_time
	for layer in _rain_layers:
		if layer.visible:
			(layer.material_override as ShaderMaterial).set_shader_parameter("animation_time", rain_time)

func _setup_furniture() -> void:
	var furnishings := preload("res://client/scripts/workshop_furnishings.gd").new()
	furnishings.name = "WorkshopFurnishings"
	room_node.add_child(furnishings)
	furnishings.furnish(FLOOR_Y, BACK_WALL, ROOM_FRONT, ROOM_WIDTH * 0.5)
	_furniture("books", Vector3(39, FLOOR_Y + 34.0, -42), 34.0)
	_furniture("plantSmall1", Vector3(25.2, FLOOR_Y + 11.4, -39), 29.0, 20.0)
	_furniture("lampRoundFloor", Vector3(54.0, FLOOR_Y, -29), 43.0)
	_furniture("chair", Vector3(-51, FLOOR_Y, -29), 35.0, 65.0)
	_furniture("chairCushion", Vector3(-51, FLOOR_Y, -29), 35.0, 65.0)
	_furniture("pottedPlant", Vector3(-48, FLOOR_Y, -41), 29.0, 15.0)
	_furniture("plantSmall1", Vector3(-22, TABLE_TOP_Y, -17.5), 18.0, 20.0)

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
