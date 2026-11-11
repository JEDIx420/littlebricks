extends SceneTree

## Dedicated regression suite for LB-069 Camera Interaction Overhaul.
## Validates orbit, planar pan, zoom, input ownership, and mode cycling.

const CameraController = preload("res://client/scripts/camera_controller.gd")

func _init() -> void:
	print("--- Running LittleBricks Camera Tabletop Interaction Suite (LB-069) ---")
	
	var rig = CameraController.new()
	var cam = Camera3D.new()
	cam.name = "Camera3D"
	rig.add_child(cam)
	root.add_child(rig)
	rig._ready()
	
	# Test 1: Default configuration & initial state
	print("\n[Test 1: Default camera state]")
	rig.set_default_view()
	assert_eq(rig.interaction_mode, CameraController.InteractionMode.BUILD, "Initial mode must be BUILD")
	assert_false(rig.is_camera_mode, "is_camera_mode must be false in BUILD mode")
	assert_eq(rig.distance, 24.0, "Default distance must be 24.0")
	assert_eq(rig.pitch, -38.0, "Default pitch must be -38.0")
	assert_eq(rig.yaw, 45.0, "Default yaw must be 45.0")
	assert_eq(rig.target, Vector3(0, 0.5, 0), "Default target must be at (0, 0.5, 0)")
	print("PASS: Default state verified.")
	
	# Test 2: Mode cycling (BUILD -> ORBIT -> PAN -> BUILD)
	print("\n[Test 2: Mode cycling]")
	var mode1 = rig.cycle_camera_mode()
	assert_eq(mode1, CameraController.InteractionMode.ORBIT, "First cycle must be ORBIT")
	assert_true(rig.is_camera_mode, "is_camera_mode must be true in ORBIT")
	assert_eq(rig.get_mode_name(), "Orbit", "Mode name must be Orbit")
	
	var mode2 = rig.cycle_camera_mode()
	assert_eq(mode2, CameraController.InteractionMode.PAN, "Second cycle must be PAN")
	assert_true(rig.is_camera_mode, "is_camera_mode must be true in PAN")
	assert_eq(rig.get_mode_name(), "Pan", "Mode name must be Pan")
	
	var mode3 = rig.cycle_camera_mode()
	assert_eq(mode3, CameraController.InteractionMode.BUILD, "Third cycle must be BUILD")
	assert_false(rig.is_camera_mode, "is_camera_mode must be false in BUILD")
	assert_eq(rig.get_mode_name(), "Build", "Mode name must be Build")
	print("PASS: Mode cycling verified.")
	
	# Test 3: Planar tabletop pan and target Y-lock
	print("\n[Test 3: Planar tabletop pan]")
	rig.set_default_view()
	rig.pan_by(Vector2(100, 50))
	assert_eq(rig.target.y, 0.5, "Target Y must remain locked at 0.5 for tabletop focus")
	assert_true(rig.target.x != 0.0 or rig.target.z != 0.0, "Target X/Z must translate across tabletop")
	
	# Tabletop bounds clamping
	rig.pan_by(Vector2(50000, 50000))
	assert_true(abs(rig.target.x) <= 25.0, "Target X must be clamped within table bounds")
	assert_true(abs(rig.target.z) <= 25.0, "Target Z must be clamped within table bounds")
	print("PASS: Planar pan projects on horizontal plane and clamps to table margins.")
	
	# Test 4: Orbit and Pitch clamping
	print("\n[Test 4: Orbit and pitch limits]")
	rig.set_default_view()
	rig.orbit_by(90.0, 100.0) # extreme upward pitch
	assert_true(rig.pitch <= -10.0, "Pitch must not exceed maximum -10.0 deg (cannot look from below table)")
	rig.orbit_by(0.0, -200.0) # extreme downward pitch
	assert_true(rig.pitch >= -88.0, "Pitch must not exceed minimum -88.0 deg (cannot flip upside down)")
	print("PASS: Pitch clamped between -88 and -10 degrees.")
	
	# Test 5: Zoom limits
	print("\n[Test 5: Zoom limits]")
	rig.set_default_view()
	rig.zoom_by(-100.0) # zoom in deeply
	assert_eq(rig.distance, 6.0, "Distance must clamp to min 6.0")
	rig.zoom_by(200.0) # zoom out far
	assert_eq(rig.distance, 48.0, "Distance must clamp to max 48.0")
	print("PASS: Zoom clamped between 6.0 and 48.0.")
	
	# Test 6: Frame plate & Recenter
	print("\n[Test 6: Frame plate and recenter]")
	rig.pan_by(Vector2(500, 500))
	rig.frame_plate()
	assert_eq(rig.target, Vector3(0, 0.5, 0), "frame_plate must reset target to (0, 0.5, 0)")
	assert_eq(rig.distance, 24.0, "frame_plate must reset distance to 24.0")
	
	rig.recenter_on(Vector3(10.0, 5.0, -12.0))
	assert_eq(rig.target, Vector3(10.0, 0.5, -12.0), "recenter_on must set X/Z and lock Y to 0.5")
	print("PASS: frame_plate and recenter_on verified.")
	
	# Test 7: Gesture state tracking (is_gesture_active)
	print("\n[Test 7: Gesture tracking]")
	assert_false(rig.is_gesture_active, "Initial gesture state must be false")
	rig._is_orbiting = true
	assert_true(rig.is_gesture_active, "is_gesture_active must be true when orbiting")
	rig._is_orbiting = false
	rig._is_panning = true
	assert_true(rig.is_gesture_active, "is_gesture_active must be true when panning")
	rig.reset_gesture_state()
	assert_false(rig.is_gesture_active, "reset_gesture_state must clear gestures")
	print("PASS: Gesture state tracking verified.")
	
	print("\nALL LB-069 CAMERA INTERACTION TESTS PASSED.")
	rig.queue_free()
	quit(0)

func assert_true(val: bool, msg: String) -> void:
	if not val:
		print("ASSERTION FAILED (expected true): %s" % msg)
		quit(1)

func assert_false(val: bool, msg: String) -> void:
	if val:
		print("ASSERTION FAILED (expected false): %s" % msg)
		quit(1)

func assert_eq(a, b, msg: String) -> void:
	if a != b:
		print("ASSERTION FAILED (%s != %s): %s" % [str(a), str(b), msg])
		quit(1)
