extends RefCounted

## Original silhouettes for specialty parts that cannot be represented by
## their simplified collision proxies. All dimensions use the stud scale.
static func build(root: Node3D, id: String, dims: Array, mat: StandardMaterial3D) -> bool:
	var width: float = float(dims[0])
	var height: float = float(dims[1]) * 0.4
	var length: float = float(dims[2])
	var dark: StandardMaterial3D = tint(mat, mat.albedo_color.darkened(0.32))
	var light: StandardMaterial3D = tint(mat, mat.albedo_color.lightened(0.32))
	match id:
		"window_1x4x3", "window_1x2x3", "door_frame_1x4x6":
			return false # These frames use their open collision members.
		"door_leaf_1x3x5":
			box(root, Vector3(width * 0.36, height, length * 0.98), Vector3.UP * height * 0.5, mat)
			for sign_z in [-1.0, 1.0]:
				box(root, Vector3(0.52, height * 0.94, 0.14), Vector3(0, height * 0.5, sign_z * length * 0.44), dark)
			for fraction in [0.07, 0.50, 0.93]:
				box(root, Vector3(0.52, height * 0.04, length * 0.88), Vector3(0, height * fraction, 0), dark)
			oval(root, Vector3(0.13, 0.16, 0.13), Vector3(0.30, height * 0.48, length * 0.31), tint(mat, Color("#d8a450")))
		"glass_pane_1x2x2":
			var glass: StandardMaterial3D = tint(mat, Color("#9cd6db"))
			glass.roughness = 0.12
			box(root, Vector3(0.15, height - 0.26, length - 0.25), Vector3.UP * height * 0.5, glass)
			for sign_z in [-1.0, 1.0]:
				box(root, Vector3(0.32, height, 0.13), Vector3(0, height * 0.5, sign_z * (length - 0.15) * 0.5), mat)
			for y in [0.09, height - 0.09]:
				box(root, Vector3(0.36, 0.18, length - 0.025), Vector3(0, y, 0), mat)
		"fence_1x4", "fence_1x6", "barrier_1x4":
			railing(root, length, height, id == "fence_1x6", mat)
		"ladder_1x2x6":
			for sign_z in [-1.0, 1.0]:
				box(root, Vector3(0.52, height, 0.23), Vector3(0, height * 0.5, sign_z * (length * 0.5 - 0.13)), mat)
			# Both end caps are actual flat connector surfaces.
			for end_y in [0.09, height - 0.09]:
				box(root, Vector3(0.74, 0.18, length - 0.04), Vector3(0, end_y, 0), mat)
			for i in range(9):
				box(root, Vector3(0.33, 0.16, length - 0.2), Vector3(0, 0.4 + (height - 0.8) * i / 8.0, 0), dark)
		"bollard_1x1":
			cylinder(root, 0.46, 0.42, 0.26, Vector3(0, 0.13, 0), mat)
			cylinder(root, 0.22, 0.22, height - 0.26, Vector3(0, height * 0.5 + 0.13, 0), dark)
			cylinder(root, 0.39, 0.35, 0.21, Vector3(0, height - 0.105, 0), mat)
		"lantern_post_1x1x3", "lantern_1x1":
			lantern(root, height, width, mat, dark)
		"column_fluted_2x2x3", "pillar_octagonal_2x2x3", "column_capital_2x2":
			var fluted: bool = id.contains("fluted")
			var cap: float = minf(height * 0.3, 0.34)
			cylinder(root, width * 0.49, width * 0.47, cap, Vector3.UP * cap * 0.5, mat, 8)
			cylinder(root, width * 0.47, width * 0.49, cap, Vector3.UP * (height - cap * 0.5), mat, 8)
			cylinder(root, width * 0.36, width * 0.36, height - 2 * cap, Vector3.UP * height * 0.5, mat, 24 if fluted else 8)
			if fluted:
				for i in range(8):
					var angle: float = TAU * i / 8.0
					cylinder(root, 0.07, 0.07, height - 2 * cap, Vector3(cos(angle) * width * 0.35, height * 0.5, sin(angle) * width * 0.35), light, 8)
		"flower_1x1":
			cylinder(root, 0.07, 0.05, height * 0.62, Vector3.UP * height * 0.31, tint(mat, Color("#487751")))
			for i in range(5):
				var angle: float = TAU * i / 5.0
				oval(root, Vector3(0.16, 0.07, 0.16), Vector3(cos(angle) * 0.19, height - 0.08, sin(angle) * 0.19), mat)
			oval(root, Vector3(0.13, 0.07, 0.13), Vector3.UP * (height - 0.07), tint(mat, Color("#e6b861")))
		"bush_2x2":
			box(root, Vector3(width - 0.08, 0.18, length - 0.08), Vector3.UP * 0.09, dark)
			for i in range(5):
				var angle: float = TAU * i / 5.0
				oval(root, Vector3(0.55, 0.48, 0.55), Vector3(cos(angle) * 0.38, height - 0.49, sin(angle) * 0.38), mat if i % 2 == 0 else dark)
		"tree_cone_2x2x4":
			box(root, Vector3(width - 0.07, 0.20, length - 0.07), Vector3.UP * 0.10, tint(mat, Color("#77583d")))
			cylinder(root, width * 0.14, width * 0.10, height * 0.45, Vector3.UP * height * 0.225, tint(mat, Color("#7b5639")))
			for i in range(3):
				var radius: float = width * (0.48 - 0.08 * i)
				var cone_height: float = height * 0.39
				var y: float = height * (0.27 + 0.17 * i) + cone_height * 0.5
				cylinder(root, radius, 0.03, cone_height, Vector3.UP * y, light if i == 2 else mat, 14)
		"crate_2x2", "chest_treasure_2x3", "chimney_2x2":
			furnishing(root, id, Vector3(width, height, length), mat, dark)
		"barrel_2x2":
			cylinder(root, width * 0.38, width * 0.48, height * 0.5, Vector3.UP * height * 0.25, mat, 24)
			cylinder(root, width * 0.48, width * 0.38, height * 0.5, Vector3.UP * height * 0.75, mat, 24)
			for fraction in [0.19, 0.81]:
				cylinder(root, width * 0.43, width * 0.43, height * 0.09, Vector3.UP * height * fraction, dark, 24)
		"bench_1x4":
			box(root, Vector3(width * 0.74, 0.12, length - 0.09), Vector3.UP * 0.06, dark)
			box(root, Vector3(width * 0.88, 0.16, length - 0.05), Vector3(0, height * 0.51, 0), mat)
			box(root, Vector3(width * 0.20, 0.35, length - 0.05), Vector3(0.37, height - 0.175, 0), mat)
			for sign_z in [-1.0, 1.0]:
				box(root, Vector3(width * 0.75, height * 0.43, 0.22), Vector3(0, height * 0.215, sign_z * length * 0.39), dark)
		"flag_1x2":
			box(root, Vector3(width * 0.80, 0.14, length - 0.06), Vector3.UP * 0.07, dark)
			cylinder(root, 0.24, 0.18, 0.18, Vector3(0, 0.09, -length * 0.30), dark)
			cylinder(root, 0.06, 0.05, height, Vector3(0, height * 0.5, -length * 0.30), dark)
			var profile := PackedVector2Array([Vector2(-length * 0.29, height * 0.46), Vector2(length * 0.48, height * 0.72), Vector2(-length * 0.29, height * 0.98)])
			extrude_profile(root, profile, 0.075, mat)
		"crystal_1x1":
			cylinder(root, width * 0.39, width * 0.39, height * 0.77, Vector3.UP * height * 0.385, mat, 6)
			cylinder(root, width * 0.39, 0.0, height * 0.23, Vector3.UP * height * 0.885, light, 6)
		"cup_1x1", "bucket_1x1":
			var radius: float = width * (0.36 if id == "cup_1x1" else 0.43)
			hollow_cup(root, radius, height * 0.88, mat, dark)
			if id == "cup_1x1":
				ring(root, 0.13, 0.045, Vector3(0, height * 0.54, radius - 0.04), mat).rotation_degrees.z = 90.0
			else:
				ring(root, 0.30, 0.036, Vector3.UP * (height - 0.335), mat).rotation_degrees.x = 90.0
		"steering_wheel_2x2":
			box(root, Vector3(width - 0.06, 0.20, length - 0.06), Vector3.UP * 0.10, mat)
			box(root, Vector3(0.25, height * 0.47, 0.26), Vector3.UP * height * 0.38, dark)
			var center := Vector3(0, height * 0.61, 0)
			ring(root, height * 0.32, 0.054, center, mat).rotation_degrees.x = 90.0
			for i in range(6):
				var angle: float = TAU * i / 6.0
				var spoke := box(root, Vector3(0.07, height * 0.37, 0.07), center + Vector3(sin(angle), cos(angle), 0) * height * 0.18, mat)
				spoke.rotation.z = -angle
			oval(root, Vector3(0.12, 0.12, 0.11), center, dark)
		"anchor_coastal_2x3":
			box(root, Vector3(width * 0.12, height * 0.48, length * 0.59), Vector3(0, height * 0.24, 0.23), mat)
			ring(root, 0.29, 0.09, Vector3(0, height * 0.24, length * 0.35), dark)
			box(root, Vector3(width * 0.68, height * 0.43, 0.19), Vector3(0, height * 0.215, length * 0.16), mat)
			for sign_x in [-1.0, 1.0]:
				var fluke := box(root, Vector3(width * 0.45, height * 0.52, 0.24), Vector3(sign_x * width * 0.22, height * 0.26, -length * 0.26), mat)
				fluke.rotation.y = sign_x * 0.58
				var tip := box(root, Vector3(0.29, height * 0.6, 0.46), Vector3(sign_x * width * 0.36, height * 0.3, -length * 0.32), dark)
				tip.rotation.y = -sign_x * 0.58
		"lighthouse_top_4x4":
			lantern(root, height, width, mat, dark)
		"buoy_marker_1x1":
			cylinder(root, width * 0.38, width * 0.47, height * 0.36, Vector3.UP * height * 0.18, dark, 20)
			cylinder(root, width * 0.47, width * 0.16, height * 0.54, Vector3.UP * height * 0.63, mat, 20)
			oval(root, Vector3(0.13, 0.13, 0.13), Vector3.UP * (height - 0.13), light)
		"life_ring_2x2":
			ring(root, width * 0.38, height * 0.48, Vector3.UP * height * 0.48, mat)
			for i in range(4):
				var angle: float = TAU * i / 4.0
				var strap := box(root, Vector3(0.18, height * 0.32, height * 0.94), Vector3(sin(angle) * width * 0.38, height * 0.71, cos(angle) * width * 0.38), light)
				strap.rotation.y = angle
		"fire_pit_2x2":
			for i in range(9):
				var angle: float = TAU * i / 9.0
				oval(root, Vector3(0.24, 0.22, 0.26), Vector3(cos(angle) * width * 0.36, 0.22, sin(angle) * length * 0.36), mat)
			for angle in [-0.68, 0.68]:
				var log_mesh := cylinder(root, 0.14, 0.14, length * 0.53, Vector3.UP * 0.14, tint(mat, Color("#7b5639")), 10)
				log_mesh.rotation = Vector3(PI * 0.5, angle, 0.0)
			cylinder(root, 0.31, 0.05, height * 0.71, Vector3.UP * height * 0.61, tint(mat, Color("#e78b4d")), 8)
		"signpost_1x2":
			box(root, Vector3(0.31, height, 0.28), Vector3.UP * height * 0.5, dark)
			var sign_profile := PackedVector2Array([Vector2(-length * 0.48, height * 0.57), Vector2(length * 0.24, height * 0.57), Vector2(length * 0.48, height * 0.73), Vector2(length * 0.24, height * 0.90), Vector2(-length * 0.48, height * 0.90)])
			extrude_profile(root, sign_profile, 0.19, mat)
		"bell_harbour_1x1":
			hollow_cup(root, width * 0.44, height * 0.69, mat, dark, true)
			oval(root, Vector3(0.13, 0.16, 0.13), Vector3.UP * 0.18, light)
			ring(root, 0.13, 0.046, Vector3.UP * (height - 0.15), mat).rotation_degrees.x = 90.0
		"telescope_1x2":
			cylinder(root, 0.22, 0.16, height * 0.51, Vector3.UP * height * 0.255, dark)
			var tube := cylinder(root, 0.17, 0.26, length * 0.78, Vector3.UP * height * 0.62, mat)
			tube.rotation_degrees.x = 72.0
			var lens := cylinder(root, 0.26, 0.26, 0.09, Vector3(0, height * 0.45, -length * 0.36), tint(mat, Color("#95bac2")))
			lens.rotation_degrees.x = 72.0
		"candle_cabin_1x1":
			cylinder(root, 0.28, 0.26, height * 0.72, Vector3.UP * height * 0.36, mat)
			cylinder(root, 0.035, 0.035, 0.09, Vector3.UP * height * 0.74, dark)
			oval(root, Vector3(0.085, 0.14, 0.085), Vector3.UP * height * 0.88, tint(mat, Color("#ffd580")))
		"fish_coastal_1x2":
			oval(root, Vector3(width * 0.33, height * 0.49, length * 0.31), Vector3(0, height * 0.50, -length * 0.13), mat)
			var tail_profile := PackedVector2Array([Vector2(length * 0.11, height * 0.51), Vector2(length * 0.46, height * 0.08), Vector2(length * 0.40, height * 0.51), Vector2(length * 0.46, height * 0.96)])
			extrude_profile(root, tail_profile, width * 0.13, dark)
			for side in [-1.0, 1.0]:
				oval(root, Vector3(0.035, 0.045, 0.045), Vector3(side * width * 0.22, height * 0.56, -length * 0.34), dark)
		"bird_seagull_1x1":
			oval(root, Vector3(width * 0.26, height * 0.24, length * 0.32), Vector3(0, height * 0.43, 0), mat)
			oval(root, Vector3(width * 0.19, height * 0.22, length * 0.20), Vector3(0, height * 0.73, -length * 0.23), light)
			var bill: StandardMaterial3D = tint(mat, Color("#d7a553"))
			for side in [-1.0, 1.0]:
				var wing := oval(root, Vector3(width * 0.27, height * 0.12, length * 0.26), Vector3(side * width * 0.20, height * 0.57, length * 0.06), dark)
				wing.rotation.z = side * 0.23
				cylinder(root, 0.038, 0.034, 0.21, Vector3(side * 0.10, 0.12, 0.02), bill, 10)
				box(root, Vector3(0.105, 0.035, 0.17), Vector3(side * 0.10, 0.0175, -0.025), bill)
			oval(root, Vector3(width * 0.08, height * 0.085, length * 0.14), Vector3(0, height * 0.69, -length * 0.34), bill)
		_:
			return false
	return true

static func furnishing(root: Node3D, id: String, dims: Vector3, mat: Material, dark: Material) -> void:
	var body := Vector3(dims.x - 0.10, dims.y, dims.z - 0.10)
	box(root, body, Vector3.UP * dims.y * 0.5, dark)
	if id == "chimney_2x2":
		for tier in range(5):
			var slab_height: float = dims.y / 5.0
			var band: float = 0.07 if tier == 4 else 0.13
			box(root, Vector3(dims.x - band, slab_height - 0.045, dims.z - band), Vector3.UP * slab_height * (tier + 0.5), mat)
		return
	for side in [-1.0, 1.0]:
		for i in range(3):
			var y: float = dims.y * (0.17 + 0.31 * i)
			box(root, Vector3(0.08, dims.y * 0.27, dims.z - 0.16), Vector3(side * (dims.x - 0.10) * 0.5, y, 0), mat)
			box(root, Vector3(dims.x - 0.16, dims.y * 0.27, 0.08), Vector3(0, y, side * (dims.z - 0.10) * 0.5), mat)
		for edge in [-1.0, 1.0]:
			box(root, Vector3(0.16, dims.y, 0.16), Vector3(side * (dims.x - 0.2) * 0.5, dims.y * 0.5, edge * (dims.z - 0.2) * 0.5), mat)
	if id == "chest_treasure_2x3":
		box(root, Vector3(0.12, dims.y * 0.22, 0.26), Vector3(-dims.x * 0.46, dims.y * 0.58, 0), tint(mat, Color("#e9b965")))

static func railing(root: Node3D, length: float, height: float, pickets: bool, mat: Material) -> void:
	for y in [height * 0.18, height - 0.09]:
		box(root, Vector3(0.42, 0.18, length - 0.035), Vector3(0, y, 0), mat)
	var posts: int = int(length) + 1 if pickets else int(length)
	for i in range(posts):
		var z: float = lerpf(-length * 0.5 + 0.17, length * 0.5 - 0.17, float(i) / (posts - 1))
		box(root, Vector3(0.52, height, 0.19 if pickets else 0.25), Vector3(0, height * 0.5, z), mat)

static func lantern(root: Node3D, height: float, width: float, mat: Material, dark: Material) -> void:
	var base: float = width * 0.24
	cylinder(root, width * 0.44, width * 0.41, 0.18, Vector3.UP * 0.09, mat, 20)
	var post_height: float = height * (0.22 if width > 2.0 else 0.55)
	cylinder(root, width * 0.13, width * 0.10, post_height, Vector3.UP * post_height * 0.5, dark)
	var globe_height: float = height * 0.23
	box(root, Vector3(base * 1.55, globe_height, base * 1.55), Vector3.UP * (post_height + globe_height * 0.5), tint(mat, Color("#edc981")))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			box(root, Vector3(base * 0.24, globe_height, base * 0.24), Vector3(sx * base * 0.82, post_height + globe_height * 0.5, sz * base * 0.82), dark)
	var roof_height: float = height - post_height - globe_height
	cylinder(root, base * 1.47, base * 0.42, roof_height, Vector3.UP * (height - roof_height * 0.5), mat, 8)

static func tint(reference: Material, color: Color) -> StandardMaterial3D:
	var material: StandardMaterial3D = reference.duplicate()
	material.albedo_color = color
	return material

static func add_mesh(root: Node3D, mesh: Mesh, position: Vector3, mat: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = mat
	node.position = position
	root.add_child(node)
	return node

static func box(root: Node3D, size: Vector3, position: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return add_mesh(root, mesh, position, mat)

static func cylinder(root: Node3D, bottom: float, top: float, height: float, position: Vector3, mat: Material, sides: int = 20) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = bottom
	mesh.top_radius = top
	mesh.height = height
	mesh.radial_segments = sides
	return add_mesh(root, mesh, position, mat)

static func oval(root: Node3D, radius: Vector3, position: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radial_segments = 16
	mesh.rings = 8
	var node := add_mesh(root, mesh, position, mat)
	node.scale = radius * 2.0
	return node

static func ring(root: Node3D, radius: float, tube: float, position: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius - tube
	mesh.outer_radius = radius + tube
	mesh.rings = 24
	mesh.ring_segments = 10
	return add_mesh(root, mesh, position, mat)

static func hollow_cup(root: Node3D, radius: float, height: float, mat: Material, dark: Material, flipped: bool = false) -> void:
	var body := Node3D.new()
	root.add_child(body)
	if flipped:
		body.position.y = height
		body.rotation.z = PI
	cylinder(body, radius * 0.67, radius * 0.69, 0.12, Vector3.UP * 0.06, dark)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	for i in range(24):
		var angle: float = TAU * i / 24.0
		var next_angle: float = TAU * (i + 1) / 24.0
		var v := Vector3(cos(angle), 0, sin(angle))
		var next := Vector3(cos(next_angle), 0, sin(next_angle))
		var bottom: Vector3 = v * radius * 0.67
		var bottom_next: Vector3 = next * radius * 0.67
		var top: Vector3 = v * radius + Vector3.UP * height
		var top_next: Vector3 = next * radius + Vector3.UP * height
		var lip: Vector3 = v * radius * 0.82 + Vector3.UP * height
		var lip_next: Vector3 = next * radius * 0.82 + Vector3.UP * height
		var inner: Vector3 = v * radius * 0.52 + Vector3.UP * 0.12
		var inner_next: Vector3 = next * radius * 0.52 + Vector3.UP * 0.12
		_quad(surface, bottom, bottom_next, top_next, top, v)
		_quad(surface, top, top_next, lip_next, lip, Vector3.UP)
		_quad(surface, lip, lip_next, inner_next, inner, -v)
	surface.generate_normals()
	add_mesh(body, surface.commit(), Vector3.ZERO, mat)

static func arch_profile(length: float, height: float) -> PackedVector2Array:
	var end: float = length * 0.5 - 0.018
	var inner: float = end - 0.73
	var profile := PackedVector2Array([Vector2(-end, 0.0)])
	for i in range(17):
		var t: float = lerpf(-1.0, 1.0, i / 16.0)
		profile.append(Vector2(inner * t, (height - 0.4) * sqrt(maxf(0.0, 1.0 - t * t))))
	profile.append_array([Vector2(end, 0.0), Vector2(end, height), Vector2(-end, height)])
	return profile

static func extrude_profile(root: Node3D, profile: PackedVector2Array, width: float, mat: Material) -> void:
	var triangles := Geometry2D.triangulate_polygon(profile)
	if triangles.is_empty():
		return
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	var half: float = width * 0.5
	for i in range(0, triangles.size(), 3):
		var a: Vector2 = profile[triangles[i]]
		var b: Vector2 = profile[triangles[i + 1]]
		var c: Vector2 = profile[triangles[i + 2]]
		for side in [-1.0, 1.0]:
			_triangle(surface, Vector3(side * half, a.y, a.x), Vector3(side * half, b.y, b.x), Vector3(side * half, c.y, c.x), Vector3.RIGHT * side)
	var winding: float = -1.0 if Geometry2D.is_polygon_clockwise(profile) else 1.0
	for i in range(profile.size()):
		var a: Vector2 = profile[i]
		var b: Vector2 = profile[(i + 1) % profile.size()]
		var outward := Vector3(0, a.x - b.x, b.y - a.y) * winding
		_quad(surface, Vector3(-half, a.y, a.x), Vector3(-half, b.y, b.x), Vector3(half, b.y, b.x), Vector3(half, a.y, a.x), outward)
	surface.generate_normals()
	add_mesh(root, surface.commit(), Vector3.ZERO, mat)

static func build_corner_slope(root: Node3D, dims: Vector3, mat: Material) -> void:
	var x: float = dims.x * 0.5 - 0.018
	var z: float = dims.z * 0.5 - 0.018
	var a := Vector3(-x, 0.18, -z)
	var b := Vector3(x, 0.18, -z)
	var c := Vector3(x, dims.y, z)
	var d := Vector3(-x, 0.18, z)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	_triangle(surface, a, b, c, Vector3.UP)
	_triangle(surface, a, c, d, Vector3.UP)
	var corners := [a, b, c, d]
	var directions := [Vector3.FORWARD, Vector3.RIGHT, Vector3.BACK, Vector3.LEFT]
	for i in range(4):
		var start: Vector3 = corners[i]
		var end: Vector3 = corners[(i + 1) % 4]
		_quad(surface, start, end, Vector3(end.x, 0, end.z), Vector3(start.x, 0, start.z), directions[i])
	_quad(surface, Vector3(-x, 0, -z), Vector3(x, 0, -z), Vector3(x, 0, z), Vector3(-x, 0, z), Vector3.DOWN)
	surface.generate_normals()
	add_mesh(root, surface.commit(), Vector3.ZERO, mat)

static func _quad(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, outward: Vector3) -> void:
	_triangle(surface, a, b, c, outward)
	_triangle(surface, a, c, d, outward)

static func _triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, outward: Vector3) -> void:
	surface.add_vertex(a)
	if (b - a).cross(c - a).dot(outward) > 0.0:
		surface.add_vertex(c)
		surface.add_vertex(b)
	else:
		surface.add_vertex(b)
		surface.add_vertex(c)
