extends CharacterBody3D
class_name ToyExplorer

## Toy-sized character controller for LittleBricks miniature world exploration (LB-014).
## Supports first-person and third-person camera perspectives with touch and desktop controls.

enum CameraMode { THIRD_PERSON, FIRST_PERSON }

@export var walk_speed: float = 6.0
@export var turn_speed: float = 2.5
@export var gravity: float = 18.0

var camera_mode: CameraMode = CameraMode.THIRD_PERSON
var spawn_position: Vector3 = Vector3.ZERO

@onready var visual_mesh: Node3D = $VisualMesh
@onready var first_person_cam: Camera3D = %FirstPersonCam
@onready var third_person_cam: Camera3D = %ThirdPersonCam
@onready var spring_arm: SpringArm3D = %SpringArm3D

var _mouse_look_active: bool = false
var _input_direction: Vector2 = Vector2.ZERO # x=horizontal, y=forward/back
var _walk_time: float = 0.0

func _ready() -> void:
	spawn_position = position
	set_camera_mode(CameraMode.THIRD_PERSON)

func set_camera_mode(mode: CameraMode) -> void:
	camera_mode = mode
	if not first_person_cam or not third_person_cam or not visual_mesh:
		return
	if camera_mode == CameraMode.FIRST_PERSON:
		first_person_cam.current = true
		third_person_cam.current = false
		visual_mesh.visible = false # Don't clip through character's own head in 1st person
	else:
		first_person_cam.current = false
		third_person_cam.current = true
		visual_mesh.visible = true

func toggle_camera_mode() -> void:
	if camera_mode == CameraMode.FIRST_PERSON:
		set_camera_mode(CameraMode.THIRD_PERSON)
	else:
		set_camera_mode(CameraMode.FIRST_PERSON)

func reset_to_spawn() -> void:
	position = spawn_position
	velocity = Vector3.ZERO

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_V:
			toggle_camera_mode()
		elif event.keycode == KEY_R:
			reset_to_spawn()
			
	# Desktop mouse look in first-person or third-person when RMB is held
	if event is InputEventMouseButton:
		var mb = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			_mouse_look_active = mb.pressed
	elif event is InputEventMouseMotion and _mouse_look_active:
		var mm = event as InputEventMouseMotion
		rotate_y(-mm.relative.x * 0.005)
		if camera_mode == CameraMode.FIRST_PERSON:
			first_person_cam.rotate_x(-mm.relative.y * 0.005)
			first_person_cam.rotation.x = clamp(first_person_cam.rotation.x, -1.2, 1.2)
		else:
			spring_arm.rotate_x(-mm.relative.y * 0.005)
			spring_arm.rotation.x = clamp(spring_arm.rotation.x, -1.2, 0.4)

func _physics_process(delta: float) -> void:
	# 1. Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = -0.1
		
	# 2. Collect movement inputs (keyboard / on-screen virtual stick)
	var move_x: float = Input.get_axis("ui_left", "ui_right")
	var move_z: float = Input.get_axis("ui_up", "ui_down")
	
	# Combine with virtual touch stick if present
	if _input_direction.length_squared() > 0.01:
		move_x = _input_direction.x
		move_z = _input_direction.y
		
	var input_vec: Vector3 = (transform.basis * Vector3(move_x, 0, move_z)).normalized()
	
	if input_vec.length_squared() > 0.01:
		velocity.x = input_vec.x * walk_speed
		velocity.z = input_vec.z * walk_speed
		
		# Gentle bobbing walk animation
		_walk_time += delta * 12.0
		visual_mesh.position.y = abs(sin(_walk_time)) * 0.15
		visual_mesh.rotation.z = sin(_walk_time * 0.5) * 0.08
	else:
		velocity.x = move_toward(velocity.x, 0, walk_speed * delta * 8.0)
		velocity.z = move_toward(velocity.z, 0, walk_speed * delta * 8.0)
		visual_mesh.position.y = 0.0
		visual_mesh.rotation.z = 0.0
		
	# Move character with smooth floor snapping
	move_and_slide()

## Virtual touch stick input hook for mobile screens
func set_virtual_input(dir: Vector2) -> void:
	_input_direction = dir
