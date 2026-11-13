extends Control
class_name SetupScreen

## Mode-specific table setup screen (LB-035).
## Configures themes, players, timers, and bag rules before entering the table.

const Packs = preload("res://core/brick_packs.gd")
const Studio = preload("res://client/scripts/menu_studio.gd")

signal start_session_requested(config: Dictionary)
signal online_ready_requested(is_ready: bool)
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
var _default_online_endpoint := ""
var _online_pending := false
var _online_room_code := ""
var _online_ready := false

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
	for button in [btn_start, btn_create_room, btn_join_room, %BtnOnlineReady]:
		Studio.button(button, true)
	Studio.button(%BtnCopyCode)
	Studio.style_label(%OnlineStatus, 15, false, Studio.MUTED)
	Studio.style_label(%OnlineReadyCount, 16, false, Studio.MUTED)
	%LobbyCode.add_theme_color_override("font_uneditable_color", Studio.INK)
	%LobbyCode.add_theme_stylebox_override("read_only", Studio.surface(Color("#fffdf7"), 9))
	for pack_option in [opt_solo_theme, opt_pass_theme]:
		var selected := maxi(pack_option.selected, 0)
		pack_option.clear()
		for label in Packs.LABELS:
			pack_option.add_item(label)
		pack_option.select(selected)
	for option in [opt_solo_theme, opt_solo_mode, opt_player_count, opt_pass_theme, opt_pass_timer]:
		Studio.button(option)
		option.alignment = HORIZONTAL_ALIGNMENT_LEFT
	for field in [line_edit_solo_name, line_player_1, line_player_2, line_player_3, line_player_4, line_online_name, line_online_code, %LineOnlineEndpoint, %LobbyCode]:
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
	if not %BtnCopyCode.pressed.is_connected(_copy_online_code):
		%BtnCopyCode.pressed.connect(_copy_online_code)
	if not %BtnOnlineReady.pressed.is_connected(_on_online_ready_pressed):
		%BtnOnlineReady.pressed.connect(_on_online_ready_pressed)

func _layout_setup() -> void:
	var compact := size.x < 920.0 or size.y < 545.0
	var landscape_form := compact and size.x >= 620.0 and size.x > size.y
	var gutter := 12.0 if compact else 20.0
	var available := maxf(230.0, minf(size.x - 2.0 * gutter - 14.0, 1060.0))
	var split := not compact and available > 780.0 and size.x > size.y
	var form_width := minf(available, 700.0 if landscape_form else 540.0)
	var body := $ContentScroll/CenterWrapper/Body as BoxContainer
	var margin := %MainPanel.get_node("Margin") as MarginContainer
	var form := margin.get_node("VBox") as VBoxContainer
	var fields := container_solo.get_node("Fields") as GridContainer

	$TopBar.offset_left = gutter if compact else 28.0
	$TopBar.offset_right = -gutter if compact else -28.0
	$TopBar.offset_top = 8.0 if compact else 24.0
	$TopBar.offset_bottom = 56.0 if compact else 72.0
	$ContentScroll.offset_left = gutter
	$ContentScroll.offset_right = -gutter
	$ContentScroll.offset_top = 62.0 if compact else 80.0
	$ContentScroll.offset_bottom = -10.0 if compact else -20.0
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 15 if compact else 24)
	form.add_theme_constant_override("separation", 8 if compact else 16)
	fields.columns = 3 if landscape_form else 1
	fields.add_theme_constant_override("v_separation", 8 if compact else 12)
	var player_names := container_pass_play.get_node("PlayerNames") as GridContainer
	player_names.columns = 2 if compact and size.x >= 340.0 else 1
	Studio.style_label(label_mode_title, 32 if compact else 43, true)
	%Preview.visible = split or size.y >= 660.0
	%Stage.custom_minimum_size.y = 465.0 if split else 145.0
	body.vertical = not split
	body.custom_minimum_size.x = available if split else form_width
	%MainPanel.custom_minimum_size.x = 385.0 if split else form_width
	for option in [opt_solo_theme, opt_solo_mode, opt_player_count, opt_pass_theme, opt_pass_timer]:
		var popup: PopupMenu = option.get_popup()
		var font := popup.get_theme_font("font")
		var font_size := popup.get_theme_font_size("font_size")
		var row_gap := maxi(8, ceili(48.0 - font.get_height(font_size)))
		popup.add_theme_constant_override("v_separation", row_gap if compact else 8)

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
			_online_room_code = ""
			_online_ready = false
			%OnlineLobby.hide()
			%OnlineConnect.show()
			_set_online_pending(false)
			_show_online_status("")

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

func configure_online_endpoint(default_endpoint: String) -> void:
	_default_online_endpoint = default_endpoint.strip_edges()
	var has_default := not _default_online_endpoint.is_empty()
	%LabelOnlineEndpoint.text = "Server address (optional)" if has_default else "Server address"
	%LineOnlineEndpoint.placeholder_text = _default_online_endpoint if has_default else "wss://server.example"
	%LineOnlineEndpoint.tooltip_text = "Leave blank to use the default room server" if has_default else "Use the same server address as your friends"

func show_online_pending() -> void:
	_set_online_pending(true)
	_show_online_status("Connecting to the room server…")

func show_online_error(message: String) -> void:
	_set_online_pending(false)
	_show_online_status(message, true)

func show_online_lobby(code: String, players: Array, ready_count: int, is_ready: bool) -> void:
	_online_room_code = code
	_online_ready = is_ready
	_set_online_pending(false)
	%OnlineConnect.hide()
	%OnlineLobby.show()
	%LobbyCode.text = code
	%LabelModeDescription.text = "Share this code with friends. The table opens when everyone is ready."
	%OnlineReadyCount.text = "%d of %d ready" % [ready_count, players.size()]
	%BtnOnlineReady.text = "Cancel ready" if is_ready else "I'm ready"
	_show_online_status("Waiting for another player." if players.size() < 2 else "")

	for row in %OnlineRoster.get_children():
		%OnlineRoster.remove_child(row)
		row.queue_free()
	for player in players:
		if not player is Dictionary:
			continue
		var row := HBoxContainer.new()
		var player_name := Label.new()
		player_name.text = str(player.get("name", "Explorer"))
		player_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		player_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		Studio.style_label(player_name, 17)
		row.add_child(player_name)
		var status := Label.new()
		if not bool(player.get("is_online", true)):
			status.text = "Offline"
		elif bool(player.get("is_ready", false)):
			status.text = "Ready"
		else:
			status.text = "Connected"
		Studio.style_label(status, 15, false, Studio.MUTED)
		row.add_child(status)
		%OnlineRoster.add_child(row)

func _set_online_pending(pending: bool) -> void:
	_online_pending = pending
	btn_create_room.disabled = pending
	btn_join_room.disabled = pending
	%BtnOnlineReady.disabled = pending

func _show_online_status(message: String, is_error: bool = false) -> void:
	%OnlineStatus.text = message
	%OnlineStatus.visible = not message.is_empty()
	%OnlineStatus.add_theme_color_override("font_color", Color("#a1382f") if is_error else Studio.MUTED)

func _copy_online_code() -> void:
	if _online_room_code.is_empty():
		return
	if DisplayServer.has_feature(DisplayServer.FEATURE_CLIPBOARD):
		DisplayServer.clipboard_set(_online_room_code)
		_show_online_status("Room code copied.")
	else:
		%LobbyCode.grab_focus()
		%LobbyCode.select_all()
		_show_online_status("Select Copy on your device.")

func _on_online_ready_pressed() -> void:
	if not _online_pending and not _online_room_code.is_empty():
		online_ready_requested.emit(not _online_ready)

func _on_create_room_pressed() -> void:
	_request_online_room(true)

func _on_join_room_pressed() -> void:
	_request_online_room(false)

func _request_online_room(is_host: bool) -> void:
	if _online_pending or not _online_room_code.is_empty():
		return
	var code := "" if is_host else line_online_code.text.strip_edges().to_upper()
	if not is_host and not _is_room_code_valid(code):
		show_online_error("Enter the 6-character room code from your host.")
		line_online_code.grab_focus()
		return
	var endpoint := String(%LineOnlineEndpoint.text).strip_edges()
	if endpoint.is_empty():
		endpoint = _default_online_endpoint
	if not endpoint.is_empty() and not (endpoint.begins_with("ws://") or endpoint.begins_with("wss://")):
		show_online_error("The server address must start with ws:// or wss://.")
		%LineOnlineEndpoint.grab_focus()
		return
	var player_name := line_online_name.text.strip_edges()
	if player_name.is_empty():
		player_name = "Explorer"
	show_online_pending()
	start_session_requested.emit({
		"mode": "online",
		"theme_id": "harbour",
		"creation_name": "Private room",
		"players": [player_name],
		"player_name": player_name,
		"room_code": code,
		"server_url": endpoint,
		"is_host": is_host,
		"timer_enabled": false
	})

func _is_room_code_valid(code: String) -> bool:
	if code.length() != 6:
		return false
	for character in code:
		if not character in "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789":
			return false
	return true
