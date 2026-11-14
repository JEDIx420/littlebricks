extends RefCounted

const BODY_FONT := preload("res://assets/ui/fonts/DM-Sans.ttf")
const DISPLAY_FONT := preload("res://assets/ui/fonts/DM-Serif-Text.ttf")
const IVORY := Color("#fff3df")
const CREAM := Color("#f1dfbd")
const INK := Color("#24392e")
const MUTED := Color("#5a6b55")
const BRASS := Color("#b58a55")
const COBALT := Color("#254d8a")
const PERSIMMON := Color("#a53d26")
const DEEP_GREEN := Color("#284637")

static func panel(radius: int = 15, padding: int = 12) -> StyleBoxFlat:
	var style := _box(IVORY, BRASS, radius, padding)
	style.shadow_color = Color("#13251e78")
	style.shadow_offset = Vector2(0, 5)
	style.shadow_size = 7
	return style

static func button(button_control: Button, fill: Color = CREAM) -> void:
	var dark_fill := fill != CREAM
	var ink := IVORY if dark_fill else INK
	var edge := fill.darkened(0.22) if dark_fill else BRASS
	var normal := _box(fill, edge, 9, 8)
	normal.border_width_bottom = 3
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = fill.lightened(0.10)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = fill.darkened(0.12)
	pressed.border_width_bottom = 1
	var disabled := _box(Color("#e4d6bc"), Color("#c9b795"), 9, 8)
	var focus := _box(Color.TRANSPARENT, COBALT if not dark_fill else BRASS, 10, 0)
	focus.set_border_width_all(2)
	button_control.add_theme_font_override("font", BODY_FONT)
	button_control.add_theme_font_size_override("font_size", 15)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		button_control.add_theme_color_override(state, ink)
	button_control.add_theme_color_override("font_disabled_color", Color("#6c695d"))
	button_control.add_theme_stylebox_override("normal", normal)
	button_control.add_theme_stylebox_override("hover", hover)
	button_control.add_theme_stylebox_override("pressed", pressed)
	button_control.add_theme_stylebox_override("hover_pressed", pressed)
	button_control.add_theme_stylebox_override("disabled", disabled)
	button_control.add_theme_stylebox_override("focus", focus)
	button_control.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

static func progress_track(fill: Color, edge: Color) -> StyleBoxFlat:
	return _box(fill, edge, 4, 0)

static func _box(fill: Color, edge: Color, radius: int, padding: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(padding)
	return style

static func reduced_motion(node: Node) -> bool:
	var tree := node.get_tree() if node.is_inside_tree() else null
	return bool(tree.get_meta("littlebricks_reduced_motion", false)) if tree else true

class BrickMark extends Control:
	var tint := PERSIMMON

	func _draw() -> void:
		var scale_factor := minf(size.x, size.y) / 54.0
		draw_set_transform(size * 0.5 - Vector2(26.0, 24.0) * scale_factor, 0.0, Vector2.ONE * scale_factor)
		var face := Vector2(7.0, 16.0)
		draw_colored_polygon(PackedVector2Array([face, face + Vector2(38, 0), face + Vector2(35, 22), face + Vector2(2, 22)]), tint)
		draw_colored_polygon(PackedVector2Array([face + Vector2(38, 0), face + Vector2(45, -5), face + Vector2(43, 15), face + Vector2(35, 22)]), tint.darkened(0.22))
		draw_colored_polygon(PackedVector2Array([face, face + Vector2(8, -6), face + Vector2(45, -5), face + Vector2(38, 1)]), tint.lightened(0.16))
		for x in [20.0, 34.0]:
			draw_rect(Rect2(x - 4.5, 7.5, 9, 6), tint.darkened(0.08))
			draw_circle(Vector2(x, 7.5), 4.5, tint.lightened(0.22), true, -1, true)
