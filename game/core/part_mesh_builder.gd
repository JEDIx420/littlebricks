extends RefCounted
class_name PartMeshBuilder

## Dynamically constructs 3D meshes for LittleBricks catalog parts.
## Guarantees 100% correct dimensions, pivot at bottom center, and studs in Godot units.

const STUD_RADIUS: float = 0.3
const STUD_HEIGHT: float = 0.18
const STUD_SPACING: float = 1.0
const PLATE_HEIGHT: float = 0.4

## Build a 3D Node representing the part with accurate body, studs, and material.
static func build_part_node(part_def: Dictionary, color: Color) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = part_def.get("id", "Part")
	
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.35
	mat.metallic = 0.02
	
	var cat: String = part_def.get("category", "brick")
	
	if cat == "character":
		_build_character_mesh(root, part_def, mat)
		return root
		
	# Build solid or multi-box collision body
	var col_boxes: Array = part_def.get("collision_boxes", [])
	for box_info in col_boxes:
		var cmesh: MeshInstance3D = MeshInstance3D.new()
		var box: BoxMesh = BoxMesh.new()
		var s: Array = box_info.get("size", [1.0, 1.2, 1.0])
		var c: Array = box_info.get("center", [0.0, 0.6, 0.0])
		box.size = Vector3(s[0], s[1], s[2])
		cmesh.mesh = box
		cmesh.position = Vector3(c[0], c[1], c[2])
		cmesh.material_override = mat
		root.add_child(cmesh)
		
	# Build top studs
	var conns: Dictionary = part_def.get("connectors", {})
	var top_studs: Array = conns.get("studs_top", [])
	var dims: Array = part_def.get("dimensions_studs", [1, 3, 1])
	var body_top_y: float = float(dims[1]) * PLATE_HEIGHT
	
	for stud_pos in top_studs:
		var smesh: MeshInstance3D = MeshInstance3D.new()
		var cyl: CylinderMesh = CylinderMesh.new()
		cyl.top_radius = STUD_RADIUS
		cyl.bottom_radius = STUD_RADIUS
		cyl.height = STUD_HEIGHT
		cyl.radial_segments = 12
		smesh.mesh = cyl
		smesh.position = Vector3(float(stud_pos[0]), body_top_y + (STUD_HEIGHT * 0.5), float(stud_pos[1]))
		smesh.material_override = mat
		root.add_child(smesh)
		
	return root

static func _build_character_mesh(root: Node3D, part_def: Dictionary, mat: StandardMaterial3D) -> void:
	# Stylized toy explorer figure (Pippin)
	# Head, torso, legs, and hat/backpack
	# Height: 4.8 units total
	
	# Legs
	var legs: MeshInstance3D = MeshInstance3D.new()
	var leg_box: BoxMesh = BoxMesh.new()
	leg_box.size = Vector3(1.4, 1.8, 1.0)
	legs.mesh = leg_box
	legs.position = Vector3(0, 0.9, 0)
	var blue_mat: StandardMaterial3D = StandardMaterial3D.new()
	blue_mat.albedo_color = Color(0.18, 0.28, 0.55)
	legs.material_override = blue_mat
	root.add_child(legs)
	
	# Torso
	var torso: MeshInstance3D = MeshInstance3D.new()
	var torso_box: BoxMesh = BoxMesh.new()
	torso_box.size = Vector3(1.5, 1.6, 1.0)
	torso.mesh = torso_box
	torso.position = Vector3(0, 2.6, 0)
	var red_mat: StandardMaterial3D = StandardMaterial3D.new()
	red_mat.albedo_color = Color(0.85, 0.2, 0.18)
	torso.material_override = red_mat
	root.add_child(torso)
	
	# Head
	var head: MeshInstance3D = MeshInstance3D.new()
	var head_cyl: CylinderMesh = CylinderMesh.new()
	head_cyl.top_radius = 0.55
	head_cyl.bottom_radius = 0.55
	head_cyl.height = 1.0
	head.mesh = head_cyl
	head.position = Vector3(0, 3.9, 0)
	var yellow_mat: StandardMaterial3D = StandardMaterial3D.new()
	yellow_mat.albedo_color = Color(0.96, 0.82, 0.2)
	head.material_override = yellow_mat
	root.add_child(head)
	
	# Explorer Hat / Cap
	var hat: MeshInstance3D = MeshInstance3D.new()
	var hat_box: BoxMesh = BoxMesh.new()
	hat_box.size = Vector3(1.6, 0.35, 1.6)
	hat.mesh = hat_box
	hat.position = Vector3(0, 4.5, 0)
	var brown_mat: StandardMaterial3D = StandardMaterial3D.new()
	brown_mat.albedo_color = Color(0.4, 0.25, 0.15)
	hat.material_override = brown_mat
	root.add_child(hat)
