extends Node3D
class_name CameraController

## Smooth orbit, pan, and zoom camera controller for LittleBricks tabletop view (LB-069).
## Supports desktop mouse/trackpad/keyboard, dedicated Camera Modes (Build, Orbit, Pan),
## and mobile multi-touch gestures without accidental piece placement.

enum InteractionMode {
	BUILD,   ## Default building: left-click places; right-drag orbits; middle/shift+right pans
	ORBIT,   ## Left-drag orbits; right-drag orbits; middle/shift+right pans
	PAN      ## Left-drag pans; middle-drag pans; right-drag orbits
}

signal mode_changed(mode: InteractionMode, mode_name: String)

@export var target: Vector3 = Vector3(0, 0.5, 0)
@export var distance: float = 24.0
@export var min_distance: float = 6.0
@export var max_distance: float = 48.0
@export var pitch: float = -38.0 # degrees
@export var yaw: float = 45.0   # degrees
@export var room_distance: float = 24.0
@export var room_pitch: float = -38.0
@export var room_yaw: float = 45.0
@export var plate_distance: float = 24.0
@export var plate_pitch: float = -38.0
@export var plate_yaw: float = 45.0
@export var room_bounds: AABB

@onready var camera: Camera3D = $Camera3D

var interaction_mode: InteractionMode = InteractionMode.BUILD:
	set(val):
		interaction_mode = val
		mode_changed.emit(interaction_mode, get_mode_name())

var is_camera_mode: bool:
	get: return interaction_mode != InteractionMode.BUILD
	set(val):
		interaction_mode = InteractionMode.ORBIT if val else InteractionMode.BUILD

var is_input_enabled: bool = true

var is_orbiting: bool:
	get: return _is_orbiting

var is_panning: bool:
	get: return _is_panning

var is_gesture_active: bool:
	get: return _is_orbiting or _is_panning or _touches.size() >= 2

var _is_orbiting: bool = false
var _is_panning: bool = false
var _last_mouse_pos: Vector2 = Vector2.ZERO
var _drag_button: MouseButton = MOUSE_BUTTON_NONE

# Touch gesture tracking
var _touches: Dictionary = {}
var _touch_start_dist: float = 0.0
var _camera_start_dist: float = 0.0
var _last_centroid: Vector2 = Vector2.ZERO

func _ready() -> void:
	if not camera:
		camera = get_node_or_null("Camera3D")
	var viewport := get_viewport()
	if room_bounds.has_volume() and viewport:
		if not viewport.size_changed.is_connected(_update_aspect):
			viewport.size_changed.connect(_update_aspect)
		_update_aspect()
	_update_transform()

func _update_aspect() -> void:
	if camera:
		var view := get_viewport().get_visible_rect().size
		camera.keep_aspect = Camera3D.KEEP_WIDTH if view.x < view.y else Camera3D.KEEP_HEIGHT

func get_mode_name() -> String:
	match interaction_mode:
		InteractionMode.BUILD: return "Build"
		InteractionMode.ORBIT: return "Orbit"
		InteractionMode.PAN: return "Pan"
	return "Build"

func cycle_camera_mode() -> InteractionMode:
	match interaction_mode:
		InteractionMode.BUILD:
			interaction_mode = InteractionMode.ORBIT
		InteractionMode.ORBIT:
			interaction_mode = InteractionMode.PAN
		InteractionMode.PAN:
			interaction_mode = InteractionMode.BUILD
	return interaction_mode

func reset_gesture_state() -> void:
	_end_pointer_drag()
	_touches.clear()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		reset_gesture_state()

func _end_pointer_drag() -> void:
	_drag_button = MOUSE_BUTTON_NONE
	_is_orbiting = false
	_is_panning = false

func _input(event: InputEvent) -> void:
	# Release a world-owned gesture even when the pointer ends over the HUD.
	if event is InputEventMouseButton and not event.pressed and event.button_index == _drag_button:
		_end_pointer_drag()
	elif event is InputEventMouseMotion and _drag_button != MOUSE_BUTTON_NONE and is_input_enabled:
		if event.device != InputEvent.DEVICE_ID_EMULATION:
			_drag_view(_last_mouse_pos, event.position, _is_panning)
			_last_mouse_pos = event.position
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and not event.pressed and _touches.has(event.index):
		_touches.erase(event.index)
		if _touches.is_empty():
			_end_pointer_drag()
		elif _touches.size() == 1:
			_last_mouse_pos = _touches.values()[0]
		elif _touches.size() == 2:
			_start_pinch()

func _unhandled_input(event: InputEvent) -> void:
	if not is_input_enabled:
		return

	if event is InputEventMouseButton:
		if not event.pressed or event.device == InputEvent.DEVICE_ID_EMULATION:
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var direction := -1.0 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0
			_zoom_at(event.position, distance * direction * 0.09)
			get_viewport().set_input_as_handled()
			return
		var is_left_camera: bool = event.button_index == MOUSE_BUTTON_LEFT and is_camera_mode
		if _drag_button != MOUSE_BUTTON_NONE or _touches.size() > 0:
			return
		if not is_left_camera and event.button_index != MOUSE_BUTTON_RIGHT and event.button_index != MOUSE_BUTTON_MIDDLE:
			return
		_drag_button = event.button_index
		_last_mouse_pos = event.position
		_is_panning = event.button_index == MOUSE_BUTTON_MIDDLE or event.shift_pressed or (is_left_camera and interaction_mode == InteractionMode.PAN)
		_is_orbiting = not _is_panning
		get_viewport().set_input_as_handled()
	elif event is InputEventMagnifyGesture:
		_zoom_at(event.position, distance / maxf(event.factor, 0.01) - distance)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and event.pressed:
		_touches[event.index] = event.position
		if _touches.size() == 1 and is_camera_mode:
			_last_mouse_pos = event.position
			_is_panning = interaction_mode == InteractionMode.PAN
			_is_orbiting = not _is_panning
		elif _touches.size() == 2:
			_start_pinch()
	elif event is InputEventScreenDrag and _touches.has(event.index):
		_touches[event.index] = event.position
		if _touches.size() == 2:
			_update_pinch()
		elif _touches.size() == 1 and is_camera_mode:
			_drag_view(_last_mouse_pos, event.position, interaction_mode == InteractionMode.PAN)
			_last_mouse_pos = event.position

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
			# Arrows: Orbit
			if k == KEY_LEFT: orbit_by(5.0, 0.0)
			elif k == KEY_RIGHT: orbit_by(-5.0, 0.0)
			elif k == KEY_UP: orbit_by(0.0, 4.0)
			elif k == KEY_DOWN: orbit_by(0.0, -4.0)
			elif k == KEY_BRACKETLEFT or k == KEY_MINUS: zoom_by(1.5)
			elif k == KEY_BRACKETRIGHT or k == KEY_EQUAL: zoom_by(-1.5)
			elif k == KEY_F: frame_plate()
			elif k == KEY_HOME: set_default_view()

func _start_pinch() -> void:
	var first: Vector2 = _touches.values()[0]
	var second: Vector2 = _touches.values()[1]
	_touch_start_dist = first.distance_to(second)
	_camera_start_dist = distance
	_last_centroid = (first + second) * 0.5

func _update_pinch() -> void:
	var first: Vector2 = _touches.values()[0]
	var second: Vector2 = _touches.values()[1]
	var centroid := (first + second) * 0.5
	_drag_view(_last_centroid, centroid, interaction_mode != InteractionMode.ORBIT)
	if _touch_start_dist > 5.0:
		var desired := _camera_start_dist * _touch_start_dist / maxf(1.0, first.distance_to(second))
		_zoom_at(centroid, desired - distance)
	_last_centroid = centroid

func _drag_view(previous: Vector2, current: Vector2, pan: bool) -> void:
	var delta := current - previous
	if not pan:
		orbit_by(-delta.x * 0.28, -delta.y * 0.28)
		return
	var before: Variant = _table_hit(previous)
	var after: Variant = _table_hit(current)
	if before is Vector3 and after is Vector3:
		_shift_target(before - after)
	else:
		pan_by(delta)

func _table_hit(screen_point: Vector2) -> Variant:
	if camera == null or not camera.is_inside_tree():
		return null
	var plane := Plane(Vector3.UP, 0.5)
	return plane.intersects_ray(camera.project_ray_origin(screen_point), camera.project_ray_normal(screen_point))

func _zoom_at(screen_point: Vector2, delta: float) -> void:
	var before: Variant = _table_hit(screen_point)
	zoom_by(delta)
	var after: Variant = _table_hit(screen_point)
	if before is Vector3 and after is Vector3:
		_shift_target(before - after)

func orbit_by(delta_yaw: float, delta_pitch: float) -> void:
	yaw += delta_yaw
	pitch = clamp(pitch + delta_pitch, -85.0, -10.0)
	_update_transform()

func pan_by(delta_screen: Vector2) -> void:
	var cam_basis: Basis = camera.global_transform.basis if (camera and camera.is_inside_tree()) else Basis()
	# For planar tabletop panning, project screen motions onto horizontal tabletop plane
	var forward_planar: Vector3 = Vector3(-cam_basis.z.x, 0, -cam_basis.z.z).normalized()
	var right_planar: Vector3 = Vector3(cam_basis.x.x, 0, cam_basis.x.z).normalized()
	
	var factor: float = distance * 0.0022
	_shift_target(-(right_planar * delta_screen.x - forward_planar * delta_screen.y) * factor)

func _shift_target(delta: Vector3) -> void:
	target += delta
	# Keep target bounded on tabletop
	target.x = clamp(target.x, -25.0, 25.0)
	target.z = clamp(target.z, -25.0, 25.0)
	target.y = 0.5
	_update_transform()

func zoom_by(delta_dist: float) -> void:
	distance = clamp(distance + delta_dist, min_distance, max_distance)
	_update_transform()

func set_top_view() -> void:
	target = Vector3(0, 0.5, 0)
	distance = plate_distance
	yaw = 0.0
	pitch = -88.0
	_update_transform()

func set_default_view() -> void:
	target = Vector3(0, 0.5, 0)
	distance = room_distance
	pitch = room_pitch
	yaw = room_yaw
	_update_transform()

func frame_plate() -> void:
	target = Vector3(0, 0.5, 0)
	distance = plate_distance
	pitch = plate_pitch
	yaw = plate_yaw
	_update_transform()

func recenter_on(world_pos: Vector3) -> void:
	target = Vector3(clamp(world_pos.x, -20.0, 20.0), 0.5, clamp(world_pos.z, -20.0, 20.0))
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
	)
	var visible_distance := distance
	if room_bounds.has_volume():
		# Keep the camera inside the walls and ceiling when framing tall builds.
		for axis in [Vector3.AXIS_X, Vector3.AXIS_Y, Vector3.AXIS_Z]:
			if absf(offset[axis]) > 0.001:
				var wall := room_bounds.end[axis] if offset[axis] > 0.0 else room_bounds.position[axis]
				visible_distance = minf(visible_distance, (wall - target[axis]) / offset[axis])
	position = target + offset * visible_distance
	if is_inside_tree() and camera:
		camera.look_at(target, Vector3.UP)
