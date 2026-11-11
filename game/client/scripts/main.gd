extends Node3D

## Main scene controller for LittleBricks client.
## Integrates PlacementRules validation, selectable inventory tray,
## canonical stud lattice, surface-following Auto Height, manual height override,
## discoverable camera modes, and robust touch/desktop input ownership.

signal finish_requested()
signal leave_requested()
signal settings_requested()

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
var _is_initialized: bool = false
var _last_pointer_screen_pos: Vector2 = Vector2.ZERO

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
	
	_connect_ui()
	_setup_inventory_tray()
	_update_height_mode_ui()
	_rebuild_ghost()
	_validate_and_update_ghost()

func _process(delta: float) -> void:
	if session and session.timer_enabled and session.phase == SessionManager.SessionPhase.BUILDING:
		session.tick_timer(delta)

func attach_session(p_session: SessionManager, p_audio = null, p_haptics = null, p_settings = null) -> void:
	session = p_session
	audio_director = p_audio
	haptics_adapter = p_haptics
	settings_manager = p_settings
	
	feedback = InteractionFeedback.new(audio_director, haptics_adapter, settings_manager)
	
	if not presentation:
		presentation = PresentationController.new()
		add_child(presentation)
	
	if session and presentation:
		presentation.apply_presentation(session.theme_id, get_node_or_null("WorldEnvironment"), get_node_or_null("DirectionalLight3D"), table_view)
	
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
		btn_pass_turn.visible = (session.mode != SessionManager.GameMode.SOLO_CREATIVE)
		
	var cur_player = session.get_current_player()
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
	if btn_camera_mode and not btn_camera_mode.pressed.is_connected(_toggle_camera_mode):
		btn_camera_mode.pressed.connect(_toggle_camera_mode)
	if btn_top_view and camera_rig and not btn_top_view.pressed.is_connected(camera_rig.set_top_view):
		btn_top_view.pressed.connect(camera_rig.set_top_view)
	if btn_frame_build and not btn_frame_build.pressed.is_connected(_on_frame_build):
		btn_frame_build.pressed.connect(_on_frame_build)
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
	for child in tray_container.get_children():
		tray_container.remove_child(child)
		child.queue_free()
		
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
	
	for i in range(pieces_to_show.size()):
		var piece = pieces_to_show[i]
		var pid = piece.get("part_id", piece.get("id", "brick_2x4"))
		var pname = piece.get("name", pid)
		var pcolor = piece.get("color", Color(0.85, 0.15, 0.15))
		var is_selected: bool = (selected_hand_slot == i)
		
		var btn: Button = Button.new()
		btn.text = pname
		btn.custom_minimum_size = Vector2(96, 48)
		
		# Visual styling with swatch color and selection border (LB-061)
		var sb = StyleBoxFlat.new()
		sb.bg_color = UIThemeHelper.COLOR_SURFACE_PAPER
		sb.border_color = UIThemeHelper.COLOR_PRIMARY_TEAL if is_selected else UIThemeHelper.COLOR_BORDER_WARM
		sb.set_border_width_all(3 if is_selected else 1)
		sb.set_corner_radius_all(12)
		sb.set_content_margin_all(8)
		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_stylebox_override("hover", sb)
		btn.add_theme_stylebox_override("pressed", sb)
		btn.add_theme_stylebox_override("focus", sb)
		btn.add_theme_color_override("font_color", UIThemeHelper.COLOR_TEXT_INK)
		btn.modulate = Color(1.0, 1.0, 1.0, 1.0) if is_selected else Color(0.95, 0.95, 0.95, 0.9)
		
		var slot_idx = i
		btn.pressed.connect(func():
			selected_hand_slot = slot_idx
			_select_piece_from_slot(slot_idx, pid, pcolor)
			_setup_inventory_tray()
		)
		tray_container.add_child(btn)

func _select_piece_from_slot(slot_idx: int, part_id: String, color: Color) -> void:
	selected_hand_slot = slot_idx
	_select_piece(part_id, color)

func _select_piece(part_id: String, color: Color) -> void:
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
		
	# Build translucent ghost version
	_ghost_node = PartMeshBuilder.build_part_node(p_def, selected_color)
	ghost_preview.add_child(_ghost_node)

func _unhandled_input(event: InputEvent) -> void:
	# If catalog modal is open, prevent all world interaction
	if catalog_modal and catalog_modal.visible:
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
			_on_frame_build()
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
		elif k == KEY_F3:
			if label_coords:
				label_coords.visible = not label_coords.visible
			_consume_input()
			return

	# Mouse/Touch placement in 3D world (only when NOT in camera mode or orbiting/panning)
	var is_cam_busy: bool = camera_rig and (camera_rig.is_camera_mode or camera_rig.is_orbiting or camera_rig.is_panning)
	if not is_cam_busy and current_input_state == InputState.HOLDING:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Direct world click resolves at click's exact screen position (PT-01 / PT-03)
			var target = _find_target_surface(event.position)
			if target.get("valid", false):
				current_grid_pos = target["grid_pos"]
				current_layer_plate = target["layer_plate"]
				has_valid_target_surface = true
				_validate_and_update_ghost()
				if is_current_placement_valid:
					_on_place_pressed()
			else:
				_invalidate_candidate()
			_consume_input()
			return

	if not is_cam_busy:
		if event is InputEventMouseMotion:
			_last_pointer_screen_pos = event.position
			_handle_pointer_position(event.position)
		elif event is InputEventScreenDrag:
			var offset_pos: Vector2 = event.position - Vector2(0, 50)
			_last_pointer_screen_pos = offset_pos
			_handle_pointer_position(offset_pos)
		elif event is InputEventScreenTouch and event.pressed:
			var offset_pos: Vector2 = event.position - Vector2(0, 50)
			_last_pointer_screen_pos = offset_pos
			_handle_pointer_position(offset_pos)

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
	camera_rig.is_camera_mode = not camera_rig.is_camera_mode
	if btn_camera_mode:
		btn_camera_mode.text = "Camera: Pan (C)" if camera_rig.is_camera_mode else "Camera: Drag (C)"
	if label_status:
		label_status.text = "Camera Mode Active (Left-drag orbits table)" if camera_rig.is_camera_mode else "Ready to build"

func _update_height_mode_ui() -> void:
	if btn_auto_height:
		btn_auto_height.text = "Auto Height [ON]" if is_auto_height else "Manual Height [ON]"

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
	if dir.y >= -0.0001:
		return {"valid": false}
		
	var p_def: Dictionary = catalog.get_part(selected_part_id)
	var dims: Array = p_def.get("dimensions_studs", [1, 3, 1])
	
	if not is_auto_height:
		# Manual height mode: intersect fixed plane at manual_layer_plate
		var plane_y: float = 0.1 + (float(manual_layer_plate) * TableView.PLATE_HEIGHT)
		var t: float = (plane_y - from.y) / dir.y
		if t > 0.0:
			var hit_pos: Vector3 = from + dir * t
			var grid_x_f: float = (hit_pos.x / TableView.STUD_SPACING) + 15.5
			var grid_z_f: float = (hit_pos.z / TableView.STUD_SPACING) + 15.5
			if grid_x_f >= -0.5 and grid_x_f <= 31.5 and grid_z_f >= -0.5 and grid_z_f <= 31.5:
				var grid_pos: Vector2i = TableView.world_to_grid(hit_pos, dims, current_rotation_step)
				return {
					"valid": true,
					"grid_pos": grid_pos,
					"layer_plate": manual_layer_plate,
					"hit_pos": hit_pos
				}
		return {"valid": false}
		
	# AUTO HEIGHT MODE:
	# Intersect ray with top surfaces of placed bricks and baseplate
	var candidate_hits: Array = []
	
	# 1. Baseplate surface (y = 0.1, layer = 0)
	var t_base: float = (0.1 - from.y) / dir.y
	if t_base > 0.0:
		var hit_base: Vector3 = from + dir * t_base
		var grid_x_f: float = (hit_base.x / TableView.STUD_SPACING) + 15.5
		var grid_z_f: float = (hit_base.z / TableView.STUD_SPACING) + 15.5
		# Check if hit is within the 32x32 board area (with 0.5 stud margin)
		if grid_x_f >= -0.5 and grid_x_f <= 31.5 and grid_z_f >= -0.5 and grid_z_f <= 31.5:
			candidate_hits.append({
				"t": t_base,
				"layer": 0,
				"hit_pos": hit_base
			})
			
	# 2. Placed pieces top surfaces
	for placed in placed_pieces_data:
		var pid: String = placed.get("part_id", "")
		var pgx: int = placed.get("grid_x", 0)
		var pgz: int = placed.get("grid_z", 0)
		var player: int = placed.get("layer_plate", 0)
		var prot: int = placed.get("rotation_step", 0)
		
		var placed_def: Dictionary = catalog.get_part(pid)
		var placed_dims: Array = placed_def.get("dimensions_studs", [1, 3, 1])
		var placed_fp: Vector2i = PlacementRules.get_part_footprint(placed_dims, prot)
		var top_layer: int = player + int(placed_dims[1])
		var top_y: float = 0.1 + (float(top_layer) * TableView.PLATE_HEIGHT)
		
		var t_piece: float = (top_y - from.y) / dir.y
		if t_piece > 0.0:
			var hit_piece: Vector3 = from + dir * t_piece
			var pt_gx: float = (hit_piece.x / TableView.STUD_SPACING) + 15.5
			var pt_gz: float = (hit_piece.z / TableView.STUD_SPACING) + 15.5
			
			var x_min: float = float(pgx) - 0.5
			var x_max: float = float(pgx + placed_fp.x) - 0.5
			var z_min: float = float(pgz) - 0.5
			var z_max: float = float(pgz + placed_fp.y) - 0.5
			
			if pt_gx >= x_min and pt_gx <= x_max and pt_gz >= z_min and pt_gz <= z_max:
				candidate_hits.append({
					"t": t_piece,
					"layer": top_layer,
					"hit_pos": hit_piece
				})
				
	if candidate_hits.is_empty():
		return {"valid": false}
		
	# Pick the closest hit along ray to camera (smallest positive t)
	candidate_hits.sort_custom(func(a, b): return a["t"] < b["t"])
	var best_hit: Dictionary = candidate_hits[0]
	
	var chosen_layer: int = best_hit["layer"]
	var chosen_hit_pos: Vector3 = best_hit["hit_pos"]
	var chosen_grid: Vector2i = TableView.world_to_grid(chosen_hit_pos, dims, current_rotation_step)
	
	return {
		"valid": true,
		"grid_pos": chosen_grid,
		"layer_plate": chosen_layer,
		"hit_pos": chosen_hit_pos
	}

func _handle_pointer_position(screen_pos: Vector2) -> void:
	if current_input_state == InputState.IDLE:
		return
	if camera_rig and (camera_rig.is_camera_mode or camera_rig.is_orbiting or camera_rig.is_panning):
		return
		
	var target = _find_target_surface(screen_pos)
	if not target.get("valid", false):
		_invalidate_candidate()
		return
		
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
		label_status.text = "Placement canceled. Select a piece from the tray to build."

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
	if is_current_placement_valid:
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
		btn_place.disabled = false
		status_text = "%s✓ %s" % [player_prefix, friendly_msg]
	else:
		btn_place.disabled = true
		status_text = "%s✕ %s" % [player_prefix, friendly_msg]
		
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
	if not _ghost_node:
		return
	var display_color: Color
	if is_valid:
		display_color = Color(selected_color.r * 0.9, selected_color.g * 1.1, selected_color.b * 0.9, 0.65)
	else:
		display_color = Color(0.95, 0.15, 0.15, 0.6) # Translucent red for collision/floating
		
	_set_node_material_color(_ghost_node, display_color)

func _set_node_material_color(node: Node, color: Color) -> void:
	if node is MeshInstance3D:
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.albedo_color = color
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.roughness = 0.3
		node.material_override = mat
	for child in node.get_children():
		_set_node_material_color(child, color)

func _on_place_pressed() -> void:
	if current_input_state == InputState.IDLE or current_input_state == InputState.PENDING_ACCEPTANCE:
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
	var placement_id: String = "pl_%d" % (placed_pieces_data.size() + 1)
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
	
	var placement_id = placement_record.get("placement_id", "pl_%d" % placed_pieces_data.size())
	if feedback:
		feedback.notify_placement_accepted(placement_id, placed_node, false, false)
	else:
		if audio_director:
			audio_director.play_click(placement_id)
		if haptics_adapter:
			haptics_adapter.vibrate_placement()
			
	if btn_finish:
		btn_finish.text = "Explore"
		
	# Update active hand selection if in turn-based mode
	if session and session.players.size() > 1:
		_setup_inventory_tray()
		var cur_player = session.get_current_player()
		var hand = cur_player.get("hand", [])
		if not hand.is_empty():
			var slot_idx = clampi(selected_hand_slot, 0, hand.size() - 1)
			var slot_piece = hand[slot_idx]
			_select_piece_from_slot(slot_idx, slot_piece.get("part_id", "brick_2x4"), slot_piece.get("color", cur_player.get("color", Color.WHITE)))
	else:
		_setup_inventory_tray()
		
	# NOTE: We DO NOT unconditionally add piece height to current_layer_plate!
	# The surface targeting automatically detects the top surface under the pointer (PC-01).
	_update_pointer_target()
	_validate_and_update_ghost()

func _on_placement_rejected(reason: String, code: String) -> void:
	current_input_state = InputState.HOLDING
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

func _on_turn_advanced(player_id: String, player_idx: int) -> void:
	if not session:
		return
	var cur_player = session.get_current_player()
	var p_num = session.current_player_idx + 1
	if color_player_badge:
		color_player_badge.color = cur_player.get("color", Color.WHITE)
	if label_status:
		label_status.text = "Turn: [P%d] %s" % [p_num, cur_player.get("name", "Player")]
	_setup_inventory_tray()
	selected_hand_slot = 0
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
		label_timer.text = "⏱ %ds" % ceil(seconds_remaining)
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
	_setup_inventory_tray()

func _on_pass_turn_pressed() -> void:
	if not session or session.players.size() <= 1:
		return
	session.skip_turn()
	if audio_director:
		audio_director.play_pickup()

func _on_undo_pressed() -> void:
	if not session:
		return
	var res = session.undo_last_placement()
	if res.get("success", false):
		if placed_bricks_container and placed_bricks_container.get_child_count() > 0:
			var last_node = placed_bricks_container.get_child(placed_bricks_container.get_child_count() - 1)
			last_node.queue_free()
		placed_pieces_data.pop_back()
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

# Solo Parts Catalog Browser
func _toggle_catalog_modal() -> void:
	if not catalog_modal:
		return
	catalog_modal.visible = not catalog_modal.visible
	if catalog_modal.visible:
		_setup_catalog_categories()
		_populate_catalog_grid()

func _close_catalog_modal() -> void:
	if catalog_modal:
		catalog_modal.visible = false

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
	
	var cat_map = ["", "brick", "plate", "slope", "opening", "tile", "decoration", "character"]
	var target_cat = cat_map[selected_cat_idx] if selected_cat_idx < cat_map.size() else ""
	
	var all_ids = catalog.get_all_part_ids()
	all_ids.sort()
	var matched_count: int = 0
	
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
		btn.custom_minimum_size = Vector2(130, 44)
		UIThemeHelper.apply_secondary_button(btn)
		btn.pressed.connect(func():
			if session and session.mode != SessionManager.GameMode.SOLO_CREATIVE:
				if label_status:
					label_status.text = "In Mixed Bags mode, build using your 6 hand pieces!"
				if feedback:
					feedback.notify_placement_rejected("OUTSIDE_HAND: Use hand pieces")
				elif audio_director:
					audio_director.play_reject()
			else:
				_select_piece(pid, selected_color)
			if catalog_modal:
				catalog_modal.visible = false
		)
		catalog_grid.add_child(btn)
		
	if matched_count == 0:
		var empty_lbl = Label.new()
		empty_lbl.text = "No parts match '%s'" % filter_text if not filter_text.is_empty() else "No parts in this category"
		empty_lbl.add_theme_color_override("font_color", UIThemeHelper.COLOR_TEXT_SECONDARY)
		catalog_grid.add_child(empty_lbl)
