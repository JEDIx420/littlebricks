extends SceneTree

const WORKSHOP := preload("res://client/scenes/main.tscn")
const DOG := preload("res://client/scripts/workshop_dog.gd")
const DELTA := 1.0 / 60.0

func _initialize() -> void:
	call_deferred("_check")

func _check() -> void:
	var world := WORKSHOP.instantiate()
	root.add_child(world)
	var dog := world.get_node("TableView/CraftRoom/WorkshopDog") as WorkshopDog
	var animator := dog.find_child("AnimationPlayer", true, false) as AnimationPlayer
	dog._random.seed = 7321
	dog._climb_after = 32.0

	var visited := {}
	var seen_clips := {}
	var top_min := INF
	var top_max := -INF
	var first_table_second := -1.0
	var did_return := false
	var stopped_in_air := false
	var source_drift := 0.0
	var planted_drift := 0.0
	var samples := 0
	for frame in range(180 * 60):
		dog._process(DELTA)
		var position := dog.position
		visited[dog.stage] = true
		seen_clips[animator.current_animation] = true
		if dog.stage == DOG.Stage.TABLE_WALK or dog.stage == DOG.Stage.LOOK:
			if not is_equal_approx(position.y, -0.1) or position.z < 19.95 or absf(position.x) > 20.61:
				_fail("Table walk must stay in the narrow front strip outside studs, trays, and the blueprint.")
				return
			top_min = minf(top_min, position.x)
			top_max = maxf(top_max, position.x)
			if first_table_second < 0.0:
				first_table_second = frame * DELTA
		if dog.stage == DOG.Stage.FLOOR:
			dog._rig.force_update_all_bone_transforms()
			for paw in dog._leg_indices.size():
				if not dog._planted[paw] or dog._plant_weight[paw] < 0.9:
					continue
				var chain: Vector3i = dog._leg_indices[paw]
				var source_leg := dog._rig.get_bone_global_pose_no_override(chain.y)
				var corrected_leg := dog._rig.get_bone_global_pose(chain.y)
				var source_paw := dog._rig.get_bone_global_pose_no_override(chain.z).origin
				var corrected_paw := corrected_leg * (source_leg.affine_inverse() * source_paw)
				var anchor: Vector3 = dog._anchors[paw]
				source_drift += (dog._rig.global_transform * source_paw).distance_to(anchor)
				planted_drift += (dog._rig.global_transform * corrected_paw).distance_to(anchor)
				samples += 1
			if position.y < -23.001 or position.y > -22.86 or (absf(position.x) < 27.0 and absf(position.z) < 22.0):
				_fail("Floor route entered the table footprint or departed the floor and rug.")
				return
			if visited.has(DOG.Stage.REJOIN):
				did_return = true
		if did_return and dog.stage == DOG.Stage.JUMP_UP and position.y > -21.5:
			dog.set_reduced_motion(true)
			stopped_in_air = dog.stage == DOG.Stage.FLOOR and is_equal_approx(dog.position.y, -23.0)
			if not stopped_in_air or dog.is_processing() or animator.is_playing() or not is_zero_approx(dog._model.rotation.x):
				_fail("Reduced motion must park safely on the floor even when toggled in midair.")
				return
			dog.set_reduced_motion(false)
			if not dog.is_processing() or not animator.is_playing():
				_fail("Normal motion must resume from the park point.")
				return
			break

	if visited.size() != 7 or not stopped_in_air or not did_return:
		_fail("Expected full floor, approach, jump, table look, descent, and rejoin sequence.")
		return
	if not seen_clips.has("Gallop") or not seen_clips.has("Gallop_Jump") or top_max < 20.0 or top_min > -20.0:
		_fail("Expected the animation clips and a complete crossing of the table strip.")
		return
	if first_table_second < 23.0 or first_table_second > 57.0:
		_fail("Expected the first visit during a normal first minute in the workshop.")
		return
	if samples < 150 or planted_drift / source_drift > 0.30:
		_fail("Planted paws must move less than 30% of source gait drift across the floor route.")
		return
	print("PASS: Mean planted paw drift %.3f vs %.3f source across %d stance samples." % [planted_drift / samples, source_drift / samples, samples])
	print("PASS: Workshop dog roams, gallops, climbs at %.1fs, traverses the clear table strip, returns, and can park mid-jump." % first_table_second)
	world.queue_free()
	quit(0)

func _fail(reason: String) -> void:
	push_error(reason)
	quit(1)
