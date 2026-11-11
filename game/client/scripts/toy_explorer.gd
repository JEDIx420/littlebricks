extends CharacterBody3D
class_name ToyExplorer

## The explorer walks relative to the current view. Third-person look orbits the
## figure while first-person look turns the figure and camera together.

enum CameraMode { THIRD_PERSON, FIRST_PERSON }

signal camera_mode_changed(mode: CameraMode)

@export var walk_speed: float = 6.0
@export var gravity: float = 18.0

var camera_mode: CameraMode = CameraMode.THIRD_PERSON
var spawn_position: Vector3 = Vector3.ZERO

@onready var visual_mesh: Node3D = $VisualMesh
@onready var first_person_cam: Camera3D = %FirstPersonCam
@onready var third_person_cam: Camera3D = %ThirdPersonCam
@onready var spring_arm: SpringArm3D = %SpringArm3D

var _mouse_look_active: bool = false
var _touch_look_index: int = -1
var _input_direction: Vector2 = Vector2.ZERO
var _spawn_yaw: float = 0.0
var _default_arm_pitch: float = 0.0
var _default_eye_pitch: float = 0.0
var _walk_time: float = 0.0

func _ready() -> void:
	remember_spawn()
	if spring_arm:
		spring_arm.add_excluded_object(get_rid())
		_default_arm_pitch = spring_arm.rotation.x
	if first_person_cam:
		_default_eye_pitch = first_person_cam.rotation.x
	set_camera_mode(CameraMode.THIRD_PERSON)

func remember_spawn() -> void:
	spawn_position = position
	_spawn_yaw = rotation.y

func set_camera_mode(mode: CameraMode) -> void:
	if not first_person_cam or not third_person_cam or not visual_mesh:
		camera_mode = mode
		return
	if mode == CameraMode.FIRST_PERSON:
		# Preserve the direction the player is looking when changing cameras.
		rotation.y += spring_arm.rotation.y
		spring_arm.rotation.y = 0.0
		visual_mesh.rotation.y = 0.0
		first_person_cam.make_current()
	else:
		third_person_cam.make_current()
	visual_mesh.visible = mode == CameraMode.THIRD_PERSON
	camera_mode = mode
	camera_mode_changed.emit(camera_mode)

func toggle_camera_mode() -> void:
	set_camera_mode(CameraMode.THIRD_PERSON if camera_mode == CameraMode.FIRST_PERSON else CameraMode.FIRST_PERSON)

func reset_to_spawn() -> void:
	position = spawn_position
	rotation.y = _spawn_yaw
	velocity = Vector3.ZERO
	if visual_mesh:
		visual_mesh.rotation.y = 0.0
	if first_person_cam:
		first_person_cam.rotation.x = _default_eye_pitch
	if spring_arm:
		spring_arm.rotation = Vector3(_default_arm_pitch, 0, 0)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_mouse_look_active = false
		_touch_look_index = -1
		_input_direction = Vector2.ZERO

func _input(event: InputEvent) -> void:
	# A drag can be released over a HUD control. Release capture before GUI dispatch.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
		_mouse_look_active = false
	elif event is InputEventScreenTouch and event.index == _touch_look_index and not event.pressed:
		_touch_look_index = -1

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_V:
			toggle_camera_mode()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_R:
			reset_to_spawn()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_mouse_look_active = true
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _mouse_look_active:
		_look(event.relative)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and event.pressed and _touch_look_index == -1:
		_touch_look_index = event.index
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index == _touch_look_index:
		_look(event.relative)
		get_viewport().set_input_as_handled()

func _look(relative: Vector2) -> void:
	if camera_mode == CameraMode.FIRST_PERSON:
		rotate_y(-relative.x * 0.005)
		first_person_cam.rotation.x = clampf(first_person_cam.rotation.x - relative.y * 0.005, -1.2, 1.2)
	else:
		spring_arm.rotation.y = wrapf(spring_arm.rotation.y - relative.x * 0.005, -PI, PI)
		spring_arm.rotation.x = clampf(spring_arm.rotation.x - relative.y * 0.005, -1.12, 0.05)

func _physics_process(delta: float) -> void:
	if position.y < -8.0:
		reset_to_spawn()
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = -0.1

	var movement := Vector2(
		Input.get_axis("ui_left", "ui_right") + float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
		Input.get_axis("ui_up", "ui_down") + float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
	).limit_length()
	if _input_direction.length_squared() > 0.01:
		movement = _input_direction
	var view_yaw := spring_arm.rotation.y if camera_mode == CameraMode.THIRD_PERSON else 0.0
	var local_dir := Vector3(movement.x, 0, movement.y).rotated(Vector3.UP, view_yaw)
	var direction := transform.basis * local_dir
	velocity.x = move_toward(velocity.x, direction.x * walk_speed, walk_speed * delta * 10.0)
	velocity.z = move_toward(velocity.z, direction.z * walk_speed, walk_speed * delta * 10.0)

	if camera_mode == CameraMode.THIRD_PERSON and movement.length_squared() > 0.015:
		var heading := atan2(-local_dir.x, -local_dir.z)
		visual_mesh.rotation.y = lerp_angle(visual_mesh.rotation.y, heading, minf(1.0, delta * 15.0))
	move_and_slide()

	var ground_velocity := get_real_velocity()
	var stride := minf(Vector2(ground_velocity.x, ground_velocity.z).length() / walk_speed, 1.0)
	_walk_time += delta * 12.0 * stride
	visual_mesh.position.y = move_toward(visual_mesh.position.y, absf(sin(_walk_time)) * 0.065 * stride, delta)
	visual_mesh.animate_walk(_walk_time, stride, delta)

func set_virtual_input(direction: Vector2) -> void:
	_input_direction = direction.limit_length()
