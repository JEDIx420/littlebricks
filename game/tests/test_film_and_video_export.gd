extends SceneTree

## Dedicated automated test suite for LB-046 (Replay Film), LB-047 (Video Output), and LB-048 (Android Adapter).

const ReplayTimeline = preload("res://replay/replay_timeline.gd")
const VideoExporter = preload("res://platform/video_exporter.gd")
const PartCatalog = preload("res://core/part_catalog.gd")

func _init() -> void:
	print("\n--- Running LittleBricks Construction Film & Video Export Suite (LB-046..LB-048) ---\n")
	
	test_cumulative_frame_generation()
	test_cinematic_orbit_and_reveal()
	test_genuine_video_file_export()
	test_platform_adapters_android_web()
	
	print("\nALL LB-046..LB-048 REGRESSION CHECKS PASSED SUCCESSFULLY.\n")
	quit(0)

func test_cumulative_frame_generation() -> void:
	print("[Group 1: Cumulative Frame Generation & No Dummy Frames (LB-046)]")
	var catalog = PartCatalog.new()
	catalog.load_catalog("res://assets/catalog/parts_manifest.json")
	var timeline = ReplayTimeline.new(catalog)
	root.add_child(timeline)
	
	var placements = [
		{"part_id": "brick_2x4", "grid_x": 10, "grid_z": 10, "layer_plate": 0, "rotation_step": 0, "color": Color(0.85, 0.15, 0.15)},
		{"part_id": "brick_2x2", "grid_x": 16, "grid_z": 16, "layer_plate": 0, "rotation_step": 0, "color": Color(0.15, 0.35, 0.85)}
	]
	timeline.load_build_history(placements)
	
	# Generate frame 0 (first brick placed)
	var img_step_0 = timeline._generate_cumulative_frame(0, 320, 240, 0.0, false)
	assert(img_step_0 != null, "Frame 0 generated")
	assert(img_step_0.get_width() == 320 and img_step_0.get_height() == 240, "Frame size matches target")
	
	# Generate frame 1 (both bricks placed)
	var img_step_1 = timeline._generate_cumulative_frame(1, 320, 240, 45.0, false)
	assert(img_step_1 != null, "Frame 1 generated")
	
	# Verify images are NOT dummy solid color
	var c_table = img_step_1.get_pixel(10, 10)
	var c_base = img_step_1.get_pixel(160, 120)
	assert(c_table != c_base, "Frame contains distinct table and baseplate regions (not solid dummy)")
	
	root.remove_child(timeline)
	timeline.queue_free()
	print("PASS: Frame generation renders cumulative model with distinct materials.")

func test_cinematic_orbit_and_reveal() -> void:
	print("[Group 2: Camera Orbit & Finished Reveal (LB-046)]")
	var catalog = PartCatalog.new()
	catalog.load_catalog("res://assets/catalog/parts_manifest.json")
	var timeline = ReplayTimeline.new(catalog)
	root.add_child(timeline)
	
	timeline.load_build_history([
		{"part_id": "brick_2x4", "grid_x": 16, "grid_z": 16, "layer_plate": 0, "rotation_step": 0, "color": Color.RED}
	])
	
	timeline.play_replay()
	assert(timeline.is_playing, "Timeline is playing")
	assert(timeline.camera_rig.rotation_degrees.y == 0.0, "Initial orbit angle is 0")
	
	# Simulate 1 second of playback
	timeline._process(1.0)
	assert(timeline.camera_rig.rotation_degrees.y > 0.0, "Camera rig rotates during playback")
	assert(timeline.in_final_reveal, "Timeline reached final reveal state")
	
	root.remove_child(timeline)
	timeline.queue_free()
	print("PASS: Camera orbit advances dynamically into finished reveal.")

func test_genuine_video_file_export() -> void:
	print("[Group 3: Genuine Video File Output (LB-047)]")
	var catalog = PartCatalog.new()
	catalog.load_catalog("res://assets/catalog/parts_manifest.json")
	var timeline = ReplayTimeline.new(catalog)
	root.add_child(timeline)
	
	timeline.load_build_history([
		{"part_id": "brick_2x4", "grid_x": 16, "grid_z": 16, "layer_plate": 0, "rotation_step": 0, "color": Color.RED},
		{"part_id": "brick_2x2", "grid_x": 16, "grid_z": 20, "layer_plate": 0, "rotation_step": 0, "color": Color.BLUE}
	])
	
	var exporter = VideoExporter.new()
	exporter.initialize(640, 360, 30)
	var out_path = "user://saves/film_test.mp4"
	
	var progress_list = []
	exporter.export_progress.connect(func(c, t, p): progress_list.append(p))
	
	var ok = timeline.render_to_video_stream(exporter, out_path, 30)
	assert(ok, "Render to video stream returns true")
	assert(exporter.state == VideoExporter.ExportState.COMPLETED, "Exporter reached COMPLETED state")
	assert(FileAccess.file_exists(out_path), "Genuine video output file exists on disk")
	assert(progress_list.size() > 0, "Progress events emitted during frame encoding")
	
	# Clean up
	if FileAccess.file_exists(out_path):
		DirAccess.remove_absolute(out_path)
	root.remove_child(timeline)
	timeline.queue_free()
	print("PASS: Real video file encoded to disk with verified completion and progress.")

func test_platform_adapters_android_web() -> void:
	print("[Group 4: Platform Adapters for Android and Web (LB-047 / LB-048)]")
	var exporter = VideoExporter.new()
	exporter.initialize(1280, 720, 30)
	
	# Native Godot cannot provide a browser canvas or an Android singleton.
	assert(not exporter._start_web_media_recorder(), "Web capture reports unavailable outside a browser")
	assert(not exporter._finalize_web_media_recorder(), "Web finalize cannot report a native capture")

	var android_out = "user://saves/android_film.mp4"
	exporter.current_output_path = android_out
	if not Engine.has_singleton("LittleBricksMediaCodec"):
		assert(not exporter._start_android_mediacodec(android_out), "Missing Android adapter is reported")
		assert(not exporter._finalize_android_mediacodec(), "Missing adapter cannot produce a film")
		assert(not FileAccess.file_exists(android_out), "Missing Android adapter does not write a mock video")
	print("PASS: Missing platform adapters report unavailable without creating a mock file.")
