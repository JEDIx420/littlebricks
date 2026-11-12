class_name WorkbenchHUD
extends RefCounted

const INK := Color("#f5e8ce")
const MUTED := Color("#cabda8")
const PANEL := Color("#222a27")
const BUTTON := Color("#303b34")
const EDGE := Color("#526052")
const ACTIVE := Color("#eac481")
const DARK := Color("#252a25")

static func surface(fill: Color, border: Color, radius: int = 10, padding: int = 7) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(radius)
	box.set_content_margin_all(padding)
	return box

static func apply(root: Control, body_font: Font, display_font: Font) -> void:
	var theme := Theme.new()
	theme.default_font_size = 15
	theme.default_font = body_font
	for type in ["Label", "Button", "OptionButton", "LineEdit"]:
		theme.set_color("font_color", type, INK)
	theme.set_color("font_hover_color", "Button", INK)
	theme.set_color("font_pressed_color", "Button", DARK)
	theme.set_color("font_disabled_color", "Button", Color("#a19b8d"))
	theme.set_stylebox("normal", "Button", surface(BUTTON, EDGE))
	theme.set_stylebox("hover", "Button", surface(Color("#4a5146"), ACTIVE))
	theme.set_stylebox("pressed", "Button", surface(ACTIVE, ACTIVE))
	theme.set_stylebox("disabled", "Button", surface(PANEL, EDGE))
	var focus := surface(Color.TRANSPARENT, ACTIVE)
	focus.set_border_width_all(2)
	theme.set_stylebox("focus", "Button", focus)
	var card := surface(Color(PANEL, 0.94), EDGE, 12, 5)
	card.shadow_color = Color(0.06, 0.05, 0.04, 0.44)
	card.shadow_offset = Vector2(0, 4)
	card.shadow_size = 4
	theme.set_stylebox("panel", "PanelContainer", card)
	root.theme = theme
	var title := root.find_child("Title", true, false) as Label
	title.add_theme_font_override("font", display_font)
	title.add_theme_font_size_override("font_size", 19)
	for name in ["BtnOrbitLeft", "BtnOrbitUp", "BtnOrbitDown", "BtnOrbitRight"]:
		var nudge := root.find_child(name, true, false) as Button
		nudge.add_theme_stylebox_override("normal", surface(BUTTON, EDGE, 21))
		nudge.add_theme_stylebox_override("hover", surface(Color("#4a5146"), ACTIVE, 21))
		nudge.add_theme_font_size_override("font_size", 20)
	for name in ["CameraTitle", "ToolTitle", "CameraHint", "ZoomLabel"]:
		var label := root.find_child(name, true, false) as Label
		if label:
			label.add_theme_color_override("font_color", MUTED)
			label.add_theme_font_size_override("font_size", 13)
	for name in ["BtnFinish", "BtnPlace"]:
		var action := root.find_child(name, true, false) as Button
		if action:
			select(action, true)

static func select(button: Button, selected: bool) -> void:
	if selected:
		button.add_theme_stylebox_override("normal", surface(ACTIVE, ACTIVE))
		button.add_theme_stylebox_override("hover", surface(Color("#f7dba6"), ACTIVE))
		button.add_theme_color_override("font_color", DARK)
		button.add_theme_color_override("font_hover_color", DARK)
	else:
		for state in ["normal", "hover"]:
			button.remove_theme_stylebox_override(state)
		for color in ["font_color", "font_hover_color"]:
			button.remove_theme_color_override(color)

static func add_part_preview(button: Button, part: Dictionary, color: Color) -> void:
	# Render the same geometry that will be placed. Only the six tray slots and
	# the current catalogue preview use a live render target.
	var view := SubViewport.new()
	view.size = Vector2i(124, 72)
	view.own_world_3d = true
	view.transparent_bg = true
	view.render_target_update_mode = SubViewport.UPDATE_ONCE
	view.msaa_3d = Viewport.MSAA_2X

	var model := PartMeshBuilder.build_part_node(part, color)
	view.add_child(model)
	var dims: Array = part.get("dimensions_studs", [2, 3, 2])
	var span := maxf(maxf(float(dims[0]), float(dims[2])), float(dims[1]) * 0.4)
	var focus := Vector3(0, float(dims[1]) * 0.2, 0)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = maxf(2.4, span * 1.20)
	view.add_child(camera)
	camera.position = focus + Vector3(5, 5, 7)
	camera.basis = Basis.looking_at(focus - camera.position)
	camera.current = true

	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color("#ffffff")
	world.environment.ambient_light_energy = 0.68
	view.add_child(world)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-50, -35, 0)
	key.light_energy = 0.86
	view.add_child(key)
	button.add_child(view)

	var preview := TextureRect.new()
	preview.texture = view.get_texture()
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(preview)
	preview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	preview.offset_left = 4
	preview.offset_right = -4
	preview.offset_top = 2
	preview.offset_bottom = -28
