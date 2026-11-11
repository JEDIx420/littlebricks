extends Node3D
class_name CameraController

## Smooth orbit, pan, and zoom camera controller for LittleBricks tabletop view.

@export var target: Vector3 = Vector3(0, 0.5, 0)
@export var distance: float = 24.0
@export var min_distance: float = 6.0
@export var max_distance: float = 45.0
@export var pitch: float = -38.0 # degrees
@export var yaw: float = 45.0   # degrees

@onready var camera: Camera3D = $Camera3D

var _is_orbiting: bool = false
var _is_panning: bool = false
var _last_mouse_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	_update_transform()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_RIGHT or mb.button_index == MOUSE_BUTTON_MIDDLE:
			if mb.pressed:
				_is_orbiting = true
				_last_mouse_pos = mb.position
			else:
				_is_orbiting = false
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			distance = clamp(distance - 1.5, min_distance, max_distance)
			_update_transform()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			distance = clamp(distance + 1.5, min_distance, max_distance)
			_update_transform()
	
	elif event is InputEventMouseMotion and _is_orbiting:
		var mm: InputEventMouseMotion = event
		var delta: Vector2 = mm.position - _last_mouse_pos
		_last_mouse_pos = mm.position
		
		yaw -= delta.x * 0.4
		pitch = clamp(pitch - delta.y * 0.4, -85.0, -10.0)
		_update_transform()

func set_top_view() -> void:
	yaw = 0.0
	pitch = -89.0
	_update_transform()

func set_default_view() -> void:
	target = Vector3(0, 0.5, 0)
	distance = 24.0
	pitch = -38.0
	yaw = 45.0
	_update_transform()

func _update_transform() -> void:
	var yaw_rad: float = deg_to_rad(yaw)
	var pitch_rad: float = deg_to_rad(pitch)
	
	var offset: Vector3 = Vector3(
		sin(yaw_rad) * cos(pitch_rad),
		-sin(pitch_rad),
		cos(yaw_rad) * cos(pitch_rad)
	) * distance
	
	global_position = target + offset
	look_at(target, Vector3.UP)
