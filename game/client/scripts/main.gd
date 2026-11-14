extends Node3D

## Main scene controller for LittleBricks client.
## Integrates PlacementRules validation, selectable inventory tray,
## canonical stud lattice, surface-following Auto Height, manual height override,
## discoverable camera modes, and robust touch/desktop input ownership.

signal finish_requested()
signal leave_requested()
signal settings_requested()

const WorkshopBlueprint = preload("res://client/scripts/workshop_blueprint.gd")
const BrickPacks = preload("res://core/brick_packs.gd")
const ROOM_MODES: Array[String] = ["cycle", "day", "dusk", "night", "rain"]
const WorkbenchHUD = preload("res://client/scripts/workbench_hud.gd")
const HUD_FONT := preload("res://assets/ui/fonts/DM-Sans.ttf")
const HUD_DISPLAY_FONT := preload("res://assets/ui/fonts/DM-Serif-Text.ttf")
const BrickSurfaceTarget = preload("res://client/scripts/brick_surface_target.gd")
const CameraController = preload("res://client/scripts/camera_controller.gd")
const TableView = preload("res://client/scripts/table_view.gd")
const PartCatalog = preload("res://core/part_catalog.gd")
const PartMeshBuilder = preload("res://core/part_mesh_builder.gd")
const PlacementRules = preload("res://core/placement_rules.gd")
const SessionManager = preload("res://core/session_manager.gd")
const InteractionFeedback = preload("res://client/scripts/interaction_feedback.gd")
const PresentationController = preload("res://client/scripts/presentation_controller.gd")

@onready var camera_rig: CameraController = $CameraRig
@onready var table_view: TableView = $TableView
@onready var ghost_preview: Node3D = $GhostPreview
@onready var placed_bricks_container: Node3D = $PlacedBricks

# UI controls
@onready var label_status: Label = %LabelStatus
@onready var label_coords: Label = %LabelCoords
@onready var color_player_badge: ColorRect = %ColorPlayerBadge
@onready var label_timer: Label = %LabelTimer
@onready var btn_pass_turn: Button = %BtnPassTurn
@onready var btn_undo: Button = %BtnUndo
@onready var btn_redo: Button = %BtnRedo
@onready var btn_all_parts: Button = %BtnAllParts
@onready var catalog_modal: PanelContainer = %CatalogModal
@onready var btn_close_catalog: Button = %BtnCloseCatalog
@onready var opt_catalog_category: OptionButton = %OptCatalogCategory
@onready var opt_catalog_pack: OptionButton = %OptCatalogPack
@onready var line_catalog_search: LineEdit = %LineCatalogSearch
@onready var catalog_grid: GridContainer = %CatalogGrid
@onready var btn_rotate_left: Button = %BtnRotateLeft
@onready var btn_rotate_right: Button = %BtnRotateRight
@onready var btn_auto_height: Button = %BtnAutoHeight
@onready var btn_layer_down: Button = %BtnLayerDown
@onready var btn_layer_up: Button = %BtnLayerUp
@onready var btn_return_base: Button = %BtnReturnBase
@onready var btn_place: Button = %BtnPlace
@onready var btn_cancel: Button = %BtnCancel
@onready var btn_camera_mode: Button = %BtnCameraMode
@onready var btn_top_view: Button = %BtnTopView
@onready var btn_frame_build: Button = %BtnFrameBuild
@onready var btn_reset_view: Button = %BtnResetView
@onready var btn_finish: Button = %BtnFinish
@onready var btn_leave: Button = %BtnLeave
@onready var btn_settings: Button = %BtnSettings
@onready var tray_container: HBoxContainer = %TrayContainer

enum InputState { IDLE, HOLDING, CAMERA_GESTURE, PENDING_ACCEPTANCE, MODAL }
enum TouchAction { NONE, WORLD, PLAN, TRAY, TRAY_BRICK, TRAY_SCROLL, CAMERA }

const TAP_RADIUS := 12.0

var current_input_state: InputState = InputState.HOLDING
var selected_hand_slot: int = 0
var has_valid_target_surface: bool = false

var catalog: PartCatalog
var rules: PlacementRules
var session: SessionManager = null
var audio_director = null
var haptics_adapter = null
var settings_manager = null
var feedback: InteractionFeedback = null
var presentation: PresentationController = null

# State
var current_rotation_step: int = 0 # 0, 1, 2, 3 representing 0, 90, 180, 270 degrees
var current_grid_pos: Vector2i = Vector2i(16, 16)
var current_layer_plate: int = 0 # in plates (0 = on baseplate, 3 = on top of 1st brick, etc.)
var is_auto_height: bool = true
var manual_layer_plate: int = 0
var selected_part_id: String = "brick_2x4"
var selected_color: Color = Color(0.85, 0.15, 0.15) # Classic red brick
var is_current_placement_valid: bool = false
var last_validation_result: Dictionary = {}

var placed_pieces_data: Array = []
var _ghost_node: Node3D = null
var _ghost_material: StandardMaterial3D
var _is_initialized: bool = false
var _last_pointer_screen_pos: Vector2 = Vector2.ZERO
var _mouse_press_position: Vector2 = Vector2.ZERO
var _mouse_placement_armed: bool = false
var _pointer_missed_board: bool = false
var _camera_buttons: Array[Button] = []
var _catalog_part_id: String = ""
var _external_modal_open: bool = false
var _local_placement_sequence: int = 0
var _blueprint: WorkshopBlueprint
var _touch_action: TouchAction = TouchAction.NONE
var _touch_indices: Array[int] = []
var _primary_touch: int = -1
var _touch_origin := Vector2.ZERO
var _touch_moved: bool = false
var _touch_interrupted: bool = false
var _touch_slot: int = -1
var _touch_scroll_origin: int = 0
var _room_picker: OptionButton
var _tray_compact := false

signal online_placement_requested(slot: int, x: int, z: int, layer: int, rotation: int)
signal online_ready_requested(is_ready: bool)

var online_player_id := ""
var online_connected := false
var online_disconnect_message := ""
var online_ready := false

func attach_online_room(code: String, player_id: String) -> void:
	online_player_id = player_id
	online_connected = true
	btn_undo.hide()
	btn_redo.hide()
	btn_pass_turn.hide()
	btn_finish.text = "Ready to explore"
	label_status.text = "Room %s  ·  %s's turn" % [code, session.get_current_player().get("name", "Builder")]
	_validate_and_update_ghost()

func set_online_ready_count(ready_count: int, total_players: int) -> void:
	if ready_count == 0:
		online_ready = false
	var action := "Cancel ready" if online_ready else "Ready to explore"
	btn_finish.text = "%s (%d/%d)" % [action, ready_count, total_players]

func set_online_disconnected(message: String) -> void:
	online_connected = false
	online_disconnect_message = message
	btn_finish.disabled = true
	_validate_and_update_ghost()

func _ready() -> void:
	if _is_initialized:
		return
	_is_initialized = true
	
	if not camera_rig: camera_rig = get_node_or_null("CameraRig")
	if not table_view: table_view = get_node_or_null("TableView")
	if not ghost_preview: ghost_preview = get_node_or_null("GhostPreview")
	if not placed_bricks_container: placed_bricks_container = get_node_or_null("PlacedBricks")
	if not label_status: label_status = find_child("LabelStatus", true, false)
	if not label_coords: label_coords = find_child("LabelCoords", true, false)
	if not color_player_badge: color_player_badge = find_child("ColorPlayerBadge", true, false)
	if not label_timer: label_timer = find_child("LabelTimer", true, false)
	if not btn_pass_turn: btn_pass_turn = find_child("BtnPassTurn", true, false)
	if not btn_undo: btn_undo = find_child("BtnUndo", true, false)
	if not btn_redo: btn_redo = find_child("BtnRedo", true, false)
	if not btn_all_parts: btn_all_parts = find_child("BtnAllParts", true, false)
	if not catalog_modal: catalog_modal = find_child("CatalogModal", true, false)
	if not btn_close_catalog: btn_close_catalog = find_child("BtnCloseCatalog", true, false)
	if not opt_catalog_category: opt_catalog_category = find_child("OptCatalogCategory", true, false)
	if not opt_catalog_pack: opt_catalog_pack = find_child("OptCatalogPack", true, false)
	if not line_catalog_search: line_catalog_search = find_child("LineCatalogSearch", true, false)
	if not catalog_grid: catalog_grid = find_child("CatalogGrid", true, false)
	if not btn_rotate_left: btn_rotate_left = find_child("BtnRotateLeft", true, false)
	if not btn_rotate_right: btn_rotate_right = find_child("BtnRotateRight", true, false)
	if not btn_auto_height: btn_auto_height = find_child("BtnAutoHeight", true, false)
	if not btn_layer_down: btn_layer_down = find_child("BtnLayerDown", true, false)
	if not btn_layer_up: btn_layer_up = find_child("BtnLayerUp", true, false)
	if not btn_return_base: btn_return_base = find_child("BtnReturnBase", true, false)
	if not btn_place: btn_place = find_child("BtnPlace", true, false)
	if not btn_cancel: btn_cancel = find_child("BtnCancel", true, false)
	if not btn_camera_mode: btn_camera_mode = find_child("BtnCameraMode", true, false)
	if not btn_top_view: btn_top_view = find_child("BtnTopView", true, false)
	if not btn_frame_build: btn_frame_build = find_child("BtnFrameBuild", true, false)
	if not btn_reset_view: btn_reset_view = find_child("BtnResetView", true, false)
	if not btn_finish: btn_finish = find_child("BtnFinish", true, false)
	if not btn_leave: btn_leave = find_child("BtnLeave", true, false)
	if not btn_settings: btn_settings = find_child("BtnSettings", true, false)
	if not tray_container: tray_container = find_child("TrayContainer", true, false)
	if camera_rig: camera_rig._ready()
	
	catalog = PartCatalog.new()
	catalog.load_catalog("res://assets/catalog/parts_manifest.json")
	rules = PlacementRules.new(catalog)
	
	WorkbenchHUD.apply($UI/RootControl, HUD_FONT, HUD_DISPLAY_FONT)
	WorkbenchHUD.bind_responsive_layout($UI/RootControl)
	_connect_ui()
	_connect_camera_hud()
	_setup_catalog_packs()
	_connect_workshop_dock()
	_setup_inventory_tray()
	$UI/RootControl.resized.connect(_refresh_tray_layout)
	_update_height_mode_ui()
	_rebuild_ghost()
	_validate_and_update_ghost()

func _process(delta: float) -> void:
	if presentation and settings_manager and presentation.is_reduced_motion != settings_manager.reduced_motion:
		presentation.is_reduced_motion = settings_manager.reduced_motion
	if session and session.timer_enabled and session.phase == SessionManager.SessionPhase.BUILDING:
		session.tick_timer(delta)

func attach_session(p_session: SessionManager, p_audio = null, p_haptics = null, p_settings = null, room_state: Dictionary = {}) -> void:
	session = p_session
	audio_director = p_audio
	haptics_adapter = p_haptics
	settings_manager = p_settings
	
	feedback = InteractionFeedback.new(audio_director, haptics_adapter, settings_manager)
	
	if not presentation:
		presentation = PresentationController.new()
		add_child(presentation)
	
	if session and presentation:
		presentation.is_reduced_motion = settings_manager != null and settings_manager.reduced_motion
		presentation.apply_presentation(session.theme_id, get_node_or_null("WorldEnvironment"), get_node_or_null("DirectionalLight3D"), table_view)
		if not presentation.atmosphere_changed.is_connected(_on_atmosphere_changed):
			presentation.atmosphere_changed.connect(_on_atmosphere_changed)
		if not room_state.is_empty():
			presentation.restore_atmosphere_state(room_state)
		_room_picker.disabled = false
		_on_atmosphere_changed(presentation.get_atmosphere_mode(), presentation.get_atmosphere_label())
		_blueprint.configure(session.theme_id, catalog)
	
	if not session:
		return
		
	# Connect session signals
	if not session.placement_accepted.is_connected(_on_placement_accepted):
		session.placement_accepted.connect(_on_placement_accepted)
	if not session.placement_rejected.is_connected(_on_placement_rejected):
		session.placement_rejected.connect(_on_placement_rejected)
	if not session.turn_advanced.is_connected(_on_turn_advanced):
		session.turn_advanced.connect(_on_turn_advanced)
	if not session.timer_ticked.is_connected(_on_timer_ticked):
		session.timer_ticked.connect(_on_timer_ticked)
	if not session.timer_expired.is_connected(_on_timer_expired):
		session.timer_expired.connect(_on_timer_expired)
	if not session.inventory_refilled.is_connected(_on_inventory_refilled):
		session.inventory_refilled.connect(_on_inventory_refilled)
	if not session.ready_status_changed.is_connected(_on_ready_status_changed):
		session.ready_status_changed.connect(_on_ready_status_changed)
	if not session.phase_changed.is_connected(_on_session_phase_changed):
		session.phase_changed.connect(_on_session_phase_changed)
		
	if label_timer:
		label_timer.visible = session.timer_enabled
	if btn_pass_turn:
		btn_pass_turn.visible = session.players.size() > 1

		
	var cur_player = session.get_current_player()
	var starting_hand: Array = cur_player.get("hand", [])
	if not starting_hand.is_empty():
		selected_hand_slot = 0
		selected_part_id = starting_hand[0].get("part_id", "brick_2x4")
		selected_color = starting_hand[0].get("color", selected_color)
		_rebuild_ghost()
	var p_num = session.current_player_idx + 1
	if color_player_badge and not cur_player.is_empty():
		color_player_badge.color = cur_player.get("color", Color.WHITE)
	if label_status and not cur_player.is_empty():
		label_status.text = "Turn: [P%d] %s" % [p_num, cur_player.get("name", "Player")]
		
	# Reconstruct existing placements from session
	placed_pieces_data.clear()
	if not placed_bricks_container:
		placed_bricks_container = get_node_or_null("PlacedBricks")
	if placed_bricks_container:
		for child in placed_bricks_container.get_children():
			child.queue_free()
			
		for p in session.placements:
			var pid = p.get("part_id", "brick_2x4")
			var col = p.get("color", Color.WHITE)
			var p_def = catalog.get_part(pid)
			var dims = p_def.get("dimensions_studs", [1, 3, 1])
			var rot = p.get("rotation_step", 0)
			var node = PartMeshBuilder.build_part_node(p_def, col)
			node.position = TableView.grid_to_world(p.get("grid_x", 0), p.get("grid_z", 0), p.get("layer_plate", 0), dims, rot)
			node.rotation_degrees = PlacementRules.get_rotation_degrees(rot)
			placed_bricks_container.add_child(node)
			placed_pieces_data.append(p)
		
	_setup_inventory_tray()
	_update_brick_count()
	_update_pointer_target()
	_validate_and_update_ghost()

func _connect_ui() -> void:
	if btn_rotate_left and not btn_rotate_left.pressed.is_connected(_on_rotate_left):
		btn_rotate_left.pressed.connect(_on_rotate_left)
	if btn_rotate_right and not btn_rotate_right.pressed.is_connected(_on_rotate_right):
		btn_rotate_right.pressed.connect(_on_rotate_right)
	if btn_auto_height and not btn_auto_height.pressed.is_connected(_toggle_auto_height):
		btn_auto_height.pressed.connect(_toggle_auto_height)
	if btn_layer_down and not btn_layer_down.pressed.is_connected(func(): _bump_layer(-1)):
		btn_layer_down.pressed.connect(func(): _bump_layer(-1))
	if btn_layer_up and not btn_layer_up.pressed.is_connected(func(): _bump_layer(1)):
		btn_layer_up.pressed.connect(func(): _bump_layer(1))
	if btn_return_base and not btn_return_base.pressed.is_connected(_return_to_base):
		btn_return_base.pressed.connect(_return_to_base)
	if btn_place and not btn_place.pressed.is_connected(_on_place_pressed):
		btn_place.pressed.connect(_on_place_pressed)
	if btn_cancel and not btn_cancel.pressed.is_connected(_on_cancel_held_piece):
		btn_cancel.pressed.connect(_on_cancel_held_piece)
	if btn_camera_mode:
		btn_camera_mode.pressed.connect(_set_camera_mode.bind(CameraController.InteractionMode.BUILD))
	if camera_rig and not camera_rig.mode_changed.is_connected(_on_camera_mode_changed):
		camera_rig.mode_changed.connect(_on_camera_mode_changed)
	if btn_top_view and camera_rig and not btn_top_view.pressed.is_connected(camera_rig.set_top_view):
		btn_top_view.pressed.connect(camera_rig.set_top_view)
	if btn_frame_build and not btn_frame_build.pressed.is_connected(camera_rig.frame_plate):
		btn_frame_build.pressed.connect(camera_rig.frame_plate)
	if btn_reset_view and camera_rig and not btn_reset_view.pressed.is_connected(camera_rig.set_default_view):
		btn_reset_view.pressed.connect(camera_rig.set_default_view)
	if btn_undo and not btn_undo.pressed.is_connected(_on_undo_pressed):
		btn_undo.pressed.connect(_on_undo_pressed)
	if btn_redo and not btn_redo.pressed.is_connected(_on_redo_pressed):
		btn_redo.pressed.connect(_on_redo_pressed)
	if btn_pass_turn and not btn_pass_turn.pressed.is_connected(_on_pass_turn_pressed):
		btn_pass_turn.pressed.connect(_on_pass_turn_pressed)
	if btn_all_parts and not btn_all_parts.pressed.is_connected(_toggle_catalog_modal):
		btn_all_parts.pressed.connect(_toggle_catalog_modal)
	catalog_modal.find_child("BtnPickPart").pressed.connect(_pick_catalog_part)
	if btn_close_catalog and not btn_close_catalog.pressed.is_connected(_close_catalog_modal):
		btn_close_catalog.pressed.connect(_close_catalog_modal)
	if opt_catalog_category and not opt_catalog_category.item_selected.is_connected(func(_i): _populate_catalog_grid()):
		opt_catalog_category.item_selected.connect(func(_i): _populate_catalog_grid())
	if line_catalog_search and not line_catalog_search.text_changed.is_connected(func(_t): _populate_catalog_grid()):
		line_catalog_search.text_changed.connect(func(_t): _populate_catalog_grid())
	if btn_finish and not btn_finish.pressed.is_connected(_on_finish_pressed):
		btn_finish.pressed.connect(_on_finish_pressed)
	if btn_leave and not btn_leave.pressed.is_connected(func(): leave_requested.emit()):
		btn_leave.pressed.connect(func(): leave_requested.emit())
	if btn_settings and not btn_settings.pressed.is_connected(func(): settings_requested.emit()):
		btn_settings.pressed.connect(func(): settings_requested.emit())

func _setup_inventory_tray() -> void:
	if not tray_container:
		return
	var scroll := tray_container.get_parent() as ScrollContainer
	var scroll_offset: int = scroll.scroll_horizontal
	_tray_compact = $UI/RootControl.get_meta("compact_hud", false)
		
	var pieces_to_show = []
	if session and session.players.size() > 0:
		var cur_player = session.get_current_player()
		pieces_to_show = cur_player.get("hand", [])
		var p_num = session.current_player_idx + 1
		if label_status:
			label_status.text = "Turn: [P%d] %s" % [p_num, cur_player.get("name", "Player")]
		if color_player_badge:
			color_player_badge.color = cur_player.get("color", Color.WHITE)
	
	if pieces_to_show.is_empty():
		pieces_to_show = [
			{"part_id": "brick_2x4", "name": "2x4 Brick", "color": Color(0.85, 0.15, 0.15)},
			{"part_id": "brick_2x2", "name": "2x2 Brick", "color": Color(0.15, 0.35, 0.85)},
			{"part_id": "brick_1x4", "name": "1x4 Brick", "color": Color(0.9, 0.75, 0.1)},
			{"part_id": "brick_1x2", "name": "1x2 Brick", "color": Color(0.92, 0.92, 0.92)},
			{"part_id": "plate_2x4", "name": "2x4 Plate", "color": Color(0.15, 0.65, 0.25)},
			{"part_id": "arch_1x4",  "name": "1x4 Arch",  "color": Color(0.3, 0.3, 0.35)}
		]
	
	while tray_container.get_child_count() > pieces_to_show.size():
		var extra := tray_container.get_child(tray_container.get_child_count() - 1)
		tray_container.remove_child(extra)
		extra.queue_free()
	for i in range(pieces_to_show.size()):
		var piece = pieces_to_show[i]
		var pid: String = piece.get("part_id", piece.get("id", "brick_2x4"))
		var pcolor: Color = piece.get("color", Color(0.85, 0.15, 0.15))
		var btn := tray_container.get_child(i) as Button if i < tray_container.get_child_count() else null
		if btn and btn.get_meta("tray_part_id") == pid and btn.get_meta("tray_part_color") == pcolor:
			continue
		if btn:
			tray_container.remove_child(btn)
			btn.queue_free()
		btn = Button.new()
		var part: Dictionary = catalog.get_part(pid)
		var pname: String = part.get("name", pid)
		btn.text = pname
		btn.tooltip_text = "%s  ·  %d" % [pname, i + 1]
		btn.focus_mode = Control.FOCUS_CLICK
		btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		btn.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		btn.add_theme_font_size_override("font_size", 12)
		if not part.is_empty():
			WorkbenchHUD.add_part_preview(btn, part, pcolor)

		btn.set_meta("tray_part_id", pid)
		btn.set_meta("tray_part_color", pcolor)
		btn.pressed.connect(_pick_tray_button.bind(btn))
		tray_container.add_child(btn)
		tray_container.move_child(btn, i)
	_refresh_tray_selection()
	# Containers update their scroll range after laying out the tray.
	if scroll_offset > 0:
		scroll.set_deferred("scroll_horizontal", scroll_offset)

func _refresh_tray_layout() -> void:
	var compact: bool = $UI/RootControl.get_meta("compact_hud", false)
	if compact != _tray_compact:
		_tray_compact = compact
		_refresh_tray_selection()

func _refresh_tray_selection(animate: bool = false) -> void:
	for slot in tray_container.get_children():
		var selected := slot.get_index() == selected_hand_slot
		var style_state := Vector2i(int(_tray_compact), int(selected))
		if slot.get_meta("tray_style", Vector2i(-1, -1)) != style_state:
			slot.custom_minimum_size = Vector2(88, 64 if _tray_compact else 68)
			slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER if _tray_compact else Control.SIZE_FILL
			WorkbenchHUD.style_tray_slot(slot, _tray_compact, selected)
			slot.set_meta("tray_style", style_state)
		if animate and selected:
			var preview := slot.get_node_or_null("BrickPreview") as TextureRect
			if preview:
				WorkbenchHUD.pulse(preview, _hud_reduced_motion(), 0.83)

func _hud_reduced_motion() -> bool:
	if settings_manager:
		return settings_manager.reduced_motion
	return is_inside_tree() and get_tree().get_meta("littlebricks_reduced_motion", false)

func _update_brick_count(animate: bool = false) -> void:
	var count := placed_pieces_data.size()
	var badge := get_node_or_null("%BrickCount") as Label
	if not badge:
		return
	badge.text = "1 brick" if count == 1 else "%d bricks" % count
	if animate:
		WorkbenchHUD.pulse(badge, _hud_reduced_motion(), 1.14, Color("#ffde8d"))

func _pick_tray_button(button: Button) -> void:
	if current_input_state == InputState.PENDING_ACCEPTANCE:
		return
	_select_piece_from_slot(button.get_index(), button.get_meta("tray_part_id"), button.get_meta("tray_part_color"))
	_refresh_tray_selection(true)

func _select_slot_by_index(slot_idx: int) -> void:
	var hand: Array = []
	if session and session.players.size() > 0:
		hand = session.get_current_player().get("hand", [])
	if slot_idx >= 0 and slot_idx < hand.size():
		var piece = hand[slot_idx]
		_select_piece_from_slot(slot_idx, piece.get("part_id", "brick_2x4"), piece.get("color", Color(0.85, 0.15, 0.15)))
		_refresh_tray_selection(true)

func _select_piece_from_slot(slot_idx: int, part_id: String, color: Color) -> void:
	selected_hand_slot = slot_idx
	_select_piece(part_id, color)

func _select_piece(part_id: String, color: Color) -> void:
	_set_camera_mode(CameraController.InteractionMode.BUILD)
	current_input_state = InputState.HOLDING
	selected_part_id = part_id
	selected_color = color
	if feedback:
		feedback.notify_piece_selected(part_id, color)
	else:
		if audio_director:
			audio_director.play_pickup()
		if haptics_adapter:
			haptics_adapter.vibrate_light()
	_rebuild_ghost()
	_update_pointer_target()
	_validate_and_update_ghost()

func _rebuild_ghost() -> void:
	if _ghost_node:
		_ghost_node.queue_free()
		_ghost_node = null
		
	var p_def: Dictionary = catalog.get_part(selected_part_id)
	if p_def.is_empty():
		return
		
	_ghost_node = PartMeshBuilder.build_part_node(p_def, selected_color)
	ghost_preview.add_child(_ghost_node)
	_ghost_material = StandardMaterial3D.new()
	_ghost_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ghost_material.roughness = 0.42
	_set_ghost_material(_ghost_node)
	btn_place.tooltip_text = "Place %s (Enter)" % p_def.get("name", "brick")

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_clear_touch_sequence()

func _input(event: InputEvent) -> void:
	if not _is_initialized or not camera_rig:
		return
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		if event.device == InputEvent.DEVICE_ID_EMULATION and not _touch_modal_open():
			# Godot emits mouse compatibility input around real touch input.
			# Native touch owns tray pockets, while other controls keep their
			# regular button events. A world release over the HUD belongs to
			# the same touch sequence that started over the table.
			var over_tray := _tray_slot_at(event.position) >= 0
			var over_world := not _touch_over_hud(event.position)
			if over_tray or over_world or _touch_action != TouchAction.NONE:
				_consume_input()
		return
	if event is InputEventScreenTouch and event.device != InputEvent.DEVICE_ID_EMULATION:
		_route_touch(event)
	elif event is InputEventScreenDrag and event.device != InputEvent.DEVICE_ID_EMULATION:
		_route_touch_drag(event)

func _touch_modal_open() -> bool:
	return _external_modal_open or catalog_modal.visible

func _route_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if event.index in _touch_indices:
			return
		_touch_indices.append(event.index)
		if _touch_modal_open():
			return
		_begin_touch(event)
		if _touch_action != TouchAction.NONE:
			_consume_input()
		return

	var had_owner: bool = _touch_action != TouchAction.NONE
	_touch_indices.erase(event.index)
	camera_rig.release_world_touch(event.index)
	if event.index == _primary_touch:
		_end_touch(event)
	if _touch_indices.is_empty():
		_clear_touch_sequence()
	if had_owner:
		_consume_input()

func _begin_touch(event: InputEventScreenTouch) -> void:
	_mouse_placement_armed = false
	if _touch_indices.size() > 1:
		if not _touch_over_hud(event.position) and (_touch_action == TouchAction.WORLD or _touch_action == TouchAction.PLAN or _touch_action == TouchAction.CAMERA):
			camera_rig.press_world_touch(event.index, event.position)
			_touch_action = TouchAction.CAMERA
		elif _touch_action != TouchAction.NONE and _touch_action != TouchAction.CAMERA:
			# A second finger cancels the pending drop. Camera gestures
			# are available when both touches start on the table.
			_touch_interrupted = true
		return

	_primary_touch = event.index
	_touch_origin = event.position
	_touch_moved = false
	_touch_interrupted = false
	_touch_slot = _tray_slot_at(event.position)
	if _touch_slot >= 0:
		_touch_action = TouchAction.TRAY
		var scroll := tray_container.get_parent() as ScrollContainer
		_touch_scroll_origin = scroll.scroll_horizontal
	elif not _touch_over_hud(event.position):
		camera_rig.press_world_touch(event.index, event.position)
		if camera_rig.is_camera_mode:
			_touch_action = TouchAction.CAMERA
		elif _blueprint.is_under_pointer(camera_rig.camera, event.position):
			_touch_action = TouchAction.PLAN
		else:
			_touch_action = TouchAction.WORLD
			_aim_touch(event.position)

func _route_touch_drag(event: InputEventScreenDrag) -> void:
	if _touch_modal_open() or event.index not in _touch_indices or _touch_action == TouchAction.NONE:
		return
	if _touch_action == TouchAction.CAMERA:
		camera_rig.drag_world_touch(event.index, event.position)
		_consume_input()
		return
	if event.index != _primary_touch or _touch_interrupted or _touch_indices.size() > 1:
		_consume_input()
		return
	if _touch_action == TouchAction.WORLD or _touch_action == TouchAction.PLAN:
		camera_rig.drag_world_touch(event.index, event.position)
	var delta: Vector2 = event.position - _touch_origin
	_touch_moved = _touch_moved or delta.length_squared() > TAP_RADIUS * TAP_RADIUS
	match _touch_action:
		TouchAction.TRAY, TouchAction.TRAY_SCROLL:
			_drag_from_tray(event.position, delta)
		TouchAction.WORLD, TouchAction.TRAY_BRICK:
			if not _touch_over_hud(event.position):
				_aim_touch(event.position)
	_consume_input()

func _drag_from_tray(position: Vector2, delta: Vector2) -> void:
	if _touch_slot < 0:
		return
	var scroll := tray_container.get_parent() as ScrollContainer
	var drag_started: bool = delta.y < -TAP_RADIUS and position.y < scroll.get_global_rect().position.y
	if _touch_action == TouchAction.TRAY and drag_started:
		_touch_action = TouchAction.TRAY_BRICK
		_pick_tray_button(tray_container.get_child(_touch_slot) as Button)
		if not _touch_over_hud(position):
			_aim_touch(position)
	elif _touch_action == TouchAction.TRAY_SCROLL or (absf(delta.x) >= TAP_RADIUS and absf(delta.x) > absf(delta.y)):
		_touch_action = TouchAction.TRAY_SCROLL
		scroll.scroll_horizontal = _touch_scroll_origin - roundi(delta.x)

func _end_touch(event: InputEventScreenTouch) -> void:
	_primary_touch = -1
	if event.canceled or _touch_interrupted or _touch_modal_open() or not _touch_indices.is_empty():
		return
	var is_tap: bool = not _touch_moved and event.position.distance_squared_to(_touch_origin) <= TAP_RADIUS * TAP_RADIUS
	match _touch_action:
		TouchAction.TRAY:
			if is_tap and _touch_slot >= 0 and _tray_slot_at(event.position) == _touch_slot:
				_pick_tray_button(tray_container.get_child(_touch_slot) as Button)
		TouchAction.PLAN:
			if is_tap and not _touch_over_hud(event.position) and _blueprint.is_under_pointer(camera_rig.camera, event.position):
				_open_blueprint()
		TouchAction.WORLD, TouchAction.TRAY_BRICK:
			if _touch_over_hud(event.position):
				return
			_aim_touch(event.position)
			if has_valid_target_surface and (is_tap or _touch_action == TouchAction.TRAY_BRICK):
				_on_place_pressed()

func _aim_touch(position: Vector2) -> void:
	_last_pointer_screen_pos = position
	_handle_pointer_position(position)

func _tray_slot_at(position: Vector2) -> int:
	var scroll := tray_container.get_parent() as ScrollContainer
	if not scroll.is_visible_in_tree() or not scroll.get_global_rect().has_point(position):
		return -1
	for child in tray_container.get_children():
		if child is Button and child.is_visible_in_tree() and child.get_global_rect().has_point(position):
			return child.get_index()
	return -1

func _touch_over_hud(position: Vector2) -> bool:
	for control in $UI/RootControl.get_children():
		if control is Control and control.is_visible_in_tree() and control.mouse_filter != Control.MOUSE_FILTER_IGNORE and control.get_global_rect().has_point(position):
			return true
	return false

func _clear_touch_sequence() -> void:
	_touch_action = TouchAction.NONE
	_primary_touch = -1
	_touch_slot = -1
	_touch_indices.clear()

func _unhandled_input(event: InputEvent) -> void:
	if _external_modal_open:
		return
	# If catalog modal is open, prevent all world interaction
	if catalog_modal and catalog_modal.visible:
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			_close_catalog_modal()
			_consume_input()
		return

	# Handle cancel / escape key (LB-058)
	if event is InputEventKey and event.pressed and (event.keycode == KEY_ESCAPE or event.is_action_pressed("ui_cancel")):
		_on_cancel_held_piece()
		_consume_input()
		return

	# Safe input handling: UI controls consume events first so clicking
	# tray or buttons never accidentally places a brick or moves ghost (PC-07).
	
	if event.is_action_pressed("rotate_left"):
		_on_rotate_left()
		_consume_input()
		return
	elif event.is_action_pressed("rotate_right"):
		_on_rotate_right()
		_consume_input()
		return
	elif event.is_action_pressed("place"):
		_on_place_pressed()
		_consume_input()
		return
		
	# Keyboard shortcuts
	if event is InputEventKey and event.pressed:
		var k = event.keycode
		if k == KEY_EQUAL or k == KEY_KP_ADD:
			_bump_layer(1)
			_consume_input()
			return
		elif k == KEY_MINUS or k == KEY_KP_SUBTRACT:
			_bump_layer(-1)
			_consume_input()
			return
		elif k == KEY_B or k == KEY_0:
			_return_to_base()
			_consume_input()
			return
		elif k == KEY_J:
			_open_blueprint()
			_consume_input()
			return
		elif k == KEY_M:
			_toggle_auto_height()
			_consume_input()
			return
		elif k == KEY_C:
			_toggle_camera_mode()
			_consume_input()
			return
		elif k == KEY_T:
			camera_rig.set_top_view()
			_consume_input()
			return
		elif k == KEY_F:
			camera_rig.frame_plate()
			_consume_input()
			return
		elif k == KEY_SPACE:
			camera_rig.set_default_view()
			_consume_input()
			return
		elif k == KEY_Z:
			_on_undo_pressed()
			_consume_input()
			return
		elif k == KEY_Y:
			_on_redo_pressed()
			_consume_input()
			return
		elif k == KEY_P:
			_on_pass_turn_pressed()
			_consume_input()
			return
		elif k >= KEY_1 and k <= KEY_6:
			var slot_idx: int = k - KEY_1
			_select_slot_by_index(slot_idx)
			_consume_input()
			return
		elif k == KEY_F3:
			if label_coords:
				label_coords.visible = not label_coords.visible
			_consume_input()
			return

	# Mouse clicks commit once on release. A left drag only aims.
	var is_cam_busy := camera_rig.is_camera_mode or camera_rig.is_gesture_active
	if is_cam_busy:
		_mouse_placement_armed = false
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.device == InputEvent.DEVICE_ID_EMULATION:
			return
		if event.pressed:
			_mouse_press_position = event.position
			_mouse_placement_armed = current_input_state == InputState.HOLDING or _blueprint.is_under_pointer(camera_rig.camera, event.position)
		elif _mouse_placement_armed and event.position.distance_to(_mouse_press_position) <= 7.0:
			_mouse_placement_armed = false
			if _blueprint.is_under_pointer(camera_rig.camera, _mouse_press_position) and _blueprint.is_under_pointer(camera_rig.camera, event.position):
				_open_blueprint()
				_consume_input()
				return
			_last_pointer_screen_pos = event.position
			_handle_pointer_position(event.position)
			if is_current_placement_valid:
				_on_place_pressed()
		else:
			_mouse_placement_armed = false
		_consume_input()
	elif event is InputEventMouseMotion:
		if event.device == InputEvent.DEVICE_ID_EMULATION:
			return
		if _mouse_placement_armed and event.position.distance_to(_mouse_press_position) > 7.0:
			_mouse_placement_armed = false
		_last_pointer_screen_pos = event.position
		if _blueprint.is_under_pointer(camera_rig.camera, event.position):
			_invalidate_candidate()
			label_status.text = "Click to read the build plan"
		else:
			_handle_pointer_position(event.position)

func _consume_input() -> void:
	if get_viewport():
		get_viewport().set_input_as_handled()

func set_layer(layer_plate: int) -> void:
	# Explicitly set layer (switches to Manual mode)
	is_auto_height = false
	manual_layer_plate = clampi(layer_plate, 0, PlacementRules.MAX_LAYER_PLATES)
	current_layer_plate = manual_layer_plate
	_update_height_mode_ui()
	_validate_and_update_ghost()

func _toggle_auto_height() -> void:
	is_auto_height = not is_auto_height
	if not is_auto_height:
		manual_layer_plate = current_layer_plate
	_update_height_mode_ui()
	_update_pointer_target()
	_validate_and_update_ghost()

func _bump_layer(delta: int) -> void:
	# Bumping layer explicitly locks into Manual mode
	is_auto_height = false
	manual_layer_plate = clampi(current_layer_plate + delta, 0, PlacementRules.MAX_LAYER_PLATES)
	current_layer_plate = manual_layer_plate
	_update_height_mode_ui()
	_update_pointer_target()
	_validate_and_update_ghost()

func _return_to_base() -> void:
	# Returning to baseplate clears any manual lock and restores Auto Height (PC-03)
	is_auto_height = true
	manual_layer_plate = 0
	current_layer_plate = 0
	_update_height_mode_ui()
	_update_pointer_target()
	_validate_and_update_ghost()

func _toggle_camera_mode() -> void:
	if camera_rig:
		camera_rig.cycle_camera_mode()

func _connect_workshop_dock() -> void:
	var ui := $UI/RootControl
	_room_picker = ui.find_child("OptRoom") as OptionButton
	for label in ["Auto cycle", "Daylight", "Dusk", "Night", "Rain"]:
		_room_picker.add_item(label)
	_room_picker.select(0)
	_room_picker.text = "Room"
	_room_picker.disabled = true
	_room_picker.item_selected.connect(func(index: int):
		if presentation:
			presentation.set_atmosphere_mode(ROOM_MODES[index])
	)

	_blueprint = WorkshopBlueprint.new()
	table_view.add_child(_blueprint)
	_blueprint.reader_closed.connect(set_external_modal_open.bind(false))
	ui.find_child("BtnPlans").pressed.connect(_open_blueprint)

func _open_blueprint() -> void:
	if _external_modal_open or catalog_modal.visible or not session:
		return
	set_external_modal_open(true)
	_blueprint.show_reader($UI/RootControl)

func get_workshop_state() -> Dictionary:
	return presentation.get_atmosphere_state() if presentation else {}

func _on_atmosphere_changed(mode: String, label: String) -> void:
	var index := ROOM_MODES.find(mode)
	if index >= 0:
		_room_picker.select(index)
	_room_picker.text = label
	var state := presentation.get_atmosphere_state()
	if audio_director:
		audio_director.set_workshop_atmosphere(state.get("is_raining", false), state.get("is_night", false))

func _connect_camera_hud() -> void:
	var ui := $UI/RootControl
	var camera_panel := ui.get_node("CameraPanel") as PanelContainer
	var view_button := ui.find_child("BtnCameraDock") as Button
	view_button.pressed.connect(func():
		camera_panel.visible = not camera_panel.visible
		WorkbenchHUD.select(view_button, camera_panel.visible)
	)

	_camera_buttons = [
		btn_camera_mode, ui.find_child("BtnOrbitMode"), ui.find_child("BtnPanMode"),
	]
	_camera_buttons[1].pressed.connect(_set_camera_mode.bind(CameraController.InteractionMode.ORBIT))
	_camera_buttons[2].pressed.connect(_set_camera_mode.bind(CameraController.InteractionMode.PAN))
	ui.find_child("BtnOrbitLeft").pressed.connect(camera_rig.orbit_by.bind(30.0, 0.0))
	ui.find_child("BtnOrbitRight").pressed.connect(camera_rig.orbit_by.bind(-30.0, 0.0))
	ui.find_child("BtnOrbitUp").pressed.connect(camera_rig.orbit_by.bind(0.0, -12.0))
	ui.find_child("BtnOrbitDown").pressed.connect(camera_rig.orbit_by.bind(0.0, 12.0))
	ui.find_child("BtnZoomOut").pressed.connect(camera_rig.zoom_by.bind(3.0))
	ui.find_child("BtnZoomIn").pressed.connect(camera_rig.zoom_by.bind(-3.0))
	_on_camera_mode_changed(camera_rig.interaction_mode, camera_rig.get_mode_name())

func _set_camera_mode(mode: CameraController.InteractionMode) -> void:
	if camera_rig and camera_rig.interaction_mode != mode:
		camera_rig.reset_gesture_state()
		camera_rig.interaction_mode = mode

func _on_camera_mode_changed(mode: int, mode_name: String) -> void:
	for i in range(_camera_buttons.size()):
		WorkbenchHUD.select(_camera_buttons[i], i == mode)
	var view_button := $UI/RootControl.find_child("BtnCameraDock") as Button
	view_button.text = "View" if mode == CameraController.InteractionMode.BUILD else mode_name
	var hint := $UI/RootControl.find_child("CameraHint") as Label
	match mode:
		CameraController.InteractionMode.BUILD:
			hint.text = "Right-drag · Scroll"
			if label_status:
				label_status.text = "Aim a brick at the plate"
		CameraController.InteractionMode.ORBIT:
			hint.text = "Drag to turn the view"
		CameraController.InteractionMode.PAN:
			hint.text = "Drag to slide the view"
	if mode != CameraController.InteractionMode.BUILD:
		_touch_interrupted = true
		_mouse_placement_armed = false
		_pointer_missed_board = true
		_invalidate_candidate()
		label_status.text = "Switch to Build to place bricks"

func _update_height_mode_ui() -> void:
	if btn_auto_height:
		btn_auto_height.text = "Height  ·  Auto" if is_auto_height else "Layer  %d  ·  Manual" % manual_layer_plate

func _on_frame_build() -> void:
	if placed_pieces_data.is_empty():
		camera_rig.set_default_view()
		return
	var min_w: Vector3 = Vector3(999, 999, 999)
	var max_w: Vector3 = Vector3(-999, -999, -999)
	for p in placed_pieces_data:
		var pid = p.get("part_id", "")
		var p_def = catalog.get_part(pid)
		var dims = p_def.get("dimensions_studs", [1, 3, 1])
		var rot = p.get("rotation_step", 0)
		var wpos = TableView.grid_to_world(p.get("grid_x", 0), p.get("grid_z", 0), p.get("layer_plate", 0), dims, rot)
		min_w.x = min(min_w.x, wpos.x - 2.0)
		min_w.z = min(min_w.z, wpos.z - 2.0)
		min_w.y = min(min_w.y, wpos.y)
		max_w.x = max(max_w.x, wpos.x + 2.0)
		max_w.z = max(max_w.z, wpos.z + 2.0)
		max_w.y = max(max_w.y, wpos.y + 2.0)
	camera_rig.frame_build(min_w, max_w)

func _update_pointer_target() -> void:
	if _last_pointer_screen_pos != Vector2.ZERO:
		_handle_pointer_position(_last_pointer_screen_pos)

## Resolve pointer ray against eligible surfaces (baseplate and placed brick tops).
## Returns candidate grid anchor, target layer plate, and world position.
func _find_target_surface(screen_pos: Vector2) -> Dictionary:
	var cam: Camera3D = camera_rig.camera
	if not cam or not cam.is_inside_tree():
		return {"valid": false}
		
	var from: Vector3 = cam.project_ray_origin(screen_pos)
	var dir: Vector3 = cam.project_ray_normal(screen_pos)
	return find_target_surface_from_ray(from, dir)

## Core 3D raycasting against placed brick tops and baseplate plane.
func find_target_surface_from_ray(from: Vector3, dir: Vector3) -> Dictionary:
	return BrickSurfaceTarget.resolve(
		from, dir, rules, placed_pieces_data, selected_part_id, current_rotation_step,
		-1 if is_auto_height else manual_layer_plate,
		current_grid_pos if has_valid_target_surface else Vector2i(-1, -1),
		current_layer_plate if has_valid_target_surface else -1
	)

func _handle_pointer_position(screen_pos: Vector2) -> void:
	if current_input_state == InputState.IDLE:
		return
	if camera_rig and (camera_rig.is_camera_mode or camera_rig.is_gesture_active):
		return
		
	var target = _find_target_surface(screen_pos)
	if not target.get("valid", false):
		_pointer_missed_board = true
		_invalidate_candidate()
		return
		
	_pointer_missed_board = false
	has_valid_target_surface = true
	if ghost_preview and not ghost_preview.visible:
		ghost_preview.visible = true
		
	var new_grid: Vector2i = target["grid_pos"]
	var new_layer: int = target["layer_plate"]
	
	if new_grid != current_grid_pos or new_layer != current_layer_plate or not is_current_placement_valid:
		current_grid_pos = new_grid
		current_layer_plate = new_layer
		_validate_and_update_ghost()

func _invalidate_candidate() -> void:
	has_valid_target_surface = false
	is_current_placement_valid = false
	if ghost_preview:
		ghost_preview.visible = false
	if btn_place:
		btn_place.disabled = true
	if label_status:
		label_status.text = "Pointer outside building area"

func _on_cancel_held_piece() -> void:
	current_input_state = InputState.IDLE
	_invalidate_candidate()
	if label_status:
		label_status.text = "Choose a brick from the tray"

func _on_rotate_left() -> void:
	current_rotation_step = (current_rotation_step - 1 + 4) % 4
	if feedback:
		feedback.notify_rotation_changed(current_rotation_step)
	elif audio_director:
		audio_director.play_rotate()
	_update_pointer_target()
	_validate_and_update_ghost()

func _on_rotate_right() -> void:
	current_rotation_step = (current_rotation_step + 1) % 4
	if feedback:
		feedback.notify_rotation_changed(current_rotation_step)
	elif audio_director:
		audio_director.play_rotate()
	_update_pointer_target()
	_validate_and_update_ghost()

func _validate_and_update_ghost() -> void:
	if not online_player_id.is_empty() and (not online_connected or session.get_current_player_id() != online_player_id):
		is_current_placement_valid = false
		btn_place.disabled = true
		ghost_preview.hide()
		label_status.text = "Waiting for %s" % session.get_current_player().get("name", "Builder") if online_connected else online_disconnect_message
		return
	if current_input_state == InputState.IDLE or _pointer_missed_board or camera_rig.is_camera_mode:
		return
	# Run authoritative placement rules check
	last_validation_result = rules.validate_placement(
		selected_part_id,
		current_grid_pos.x,
		current_grid_pos.y,
		current_layer_plate,
		current_rotation_step,
		placed_pieces_data
	)
	
	is_current_placement_valid = last_validation_result.get("valid", false)
	has_valid_target_surface = true
	if ghost_preview:
		ghost_preview.visible = true
	if feedback:
		feedback.notify_preview_validity_changed(is_current_placement_valid)
	
	# Update ghost transform using canonical stud lattice
	var p_def: Dictionary = catalog.get_part(selected_part_id)
	var dims: Array = p_def.get("dimensions_studs", [1, 3, 1])
	var world_pos: Vector3 = TableView.grid_to_world(current_grid_pos.x, current_grid_pos.y, current_layer_plate, dims, current_rotation_step)
	ghost_preview.position = world_pos
	ghost_preview.rotation_degrees = PlacementRules.get_rotation_degrees(current_rotation_step)
	
	# Update visual tint and cues
	_apply_validity_appearance(is_current_placement_valid)
	
	# Update UI feedback text with friendly family messages (LB-061)
	var status_text: String
	var player_prefix = ""
	if session and session.players.size() > 1:
		var cur_p = session.get_current_player()
		player_prefix = "[P%d] %s: " % [session.current_player_idx + 1, cur_p.get("name", "Player")]
		
	var code = last_validation_result.get("code", "ERROR")
	var reason = last_validation_result.get("reason", "")
	var friendly_msg = _format_friendly_validation_message(is_current_placement_valid, code, reason)
	
	if is_current_placement_valid:
		btn_place.disabled = current_input_state == InputState.PENDING_ACCEPTANCE
		status_text = "%s%s" % [player_prefix, friendly_msg]
	else:
		btn_place.disabled = true
		status_text = "%sBlocked · %s" % [player_prefix, friendly_msg]
		
	if label_status:
		label_status.text = status_text
		
	if label_coords and label_coords.visible:
		var mode_str = "Auto" if is_auto_height else "Manual"
		label_coords.text = "Stud: (%d, %d) | Plate: %d [%s] | Yaw: %d°  " % [
			current_grid_pos.x, current_grid_pos.y, current_layer_plate, mode_str, current_rotation_step * 90
		]

func _format_friendly_validation_message(valid: bool, code: String, reason: String) -> String:
	if valid:
		if current_layer_plate == 0:
			return "Ready to place on table"
		return "Ready to place"
	match code:
		"COLLISION":
			return "Space is already occupied"
		"FLOATING":
			return "Needs support underneath"
		"OUT_OF_BOUNDS":
			return "Must stay on the baseplate"
		"OUTSIDE_HAND":
			return "Pick a brick from your hand"
		"UNATTACHED":
			return "Connect to studs"
		"INVALID_STUD_ALIGNMENT":
			return "Must align with stud grid"
		"STUD_COLLISION":
			return "Studs don't fit there"
		_:
			return reason if not reason.is_empty() else "Cannot place here"

func _apply_validity_appearance(is_valid: bool) -> void:
	if not _ghost_material:
		return
	var high_contrast: bool = settings_manager != null and settings_manager.high_contrast_cues
	if high_contrast:
		_ghost_material.albedo_color = Color("#d3fff2dc") if is_valid else Color("#ff4968e6")
	else:
		_ghost_material.albedo_color = Color(selected_color, 0.66) if is_valid else Color("#ff495cbf")

func _set_ghost_material(node: Node) -> void:
	if node is MeshInstance3D:
		node.material_override = _ghost_material
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child in node.get_children():
		_set_ghost_material(child)

func _on_place_pressed() -> void:
	if _external_modal_open or catalog_modal.visible or camera_rig.is_camera_mode or camera_rig.is_gesture_active:
		return
	if current_input_state != InputState.HOLDING:
		return
	if not is_current_placement_valid:
		var code = last_validation_result.get("code", "ERROR")
		var reason = last_validation_result.get("reason", "Invalid placement")
		if feedback:
			feedback.notify_placement_rejected("%s: %s" % [code, reason])
		else:
			if audio_director:
				audio_director.play_reject()
			if haptics_adapter:
				haptics_adapter.vibrate_error()
		return
		
	current_input_state = InputState.PENDING_ACCEPTANCE
	if not online_player_id.is_empty():
		btn_place.disabled = true
		online_placement_requested.emit(selected_hand_slot, current_grid_pos.x, current_grid_pos.y, current_layer_plate, current_rotation_step)
		return
	if session:
		var cur_player = session.get_current_player()
		var player_id = cur_player.get("id", "p0")
		var ok = session.request_placement(
			player_id,
			selected_hand_slot,
			current_grid_pos.x,
			current_grid_pos.y,
			current_layer_plate,
			current_rotation_step,
			selected_color,
			selected_part_id
		)
		if not ok:
			current_input_state = InputState.HOLDING
	else:
		_handle_local_placement_fallback()

func _handle_local_placement_fallback() -> void:
	_local_placement_sequence += 1
	var placement_id: String = "pl_%d" % _local_placement_sequence
	var placement_record = {
		"placement_id": placement_id,
		"part_id": selected_part_id,
		"grid_x": current_grid_pos.x,
		"grid_z": current_grid_pos.y,
		"layer_plate": current_layer_plate,
		"rotation_step": current_rotation_step,
		"color": selected_color
	}
	_on_placement_accepted(placement_record)

func _on_placement_accepted(placement_record: Dictionary) -> void:
	current_input_state = InputState.HOLDING
	
	var pid = placement_record.get("part_id", selected_part_id)
	var col = placement_record.get("color", selected_color)
	var p_def: Dictionary = catalog.get_part(pid)
	var placed_node: Node3D = PartMeshBuilder.build_part_node(p_def, col)
	var dims: Array = p_def.get("dimensions_studs", [1, 3, 1])
	var rot: int = placement_record.get("rotation_step", current_rotation_step)
	var gx: int = placement_record.get("grid_x", current_grid_pos.x)
	var gz: int = placement_record.get("grid_z", current_grid_pos.y)
	var layer: int = placement_record.get("layer_plate", current_layer_plate)
	
	placed_node.position = TableView.grid_to_world(gx, gz, layer, dims, rot)
	placed_node.rotation_degrees = PlacementRules.get_rotation_degrees(rot)
	placed_bricks_container.add_child(placed_node)
	placed_pieces_data.append(placement_record)
	_update_brick_count(true)
	
	var scope_id := session.get_instance_id() if session else get_instance_id()
	var sequence = placement_record.get("sequence", placement_record.get("placement_id", ""))
	var placement_id := "%d:%s" % [scope_id, str(sequence)]
	if feedback:
		feedback.notify_placement_accepted(placement_id, placed_node, false, false)
	else:
		if audio_director:
			audio_director.play_click(placement_id)
		if haptics_adapter:
			haptics_adapter.vibrate_placement()
			
	if btn_finish:
		btn_finish.text = "Explore"
	if not online_player_id.is_empty():
		set_online_ready_count(0, session.players.size())
		
	# A solo mixed bag replenishes the spent slot without advancing a turn.
	if session and session.mode == SessionManager.GameMode.SOLO_CHALLENGE:
		var hand: Array = session.get_current_player().get("hand", [])
		if not hand.is_empty():
			var slot_idx := clampi(selected_hand_slot, 0, hand.size() - 1)
			var slot_piece: Dictionary = hand[slot_idx]
			selected_part_id = slot_piece.get("part_id", selected_part_id)
			selected_color = slot_piece.get("color", selected_color)
			_rebuild_ghost()

	# NOTE: We DO NOT unconditionally add piece height to current_layer_plate!
	# The surface targeting automatically detects the top surface under the pointer (PC-01).
	_update_pointer_target()
	_validate_and_update_ghost()

func _on_placement_rejected(reason: String, code: String) -> void:
	current_input_state = InputState.HOLDING
	if not online_player_id.is_empty():
		_validate_and_update_ghost()
		label_status.text = reason
	if feedback:
		feedback.notify_placement_rejected("%s: %s" % [code, reason])
	else:
		if audio_director:
			audio_director.play_reject()
		if haptics_adapter:
			haptics_adapter.vibrate_error()

# =========================================================================
# LB-036 Building Rules, Undo/Redo, Timers, and Solo Browser
# =========================================================================

func _on_finish_pressed() -> void:
	if not online_player_id.is_empty():
		if online_connected:
			online_ready = not online_ready
			online_ready_requested.emit(online_ready)
		return
	if not session or session.players.size() <= 1:
		finish_requested.emit()
		return
		
	var cur_player = session.get_current_player()
	var cur_id = cur_player.get("id", "")
	var is_ready = cur_player.get("is_ready_to_explore", false)
	session.set_ready_to_explore(cur_id, not is_ready)

func _on_ready_status_changed(_player_id: String, _is_ready: bool, ready_count: int, total_players: int) -> void:
	if btn_finish:
		if ready_count == total_players:
			btn_finish.text = "Explore (%d/%d)" % [ready_count, total_players]
			if feedback:
				feedback.notify_build_finished()
		else:
			btn_finish.text = "Ready (%d/%d)" % [ready_count, total_players]
	if label_status:
		label_status.text = "Finish Agreement: %d/%d players ready" % [ready_count, total_players]

func _on_session_phase_changed(new_phase: SessionManager.SessionPhase) -> void:
	if new_phase == SessionManager.SessionPhase.EXPLORATION:
		finish_requested.emit()
	elif new_phase == SessionManager.SessionPhase.BUILDING:
		btn_finish.text = "Explore"

func _on_turn_advanced(player_id: String, player_idx: int) -> void:
	_touch_interrupted = true
	if not session:
		return
	var cur_player = session.get_current_player()
	var p_num = session.current_player_idx + 1
	if color_player_badge:
		color_player_badge.color = cur_player.get("color", Color.WHITE)
	if label_status:
		label_status.text = "Turn: [P%d] %s" % [p_num, cur_player.get("name", "Player")]
	selected_hand_slot = 0
	_setup_inventory_tray()
	var hand = cur_player.get("hand", [])
	if not hand.is_empty():
		var piece = hand[0]
		_select_piece_from_slot(0, piece.get("part_id", "brick_2x4"), piece.get("color", cur_player.get("color", Color.WHITE)))
	if feedback:
		feedback.notify_turn_changed(cur_player.get("name", "Player"))
	elif audio_director:
		audio_director.play_pickup()

func _on_timer_ticked(seconds_remaining: float) -> void:
	if label_timer and label_timer.visible:
		label_timer.text = "%ds" % ceil(seconds_remaining)
		if seconds_remaining <= 5.0:
			label_timer.modulate = Color(1.0, 0.35, 0.35)
		else:
			label_timer.modulate = Color(1.0, 1.0, 1.0)

func _on_timer_expired(skipped_player_id: String) -> void:
	if label_status:
		label_status.text = "Time expired! Turn passed to next player."
	if audio_director:
		audio_director.play_reject()

func _on_inventory_refilled(_player_id: String, _new_piece: Dictionary, _slot_idx: int) -> void:
	if session and session.mode == SessionManager.GameMode.SOLO_CHALLENGE:
		_setup_inventory_tray()

func _on_pass_turn_pressed() -> void:
	if not online_player_id.is_empty():
		return
	if not session or session.players.size() <= 1:
		return
	session.skip_turn()
	if audio_director:
		audio_director.play_pickup()

func _on_undo_pressed() -> void:
	if not online_player_id.is_empty():
		return
	if not session:
		return
	var res = session.undo_last_placement()
	if res.get("success", false):
		if placed_bricks_container and placed_bricks_container.get_child_count() > 0:
			var last_node = placed_bricks_container.get_child(placed_bricks_container.get_child_count() - 1)
			last_node.queue_free()
		placed_pieces_data.pop_back()
		_update_brick_count()
		if label_status:
			label_status.text = "Placement undone (%d placed)" % placed_pieces_data.size()
		if feedback:
			feedback.notify_undo()
		elif audio_director:
			audio_director.play_click()
		if haptics_adapter:
			haptics_adapter.vibrate_light()
		_update_pointer_target()
		_validate_and_update_ghost()
	else:
		var code = res.get("code", "FAIL")
		if code == "DEPENDENT_MOVE_EXISTS":
			if label_status:
				label_status.text = "Cannot undo: a piece above depends on this brick"
			if feedback:
				feedback.notify_placement_rejected("DEPENDENT_MOVE_EXISTS")
			else:
				if audio_director:
					audio_director.play_reject()
				if haptics_adapter:
					haptics_adapter.vibrate_error()

func _on_redo_pressed() -> void:
	if not online_player_id.is_empty():
		return
	if not session:
		return
	var res = session.redo_placement()
	if res.get("success", false):
		var to_redo = res.get("redone_placement", res.get("undone_placement", {}))
		if to_redo.is_empty() and session.placements.size() > 0:
			to_redo = session.placements.back()
		_reconstruct_redone_piece(to_redo)
		if label_status:
			label_status.text = "Placement redone (%d placed)" % placed_pieces_data.size()
		if feedback:
			feedback.notify_redo()
		elif audio_director:
			audio_director.play_click()
		if haptics_adapter:
			haptics_adapter.vibrate_light()
		_update_pointer_target()
		_validate_and_update_ghost()

func _reconstruct_redone_piece(to_redo: Dictionary) -> void:
	var pid = to_redo.get("part_id", "brick_2x4")
	var col = to_redo.get("color", Color.WHITE)
	var p_def = catalog.get_part(pid)
	var dims = p_def.get("dimensions_studs", [1, 3, 1])
	var rot = to_redo.get("rotation_step", 0)
	var node = PartMeshBuilder.build_part_node(p_def, col)
	node.position = TableView.grid_to_world(to_redo.get("grid_x", 0), to_redo.get("grid_z", 0), to_redo.get("layer_plate", 0), dims, rot)
	node.rotation_degrees = PlacementRules.get_rotation_degrees(rot)
	placed_bricks_container.add_child(node)
	placed_pieces_data.append(to_redo)
	_update_brick_count(true)

# Solo Parts Catalog Browser
func _toggle_catalog_modal() -> void:
	if not catalog_modal:
		return
	catalog_modal.visible = not catalog_modal.visible
	_update_modal_input()
	if catalog_modal.visible:
		_setup_catalog_categories()
		_populate_catalog_grid()

func _close_catalog_modal() -> void:
	if catalog_modal:
		catalog_modal.visible = false
		_update_modal_input()

func set_external_modal_open(open: bool) -> void:
	_external_modal_open = open
	_update_modal_input()

func _update_modal_input() -> void:
	$UI/RootControl/CatalogScrim.visible = catalog_modal.visible
	camera_rig.is_input_enabled = not (_external_modal_open or catalog_modal.visible)
	camera_rig.reset_gesture_state()
	_mouse_placement_armed = false
	_clear_touch_sequence()

func _setup_catalog_packs() -> void:
	opt_catalog_pack.add_item("All packs")
	opt_catalog_pack.set_item_metadata(0, "")
	opt_catalog_pack.add_item("Core bricks")
	opt_catalog_pack.set_item_metadata(1, "core")
	for i in range(BrickPacks.IDS.size()):
		opt_catalog_pack.add_item(BrickPacks.LABELS[i])
		opt_catalog_pack.set_item_metadata(i + 2, BrickPacks.IDS[i])
	opt_catalog_pack.select(0)
	opt_catalog_pack.item_selected.connect(func(_index: int): _populate_catalog_grid())

func _setup_catalog_categories() -> void:
	if not opt_catalog_category or opt_catalog_category.item_count > 0:
		return
	opt_catalog_category.add_item("All Categories")
	opt_catalog_category.add_item("Bricks")
	opt_catalog_category.add_item("Plates")
	opt_catalog_category.add_item("Slopes")
	opt_catalog_category.add_item("Openings")
	opt_catalog_category.add_item("Tiles")
	opt_catalog_category.add_item("Decorations")
	opt_catalog_category.add_item("Characters")
	opt_catalog_category.add_item("Structures")

func _populate_catalog_grid() -> void:
	if not catalog_grid:
		return
	for child in catalog_grid.get_children():
		catalog_grid.remove_child(child)
		child.queue_free()
		
	# Responsive grid column count based on viewport or modal width
	if catalog_modal:
		var modal_w: float = catalog_modal.size.x
		if modal_w < 500.0:
			catalog_grid.columns = 2
		elif modal_w < 720.0:
			catalog_grid.columns = 3
		else:
			catalog_grid.columns = 4
		
	var selected_cat_idx = opt_catalog_category.selected if opt_catalog_category else 0
	var filter_text = line_catalog_search.text.strip_edges().to_lower() if line_catalog_search else ""
	
	var cat_map = ["", "brick", "plate", "slope", "opening", "tile", "decoration", "character", "structure"]
	var target_cat = cat_map[selected_cat_idx] if selected_cat_idx < cat_map.size() else ""
	
	var selected_pack := String(opt_catalog_pack.get_selected_metadata())
	var all_ids: Array[String] = []
	if selected_pack.is_empty():
		all_ids = catalog.get_all_part_ids()
		all_ids.sort()
	else:
		var shared_ids: Array[String] = []
		for part in catalog.get_theme_parts(selected_pack):
			if selected_pack != "core" and "core" in part.get("theme_tags", []):
				shared_ids.append(part["id"])
			else:
				all_ids.append(part["id"])
		all_ids.sort()
		shared_ids.sort()
		all_ids.append_array(shared_ids)
	var matched_count: int = 0
	_catalog_part_id = ""
	_clear_catalog_preview()
	
	for pid in all_ids:
		var p_def = catalog.get_part(pid)
		var p_cat = p_def.get("category", "")
		var p_name = p_def.get("name", pid)
		
		if not target_cat.is_empty() and p_cat != target_cat:
			continue
		if not filter_text.is_empty() and not p_name.to_lower().contains(filter_text) and not pid.to_lower().contains(filter_text):
			continue
			
		matched_count += 1
		var btn = Button.new()
		btn.text = p_name
		btn.tooltip_text = p_name
		btn.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		btn.custom_minimum_size = Vector2(110, 44)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(_show_catalog_preview.bind(pid))
		if matched_count == 1:
			_show_catalog_preview(pid)

		catalog_grid.add_child(btn)
		
	if matched_count == 0:
		var empty_lbl = Label.new()
		empty_lbl.text = "No parts match '%s'" % filter_text if not filter_text.is_empty() else "No parts in this pack or category"
		empty_lbl.add_theme_color_override("font_color", WorkbenchHUD.MUTED)
		catalog_grid.add_child(empty_lbl)

func _clear_catalog_preview() -> void:
	var preview := catalog_modal.find_child("CatalogPreview")
	for child in preview.get_children():
		preview.remove_child(child)
		child.queue_free()
	catalog_modal.find_child("BtnPickPart").disabled = true

func _show_catalog_preview(part_id: String) -> void:
	if _catalog_part_id == part_id:
		return
	_clear_catalog_preview()
	_catalog_part_id = part_id
	var part: Dictionary = catalog.get_part(part_id)
	if part.is_empty():
		return
	var preview := catalog_modal.find_child("CatalogPreview")
	var specimen := Button.new()
	specimen.disabled = true
	specimen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	specimen.custom_minimum_size = Vector2(180, 141)
	specimen.text = String(part.get("name", part_id))
	var box := WorkbenchHUD.surface(WorkbenchHUD.IVORY, Color("#b89d65"))
	box.content_margin_top = 108
	specimen.add_theme_stylebox_override("disabled", box)
	specimen.add_theme_color_override("font_disabled_color", WorkbenchHUD.DARK)
	preview.add_child(specimen)
	WorkbenchHUD.add_part_preview(specimen, part, selected_color)
	var pick := catalog_modal.find_child("BtnPickPart") as Button
	pick.disabled = session != null and session.mode != SessionManager.GameMode.SOLO_CREATIVE
	pick.text = "Use the brick tray" if pick.disabled else "Pick this brick"

func _pick_catalog_part() -> void:
	if _catalog_part_id.is_empty():
		return
	if session and session.mode != SessionManager.GameMode.SOLO_CREATIVE:
		return
	selected_hand_slot = -1
	_select_piece(_catalog_part_id, selected_color)
	_refresh_tray_selection()
	_close_catalog_modal()
