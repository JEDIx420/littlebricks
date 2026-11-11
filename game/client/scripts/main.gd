extends Node3D

## Main scene controller for LittleBricks client.
## Handles UI interaction, camera, ghost brick preview, and user inputs.

const CameraController = preload("res://client/scripts/camera_controller.gd")
const TableView = preload("res://client/scripts/table_view.gd")

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

var current_rotation_step: int = 0 # 0, 1, 2, 3 representing 0, 90, 180, 270 degrees
var current_grid_pos: Vector2i = Vector2i(16, 16)
var current_layer: int = 0 # in plates
var selected_part_id: String = "brick_2x4"
var selected_color: Color = Color(0.85, 0.15, 0.15) # Classic red brick

var _ghost_mesh: MeshInstance3D

func _ready() -> void:
	_setup_ghost()
	_connect_ui()
	_setup_inventory_tray()
	_update_ghost_transform()
	_update_status("Select piece and target grid. Press Place or Space/Enter.")

func _setup_ghost() -> void:
	_ghost_mesh = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(2.0, 1.2, 4.0) # 2x4 brick default
	_ghost_mesh.mesh = box
	
	var ghost_mat: StandardMaterial3D = StandardMaterial3D.new()
	ghost_mat.albedo_color = Color(selected_color.r, selected_color.g, selected_color.b, 0.65)
	ghost_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ghost_mat.roughness = 0.3
	_ghost_mesh.material_override = ghost_mat
	
	ghost_preview.add_child(_ghost_mesh)

func _connect_ui() -> void:
	btn_rotate_left.pressed.connect(_on_rotate_left)
	btn_rotate_right.pressed.connect(_on_rotate_right)
	btn_place.pressed.connect(_on_place_pressed)
	btn_top_view.pressed.connect(camera_rig.set_top_view)
	btn_reset_view.pressed.connect(camera_rig.set_default_view)

func _setup_inventory_tray() -> void:
	# Clear sample children
	for child in tray_container.get_children():
		child.queue_free()
		
	var sample_pieces = [
		{"id": "brick_2x4", "name": "2x4 Red", "color": Color(0.85, 0.15, 0.15), "size": Vector3(2.0, 1.2, 4.0)},
		{"id": "brick_2x2", "name": "2x2 Blue", "color": Color(0.15, 0.35, 0.85), "size": Vector3(2.0, 1.2, 2.0)},
		{"id": "brick_1x4", "name": "1x4 Yellow", "color": Color(0.9, 0.75, 0.1), "size": Vector3(1.0, 1.2, 4.0)},
		{"id": "brick_2x3", "name": "2x3 White", "color": Color(0.92, 0.92, 0.92), "size": Vector3(2.0, 1.2, 3.0)},
		{"id": "plate_2x4", "name": "2x4 Green", "color": Color(0.15, 0.65, 0.25), "size": Vector3(2.0, 0.4, 4.0)},
		{"id": "tile_2x2",  "name": "2x2 Orange", "color": Color(0.95, 0.45, 0.1), "size": Vector3(2.0, 0.4, 2.0)}
	]
	
	for piece in sample_pieces:
		var btn: Button = Button.new()
		btn.text = piece["name"]
		btn.custom_minimum_size = Vector2(80, 48)
		btn.pressed.connect(func(): _select_piece(piece))
		tray_container.add_child(btn)

func _select_piece(piece: Dictionary) -> void:
	selected_part_id = piece["id"]
	selected_color = piece["color"]
	var box: BoxMesh = _ghost_mesh.mesh as BoxMesh
	if box:
		box.size = piece["size"]
	var mat: StandardMaterial3D = _ghost_mesh.material_override as StandardMaterial3D
	if mat:
		mat.albedo_color = Color(selected_color.r, selected_color.g, selected_color.b, 0.65)
	_update_ghost_transform()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("rotate_left"):
		_on_rotate_left()
	elif event.is_action_pressed("rotate_right"):
		_on_rotate_right()
	elif event.is_action_pressed("place"):
		_on_place_pressed()
	
	if event is InputEventMouseMotion:
		_handle_mouse_pointer(event.position)

func _handle_mouse_pointer(screen_pos: Vector2) -> void:
	var cam: Camera3D = camera_rig.camera
	if not cam:
		return
	
	var from: Vector3 = cam.project_ray_origin(screen_pos)
	var dir: Vector3 = cam.project_ray_normal(screen_pos)
	
	# Intersect with table plane Y = 0.1
	var plane_y: float = 0.1 + (float(current_layer) * TableView.PLATE_HEIGHT)
	if abs(dir.y) > 0.001:
		var t: float = (plane_y - from.y) / dir.y
		if t > 0:
			var hit_pos: Vector3 = from + dir * t
			current_grid_pos = TableView.world_to_grid(hit_pos)
			_update_ghost_transform()

func _on_rotate_left() -> void:
	current_rotation_step = (current_rotation_step - 1 + 4) % 4
	_update_ghost_transform()

func _on_rotate_right() -> void:
	current_rotation_step = (current_rotation_step + 1) % 4
	_update_ghost_transform()

func _update_ghost_transform() -> void:
	var world_pos: Vector3 = TableView.grid_to_world(current_grid_pos.x, current_grid_pos.y, current_layer)
	var box: BoxMesh = _ghost_mesh.mesh as BoxMesh
	var height_offset: float = (box.size.y * 0.5) if box else 0.6
	ghost_preview.position = Vector3(world_pos.x, world_pos.y + height_offset, world_pos.z)
	ghost_preview.rotation_degrees = Vector3(0, float(current_rotation_step) * 90.0, 0)
	
	label_coords.text = "Stud: (%d, %d) | Layer: %d | Yaw: %d°" % [
		current_grid_pos.x, current_grid_pos.y, current_layer, current_rotation_step * 90
	]

func _on_place_pressed() -> void:
	# Instantiate permanent placed brick mesh
	var placed: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	var ghost_box: BoxMesh = _ghost_mesh.mesh as BoxMesh
	box.size = ghost_box.size if ghost_box else Vector3(2.0, 1.2, 4.0)
	placed.mesh = box
	
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = selected_color
	mat.roughness = 0.3
	placed.material_override = mat
	
	placed.position = ghost_preview.position
	placed.rotation = ghost_preview.rotation
	placed_bricks_container.add_child(placed)
	
	_update_status("Placed %s at (%d, %d)" % [selected_part_id, current_grid_pos.x, current_grid_pos.y])

func _update_status(msg: String) -> void:
	if label_status:
		label_status.text = msg
