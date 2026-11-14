class_name BrickColorPalette
extends RefCounted

const HUD := preload("res://client/scripts/workbench_hud.gd")
const DISPLAY_FONT := preload("res://assets/ui/fonts/DM-Serif-Text.ttf")
const BODY_FONT := preload("res://assets/ui/fonts/DM-Sans.ttf")
const SWATCHES := {
	"Red": Color("#c92827"), "Orange": Color("#ef772a"), "Yellow": Color("#f2c02b"),
	"Lime": Color("#9dc74b"), "Green": Color("#30894b"), "Teal": Color("#369e9f"),
	"Sky blue": Color("#74c7e9"), "Blue": Color("#335bc9"), "Purple": Color("#8353a8"),
	"Pink": Color("#ed91b0"), "Brown": Color("#825139"), "Tan": Color("#d2b486"),
	"White": Color("#f5f0df"), "Gray": Color("#90949b"), "Black": Color("#25272c"),
}

static func attach(launcher: Button, current_color: Callable, on_color_selected: Callable) -> PopupPanel:
	var popup := PopupPanel.new()
	popup.name = "BrickColorPalette"
	popup.borderless = true
	popup.transient = true
	popup.popup_window = true
	launcher.add_child(popup)
	var frame := HUD.surface(Color("#f8ecd5"), Color("#ad9267"), 13, 12)
	popup.add_theme_stylebox_override("panel", frame)
	var overlay_theme := Theme.new()
	overlay_theme.default_font = BODY_FONT
	overlay_theme.default_font_size = 14
	overlay_theme.set_color("font_color", "Label", HUD.DARK)
	overlay_theme.set_color("font_color", "LineEdit", HUD.DARK)
	overlay_theme.set_color("font_placeholder_color", "LineEdit", Color("#665f50"))
	overlay_theme.set_color("caret_color", "LineEdit", HUD.DARK)
	overlay_theme.set_stylebox("normal", "LineEdit", HUD.surface(Color("#fff8e9"), Color("#ab956f"), 8, 7))
	var focus := HUD.surface(Color.TRANSPARENT, HUD.COBALT, 8, 7)
	focus.set_border_width_all(2)
	overlay_theme.set_stylebox("focus", "LineEdit", focus)
	var stack := VBoxContainer.new()
	stack.theme = overlay_theme
	stack.add_theme_constant_override("separation", 7)
	popup.add_child(stack)
	var header := HBoxContainer.new()
	stack.add_child(header)
	var title := Label.new()
	title.text = "Brick color"
	title.add_theme_font_override("font", DISPLAY_FONT)
	title.add_theme_font_size_override("font_size", 21)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close := Button.new()
	close.text = "Close"
	close.custom_minimum_size = Vector2(54, 44)
	_style_button(close, false)
	close.pressed.connect(popup.hide)
	header.add_child(close)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 4)
	stack.add_child(grid)

	var swatches: Array[Button] = []
	var choose := func(color: Color):
		on_color_selected.call(color)
		update_launcher(launcher, current_color.call())
		popup.hide()
	for label: String in SWATCHES:
		var color: Color = SWATCHES[label]
		var button := Button.new()
		button.text = label
		button.icon = _chip(color)
		button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(89, 44)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_style_button(button, false)
		button.pressed.connect(choose.bind(color))
		grid.add_child(button)
		swatches.append(button)

	var custom := HBoxContainer.new()
	custom.add_theme_constant_override("separation", 6)
	stack.add_child(custom)
	var hex_input := LineEdit.new()
	hex_input.placeholder_text = "#RRGGBB"
	hex_input.accessibility_name = "Custom hex color"
	hex_input.custom_minimum_size = Vector2(89, 44)
	hex_input.max_length = 7
	hex_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	custom.add_child(hex_input)
	var apply := Button.new()
	apply.text = "Apply hex"
	apply.custom_minimum_size.y = 44
	_style_button(apply, true)
	custom.add_child(apply)
	var status := Label.new()
	status.custom_minimum_size.y = 18
	status.add_theme_font_size_override("font_size", 13)
	status.add_theme_color_override("font_color", Color("#8b392b"))
	stack.add_child(status)
	var choose_hex := func():
		var color_hex := hex_input.text.strip_edges().trim_prefix("#")
		if color_hex.length() != 6 or not color_hex.is_valid_hex_number(false):
			status.text = "Enter 6 hex digits, such as 335BC9."
			hex_input.grab_focus()
			return
		choose.call(Color.from_string("#" + color_hex, Color.WHITE))
	apply.pressed.connect(choose_hex)
	hex_input.text_submitted.connect(func(_value: String): choose_hex.call())
	hex_input.text_changed.connect(func(_value: String): status.text = "")

	launcher.pressed.connect(func():
		if popup.visible:
			return
		var available := launcher.get_viewport().get_visible_rect().size
		grid.columns = 4 if available.y < 440.0 and available.x >= 430.0 else 3
		var active: Color = current_color.call()
		var selected := -1
		for index in swatches.size():
			var button := swatches[index]
			var matches: bool = _hex(SWATCHES[button.text]) == _hex(active)
			_style_button(button, matches)
			button.accessibility_description = "Current color" if matches else ""
			if matches:
				selected = index
		hex_input.text = "#" + _hex(active)
		status.text = ""
		popup.reset_size()
		popup.popup_centered()
		swatches[maxi(selected, 0)].grab_focus()
	)
	popup.popup_hide.connect(func():
		if launcher.is_visible_in_tree() and not launcher.disabled:
			launcher.grab_focus()
	)
	update_launcher(launcher, current_color.call())
	return popup

static func update_launcher(launcher: Button, color: Color) -> void:
	var color_hex := _hex(color)
	if launcher.has_meta("brick_color_hex") and launcher.get_meta("brick_color_hex") == color_hex:
		return
	launcher.set_meta("brick_color_hex", color_hex)
	var label := "#" + color_hex
	for swatch: String in SWATCHES:
		if _hex(SWATCHES[swatch]) == color_hex:
			label = swatch
			break
	launcher.icon = _chip(color)
	launcher.add_theme_constant_override("icon_max_width", 16)
	launcher.tooltip_text = "Brick color · " + label
	launcher.accessibility_name = "Brick color"
	launcher.accessibility_description = "Current color: " + label

static func _hex(color: Color) -> String:
	return color.to_html(false).to_upper()

static func _chip(color: Color) -> ImageTexture:
	var chip := Image.create_empty(16, 16, false, Image.FORMAT_RGBA8)
	chip.fill(Color.TRANSPARENT)
	chip.fill_rect(Rect2i(1, 1, 14, 14), Color("#f7ead0"))
	chip.fill_rect(Rect2i(2, 2, 12, 12), Color("#544c41"))
	chip.fill_rect(Rect2i(3, 3, 10, 10), Color(color, 1.0))
	return ImageTexture.create_from_image(chip)

static func _style_button(button: Button, emphasized: bool) -> void:
	var fill := Color("#f0cd82") if emphasized else Color("#fff8e9")
	var edge := Color("#a97c32") if emphasized else Color("#c9b792")
	button.add_theme_stylebox_override("normal", HUD.surface(fill, edge, 8, 6))
	button.add_theme_stylebox_override("hover", HUD.surface(fill.lightened(0.23), HUD.COBALT, 8, 6))
	button.add_theme_stylebox_override("pressed", HUD.surface(fill.darkened(0.10), edge, 8, 6))
	var focus := HUD.surface(Color.TRANSPARENT, HUD.COBALT, 8, 6)
	focus.set_border_width_all(2)
	button.add_theme_stylebox_override("focus", focus)
	for color in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(color, HUD.DARK)
