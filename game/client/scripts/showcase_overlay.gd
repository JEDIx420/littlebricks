extends Control
class_name ShowcaseOverlay

## Finished-build showcase and celebration overlay (LB-063).
## Frames creation bounds with warm lighting, congratulatory summary,
## and provides Explore, Watch Build (cinematic replay/export), and Keep Building.

signal explore_requested()
signal keep_building_requested()
signal watch_build_requested()
signal video_export_requested()
signal replay_closed()

const HUD = preload("res://client/scripts/workbench_hud.gd")
const BODY_FONT = preload("res://assets/ui/fonts/DM-Sans.ttf")
const TITLE_FONT = preload("res://assets/ui/fonts/DM-Serif-Text.ttf")

@onready var card_panel: PanelContainer = %CardPanel
@onready var title: Label = %Title
@onready var subtitle: Label = %Subtitle
@onready var actions_box: HBoxContainer = %ActionsBox
@onready var btn_explore: Button = %BtnExplore
@onready var btn_watch_build: Button = %BtnWatchBuild
@onready var btn_keep_building: Button = %BtnKeepBuilding

# Replay mode controls
@onready var replay_box: VBoxContainer = %ReplayBox
@onready var label_replay: Label = %LabelReplay
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var btn_replay_restart: Button = %BtnReplayRestart
@onready var btn_export_video: Button = %BtnExportVideo
@onready var btn_close_replay: Button = %BtnCloseReplay

var creation_name: String = "My Creation"
var total_pieces: int = 0
var timeline: ReplayTimeline
var exporting: bool = false
var export_cancelled: bool = false

func _ready() -> void:
	_ensure_nodes()
	_apply_theme()
	_connect_signals()

func _ensure_nodes() -> void:
	if not card_panel: card_panel = find_child("CardPanel", true, false)
	if not title: title = find_child("Title", true, false)
	if not subtitle: subtitle = find_child("Subtitle", true, false)
	if not actions_box: actions_box = find_child("ActionsBox", true, false)
	if not btn_explore: btn_explore = find_child("BtnExplore", true, false)
	if not btn_watch_build: btn_watch_build = find_child("BtnWatchBuild", true, false)
	if not btn_keep_building: btn_keep_building = find_child("BtnKeepBuilding", true, false)
	if not replay_box: replay_box = find_child("ReplayBox", true, false)
	if not label_replay: label_replay = find_child("LabelReplay", true, false)
	if not progress_bar: progress_bar = find_child("ProgressBar", true, false)
	if not btn_replay_restart: btn_replay_restart = find_child("BtnReplayRestart", true, false)
	if not btn_export_video: btn_export_video = find_child("BtnExportVideo", true, false)
	if not btn_close_replay: btn_close_replay = find_child("BtnCloseReplay", true, false)

func _apply_theme() -> void:
	var showcase_theme := Theme.new()
	showcase_theme.default_font = BODY_FONT
	showcase_theme.default_font_size = 16
	theme = showcase_theme
	title.add_theme_font_override("font", TITLE_FONT)
	title.add_theme_color_override("font_color", HUD.INK)
	subtitle.add_theme_color_override("font_color", HUD.MUTED)
	label_replay.add_theme_color_override("font_color", HUD.INK)
	var panel := HUD.surface(HUD.PANEL, HUD.EDGE, 18)
	panel.shadow_color = Color(0.06, 0.05, 0.04, 0.36)
	panel.shadow_size = 10
	panel.shadow_offset = Vector2(0, 5)
	card_panel.add_theme_stylebox_override("panel", panel)
	for button in [btn_explore, btn_watch_build, btn_keep_building, btn_replay_restart, btn_export_video, btn_close_replay]:
		button.add_theme_stylebox_override("normal", HUD.surface(HUD.BUTTON, HUD.EDGE))
		button.add_theme_stylebox_override("hover", HUD.surface(Color("#4a5146"), HUD.ACTIVE))
		button.add_theme_stylebox_override("pressed", HUD.surface(HUD.ACTIVE, HUD.ACTIVE))
		button.add_theme_stylebox_override("disabled", HUD.surface(HUD.PANEL, HUD.EDGE))
		button.add_theme_color_override("font_color", HUD.INK)
		button.add_theme_color_override("font_hover_color", HUD.INK)
		button.add_theme_color_override("font_pressed_color", HUD.DARK)
		button.add_theme_color_override("font_disabled_color", HUD.MUTED)
	HUD.select(btn_explore, true)
	HUD.select(btn_export_video, true)
	progress_bar.add_theme_stylebox_override("background", HUD.surface(HUD.BUTTON, HUD.EDGE, 4, 0))
	progress_bar.add_theme_stylebox_override("fill", HUD.surface(HUD.ACTIVE, HUD.ACTIVE, 4, 0))

func _connect_signals() -> void:
	if btn_explore and not btn_explore.pressed.is_connected(_on_explore_clicked):
		btn_explore.pressed.connect(_on_explore_clicked)
	if btn_watch_build and not btn_watch_build.pressed.is_connected(_on_watch_build_clicked):
		btn_watch_build.pressed.connect(_on_watch_build_clicked)
	if btn_keep_building and not btn_keep_building.pressed.is_connected(_on_keep_building_clicked):
		btn_keep_building.pressed.connect(_on_keep_building_clicked)
	if btn_replay_restart and not btn_replay_restart.pressed.is_connected(_on_restart_replay_clicked):
		btn_replay_restart.pressed.connect(_on_restart_replay_clicked)
	if btn_export_video and not btn_export_video.pressed.is_connected(_on_export_video_clicked):
		btn_export_video.pressed.connect(_on_export_video_clicked)
	if btn_close_replay and not btn_close_replay.pressed.is_connected(_on_close_replay_clicked):
		btn_close_replay.pressed.connect(_on_close_replay_clicked)

func configure_showcase(p_creation_name: String, piece_count: int) -> void:
	_ensure_nodes()
	creation_name = p_creation_name if not p_creation_name.is_empty() else "Sunny Harbour"
	total_pieces = piece_count
	
	if title:
		title.text = creation_name
		title.tooltip_text = creation_name
	if subtitle:
		subtitle.text = "%d brick%s placed" % [
			total_pieces,
			"" if total_pieces == 1 else "s"
		]
	
	btn_watch_build.disabled = total_pieces == 0
	_show_main_actions()

func _show_main_actions() -> void:
	if actions_box: actions_box.visible = true
	if replay_box: replay_box.visible = false

func _on_explore_clicked() -> void:
	explore_requested.emit()

func _on_watch_build_clicked() -> void:
	if actions_box: actions_box.visible = false
	if replay_box: replay_box.visible = true
	watch_build_requested.emit()

func _on_keep_building_clicked() -> void:
	keep_building_requested.emit()

func _on_restart_replay_clicked() -> void:
	watch_build_requested.emit()

func _on_export_video_clicked() -> void:
	video_export_requested.emit()

func _on_close_replay_clicked() -> void:
	_show_main_actions()
	replay_closed.emit()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if exporting:
		export_cancelled = true
	elif replay_box.visible:
		_on_close_replay_clicked()
	else:
		_on_keep_building_clicked()
	get_viewport().set_input_as_handled()

func begin_export() -> void:
	exporting = true
	export_cancelled = false
	card_panel.hide()

func notify_export_finished(message: String, file_path: String = "") -> void:
	exporting = false
	card_panel.show()
	label_replay.text = message
	label_replay.tooltip_text = file_path

func update_replay_progress(current_step: int, total_steps: int) -> void:
	if progress_bar:
		progress_bar.max_value = float(total_steps)
		progress_bar.value = float(current_step)
	if label_replay:
		label_replay.text = "Brick %d of %d" % [current_step, total_steps]

func notify_replay_finished() -> void:
	if label_replay:
		label_replay.text = "Build complete"
