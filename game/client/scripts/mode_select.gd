extends Control
class_name ModeSelectScreen

## Mode selection screen (LB-035).
## Displays 3 cards for Solo, Pass & Play, and Online with clear player-facing descriptions.

signal mode_selected(mode: String)
signal back_pressed()

@onready var btn_solo: Button = %BtnSolo
@onready var btn_pass_play: Button = %BtnPassPlay
@onready var btn_online: Button = %BtnOnline
@onready var btn_back: Button = %BtnBack

func _ready() -> void:
	if not btn_solo: btn_solo = find_child("BtnSolo", true, false)
	if not btn_pass_play: btn_pass_play = find_child("BtnPassPlay", true, false)
	if not btn_online: btn_online = find_child("BtnOnline", true, false)
	if not btn_back: btn_back = find_child("BtnBack", true, false)
	
	# Apply craft-table theme tokens (LB-060)
	if btn_back:
		UIThemeHelper.apply_secondary_button(btn_back)
	
	var card_solo = find_child("CardSolo", true, false) as PanelContainer
	if card_solo:
		UIThemeHelper.apply_card(card_solo, UIThemeHelper.COLOR_ACCENT_CORAL)
	var card_pass = find_child("CardPassPlay", true, false) as PanelContainer
	if card_pass:
		UIThemeHelper.apply_card(card_pass, UIThemeHelper.COLOR_ACCENT_SKY)
	var card_online = find_child("CardOnline", true, false) as PanelContainer
	if card_online:
		UIThemeHelper.apply_card(card_online, UIThemeHelper.COLOR_ACCENT_YELLOW)
		
	if btn_solo:
		UIThemeHelper.apply_primary_button(btn_solo)
	if btn_pass_play:
		UIThemeHelper.apply_primary_button(btn_pass_play)
	if btn_online:
		UIThemeHelper.apply_primary_button(btn_online)
	
	if btn_solo and not btn_solo.pressed.is_connected(_on_solo_pressed):
		btn_solo.pressed.connect(_on_solo_pressed)
	if btn_pass_play and not btn_pass_play.pressed.is_connected(_on_pass_play_pressed):
		btn_pass_play.pressed.connect(_on_pass_play_pressed)
	if btn_online and not btn_online.pressed.is_connected(_on_online_pressed):
		btn_online.pressed.connect(_on_online_pressed)
	if btn_back and not btn_back.pressed.is_connected(_on_back_pressed):
		btn_back.pressed.connect(_on_back_pressed)

func _on_solo_pressed() -> void:
	mode_selected.emit("solo")

func _on_pass_play_pressed() -> void:
	mode_selected.emit("pass_and_play")

func _on_online_pressed() -> void:
	mode_selected.emit("online")

func _on_back_pressed() -> void:
	back_pressed.emit()
