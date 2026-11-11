extends Node3D

## Original LittleBricks explorer. Feet sit at the origin, the face points along -Z,
## and the head stud stays below the four-stud exploration collision envelope.

var _left_leg: Node3D
var _right_leg: Node3D
var _left_arm: Node3D
var _right_arm: Node3D
var _swing: float = 0.0

func _ready() -> void:
	configure("")

func configure(variant: String) -> void:
	if _left_leg:
		return

	var jacket_color := Color("#ad4c31")
	var trousers_color := Color("#2c4d65")
	var strap_color := Color("#62442e")
	if variant.ends_with("marina"):
		jacket_color = Color("#277b70")
		trousers_color = Color("#dbc4a0")
		strap_color = Color("#614835")
	elif variant.ends_with("rowan"):
		jacket_color = Color("#506d46")
		trousers_color = Color("#625569")
		strap_color = Color("#343f40")

	var plastic := _material(Color("#f0bb58"), 0.30)
	var coat := _material(jacket_color, 0.32)
	var pants := _material(trousers_color, 0.34)
	var boots := _material(trousers_color.darkened(0.22), 0.36)
	var leather := _material(strap_color, 0.57)
	var pack := _material(Color("#c59352"), 0.55)
	var pack_trim := _material(Color("#9b6b3c"), 0.58)
	var ink := _material(Color("#382724"), 0.52)
	var cream := _material(Color("#f6dfb0"), 0.44)
	var brass := _material(Color("#db9d45"), 0.28)

	# Separate hinge groups keep the walk articulated and preserve the hip seam.
	_left_leg = _pivot("LeftLeg", Vector3(-0.395, 1.42, 0))
	_right_leg = _pivot("RightLeg", Vector3(0.395, 1.42, 0))
	for leg in [_left_leg, _right_leg]:
		_mold(leg, Vector3(0, -0.58, 0.015), Vector3(0.73, 1.16, 0.83), 0.08, pants)
		_mold(leg, Vector3(0, -1.24, -0.105), Vector3(0.75, 0.36, 1.07), 0.07, boots)
	_mold(self, Vector3(0, 1.49, 0.0), Vector3(1.57, 0.31, 0.90), 0.075, pants)
	_mold(self, Vector3(0, 2.24, 0.0), Vector3(1.62, 1.19, 0.95), 0.10, coat, 1.22)
	_lathe(self, Vector3(0, 2.90, 0), [Vector2(0.25, -0.11), Vector2(0.29, -0.08),
		Vector2(0.29, 0.07), Vector2(0.25, 0.11)], plastic)

	_left_arm = _make_arm(-1.0, coat, plastic)
	_right_arm = _make_arm(1.0, coat, plastic)

	# Molded head with a neck rim, rounded bevels and a visible top stud.
	_lathe(self, Vector3(0, 3.29, 0), [
		Vector2(0.38, -0.405), Vector2(0.49, -0.39), Vector2(0.552, -0.34),
		Vector2(0.572, -0.27), Vector2(0.572, 0.29), Vector2(0.55, 0.35),
		Vector2(0.49, 0.40), Vector2(0.38, 0.421)], plastic)
	_lathe(self, Vector3(0, 3.71, 0), [
		Vector2(0.245, -0.012), Vector2(0.294, 0.012), Vector2(0.308, 0.045),
		Vector2(0.308, 0.145), Vector2(0.28, 0.18)], plastic)

	for side in [-1.0, 1.0]:
		_face_dot(Vector2(side * 0.206, 0.042), Vector2(0.043, 0.055), ink)
		_face_dot(Vector2(side * 0.206 - 0.011, 0.058), Vector2(0.011, 0.013), cream, 0.003)
		_face_dot(Vector2(side * 0.29, -0.075), Vector2(0.014, 0.011), leather)
		_face_dot(Vector2(side * 0.34, -0.060), Vector2(0.012, 0.01), leather)
	_face_line([
		Vector2(-0.151, -0.124), Vector2(-0.104, -0.158), Vector2(-0.052, -0.176),
		Vector2(0.014, -0.183), Vector2(0.081, -0.164), Vector2(0.144, -0.118)], 0.022, ink)

	# Printed collar, jacket seam and a small enamel route badge.
	_mold(self, Vector3(-0.102, 2.696, -0.476), Vector3(0.20, 0.070, 0.020), 0.007, cream).rotation.z = -0.50
	_mold(self, Vector3(0.102, 2.696, -0.476), Vector3(0.20, 0.070, 0.020), 0.007, cream).rotation.z = 0.50
	_mold(self, Vector3(0, 2.18, -0.476), Vector3(0.028, 0.82, 0.016), 0.006, leather)
	for button_y in [1.92, 2.13, 2.35]:
		_mold(self, Vector3(0.068, button_y, -0.48), Vector3(0.037, 0.042, 0.017), 0.007, brass)
	_mold(self, Vector3(-0.168, 2.35, -0.48), Vector3(0.153, 0.137, 0.022), 0.010, pants)
	_mold(self, Vector3(-0.168, 2.35, -0.496), Vector3(0.066, 0.066, 0.016), 0.007, cream).rotation.z = PI / 4.0

	# Field pack reads clearly in the normal over-the-shoulder camera.
	_mold(self, Vector3(0, 2.17, 0.59), Vector3(1.07, 0.94, 0.43), 0.095, pack)
	_mold(self, Vector3(0, 2.52, 0.70), Vector3(1.13, 0.32, 0.35), 0.075, pack_trim)
	_mold(self, Vector3(0, 2.11, 0.80), Vector3(0.60, 0.41, 0.13), 0.050, pack_trim)
	for strap_x in [-0.30, 0.30]:
		_mold(self, Vector3(strap_x, 2.42, -0.49), Vector3(0.086, 0.67, 0.034), 0.014, leather)
		_mold(self, Vector3(strap_x, 2.63, 0.20), Vector3(0.092, 0.10, 0.91), 0.031, leather)
		_mold(self, Vector3(strap_x, 2.42, 0.852), Vector3(0.092, 0.32, 0.031), 0.013, leather)
		_mold(self, Vector3(strap_x, 2.37, 0.874), Vector3(0.091, 0.077, 0.017), 0.007, brass)

func animate_walk(phase: float, amount: float, delta: float) -> void:
	_swing = move_toward(_swing, sin(phase) * 0.43 * amount, delta * 8.0)
	_left_leg.rotation.x = _swing
	_right_leg.rotation.x = -_swing
	_left_arm.rotation.x = -_swing * 0.75
	_right_arm.rotation.x = _swing * 0.75

func _make_arm(side: float, sleeve: Material, skin: Material) -> Node3D:
	var arm := _pivot("LeftArm" if side < 0.0 else "RightArm", Vector3(side * 0.655, 2.65, 0))
	var upper := _mold(arm, Vector3(side * 0.106, -0.223, 0.015),
		Vector3(0.45, 0.58, 0.50), 0.105, sleeve)
	upper.rotation.z = side * 0.36
	var forearm := _mold(arm, Vector3(side * 0.225, -0.578, -0.075),
		Vector3(0.39, 0.47, 0.45), 0.08, sleeve)
	forearm.rotation.x = 0.33
	_mold(arm, Vector3(side * 0.225, -0.795, -0.154), Vector3(0.23, 0.19, 0.26), 0.06, skin)
	var hand := _claw(arm, Vector3(side * 0.225, -0.925, -0.227), skin)
	hand.rotation.z = side * 0.32
	hand.rotation.y = side * 0.28
	return arm

func _pivot(pivot_name: String, center: Vector3) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = pivot_name
	pivot.position = center
	add_child(pivot)
	return pivot

func _material(tint: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.roughness = roughness
	material.metallic_specular = 0.32
	return material

func _mold(parent: Node3D, center: Vector3, size: Vector3, radius: float,
		material: Material, top_width: float = -1.0) -> MeshInstance3D:
	var rings: Array[PackedVector3Array] = []
	var width_top := top_width if top_width > 0.0 else size.x
	var half_height := size.y * 0.5
	var lower_roll := Vector2(0.2929 * radius, 0.2929 * radius)
	var upper_roll := Vector2(0.2929 * radius, 0.7071 * radius)
	var profiles := [
		Vector2(-half_height, radius), Vector2(-half_height + lower_roll.x, upper_roll.y),
		Vector2(-half_height + upper_roll.y, lower_roll.x), Vector2(-half_height + radius, 0),
		Vector2(half_height - radius, 0), Vector2(half_height - upper_roll.y, lower_roll.x),
		Vector2(half_height - lower_roll.x, upper_roll.y), Vector2(half_height, radius)
	]
	for profile: Vector2 in profiles:
		var blend := (profile.x + half_height) / size.y
		var half_x := lerpf(size.x, width_top, blend) * 0.5
		var half_z := size.z * 0.5
		var ring := PackedVector3Array()
		for corner in range(4):
			var start := float(corner) * PI / 2.0
			var midpoint := start + PI / 4.0
			var corner_x := signf(cos(midpoint)) * (half_x - radius)
			var corner_z := signf(sin(midpoint)) * (half_z - radius)
			for step in range(5):
				var angle := start + float(step) * PI / 8.0
				var r := maxf(0.0005, radius - profile.y)
				ring.append(Vector3(corner_x + cos(angle) * r, profile.x, corner_z + sin(angle) * r))
		rings.append(ring)
	return _rings(parent, center, rings, material)

func _lathe(parent: Node3D, center: Vector3, profile: Array, material: Material) -> MeshInstance3D:
	var rings: Array[PackedVector3Array] = []
	for radius_y: Vector2 in profile:
		var ring := PackedVector3Array()
		for step in range(40):
			var angle := TAU * float(step) / 40.0
			ring.append(Vector3(cos(angle) * radius_y.x, radius_y.y, sin(angle) * radius_y.x))
		rings.append(ring)
	return _rings(parent, center, rings, material)

func _rings(parent: Node3D, center: Vector3, rings: Array[PackedVector3Array],
		material: Material) -> MeshInstance3D:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count := rings[0].size()
	for row in range(rings.size() - 1):
		var low := rings[row]
		var high := rings[row + 1]
		for i in range(count):
			var j := (i + 1) % count
			_quad(surface, low[i], low[j], high[j], high[i])
	var bottom := rings.front() as PackedVector3Array
	var top := rings.back() as PackedVector3Array
	for i in range(count):
		var j := (i + 1) % count
		_triangle(surface, Vector3(0, bottom[0].y, 0), bottom[j], bottom[i])
		_triangle(surface, Vector3(0, top[0].y, 0), top[i], top[j])
	return _instance(parent, center, surface, material)

func _claw(parent: Node3D, center: Vector3, material: Material) -> MeshInstance3D:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	# A real open profile, with an inner gripping wall and capped tips.
	var front_outer := PackedVector3Array()
	var front_inner := PackedVector3Array()
	var back_outer := PackedVector3Array()
	var back_inner := PackedVector3Array()
	for i in range(24):
		var angle := deg_to_rad(304.0 + 292.0 * float(i) / 23.0)
		var direction := Vector3(cos(angle), sin(angle), 0)
		front_outer.append(direction * 0.218 + Vector3(0, 0, -0.134))
		front_inner.append(direction * 0.125 + Vector3(0, 0, -0.134))
		back_outer.append(direction * 0.218 + Vector3(0, 0, 0.134))
		back_inner.append(direction * 0.125 + Vector3(0, 0, 0.134))
	for i in range(23):
		var j := i + 1
		_quad(surface, front_inner[i], front_outer[i], front_outer[j], front_inner[j])
		_quad(surface, back_inner[i], back_inner[j], back_outer[j], back_outer[i])
		_quad(surface, front_outer[i], back_outer[i], back_outer[j], front_outer[j])
		_quad(surface, front_inner[i], front_inner[j], back_inner[j], back_inner[i])
	_quad(surface, front_inner[0], back_inner[0], back_outer[0], front_outer[0])
	_quad(surface, front_inner[23], front_outer[23], back_outer[23], back_inner[23])
	return _instance(parent, center, surface, material)

func _face_dot(center: Vector2, radii: Vector2, material: Material, offset: float = 0.0) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(16):
		var a := TAU * float(i) / 16.0
		var b := TAU * float(i + 1) / 16.0
		_triangle(surface, _face_position(center, offset),
			_face_position(center + Vector2(cos(a), sin(a)) * radii, offset),
			_face_position(center + Vector2(cos(b), sin(b)) * radii, offset))
	var dot := _instance(self, Vector3.ZERO, surface, material)
	dot.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _face_line(points: Array, thickness: float, material: Material) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(points.size() - 1):
		var a: Vector2 = points[i]
		var b: Vector2 = points[i + 1]
		var edge := Vector2(0, thickness * 0.5)
		_quad(surface, _face_position(a - edge), _face_position(b - edge),
			_face_position(b + edge), _face_position(a + edge))
	var line := _instance(self, Vector3.ZERO, surface, material)
	line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _face_position(point: Vector2, offset: float = 0.0) -> Vector3:
	# Keep the print just proud of the cylinder skin so it follows the head curvature.
	return Vector3(point.x, 3.29 + point.y, -sqrt(0.572 * 0.572 - point.x * point.x) - 0.008 - offset)

func _instance(parent: Node3D, center: Vector3, surface: SurfaceTool, material: Material) -> MeshInstance3D:
	surface.index()
	surface.generate_normals()
	var item := MeshInstance3D.new()
	item.mesh = surface.commit()
	item.material_override = material
	item.position = center
	parent.add_child(item)
	return item

func _quad(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	_triangle(surface, a, b, c)
	_triangle(surface, a, c, d)

func _triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	surface.add_vertex(a)
	surface.add_vertex(b)
	surface.add_vertex(c)
