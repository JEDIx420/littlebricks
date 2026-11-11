extends Node3D

## Main scene controller for LittleBricks client.
## Integrates PlacementRules validation, selectable inventory tray,
## canonical stud lattice, surface-following Auto Height, manual height override,
## discoverable camera modes, and robust touch/desktop input ownership.

const CameraController = preload("res://client/scripts/camera_controller.gd")
const TableView = preload("res://client/scripts/table_view.gd")
const PartCatalog = preload("res://core/part_catalog.gd")
const PartMeshBuilder = preload("res://core/part_mesh_builder.gd")
const PlacementRules = preload("res://core/placement_rules.gd")

@onready var camera_rig: CameraController = $CameraRig
@onready var table_view: TableView = $TableView
@onready var ghost_preview: Node3D = $GhostPreview
@onready var placed_bricks_container: Node3D = $PlacedBricks

# UI controls
@onready var label_status: Label = %LabelStatus
@onready var label_coords: Label = %LabelCoords
@onready var btn_rotate_left: Button = %BtnRotateLeft
@onready var btn_rotate_right: Button = %BtnRotateRight
@onready var btn_auto_height: Button = %BtnAutoHeight
@onready var btn_layer_down: Button = %BtnLayerDown
@onready var btn_layer_up: Button = %BtnLayerUp
@onready var btn_return_base: Button = %BtnReturnBase
@onready var btn_place: Button = %BtnPlace
@onready var btn_camera_mode: Button = %BtnCameraMode
@onready var btn_top_view: Button = %BtnTopView
@onready var btn_frame_build: Button = %BtnFrameBuild
@onready var btn_reset_view: Button = %BtnResetView
@onready var tray_container: HBoxContainer = %TrayContainer

var catalog: PartCatalog
var rules: PlacementRules

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
	if not label_status: label_status = get_node_or_null("%LabelStatus")
	if not label_coords: label_coords = get_node_or_null("%LabelCoords")
	if not btn_rotate_left: btn_rotate_left = get_node_or_null("%BtnRotateLeft")
	if not btn_rotate_right: btn_rotate_right = get_node_or_null("%BtnRotateRight")
	if not btn_auto_height: btn_auto_height = get_node_or_null("%BtnAutoHeight")
	if not btn_layer_down: btn_layer_down = get_node_or_null("%BtnLayerDown")
	if not btn_layer_up: btn_layer_up = get_node_or_null("%BtnLayerUp")
	if not btn_return_base: btn_return_base = get_node_or_null("%BtnReturnBase")
	if not btn_place: btn_place = get_node_or_null("%BtnPlace")
	if not btn_camera_mode: btn_camera_mode = get_node_or_null("%BtnCameraMode")
	if not btn_top_view: btn_top_view = get_node_or_null("%BtnTopView")
	if not btn_frame_build: btn_frame_build = get_node_or_null("%BtnFrameBuild")
	if not btn_reset_view: btn_reset_view = get_node_or_null("%BtnResetView")
	if not tray_container: tray_container = get_node_or_null("%TrayContainer")
	if camera_rig: camera_rig._ready()
	
	catalog = PartCatalog.new()
	catalog.load_catalog("res://assets/catalog/parts_manifest.json")
	rules = PlacementRules.new(catalog)
	
	_connect_ui()
	_setup_inventory_tray()
	_update_height_mode_ui()
	_rebuild_ghost()
	_validate_and_update_ghost()

func _connect_ui() -> void:
	if not btn_rotate_left.pressed.is_connected(_on_rotate_left):
		btn_rotate_left.pressed.connect(_on_rotate_left)
	if not btn_rotate_right.pressed.is_connected(_on_rotate_right):
		btn_rotate_right.pressed.connect(_on_rotate_right)
	if not btn_auto_height.pressed.is_connected(_toggle_auto_height):
		btn_auto_height.pressed.connect(_toggle_auto_height)
	if not btn_layer_down.pressed.is_connected(func(): _bump_layer(-1)):
		btn_layer_down.pressed.connect(func(): _bump_layer(-1))
	if not btn_layer_up.pressed.is_connected(func(): _bump_layer(1)):
		btn_layer_up.pressed.connect(func(): _bump_layer(1))
	if not btn_return_base.pressed.is_connected(_return_to_base):
		btn_return_base.pressed.connect(_return_to_base)
	if not btn_place.pressed.is_connected(_on_place_pressed):
		btn_place.pressed.connect(_on_place_pressed)
	if not btn_camera_mode.pressed.is_connected(_toggle_camera_mode):
		btn_camera_mode.pressed.connect(_toggle_camera_mode)
	if not btn_top_view.pressed.is_connected(camera_rig.set_top_view):
		btn_top_view.pressed.connect(camera_rig.set_top_view)
	if not btn_frame_build.pressed.is_connected(_on_frame_build):
		btn_frame_build.pressed.connect(_on_frame_build)
	if not btn_reset_view.pressed.is_connected(camera_rig.set_default_view):
		btn_reset_view.pressed.connect(camera_rig.set_default_view)

func _setup_inventory_tray() -> void:
	for child in tray_container.get_children():
		child.queue_free()
		
	var available_parts = [
		{"id": "brick_2x4", "name": "2x4 Brick", "color": Color(0.85, 0.15, 0.15)},
		{"id": "brick_2x2", "name": "2x2 Brick", "color": Color(0.15, 0.35, 0.85)},
		{"id": "brick_1x4", "name": "1x4 Brick", "color": Color(0.9, 0.75, 0.1)},
		{"id": "brick_1x2", "name": "1x2 Brick", "color": Color(0.92, 0.92, 0.92)},
		{"id": "plate_2x4", "name": "2x4 Plate", "color": Color(0.15, 0.65, 0.25)},
		{"id": "arch_1x4",  "name": "1x4 Arch",  "color": Color(0.3, 0.3, 0.35)}
	]
	
	for piece in available_parts:
		var btn: Button = Button.new()
		btn.text = piece["name"]
		btn.custom_minimum_size = Vector2(90, 48)
		btn.pressed.connect(func(): _select_piece(piece["id"], piece["color"]))
		tray_container.add_child(btn)

func _select_piece(part_id: String, color: Color) -> void:
	selected_part_id = part_id
	selected_color = color
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

	# Mouse/Touch placement in 3D world (only when NOT in camera drag mode)
	if not camera_rig.is_camera_mode:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_on_place_pressed()
			_consume_input()
			return

	if event is InputEventMouseMotion:
		_last_pointer_screen_pos = event.position
		_handle_pointer_position(event.position)
	elif event is InputEventScreenDrag:
		# Touch dragging with vertical offset to avoid finger obscuring target
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
	var target = _find_target_surface(screen_pos)
	if not target.get("valid", false):
		return
		
	var new_grid: Vector2i = target["grid_pos"]
	var new_layer: int = target["layer_plate"]
	
	if new_grid != current_grid_pos or new_layer != current_layer_plate:
		current_grid_pos = new_grid
		current_layer_plate = new_layer
		_validate_and_update_ghost()

func _on_rotate_left() -> void:
	current_rotation_step = (current_rotation_step - 1 + 4) % 4
	_update_pointer_target()
	_validate_and_update_ghost()

func _on_rotate_right() -> void:
	current_rotation_step = (current_rotation_step + 1) % 4
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
	
	# Update ghost transform using canonical stud lattice
	var p_def: Dictionary = catalog.get_part(selected_part_id)
	var dims: Array = p_def.get("dimensions_studs", [1, 3, 1])
	var world_pos: Vector3 = TableView.grid_to_world(current_grid_pos.x, current_grid_pos.y, current_layer_plate, dims, current_rotation_step)
	ghost_preview.position = world_pos
	ghost_preview.rotation_degrees = PlacementRules.get_rotation_degrees(current_rotation_step)
	
	# Update visual tint and cues
	_apply_validity_appearance(is_current_placement_valid)
	
	# Update UI feedback text
	var status_text: String
	if is_current_placement_valid:
		btn_place.disabled = false
		status_text = "✓ [VALID] Ready to place (%s)" % last_validation_result.get("reason", "OK")
	else:
		btn_place.disabled = true
		status_text = "✕ [INVALID] %s: %s" % [
			last_validation_result.get("code", "ERROR"),
			last_validation_result.get("reason", "Cannot place here")
		]
		
	if label_status:
		label_status.text = status_text
		
	if label_coords:
		var mode_str = "Auto" if is_auto_height else "Manual"
		label_coords.text = "Stud: (%d, %d) | Plate: %d [%s] | Yaw: %d°  " % [
			current_grid_pos.x, current_grid_pos.y, current_layer_plate, mode_str, current_rotation_step * 90
		]

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
	if not is_current_placement_valid:
		return
		
	# Spawn permanent brick
	var p_def: Dictionary = catalog.get_part(selected_part_id)
	var placed_node: Node3D = PartMeshBuilder.build_part_node(p_def, selected_color)
	placed_node.position = ghost_preview.position
	placed_node.rotation = ghost_preview.rotation
	placed_bricks_container.add_child(placed_node)
	
	# Record piece state
	var piece_record = {
		"placement_id": "p_%d" % placed_pieces_data.size(),
		"part_id": selected_part_id,
		"grid_x": current_grid_pos.x,
		"grid_z": current_grid_pos.y,
		"layer_plate": current_layer_plate,
		"rotation_step": current_rotation_step,
		"color": selected_color
	}
	placed_pieces_data.append(piece_record)
	
	# NOTE: We DO NOT unconditionally add piece height to current_layer_plate!
	# The surface targeting automatically detects the top surface under the pointer (PC-01).
	_update_pointer_target()
	_validate_and_update_ghost()
