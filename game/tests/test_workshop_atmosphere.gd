extends SceneTree

const TableScene := preload("res://client/scenes/main.tscn")
const SessionManager := preload("res://core/session_manager.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func _run() -> void:
	var table = TableScene.instantiate()
	root.add_child(table)
	var session := SessionManager.new()
	session.setup_session(SessionManager.GameMode.SOLO_CREATIVE, ["Builder"])
	table.attach_session(session, null, null, null, {"mode": "cycle", "phase": 0.12})

	var atmosphere: PresentationController = table.presentation
	var sun := table.get_node("DirectionalLight3D") as DirectionalLight3D
	var daylight_energy := sun.light_energy
	atmosphere._process(PresentationController.CYCLE_SECONDS * 0.47)
	_expect(atmosphere.get_atmosphere_state().is_night, "The automatic workshop cycle reaches night")
	_expect(sun.light_energy < daylight_energy * 0.3, "The actual room light darkens at night")
	atmosphere._process(PresentationController.CYCLE_SECONDS * 0.28)
	_expect(atmosphere.get_atmosphere_state().is_raining, "The automatic workshop cycle reaches rain")

	var saved: Dictionary = table.get_workshop_state()
	atmosphere.is_reduced_motion = true
	atmosphere._process(10.0)
	_expect(table.get_workshop_state() == saved, "Reduced motion preserves the current phase and rain frame")

	atmosphere.set_atmosphere_mode("day")
	_expect(not table.get_workshop_state().is_raining and is_equal_approx(sun.light_energy, daylight_energy), "Day restores the room light immediately in reduced motion")
	atmosphere.restore_atmosphere_state(saved)
	_expect(table.get_workshop_state().is_raining, "The previous workshop atmosphere restores from saved state")
	_expect(session.placements.is_empty(), "Room lighting never changes the build")

	table.queue_free()
	await process_frame
	if failures.is_empty():
		print("PASS: Workshop day, night, rain, reduced motion and restoration")
	quit(0 if failures.is_empty() else 1)
