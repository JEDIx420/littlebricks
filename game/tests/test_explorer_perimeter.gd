extends SceneTree

const ExplorationScene := preload("res://client/scenes/exploration_view.tscn")
const ExplorationWorld := preload("res://core/exploration_world.gd")
const Rules := preload("res://core/placement_rules.gd")

var _failed := false

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		_failed = true

func _run() -> void:
	var view := ExplorationScene.instantiate()
	root.add_child(view)
	view.setup_exploration_scene([])
	var explorer: ToyExplorer = view.explorer_instance
	_check(explorer.spring_arm.collision_mask & ExplorationWorld.PERIMETER_LAYER == 0, "Camera stays clear of the invisible perimeter")
	for direction: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN, Vector2.ONE.normalized()]:
		explorer.reset_to_spawn()
		explorer.position = Vector3(signf(direction.x) * 14.3, 0.15, signf(direction.y) * 14.3)
		explorer.rotation = Vector3.ZERO
		explorer.set_virtual_input(direction)
		for tick in range(55):
			await physics_frame
		_check(explorer.is_on_floor(), "Explorer remains grounded while walking toward %s" % direction)
		_check(explorer.position.y >= 0.08 and explorer.position.y < 0.2, "Explorer stays at tabletop height")
		var position := Vector2(explorer.position.x, explorer.position.z)
		var motion := position.dot(direction)
		var starting_offset := Vector2(signf(direction.x), signf(direction.y)).dot(direction) * 14.3
		_check(motion > starting_offset + 0.8, "Explorer can reach the edge before the barrier")
		_check(absf(position.x) < 15.7 and absf(position.y) < 15.7, "Explorer capsule stays inside both perimeter axes")
	explorer.set_virtual_input(Vector2.ZERO)
	# Rebuild the scene around an uppermost legal-height surface at the edge.
	view.setup_exploration_scene([{
		"part_id": "brick_2x4", "grid_x": 30, "grid_z": 14,
		"layer_plate": Rules.MAX_LAYER_PLATES - 3, "rotation_step": 0,
	}])
	await process_frame
	explorer = view.explorer_instance
	var top := 0.1 + Rules.MAX_LAYER_PLATES * Rules.PLATE_HEIGHT
	explorer.position = Vector3(14.35, top + 0.05, 0.0)
	explorer.rotation = Vector3.ZERO
	explorer.set_virtual_input(Vector2.RIGHT)
	for tick in range(55):
		await physics_frame
	_check(explorer.is_on_floor() and is_equal_approx(explorer.position.y, top), "The perimeter also contains movement on the highest build layer")
	_check(explorer.position.x > 15.1 and explorer.position.x < 15.7, "The elevated explorer reaches and stops at the edge")

	var covered: Array = []
	for layer in range(8):
		for x in range(0, Rules.GRID_SIZE, 8):
			for z in range(0, Rules.GRID_SIZE, 8):
				covered.append({"part_id": "plate_8x8", "grid_x": x, "grid_z": z, "layer_plate": layer})
	view.setup_exploration_scene(covered)
	for tick in range(25):
		await physics_frame
	explorer = view.explorer_instance
	_check(explorer.is_on_floor() and explorer.position.y >= 3.24, "A fully covered board spawns the explorer on top of the build")
	view.queue_free()
	await process_frame
	if not _failed:
		print("PASS: Explorer remains grounded at all edges, the diagonal corner, maximum build height, and a covered board")
	quit(1 if _failed else 0)
