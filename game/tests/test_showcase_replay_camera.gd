extends SceneTree

const AppScene := preload("res://client/scenes/app_root.tscn")

var _failed := false

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error(message)

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var app := AppScene.instantiate() as AppRoot
	root.add_child(app)
	app.settings.reduced_motion = false
	app.start_session({"mode": "solo", "free_build": true, "creation_name": "Replay Camera Test"})
	var session := app.active_session
	for index in 38:
		var x := 1 + index % 8 * 4
		var z := 1 + floori(float(index) / 8.0) * 6
		_check(session.submit_placement(session.get_current_player_id(), "brick_2x4", x, z, 0, 0), "Replay fixture places brick %d" % index)

	var table = app.current_view
	# Before the fix this viewing angle led the Watch Build camera through a wall.
	table.camera_rig.orbit_by(155.0, 0.0)
	app._on_table_finish_requested()
	var showcase := table.find_child("ShowcaseOverlay", true, false) as ShowcaseOverlay
	showcase.btn_watch_build.pressed.emit()
	var timeline := showcase.timeline
	timeline.set_process(false)
	var first_pose := timeline.camera.global_transform
	for tick in 54:
		_check(table.camera_rig.room_bounds.has_point(timeline.camera.global_position), "Replay camera stays inside at tick %d" % tick)
		_check(_fits_view(timeline.camera), "Replay shows the entire 38-brick footprint at tick %d" % tick)
		timeline.advance_replay(0.25)
	_check(timeline.active_step == 38 and not timeline.is_playing, "Replay reaches the complete reveal")
	_check(showcase.label_replay.text == "Build complete", "Showcase shows finished playback")
	_check(timeline.verify_final_scene_matches_build(), "The 38 bricks remain visible at completion")

	showcase.btn_replay_restart.pressed.emit()
	var restarted := showcase.timeline
	restarted.set_process(false)
	_check(restarted != timeline and restarted.active_step == 0, "Restart rebuilds from an empty timeline")
	_check(restarted.camera.global_transform.is_equal_approx(first_pose), "Restart restores the same initial camera")
	showcase.btn_close_replay.pressed.emit()
	_check(table.camera_rig.camera.current and table.placed_bricks_container.visible, "Back returns to the camera and original build")
	_check(session.placements.size() == 38, "Playback leaves the original build intact")

	root.remove_child(app)
	app.queue_free()
	await process_frame
	if not _failed:
		print("PASS: 38-brick showcase replay stays in frame through final reveal, restart, and return")
	quit(1 if _failed else 0)

func _fits_view(camera: Camera3D) -> bool:
	var view := camera.get_viewport().get_visible_rect().grow(-2.0)
	# The brick fixture spans columns 1–30 and rows 1–28.
	for x in [-15.0, 15.0]:
		for z in [-15.0, 13.0]:
			for y in [0.1, 1.53]:
				var corner := Vector3(x, y, z)
				if camera.is_position_behind(corner) or not view.has_point(camera.unproject_position(corner)):
					return false
	return true
