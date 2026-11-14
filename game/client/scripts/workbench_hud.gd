class_name WorkbenchHUD
extends RefCounted

const INK := Color("#fff4da")
const MUTED := Color("#c9be9d")
const PANEL := Color("#18352c")
const BUTTON := Color("#294d3e")
const EDGE := Color("#607965")
const ACTIVE := Color("#f2c574")
const DARK := Color("#192e26")
const IVORY := Color("#fbefda")
const COBALT := Color("#264b9b")
const PERSIMMON := Color("#ff976d")

const ICON_PATHS := {
	"stud": "M5 9h14v11H5z M8 9V5h8v4 M5 12h14",
	"view": "M3 8V4h4m10 0h4v4m0 8v4h-4m-10 0H3v-4 M7 12l5-4 5 4-5 4z",
	"plans": "M5 4h11l3 3v13H5z M15 4v4h4 M8 12h8m-8 4h6",
	"colors": "M12 4c-5 0-8 3-8 7s3 8 7 8h2a2 2 0 001-3c-1-1 1-2 2-2h2c2 0 3-1 3-3 0-4-4-7-9-7zm-5 6h.1m3-3h.1m5 0h.1m3 3h.1",
	"erase": "M4 13l8-8c1-1 2-1 3 0l5 5c1 1 1 2 0 3l-6 6H9l-5-5zm5-5 8 8m-5 3h9",
	"left": "M6 9a7 7 0 115 10 M5 4v6h6",
	"right": "M18 9a7 7 0 10-5 10 M19 4v6h-6",
	"undo": "M9 5L4 10l5 5m-5-5h10a5 5 0 015 5v2",
	"redo": "M15 5l5 5-5 5m5-5H10a5 5 0 00-5 5v2",
	"drop": "M6 6l12 12M6 18L18 6",
	"place": "M3.5 12l5.5 5.5L20.5 6",
	"packs": "M3 7l9-4 9 4v10l-9 4-9-4zm0 0 9 4 9-4m-9 4v10m-4-16 9 4",
	"height": "M7 7l5-4 5 4 M12 3v18 M7 17l5 4 5-4",
}

static func _texture(icon_name: String, color: Color) -> ImageTexture:
	var art := '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><path d="%s" fill="none" stroke="#%s" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/></svg>' % [ICON_PATHS[icon_name], color.to_html(false)]
	var image := Image.new()
	image.load_svg_from_string(art, 2.0)
	return ImageTexture.create_from_image(image)

static func surface(fill: Color, border: Color, radius: int = 10, padding: int = 7) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(radius)
	box.set_content_margin_all(padding)
	return box

static func _button_face(fill: Color, rim: Color, base: Color, radius: int = 8) -> StyleBoxFlat:
	var face := surface(fill, rim, radius, 7)
	face.border_width_bottom = 3
	face.shadow_color = base
	face.shadow_size = 1
	face.shadow_offset = Vector2(0, 2)
	return face

static func _action(button: Button, fill: Color, hover: Color, base: Color, ink: Color) -> void:
	button.add_theme_stylebox_override("normal", _button_face(fill, fill, base))
	button.add_theme_stylebox_override("hover", _button_face(hover, fill, base))
	button.add_theme_stylebox_override("pressed", surface(fill.darkened(0.12), fill, 8, 7))
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		button.add_theme_color_override(state, ink)

static func apply(root: Control, body_font: Font, display_font: Font) -> void:
	var theme := Theme.new()
	theme.default_font_size = 15
	theme.default_font = body_font
	for type in ["Label", "Button", "OptionButton", "LineEdit"]:
		theme.set_color("font_color", type, INK)
	theme.set_color("font_hover_color", "Button", INK)
	theme.set_color("font_pressed_color", "Button", DARK)
	theme.set_color("font_disabled_color", "Button", Color("#bcb9a7"))
	theme.set_stylebox("normal", "Button", _button_face(BUTTON, EDGE, Color("#102b24")))
	theme.set_stylebox("hover", "Button", _button_face(Color("#356353"), ACTIVE, Color("#102b24")))
	theme.set_stylebox("pressed", "Button", surface(ACTIVE, ACTIVE))
	theme.set_stylebox("disabled", "Button", surface(PANEL, EDGE))
	var focus := surface(Color.TRANSPARENT, ACTIVE)
	focus.set_border_width_all(2)
	theme.set_stylebox("focus", "Button", focus)
	theme.set_constant("icon_max_width", "Button", 18)
	theme.set_constant("h_separation", "Button", 6)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		theme.set_stylebox(state, "OptionButton", theme.get_stylebox(state, "Button"))
	theme.set_color("font_pressed_color", "OptionButton", DARK)
	theme.set_color("font_hover_pressed_color", "OptionButton", DARK)
	theme.set_color("font_focus_color", "OptionButton", INK)
	theme.set_color("font_hover_color", "OptionButton", INK)
	theme.set_stylebox("panel", "PopupMenu", surface(PANEL, EDGE))
	theme.set_stylebox("hover", "PopupMenu", surface(ACTIVE, ACTIVE, 7, 0))
	theme.set_color("font_color", "PopupMenu", INK)
	theme.set_color("font_hover_color", "PopupMenu", DARK)
	var card := surface(Color(PANEL, 0.97), EDGE, 13, 5)
	card.shadow_color = Color(0.08, 0.13, 0.09, 0.35)
	card.shadow_offset = Vector2(0, 4)
	card.shadow_size = 4
	theme.set_stylebox("panel", "PanelContainer", card)
	theme.set_stylebox("normal", "LineEdit", surface(IVORY, Color("#d1bd96")))
	theme.set_color("font_color", "LineEdit", DARK)
	theme.set_color("font_placeholder_color", "LineEdit", Color("#5e6252"))
	theme.set_color("caret_color", "LineEdit", DARK)
	theme.set_color("selection_color", "LineEdit", Color("#a7bced"))
	var scroll_track := surface(Color("#213e32"), Color("#435f50"), 5, 0)
	var scroll_grab := surface(Color("#a39164"), Color("#cab482"), 5, 0)
	theme.set_stylebox("scroll", "HScrollBar", scroll_track)
	theme.set_stylebox("grabber", "HScrollBar", scroll_grab)
	root.theme = theme
	var title := root.find_child("Title", true, false) as Label
	title.add_theme_font_override("font", display_font)
	title.add_theme_font_size_override("font_size", 24)
	var mark := root.find_child("WorkbenchMark", true, false) as TextureRect
	mark.texture = _texture("stud", ACTIVE)
	var count := root.find_child("BrickCount", true, false) as Label
	if count:
		count.add_theme_stylebox_override("normal", surface(Color("#324d3e"), Color("#9e8757"), 12, 4))
		count.add_theme_color_override("font_color", ACTIVE)
	var tools_frame := card.duplicate() as StyleBoxFlat
	tools_frame.set_corner_radius_all(9)
	tools_frame.border_color = Color("#9d8555")
	tools_frame.set_content_margin_all(3)
	tools_frame.shadow_size = 0
	root.get_node("RightControls").add_theme_stylebox_override("panel", tools_frame)
	var dock_frame := card.duplicate() as StyleBoxFlat
	dock_frame.set_corner_radius_all(11)
	dock_frame.border_color = Color("#667e61")
	dock_frame.set_content_margin_all(3)
	root.get_node("LeftDock").add_theme_stylebox_override("panel", dock_frame)
	var tray := root.get_node("BottomPanel") as PanelContainer
	var tray_frame := card.duplicate() as StyleBoxFlat
	tray_frame.bg_color = Color("#203b2e")
	tray_frame.border_color = Color("#b49a65")
	tray_frame.border_width_bottom = 3
	tray_frame.set_content_margin_all(6)
	tray.add_theme_stylebox_override("panel", tray_frame)
	var catalogue := root.get_node("CatalogModal") as PanelContainer
	var catalogue_frame := card.duplicate() as StyleBoxFlat
	catalogue_frame.border_color = Color("#b49a65")
	catalogue_frame.border_width_top = 3
	catalogue_frame.set_content_margin_all(10)
	catalogue.add_theme_stylebox_override("panel", catalogue_frame)
	var catalogue_title := catalogue.find_child("ModalTitle", true, false) as Label
	catalogue_title.add_theme_font_override("font", display_font)
	catalogue_title.add_theme_font_size_override("font_size", 28)
	for name in ["BtnOrbitLeft", "BtnOrbitUp", "BtnOrbitDown", "BtnOrbitRight"]:
		var nudge := root.find_child(name, true, false) as Button
		nudge.add_theme_stylebox_override("normal", surface(BUTTON, EDGE, 21))
		nudge.add_theme_stylebox_override("hover", surface(Color("#356353"), ACTIVE, 21))
		nudge.add_theme_font_size_override("font_size", 20)
	for name in ["CameraTitle", "ToolTitle", "CameraHint", "ZoomLabel"]:
		var label := root.find_child(name, true, false) as Label
		if label:
			label.add_theme_color_override("font_color", MUTED)
			label.add_theme_font_size_override("font_size", 13)
	_action(root.find_child("BtnFinish", true, false), ACTIVE, Color("#f9d38d"), Color("#70502f"), DARK)
	_action(root.find_child("BtnPlace", true, false), PERSIMMON, Color("#ffae8c"), Color("#893b27"), DARK)
	_action(root.find_child("BtnAllParts", true, false), COBALT, Color("#375cc2"), Color("#162b63"), INK)
	_action(root.find_child("BtnPickPart", true, false), ACTIVE, Color("#f9d38d"), Color("#70502f"), DARK)

	var icons := {
		"BtnUndo": "undo", "BtnRedo": "redo", "BtnCameraDock": "view", "BtnPlans": "plans",
		"BtnRotateLeft": "left", "BtnRotateRight": "right", "BtnBrickColor": "colors",
		"BtnErase": "erase", "BtnCancel": "drop", "BtnAllParts": "packs",
		"BtnPlace": "place"
	}
	for control_name in icons:
		var control := root.find_child(control_name, true, false) as Button
		var tint := DARK if control_name == "BtnPlace" else INK
		control.icon = _texture(icons[control_name], tint)
		control.tooltip_text = control.text if control.tooltip_text.is_empty() else control.tooltip_text
		control.accessibility_name = control.tooltip_text
		control.expand_icon = true

	for name in ["BtnPlace", "BtnErase", "BtnCancel", "BtnRotateLeft", "BtnRotateRight", "BtnAllParts"]:
		var control := root.find_child(name) as Button
		control.add_theme_constant_override("h_separation", 3)


static func select(button: Button, selected: bool) -> void:
	if selected:
		var active_edge := PERSIMMON if button.name == "BtnErase" else ACTIVE
		var active_fill := Color("#773924") if button.name == "BtnErase" else Color("#715130")
		var rail := surface(active_fill, active_edge, 8, 7) if button.icon else surface(ACTIVE, ACTIVE, 8, 7)
		rail.border_width_bottom = 3
		button.add_theme_stylebox_override("normal", rail)
		var hovered := rail.duplicate() as StyleBoxFlat
		hovered.bg_color = rail.bg_color.lightened(0.13)
		button.add_theme_stylebox_override("hover", hovered)
		button.add_theme_color_override("font_color", INK if button.icon else DARK)
		button.add_theme_color_override("font_hover_color", INK if button.icon else DARK)
	else:
		for state in ["normal", "hover"]:
			button.remove_theme_stylebox_override(state)
		for color in ["font_color", "font_hover_color"]:
			button.remove_theme_color_override(color)

static func style_tray_slot(button: Button, compact: bool, selected: bool) -> void:
	var fill := Color("#ffe3a8") if selected else IVORY
	var rim := Color("#d79732") if selected else Color("#c5b38e")
	var pocket := _button_face(fill, rim, Color("#101d17"), 8)
	pocket.content_margin_top = 37 if compact else 45
	pocket.content_margin_bottom = 3
	if selected:
		pocket.set_border_width_all(2)
		pocket.border_width_bottom = 4
	button.add_theme_stylebox_override("normal", pocket)
	var hover := pocket.duplicate() as StyleBoxFlat
	hover.bg_color = fill.lightened(0.18)
	button.add_theme_stylebox_override("hover", hover)
	var pressed := pocket.duplicate() as StyleBoxFlat
	pressed.bg_color = fill.darkened(0.10)
	button.add_theme_stylebox_override("pressed", pressed)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, DARK)

static func pulse(control: Control, reduced_motion: bool, start_scale: float, tint: Color = Color.WHITE) -> void:
	if control.has_meta("hud_pulse"):
		var existing := control.get_meta("hud_pulse") as Tween
		if existing.is_valid():
			existing.kill()
	control.scale = Vector2.ONE
	control.modulate = Color.WHITE
	if reduced_motion or not control.is_inside_tree() or not control.is_visible_in_tree():
		return
	control.pivot_offset = control.size * 0.5
	control.scale = Vector2.ONE * start_scale
	control.modulate = tint
	var tween := control.create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "scale", Vector2.ONE, 0.20)
	tween.tween_property(control, "modulate", Color.WHITE, 0.24)
	control.set_meta("hud_pulse", tween)

static func add_part_preview(button: Button, part: Dictionary, color: Color) -> void:
	# Render the same geometry that will be placed. Only the six tray slots and
	# the current catalogue preview use a live render target.
	var view := SubViewport.new()
	view.name = "BrickPreviewWorld"
	view.size = Vector2i(124, 72)
	view.own_world_3d = true
	view.transparent_bg = true
	view.render_target_update_mode = SubViewport.UPDATE_ONCE
	view.msaa_3d = Viewport.MSAA_2X

	var camera := Camera3D.new()
	camera.name = "BrickPreviewCamera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	view.add_child(camera)
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
	preview.name = "BrickPreview"
	preview.texture = view.get_texture()
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(preview)
	preview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	preview.offset_left = 4
	preview.offset_right = -4
	preview.offset_top = 3
	preview.offset_bottom = -22
	update_part_preview(button, part, color)

static func update_part_preview(button: Button, part: Dictionary, color: Color) -> void:
	var view := button.get_node_or_null("BrickPreviewWorld") as SubViewport
	if not view:
		add_part_preview(button, part, color)
		return
	var old_model := view.get_node_or_null("BrickPreviewModel")
	if old_model:
		view.remove_child(old_model)
		old_model.queue_free()
	var model := PartMeshBuilder.build_part_node(part, color)
	model.name = "BrickPreviewModel"
	view.add_child(model)
	var dims: Array = part.get("dimensions_studs", [2, 3, 2])
	var span := maxf(maxf(float(dims[0]), float(dims[2])), float(dims[1]) * 0.4)
	var focus := Vector3(0, float(dims[1]) * 0.2, 0)
	var camera := view.get_node("BrickPreviewCamera") as Camera3D
	camera.size = maxf(2.4, span * 1.20)
	camera.position = focus + Vector3(5, 5, 7)
	camera.basis = Basis.looking_at(focus - camera.position)
	view.render_target_update_mode = SubViewport.UPDATE_ONCE

static func bind_responsive_layout(root: Control) -> void:
	var top := root.get_node("TopPanel") as Control
	var commands := root.get_node("Commands") as Control
	var dock := root.get_node("LeftDock") as Control
	var camera := root.get_node("CameraPanel") as Control
	var build := root.get_node("RightControls") as Control
	var tray := root.get_node("BottomPanel") as Control
	var catalog := root.get_node("CatalogModal") as Control
	var panels := [top, commands, dock, camera, build, tray, catalog]
	var default_rects: Dictionary = {}
	for panel in panels:
		default_rects[panel] = [panel.anchor_left, panel.anchor_top, panel.anchor_right, panel.anchor_bottom,
			panel.offset_left, panel.offset_top, panel.offset_right, panel.offset_bottom]
	var mobile_buttons: Array[Button] = []
	for panel in [commands, dock, camera, build, tray, catalog]:
		for child in panel.find_children("*", "Button", true, false):
			mobile_buttons.append(child as Button)
	var defaults: Dictionary = {}
	for button in mobile_buttons:
		defaults[button] = [button.custom_minimum_size, button.text, button.clip_text, button.size_flags_horizontal]
	var filters := catalog.find_child("FilterBar") as BoxContainer
	var catalog_body := catalog.find_child("CatalogBody") as BoxContainer
	var catalog_detail := catalog.find_child("CatalogDetail") as Control
	var catalog_grid := catalog.find_child("CatalogGrid") as GridContainer
	var catalog_pick := catalog.find_child("BtnPickPart") as Button
	var search := catalog.find_child("LineCatalogSearch") as LineEdit
	var title := top.find_child("IdentityHeader") as Control
	var tools := build.find_child("BuildTools") as BoxContainer
	var place := tools.find_child("BtnPlace") as Button
	var height_mode := tools.find_child("BtnAutoHeight") as Button
	var fine_tools := [height_mode, tools.find_child("BtnLayerDown"), tools.find_child("BtnLayerUp"), tools.find_child("BtnReturnBase")]
	var command_labels := {"BtnLeave": "Leave", "BtnUndo": "", "BtnRedo": "", "BtnSettings": "Settings"}
	var build_labels := {"BtnRotateLeft": "", "BtnRotateRight": "", "BtnCancel": ""}
	var camera_title := camera.find_child("CameraTitle") as Label
	var camera_rows := camera.find_child("ViewControls") as VBoxContainer
	var label_tools := ["BtnBrickColor", "BtnErase", "BtnHeightControls"]
	var camera_hint := camera.find_child("CameraHint") as Label
	var catalogue_title := catalog.find_child("ModalTitle") as Label
	var advanced := PanelContainer.new()
	advanced.name = "HeightControls"
	advanced.hide()
	root.add_child(advanced)
	root.move_child(advanced, build.get_index() + 1)
	var advanced_row := HBoxContainer.new()
	advanced.add_child(advanced_row)
	var height_button := Button.new()
	height_button.name = "BtnHeightControls"
	height_button.text = "Height"
	height_button.icon = _texture("height", INK)
	height_button.expand_icon = true
	height_button.add_theme_constant_override("icon_max_width", 15)
	height_button.tooltip_text = "Show height controls"
	height_button.accessibility_name = "Show height controls"
	height_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	height_button.hide()
	tools.add_child(height_button)
	height_button.pressed.connect(func():
		advanced.visible = not advanced.visible
		select(height_button, advanced.visible)
	)

	var layout := func():
		var width := root.size.x
		var height := root.size.y
		var compact := width < 1090.0 or height < 530.0
		var tall := height > width or width < 580.0
		root.set_meta("compact_hud", compact)
		for panel in panels:
			_set_rect(panel, default_rects[panel])
		camera_title.visible = true
		camera_hint.visible = true
		camera_rows.add_theme_constant_override("separation", 7)
		for button in mobile_buttons:
			var previous: Array = defaults[button]
			button.custom_minimum_size = previous[0]
			button.clip_text = previous[2]
			button.size_flags_horizontal = previous[3]
			if button.name in ["BtnUndo", "BtnRedo", "BtnRotateLeft", "BtnRotateRight", "BtnCancel", "BtnBrickColor", "BtnErase"]:
				button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
			if command_labels.has(button.name) or build_labels.has(button.name) or button.name in ["BtnBrickColor", "BtnErase"]:
				button.text = previous[1]
			if command_labels.has(button.name) or button.get_parent() == commands.find_child("Actions"):
				button.remove_theme_font_size_override("font_size")
		for option in [dock.find_child("OptRoom"), catalog.find_child("OptCatalogPack"), catalog.find_child("OptCatalogCategory")]:
			var popup: PopupMenu = option.get_popup()
			var line_height := popup.get_theme_font("font").get_height(popup.get_theme_font_size("font_size"))
			var row_height := 44.0
			if compact and not tall and option.name != "OptRoom":
				# Keep the entire filter list tappable in short landscape views.
				var available := height - 119.0
				row_height = minf(row_height, available / maxf(9.0, option.item_count))
			popup.add_theme_constant_override("v_separation", maxi(4, floori(row_height - line_height)) if compact else 8)
			popup.max_size.y = clampi(int(height * 0.84), 160, 540) if compact else 0
		for button in fine_tools:
			var parent := advanced_row as Node if compact else tools as Node
			if button.get_parent() != parent:
				var scene_owner: Node = button.owner
				button.owner = null
				button.reparent(parent, false)
				button.owner = scene_owner
		height_button.visible = compact
		title.visible = not compact
		place.visible = not compact
		filters.vertical = compact and tall
		catalog_body.vertical = compact and tall
		catalog_detail.custom_minimum_size.x = 0 if compact and tall else 204
		if not compact:
			catalog_detail.custom_minimum_size.x = 208
		catalogue_title.text = "Parts" if compact else "Parts catalogue"
		catalog_pick.clip_text = compact
		search.custom_minimum_size.y = 44 if compact else 0
		height_button.text = "Height"
		height_button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		tools.add_theme_constant_override("separation", 5)
		if not compact:
			for button in tools.get_children():
				button.remove_theme_font_size_override("font_size")
			advanced.hide()
			select(height_button, false)
			camera_hint.text = "Right-drag · Scroll" if camera_hint.text == "Pinch to zoom" else camera_hint.text
			return

		for button in mobile_buttons:
			button.custom_minimum_size.y = 44
		for button in commands.find_child("Actions").get_children():
			button.custom_minimum_size.x = 44
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.clip_text = true
			button.add_theme_font_size_override("font_size", 13)
			if command_labels.has(button.name):
				button.text = command_labels[button.name]
			if tall and width < 350.0:
				if button.name == "BtnSettings":
					button.text = "Setup"
				elif button.name == "BtnFinish" and button.text == "Explore":
					button.add_theme_font_size_override("font_size", 11)
			if button.name in ["BtnUndo", "BtnRedo"]:
				button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
				button.size_flags_horizontal = Control.SIZE_FILL
		for button in tools.get_children():
			button.custom_minimum_size = Vector2(44, 46)
			button.clip_text = true
			button.add_theme_font_size_override("font_size", 13)
			if build_labels.has(button.name):
				button.text = build_labels[button.name]
				button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
				button.size_flags_horizontal = Control.SIZE_FILL
		tools.add_theme_constant_override("separation", 4)
		var show_tool_labels := width >= (382.0 if tall else 730.0)
		for name in label_tools:
			var tool_button := tools.find_child(name, false, false) as Button
			if show_tool_labels:
				tool_button.custom_minimum_size.x = 70
				if tool_button == height_button:
					tool_button.add_theme_font_size_override("font_size", 12)
			else:
				tool_button.text = ""
				tool_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		height_mode.custom_minimum_size.x = 135
		if camera_hint.text == "Right-drag · Scroll":
			camera_hint.text = "Pinch to zoom"
		for name in ["OptCatalogPack", "OptCatalogCategory"]:
			var filter := catalog.find_child(name) as OptionButton
			filter.custom_minimum_size.x = 0 if tall else 132
			filter.fit_to_longest_item = false
			filter.clip_text = true
		catalog_grid.columns = 2 if tall else 3
		_set_rect(tray, [0, 1, 1, 1, 6, -86, -6, -6])
		_set_rect(catalog, [0, 0, 1, 1, 8, 8, -8, -8])
		if tall:
			_set_rect(top, [0, 0, 1, 0, 6, 4, -6, 31])
			_set_rect(commands, [0, 0, 1, 0, 6, 36, -6, 90])
			_set_rect(dock, [0, 0, 0, 0, 6, 95, 234, 149])
			_set_rect(camera, [0, 0, 0, 0, 6, 154, 234, 420])
			_set_rect(build, [0, 1, 1, 1, 6, -138, -6, -85])
			_set_rect(advanced, [1, 1, 1, 1, -291, -194, -6, -143])
		else:
			camera_title.hide()
			camera_hint.hide()
			camera_rows.add_theme_constant_override("separation", 4)
			_set_rect(top, [0, 0, 0.35, 0, 6, 7, -6, 55])
			_set_rect(commands, [0.35, 0, 1, 0, 0, 5, -6, 59])
			_set_rect(dock, [0, 1, 0, 1, 6, -138, 233, -85])
			_set_rect(camera, [0, 1, 0, 1, 6, -345, 233, -142])
			_set_rect(build, [0, 1, 1, 1, 237, -138, -6, -85])
			_set_rect(advanced, [1, 1, 1, 1, -291, -194, -6, -143])

	root.resized.connect(layout)
	layout.call()

static func _set_rect(panel: Control, values: Array) -> void:
	panel.anchor_left = values[0]
	panel.anchor_top = values[1]
	panel.anchor_right = values[2]
	panel.anchor_bottom = values[3]
	panel.offset_left = values[4]
	panel.offset_top = values[5]
	panel.offset_right = values[6]
	panel.offset_bottom = values[7]
