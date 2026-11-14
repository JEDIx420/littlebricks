extends RefCounted

const SANS = preload("res://assets/ui/fonts/DM-Sans.ttf")
const SERIF = preload("res://assets/ui/fonts/DM-Serif-Text.ttf")
const BACKDROP = preload("res://client/shaders/menu_backdrop.gdshader")
const INK := Color("#18352c")
const MUTED := Color("#4c6051")
const PAPER := Color("#fff8e9")
const CANVAS := Color("#f3e8d4")
const BORDER := Color("#d9c8a9")
const GREEN := Color("#235845")
const FOREST := Color("#173a2f")
const IVORY := Color("#fff2d7")
const BRASS := Color("#e1b362")
const PERSIMMON := Color("#c64725")
const CORAL := Color("#ffa16c")
const COBALT := Color("#254593")
const FOCUS := Color("#aa6427")

static func apply_theme(screen: Control, night: bool = false) -> void:
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
		var backdrop := ShaderMaterial.new()
		backdrop.shader = BACKDROP
		if night:
			backdrop.set_shader_parameter("paper", Color("#254c3e"))
			backdrop.set_shader_parameter("edge", Color("#0d2c22"))
			backdrop.set_shader_parameter("studs", Color("#cdb27b"))
			backdrop.set_shader_parameter("stud_weight", 0.12)
		background.material = backdrop
		background.color = FOREST if night else CANVAS
		background.mouse_filter = Control.MOUSE_FILTER_IGNORE

static func style_label(label: Label, font_size: int, serif: bool = false, color: Color = INK) -> void:
	label.add_theme_font_override("font", SERIF if serif else SANS)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)

static func enter(control: Control, delay: float = 0.0) -> void:
	if not control.is_inside_tree() or control.get_tree().get_meta("littlebricks_reduced_motion", false):
		return
	control.modulate.a = 0.82
	var reveal := control.create_tween()
	reveal.tween_property(control, "modulate:a", 1.0, 0.22).set_delay(delay).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

static func frame(color: Color = BRASS) -> StyleBoxFlat:
	var box := surface(Color("#977144"), 15, color, true)
	box.set_border_width_all(2)
	box.set_content_margin_all(6.0)
	return box

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

static func button(control: Button, primary: bool = false, accent: Color = GREEN) -> void:
	var normal := accent if primary else PAPER
	var hover := accent.darkened(0.08) if primary else Color("#f3e4c6")
	var pressed := accent.darkened(0.20) if primary else Color("#ebd8b7")
	var border := accent.darkened(0.18) if primary else BORDER
	var ink := Color("#fff9eb") if primary else INK
	var resting := surface(normal, 10, border, false)
	if primary:
		resting.border_width_bottom = 3
	control.add_theme_stylebox_override("normal", resting)
	control.add_theme_stylebox_override("hover", surface(hover, 10, border))
	control.add_theme_stylebox_override("pressed", surface(pressed, 10, border))
	control.add_theme_stylebox_override("focus", focus_ring(10))
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		control.add_theme_color_override(color_name, ink)
	control.custom_minimum_size.y = maxf(control.custom_minimum_size.y, 48.0)

static func dark_button(control: Button) -> void:
	control.add_theme_stylebox_override("normal", surface(Color("#21473a"), 10, Color("#699078")))
	control.add_theme_stylebox_override("hover", surface(Color("#335948"), 10, BRASS))
	control.add_theme_stylebox_override("pressed", surface(Color("#13372b"), 10, BRASS))
	control.add_theme_stylebox_override("focus", focus_ring(10))
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		control.add_theme_color_override(color_name, IVORY)
	control.custom_minimum_size.y = maxf(control.custom_minimum_size.y, 48.0)
