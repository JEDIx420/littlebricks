extends Node3D
class_name WorkshopDog

## Decorative local actor. Its loop lives on a clear strip around the table and
## does not participate in placement, multiplayer, picking, or explorer collision.
const MODEL := preload("res://assets/sourced/quaternius_dog/workshop_dog.glb")
const LOOP := [
	Vector2(36, 24), Vector2(43, 12), Vector2(40, -7),
	Vector2(33, -24), Vector2(14, -30), Vector2(-10, -30),
	Vector2(-33, -29), Vector2(-36, -11), Vector2(-36, 10),
	Vector2(-34, 26), Vector2(-16, 28), Vector2(5, 32), Vector2(24, 32),
]
const ACTIONS := {
	0: {"clip": &"Idle_2_HeadLow", "duration": 2.6},
	3: {"clip": &"Idle", "duration": 1.6},
	11: {"clip": &"Idle_2_HeadLow", "duration": 2.1},
}

var _animation: AnimationPlayer
var _route := Curve3D.new()
var _stops: PackedFloat32Array
var _target := 1
var _wait := 1.8
var _distance := 0.0
var _speed := 0.0
var _gallop := false
var _random := RandomNumberGenerator.new()
var _clip: StringName
var _floor_y := 0.0

func _ready() -> void:
	_random.randomize()
	_route.bake_interval = 0.18
	for i in range(LOOP.size() + 1):
		var index := i % LOOP.size()
		var current: Vector2 = LOOP[index]
		var previous: Vector2 = LOOP[posmod(index - 1, LOOP.size())]
		var next: Vector2 = LOOP[(index + 1) % LOOP.size()]
		var tangent := (next - previous).normalized() * minf(current.distance_to(previous), current.distance_to(next)) * 0.29
		_route.add_point(Vector3(current.x, 0, current.y), Vector3(-tangent.x, 0, -tangent.y), Vector3(tangent.x, 0, tangent.y))
	for spot: Vector2 in LOOP:
		_stops.append(_route.get_closest_offset(Vector3(spot.x, 0, spot.y)))
	_stops.append(_route.get_baked_length())

	var model := MODEL.instantiate() as Node3D
	model.name = "DogModel"
	model.scale = Vector3.ONE * 2.70
	model.position.y = -0.01
	add_child(model)
	_animation = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if _animation:
		for clip in [&"Idle", &"Idle_2_HeadLow", &"Walk", &"Gallop"]:
			_animation.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	_floor_y = position.y
	_place_on_route()
	rotation.y = _facing()
	_play(&"Idle")

func set_reduced_motion(enabled: bool) -> void:
	set_process(not enabled)
	if enabled:
		_play(&"Idle")
		if _animation:
			_animation.seek(0.0, true)
			_animation.pause()

func _process(delta: float) -> void:
	if _wait > 0.0:
		_wait -= delta
		return
	var remaining := _stops[_target] - _distance
	var speed := 12.0 if _gallop else 5.2
	if ACTIONS.has(_target % LOOP.size()):
		speed = minf(speed, 2.2 + remaining * 1.65)
	_speed = move_toward(_speed, speed, 13.0 * delta)
	_distance = minf(_distance + _speed * delta, _stops[_target])
	_place_on_route()
	rotation.y = lerp_angle(rotation.y, _facing(), 1.0 - exp(-delta * 11.0))
	if _speed > 8.0:
		_play(&"Gallop", 0.94)
	else:
		_play(&"Walk", clampf(_speed / 5.2, 0.6, 1.15))
	if _distance >= _stops[_target] - 0.005:
		var action: Dictionary = ACTIONS.get(_target % LOOP.size(), {})
		if not action.is_empty():
			_wait = float(action["duration"]) * _random.randf_range(0.82, 1.18)
			_speed = 0.0
			_play(action["clip"])
		if _target == LOOP.size():
			_distance = 0.0
			_target = 1
		else:
			_target += 1
		# Leave one consistent playful run and vary the optional front stretch.
		_gallop = _target == 2 or (_target == 12 and _random.randf() < 0.45)

func _place_on_route() -> void:
	var offset := _route.sample_baked(_distance, true)
	# The woven rug is 0.13 units above the floor.
	var on_rug := absf(offset.x) < 33.5 and absf(offset.z - 1.4) < 26.5
	position = Vector3(offset.x, _floor_y + (0.13 if on_rug else 0.0), offset.z)

func _facing() -> float:
	var next := _route.sample_baked(fposmod(_distance + 0.4, _route.get_baked_length()), true)
	var direction := next - position
	return atan2(direction.x, direction.z)

func _play(clip: StringName, speed: float = 1.0) -> void:
	if not _animation:
		return
	_animation.speed_scale = speed
	if _clip != clip or not _animation.is_playing():
		_clip = clip
		_animation.play(clip, 0.18)
