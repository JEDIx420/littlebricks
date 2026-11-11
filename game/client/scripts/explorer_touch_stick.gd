extends Control

## Floating-looking analog controller pinned to the lower left of the Explorer HUD.

signal direction_changed(direction: Vector2)

const TRAVEL: float = 43.0

var _touch_index: int = -1
var _direction := Vector2.ZERO

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_release()

func _draw() -> void:
	var center := size * 0.5
	draw_circle(center, 66.0, Color("#292a21dc"))
	draw_arc(center, 64.0, 0, TAU, 64, Color("#f1dfb8bd"), 2, true)
	for axis in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]:
		draw_line(center + axis * 54, center + axis * 60, Color("#f1dfb8bd"), 2, true)
	var thumb := center + _direction * TRAVEL
	draw_circle(thumb + Vector2(0, 4), 25.0, Color("#2a231e60"))
	draw_circle(thumb, 25.0, Color("#f1dfb8"))
	draw_arc(thumb, 20.0, 0, TAU, 40, Color("#c8a978"), 1, true)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed and _touch_index == -1:
		_touch_index = event.index
		_update_direction(event.position)
		accept_event()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenDrag and event.index == _touch_index:
		_update_direction(get_global_transform_with_canvas().affine_inverse() * event.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and event.index == _touch_index and not event.pressed:
		_release()
		get_viewport().set_input_as_handled()

func _update_direction(local_position: Vector2) -> void:
	_direction = ((local_position - size * 0.5) / TRAVEL).limit_length()
	direction_changed.emit(_direction)
	queue_redraw()

func _release() -> void:
	if _touch_index == -1:
		return
	_touch_index = -1
	_direction = Vector2.ZERO
	direction_changed.emit(Vector2.ZERO)
	queue_redraw()
