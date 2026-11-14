extends Control
class_name WelcomeScreen

## Welcome screen controller (LB-035).
## Displays game branding, prominent Continue button if recent save exists,
## New Play, My Builds, Settings, and immediate audio mute toggle.

const Studio = preload("res://client/scripts/menu_studio.gd")

signal continue_pressed()
signal play_pressed()
signal my_builds_pressed()
signal settings_pressed()
signal mute_toggled(is_muted: bool)

@onready var btn_continue: Button = %BtnContinue
@onready var btn_play: Button = %BtnPlay
@onready var btn_my_builds: Button = %BtnMyBuilds
@onready var btn_settings: Button = %BtnSettings
@onready var btn_mute: Button = %BtnMute
@onready var label_continue_info: Label = %LabelContinueInfo

var latest_save_path: String = ""
var is_muted: bool = false

func _ready() -> void:
	if not btn_continue: btn_continue = find_child("BtnContinue", true, false)
	if not btn_play: btn_play = find_child("BtnPlay", true, false)
	if not btn_my_builds: btn_my_builds = find_child("BtnMyBuilds", true, false)
	if not btn_settings: btn_settings = find_child("BtnSettings", true, false)
	if not btn_mute: btn_mute = find_child("BtnMute", true, false)
	if not label_continue_info: label_continue_info = find_child("LabelContinueInfo", true, false)
	
	Studio.apply_theme(self, true)
	Studio.style_label(label_continue_info, 14, false, Color("#dbceae"))
	Studio.button(btn_play, true, Studio.PERSIMMON)
	Studio.button(btn_continue, true, Studio.COBALT)
	for button in [btn_my_builds, btn_settings, btn_mute]:
		Studio.dark_button(button)
	var body := $ContentScroll/Center/Body
	var hero := body.get_node("Hero") as PanelContainer
	hero.add_theme_stylebox_override("panel", Studio.frame())
	Studio.enter(body)
	$Divider.color = Color("#a78552")
	if not resized.is_connected(_layout_welcome):
		resized.connect(_layout_welcome)

	if btn_continue and not btn_continue.pressed.is_connected(_on_continue_clicked):
		btn_continue.pressed.connect(_on_continue_clicked)
	if btn_play and not btn_play.pressed.is_connected(_on_play_clicked):
		btn_play.pressed.connect(_on_play_clicked)
	if btn_my_builds and not btn_my_builds.pressed.is_connected(_on_my_builds_clicked):
		btn_my_builds.pressed.connect(_on_my_builds_clicked)
	if btn_settings and not btn_settings.pressed.is_connected(_on_settings_clicked):
		btn_settings.pressed.connect(_on_settings_clicked)
	if btn_mute and not btn_mute.pressed.is_connected(_on_mute_pressed):
		btn_mute.pressed.connect(_on_mute_pressed)
	
	_update_mute_display()
	_check_for_latest_save()
	_layout_welcome()

func _layout_welcome() -> void:
	var compact := size.x < 920.0 or size.y < 545.0
	var stacked := size.x < 620.0 or size.x / maxf(size.y, 1.0) < 0.92
	var short_landscape := not stacked and size.y <= 445.0
	var body := $ContentScroll/Center/Body as BoxContainer
	var copy := body.get_node("Copy") as VBoxContainer
	var stage := body.get_node("Hero/Stage") as SubViewportContainer
	var heading := copy.get_node("Heading") as VBoxContainer
	var actions := copy.get_node("Actions") as BoxContainer
	var tag := copy.get_node("Tagline") as Label
	var has_save := not latest_save_path.is_empty()
	var gutter := 12.0 if compact else 28.0
	var available := maxf(230.0, minf(size.x - 2.0 * gutter - 14.0, 1300.0))
	var compact_header := size.x < 465.0

	Studio.style_label($TopBar/Brand, 19 if compact_header else 28, true, Studio.IVORY)
	$TopBar.offset_left = gutter
	$TopBar.offset_right = -gutter
	$TopBar.offset_top = 8.0 if compact else 16.0
	$TopBar.offset_bottom = 56.0 if compact else 68.0
	$TopBar.add_theme_constant_override("separation", 7 if compact_header else 12)
	for button in [btn_settings, btn_mute]:
		button.add_theme_font_size_override("font_size", 13 if compact_header else 17)
		for state in ["normal", "hover", "pressed"]:
			var style := button.get_theme_stylebox(state) as StyleBoxFlat
			style.content_margin_left = 11 if compact_header else 15
			style.content_margin_right = style.content_margin_left
	$Divider.offset_left = gutter
	$Divider.offset_right = -gutter
	$Divider.offset_top = 62.0 if compact else 76.0
	$Divider.offset_bottom = $Divider.offset_top + 1.0
	$ContentScroll.offset_left = gutter
	$ContentScroll.offset_right = -gutter
	$ContentScroll.offset_top = 70.0 if compact else 94.0
	$ContentScroll.offset_bottom = -12.0 if compact else -26.0

	body.vertical = stacked
	actions.vertical = not short_landscape
	actions.add_theme_constant_override("separation", 6 if short_landscape else 8)
	copy.move_child(actions, -1 if short_landscape else 3)
	tag.visible = not short_landscape or not has_save
	copy.get_node("ActionSpace").visible = not short_landscape
	for button in [btn_play, btn_my_builds, btn_continue]:
		button.add_theme_font_size_override("font_size", 15 if short_landscape else 17)
	btn_play.custom_minimum_size.y = 48.0 if short_landscape else 56.0
	var hero_height := clampf(size.y - 92.0, 180.0, 400.0) if compact else clampf(size.y - 135.0, 400.0, 635.0)
	body.custom_minimum_size = Vector2(available, 0.0 if stacked else hero_height)
	body.add_theme_constant_override("separation", 14 if compact else 44)
	copy.add_theme_constant_override("separation", 7 if compact else 14)
	stage.custom_minimum_size.y = clampf(available * 0.57, 140.0, 280.0) if stacked else 0.0
	Studio.style_label(tag, 15 if compact else 21, false, Color("#faeace"))
	heading.add_theme_constant_override("separation", -4 if compact else -14)
	var font_size := int(clampf(available * (0.138 if stacked else 0.056 if compact else 0.073), 35, 92))
	Studio.style_label(heading.get_node("TitleFirst"), font_size, true, Studio.IVORY)
	Studio.style_label(heading.get_node("Title"), font_size, true, Studio.CORAL)

func set_mute_state(muted: bool) -> void:
	is_muted = muted
	_update_mute_display()

func _update_mute_display() -> void:
	if btn_mute:
		btn_mute.text = "Sound: OFF" if is_muted else "Sound: ON"

func _on_mute_pressed() -> void:
	is_muted = not is_muted
	_update_mute_display()
	mute_toggled.emit(is_muted)

func _on_continue_clicked() -> void:
	continue_pressed.emit()

func _on_play_clicked() -> void:
	play_pressed.emit()

func _on_my_builds_clicked() -> void:
	my_builds_pressed.emit()

func _on_settings_clicked() -> void:
	settings_pressed.emit()

func _check_for_latest_save() -> void:
	latest_save_path = ""
	var dir = DirAccess.open("user://saves")
	if not dir:
		if btn_continue: btn_continue.visible = false
		if label_continue_info: label_continue_info.visible = false
		return
		
	dir.list_dir_begin()
	var filename = dir.get_next()
	var newest_time: int = 0
	var newest_file: String = ""
	
	while filename != "":
		if filename.ends_with(".json") and not filename.ends_with(".tmp"):
			var full_path = "user://saves/" + filename
			var mod_time = FileAccess.get_modified_time(full_path)
			if mod_time > newest_time:
				newest_time = mod_time
				newest_file = full_path
		filename = dir.get_next()
		
	if not newest_file.is_empty():
		latest_save_path = newest_file
		btn_continue.visible = true
		btn_continue.text = "Continue Creation"
		label_continue_info.visible = true
		label_continue_info.text = "Resume: %s" % newest_file.get_file().get_basename()
	else:
		btn_continue.visible = false
		label_continue_info.visible = false


