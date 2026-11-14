class_name WorkbenchHUD
extends RefCounted

const INK := Color("#fff3dd")
const MUTED := Color("#d8c8aa")
const PANEL := Color("#173b32")
const BUTTON := Color("#265044")
const EDGE := Color("#597062")
const ACTIVE := Color("#edbd66")
const DARK := Color("#222f27")
const IVORY := Color("#f5e8d1")
const COBALT := Color("#2d4da4")
const PERSIMMON := Color("#fb865e")

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
	title.add_theme_font_size_override("font_size", 23)
	var count := root.find_child("BrickCount", true, false) as Label
	if count:
		count.add_theme_stylebox_override("normal", surface(Color("#32594b"), Color("#788166"), 6, 4))
		count.add_theme_color_override("font_color", ACTIVE)
	var tray := root.get_node("BottomPanel") as PanelContainer
	var tray_frame := card.duplicate() as StyleBoxFlat
	tray_frame.border_color = Color("#ad935e")
	tray_frame.border_width_bottom = 2
	tray.add_theme_stylebox_override("panel", tray_frame)
	var catalogue := root.get_node("CatalogModal") as PanelContainer
	var catalogue_frame := card.duplicate() as StyleBoxFlat
	catalogue_frame.border_color = Color("#9b946f")
	catalogue_frame.set_content_margin_all(10)
	catalogue.add_theme_stylebox_override("panel", catalogue_frame)
	var catalogue_title := catalogue.find_child("ModalTitle", true, false) as Label
	catalogue_title.add_theme_font_override("font", display_font)
	catalogue_title.add_theme_font_size_override("font_size", 24)
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
	_action(root.find_child("BtnPlace", true, false), PERSIMMON, Color("#ffa07c"), Color("#893b27"), DARK)
	_action(root.find_child("BtnAllParts", true, false), COBALT, Color("#375cc2"), Color("#162b63"), INK)
	_action(root.find_child("BtnPickPart", true, false), ACTIVE, Color("#f9d38d"), Color("#70502f"), DARK)

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
	var search := catalog.find_child("LineCatalogSearch") as LineEdit
	var title := top.find_child("Title") as Label
	var tools := build.find_child("BuildTools") as BoxContainer
	var place := tools.find_child("BtnPlace") as Button
	var height_mode := tools.find_child("BtnAutoHeight") as Button
	var fine_tools := [height_mode, tools.find_child("BtnLayerDown"), tools.find_child("BtnLayerUp"), tools.find_child("BtnReturnBase")]
	var command_labels := {"BtnLeave": "Leave"}
	var build_labels := {"BtnRotateLeft": "Turn left", "BtnRotateRight": "Turn right", "BtnCancel": "Drop"}
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
	height_button.text = "Height"
	height_button.tooltip_text = "Show height controls"
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
		var compact := width < 820.0 or height < 530.0
		var tall := height > width or width < 580.0
		root.set_meta("compact_hud", compact)
		for panel in panels:
			_set_rect(panel, default_rects[panel])
		for button in mobile_buttons:
			var previous: Array = defaults[button]
			button.custom_minimum_size = previous[0]
			button.clip_text = previous[2]
			button.size_flags_horizontal = previous[3]
			if command_labels.has(button.name) or build_labels.has(button.name):
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
		catalog_detail.custom_minimum_size.x = 0 if compact and tall else 180
		catalogue_title.text = "Parts" if compact else "Parts catalogue"
		search.custom_minimum_size.y = 44 if compact else 0
		if not compact:
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
		for button in tools.get_children():
			button.custom_minimum_size = Vector2(44, 46)
			button.clip_text = true
			if build_labels.has(button.name):
				button.text = build_labels[button.name]
		height_mode.custom_minimum_size.x = 135
		if camera_hint.text == "Right-drag · Scroll":
			camera_hint.text = "Pinch to zoom"
		for name in ["OptCatalogPack", "OptCatalogCategory"]:
			var filter := catalog.find_child(name) as OptionButton
			filter.custom_minimum_size.x = 0 if tall else 132
			filter.fit_to_longest_item = false
			filter.clip_text = true
		catalog_grid.columns = 2 if tall else 3
		_set_rect(tray, [0, 1, 1, 1, 6, -87, -6, -6])
		_set_rect(catalog, [0, 0, 1, 1, 8, 8, -8, -8])
		if tall:
			_set_rect(top, [0, 0, 1, 0, 6, 4, -6, 31])
			_set_rect(commands, [0, 0, 1, 0, 6, 36, -6, 90])
			_set_rect(dock, [0, 0, 0, 0, 6, 95, 234, 149])
			_set_rect(camera, [0, 0, 0, 0, 6, 154, 234, 420])
			_set_rect(build, [0, 1, 1, 1, 6, -146, -6, -91])
			_set_rect(advanced, [1, 1, 1, 1, -291, -202, -6, -150])
		else:
			_set_rect(top, [0, 0, 0.35, 0, 6, 7, -6, 55])
			_set_rect(commands, [0.35, 0, 1, 0, 0, 5, -6, 59])
			_set_rect(dock, [0, 1, 0, 1, 6, -146, 234, -91])
			_set_rect(camera, [0, 0, 0, 0, 6, 60, 234, 325])
			_set_rect(build, [0, 1, 1, 1, 239, -146, -6, -91])
			_set_rect(advanced, [1, 1, 1, 1, -291, -202, -6, -150])

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
