extends Node3D

## Main scene controller for LittleBricks client.
## Integrates PlacementRules validation, selectable inventory tray,
## quarter-turn rotation, layer height controls, and touch/desktop input parity.

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
@onready var btn_place: Button = %BtnPlace
@onready var btn_top_view: Button = %BtnTopView
@onready var btn_reset_view: Button = %BtnResetView
@onready var tray_container: HBoxContainer = %TrayContainer

var catalog: PartCatalog
var rules: PlacementRules

# State
var current_rotation_step: int = 0 # 0, 1, 2, 3 representing 0, 90, 180, 270 degrees
var current_grid_pos: Vector2i = Vector2i(16, 16)
var current_layer_plate: int = 0 # in plates (0 = on baseplate, 3 = on top of 1st brick, etc.)
var selected_part_id: String = "brick_2x4"
var selected_color: Color = Color(0.85, 0.15, 0.15) # Classic red brick
var is_current_placement_valid: bool = false
var last_validation_result: Dictionary = {}

var placed_pieces_data: Array = []
var _ghost_node: Node3D = null
var _is_initialized: bool = false

func _ready() -> void:
	if _is_initialized:
		return
	_is_initialized = true
	
	catalog = PartCatalog.new()
	catalog.load_catalog("res://assets/catalog/parts_manifest.json")
	rules = PlacementRules.new(catalog)
	
	_connect_ui()
	_setup_inventory_tray()
	_rebuild_ghost()
	_validate_and_update_ghost()

func _connect_ui() -> void:
	if not btn_rotate_left.pressed.is_connected(_on_rotate_left):
		btn_rotate_left.pressed.connect(_on_rotate_left)
	if not btn_rotate_right.pressed.is_connected(_on_rotate_right):
		btn_rotate_right.pressed.connect(_on_rotate_right)
	if not btn_place.pressed.is_connected(_on_place_pressed):
		btn_place.pressed.connect(_on_place_pressed)
	if not btn_top_view.pressed.is_connected(camera_rig.set_top_view):
		btn_top_view.pressed.connect(camera_rig.set_top_view)
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

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("rotate_left"):
		_on_rotate_left()
	elif event.is_action_pressed("rotate_right"):
		_on_rotate_right()
	elif event.is_action_pressed("place"):
		_on_place_pressed()
	
	# Layer height controls via keyboard (+/-)
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_EQUAL or event.keycode == KEY_KP_ADD:
			set_layer(current_layer_plate + 1)
		elif event.keycode == KEY_MINUS or event.keycode == KEY_KP_SUBTRACT:
			set_layer(max(0, current_layer_plate - 1))
	
	if event is InputEventMouseMotion:
		_handle_pointer_position(event.position)
	elif event is InputEventScreenDrag:
		# Touch dragging with vertical offset to avoid finger obscuring target
		var offset_pos: Vector2 = event.position - Vector2(0, 50)
		_handle_pointer_position(offset_pos)
	elif event is InputEventScreenTouch and event.pressed:
		var offset_pos: Vector2 = event.position - Vector2(0, 50)
		_handle_pointer_position(offset_pos)

func set_layer(layer_plate: int) -> void:
	current_layer_plate = clampi(layer_plate, 0, PlacementRules.MAX_LAYER_PLATES)
	_validate_and_update_ghost()

func _handle_pointer_position(screen_pos: Vector2) -> void:
	var cam: Camera3D = camera_rig.camera
	if not cam:
		return
	
	var from: Vector3 = cam.project_ray_origin(screen_pos)
	var dir: Vector3 = cam.project_ray_normal(screen_pos)
	
	var plane_y: float = 0.1 + (float(current_layer_plate) * TableView.PLATE_HEIGHT)
	if abs(dir.y) > 0.001:
		var t: float = (plane_y - from.y) / dir.y
		if t > 0:
			var hit_pos: Vector3 = from + dir * t
			var p_def: Dictionary = catalog.get_part(selected_part_id)
			var dims: Array = p_def.get("dimensions_studs", [1, 3, 1])
			var new_grid: Vector2i = TableView.world_to_grid(hit_pos, dims, current_rotation_step)
			if new_grid != current_grid_pos:
				current_grid_pos = new_grid
				_validate_and_update_ghost()

func _on_rotate_left() -> void:
	current_rotation_step = (current_rotation_step - 1 + 4) % 4
	_validate_and_update_ghost()

func _on_rotate_right() -> void:
	current_rotation_step = (current_rotation_step + 1) % 4
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
	
	# Update UI feedback text (non-color accessibility cues)
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
		label_coords.text = "Stud: (%d, %d) | Plate: %d | Yaw: %d°  " % [
			current_grid_pos.x, current_grid_pos.y, current_layer_plate, current_rotation_step * 90
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
	
	# Automatically adjust layer to piece top if user desires stacking
	var dims: Array = p_def.get("dimensions_studs", [1, 3, 1])
	current_layer_plate = current_layer_plate + int(dims[1])
	
	_validate_and_update_ghost()
