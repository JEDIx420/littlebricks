extends SceneTree

## Sends raw screen touches through Godot's viewport and mouse emulation.
const AppRoot = preload("res://client/scenes/app_root.tscn")
const Rules = preload("res://core/placement_rules.gd")

func _initialize() -> void:
	create_timer(12.0).timeout.connect(func(): quit(1))
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	Input.set_emulate_mouse_from_touch(true)
	var app = AppRoot.instantiate()
	root.add_child(app)
	await process_frame
	app.audio.set_mute(true)
	app.start_session({
		"mode": "solo", "free_build": true, "theme_id": "harbour",
		"creation_name": "Touch Test", "players": ["Tester"], "timer_enabled": false,
	})
	await process_frame

	var table = app.current_view
	var session = app.active_session
	var hand: Array = session.players[0]["hand"]
	hand[0]["part_id"] = "brick_2x4"
	hand[1]["part_id"] = "brick_1x4"
	hand[2]["part_id"] = "brick_2x2"
	# Attach the controlled hand through the normal session-to-table path.
	table.attach_session(session, null, null, app.settings)
	await process_frame

	var camera_dock := table.find_child("BtnCameraDock", true, false) as Control
	_tap(camera_dock.get_global_rect().get_center())
	await process_frame
	_tap(table.btn_top_view.get_global_rect().get_center())
	assert(is_equal_approx(table.camera_rig.pitch, -88.0), "HUD controls still receive touch through Godot mouse emulation")
	_tap(camera_dock.get_global_rect().get_center())
	await process_frame
	_tap(_slot(table, 0))
	assert(table.selected_hand_slot == 0 and table.selected_part_id == "brick_2x4")
	assert(session.placements.is_empty(), "Tapping a tray selects without placing")
	var base := _world(table, "brick_2x4", Vector2i(10, 10))
	_touch(0, base, true)
	assert(session.placements.is_empty(), "Press alone cannot place")
	_touch(0, base, false)
	assert(session.placements.size() == 1 and session.placements[0]["layer_plate"] == 0, "Single tap places a brick")
	await process_frame

	_tap(_slot(table, 1))
	assert(table.selected_part_id == "brick_1x4")
	_tap(_world(table, "brick_1x4", Vector2i(10, 10), 3))
	assert(session.placements.size() == 2 and session.placements[1]["layer_plate"] == 3, "Single tap stacks on the actual top layer")
	await process_frame
	_tap(table.btn_rotate_right.get_global_rect().get_center())
	assert(table.current_rotation_step == 1 and session.placements.size() == 2, "Rotate HUD stays isolated from placement")

	var tray := _slot(table, 2)
	var drop := _world(table, "brick_2x2", Vector2i(18, 17), 0, table.current_rotation_step)
	_touch(0, tray, true)
	_drag(0, tray, tray.lerp(drop, 0.5))
	_drag(0, tray.lerp(drop, 0.5), drop)
	assert(session.placements.size() == 2, "Tray drag only aims before release")
	_touch(0, drop, false)
	assert(session.placements.size() == 3 and session.placements[2]["part_id"] == "brick_2x2", "Dragging a tray piece onto the plate places it")

	var empty := _world(table, "brick_2x2", Vector2i(14, 16))
	var second := _world(table, "brick_2x2", Vector2i(20, 16))
	var distance_before: float = table.camera_rig.distance
	_touch(0, empty, true)
	_touch(1, second, true)
	_drag(1, second, second + Vector2(45, 0))
	assert(not is_equal_approx(distance_before, table.camera_rig.distance), "Two fingers control zoom")
	_touch(1, second + Vector2(45, 0), false)
	_touch(0, empty, false)
	assert(session.placements.size() == 3, "Pinch and release cannot place a brick")

	var hud := table.btn_rotate_right.get_global_rect().get_center() as Vector2
	var angle_before: int = table.current_rotation_step
	_touch(0, empty, true)
	_drag(0, empty, hud)
	_touch(0, hud, false)
	assert(session.placements.size() == 3 and table.current_rotation_step == angle_before, "Releasing world drag over HUD fires neither action")
	_touch(0, empty, true)
	_touch(0, empty, false, true)
	assert(session.placements.size() == 3, "A canceled touch cannot place")
	_tap(empty)
	assert(session.placements.size() == 4, "New touch works after pinch and cancellation")

	for player in app.audio.find_children("*", "AudioStreamPlayer", true, false):
		player.stop()
	await create_timer(0.12).timeout
	app.queue_free()
	await process_frame
	print("PASS: touch tray tap, stacking, rotation, tray drop, pinch, HUD release, cancellation")
	quit(0)

func _slot(table: Node, slot: int) -> Vector2:
	return table.tray_container.get_child(slot).get_global_rect().get_center()

func _world(table: Node, id: String, grid: Vector2i, layer: int = 0, rotation: int = 0) -> Vector2:
	var dims: Array = table.catalog.get_part(id)["dimensions_studs"]
	return table.camera_rig.camera.unproject_position(Rules.grid_to_world(grid.x, grid.y, layer, dims, rotation))

func _tap(position: Vector2) -> void:
	_touch(0, position, true)
	_touch(0, position, false)

func _touch(index: int, position: Vector2, pressed: bool, canceled: bool = false) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = position
	event.pressed = pressed
	event.canceled = canceled
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func _drag(index: int, from: Vector2, to: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = to
	event.relative = to - from
	event.screen_relative = event.relative
	Input.parse_input_event(event)
	Input.flush_buffered_events()
