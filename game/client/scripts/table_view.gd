extends Node3D
class_name TableView

## TableView manages the 3D tabletop, 32x32 stud baseplate, cozy craft room, and visual materials.
## Features a solid wooden table, bounding room walls, floor, sunny window, and sourced furniture props (LB-070).

const GRID_SIZE: int = 32
const STUD_SPACING: float = 1.0
const STUD_RADIUS: float = 0.3
const STUD_HEIGHT: float = 0.18
const PLATE_HEIGHT: float = 0.4 # In Godot units, 1 plate = 0.4

const FLOOR_Y: float = -21.6
const TABLE_TOP_Y: float = 0.0
const TABLE_HEIGHT: float = 21.6

@onready var table_mesh: MeshInstance3D = $TableMesh
@onready var baseplate_mesh: MeshInstance3D = $BaseplateMesh
@onready var studs_multimesh: MultiMeshInstance3D = $StudsMultiMesh

var room_node: Node3D = null

func _ready() -> void:
	_setup_table()
	_setup_baseplate()
	_generate_studs()
	_setup_room()

func _setup_table() -> void:
	# 1. Main Solid Wooden Tabletop (56 studs wide x 44 studs deep x 1.6 thickness)
	# Center is at (0, -0.8, 0) so top surface aligns at y = 0.0
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(56.0, 1.6, 44.0)
	table_mesh.mesh = box
	table_mesh.position = Vector3(0, -0.8, 0)
	
	var table_mat: StandardMaterial3D = StandardMaterial3D.new()
	table_mat.albedo_color = Color(0.52, 0.31, 0.16) # Warm golden honey oak / walnut wood
	table_mat.roughness = 0.38
	table_mat.metallic = 0.02
	table_mat.metallic_specular = 0.45
	table_mesh.material_override = table_mat
	
	# Beveled lower chamfer edge / apron under tabletop
	var chamfer: MeshInstance3D = MeshInstance3D.new()
	chamfer.name = "TableBevel"
	var chamfer_box: BoxMesh = BoxMesh.new()
	chamfer_box.size = Vector3(54.6, 0.4, 42.6)
	chamfer.mesh = chamfer_box
	chamfer.position = Vector3(0, -1.8, 0)
	var chamfer_mat: StandardMaterial3D = StandardMaterial3D.new()
	chamfer_mat.albedo_color = Color(0.42, 0.24, 0.12)
	chamfer_mat.roughness = 0.45
	chamfer.material_override = chamfer_mat
	table_mesh.add_child(chamfer)
	
	# 4 Sturdy Wooden Legs extending to floor at y = -21.6
	var leg_height: float = 20.0
	var leg_y: float = -1.6 - (leg_height * 0.5) # Center at y = -11.6
	var leg_mat: StandardMaterial3D = StandardMaterial3D.new()
	leg_mat.albedo_color = Color(0.44, 0.26, 0.13)
	leg_mat.roughness = 0.42
	
	var leg_coords = [
		Vector3(-24.5, leg_y, -18.5),
		Vector3(24.5, leg_y, -18.5),
		Vector3(-24.5, leg_y, 18.5),
		Vector3(24.5, leg_y, 18.5)
	]
	
	for idx in range(leg_coords.size()):
		var leg: MeshInstance3D = MeshInstance3D.new()
		leg.name = "TableLeg_%d" % idx
		var leg_mesh: BoxMesh = BoxMesh.new()
		leg_mesh.size = Vector3(2.6, leg_height, 2.6)
		leg.mesh = leg_mesh
		leg.position = leg_coords[idx]
		leg.material_override = leg_mat
		table_mesh.add_child(leg)
		
	# Table Apron Stretchers (under-table wooden framing)
	var apron_mat: StandardMaterial3D = StandardMaterial3D.new()
	apron_mat.albedo_color = Color(0.40, 0.22, 0.11)
	apron_mat.roughness = 0.5
	
	# Long stretchers (Z = +-18.5)
	for sz in [-18.5, 18.5]:
		var apron_x: MeshInstance3D = MeshInstance3D.new()
		var a_box: BoxMesh = BoxMesh.new()
		a_box.size = Vector3(46.0, 1.8, 1.2)
		apron_x.mesh = a_box
		apron_x.position = Vector3(0, -2.5, sz)
		apron_x.material_override = apron_mat
		table_mesh.add_child(apron_x)
		
	# Short stretchers (X = +-24.5)
	for sx in [-24.5, 24.5]:
		var apron_z: MeshInstance3D = MeshInstance3D.new()
		var a_box_z: BoxMesh = BoxMesh.new()
		a_box_z.size = Vector3(1.2, 1.8, 34.0)
		apron_z.mesh = a_box_z
		apron_z.position = Vector3(sx, -2.5, 0)
		apron_z.material_override = apron_mat
		table_mesh.add_child(apron_z)

func _setup_baseplate() -> void:
	# 32x32 green baseplate resting at y = 0.0 with 0.2 thickness (top surface at y = 0.1)
	var plate: BoxMesh = BoxMesh.new()
	plate.size = Vector3(GRID_SIZE * STUD_SPACING, 0.2, GRID_SIZE * STUD_SPACING)
	baseplate_mesh.mesh = plate
	baseplate_mesh.position = Vector3(0, 0.0, 0)
	
	var plate_mat: StandardMaterial3D = StandardMaterial3D.new()
	plate_mat.albedo_color = Color(0.18, 0.52, 0.24) # Classic Lego baseplate green
	plate_mat.roughness = 0.35
	plate_mat.metallic = 0.0
	baseplate_mesh.material_override = plate_mat
	
	# Subtle beveled border around baseplate edge
	var border: MeshInstance3D = MeshInstance3D.new()
	border.name = "PlateBorder"
	var b_box: BoxMesh = BoxMesh.new()
	b_box.size = Vector3(32.4, 0.18, 32.4)
	border.mesh = b_box
	border.position = Vector3(0, -0.01, 0)
	var b_mat: StandardMaterial3D = StandardMaterial3D.new()
	b_mat.albedo_color = Color(0.15, 0.45, 0.20)
	b_mat.roughness = 0.4
	border.material_override = b_mat
	baseplate_mesh.add_child(border)

func _generate_studs() -> void:
	# 32x32 = 1024 studs via high-performance MultiMesh
	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = GRID_SIZE * GRID_SIZE
	
	var cyl: CylinderMesh = CylinderMesh.new()
	cyl.top_radius = STUD_RADIUS
	cyl.bottom_radius = STUD_RADIUS
	cyl.height = STUD_HEIGHT
	cyl.radial_segments = 12
	mm.mesh = cyl
	
	var stud_mat: StandardMaterial3D = StandardMaterial3D.new()
	stud_mat.albedo_color = Color(0.18, 0.54, 0.24)
	stud_mat.roughness = 0.35
	studs_multimesh.material_override = stud_mat
	studs_multimesh.multimesh = mm
	
	var half_grid: float = (GRID_SIZE - 1) * 0.5
	var idx: int = 0
	var stud_y: float = 0.1 + (STUD_HEIGHT * 0.5)
	
	for gx in range(GRID_SIZE):
		for gz in range(GRID_SIZE):
			var world_x: float = (gx - half_grid) * STUD_SPACING
			var world_z: float = (gz - half_grid) * STUD_SPACING
			var t: Transform3D = Transform3D(Basis(), Vector3(world_x, stud_y, world_z))
			mm.set_instance_transform(idx, t)
			idx += 1

## Builds cozy craft room, hardwood floor, bounding walls, sunny window and furniture props (LB-070)
func _setup_room() -> void:
	if room_node:
		room_node.queue_free()
	room_node = Node3D.new()
	room_node.name = "CraftRoom"
	add_child(room_node)
	
	# 1. Hardwood Plank Floor
	var floor_mesh: MeshInstance3D = MeshInstance3D.new()
	floor_mesh.name = "Floor"
	var f_box: BoxMesh = BoxMesh.new()
	f_box.size = Vector3(120.0, 0.4, 110.0)
	floor_mesh.mesh = f_box
	floor_mesh.position = Vector3(0, FLOOR_Y, 0)
	
	var floor_mat: StandardMaterial3D = StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.44, 0.28, 0.16) # Rich parquet / pine floor
	floor_mat.roughness = 0.52
	floor_mat.metallic_specular = 0.25
	floor_mesh.material_override = floor_mat
	room_node.add_child(floor_mesh)
	
	# 2. Cozy Tabletop Rug under table
	var rug_mesh: MeshInstance3D = MeshInstance3D.new()
	rug_mesh.name = "Rug"
	var r_box: BoxMesh = BoxMesh.new()
	r_box.size = Vector3(64.0, 0.05, 52.0)
	rug_mesh.mesh = r_box
	rug_mesh.position = Vector3(0, FLOOR_Y + 0.22, 0)
	
	var rug_mat: StandardMaterial3D = StandardMaterial3D.new()
	rug_mat.albedo_color = Color(0.62, 0.36, 0.28) # Warm terracotta / rust cozy rug
	rug_mat.roughness = 0.85
	rug_mesh.material_override = rug_mat
	room_node.add_child(rug_mesh)
	
	# Rug Cream Border Trim
	var rug_border: MeshInstance3D = MeshInstance3D.new()
	rug_border.name = "RugBorder"
	var rb_box: BoxMesh = BoxMesh.new()
	rb_box.size = Vector3(66.0, 0.04, 54.0)
	rug_border.mesh = rb_box
	rug_border.position = Vector3(0, FLOOR_Y + 0.21, 0)
	var rb_mat: StandardMaterial3D = StandardMaterial3D.new()
	rb_mat.albedo_color = Color(0.88, 0.84, 0.76) # Cream trim
	rb_mat.roughness = 0.8
	rug_border.material_override = rb_mat
	room_node.add_child(rug_border)
	
	# 3. Room Walls (Back wall, Left wall, Right wall)
	var wall_height: float = 58.0
	var wall_center_y: float = FLOOR_Y + (wall_height * 0.5)
	
	var wall_mat: StandardMaterial3D = StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.94, 0.92, 0.88) # Warm off-white / soft cream plaster
	wall_mat.roughness = 0.88
	
	# Back Wall (Z = -46.0)
	var back_wall: MeshInstance3D = MeshInstance3D.new()
	back_wall.name = "BackWall"
	var bw_box: BoxMesh = BoxMesh.new()
	bw_box.size = Vector3(120.0, wall_height, 2.0)
	back_wall.mesh = bw_box
	back_wall.position = Vector3(0, wall_center_y, -46.0)
	back_wall.material_override = wall_mat
	room_node.add_child(back_wall)
	
	# Left Wall (X = -56.0)
	var left_wall: MeshInstance3D = MeshInstance3D.new()
	left_wall.name = "LeftWall"
	var lw_box: BoxMesh = BoxMesh.new()
	lw_box.size = Vector3(2.0, wall_height, 110.0)
	left_wall.mesh = lw_box
	left_wall.position = Vector3(-56.0, wall_center_y, 0)
	left_wall.material_override = wall_mat
	room_node.add_child(left_wall)
	
	# Right Wall (X = 56.0)
	var right_wall: MeshInstance3D = MeshInstance3D.new()
	right_wall.name = "RightWall"
	var rw_box: BoxMesh = BoxMesh.new()
	rw_box.size = Vector3(2.0, wall_height, 110.0)
	right_wall.mesh = rw_box
	right_wall.position = Vector3(56.0, wall_center_y, 0)
	right_wall.material_override = wall_mat
	room_node.add_child(right_wall)
	
	# White Skirting Boards along wall bottoms
	var skirt_mat: StandardMaterial3D = StandardMaterial3D.new()
	skirt_mat.albedo_color = Color(0.96, 0.95, 0.93)
	skirt_mat.roughness = 0.35
	
	var skirt_back: MeshInstance3D = MeshInstance3D.new()
	var sb_box: BoxMesh = BoxMesh.new()
	sb_box.size = Vector3(120.0, 2.0, 0.4)
	skirt_back.mesh = sb_box
	skirt_back.position = Vector3(0, FLOOR_Y + 1.2, -44.8)
	skirt_back.material_override = skirt_mat
	room_node.add_child(skirt_back)
	
	# 4. Sunny Window on Left Wall
	var window_frame: MeshInstance3D = MeshInstance3D.new()
	window_frame.name = "SunnyWindow"
	var wf_box: BoxMesh = BoxMesh.new()
	wf_box.size = Vector3(0.6, 22.0, 32.0)
	window_frame.mesh = wf_box
	window_frame.position = Vector3(-55.2, 8.0, -12.0)
	var wf_mat: StandardMaterial3D = StandardMaterial3D.new()
	wf_mat.albedo_color = Color(0.98, 0.97, 0.95)
	wf_mat.roughness = 0.3
	window_frame.material_override = wf_mat
	room_node.add_child(window_frame)
	
	# Window Glasspane with bright outdoor sky emission
	var window_glass: MeshInstance3D = MeshInstance3D.new()
	window_glass.name = "WindowGlass"
	var wg_box: BoxMesh = BoxMesh.new()
	wg_box.size = Vector3(0.2, 19.6, 29.6)
	window_glass.mesh = wg_box
	window_glass.position = Vector3(-55.0, 8.0, -12.0)
	var wg_mat: StandardMaterial3D = StandardMaterial3D.new()
	wg_mat.albedo_color = Color(0.85, 0.92, 1.0)
	wg_mat.emission_enabled = true
	wg_mat.emission = Color(0.95, 0.98, 1.0)
	wg_mat.emission_energy_multiplier = 0.6
	window_glass.material_override = wg_mat
	room_node.add_child(window_glass)
	
	# 5. Sourced Furniture Props (Kenney Furniture Kit)
	_instantiate_furniture_props()

## Instantiates vetted Kenney furniture props with appropriate scale and placement
func _instantiate_furniture_props() -> void:
	# A. Bookcase against back wall
	var bookcase_scene = load("res://assets/sourced/kenney_furniture/bookcaseOpen.glb")
	if bookcase_scene:
		var bookcase = bookcase_scene.instantiate()
		bookcase.name = "Bookcase"
		bookcase.scale = Vector3(44.0, 44.0, 44.0)
		bookcase.position = Vector3(18.0, FLOOR_Y + 0.2, -43.5)
		room_node.add_child(bookcase)
		
		# Books in the bookcase
		var books_scene = load("res://assets/sourced/kenney_furniture/books.glb")
		if books_scene:
			var books = books_scene.instantiate()
			books.scale = Vector3(38.0, 38.0, 38.0)
			books.position = Vector3(17.5, FLOOR_Y + 12.0, -43.0)
			room_node.add_child(books)
			
	# B. Chairs pulled up to table
	var chair_scene = load("res://assets/sourced/kenney_furniture/chair.glb")
	var cushion_scene = load("res://assets/sourced/kenney_furniture/chairCushion.glb")
	if chair_scene:
		# Chair 1: Opposite side of table (facing player)
		var chair1 = chair_scene.instantiate()
		chair1.name = "Chair_North"
		chair1.scale = Vector3(45.0, 45.0, 45.0)
		chair1.position = Vector3(0.0, FLOOR_Y + 0.2, -26.0)
		chair1.rotation_degrees = Vector3(0, 180, 0)
		room_node.add_child(chair1)
		if cushion_scene:
			var c1 = cushion_scene.instantiate()
			c1.scale = Vector3(45.0, 45.0, 45.0)
			c1.position = Vector3(0.0, FLOOR_Y + 0.2, -26.0)
			c1.rotation_degrees = Vector3(0, 180, 0)
			room_node.add_child(c1)
			
		# Chair 2: Side of table (facing center)
		var chair2 = chair_scene.instantiate()
		chair2.name = "Chair_West"
		chair2.scale = Vector3(45.0, 45.0, 45.0)
		chair2.position = Vector3(-32.0, FLOOR_Y + 0.2, 0.0)
		chair2.rotation_degrees = Vector3(0, 90, 0)
		room_node.add_child(chair2)
		
	# C. Floor Lamp in corner
	var lamp_scene = load("res://assets/sourced/kenney_furniture/lampRoundFloor.glb")
	if lamp_scene:
		var lamp = lamp_scene.instantiate()
		lamp.name = "FloorLamp"
		lamp.scale = Vector3(42.0, 42.0, 42.0)
		lamp.position = Vector3(42.0, FLOOR_Y + 0.2, -38.0)
		room_node.add_child(lamp)
		
	# D. Small Potted Plant resting on the corner of the wooden table
	var plant_scene = load("res://assets/sourced/kenney_furniture/plantSmall1.glb")
	if not plant_scene:
		plant_scene = load("res://assets/sourced/kenney_furniture/pottedPlant.glb")
	if plant_scene:
		var plant = plant_scene.instantiate()
		plant.name = "TablePlant"
		plant.scale = Vector3(16.0, 16.0, 16.0)
		plant.position = Vector3(-23.0, 0.0, -17.5) # Table top margin
		room_node.add_child(plant)

## Convert integer grid (gx, gz, z_plate) to canonical 3D world coordinates
static func grid_to_world(gx: int, gz: int, z_plate: int, dims_studs: Array = [1, 3, 1], rot_step: int = 0) -> Vector3:
	return PlacementRules.grid_to_world(gx, gz, z_plate, dims_studs, rot_step)

## Convert world point to closest integer grid anchor (gx, gz) on baseplate
static func world_to_grid(world_pos: Vector3, dims_studs: Array = [1, 3, 1], rot_step: int = 0) -> Vector2i:
	return PlacementRules.world_to_grid(world_pos, dims_studs, rot_step)
