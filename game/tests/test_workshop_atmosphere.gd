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

	_check_manual_transition(table)
	table.queue_free()
	await process_frame
	if failures.is_empty():
		print("PASS: Workshop day, night, rain, reduced motion and restoration")
	quit(0 if failures.is_empty() else 1)

func _check_manual_transition(table: Node) -> void:
	var atmosphere: PresentationController = table.presentation
	var sun := table.get_node("DirectionalLight3D") as DirectionalLight3D
	atmosphere.is_reduced_motion = false
	atmosphere.restore_atmosphere_state({"mode": "day"})
	var day_energy := sun.light_energy
	atmosphere.set_atmosphere_mode("night")
	_expect(is_equal_approx(sun.light_energy, day_energy), "Selecting night does not cut the daylight")
	var last_energy := sun.light_energy
	var last_shadow := sun.shadow_opacity
	var largest_energy_step := 0.0
	var largest_shadow_step := 0.0
	var monotonic := true
	var soft_switch := true
	var previous_shadow_enabled := sun.shadow_enabled
	for i in range(1, 361):
		atmosphere._process(1.0 / 60.0)
		monotonic = monotonic and sun.light_energy <= last_energy + 0.00001
		largest_energy_step = maxf(largest_energy_step, absf(sun.light_energy - last_energy))
		largest_shadow_step = maxf(largest_shadow_step, absf(sun.shadow_opacity - last_shadow))
		if previous_shadow_enabled and not sun.shadow_enabled:
			soft_switch = soft_switch and last_shadow < 0.001 and last_energy < day_energy * 0.001
		last_energy = sun.light_energy
		last_shadow = sun.shadow_opacity
		previous_shadow_enabled = sun.shadow_enabled
		if i == 120:
			_check_transition_restore(table, sun)
	_expect(monotonic and largest_energy_step < day_energy * 0.01, "Sunlight fades continuously at 60 Hz")
	_expect(soft_switch and largest_shadow_step < 0.02, "Sun shadows soften before disabling")
	_expect(table.get_workshop_state().is_night, "The manual transition reaches the night preset")

func _check_transition_restore(table: Node, sun: DirectionalLight3D) -> void:
	var energy_before := sun.light_energy
	var shadow_before := sun.shadow_opacity
	var saved: Dictionary = JSON.parse_string(JSON.stringify(table.get_workshop_state()))
	table.presentation.restore_atmosphere_state(saved)
	_expect(is_equal_approx(sun.light_energy, energy_before), "Restoring an in-flight transition preserves the displayed lighting")
	_expect(is_equal_approx(sun.shadow_opacity, shadow_before), "Restoring an in-flight transition preserves shadow softness")
