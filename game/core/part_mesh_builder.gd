extends RefCounted
class_name PartMeshBuilder

## Dynamically constructs genuine 3D meshes for LittleBricks catalog parts.
## Provides distinct recognizable geometry (slopes, cones, cylinders, arches, stairs, fish, explorers)
## while maintaining canonical stud connections, bottom-center pivot, and exact dimensions.

const STUD_RADIUS: float = 0.3
const STUD_HEIGHT: float = 0.18
const STUD_SPACING: float = 1.0
const PLATE_HEIGHT: float = 0.4
const KENNEY_STUD_PITCH := Vector3(0.0795, 0.0800, 0.0790)
const FIGURE_STAND_HEIGHT: float = 0.16
const FIGURE_DISPLAY_SCALE: float = 0.53

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
	"plate_4x6": {"file": "bevel-hq-plate-4x6.glb", "swap_xz": true}
}

const LDRAW_PART_MAP: Dictionary = {
	"window_1x2x2": {"file": "window_frame_60592.obj", "yaw": 90.0},
	"arch_1x4": {"file": "arch_1x4_3659.obj", "yaw": 90.0}
}

const MinifigureModel = preload("res://client/scripts/minifigure_model.gd")
const SpecialtyMeshes = preload("res://core/part_detail_meshes.gd")

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
	
	if cat == "character":
		var figure = MinifigureModel.new()
		figure.configure(pid)
		# Display figures fit the original save footprint with a uniform scale.
		# The standing model and its walking counterpart keep the same proportions.
		var figure_bounds: AABB = figure.get_render_bounds()
		var stand_size := Vector3(float(dims[0]) - 0.035, FIGURE_STAND_HEIGHT, float(dims[2]) - 0.035)
		var fit := Vector3(stand_size.x, body_top_y - FIGURE_STAND_HEIGHT, stand_size.z) / figure_bounds.size
		var uniform_scale := minf(FIGURE_DISPLAY_SCALE, minf(fit.x, minf(fit.y, fit.z)))
		figure.scale = Vector3.ONE * uniform_scale
		var center := figure_bounds.get_center()
		figure.position = Vector3(-center.x, -figure_bounds.position.y, -center.z) * uniform_scale
		figure.position.y += FIGURE_STAND_HEIGHT
		root.add_child(figure)
		var stand_material := SpecialtyMeshes.tint(mat, Color("#34383d"))
		SpecialtyMeshes.box(root, stand_size, Vector3.UP * FIGURE_STAND_HEIGHT * 0.5, stand_material)
		return root
	if _build_catalogue_mesh(root, part_def, mat) or _try_build_sourced_mesh(root, pid, mat):
		return root

	if cat == "slope" or pid.contains("slope"):
		_build_slope_mesh(root, part_def, dims, mat)
	elif pid.begins_with("arch"):
		_build_arch_mesh(root, part_def, dims, mat)
	elif pid.begins_with("stairs"):
		_build_stairs_body(root, part_def, dims, mat)
	elif pid.contains("corner") or pid == "brick_4x4":
		_build_corner_body(root, dims, mat)
	elif SpecialtyMeshes.build(root, pid, dims, mat):
		pass
	elif pid.contains("round"):
		_build_round_mesh(root, part_def, dims, mat)
	elif pid.contains("cone"):
		_build_cone_mesh(root, part_def, dims, mat)
	else:
		_build_box_body(root, part_def, mat)

	var top_studs: Array = part_def.get("connectors", {}).get("studs_top", [])
	for stud_pos in top_studs:
		var y: float = float(stud_pos[2]) * PLATE_HEIGHT if stud_pos.size() > 2 else body_top_y
		_add_stud(root, Vector3(float(stud_pos[0]), y, float(stud_pos[1])), mat)

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
		box.size = Vector3(w - 0.035, h, l - 0.035)
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
		box.size = Vector3(maxf(0.01, s[0] - 0.035), s[1], maxf(0.01, s[2] - 0.035))
		cmesh.mesh = box
		cmesh.position = Vector3(c[0], c[1], c[2])
		cmesh.material_override = mat
		root.add_child(cmesh)

static func _build_corner_body(root: Node3D, dims: Array, mat: Material) -> void:
	var half_width: float = float(dims[0]) * 0.5 - 0.018
	var half_length: float = float(dims[2]) * 0.5 - 0.018
	var height: float = float(dims[1]) * PLATE_HEIGHT
	var inner_x: float = half_width - 0.97
	var inner_z: float = -half_length + 0.97
	var profile := PackedVector2Array([
		Vector2(-half_length, half_width), Vector2(-half_length, -half_width),
		Vector2(inner_z, -half_width), Vector2(inner_z, inner_x),
		Vector2(half_length, inner_x), Vector2(half_length, half_width)
	])
	var pivot := Node3D.new()
	pivot.position.y = height * 0.5
	pivot.rotation.z = PI * 0.5
	root.add_child(pivot)
	SpecialtyMeshes.extrude_profile(pivot, profile, height, mat)

static func _add_stud(root: Node3D, center: Vector3, mat: Material) -> void:
	var stud := CylinderMesh.new()
	stud.top_radius = STUD_RADIUS - 0.016
	stud.bottom_radius = STUD_RADIUS
	stud.height = STUD_HEIGHT
	stud.radial_segments = 20
	SpecialtyMeshes.add_mesh(root, stud, center + Vector3.UP * STUD_HEIGHT * 0.5, mat)

static func _build_slope_mesh(root: Node3D, part_def: Dictionary, dims: Array, mat: StandardMaterial3D) -> void:
	var pid: String = part_def["id"]
	var half_length: float = float(dims[2]) * 0.5 - 0.018
	var height: float = float(dims[1]) * PLATE_HEIGHT
	var edge: float = minf(0.20, height * 0.35)
	var profile := PackedVector2Array([Vector2(-half_length, 0.0), Vector2(half_length, 0.0)])
	if pid.begins_with("roof_") or pid.contains("double"):
		var ridge: float = 0.20 if pid != "roof_peak_2x2" else 0.035
		profile.append_array([Vector2(half_length, edge), Vector2(ridge, height), Vector2(-ridge, height), Vector2(-half_length, edge)])
	elif pid.contains("curved"):
		for i in range(13):
			var t: float = float(i) / 12.0
			var y: float = lerpf(edge, height, sqrt(maxf(0.0, 1.0 - t * t)))
			profile.append(Vector2(lerpf(half_length, -half_length, t), y))
	elif pid.contains("inverted"):
		profile = PackedVector2Array([Vector2(-0.02, 0.0), Vector2(half_length, 0.0), Vector2(half_length, height), Vector2(-half_length, height), Vector2(-half_length, height - edge)])
	elif pid.contains("corner"):
		SpecialtyMeshes.build_corner_slope(root, Vector3(float(dims[0]), height, float(dims[2])), mat)
		return
	else:
		var degrees: float = 30.0 if pid.ends_with("_30") else (33.0 if pid.contains("33") else 45.0)
		var slope_run: float = minf(2.0 * half_length - 0.08, (height - edge) / tan(deg_to_rad(degrees)))
		profile.append_array([Vector2(half_length, height), Vector2(-half_length + slope_run, height), Vector2(-half_length, edge)])
	SpecialtyMeshes.extrude_profile(root, profile, float(dims[0]) - 0.035, mat)

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

## Rounded underside with full studded lintel; collision uses matching stepped sections.
static func _build_arch_mesh(root: Node3D, part_def: Dictionary, dims: Array, mat: StandardMaterial3D) -> void:
	var length: float = float(dims[2])
	var height: float = float(dims[1]) * PLATE_HEIGHT
	var width: float = float(dims[0]) - 0.035
	if part_def.get("id", "").contains("inverted"):
		var arch := Node3D.new()
		root.add_child(arch)
		arch.position.y = height
		arch.rotation.z = PI
		SpecialtyMeshes.extrude_profile(arch, SpecialtyMeshes.arch_profile(length, height), width, mat)
		return
	SpecialtyMeshes.extrude_profile(root, SpecialtyMeshes.arch_profile(length, height), width, mat)

static func _build_stairs_body(root: Node3D, part_def: Dictionary, dims: Array, mat: Material) -> void:
	var half_length: float = float(dims[2]) * 0.5
	var profile := PackedVector2Array([Vector2(-half_length, 0), Vector2(half_length, 0)])
	var treads: Array = part_def.get("collision_boxes", [])
	for i in range(treads.size() - 1, -1, -1):
		var tread: Dictionary = treads[i]
		var edge: float = float(tread["center"][2])
		var height: float = float(tread["size"][1])
		profile.append(Vector2(edge + 0.5, height))
		profile.append(Vector2(edge - 0.5, height))
	SpecialtyMeshes.extrude_profile(root, profile, float(dims[0]) - 0.035, mat)

static func _build_catalogue_mesh(root: Node3D, part: Dictionary, mat: StandardMaterial3D) -> bool:
	var source_path: String = part.get("sourced_mesh", "")
	if source_path.is_empty():
		return false
	var mesh := load("res://" + source_path) as Mesh
	if mesh == null:
		push_error("Missing sourced brick mesh: " + source_path)
		return false
	var mount: Array = part.get("mesh_mount", [])
	var y: float = 0.0
	if not mount.is_empty():
		var pedestal := SpecialtyMeshes.tint(mat, mat.albedo_color.darkened(0.45))
		SpecialtyMeshes.box(root, Vector3(float(mount[0]) - 0.035, PLATE_HEIGHT, float(mount[1]) - 0.035), Vector3.UP * PLATE_HEIGHT * 0.5, pedestal)
		y = PLATE_HEIGHT
	if part.get("mesh_glazing", false):
		mat.albedo_color = mat.albedo_color.lerp(Color("#8AD5E8"), 0.68)
		mat.albedo_color.a = 0.54
		mat.roughness = 0.15
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	SpecialtyMeshes.add_mesh(root, mesh, Vector3.UP * y, mat)
	return true

## Attempts to build part node using vetted sourced 3D model (LB-072).
static func _try_build_sourced_mesh(root: Node3D, pid: String, mat: StandardMaterial3D) -> bool:
	if KENNEY_PART_MAP.has(pid):
		var info: Dictionary = KENNEY_PART_MAP[pid]
		var path: String = "res://assets/sourced/kenney_bricks/" + info["file"]
		var scene = load(path)
		if scene:
			var inst = scene.instantiate()
			# The source kit uses slightly different pitches along its two axes.
			# Normalize each one independently so long bricks line up at both ends.
			inst.scale = Vector3.ONE / KENNEY_STUD_PITCH
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
			mi.rotation_degrees.y = info["yaw"]
			mi.material_override = mat
			root.add_child(mi)
			return true
			
	return false

static func _apply_material_recursive(node: Node, mat: StandardMaterial3D) -> void:
	if node is MeshInstance3D:
		node.material_override = mat
	for child in node.get_children():
		_apply_material_recursive(child, mat)
