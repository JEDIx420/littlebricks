extends Node3D
class_name CameraController

## Smooth orbit, pan, and zoom camera controller for LittleBricks tabletop view.
## Supports desktop mouse/trackpad/keyboard, dedicated Camera Mode, and mobile multi-touch gestures.

@export var target: Vector3 = Vector3(0, 0.5, 0)
@export var distance: float = 24.0
@export var min_distance: float = 6.0
@export var max_distance: float = 45.0
@export var pitch: float = -38.0 # degrees
@export var yaw: float = 45.0   # degrees

@onready var camera: Camera3D = $Camera3D

var is_camera_mode: bool = false
var _is_orbiting: bool = false
var _is_panning: bool = false
var _last_mouse_pos: Vector2 = Vector2.ZERO

# Touch gesture tracking
var _touches: Dictionary = {}
var _touch_start_dist: float = 0.0
var _camera_start_dist: float = 0.0
var _last_centroid: Vector2 = Vector2.ZERO

func _ready() -> void:
	if not camera:
		camera = get_node_or_null("Camera3D")
	_update_transform()

func _input(event: InputEvent) -> void:
	# Desktop Mouse / Trackpad Handling
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		var shift_pressed: bool = mb.shift_pressed
		
		# Right button: orbit (or pan if Shift held)
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			if mb.pressed:
				_last_mouse_pos = mb.position
				if shift_pressed:
					_is_panning = true
					_is_orbiting = false
				else:
					_is_orbiting = true
					_is_panning = false
			else:
				_is_orbiting = false
				_is_panning = false
				
		# Middle button: always pan
		elif mb.button_index == MOUSE_BUTTON_MIDDLE:
			if mb.pressed:
				_is_panning = true
				_is_orbiting = false
				_last_mouse_pos = mb.position
			else:
				_is_panning = false
				
		# Left button in dedicated Camera Mode: orbit (or pan if Shift held)
		elif mb.button_index == MOUSE_BUTTON_LEFT and is_camera_mode:
			if mb.pressed:
				_last_mouse_pos = mb.position
				if shift_pressed:
					_is_panning = true
					_is_orbiting = false
				else:
					_is_orbiting = true
					_is_panning = false
			else:
				_is_orbiting = false
				_is_panning = false
				
		# Wheel Zoom
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			zoom_by(-1.5)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			zoom_by(1.5)
	
	elif event is InputEventMouseMotion:
		var mm: InputEventMouseMotion = event
		var delta: Vector2 = mm.position - _last_mouse_pos
		_last_mouse_pos = mm.position
		
		if _is_orbiting:
			orbit_by(-delta.x * 0.4, -delta.y * 0.4)
		elif _is_panning:
			pan_by(delta)
			
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
				_last_centroid = (p1 + p2) * 0.5
			elif _touches.size() == 1 and is_camera_mode:
				_last_mouse_pos = st.position
				_is_orbiting = true
		else:
			_touches.erase(st.index)
			if _touches.is_empty():
				_is_orbiting = false
				_is_panning = false
			
	elif event is InputEventScreenDrag:
		var sd: InputEventScreenDrag = event
		_touches[sd.index] = sd.position
		if _touches.size() == 2:
			# 2-finger gesture: pinch zoom & centroid orbit
			var p1: Vector2 = _touches.values()[0]
			var p2: Vector2 = _touches.values()[1]
			var current_dist: float = p1.distance_to(p2)
			if _touch_start_dist > 5.0:
				var scale_ratio: float = _touch_start_dist / max(1.0, current_dist)
				distance = clamp(_camera_start_dist * scale_ratio, min_distance, max_distance)
				
			var current_centroid: Vector2 = (p1 + p2) * 0.5
			var centroid_delta: Vector2 = current_centroid - _last_centroid
			_last_centroid = current_centroid
			orbit_by(-centroid_delta.x * 0.4, -centroid_delta.y * 0.4)
		elif _touches.size() == 1 and is_camera_mode and _is_orbiting:
			var delta: Vector2 = sd.position - _last_mouse_pos
			_last_mouse_pos = sd.position
			orbit_by(-delta.x * 0.4, -delta.y * 0.4)

	# Keyboard navigation
	elif event is InputEventKey and event.pressed:
		var k = event.keycode
		if event.shift_pressed:
			# Shift + Arrows: Pan
			if k == KEY_LEFT: pan_by(Vector2(-20, 0))
			elif k == KEY_RIGHT: pan_by(Vector2(20, 0))
			elif k == KEY_UP: pan_by(Vector2(0, -20))
			elif k == KEY_DOWN: pan_by(Vector2(0, 20))
		else:
			# Arrows or IJKL: Orbit
			if k == KEY_LEFT: orbit_by(5.0, 0.0)
			elif k == KEY_RIGHT: orbit_by(-5.0, 0.0)
			elif k == KEY_UP: orbit_by(0.0, 4.0)
			elif k == KEY_DOWN: orbit_by(0.0, -4.0)
			elif k == KEY_BRACKETLEFT: zoom_by(-1.5)
			elif k == KEY_BRACKETRIGHT: zoom_by(1.5)

func orbit_by(delta_yaw: float, delta_pitch: float) -> void:
	yaw += delta_yaw
	pitch = clamp(pitch + delta_pitch, -85.0, -10.0)
	_update_transform()

func pan_by(delta_screen: Vector2) -> void:
	var cam_basis: Basis = camera.global_transform.basis if (camera and camera.is_inside_tree()) else Basis()
	var right_dir: Vector3 = cam_basis.x
	var up_dir: Vector3 = cam_basis.y
	# Screen pixels to world translation proportional to distance
	var factor: float = distance * 0.0018
	target -= (right_dir * delta_screen.x - up_dir * delta_screen.y) * factor
	# Keep target on or near the 32x32 table
	target.x = clamp(target.x, -20.0, 20.0)
	target.z = clamp(target.z, -20.0, 20.0)
	target.y = clamp(target.y, 0.0, 15.0)
	_update_transform()

func zoom_by(delta_dist: float) -> void:
	distance = clamp(distance + delta_dist, min_distance, max_distance)
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

func frame_build(min_pos: Vector3, max_pos: Vector3) -> void:
	target = (min_pos + max_pos) * 0.5
	var extent_x = max_pos.x - min_pos.x
	var extent_z = max_pos.z - min_pos.z
	var max_extent = max(extent_x, extent_z, 4.0)
	distance = clamp(max_extent * 2.2, min_distance, max_distance)
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
