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
	
	Studio.apply_theme(self)
	Studio.style_label($ContentScroll/Center/Body/Copy/Tagline, 20, false, Studio.MUTED)
	Studio.style_label(label_continue_info, 14, false, Studio.MUTED)
	Studio.button(btn_play, true)
	for button in [btn_continue, btn_my_builds, btn_settings, btn_mute]:
		Studio.button(button)
	var hero := $ContentScroll/Center/Body/Hero as PanelContainer
	var frame := Studio.surface(Color("#d2c0a2"), 16, Color("#e1d0b6"), true)
	frame.set_content_margin_all(6.0)
	hero.add_theme_stylebox_override("panel", frame)
	if not resized.is_connected(_layout_welcome):
		resized.connect(_layout_welcome)
	_layout_welcome()

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

func _layout_welcome() -> void:
	var stacked := size.x < 740.0 or size.x / maxf(size.y, 1.0) < 0.92
	var body := $ContentScroll/Center/Body as BoxContainer
	var stage := $ContentScroll/Center/Body/Hero/Stage as SubViewportContainer
	var title := $ContentScroll/Center/Body/Copy/Title as Label
	var available := maxf(260.0, minf(size.x - 62.0, 1300.0))
	var compact_header := size.x < 465.0
	Studio.style_label($TopBar/Brand, 19 if compact_header else 28, true)
	$TopBar.offset_left = 8.0 if compact_header else 28.0
	$TopBar.offset_right = -8.0 if compact_header else -28.0
	$TopBar.add_theme_constant_override("separation", 7 if compact_header else 12)
	for button in [btn_settings, btn_mute]:
		button.add_theme_font_size_override("font_size", 14 if compact_header else 17)
	body.vertical = stacked
	body.custom_minimum_size = Vector2(available, 0.0 if stacked else clampf(size.y - 135.0, 400.0, 635.0))
	body.add_theme_constant_override("separation", 22 if stacked else 44)
	stage.custom_minimum_size.y = clampf(available * 0.64, 180.0, 440.0) if stacked else 0.0
	Studio.style_label(title, int(clampf(available * (0.13 if stacked else 0.065), 34, 88)), true)

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


