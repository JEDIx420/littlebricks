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
	
	Studio.apply_theme(self, true)
	Studio.dark_button(btn_back)
	Studio.style_label($MainLayout/HeadingBox/Subheading, 18, false, Studio.IVORY)
	var cards := %CardsContainer as HFlowContainer
	var accents: Array[Color] = [Studio.PERSIMMON, Studio.GREEN, Studio.COBALT]
	var mode_buttons: Array[Button] = [btn_solo, btn_pass_play, btn_online]
	var badges: Array[Label] = [%BadgeSolo, %BadgePassPlay, %BadgeOnline]
	for index in range(cards.get_child_count()):
		var card := cards.get_child(index) as PanelContainer
		var accent := accents[index]
		var edge := accent.lerp(Studio.BRASS, 0.47)
		var card_face := Studio.surface(Studio.PAPER, 14, edge, true)
		card_face.border_width_bottom = 3
		card.add_theme_stylebox_override("panel", card_face)
		Studio.enter(card, index * 0.045)
		Studio.style_label(card.get_node("CardLayout/VBox/Title"), 30, true)
		Studio.style_label(card.get_node("CardLayout/VBox/Desc"), 17, false, Studio.MUTED)
		Studio.style_label(badges[index], 13, false, accent)
		var button: Button = mode_buttons[index]
		Studio.button(button, true, accent)
		var artwork := card.get_node("CardLayout/Artwork") as Vignette
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
	var compact := size.x < 920.0 or size.y < 545.0
	var columns := 3 if size.x >= (620.0 if compact else 920.0) else 1
	var row_cards := compact and columns == 1
	var gutter := 12.0 if compact else 28.0
	var gap := 10.0 if compact else 18.0
	var available := minf(maxf(230.0, size.x - 2.0 * gutter - 14.0), 1150.0)
	var card_width := minf(available, 520.0) if row_cards else floorf((available - 2.0 * gap) / 3.0)

	$TopBar.offset_left = gutter
	$TopBar.offset_right = -gutter
	$TopBar.offset_top = 8.0 if compact else 24.0
	$TopBar.offset_bottom = 56.0 if compact else 72.0
	$MainLayout.offset_left = gutter
	$MainLayout.offset_right = -gutter
	$MainLayout.offset_top = 60.0 if compact else 80.0
	$MainLayout.offset_bottom = -10.0 if compact else -24.0
	$MainLayout.add_theme_constant_override("separation", 7 if compact else 20)
	Studio.style_label($MainLayout/HeadingBox/Heading, 33 if compact else 58, true, Studio.IVORY)
	$MainLayout/HeadingBox/Subheading.visible = not compact

	cards.add_theme_constant_override("h_separation", int(gap))
	cards.add_theme_constant_override("v_separation", int(gap))
	cards.custom_minimum_size.x = card_width * columns + gap * (columns - 1)
	for card in cards.get_children():
		var layout := card.get_node("CardLayout") as BoxContainer
		var content := layout.get_node("VBox") as VBoxContainer
		var artwork := layout.get_node("Artwork") as Control
		var description := content.get_node("Desc") as Label
		var badge := content.get_child(1) as Label
		var narrow_landscape := compact and columns == 3 and card_width < 232.0
		layout.vertical = not row_cards
		layout.add_theme_constant_override("separation", 9 if compact else 10)
		content.add_theme_constant_override("separation", 4 if compact else 10)
		artwork.custom_minimum_size = Vector2(88, 76) if row_cards else Vector2(0, 96 if compact else 166)
		Studio.style_label(content.get_node("Title"), 22 if compact else 30, true)
		badge.add_theme_font_size_override("font_size", 11 if narrow_landscape else 13)
		description.visible = not compact
		card.custom_minimum_size.x = card_width

func _on_solo_pressed() -> void:
	mode_selected.emit("solo")

func _on_pass_play_pressed() -> void:
	mode_selected.emit("pass_and_play")

func _on_online_pressed() -> void:
	mode_selected.emit("online")

func _on_back_pressed() -> void:
	back_pressed.emit()
