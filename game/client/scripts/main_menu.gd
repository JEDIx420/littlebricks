extends Control

## Main menu, game mode selector, save browser, and settings controller (LB-026).

const SettingsManager = preload("res://client/scripts/settings_manager.gd")
const SaveManager = preload("res://core/save_manager.gd")

signal start_solo_game(theme_id: String)
signal start_pass_and_play(player_names: Array[String], theme_id: String)
signal join_online_room(room_code: String, player_name: String)
signal load_saved_game(filepath: String)

@onready var btn_solo: Button = %BtnSolo
@onready var btn_pass_play: Button = %BtnPassPlay
@onready var btn_online: Button = %BtnOnline
@onready var btn_saves: Button = %BtnSaves
@onready var btn_settings: Button = %BtnSettings

@onready var panel_saves: PanelContainer = %PanelSaves
@onready var saves_list_container: VBoxContainer = %SavesListContainer
@onready var btn_close_saves: Button = %BtnCloseSaves

@onready var panel_settings: PanelContainer = %PanelSettings
@onready var check_reduced_motion: CheckBox = %CheckReducedMotion
@onready var check_high_contrast: CheckBox = %CheckHighContrast
@onready var check_sound: CheckBox = %CheckSound
@onready var check_timer: CheckBox = %CheckTimer
@onready var opt_theme: OptionButton = %OptTheme
@onready var btn_close_settings: Button = %BtnCloseSettings

var settings: SettingsManager

func _ready() -> void:
	settings = SettingsManager.new()
	_connect_signals()
	_update_settings_ui()
	panel_saves.visible = false
	panel_settings.visible = false

func _connect_signals() -> void:
	btn_solo.pressed.connect(func(): start_solo_game.emit(settings.preferred_theme))
	btn_pass_play.pressed.connect(func(): start_pass_and_play.emit(["Player 1", "Player 2"], settings.preferred_theme))
	btn_online.pressed.connect(func(): join_online_room.emit("LBRICK", "Explorer1"))
	btn_saves.pressed.connect(_open_saves_browser)
	btn_close_saves.pressed.connect(func(): panel_saves.visible = false)
	btn_settings.pressed.connect(_open_settings)
	btn_close_settings.pressed.connect(_save_and_close_settings)

func _open_saves_browser() -> void:
	panel_saves.visible = true
	for child in saves_list_container.get_children():
		child.queue_free()
		
	var dir = DirAccess.open("user://saves")
	if not dir:
		var lbl = Label.new()
		lbl.text = "No saved creations found."
		saves_list_container.add_child(lbl)
		return
		
	dir.list_dir_begin()
	var filename = dir.get_next()
	var count = 0
	while filename != "":
		if filename.ends_with(".json") and not filename.ends_with(".tmp"):
			count += 1
			var row = HBoxContainer.new()
			var lbl = Label.new()
			lbl.text = filename
			lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var btn_load = Button.new()
			btn_load.text = "Open"
			var full_path = "user://saves/" + filename
			btn_load.pressed.connect(func(): load_saved_game.emit(full_path))
			row.add_child(lbl)
			row.add_child(btn_load)
			saves_list_container.add_child(row)
		filename = dir.get_next()
		
	if count == 0:
		var lbl = Label.new()
		lbl.text = "No saved creations found in user://saves"
		saves_list_container.add_child(lbl)

func _open_settings() -> void:
	_update_settings_ui()
	panel_settings.visible = true

func _update_settings_ui() -> void:
	check_reduced_motion.button_pressed = settings.reduced_motion
	check_high_contrast.button_pressed = settings.high_contrast_cues
	check_sound.button_pressed = settings.sound_enabled
	check_timer.button_pressed = settings.timer_default_enabled
	
	opt_theme.clear()
	opt_theme.add_item("Cozy Coastal Harbour", 0)
	opt_theme.add_item("Rustic Forest Cabin", 1)
	if settings.preferred_theme == "cabin":
		opt_theme.selected = 1
	else:
		opt_theme.selected = 0

func _save_and_close_settings() -> void:
	settings.reduced_motion = check_reduced_motion.button_pressed
	settings.high_contrast_cues = check_high_contrast.button_pressed
	settings.sound_enabled = check_sound.button_pressed
	settings.timer_default_enabled = check_timer.button_pressed
	settings.preferred_theme = "cabin" if opt_theme.selected == 1 else "harbour"
	settings.save_settings()
	panel_settings.visible = false
