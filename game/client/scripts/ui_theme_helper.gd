class_name UIThemeHelper
extends RefCounted

## Unified design tokens and theme generator for LittleBricks Family Play Experience (LB-060).
## Implements warm craft-table canvas, tactile buttons, soft rounded containers,
## and accessible high-contrast typography according to docs/FAMILY_PLAY_EXPERIENCE.md.

const COLOR_CANVAS_CREAM: Color = Color(1.0, 0.957, 0.875, 1.0) # #FFF4DF
const COLOR_SURFACE_PAPER: Color = Color(1.0, 0.984, 0.945, 1.0) # #FFFBF1
const COLOR_TEXT_INK: Color = Color(0.141, 0.204, 0.231, 1.0) # #24343B
const COLOR_TEXT_SECONDARY: Color = Color(0.35, 0.42, 0.46, 1.0)
const COLOR_PRIMARY_TEAL: Color = Color(0.129, 0.408, 0.357, 1.0) # #21685B
const COLOR_PRIMARY_TEAL_HOVER: Color = Color(0.16, 0.48, 0.42, 1.0)
const COLOR_PRIMARY_TEAL_PRESSED: Color = Color(0.10, 0.35, 0.30, 1.0)
const COLOR_SECONDARY_BG: Color = Color(0.93, 0.89, 0.83, 1.0) # #EDE4D3
const COLOR_SECONDARY_HOVER: Color = Color(0.88, 0.84, 0.77, 1.0)
const COLOR_SECONDARY_PRESSED: Color = Color(0.82, 0.78, 0.70, 1.0)
const COLOR_ACCENT_CORAL: Color = Color(0.929, 0.475, 0.373, 1.0) # #ED795F
const COLOR_ACCENT_YELLOW: Color = Color(0.957, 0.792, 0.408, 1.0) # #F4CA68
const COLOR_ACCENT_SKY: Color = Color(0.451, 0.718, 0.816, 1.0) # #73B7D0
const COLOR_BORDER_WARM: Color = Color(0.847, 0.8, 0.718, 1.0) # #D8CCB7
const COLOR_ERROR_INK: Color = Color(0.612, 0.2, 0.263, 1.0) # #9C3343

static func create_primary_button_style(bg_col: Color) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.set_corner_radius_all(14)
	sb.set_content_margin_all(12)
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	sb.shadow_color = Color(0.14, 0.2, 0.23, 0.12)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2(0, 3)
	return sb

static func create_secondary_button_style(bg_col: Color, border_col: Color = COLOR_BORDER_WARM) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_color = border_col
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(14)
	sb.set_content_margin_all(10)
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb

static func create_card_style(bg_col: Color = COLOR_SURFACE_PAPER, border_col: Color = COLOR_BORDER_WARM) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_color = border_col
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(20)
	sb.set_content_margin_all(20)
	sb.shadow_color = Color(0.14, 0.2, 0.23, 0.08)
	sb.shadow_size = 8
	sb.shadow_offset = Vector2(0, 4)
	return sb

static func apply_primary_button(btn: Button) -> void:
	if not btn: return
	btn.add_theme_stylebox_override("normal", create_primary_button_style(COLOR_PRIMARY_TEAL))
	btn.add_theme_stylebox_override("hover", create_primary_button_style(COLOR_PRIMARY_TEAL_HOVER))
	btn.add_theme_stylebox_override("pressed", create_primary_button_style(COLOR_PRIMARY_TEAL_PRESSED))
	btn.add_theme_stylebox_override("focus", create_primary_button_style(COLOR_PRIMARY_TEAL_HOVER))
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color(0.9, 0.9, 0.9))
	btn.add_theme_font_size_override("font_size", 18)
	if btn.custom_minimum_size.y < 48:
		btn.custom_minimum_size.y = 48

static func apply_secondary_button(btn: Button) -> void:
	if not btn: return
	btn.add_theme_stylebox_override("normal", create_secondary_button_style(COLOR_SECONDARY_BG))
	btn.add_theme_stylebox_override("hover", create_secondary_button_style(COLOR_SECONDARY_HOVER))
	btn.add_theme_stylebox_override("pressed", create_secondary_button_style(COLOR_SECONDARY_PRESSED))
	btn.add_theme_stylebox_override("focus", create_secondary_button_style(COLOR_SECONDARY_HOVER))
	btn.add_theme_color_override("font_color", COLOR_TEXT_INK)
	btn.add_theme_color_override("font_hover_color", COLOR_TEXT_INK)
	btn.add_theme_color_override("font_pressed_color", COLOR_TEXT_INK)
	btn.add_theme_font_size_override("font_size", 16)
	if btn.custom_minimum_size.y < 44:
		btn.custom_minimum_size.y = 44

static func apply_card(panel: PanelContainer, border_col: Color = COLOR_BORDER_WARM) -> void:
	if not panel: return
	panel.add_theme_stylebox_override("panel", create_card_style(COLOR_SURFACE_PAPER, border_col))
