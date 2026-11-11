extends Node3D
class_name CameraController

## Smooth orbit, pan, and zoom camera controller for LittleBricks tabletop view.
## Supports both desktop mouse/keyboard and mobile multi-touch gestures.

@export var target: Vector3 = Vector3(0, 0.5, 0)
@export var distance: float = 24.0
@export var min_distance: float = 6.0
@export var max_distance: float = 45.0
@export var pitch: float = -38.0 # degrees
@export var yaw: float = 45.0   # degrees

@onready var camera: Camera3D = $Camera3D

var _is_orbiting: bool = false
var _last_mouse_pos: Vector2 = Vector2.ZERO

# Touch gesture tracking
var _touches: Dictionary = {}
var _touch_start_dist: float = 0.0
var _camera_start_dist: float = 0.0

func _ready() -> void:
	_update_transform()

func _input(event: InputEvent) -> void:
	# Desktop Mouse Handling
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
		
	# Touch & Gesture Handling (Mobile 2-finger orbit and pinch-zoom)
	elif event is InputEventScreenTouch:
		var st: InputEventScreenTouch = event
		if st.pressed:
			_touches[st.index] = st.position
			if _touches.size() == 2:
				var p1: Vector2 = _touches.values()[0]
				var p2: Vector2 = _touches.values()[1]
				_touch_start_dist = p1.distance_to(p2)
				_camera_start_dist = distance
		else:
			_touches.erase(st.index)
			
	elif event is InputEventScreenDrag:
		var sd: InputEventScreenDrag = event
		_touches[sd.index] = sd.position
		if _touches.size() == 2:
			# 2-finger gesture: pinch zoom & orbit
			var p1: Vector2 = _touches.values()[0]
			var p2: Vector2 = _touches.values()[1]
			var current_dist: float = p1.distance_to(p2)
			if _touch_start_dist > 5.0:
				var scale_ratio: float = _touch_start_dist / max(1.0, current_dist)
				distance = clamp(_camera_start_dist * scale_ratio, min_distance, max_distance)
				_update_transform()

func set_top_view() -> void:
	yaw = 0.0
	pitch = -88.0
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
	
	position = target + offset
	if is_inside_tree():
		look_at(target, Vector3.UP)
