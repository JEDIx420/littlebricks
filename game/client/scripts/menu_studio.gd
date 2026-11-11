extends RefCounted

const SANS = preload("res://assets/ui/fonts/DM-Sans.ttf")
const SERIF = preload("res://assets/ui/fonts/DM-Serif-Text.ttf")
const INK := Color("#233b35")
const MUTED := Color("#546359")
const PAPER := Color("#faf6ec")
const CANVAS := Color("#f1eadc")
const BORDER := Color("#d7cebd")
const GREEN := Color("#285648")
const FOCUS := Color("#ad6741")

static func apply_theme(screen: Control) -> void:
	var theme := Theme.new()
	theme.default_font = SANS
	theme.default_font_size = 17
	theme.set_color("font_color", "Label", INK)
	theme.set_color("font_color", "LineEdit", INK)
	theme.set_color("font_placeholder_color", "LineEdit", MUTED)
	theme.set_color("font_color", "PopupMenu", INK)
	theme.set_color("font_hover_color", "PopupMenu", INK)
	theme.set_stylebox("panel", "PopupMenu", surface(PAPER, 12))
	theme.set_stylebox("hover", "PopupMenu", surface(Color("#e4ebdf"), 6, Color.TRANSPARENT, false))
	theme.set_stylebox("normal", "LineEdit", surface(Color("#fffdf7"), 9))
	theme.set_stylebox("focus", "LineEdit", focus_ring(9))
	screen.theme = theme
	var background := screen.get_node_or_null("Background") as ColorRect
	if background:
		background.color = CANVAS
		background.mouse_filter = Control.MOUSE_FILTER_IGNORE

static func style_label(label: Label, font_size: int, serif: bool = false, color: Color = INK) -> void:
	label.add_theme_font_override("font", SERIF if serif else SANS)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)

static func surface(color: Color, radius: int, border: Color = BORDER, shadow: bool = false) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 15
	box.content_margin_right = 15
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	if shadow:
		box.shadow_color = Color("#33271c22")
		box.shadow_size = 10
		box.shadow_offset = Vector2(0, 6)
	return box

static func focus_ring(radius: int) -> StyleBoxFlat:
	var box := surface(Color.TRANSPARENT, radius, FOCUS)
	box.set_border_width_all(2)
	return box

static func button(control: Button, primary: bool = false) -> void:
	var normal := GREEN if primary else PAPER
	var hover := Color("#356b59") if primary else Color("#e8ecdf")
	var pressed := Color("#1d4439") if primary else Color("#dce4d7")
	var border := normal if primary else BORDER
	var ink := Color("#fff9ea") if primary else INK
	control.add_theme_stylebox_override("normal", surface(normal, 9, border, primary))
	control.add_theme_stylebox_override("hover", surface(hover, 9, border))
	control.add_theme_stylebox_override("pressed", surface(pressed, 9, border))
	control.add_theme_stylebox_override("focus", focus_ring(9))
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		control.add_theme_color_override(color_name, ink)
	control.custom_minimum_size.y = maxf(control.custom_minimum_size.y, 48.0)
