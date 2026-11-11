extends Control
class_name WelcomeScreen

## Welcome screen controller (LB-035).
## Displays game branding, prominent Continue button if recent save exists,
## New Play, My Builds, Settings, and immediate audio mute toggle.

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
	
	_check_for_latest_save()

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

func _on_mute_pressed() -> void:
	is_muted = not is_muted
	btn_mute.text = "🔇 Muted" if is_muted else "🔊 Sound"
	mute_toggled.emit(is_muted)
