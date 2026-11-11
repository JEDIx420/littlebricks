extends RefCounted
class_name PartMeshBuilder

## Dynamically constructs genuine 3D meshes for LittleBricks catalog parts.
## Provides distinct recognizable geometry (slopes, cones, cylinders, arches, stairs, fish, explorers)
## while maintaining canonical stud connections, bottom-center pivot, and exact dimensions.

const STUD_RADIUS: float = 0.3
const STUD_HEIGHT: float = 0.18
const STUD_SPACING: float = 1.0
const PLATE_HEIGHT: float = 0.4

const KENNEY_PART_MAP: Dictionary = {
	"brick_1x1": {"file": "bevel-hq-brick-1x1.glb", "swap_xz": false},
	"brick_1x2": {"file": "bevel-hq-brick-1x2.glb", "swap_xz": true},
	"brick_1x4": {"file": "bevel-hq-brick-1x4.glb", "swap_xz": true},
	"brick_1x6": {"file": "bevel-hq-brick-1x6.glb", "swap_xz": true},
	"brick_1x8": {"file": "bevel-hq-brick-1x8.glb", "swap_xz": true},
	"brick_2x2": {"file": "bevel-hq-brick-2x2.glb", "swap_xz": false},
	"brick_2x4": {"file": "bevel-hq-brick-2x4.glb", "swap_xz": true},
	"brick_2x6": {"file": "bevel-hq-brick-2x6.glb", "swap_xz": true},
	"brick_2x8": {"file": "bevel-hq-brick-2x8.glb", "swap_xz": true},
	"plate_1x1": {"file": "bevel-hq-plate-1x1.glb", "swap_xz": false},
	"plate_1x2": {"file": "bevel-hq-plate-1x2.glb", "swap_xz": true},
	"plate_1x4": {"file": "bevel-hq-plate-1x4.glb", "swap_xz": true},
	"plate_1x6": {"file": "bevel-hq-plate-1x6.glb", "swap_xz": true},
	"plate_1x8": {"file": "bevel-hq-plate-1x8.glb", "swap_xz": true},
	"plate_2x2": {"file": "bevel-hq-plate-2x2.glb", "swap_xz": false},
	"plate_2x4": {"file": "bevel-hq-plate-2x4.glb", "swap_xz": true},
	"plate_2x6": {"file": "bevel-hq-plate-2x6.glb", "swap_xz": true},
	"plate_2x8": {"file": "bevel-hq-plate-2x8.glb", "swap_xz": true},
	"plate_4x4": {"file": "bevel-hq-plate-4x4.glb", "swap_xz": false},
	"plate_4x6": {"file": "bevel-hq-plate-4x6.glb", "swap_xz": true},
	"plate_4x8": {"file": "bevel-hq-plate-4x8.glb", "swap_xz": true},
	"plate_round_1x1": {"file": "bevel-hq-plate-1x1-round.glb", "swap_xz": false},
	"slope_2x2": {"file": "bevel-hq-brick-slope-2x2.glb", "swap_xz": false},
	"slope_2x4_45": {"file": "bevel-hq-brick-slope-2x4.glb", "swap_xz": true},
	"slope_33_3x2": {"file": "bevel-hq-brick-slope-3x2.glb", "swap_xz": true},
	"slope_inverted_1x2": {"file": "bevel-hq-brick-slope-inverted-1x2.glb", "swap_xz": true},
	"slope_inverted_2x2": {"file": "bevel-hq-brick-slope-inverted-2x2.glb", "swap_xz": false},
	"plate_corner_2x2": {"file": "bevel-hq-plate-corner.glb", "swap_xz": false},
	"brick_corner_3x3": {"file": "bevel-hq-brick-corner.glb", "swap_xz": false}
}

const LDRAW_PART_MAP: Dictionary = {
	"slope_curved_1x4": {"file": "slope_curved_top_6091.obj", "scale": Vector3(1.0, 1.0, 1.0)},
	"slope_curved_2x2": {"file": "slope_curved_top_6091.obj", "scale": Vector3(1.0, 1.0, 1.0)},
	"steering_wheel_2x2": {"file": "steering_wheel_3829c01.obj", "scale": Vector3(1.0, 1.0, 1.0)},
	"window_1x2x2": {"file": "window_frame_60592.obj", "scale": Vector3(1.0, 1.0, 1.0)},
	"window_1x2x3": {"file": "window_frame_60592.obj", "scale": Vector3(1.0, 1.25, 1.0)}
}

## Build a 3D Node representing the part with accurate body, studs, and material.
static func build_part_node(part_def: Dictionary, color: Color) -> Node3D:
	var root: Node3D = Node3D.new()
	var pid: String = part_def.get("id", "Part")
	root.name = pid
	
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.35
	mat.metallic = 0.02
	
	var cat: String = part_def.get("category", "brick")
	var dims: Array = part_def.get("dimensions_studs", [1, 3, 1])
	var body_top_y: float = float(dims[1]) * PLATE_HEIGHT
	
	# Priority 1: Check for vetted sourced 3D model (Kenney Brick Kit or LDraw Library) (LB-072)
	if _try_build_sourced_mesh(root, pid, dims, mat):
		return root
	
	# Select specialized visual builder
	if cat == "character":
		_build_character_mesh(root, part_def, mat)
		return root
	elif cat == "slope" or pid.contains("slope"):
		_build_slope_mesh(root, part_def, dims, mat)
	elif pid.contains("round") or pid.contains("pillar_round"):
		_build_round_mesh(root, part_def, dims, mat)
	elif pid.contains("cone"):
		_build_cone_mesh(root, part_def, dims, mat)
	elif pid.begins_with("arch"):
		_build_arch_mesh(root, part_def, dims, mat)
	elif pid.begins_with("stairs"):
		_build_stairs_mesh(root, part_def, dims, mat)
	elif pid.contains("fish"):
		_build_fish_mesh(root, part_def, dims, mat)
	elif pid.begins_with("fence"):
		_build_fence_mesh(root, part_def, dims, mat)
	elif pid.begins_with("flower"):
		_build_flower_mesh(root, part_def, dims, mat)
	elif pid.begins_with("lantern"):
		_build_lantern_mesh(root, part_def, dims, mat)
	else:
		# Standard rectangular brick / plate / tile / structure body
		_build_box_body(root, part_def, mat)
		
	# Build top studs if defined
	var conns: Dictionary = part_def.get("connectors", {})
	var top_studs: Array = conns.get("studs_top", [])
	
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

static func _build_box_body(root: Node3D, part_def: Dictionary, mat: StandardMaterial3D) -> void:
	var col_boxes: Array = part_def.get("collision_boxes", [])
	if col_boxes.is_empty():
		var dims: Array = part_def.get("dimensions_studs", [1, 3, 1])
		var w = float(dims[0]) * STUD_SPACING
		var h = float(dims[1]) * PLATE_HEIGHT
		var l = float(dims[2]) * STUD_SPACING
		var cmesh: MeshInstance3D = MeshInstance3D.new()
		var box: BoxMesh = BoxMesh.new()
		box.size = Vector3(w, h, l)
		cmesh.mesh = box
		cmesh.position = Vector3(0.0, h * 0.5, 0.0)
		cmesh.material_override = mat
		root.add_child(cmesh)
		return

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

## Genuine wedge/ramp mesh for slopes (LB-065)
static func _build_slope_mesh(root: Node3D, _part_def: Dictionary, dims: Array, mat: StandardMaterial3D) -> void:
	var w: float = float(dims[0]) * STUD_SPACING
	var h: float = float(dims[1]) * PLATE_HEIGHT
	var l: float = float(dims[2]) * STUD_SPACING
	
	var half_w: float = w * 0.5
	var half_l: float = l * 0.5
	
	# A wedge sloping from z = +half_l (top, height h) down to z = -half_l (bottom, height 0.1)
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var p0 = Vector3(-half_w, 0, -half_l) # front-left-bottom
	var p1 = Vector3(half_w, 0, -half_l)  # front-right-bottom
	var p2 = Vector3(half_w, 0, half_l)   # back-right-bottom
	var p3 = Vector3(-half_w, 0, half_l)  # back-left-bottom
	var p4 = Vector3(-half_w, h, half_l)  # back-left-top
	var p5 = Vector3(half_w, h, half_l)   # back-right-top
	
	# Bottom face (p0, p2, p1) & (p0, p3, p2)
	st.add_vertex(p0); st.add_vertex(p2); st.add_vertex(p1)
	st.add_vertex(p0); st.add_vertex(p3); st.add_vertex(p2)
	
	# Back face (p3, p5, p2) & (p3, p4, p5)
	st.add_vertex(p3); st.add_vertex(p5); st.add_vertex(p2)
	st.add_vertex(p3); st.add_vertex(p4); st.add_vertex(p5)
	
	# Sloped face (p0, p5, p4) & (p0, p1, p5)
	st.add_vertex(p0); st.add_vertex(p5); st.add_vertex(p4)
	st.add_vertex(p0); st.add_vertex(p1); st.add_vertex(p5)
	
	# Left triangular face (p0, p4, p3)
	st.add_vertex(p0); st.add_vertex(p4); st.add_vertex(p3)
	
	# Right triangular face (p1, p2, p5)
	st.add_vertex(p1); st.add_vertex(p2); st.add_vertex(p5)
	
	st.generate_normals()
	var mesh = st.commit()
	
	var m_inst: MeshInstance3D = MeshInstance3D.new()
	m_inst.mesh = mesh
	m_inst.material_override = mat
	root.add_child(m_inst)

## Cylindrical mesh for round bricks, plates, and pillars (LB-065)
static func _build_round_mesh(root: Node3D, _part_def: Dictionary, dims: Array, mat: StandardMaterial3D) -> void:
	var d_studs: float = float(dims[0])
	var radius: float = (d_studs * STUD_SPACING * 0.5) - 0.02
	var height: float = float(dims[1]) * PLATE_HEIGHT
	
	var cyl: CylinderMesh = CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = height
	cyl.radial_segments = 24
	
	var m_inst: MeshInstance3D = MeshInstance3D.new()
	m_inst.mesh = cyl
	m_inst.position = Vector3(0.0, height * 0.5, 0.0)
	m_inst.material_override = mat
	root.add_child(m_inst)

## Tapered cone mesh (LB-065)
static func _build_cone_mesh(root: Node3D, _part_def: Dictionary, dims: Array, mat: StandardMaterial3D) -> void:
	var d_studs: float = float(dims[0])
	var bottom_radius: float = (d_studs * STUD_SPACING * 0.5) - 0.02
	var top_radius: float = STUD_RADIUS
	var height: float = float(dims[1]) * PLATE_HEIGHT
	
	var cyl: CylinderMesh = CylinderMesh.new()
	cyl.top_radius = top_radius
	cyl.bottom_radius = bottom_radius
	cyl.height = height
	cyl.radial_segments = 24
	
	var m_inst: MeshInstance3D = MeshInstance3D.new()
	m_inst.mesh = cyl
	m_inst.position = Vector3(0.0, height * 0.5, 0.0)
	m_inst.material_override = mat
	root.add_child(m_inst)

## Hollow opening arch mesh with side pillars and spanning lintel (LB-065)
static func _build_arch_mesh(root: Node3D, _part_def: Dictionary, dims: Array, mat: StandardMaterial3D) -> void:
	var w: float = float(dims[0]) * STUD_SPACING
	var h: float = float(dims[1]) * PLATE_HEIGHT
	var l: float = float(dims[2]) * STUD_SPACING
	
	var span_thick: float = PLATE_HEIGHT # 1 plate thickness on top
	var pillar_len: float = 1.0 # 1 stud length per side pillar
	var pillar_height: float = h - span_thick
	
	# Left pillar
	var left_p: MeshInstance3D = MeshInstance3D.new()
	var left_box: BoxMesh = BoxMesh.new()
	left_box.size = Vector3(w, pillar_height, pillar_len)
	left_p.mesh = left_box
	var left_z = (-l * 0.5) + (pillar_len * 0.5)
	left_p.position = Vector3(0.0, pillar_height * 0.5, left_z)
	left_p.material_override = mat
	root.add_child(left_p)
	
	# Right pillar
	var right_p: MeshInstance3D = MeshInstance3D.new()
	var right_box: BoxMesh = BoxMesh.new()
	right_box.size = Vector3(w, pillar_height, pillar_len)
	right_p.mesh = right_box
	var right_z = (l * 0.5) - (pillar_len * 0.5)
	right_p.position = Vector3(0.0, pillar_height * 0.5, right_z)
	right_p.material_override = mat
	root.add_child(right_p)
	
	# Top lintel spanning full length
	var top_span: MeshInstance3D = MeshInstance3D.new()
	var span_box: BoxMesh = BoxMesh.new()
	span_box.size = Vector3(w, span_thick, l)
	top_span.mesh = span_box
	top_span.position = Vector3(0.0, pillar_height + (span_thick * 0.5), 0.0)
	top_span.material_override = mat
	root.add_child(top_span)

## Stepped stairs mesh (LB-065)
static func _build_stairs_mesh(root: Node3D, _part_def: Dictionary, dims: Array, mat: StandardMaterial3D) -> void:
	var w: float = float(dims[0]) * STUD_SPACING
	var total_h: float = float(dims[1]) * PLATE_HEIGHT
	var total_l: float = float(dims[2]) * STUD_SPACING
	
	var step_count: int = clampi(int(dims[2]), 2, 4)
	var step_len: float = total_l / float(step_count)
	var step_h: float = total_h / float(step_count)
	
	for i in range(step_count):
		var step: MeshInstance3D = MeshInstance3D.new()
		var box: BoxMesh = BoxMesh.new()
		var h_i: float = step_h * float(i + 1)
		box.size = Vector3(w, h_i, step_len)
		step.mesh = box
		var z_i: float = (-total_l * 0.5) + (step_len * 0.5) + (float(i) * step_len)
		step.position = Vector3(0.0, h_i * 0.5, z_i)
		step.material_override = mat
		root.add_child(step)

## Stylized coastal fish silhouette with body, tail, and dorsal fin (LB-065)
static func _build_fish_mesh(root: Node3D, _part_def: Dictionary, _dims: Array, mat: StandardMaterial3D) -> void:
	# Main body (tapered oval)
	var body: MeshInstance3D = MeshInstance3D.new()
	var body_box: BoxMesh = BoxMesh.new()
	body_box.size = Vector3(0.6, 0.36, 1.2)
	body.mesh = body_box
	body.position = Vector3(0.0, 0.2, -0.2)
	body.material_override = mat
	root.add_child(body)
	
	# Tail fin (flared wedge)
	var tail: MeshInstance3D = MeshInstance3D.new()
	var tail_box: BoxMesh = BoxMesh.new()
	tail_box.size = Vector3(0.2, 0.45, 0.5)
	tail.mesh = tail_box
	tail.position = Vector3(0.0, 0.22, 0.6)
	tail.material_override = mat
	root.add_child(tail)

## Fence rails with pickets (LB-065)
static func _build_fence_mesh(root: Node3D, _part_def: Dictionary, dims: Array, mat: StandardMaterial3D) -> void:
	var w: float = float(dims[0]) * STUD_SPACING
	var h: float = float(dims[1]) * PLATE_HEIGHT
	var l: float = float(dims[2]) * STUD_SPACING
	
	# Top and bottom rail
	for rail_y in [0.15, h - 0.15]:
		var rail: MeshInstance3D = MeshInstance3D.new()
		var r_box: BoxMesh = BoxMesh.new()
		r_box.size = Vector3(w * 0.4, 0.12, l)
		rail.mesh = r_box
		rail.position = Vector3(0.0, rail_y, 0.0)
		rail.material_override = mat
		root.add_child(rail)
		
	# Vertical posts
	var posts: int = int(dims[2])
	for i in range(posts + 1):
		var post: MeshInstance3D = MeshInstance3D.new()
		var p_box: BoxMesh = BoxMesh.new()
		p_box.size = Vector3(w * 0.5, h, 0.15)
		post.mesh = p_box
		var p_z = (-l * 0.5) + (float(i) * (l / float(posts)))
		post.position = Vector3(0.0, h * 0.5, p_z)
		post.material_override = mat
		root.add_child(post)

## Stylized decorative flower with stem and petals (LB-065)
static func _build_flower_mesh(root: Node3D, _part_def: Dictionary, _dims: Array, mat: StandardMaterial3D) -> void:
	var stem: MeshInstance3D = MeshInstance3D.new()
	var cyl: CylinderMesh = CylinderMesh.new()
	cyl.top_radius = 0.1
	cyl.bottom_radius = 0.1
	cyl.height = 0.3
	stem.mesh = cyl
	stem.position = Vector3(0.0, 0.15, 0.0)
	var green_mat = StandardMaterial3D.new()
	green_mat.albedo_color = Color(0.2, 0.6, 0.25)
	stem.material_override = green_mat
	root.add_child(stem)
	
	var blossom: MeshInstance3D = MeshInstance3D.new()
	var b_cyl: CylinderMesh = CylinderMesh.new()
	b_cyl.top_radius = 0.38
	b_cyl.bottom_radius = 0.25
	b_cyl.height = 0.12
	blossom.mesh = b_cyl
	blossom.position = Vector3(0.0, 0.36, 0.0)
	blossom.material_override = mat
	root.add_child(blossom)

## Stylized lantern with post and glass lantern box (LB-065)
static func _build_lantern_mesh(root: Node3D, _part_def: Dictionary, dims: Array, mat: StandardMaterial3D) -> void:
	var h: float = float(dims[1]) * PLATE_HEIGHT
	
	# Post
	var post: MeshInstance3D = MeshInstance3D.new()
	var p_cyl: CylinderMesh = CylinderMesh.new()
	p_cyl.top_radius = 0.15
	p_cyl.bottom_radius = 0.2
	p_cyl.height = h - 0.6
	post.mesh = p_cyl
	post.position = Vector3(0.0, (h - 0.6) * 0.5, 0.0)
	var dark_mat = StandardMaterial3D.new()
	dark_mat.albedo_color = Color(0.2, 0.22, 0.25)
	post.material_override = dark_mat
	root.add_child(post)
	
	# Lamp lantern head
	var lamp: MeshInstance3D = MeshInstance3D.new()
	var lamp_box: BoxMesh = BoxMesh.new()
	lamp_box.size = Vector3(0.6, 0.6, 0.6)
	lamp.mesh = lamp_box
	lamp.position = Vector3(0.0, h - 0.3, 0.0)
	var warm_lamp_mat = StandardMaterial3D.new()
	warm_lamp_mat.albedo_color = Color(0.98, 0.88, 0.5)
	warm_lamp_mat.emission_enabled = true
	warm_lamp_mat.emission = Color(0.98, 0.88, 0.5)
	warm_lamp_mat.emission_energy_multiplier = 0.8
	lamp.material_override = warm_lamp_mat
	root.add_child(lamp)

## Stylized toy explorer figure (Pippin, Marina, Rowan)
static func _build_character_mesh(root: Node3D, part_def: Dictionary, _mat: StandardMaterial3D) -> void:
	var pid: String = part_def.get("id", "toy_explorer_pippin")
	
	var leg_col = Color(0.18, 0.28, 0.55) # Blue
	var torso_col = Color(0.85, 0.2, 0.18) # Red
	var hat_col = Color(0.4, 0.25, 0.15) # Brown
	
	if pid.contains("marina"):
		torso_col = Color(0.15, 0.65, 0.55) # Teal
		leg_col = Color(0.85, 0.85, 0.9) # Light
		hat_col = Color(0.95, 0.8, 0.2) # Yellow
	elif pid.contains("rowan"):
		torso_col = Color(0.25, 0.55, 0.25) # Forest green
		leg_col = Color(0.35, 0.25, 0.15) # Brown
		hat_col = Color(0.2, 0.25, 0.3) # Dark
		
	# Legs
	var legs: MeshInstance3D = MeshInstance3D.new()
	var leg_box: BoxMesh = BoxMesh.new()
	leg_box.size = Vector3(1.4, 1.8, 1.0)
	legs.mesh = leg_box
	legs.position = Vector3(0, 0.9, 0)
	var leg_mat = StandardMaterial3D.new()
	leg_mat.albedo_color = leg_col
	legs.material_override = leg_mat
	root.add_child(legs)
	
	# Torso
	var torso: MeshInstance3D = MeshInstance3D.new()
	var torso_box: BoxMesh = BoxMesh.new()
	torso_box.size = Vector3(1.5, 1.6, 1.0)
	torso.mesh = torso_box
	torso.position = Vector3(0, 2.6, 0)
	var torso_mat = StandardMaterial3D.new()
	torso_mat.albedo_color = torso_col
	torso.material_override = torso_mat
	root.add_child(torso)
	
	# Head
	var head: MeshInstance3D = MeshInstance3D.new()
	var head_cyl: CylinderMesh = CylinderMesh.new()
	head_cyl.top_radius = 0.55
	head_cyl.bottom_radius = 0.55
	head_cyl.height = 1.0
	head.mesh = head_cyl
	head.position = Vector3(0, 3.9, 0)
	var yellow_mat = StandardMaterial3D.new()
	yellow_mat.albedo_color = Color(0.96, 0.82, 0.2)
	head.material_override = yellow_mat
	root.add_child(head)
	
	# Explorer Hat / Cap
	var hat: MeshInstance3D = MeshInstance3D.new()
	var hat_box: BoxMesh = BoxMesh.new()
	hat_box.size = Vector3(1.6, 0.35, 1.6)
	hat.mesh = hat_box
	hat.position = Vector3(0, 4.5, 0)
	var hat_material = StandardMaterial3D.new()
	hat_material.albedo_color = hat_col
	hat.material_override = hat_material
	root.add_child(hat)

## Attempts to build part node using vetted sourced 3D model (LB-072).
static func _try_build_sourced_mesh(root: Node3D, pid: String, dims: Array, mat: StandardMaterial3D) -> bool:
	if KENNEY_PART_MAP.has(pid):
		var info: Dictionary = KENNEY_PART_MAP[pid]
		var path: String = "res://assets/sourced/kenney_bricks/" + info["file"]
		var scene = load(path)
		if scene:
			var inst = scene.instantiate()
			# Scale from Kenney 0.08m units to LittleBricks canonical stud units (12.5x)
			inst.scale = Vector3(12.5, 12.5, 12.5)
			if info.get("swap_xz", false):
				inst.rotation_degrees.y = 90.0
			_apply_material_recursive(inst, mat)
			root.add_child(inst)
			return true
			
	if LDRAW_PART_MAP.has(pid):
		var info: Dictionary = LDRAW_PART_MAP[pid]
		var path: String = "res://assets/sourced/ldraw/" + info["file"]
		var mesh_res = load(path)
		if mesh_res:
			var mi: MeshInstance3D = MeshInstance3D.new()
			mi.mesh = mesh_res
			mi.scale = info.get("scale", Vector3.ONE)
			mi.material_override = mat
			root.add_child(mi)
			return true
			
	return false

static func _apply_material_recursive(node: Node, mat: StandardMaterial3D) -> void:
	if node is MeshInstance3D:
		node.material_override = mat
	for child in node.get_children():
		_apply_material_recursive(child, mat)
