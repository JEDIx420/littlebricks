extends Node3D

## Articulated LittleBricks figure. The face points along -Z and every playable
## head fits inside the same four-stud collision envelope.

const STYLES := {
	"toy_explorer_pippin": "Pippin",
	"toy_explorer_marina": "Marina",
	"toy_explorer_rowan": "Rowan",
	"toy_explorer_darth_vader": "Darth Vader",
	"toy_explorer_stormtrooper": "Stormtrooper",
	"toy_explorer_iron_man": "Iron Man",
	"toy_explorer_captain_america": "Captain America",
}

const VADER_HELMET = preload("res://assets/sourced/ldraw_figures/vader_helmet.glb")
const TROOPER_HELMET = preload("res://assets/sourced/ldraw_figures/trooper_helmet.glb")
const IRON_HELMET = preload("res://assets/sourced/ldraw_figures/iron_helmet.glb")
const CAPTAIN_SHIELD = preload("res://assets/sourced/ldraw_figures/captain_shield.glb")

var _left_leg: Node3D
var _right_leg: Node3D
var _left_arm: Node3D
var _right_arm: Node3D
var _swing: float = 0.0
var _style: String = ""

func _ready() -> void:
	if _style.is_empty():
		configure("toy_explorer_pippin")

func configure(variant: String) -> void:
	var style := variant if STYLES.has(variant) else "toy_explorer_pippin"
	if _style == style:
		return
	_style = style
	for child in get_children():
		remove_child(child)
		child.queue_free()

	var jacket_color := Color("#ad4c31")
	var trousers_color := Color("#2c4d65")
	var strap_color := Color("#62442e")
	var hand_color := Color("#f0bb58")
	match _style:
		"toy_explorer_marina":
			jacket_color = Color("#277b70")
			trousers_color = Color("#dbc4a0")
			strap_color = Color("#614835")
		"toy_explorer_rowan":
			jacket_color = Color("#506d46")
			trousers_color = Color("#625569")
			strap_color = Color("#343f40")
		"toy_explorer_darth_vader":
			jacket_color = Color("#282a31")
			trousers_color = Color("#272931")
			hand_color = Color("#202126")
		"toy_explorer_stormtrooper":
			jacket_color = Color("#e8e6df")
			trousers_color = Color("#dcdcd5")
			hand_color = Color("#252a2d")
		"toy_explorer_iron_man":
			jacket_color = Color("#ab202a")
			trousers_color = Color("#8b212e")
			hand_color = Color("#c62d32")
		"toy_explorer_captain_america":
			jacket_color = Color("#28568b")
			trousers_color = Color("#21456c")
			hand_color = Color("#a12b36")

	var plastic := _material(hand_color, 0.34)
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

	match _style:
		"toy_explorer_darth_vader":
			_dress_vader()
			return
		"toy_explorer_stormtrooper":
			_dress_stormtrooper()
			return
		"toy_explorer_iron_man":
			_dress_iron_man()
			return
		"toy_explorer_captain_america":
			_dress_captain_america(coat, ink, cream)
			return

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

func get_render_bounds() -> AABB:
	return _render_bounds(self, Transform3D.IDENTITY)

func _render_bounds(node: Node3D, model_space: Transform3D) -> AABB:
	var bounds := AABB()
	if node is MeshInstance3D and node.mesh:
		bounds = model_space * node.get_aabb()
	for child in node.get_children():
		if child is Node3D:
			bounds = bounds.merge(_render_bounds(child, model_space * child.transform))
	return bounds

func _dress_vader() -> void:
	_accessory(self, VADER_HELMET, Vector3(0, 3.62, 0), 0.72)
	var graphite := _material(Color("#42434c"), 0.48)
	var black := _material(Color("#1e2027"), 0.72)
	var buckle := _material(Color("#8c909b"), 0.44)
	var red := _material(Color("#cb3646"), 0.36)
	var blue := _material(Color("#5b9cc7"), 0.32)
	_mold(self, Vector3(0, 2.19, -0.50), Vector3(0.60, 0.47, 0.08), 0.026, black)
	for x in [-0.39, 0.39]:
		_mold(self, Vector3(x, 2.60, -0.49), Vector3(0.30, 0.19, 0.08), 0.03, graphite).rotation.z = x * 0.38
		_mold(self, Vector3(x, 1.48, -0.47), Vector3(0.22, 0.17, 0.08), 0.02, black)
		_mold(self, Vector3(x, 1.49, -0.52), Vector3(0.10, 0.06, 0.025), 0.01, buckle)
	for i in 3:
		_mold(self, Vector3(-0.17 + i * 0.17, 2.24, -0.549), Vector3(0.10, 0.095, 0.025), 0.01, red if i == 0 else blue)
	_mold(self, Vector3(0, 2.09, -0.547), Vector3(0.36, 0.06, 0.020), 0.008, buckle)
	var cape := SurfaceTool.new()
	cape.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 20:
		var a := -1.0 + i * 0.10
		var b := a + 0.10
		_quad(cape, _cape_corner(a, false), _cape_corner(b, false),
			_cape_corner(b, true), _cape_corner(a, true))
	black.cull_mode = BaseMaterial3D.CULL_DISABLED
	_instance(self, Vector3.ZERO, cape, black)
	var hilt := _material(Color("#6b717c"), 0.34)
	_lathe(_right_arm, Vector3(0.23, -0.94, -0.28), [
		Vector2(0.08, -0.19), Vector2(0.11, -0.15), Vector2(0.11, 0.21), Vector2(0.08, 0.24)], hilt)
	red.emission_enabled = true
	red.emission = Color("#ff183c")
	red.emission_energy_multiplier = 0.7
	_lathe(_right_arm, Vector3(0.23, -0.71, -0.28), [
		Vector2(0.066, 0), Vector2(0.065, 1.35), Vector2(0.035, 1.39)], red)

func _cape_corner(x: float, hem: bool) -> Vector3:
	if hem:
		return Vector3(x * 1.01, 0.24 + absf(x) * 0.13, 0.68 + cos(x * 15.0) * 0.09 + (1.0 - absf(x)) * 0.19)
	return Vector3(x * 0.60, 2.76 - absf(x) * 0.06, 0.39 + cos(x * 15.0) * 0.032)

func _dress_stormtrooper() -> void:
	_accessory(self, TROOPER_HELMET, Vector3(0, 3.54, 0), 0.62)
	var carbon := _material(Color("#252b30"), 0.48)
	var white := _material(Color("#f0eee6"), 0.41)
	_mold(self, Vector3(0, 2.42, -0.484), Vector3(1.08, 0.39, 0.08), 0.036, white)
	_mold(self, Vector3(0, 1.57, -0.466), Vector3(1.58, 0.17, 0.06), 0.021, carbon)
	for i in 5:
		_mold(self, Vector3(-0.53 + i * 0.263, 1.57, -0.502), Vector3(0.18, 0.14, 0.052), 0.017, white)
	for i in 3:
		_mold(self, Vector3(0, 1.89 + i * 0.072, -0.478), Vector3(0.59 - i * 0.05, 0.038, 0.035), 0.01, carbon)
	for leg in [_left_leg, _right_leg]:
		_mold(leg, Vector3(0, -0.76, -0.41), Vector3(0.45, 0.16, 0.07), 0.026, carbon)

func _dress_iron_man() -> void:
	_accessory(self, IRON_HELMET, Vector3(0, 3.53, 0), 0.68)
	var gold := _material(Color("#c99839"), 0.35)
	var slate := _material(Color("#492b30"), 0.44)
	var reactor := _material(Color("#b9f5ff"), 0.35)
	reactor.emission_enabled = true
	reactor.emission = Color("#7bd1ff")
	reactor.emission_energy_multiplier = 0.46
	_medallion(self, Vector3(0, 2.37, -0.51), 0.205, 0.09, slate)
	_medallion(self, Vector3(0, 2.37, -0.565), 0.133, 0.030, gold)
	_medallion(self, Vector3(0, 2.37, -0.588), 0.095, 0.019, reactor)
	for x in [-0.46, 0.46]:
		_mold(self, Vector3(x, 2.54, -0.492), Vector3(0.33, 0.18, 0.062), 0.03, gold).rotation.z = x * 0.4
	for leg in [_left_leg, _right_leg]:
		_mold(leg, Vector3(0, -0.52, -0.418), Vector3(0.35, 0.42, 0.06), 0.028, gold, 0.42)
	_mold(self, Vector3(0, 2.38, 0.515), Vector3(0.69, 0.50, 0.13), 0.05, slate)
	for x in [-0.20, 0.20]:
		_medallion(self, Vector3(x, 2.40, 0.589), 0.068, 0.018, reactor)

func _dress_captain_america(blue: Material, ink: Material, white: Material) -> void:
	var red := _material(Color("#ae2936"), 0.43)
	var skin := _material(Color("#f1bd92"), 0.52)
	_lathe(self, Vector3(0, 3.11, 0), [
		Vector2(0.44, -0.24), Vector2(0.572, -0.16), Vector2(0.572, 0.25)], skin)
	_lathe(self, Vector3(0, 3.33, 0), [
		Vector2(0.574, -0.10), Vector2(0.576, 0.30), Vector2(0.54, 0.40),
		Vector2(0.42, 0.47), Vector2(0.25, 0.49)], blue)
	for side in [-1.0, 1.0]:
		_face_dot(Vector2(side * 0.198, 0.044), Vector2(0.093, 0.047), skin, 0.004)
		_face_dot(Vector2(side * 0.198, 0.044), Vector2(0.041, 0.040), ink, 0.008)
	_face_line([Vector2(-0.08, -0.16), Vector2(0.04, -0.174), Vector2(0.11, -0.15)], 0.023, ink)
	_face_line([Vector2(-0.071, 0.176), Vector2(0, 0.298), Vector2(0.071, 0.176)], 0.025, white)
	_face_line([Vector2(-0.040, 0.220), Vector2(0.040, 0.220)], 0.020, white)
	_star(Vector3(0, 2.43, -0.49), 0.214, white)
	for i in 5:
		_mold(self, Vector3(-0.34 + i * 0.17, 1.89, -0.487), Vector3(0.132, 0.36, 0.035), 0.012,
			red if i % 2 == 0 else white)
	var shield := _accessory(_left_arm, CAPTAIN_SHIELD, Vector3(-0.29, -0.71, -0.49), 0.63)
	shield.rotation_degrees.y = -18.0
	shield.rotation_degrees.x = -5.0

func _star(center: Vector3, radius: float, material: Material) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 10:
		var a := PI / 2.0 + i * TAU / 10.0
		var b := a + TAU / 10.0
		var first := radius if i % 2 == 0 else radius * 0.43
		var second := radius * 0.43 if i % 2 == 0 else radius
		_triangle(surface, Vector3.ZERO, Vector3(cos(a), sin(a), 0) * first,
			Vector3(cos(b), sin(b), 0) * second)
	_instance(self, center, surface, material)

func _medallion(parent: Node3D, center: Vector3, radius: float, thickness: float,
		material: Material) -> void:
	var mesh := _lathe(parent, center, [
		Vector2(radius * 0.92, -thickness * 0.5), Vector2(radius, -thickness * 0.35),
		Vector2(radius, thickness * 0.35), Vector2(radius * 0.92, thickness * 0.5)], material)
	mesh.rotation.x = PI / 2.0

func _accessory(parent: Node3D, packed: PackedScene, center: Vector3, factor: float) -> Node3D:
	var item := packed.instantiate() as Node3D
	item.position = center
	item.scale = Vector3.ONE * factor
	parent.add_child(item)
	return item

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
