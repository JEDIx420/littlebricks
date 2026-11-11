extends Control
class_name ShowcaseOverlay

## Finished-build showcase and celebration overlay (LB-063).
## Frames creation bounds with warm lighting, congratulatory summary,
## and provides Explore, Watch Build (cinematic replay/export), and Keep Building.

signal explore_requested()
signal keep_building_requested()
signal watch_build_requested()
signal video_export_requested()

@onready var card_panel: PanelContainer = %CardPanel
@onready var title: Label = %Title
@onready var subtitle: Label = %Subtitle
@onready var actions_box: VBoxContainer = %ActionsBox
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
	if card_panel:
		UIThemeHelper.apply_card(card_panel)
	if btn_explore:
		UIThemeHelper.apply_primary_button(btn_explore)
	if btn_watch_build:
		UIThemeHelper.apply_secondary_button(btn_watch_build)
	if btn_keep_building:
		UIThemeHelper.apply_secondary_button(btn_keep_building)
	if btn_replay_restart:
		UIThemeHelper.apply_secondary_button(btn_replay_restart)
	if btn_export_video:
		UIThemeHelper.apply_primary_button(btn_export_video)
	if btn_close_replay:
		UIThemeHelper.apply_secondary_button(btn_close_replay)

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
		title.text = "Creation Complete!"
	if subtitle:
		subtitle.text = "%s — %d brick%s placed" % [
			creation_name,
			total_pieces,
			"" if total_pieces == 1 else "s"
		]
	
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

func update_replay_progress(current_step: int, total_steps: int) -> void:
	if progress_bar:
		progress_bar.max_value = float(total_steps)
		progress_bar.value = float(current_step)
	if label_replay:
		label_replay.text = "Building piece %d of %d..." % [current_step, total_steps]

func notify_replay_finished() -> void:
	if label_replay:
		label_replay.text = "Replay Complete!"
