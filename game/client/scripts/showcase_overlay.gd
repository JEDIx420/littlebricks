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

const UI := preload("res://client/scripts/build_presentation_ui.gd")

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
var _mark: UI.BrickMark
var _reveal: Tween
var _arrived: bool = false

func _ready() -> void:
	_ensure_nodes()
	_apply_theme()
	_connect_signals()
	if not resized.is_connected(_layout):
		resized.connect(_layout)
	_layout()

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
	showcase_theme.default_font = UI.BODY_FONT
	showcase_theme.default_font_size = 16
	theme = showcase_theme
	title.add_theme_font_override("font", UI.DISPLAY_FONT)
	title.add_theme_color_override("font_color", UI.INK)
	subtitle.add_theme_color_override("font_color", UI.MUTED)
	label_replay.add_theme_color_override("font_color", UI.COBALT)
	card_panel.add_theme_stylebox_override("panel", UI.panel(17))
	for control in [btn_watch_build, btn_keep_building, btn_replay_restart, btn_close_replay]:
		UI.button(control)
	UI.button(btn_explore, UI.PERSIMMON)
	UI.button(btn_export_video, UI.COBALT)
	for control in [btn_watch_build, btn_keep_building, btn_replay_restart, btn_close_replay, btn_explore, btn_export_video]:
		control.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	progress_bar.add_theme_stylebox_override("background", UI.progress_track(UI.CREAM, UI.BRASS))
	progress_bar.add_theme_stylebox_override("fill", UI.progress_track(UI.COBALT, UI.COBALT))
	if not _mark:
		var holder := find_child("MarkHolder", true, false) as Control
		_mark = UI.BrickMark.new()
		_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(_mark)
		_mark.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _layout() -> void:
	var width := size.x if size.x > 0.0 else 1280.0
	var landscape := width >= 680.0 and width > size.y * 1.45
	var max_card_width := clampf(width * 0.32, 330.0, 410.0) if landscape else 568.0
	var narrow := minf(max_card_width, width - 36.0) < 430.0
	card_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN if landscape else Control.SIZE_SHRINK_CENTER
	card_panel.custom_minimum_size.x = minf(max_card_width, maxf(1.0, width - 36.0))
	title.add_theme_font_size_override("font_size", 26 if narrow else 34)
	btn_close_replay.text = "Back" if card_panel.custom_minimum_size.x < 360.0 else "Back to showcase"
	for control in [btn_watch_build, btn_keep_building, btn_replay_restart, btn_close_replay, btn_explore, btn_export_video]:
		control.add_theme_font_size_override("font_size", 13 if narrow else 15)

func _animate_reveal(replay: bool) -> void:
	if not is_inside_tree() or UI.reduced_motion(self):
		return
	if _reveal:
		_reveal.kill()
	# Keep the build in view. Only the card and its brick mark move.
	card_panel.modulate.a = 0.25
	_mark.rotation = -0.15
	_mark.scale = Vector2.ONE * (0.75 if replay else 0.52)
	_mark.pivot_offset = _mark.size * 0.5
	_reveal = create_tween().set_parallel(true)
	_reveal.tween_property(card_panel, "modulate:a", 1.0, 0.22)
	_reveal.tween_property(_mark, "rotation", 0.0, 0.33).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_reveal.tween_property(_mark, "scale", Vector2.ONE, 0.36).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _set_mark(color: Color) -> void:
	if _mark:
		_mark.tint = color
		_mark.queue_redraw()

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
	if not _arrived:
		_arrived = true
		_animate_reveal(false)

func _show_main_actions() -> void:
	_set_mark(UI.PERSIMMON)
	if actions_box: actions_box.visible = true
	if replay_box: replay_box.visible = false

func _on_explore_clicked() -> void:
	explore_requested.emit()

func _on_watch_build_clicked() -> void:
	if actions_box: actions_box.visible = false
	if replay_box: replay_box.visible = true
	_set_mark(UI.COBALT)
	_animate_reveal(true)
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
	card_panel.modulate.a = 1.0
	card_panel.show()
	label_replay.text = message
	label_replay.tooltip_text = file_path

func update_replay_progress(current_step: int, total_steps: int) -> void:
	if progress_bar:
		progress_bar.max_value = float(total_steps)
		progress_bar.value = float(current_step)
	if current_step == 0:
		_set_mark(UI.COBALT)
	if label_replay:
		label_replay.text = "Brick %d of %d" % [current_step, total_steps]

func notify_replay_finished() -> void:
	_set_mark(UI.DEEP_GREEN)
	if not exporting:
		_animate_reveal(true)
	if label_replay:
		label_replay.text = "Build complete"
