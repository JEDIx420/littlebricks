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
			jacket_color = Color("#202127")
			trousers_color = Color("#292b32")
			hand_color = Color("#202126")
		"toy_explorer_stormtrooper":
			jacket_color = Color("#cdd2d5")
			trousers_color = Color("#c2c7ca")
			hand_color = Color("#252a2d")
		"toy_explorer_iron_man":
			jacket_color = Color("#8f2631")
			trousers_color = Color("#722733")
			hand_color = Color("#c62d32")
		"toy_explorer_captain_america":
			jacket_color = Color("#31547b")
			trousers_color = Color("#263f5b")
			hand_color = Color("#a12b36")

	var plastic := _material(hand_color, 0.34)
	var coat := _material(jacket_color, 0.30)
	var pants := _material(trousers_color, 0.34)
	var boots := _material(trousers_color.darkened(0.24), 0.29)
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
		_mold(leg, Vector3(0, -0.56, 0.025), Vector3(0.72, 1.12, 0.84), 0.10, pants, 0.74)
		_mold(leg, Vector3(0, -1.24, -0.105), Vector3(0.75, 0.36, 1.07), 0.095, boots, 0.72)
	_mold(self, Vector3(0, 1.49, 0.0), Vector3(1.57, 0.31, 0.90), 0.075, pants)
	_mold(self, Vector3(0, 2.24, 0.0), Vector3(1.62, 1.19, 0.95), 0.14, coat, 1.23)
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
	var helmet := _accessory(self, VADER_HELMET, Vector3(0, 3.62, 0), 0.72)
	_finish_accessory(helmet, 0.26)
	var alloy := _material(Color("#555b67"), 0.28)
	var armor := _material(Color("#343942"), 0.27)
	var black := _material(Color("#171b22"), 0.40)
	var fabric := _material(Color("#23262d"), 0.86)
	var silver := _material(Color("#a0a6ae"), 0.29)
	var red := _material(Color("#9e3444"), 0.31)
	var blue := _material(Color("#578baa"), 0.31)

	# A single sculpted yoke sits over the suit and wraps over both shoulders.
	_panel(self, Vector3(0, 2.64, -0.46), [
		Vector2(-0.70, -0.10), Vector2(-0.44, -0.18), Vector2(0.44, -0.18),
		Vector2(0.70, -0.10), Vector2(0.59, 0.10), Vector2(0.30, 0.16),
		Vector2(-0.30, 0.16), Vector2(-0.59, 0.10)], 0.15, armor)
	for side in [-1.0, 1.0]:
		var shoulder := _mold(self, Vector3(side * 0.50, 2.65, -0.54),
			Vector3(0.30, 0.13, 0.07), 0.024, alloy, 0.22)
		shoulder.rotation.z = side * -0.24
		_mold(self, Vector3(side * 0.35, 2.15, -0.465), Vector3(0.13, 0.52, 0.058), 0.019, fabric)
		_mold(self, Vector3(side * 0.49, 1.48, -0.49), Vector3(0.24, 0.19, 0.11), 0.027, black)
		for dot_index in 2:
			_mold(self, Vector3(side * 0.49 - 0.039 + dot_index * 0.078, 1.50, -0.553),
				Vector3(0.034, 0.063, 0.021), 0.006, silver)

	_mold(self, Vector3(0, 2.15, -0.51), Vector3(0.63, 0.49, 0.11), 0.047, armor)
	_mold(self, Vector3(0, 2.16, -0.57), Vector3(0.50, 0.38, 0.037), 0.025, black)
	for index in 3:
		_mold(self, Vector3(-0.15 + index * 0.15, 2.23, -0.594),
			Vector3(0.077, 0.083, 0.025), 0.008, red if index == 0 else blue)
	for y in [2.04, 2.10]:
		_mold(self, Vector3(0, y, -0.594), Vector3(0.30, 0.025, 0.019), 0.005, silver)
	_mold(self, Vector3(0, 1.48, -0.525), Vector3(0.23, 0.16, 0.11), 0.026, alloy)

	for leg in [_left_leg, _right_leg]:
		_panel(leg, Vector3(0, -0.77, -0.38), [
			Vector2(-0.21, -0.37), Vector2(0.21, -0.37), Vector2(0.22, 0.25),
			Vector2(0.14, 0.33), Vector2(-0.14, 0.33), Vector2(-0.22, 0.25)], 0.11, black)
	for arm in [_left_arm, _right_arm]:
		var side := signf(arm.position.x)
		_mold(arm, Vector3(side * 0.225, -0.65, -0.102), Vector3(0.405, 0.25, 0.46), 0.069, armor)

	# The cape has depth at the shoulders and broad cloth folds from neck to hem.
	var cape := SurfaceTool.new()
	cape.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in 7:
		var top := float(row) / 7.0
		var bottom := float(row + 1) / 7.0
		for column in 28:
			var left := float(column) / 14.0 - 1.0
			var right := float(column + 1) / 14.0 - 1.0
			_quad(cape, _cape_point(left, top), _cape_point(right, top),
				_cape_point(right, bottom), _cape_point(left, bottom))
	fabric.cull_mode = BaseMaterial3D.CULL_DISABLED
	_instance(self, Vector3.ZERO, cape, fabric)

func _cape_point(x: float, drop: float) -> Vector3:
	var edge := absf(x)
	var pleat := cos(x * TAU * 1.8) * lerpf(0.022, 0.088, drop)
	var shoulder := lerpf(0.60, 1.04, pow(drop, 0.78))
	var hem := 0.23 + edge * edge * 0.17 + cos(x * TAU * 1.15) * 0.029
	var back := 0.42 + sin(drop * PI * 0.61) * 0.27 + (1.0 - edge) * drop * 0.11
	return Vector3(x * shoulder, lerpf(2.78 - edge * 0.11, hem, drop), back + pleat)

func _dress_stormtrooper() -> void:
	var helmet := _accessory(self, TROOPER_HELMET, Vector3(0, 3.54, 0), 0.62)
	_finish_accessory(helmet, 0.30)
	var carbon := _material(Color("#252b30"), 0.54)
	var seam := _material(Color("#69777f"), 0.46)
	var white := _material(Color("#e8e7e0"), 0.31)
	_panel(self, Vector3(0, 2.43, -0.46), [
		Vector2(-0.54, -0.12), Vector2(-0.36, -0.22), Vector2(0.36, -0.22),
		Vector2(0.54, -0.12), Vector2(0.51, 0.16), Vector2(0.31, 0.23),
		Vector2(-0.31, 0.23), Vector2(-0.51, 0.16)], 0.18, white)
	_mold(self, Vector3(0, 2.04, -0.486), Vector3(0.75, 0.29, 0.095), 0.035, seam)
	_mold(self, Vector3(0, 2.04, -0.536), Vector3(0.64, 0.21, 0.066), 0.028, white)
	for i in 3:
		_mold(self, Vector3(0, 1.99 + i * 0.048, -0.572),
			Vector3(0.29 - i * 0.025, 0.025, 0.015), 0.004, carbon)
	_mold(self, Vector3(0, 1.57, -0.47), Vector3(1.56, 0.20, 0.095), 0.032, carbon)
	for i in 5:
		_mold(self, Vector3(-0.54 + i * 0.27, 1.58, -0.532),
			Vector3(0.21, 0.16, 0.075), 0.024, white)
	for leg in [_left_leg, _right_leg]:
		_mold(leg, Vector3(0, -0.53, -0.397), Vector3(0.51, 0.11, 0.07), 0.021, carbon)
		_panel(leg, Vector3(0, -0.89, -0.39), [
			Vector2(-0.24, -0.24), Vector2(0.24, -0.24), Vector2(0.23, 0.24),
			Vector2(0.12, 0.30), Vector2(-0.12, 0.30), Vector2(-0.23, 0.24)], 0.11, white)
	for arm in [_left_arm, _right_arm]:
		var side := signf(arm.position.x)
		_mold(arm, Vector3(side * 0.224, -0.60, -0.08), Vector3(0.41, 0.28, 0.47), 0.070, white)
	_mold(self, Vector3(0, 2.36, 0.489), Vector3(0.76, 0.48, 0.14), 0.065, white)
	_medallion(self, Vector3(0, 2.36, 0.57), 0.15, 0.055, seam)

func _dress_iron_man() -> void:
	var helmet := _accessory(self, IRON_HELMET, Vector3(0, 3.53, 0), 0.68)
	_finish_accessory(helmet, 0.24)
	var gold := _material(Color("#c29746"), 0.29)
	var red := _material(Color("#b23943"), 0.24)
	var slate := _material(Color("#502c38"), 0.45)
	var reactor := _material(Color("#b9f5ff"), 0.33)
	reactor.emission_enabled = true
	reactor.emission = Color("#7bd1ff")
	reactor.emission_energy_multiplier = 0.42
	_panel(self, Vector3(0, 2.40, -0.46), [
		Vector2(-0.54, -0.05), Vector2(-0.29, -0.22), Vector2(0.29, -0.22),
		Vector2(0.54, -0.05), Vector2(0.49, 0.18), Vector2(0.30, 0.24),
		Vector2(-0.30, 0.24), Vector2(-0.49, 0.18)], 0.17, red)
	_medallion(self, Vector3(0, 2.40, -0.55), 0.196, 0.096, slate)
	_medallion(self, Vector3(0, 2.40, -0.604), 0.145, 0.038, gold)
	_medallion(self, Vector3(0, 2.40, -0.631), 0.105, 0.022, reactor)
	for side in [-1.0, 1.0]:
		var collar := _mold(self, Vector3(side * 0.41, 2.57, -0.548),
			Vector3(0.26, 0.12, 0.055), 0.020, gold)
		collar.rotation.z = side * 0.22
		_mold(self, Vector3(side * 0.21, 1.98, -0.495),
			Vector3(0.24, 0.19, 0.075), 0.025, red, 0.29)
	for leg in [_left_leg, _right_leg]:
		_panel(leg, Vector3(0, -0.81, -0.39), [
			Vector2(-0.21, -0.32), Vector2(0.21, -0.32), Vector2(0.17, 0.14),
			Vector2(0.09, 0.28), Vector2(-0.09, 0.28), Vector2(-0.17, 0.14)], 0.10, red)
		_mold(leg, Vector3(0, -0.54, -0.458), Vector3(0.21, 0.15, 0.046), 0.019, gold, 0.15)
	for arm in [_left_arm, _right_arm]:
		var side := signf(arm.position.x)
		_mold(arm, Vector3(side * 0.222, -0.66, -0.10), Vector3(0.40, 0.27, 0.48), 0.075, red)
		_mold(arm, Vector3(side * 0.226, -0.65, -0.337), Vector3(0.19, 0.093, 0.045), 0.019, gold)
	_mold(self, Vector3(0, 2.40, 0.51), Vector3(0.68, 0.50, 0.14), 0.068, slate)
	for x in [-0.18, 0.18]:
		_medallion(self, Vector3(x, 2.42, 0.59), 0.065, 0.022, reactor)

func _dress_captain_america(blue: Material, ink: Material, white: Material) -> void:
	var red := _material(Color("#a43b42"), 0.35)
	var skin := _material(Color("#e7b291"), 0.50)
	var shell := _material(Color("#244566"), 0.30)
	var panel_blue := _material(Color("#40668c"), 0.33)
	_lathe(self, Vector3(0, 3.11, 0), [
		Vector2(0.41, -0.22), Vector2(0.52, -0.18), Vector2(0.572, -0.13),
		Vector2(0.572, 0.25)], skin)
	_lathe(self, Vector3(0, 3.33, 0), [
		Vector2(0.548, -0.13), Vector2(0.578, -0.105), Vector2(0.581, 0.26),
		Vector2(0.563, 0.34), Vector2(0.518, 0.41), Vector2(0.42, 0.47),
		Vector2(0.25, 0.49)], shell)
	for side in [-1.0, 1.0]:
		_face_dot(Vector2(side * 0.197, 0.037), Vector2(0.082, 0.035), skin, 0.006)
		_face_dot(Vector2(side * 0.184, 0.037), Vector2(0.037, 0.028), ink, 0.010)
		_face_dot(Vector2(side * 0.184 - 0.010, 0.045), Vector2(0.010, 0.008), white, 0.013)
	_face_line([Vector2(-0.099, -0.163), Vector2(-0.024, -0.182),
		Vector2(0.057, -0.171), Vector2(0.116, -0.145)], 0.024, ink)
	_face_line([Vector2(-0.087, 0.161), Vector2(0, 0.320), Vector2(0.087, 0.161)], 0.032, white, 0.014)
	_face_line([Vector2(-0.052, 0.217), Vector2(0.052, 0.217)], 0.023, white, 0.014)
	_panel(self, Vector3(0, 2.45, -0.46), [
		Vector2(-0.48, -0.09), Vector2(-0.29, -0.21), Vector2(0.29, -0.21),
		Vector2(0.48, -0.09), Vector2(0.46, 0.17), Vector2(-0.46, 0.17)], 0.12, panel_blue)
	_star(Vector3(0, 2.45, -0.535), 0.215, white)
	_mold(self, Vector3(0, 1.92, -0.49), Vector3(0.85, 0.33, 0.076), 0.022, white)
	for x in [-0.31, 0.0, 0.31]:
		_mold(self, Vector3(x, 1.92, -0.533), Vector3(0.128, 0.32, 0.025), 0.012, red)
	_mold(self, Vector3(0, 1.60, -0.466), Vector3(1.26, 0.16, 0.079), 0.028, shell)
	_mold(self, Vector3(0, 1.60, -0.519), Vector3(0.24, 0.137, 0.06), 0.026, panel_blue)
	for leg in [_left_leg, _right_leg]:
		_mold(leg, Vector3(0, -0.72, -0.382), Vector3(0.48, 0.32, 0.095), 0.057, blue, 0.42)
		_mold(leg, Vector3(0, -1.16, -0.29), Vector3(0.70, 0.37, 0.69), 0.073, red)
	var shield := _accessory(_left_arm, CAPTAIN_SHIELD, Vector3(-0.26, -0.70, -0.42), 0.60)
	shield.rotation_degrees.y = -25.0
	shield.rotation_degrees.x = -8.0
	_finish_accessory(shield, 0.26)

## A convex armor panel, beveled around its silhouette to catch real light.
func _panel(parent: Node3D, center: Vector3, outline: Array[Vector2], depth: float, material: Material) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var front := -depth * 0.5
	var back := depth * 0.5
	for i in outline.size():
		var j := (i + 1) % outline.size()
		var a := Vector3(outline[i].x, outline[i].y, 0)
		var b := Vector3(outline[j].x, outline[j].y, 0)
		var af := a * 0.82 + Vector3(0, 0, front)
		var bf := b * 0.82 + Vector3(0, 0, front)
		var am := a + Vector3(0, 0, front * 0.44)
		var bm := b + Vector3(0, 0, front * 0.44)
		var ab := a * 0.92 + Vector3(0, 0, back)
		var bb := b * 0.92 + Vector3(0, 0, back)
		_triangle(surface, Vector3(0, 0, front), af, bf)
		_quad(surface, bf, af, am, bm)
		_quad(surface, bm, am, ab, bb)
		_triangle(surface, Vector3(0, 0, back), bb, ab)
	_instance(parent, center, surface, material)

func _finish_accessory(node: Node3D, roughness: float) -> void:
	# Keep the imported CAD shapes and prints, then give the molded parts
	# the same lighting response as the articulated figure underneath.
	if node is MeshInstance3D and node.mesh:
		for i in node.mesh.get_surface_count():
			var original := node.mesh.surface_get_material(i) as StandardMaterial3D
			if original:
				var plastic := original.duplicate() as StandardMaterial3D
				plastic.roughness = roughness
				plastic.metallic_specular = 0.55
				plastic.rim_enabled = true
				plastic.rim = 0.21
				plastic.rim_tint = 0.05
				node.set_surface_override_material(i, plastic)
	for child in node.get_children():
		if child is Node3D:
			_finish_accessory(child, roughness)

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
	material.metallic_specular = 0.50
	material.rim_enabled = true
	material.rim = 0.16
	material.rim_tint = 0.18
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

func _face_line(points: Array, thickness: float, material: Material, offset: float = 0.0) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(points.size() - 1):
		var a: Vector2 = points[i]
		var b: Vector2 = points[i + 1]
		var edge := Vector2(0, thickness * 0.5)
		_quad(surface, _face_position(a - edge, offset), _face_position(b - edge, offset),
			_face_position(b + edge, offset), _face_position(a + edge, offset))
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
