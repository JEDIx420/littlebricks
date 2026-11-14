extends Node3D
class_name WorkshopDog

## Local decorative actor. Nothing in this scene can intercept brick picking.
const MODEL := preload("res://assets/sourced/quaternius_dog/workshop_dog.glb")
const LOOPS := [
	Vector2(44, 25), Vector2(49, 20), Vector2(46, 10),
	Vector2(40, -7), Vector2(33, -24), Vector2(14, -30),
	Vector2(-10, -30), Vector2(-33, -29), Vector2(-36, -11),
	Vector2(-36, 10), Vector2(-39, 23), Vector2(-37, 32),
	Vector2(-16, 34), Vector2(5, 34), Vector2(24, 34),
]
const ACTIONS := {
	0: {"clip": &"Idle_2_HeadLow", "duration": 2.2},
	4: {"clip": &"Idle", "duration": 1.6},
	13: {"clip": &"Idle_2_HeadLow", "duration": 2.1},
}
const FLOOR_JUMP := Vector2(45.0, 20.1)
const CLIMB_RIGHT := Vector2(35.0, 20.1)
const TABLE_EDGE_RIGHT := Vector2(20.6, 20.1)
const TABLE_STOP := Vector2(0.0, 20.1)
const TABLE_EDGE_LEFT := Vector2(-20.6, 20.1)
const CLIMB_LEFT := Vector2(-35.0, 20.1)
const FLOOR_LAND := Vector2(-38.0, 29.0)
const FLOOR_REST := Vector2(-37.0, 32.0)
const STOOL_HEIGHT := 10.9
# Measured at the game's current scale from the source clip's planted paws.
const WALK_SPEED := 9.6
const GALLOP_SPEED := 22.0
const PAWS := [
	[&"FrontUpperLeg.L", &"FrontLowerLeg.L", &"FF.L"],
	[&"FrontUpperLeg.R", &"FrontLowerLeg.R", &"FF.R"],
	[&"BackUpperLeg.L", &"BackLowerLeg.L", &"FFB.L"],
	[&"BackUpperLeg.R", &"BackLowerLeg.R", &"FFB.R"],
]

enum Stage { FLOOR, APPROACH, JUMP_UP, TABLE_WALK, LOOK, JUMP_DOWN, REJOIN }

var stage: Stage = Stage.FLOOR
var _animation: AnimationPlayer
var _model: Node3D
var _rig: Skeleton3D
var _head_index := -1
var _tail_index := -1
var _ear_indices: Array[int] = []
var _leg_indices: Array[Vector3i] = []
var _planted := PackedByteArray()
var _anchors := PackedVector3Array()
var _plant_weight := PackedFloat32Array()
var _look_focus := 0.0
var _idle_clock := 0.0
var _start_heading := 0.0
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
var _table_y := 0.0
var _climb_clock := 0.0
var _climb_after: float
var _action_index := 0
var _action_time := 0.0
var _actions: Array[Dictionary] = []

func configure_surfaces(floor_y: float, table_y: float) -> void:
	_floor_y = floor_y
	_table_y = table_y

func _ready() -> void:
	_random.randomize()
	_climb_after = _random.randf_range(26.0, 36.0)
	_route.bake_interval = 0.18
	for i in range(LOOPS.size() + 1):
		var index := i % LOOPS.size()
		var current: Vector2 = LOOPS[index]
		var previous: Vector2 = LOOPS[posmod(index - 1, LOOPS.size())]
		var next: Vector2 = LOOPS[(index + 1) % LOOPS.size()]
		var tangent := (next - previous).normalized() * minf(current.distance_to(previous), current.distance_to(next)) * 0.28
		_route.add_point(Vector3(current.x, 0, current.y), Vector3(-tangent.x, 0, -tangent.y), Vector3(tangent.x, 0, tangent.y))
	for spot: Vector2 in LOOPS:
		_stops.append(_route.get_closest_offset(Vector3(spot.x, 0, spot.y)))
	_stops.append(_route.get_baked_length())

	_model = MODEL.instantiate() as Node3D
	_model.name = "DogModel"
	_model.scale = Vector3.ONE * 3.55
	_model.position.y = -0.012
	add_child(_model)
	_animation = _model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	_animation.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	for clip in [&"Idle", &"Idle_2_HeadLow", &"Walk", &"Gallop"]:
		_animation.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	for clip in [&"Gallop_Jump", &"Jump_ToIdle"]:
		# Source jump clips use vertical root motion. The route already owns
		# elevation, so keep the joint posing and strip root translation.
		var jump := _animation.get_animation(clip).duplicate() as Animation
		for track in range(jump.get_track_count() - 1, -1, -1):
			var path := jump.track_get_path(track)
			if jump.track_get_type(track) == Animation.TYPE_POSITION_3D and path.get_subname_count() > 0 and path.get_subname(0) in [&"Body", &"Root"]:
				jump.remove_track(track)
		var animations := _animation.get_animation_library(&"")
		animations.remove_animation(clip)
		animations.add_animation(clip, jump)
	for mesh in _model.find_children("*", "MeshInstance3D", true, false):
		for surface in mesh.mesh.get_surface_count():
			var material := mesh.get_active_material(surface).duplicate() as StandardMaterial3D
			material.metallic_specular = 0.12
			mesh.set_surface_override_material(surface, material)
	_rig = _model.find_child("Skeleton3D", true, false) as Skeleton3D
	_head_index = _rig.find_bone("Head")
	_tail_index = _rig.find_bone("Tail1")
	_ear_indices = [_rig.find_bone("Ear1.L"), _rig.find_bone("Ear1.R")]
	for paw in PAWS:
		_leg_indices.append(Vector3i(_rig.find_bone(paw[0]), _rig.find_bone(paw[1]), _rig.find_bone(paw[2])))
	_planted.resize(PAWS.size())
	_anchors.resize(PAWS.size())
	_plant_weight.resize(PAWS.size())
	_place_on_route()
	rotation.y = _facing()
	_play(&"Idle")

func set_reduced_motion(enabled: bool) -> void:
	if enabled:
		_actions.clear()
		stage = Stage.FLOOR
		_action_time = 0.0
		_wait = 2.0
		_speed = 0.0
		_gallop = false
		_seek_floor_stop(0)
		_model.rotation.x = 0.0
		_climb_clock = 0.0
		_clear_paw_plants()
		_play(&"Idle")
		_animation.advance(0.0)
		_animation.seek(0.0, true)
		_animation.pause()
	else:
		_play(&"Idle")
	set_process(not enabled)

func _process(delta: float) -> void:
	var previous := position
	var previous_stage := stage
	_rig.clear_bones_global_pose_override()
	if stage == Stage.FLOOR:
		_advance_floor(delta)
	else:
		_advance_visit(delta)
	_animation.advance(delta)
	if stage != Stage.JUMP_UP and stage != Stage.JUMP_DOWN:
		_model.rotation.x = lerpf(_model.rotation.x, 0.0, minf(delta * 12.0, 1.0))
	if stage != previous_stage:
		_clear_paw_plants()
	var travel := Vector2(position.x - previous.x, position.z - previous.z).length()
	var walking := _clip == &"Walk" or _clip == &"Gallop"
	if walking and travel > 0.001:
		_plant_paws(delta)
	else:
		_clear_paw_plants()
	if stage == Stage.LOOK:
		_look_about(_action_time / float(_actions[_action_index]["duration"]))
	elif stage == Stage.FLOOR and _wait > 0.0 and _clip == &"Idle":
		_idle_clock += delta
		_look_about(smoothstep(0.0, 2.6, _idle_clock))

func _advance_floor(delta: float) -> void:
	_climb_clock += delta
	if _wait > 0.0:
		_wait -= delta
		return
	if _climb_clock >= _climb_after and _target == 1:
		_start_table_visit()
		return
	var remaining := _stops[_target] - _distance
	var braking := ACTIONS.has(_target % LOOPS.size())
	var goal_speed := 18.4 if _gallop else WALK_SPEED * (0.84 + 0.12 * sin(_climb_clock * 1.05))
	if braking:
		goal_speed = minf(goal_speed, sqrt(31.0 * remaining))
	_speed = move_toward(_speed, goal_speed, 14.0 * delta)
	var travel := minf(_speed * delta, remaining)
	_distance += travel
	_place_on_route()
	var trail_angle := angle_difference(rotation.y, _facing())
	rotation.y += trail_angle * (1.0 - exp(-delta * 8.0))
	_play_gait(travel / delta, _speed > (11.8 if _clip == &"Gallop" else 13.7))
	if _distance < _stops[_target] - 0.008:
		return
	var action: Dictionary = ACTIONS.get(_target % LOOPS.size(), {})
	if not action.is_empty():
		_wait = float(action["duration"]) * _random.randf_range(0.65, 1.35)
		_idle_clock = 0.0
		_look_focus = _random.randf_range(-0.25, 0.25)
		_speed = 0.0
		_play(action["clip"])
	if _target == LOOPS.size():
		_distance = 0.0
		_target = 1
	else:
		_target += 1
	_gallop = _target in [2, 3, 7, 13, 14] and _random.randf() < 0.53

func _play_gait(speed: float, running: bool) -> void:
	_play(&"Gallop" if running else &"Walk", speed / (GALLOP_SPEED if running else WALK_SPEED))

func _start_table_visit() -> void:
	var stool_y := _floor_y + STOOL_HEIGHT
	var start := position
	var launch := _floor_level(FLOOR_JUMP)
	var stool_right := _level(CLIMB_RIGHT, stool_y)
	var top_right := _level(TABLE_EDGE_RIGHT, _table_y)
	var lookout := _level(TABLE_STOP + Vector2(_random.randf_range(-3.0, 3.0), 0.0), _table_y)
	_look_focus = _random.randf_range(-0.27, 0.27)
	var top_left := _level(TABLE_EDGE_LEFT, _table_y)
	var stool_left := _level(CLIMB_LEFT, stool_y)
	var landing := _floor_level(FLOOR_LAND)
	var rejoin := _floor_level(FLOOR_REST)
	_actions = [
		_step(Stage.APPROACH, start, launch, 1.05, &"Walk"),
		_step(Stage.JUMP_UP, launch, stool_right, 0.96, &"Jump_ToIdle", 5.45),
		_step(Stage.APPROACH, stool_right, stool_right, 0.52, &"Idle"),
		_step(Stage.JUMP_UP, stool_right, top_right, 1.02, &"Gallop_Jump", 7.2),
		_step(Stage.TABLE_WALK, top_right, lookout, 2.7, &"Walk"),
		_step(Stage.LOOK, lookout, lookout, _random.randf_range(4.8, 6.2), &"Idle"),
		_step(Stage.TABLE_WALK, lookout, top_left, 2.7, &"Walk"),
		_step(Stage.JUMP_DOWN, top_left, stool_left, 1.0, &"Gallop_Jump", 6.8),
		_step(Stage.APPROACH, stool_left, stool_left, 0.53, &"Idle"),
		_step(Stage.JUMP_DOWN, stool_left, landing, 0.93, &"Jump_ToIdle", 5.1),
		_step(Stage.REJOIN, landing, rejoin, 0.9, &"Walk"),
	]
	_action_index = 0
	_begin_step()

func _step(next_stage: Stage, start: Vector3, finish: Vector3, duration: float, clip: StringName, arc: float = 0.0) -> Dictionary:
	return {"stage": next_stage, "start": start, "finish": finish, "duration": duration, "clip": clip, "arc": arc}

func _begin_step() -> void:
	var action := _actions[_action_index]
	stage = action["stage"]
	_action_time = 0.0
	_start_heading = rotation.y
	var clip: StringName = action["clip"]
	_play(clip, 0.0 if clip != &"Idle" else 1.0)

func _advance_visit(delta: float) -> void:
	var action := _actions[_action_index]
	var duration: float = action["duration"]
	_action_time = minf(_action_time + delta, duration)
	var progress := _action_time / duration
	var start: Vector3 = action["start"]
	var finish: Vector3 = action["finish"]
	var arc: float = action["arc"]
	var travel := finish - start
	if arc > 0.0:
		# The first part of the clip coils the hind legs. During flight, the
		# route carries elevation and the original clip shapes the limbs.
		var flight := clampf(remap(progress, 0.22, 0.84, 0.0, 1.0), 0.0, 1.0)
		var eased_flight := _ease_travel(flight)
		var previous := position
		position = start.lerp(finish, eased_flight)
		position.y += 4.0 * arc * eased_flight * (1.0 - eased_flight)
		rotation.y = lerp_angle(_start_heading, atan2(travel.x, travel.z), smoothstep(0.0, 0.27, progress))
		_sample_jump_pose(progress, previous, delta, action["clip"])
	elif travel.length_squared() > 0.01:
		var movement := _ease_travel(progress)
		var next := start.lerp(finish, movement)
		_play_gait(position.distance_to(next) / delta, false)
		position = next
		rotation.y = lerp_angle(_start_heading, atan2(travel.x, travel.z), smoothstep(0.0, 0.34, progress))
	if progress < 1.0:
		return
	_action_index += 1
	if _action_index < _actions.size():
		_begin_step()
	else:
		_actions.clear()
		stage = Stage.FLOOR
		_climb_clock = 0.0
		_climb_after = _random.randf_range(45.0, 75.0)
		_wait = _random.randf_range(0.8, 2.0)
		_idle_clock = 0.0
		_speed = 0.0
		_gallop = false
		_seek_floor_stop(11)
		_play(&"Idle")

func _sample_jump_pose(progress: float, previous: Vector3, delta: float, clip: StringName) -> void:
	var length := _animation.get_animation(clip).length
	var pose_time: float
	if progress < 0.22:
		pose_time = lerpf(0.085, 0.37, progress / 0.22)
	elif progress < 0.84:
		pose_time = lerpf(0.37, 0.84, (progress - 0.22) / 0.62)
	else:
		pose_time = lerpf(0.84, 1.0, (progress - 0.84) / 0.16)
	# Seek after activating a newly selected clip. update_only prevents signals
	# from firing as we retime the original poses to our physical arc.
	_animation.seek(pose_time * length, true, true)
	var speed := (position.y - previous.y) / delta
	var pitch := clampf(-speed * 0.01, -0.26, 0.24)
	_model.rotation.x = lerpf(_model.rotation.x, pitch, minf(delta * 15.0, 1.0))

func _ease_travel(progress: float) -> float:
	# Short constant-speed middle with continuous acceleration and braking.
	const RAMP := 0.15
	if progress < RAMP:
		return progress * progress / (2.0 * RAMP * (1.0 - RAMP))
	if progress > 1.0 - RAMP:
		return 1.0 - _ease_travel(1.0 - progress)
	return (progress - RAMP * 0.5) / (1.0 - RAMP)

func _look_about(progress: float) -> void:
	# Animal input remains authored by the original animation; attention adds
	# a small gaze sweep and wag on top of the relaxed idle pose.
	var sweep := (sin(progress * TAU * 1.5) + _look_focus) * sin(progress * PI)
	var pose := _rig.get_bone_global_pose_no_override(_head_index)
	var perk := sin(smoothstep(0.14, 0.76, progress) * PI)
	pose.basis = Basis(Vector3.UP, sweep * 0.67) * Basis(Vector3.FORWARD, sweep * 0.17) * Basis(Vector3.RIGHT, -0.12 * perk) * pose.basis
	_rig.set_bone_global_pose_override(_head_index, pose, 1.0, true)
	var tail := _rig.get_bone_global_pose_no_override(_tail_index)
	tail.basis = Basis(Vector3.UP, sin(_action_time * 11.0) * sin(progress * PI) * 0.24) * tail.basis
	_rig.set_bone_global_pose_override(_tail_index, tail, 1.0, true)
	# Subtle alternating ear flicks as the dog checks the room.
	for side in _ear_indices.size():
		var flick := sin(smoothstep(0.30 + side * 0.24, 0.45 + side * 0.24, progress) * PI)
		if flick > 0.001:
			var ear := _rig.get_bone_global_pose_no_override(_ear_indices[side])
			ear.basis = Basis(Vector3.FORWARD, flick * (0.15 if side == 0 else -0.15)) * ear.basis
			_rig.set_bone_global_pose_override(_ear_indices[side], ear, flick, true)
		else:
			_rig.set_bone_global_pose_override(_ear_indices[side], Transform3D.IDENTITY, 0.0, false)

func _plant_paws(delta: float) -> void:
	var world_to_rig := _rig.global_transform.affine_inverse()
	_rig.force_update_all_bone_transforms()
	var running := _clip == &"Gallop"
	for i in _leg_indices.size():
		var chain := _leg_indices[i]
		var contact := _rig.get_bone_global_pose_no_override(chain.z).origin
		var world_paw := _rig.global_transform * contact
		var height := world_paw.y - global_position.y
		var in_contact := height <= (0.34 if _planted[i] else 0.28)
		if in_contact and not _planted[i]:
			_anchors[i] = world_paw
		_planted[i] = int(in_contact)
		_plant_weight[i] = move_toward(_plant_weight[i], float(in_contact), delta * (24.0 if running else 18.0))
		if _plant_weight[i] <= 0.0:
			continue
		# Let the authored rig flex naturally. A bounded world correction
		# removes sliding through steering or speed changes without stretching.
		var offset := (world_to_rig * _anchors[i] - contact).limit_length((1.10 if running else 1.55) / _rig.global_basis.x.length())
		_correct_leg(chain, contact, offset * _plant_weight[i])

func _correct_leg(chain: Vector3i, paw: Vector3, offset: Vector3) -> void:
	var upper := _rig.get_bone_global_pose_no_override(chain.x)
	var lower := _rig.get_bone_global_pose_no_override(chain.y)
	var first := lower.origin - upper.origin
	var second := paw - lower.origin
	var first_length := first.length()
	var second_length := second.length()
	var ray := paw + offset - upper.origin
	var reach := clampf(ray.length(), absf(first_length - second_length) + 0.00004, first_length + second_length - 0.00004)
	var direction := ray.normalized()
	var bend := first - direction * direction.dot(first)
	if bend.length_squared() < 0.000000001:
		return
	var projection := (first_length * first_length - second_length * second_length + reach * reach) / (2.0 * reach)
	var knee := direction * projection + bend.normalized() * sqrt(maxf(0.0, first_length * first_length - projection * projection))
	var shin := direction * reach - knee
	upper.basis = Basis(Quaternion(first.normalized(), knee.normalized())) * upper.basis
	lower.basis = Basis(Quaternion(second.normalized(), shin.normalized())) * lower.basis
	lower.origin = upper.origin + knee
	_rig.set_bone_global_pose_override(chain.x, upper, 1.0, true)
	_rig.set_bone_global_pose_override(chain.y, lower, 1.0, true)

func _clear_paw_plants() -> void:
	_planted.fill(0)
	_plant_weight.fill(0.0)

func _seek_floor_stop(index: int) -> void:
	_distance = _stops[index]
	_target = index + 1
	_place_on_route()
	rotation.y = _facing()

func _place_on_route() -> void:
	var offset := _route.sample_baked(_distance, true)
	position = _floor_level(Vector2(offset.x, offset.z))

func _floor_level(point: Vector2) -> Vector3:
	var on_rug := absf(point.x) < 33.5 and absf(point.y - 1.4) < 26.5
	return _level(point, _floor_y + (0.13 if on_rug else 0.0))

func _level(point: Vector2, height: float) -> Vector3:
	return Vector3(point.x, height, point.y)

func _facing() -> float:
	var next := _route.sample_baked(fposmod(_distance + 0.4, _route.get_baked_length()), true)
	var direction := next - position
	return atan2(direction.x, direction.z)

func _play(clip: StringName, speed: float = 1.0) -> void:
	_animation.speed_scale = speed
	if _clip != clip or not _animation.is_playing():
		_clear_paw_plants()
		_clip = clip
		_animation.play(clip, 0.18)
