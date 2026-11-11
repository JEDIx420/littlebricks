extends Node3D
class_name TableView

## TableView manages the 3D tabletop, 32x32 stud baseplate, and visual materials.

const GRID_SIZE: int = 32
const STUD_SPACING: float = 1.0
const STUD_RADIUS: float = 0.3
const STUD_HEIGHT: float = 0.18
const PLATE_HEIGHT: float = 0.4 # In Godot units, 1 plate = 0.4

@onready var table_mesh: MeshInstance3D = $TableMesh
@onready var baseplate_mesh: MeshInstance3D = $BaseplateMesh
@onready var studs_multimesh: MultiMeshInstance3D = $StudsMultiMesh

func _ready() -> void:
	_setup_table()
	_setup_baseplate()
	_generate_studs()

func _setup_table() -> void:
	# Wooden tabletop surface
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(56.0, 1.5, 56.0)
	table_mesh.mesh = box
	table_mesh.position = Vector3(0, -0.85, 0)
	
	var table_mat: StandardMaterial3D = StandardMaterial3D.new()
	table_mat.albedo_color = Color(0.28, 0.19, 0.13) # Warm oak / walnut wood
	table_mat.roughness = 0.45
	table_mat.metallic = 0.05
	table_mesh.material_override = table_mat

func _setup_baseplate() -> void:
	# 32x32 green baseplate
	var plate: BoxMesh = BoxMesh.new()
	plate.size = Vector3(GRID_SIZE * STUD_SPACING, 0.2, GRID_SIZE * STUD_SPACING)
	baseplate_mesh.mesh = plate
	baseplate_mesh.position = Vector3(0, 0.0, 0)
	
	var plate_mat: StandardMaterial3D = StandardMaterial3D.new()
	plate_mat.albedo_color = Color(0.18, 0.52, 0.24) # Classic Lego baseplate green
	plate_mat.roughness = 0.35
	plate_mat.metallic = 0.0
	baseplate_mesh.material_override = plate_mat

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

## Convert integer grid (gx in 0..31, gz in 0..31, z_plate in plates) to world coordinates
static func grid_to_world(gx: int, gz: int, z_plate: int) -> Vector3:
	var half_grid: float = (GRID_SIZE - 1) * 0.5
	var wx: float = (float(gx) - half_grid) * STUD_SPACING
	var wz: float = (float(gz) - half_grid) * STUD_SPACING
	var wy: float = 0.1 + (float(z_plate) * PLATE_HEIGHT)
	return Vector3(wx, wy, wz)

## Convert world point to closest integer grid (gx, gz) on baseplate
static func world_to_grid(world_pos: Vector3) -> Vector2i:
	var half_grid: float = (GRID_SIZE - 1) * 0.5
	var gx: int = int(round((world_pos.x / STUD_SPACING) + half_grid))
	var gz: int = int(round((world_pos.z / STUD_SPACING) + half_grid))
	return Vector2i(clampi(gx, 0, GRID_SIZE - 1), clampi(gz, 0, GRID_SIZE - 1))
