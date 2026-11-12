extends Control
class_name SetupScreen

## Mode-specific table setup screen (LB-035).
## Configures themes, players, timers, and bag rules before entering the table.

const Packs = preload("res://core/brick_packs.gd")
const Studio = preload("res://client/scripts/menu_studio.gd")

signal start_session_requested(config: Dictionary)
signal back_pressed()

@onready var btn_back: Button = %BtnBack
@onready var btn_start: Button = %BtnStart
@onready var label_mode_title: Label = %LabelModeTitle

# Solo controls
@onready var container_solo: VBoxContainer = %ContainerSolo
@onready var line_edit_solo_name: LineEdit = %LineEditSoloName
@onready var opt_solo_theme: OptionButton = %OptSoloTheme
@onready var opt_solo_mode: OptionButton = %OptSoloMode

# Pass & Play controls
@onready var container_pass_play: VBoxContainer = %ContainerPassPlay
@onready var opt_player_count: OptionButton = %OptPlayerCount
@onready var line_player_1: LineEdit = %LinePlayer1
@onready var line_player_2: LineEdit = %LinePlayer2
@onready var line_player_3: LineEdit = %LinePlayer3
@onready var line_player_4: LineEdit = %LinePlayer4
@onready var opt_pass_theme: OptionButton = %OptPassTheme
@onready var opt_pass_timer: OptionButton = %OptPassTimer

# Online controls
@onready var container_online: VBoxContainer = %ContainerOnline
@onready var line_online_name: LineEdit = %LineOnlineName
@onready var line_online_code: LineEdit = %LineOnlineCode
@onready var btn_create_room: Button = %BtnCreateRoom
@onready var btn_join_room: Button = %BtnJoinRoom

var current_mode: String = "solo"

func _ensure_nodes() -> void:
	if not btn_back: btn_back = find_child("BtnBack", true, false)
	if not btn_start: btn_start = find_child("BtnStart", true, false)
	if not label_mode_title: label_mode_title = find_child("LabelModeTitle", true, false)
	if not container_solo: container_solo = find_child("ContainerSolo", true, false)
	if not container_pass_play: container_pass_play = find_child("ContainerPassPlay", true, false)
	if not container_online: container_online = find_child("ContainerOnline", true, false)
	if not line_edit_solo_name: line_edit_solo_name = find_child("LineEditSoloName", true, false)
	if not opt_solo_theme: opt_solo_theme = find_child("OptSoloTheme", true, false)
	if not opt_solo_mode: opt_solo_mode = find_child("OptSoloMode", true, false)
	if not opt_player_count: opt_player_count = find_child("OptPlayerCount", true, false)
	if not line_player_1: line_player_1 = find_child("LinePlayer1", true, false)
	if not line_player_2: line_player_2 = find_child("LinePlayer2", true, false)
	if not line_player_3: line_player_3 = find_child("LinePlayer3", true, false)
	if not line_player_4: line_player_4 = find_child("LinePlayer4", true, false)
	if not opt_pass_theme: opt_pass_theme = find_child("OptPassTheme", true, false)
	if not opt_pass_timer: opt_pass_timer = find_child("OptPassTimer", true, false)
	if not line_online_name: line_online_name = find_child("LineOnlineName", true, false)
	if not line_online_code: line_online_code = find_child("LineOnlineCode", true, false)
	if not btn_create_room: btn_create_room = find_child("BtnCreateRoom", true, false)
	if not btn_join_room: btn_join_room = find_child("BtnJoinRoom", true, false)

func _ready() -> void:
	_ensure_nodes()
	
	Studio.apply_theme(self)
	Studio.button(btn_back)
	Studio.style_label(label_mode_title, 43, true)
	Studio.style_label(%LabelModeDescription, 16, false, Studio.MUTED)
	var card := Studio.surface(Studio.PAPER, 16, Studio.BORDER, true)
	card.set_content_margin_all(0.0)
	%MainPanel.add_theme_stylebox_override("panel", card)
	var frame := Studio.surface(Color("#d2c0a2"), 16, Color("#e1d0b6"), true)
	frame.set_content_margin_all(6.0)
	%Preview.add_theme_stylebox_override("panel", frame)
	for button in [btn_start, btn_create_room, btn_join_room]:
		Studio.button(button, true)
	for pack_option in [opt_solo_theme, opt_pass_theme]:
		var selected := maxi(pack_option.selected, 0)
		pack_option.clear()
		for label in Packs.LABELS:
			pack_option.add_item(label)
		pack_option.select(selected)
	for option in [opt_solo_theme, opt_solo_mode, opt_player_count, opt_pass_theme, opt_pass_timer]:
		Studio.button(option)
		option.alignment = HORIZONTAL_ALIGNMENT_LEFT
	for field in [line_edit_solo_name, line_player_1, line_player_2, line_player_3, line_player_4, line_online_name, line_online_code]:
		field.custom_minimum_size.y = 48.0
	if not resized.is_connected(_layout_setup):
		resized.connect(_layout_setup)
	for option in [opt_solo_theme, opt_pass_theme, opt_solo_mode]:
		if not option.item_selected.is_connected(_refresh_preview):
			option.item_selected.connect(_refresh_preview)
	_layout_setup()
	_refresh_preview()

	if btn_back and not btn_back.pressed.is_connected(_on_back_pressed):
		btn_back.pressed.connect(_on_back_pressed)
	if btn_start and not btn_start.pressed.is_connected(_on_start_pressed):
		btn_start.pressed.connect(_on_start_pressed)
	
	if opt_player_count and not opt_player_count.item_selected.is_connected(_on_player_count_changed):
		opt_player_count.item_selected.connect(_on_player_count_changed)
		
	if btn_create_room and not btn_create_room.pressed.is_connected(_on_create_room_pressed):
		btn_create_room.pressed.connect(_on_create_room_pressed)
	if btn_join_room and not btn_join_room.pressed.is_connected(_on_join_room_pressed):
		btn_join_room.pressed.connect(_on_join_room_pressed)

func _layout_setup() -> void:
	var available := maxf(260.0, minf(size.x - 58.0, 1060.0))
	var split := available > 780.0 and size.x / maxf(size.y, 1.0) > 1.0
	var body := $ContentScroll/CenterWrapper/Body as BoxContainer
	body.vertical = not split
	%Preview.visible = split or size.y >= 660.0
	%Stage.custom_minimum_size.y = 465.0 if split else 145.0
	body.custom_minimum_size.x = available if split else minf(available, 540.0)
	%MainPanel.custom_minimum_size.x = 385.0 if split else minf(available, 540.0)

func _refresh_preview(_selection: int = -1) -> void:
	var mode_description := %LabelModeDescription as Label
	match current_mode:
		"solo":
			mode_description.text = "Pick any piece from the collection." if opt_solo_mode.selected == 1 else "Draw from a themed bag and place one piece each turn."
			var pack_id := _selected_pack(opt_solo_theme)
			line_edit_solo_name.placeholder_text = Packs.DISPLAY_NAMES[pack_id]
			%Stage.show_pack_palette(pack_id)
		"pass_and_play":
			mode_description.text = "Pass the device to the next builder after each turn."
			%Stage.show_pack_palette(_selected_pack(opt_pass_theme))
		"online":
			mode_description.text = "Host a table for friends or enter the code they sent."
			%Stage.show_pack_palette("harbour")

func _selected_pack(option: OptionButton) -> String:
	return Packs.IDS[clampi(option.selected, 0, Packs.IDS.size() - 1)]

func _on_back_pressed() -> void:
	back_pressed.emit()

func configure_for_mode(mode: String) -> void:
	_ensure_nodes()
	current_mode = mode
	if container_solo: container_solo.visible = (mode == "solo")
	if container_pass_play: container_pass_play.visible = (mode == "pass_and_play")
	if container_online: container_online.visible = (mode == "online")
	
	match mode:
		"solo":
			if label_mode_title: label_mode_title.text = "Your table"
			if btn_start:
				btn_start.visible = true
				btn_start.text = "Start Building"
		"pass_and_play":
			if label_mode_title: label_mode_title.text = "Set up Pass & Play"
			if btn_start:
				btn_start.visible = true
				btn_start.text = "Start Building"
			_on_player_count_changed(opt_player_count.selected if opt_player_count else 0)
		"online":
			if label_mode_title: label_mode_title.text = "Private room"
			if btn_start: btn_start.visible = false # Uses Create/Join buttons

	_refresh_preview()

func _on_player_count_changed(index: int) -> void:
	var count = index + 2 # 0 -> 2, 1 -> 3, 2 -> 4
	line_player_3.visible = (count >= 3)
	line_player_4.visible = (count >= 4)

func _on_start_pressed() -> void:
	var config: Dictionary = {}
	
	if current_mode == "solo":
		var theme_id := _selected_pack(opt_solo_theme)
		var creation_name = line_edit_solo_name.text.strip_edges()
		if creation_name.is_empty():
			creation_name = Packs.DISPLAY_NAMES[theme_id]
		config = {
			"mode": "solo",
			"theme_id": theme_id,
			"creation_name": creation_name,
			"free_build": (opt_solo_mode.selected == 1),
			"players": ["Builder"],
			"timer_enabled": false
		}
	elif current_mode == "pass_and_play":
		var count = opt_player_count.selected + 2
		var p_names: Array[String] = []
		p_names.append(line_player_1.text if not line_player_1.text.is_empty() else "Player 1")
		p_names.append(line_player_2.text if not line_player_2.text.is_empty() else "Player 2")
		if count >= 3:
			p_names.append(line_player_3.text if not line_player_3.text.is_empty() else "Player 3")
		if count >= 4:
			p_names.append(line_player_4.text if not line_player_4.text.is_empty() else "Player 4")
			
		var theme_id := _selected_pack(opt_pass_theme)
		var timer_enabled = (opt_pass_timer.selected != 3)
		var timer_sec = 20.0
		if opt_pass_timer.selected == 1: timer_sec = 30.0
		elif opt_pass_timer.selected == 2: timer_sec = 45.0
		
		config = {
			"mode": "pass_and_play",
			"theme_id": theme_id,
			"creation_name": "Shared Build",
			"players": p_names,
			"timer_enabled": timer_enabled,
			"timer_sec": timer_sec
		}
		
	start_session_requested.emit(config)

func _generate_room_code() -> String:
	var chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
	var code = ""
	for i in range(6):
		code += chars[randi() % chars.length()]
	return code

func _on_create_room_pressed() -> void:
	var player_name = line_online_name.text.strip_edges()
	if player_name.is_empty():
		player_name = "Explorer1"
	var code = _generate_room_code()
	start_session_requested.emit({
		"mode": "online",
		"theme_id": "harbour",
		"creation_name": "Online Room (%s)" % code,
		"players": [player_name],
		"room_code": code,
		"is_host": true,
		"timer_enabled": false
	})

func _on_join_room_pressed() -> void:
	var player_name = line_online_name.text.strip_edges()
	if player_name.is_empty():
		player_name = "Explorer2"
	var code = line_online_code.text.strip_edges().to_upper()
	if code.is_empty():
		code = "LBRICK"
	start_session_requested.emit({
		"mode": "online",
		"theme_id": "harbour",
		"creation_name": "Online Room (%s)" % code,
		"players": [player_name],
		"room_code": code,
		"is_host": false,
		"timer_enabled": false
	})
