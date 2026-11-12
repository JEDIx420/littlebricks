extends Control
class_name ModeSelectScreen

## Mode selection screen (LB-035).
## Displays 3 cards for Solo, Pass & Play, and Online with clear player-facing descriptions.

const Vignette = preload("res://client/scripts/menu_vignette.gd")
const Studio = preload("res://client/scripts/menu_studio.gd")

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
	
	Studio.apply_theme(self)
	Studio.button(btn_back)
	Studio.style_label($MainLayout/HeadingBox/Subheading, 18, false, Studio.MUTED)
	var cards := %CardsContainer as HFlowContainer
	var accents: Array[Color] = [Color("#93452f"), Color("#285648"), Color("#4e5c82")]
	var mode_buttons: Array[Button] = [btn_solo, btn_pass_play, btn_online]
	var badges: Array[Label] = [%BadgeSolo, %BadgePassPlay, %BadgeOnline]
	for index in range(cards.get_child_count()):
		var card := cards.get_child(index) as PanelContainer
		var accent := accents[index]
		var edge := accent.lerp(Studio.PAPER, 0.68)
		card.add_theme_stylebox_override("panel", Studio.surface(Studio.PAPER, 14, edge, true))
		Studio.style_label(card.get_node("VBox/Title"), 30, true)
		Studio.style_label(card.get_node("VBox/Desc"), 17, false, Studio.MUTED)
		Studio.style_label(badges[index], 13, false, accent)
		var button: Button = mode_buttons[index]
		Studio.button(button, true, accent)
		var artwork := card.get_node("VBox/Artwork") as Vignette
		if not button.mouse_entered.is_connected(artwork.set_highlighted.bind(true)):
			button.mouse_entered.connect(artwork.set_highlighted.bind(true))
			button.mouse_exited.connect(artwork.set_highlighted.bind(false))
			button.focus_entered.connect(artwork.set_highlighted.bind(true))
			button.focus_exited.connect(artwork.set_highlighted.bind(false))
	if not resized.is_connected(_layout_cards):
		resized.connect(_layout_cards)
	_layout_cards()

	if btn_solo and not btn_solo.pressed.is_connected(_on_solo_pressed):
		btn_solo.pressed.connect(_on_solo_pressed)
	if btn_pass_play and not btn_pass_play.pressed.is_connected(_on_pass_play_pressed):
		btn_pass_play.pressed.connect(_on_pass_play_pressed)
	if btn_online and not btn_online.pressed.is_connected(_on_online_pressed):
		btn_online.pressed.connect(_on_online_pressed)
	if btn_back and not btn_back.pressed.is_connected(_on_back_pressed):
		btn_back.pressed.connect(_on_back_pressed)

func _layout_cards() -> void:
	var cards := %CardsContainer as HFlowContainer
	var available := maxf(260.0, minf(size.x - 74.0, 1150.0))
	var columns := 3 if available >= 820.0 and size.x / maxf(size.y, 1.0) > 0.92 else 1
	Studio.style_label($MainLayout/HeadingBox/Heading, 55 if columns == 3 else 38, true)
	$MainLayout/HeadingBox/Subheading.visible = columns == 3
	var card_width := minf(available, 550.0) if columns == 1 else floorf((available - 36.0) / 3.0)
	cards.custom_minimum_size.x = card_width * columns + 18.0 * (columns - 1)
	for card in cards.get_children():
		card.custom_minimum_size.x = card_width

func _on_solo_pressed() -> void:
	mode_selected.emit("solo")

func _on_pass_play_pressed() -> void:
	mode_selected.emit("pass_and_play")

func _on_online_pressed() -> void:
	mode_selected.emit("online")

func _on_back_pressed() -> void:
	back_pressed.emit()
