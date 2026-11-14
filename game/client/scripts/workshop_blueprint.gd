class_name WorkshopBlueprint
extends Node3D

## A physical printed reference and an accessible close-up of the same sheet.
## Switching references affects this object only. It never modifies the session.
signal reader_closed

const Models := preload("res://core/blueprint_models.gd")
const Catalog := preload("res://core/part_catalog.gd")
const Builder := preload("res://core/part_mesh_builder.gd")
const Rules := preload("res://core/placement_rules.gd")
const HUD := preload("res://client/scripts/workbench_hud.gd")
const BODY_FONT := preload("res://assets/ui/fonts/DM-Sans.ttf")
const DISPLAY_FONT := preload("res://assets/ui/fonts/DM-Serif-Text.ttf")
const SHEET_SIZE := Vector2(8.0, 10.0)
const PRINT_SIZE := Vector2i(480, 600)
const PAPER_BACKGROUND := Color("#23394b")
const PAPER_INK := Color("#eef3e9")
const PAPER_POSITION := Vector3(-22.0, TableView.TABLE_TOP_Y, 10.5)
const PAPER_SURFACE_Y := 0.046
const PAPER_EDGE := 0.04
const PAPER_BOTTOM_Y := -0.012

var theme_id: String = "harbour"
var _catalog: Catalog
var _print: SubViewport
var _stage: Node3D
var _paper_camera: Camera3D
var _heading: Label
var _pack: Label
var _details: Label
var _reader: Reader
var _theme_buttons: Array[Button] = []

func configure(starting_theme: String, catalog: Catalog) -> void:
	_catalog = catalog
	if not _print:
		name = "WorkshopBlueprint"
		position = PAPER_POSITION
		rotation_degrees.y = -7.0
		_make_print()
		_make_physical_sheet()
	set_theme(starting_theme)

func set_theme(next_theme: String) -> void:
	if not _print:
		return
	theme_id = next_theme if next_theme in Models.THEMES else "harbour"
	var model: Dictionary = Models.get_model(theme_id)
	var theme_index: int = Models.THEMES.find(theme_id)
	var pieces: Array = model.pieces
	_heading.text = model.title
	_pack.text = Models.LABELS[theme_index].to_upper()
	_pack.add_theme_color_override("font_color", model.accent)
	for i in _theme_buttons.size():
		HUD.select(_theme_buttons[i], i == theme_index)
	for child in _stage.get_children():
		_stage.remove_child(child)
		child.queue_free()

	var lower := Vector3(INF, 0.0, INF)
	var upper := Vector3(-INF, 0.0, -INF)
	for piece in pieces:
		var part := _catalog.get_part(piece.part_id)
		if part.is_empty():
			continue
		var dimensions: Array = part.dimensions_studs
		var rotation: int = piece.rotation_step
		var footprint := Rules.get_part_footprint(dimensions, rotation)
		var mesh := Builder.build_part_node(part, piece.color)
		mesh.position = Rules.grid_to_world(piece.grid_x, piece.grid_z, piece.layer_plate, dimensions, rotation)
		mesh.rotation_degrees = Rules.get_rotation_degrees(rotation)
		_stage.add_child(mesh)
		var offset := Vector3(footprint.x * 0.5, 0.0, footprint.y * 0.5)
		lower = lower.min(mesh.position - offset)
		upper = upper.max(mesh.position + offset + Vector3.UP * float(dimensions[1]) * Rules.PLATE_HEIGHT)

	var span := upper - lower
	var center := (upper + lower) * 0.5
	center.y = span.y * 0.48
	_paper_camera.size = maxf(span.x, span.z) * 1.81 + span.y * 0.59
	_paper_camera.look_at_from_position(center + Vector3(10.0, 8.6, 15.0), center)
	_details.text = "%d pieces  ·  %d × %d studs" % [pieces.size(), roundi(span.x), roundi(span.z)]
	_print.render_target_update_mode = SubViewport.UPDATE_ONCE

func is_under_pointer(camera: Camera3D, screen_position: Vector2) -> bool:
	if not is_visible_in_tree() or not camera or not _print:
		return false
	var origin := to_local(camera.project_ray_origin(screen_position))
	var direction := global_transform.basis.inverse() * camera.project_ray_normal(screen_position)
	if direction.y >= -0.001:
		return false
	var distance := (PAPER_SURFACE_Y - origin.y) / direction.y
	if distance <= 0:
		return false
	var local := origin + direction * distance
	var half_stock := SHEET_SIZE * 0.5 + Vector2.ONE * PAPER_EDGE
	return absf(local.x) <= half_stock.x and absf(local.z) <= half_stock.y

func show_reader(parent: Control) -> void:
	if is_instance_valid(_reader) or not _print:
		return
	_reader = Reader.new()
	_reader.name = "BlueprintReader"
	_reader.z_index = 10
	_reader.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(_reader)
	_reader.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_reader.dismiss_requested.connect(close_reader)

	var dim := ColorRect.new()
	dim.color = Color(0.12, 0.13, 0.10, 0.72)
	_reader.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reader.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var case_panel := PanelContainer.new()
	var case_style := HUD.surface(HUD.PANEL, HUD.EDGE, 16, 12)
	case_style.shadow_color = Color(0.02, 0.02, 0.02, 0.50)
	case_style.shadow_size = 14
	case_style.shadow_offset = Vector2(0, 5)
	case_panel.add_theme_stylebox_override("panel", case_style)
	center.add_child(case_panel)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 9)
	case_panel.add_child(stack)
	var menu := HBoxContainer.new()
	menu.add_theme_constant_override("separation", 6)
	stack.add_child(menu)

	for i in Models.THEMES.size():
		var tab := _reader_button(Models.LABELS[i])
		tab.pressed.connect(set_theme.bind(Models.THEMES[i]))
		HUD.select(tab, Models.THEMES[i] == theme_id)
		menu.add_child(tab)
		_theme_buttons.append(tab)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu.add_child(spacer)
	var close := _reader_button("Close")
	close.name = "BtnCloseBlueprint"
	close.pressed.connect(close_reader)
	menu.add_child(close)

	var paper := TextureRect.new()
	paper.texture = _print.get_texture()
	paper.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	paper.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(paper)
	var scale_factor := clampf((parent.size.y - 110.0) / PRINT_SIZE.y, 0.6, 1.0)
	paper.custom_minimum_size = Vector2(PRINT_SIZE) * scale_factor
	_print.render_target_update_mode = SubViewport.UPDATE_ONCE
	close.grab_focus()

func close_reader() -> void:
	if not is_instance_valid(_reader):
		return
	_reader.hide()
	_reader.queue_free()
	_reader = null
	_theme_buttons.clear()
	reader_closed.emit()

func _reader_button(caption: String) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(0, 44)
	button.add_theme_font_override("font", BODY_FONT)
	button.add_theme_stylebox_override("normal", HUD.surface(HUD.BUTTON, HUD.EDGE))
	button.add_theme_stylebox_override("hover", HUD.surface(HUD.EDGE, HUD.ACTIVE))
	button.add_theme_stylebox_override("pressed", HUD.surface(HUD.ACTIVE, HUD.ACTIVE))
	button.add_theme_color_override("font_color", HUD.INK)
	button.add_theme_color_override("font_hover_color", HUD.INK)
	button.add_theme_color_override("font_pressed_color", HUD.DARK)
	return button

func _make_print() -> void:
	_print = SubViewport.new()
	_print.name = "BlueprintPrint"
	_print.own_world_3d = true
	_print.size = PRINT_SIZE
	_print.msaa_3d = Viewport.MSAA_2X
	_print.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(_print)

	_stage = Node3D.new()
	_print.add_child(_stage)
	_paper_camera = Camera3D.new()
	_paper_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_paper_camera.near = 1.0
	_paper_camera.far = 72.0
	_print.add_child(_paper_camera)
	_paper_camera.make_current()
	var studio := WorldEnvironment.new()
	studio.environment = Environment.new()
	studio.environment.background_mode = Environment.BG_COLOR
	studio.environment.background_color = PAPER_BACKGROUND
	studio.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	studio.environment.ambient_light_color = Color("#ebf1f9")
	studio.environment.ambient_light_energy = 0.56
	_print.add_child(studio)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-41, -28, 0)
	key.light_color = Color("#fff2d6")
	key.light_energy = 0.91
	_print.add_child(key)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-24, 146, 0)
	rim.light_color = Color("#c3e9ff")
	rim.light_energy = 0.33
	_print.add_child(rim)

	var art := PrintGuide.new()
	art.size = PRINT_SIZE
	_print.add_child(art)
	_print_label(art, "LITTLEBRICKS WORKSHOP", Vector2(30, 30), 12, PAPER_INK)
	_pack = _print_label(art, "", Vector2(315, 30), 12, PAPER_INK)
	_pack.size.x = 135
	_pack.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_heading = _print_label(art, "", Vector2(28, 55), 40, PAPER_INK)
	_heading.add_theme_font_override("font", DISPLAY_FONT)
	_print_label(art, "FINISHED REFERENCE", Vector2(30, 526), 13, PAPER_INK)
	_details = _print_label(art, "", Vector2(30, 549), 16, Color("#b2c3c5"))

func _print_label(parent: Control, content: String, at: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = content
	label.position = at
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", BODY_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func _make_physical_sheet() -> void:
	var stock := MeshInstance3D.new()
	stock.name = "PaperStock"
	stock.mesh = _make_paper_stock()
	var backing_material := StandardMaterial3D.new()
	backing_material.albedo_color = Color("#b7c0b6")
	backing_material.roughness = 0.84
	stock.material_override = backing_material
	add_child(stock)

	var face := MeshInstance3D.new()
	face.name = "PrintedFace"
	var sheet := PlaneMesh.new()
	sheet.size = SHEET_SIZE
	face.mesh = sheet
	face.position.y = PAPER_SURFACE_Y
	var ink := StandardMaterial3D.new()
	ink.albedo_texture = _print.get_texture()
	ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ink.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	face.material_override = ink
	face.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(face)

func _make_paper_stock() -> ArrayMesh:
	# The print fills the center opening, so the paper top has just one
	# surface at every point even when the camera skims the table.
	var half_print := SHEET_SIZE * 0.5
	var half_stock := half_print + Vector2.ONE * PAPER_EDGE
	var corners := [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]
	var top_rim: Array[Vector3] = []
	var print_edge: Array[Vector3] = []
	var bottom: Array[Vector3] = []
	for corner: Vector2 in corners:
		top_rim.append(Vector3(corner.x * half_stock.x, PAPER_SURFACE_Y, corner.y * half_stock.y))
		print_edge.append(Vector3(corner.x * half_print.x, PAPER_SURFACE_Y, corner.y * half_print.y))
		bottom.append(Vector3(corner.x * half_stock.x, PAPER_BOTTOM_Y, corner.y * half_stock.y))
	var geometry := SurfaceTool.new()
	geometry.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in corners.size():
		var next := (i + 1) % corners.size()
		_add_stock_quad(geometry, top_rim[i], top_rim[next], print_edge[next], print_edge[i])
		_add_stock_quad(geometry, top_rim[next], top_rim[i], bottom[i], bottom[next])
	_add_stock_quad(geometry, bottom[3], bottom[2], bottom[1], bottom[0])
	geometry.generate_normals()
	return geometry.commit()

func _add_stock_quad(mesh: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	# The thin paper edge turns sharply at each corner.
	mesh.set_smooth_group(-1)
	for vertex in [a, b, c, a, c, d]:
		mesh.add_vertex(vertex)

class Reader extends Control:
	signal dismiss_requested

	func _unhandled_key_input(event: InputEvent) -> void:
		if event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			dismiss_requested.emit()

class PrintGuide extends Control:
	func _draw() -> void:
		var edge := Rect2(Vector2(16, 16), Vector2(448, 568))
		draw_rect(edge, Color("#71909c"), false, 1.0)
		for x in [30.0, 450.0]:
			draw_line(Vector2(x, 111), Vector2(x, 511), Color(0.55, 0.69, 0.75, 0.26))
		for y in [111.0, 511.0]:
			draw_line(Vector2(30, y), Vector2(450, y), Color("#71909c"))
		for x in range(44, 450, 16):
			for y in range(124, 510, 16):
				draw_circle(Vector2(x, y), 0.7, Color(0.68, 0.80, 0.83, 0.20))
