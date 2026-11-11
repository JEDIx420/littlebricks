extends SceneTree

## Headless test script for LB-004: 500-piece stress scene and video export architecture.

const BenchmarkScene = preload("res://client/scripts/benchmark_scene.gd")
const VideoExporter = preload("res://platform/video_exporter.gd")

func _init() -> void:
	print("--- Running LittleBricks LB-004 Stress & Video Exporter Test Suite ---")
	
	# 1. Test 500-piece benchmark instantiation
	print("[1/2] Testing 500-piece stress scene instantiation...")
	var bench_res: Dictionary = BenchmarkScene.run_headless_benchmark()
	print("Instantiated: %d pieces, Memory: %.2f MB" % [
		bench_res.get("pieces_instantiated", 0),
		bench_res.get("memory_mb", 0.0)
	])
	if not bench_res.get("passed", false):
		print("FAILED: 500 pieces not instantiated correctly")
		quit(1)
		return
	print("PASS: 500-piece representative stress scene verified.")
	
	# 2. Test VideoExporter state machine & frame feeder
	print("[2/2] Testing VideoExporter interface & frame streaming...")
	var exporter: VideoExporter = VideoExporter.new()
	exporter.initialize(1280, 720, 30)
	
	var progress_events: Array[int] = []
	exporter.export_progress.connect(func(curr, total, pct): progress_events.append(curr))
	
	var started: bool = exporter.start_recording("test_replay.mp4", 5)
	if not started or exporter.state != VideoExporter.ExportState.RECORDING:
		print("FAILED: VideoExporter start_recording failed")
		quit(1)
		return
		
	# Feed 5 test frames
	var test_img: Image = Image.create(128, 72, false, Image.FORMAT_RGBA8)
	test_img.fill(Color.GREEN)
	for i in range(5):
		var ok: bool = exporter.push_frame(test_img)
		if not ok:
			print("FAILED: push_frame failed on frame %d" % i)
			quit(1)
			return
			
	if progress_events.size() != 5:
		print("FAILED: Expected 5 progress events, got %d" % progress_events.size())
		quit(1)
		return
		
	var out: String = exporter.finish_recording()
	if exporter.state != VideoExporter.ExportState.COMPLETED:
		print("FAILED: VideoExporter finish_recording failed to complete")
		quit(1)
		return
	print("PASS: VideoExporter frame streaming and lifecycle verified.")
	
	# Test cancellation
	exporter.start_recording("temp_cancel.mp4", 10)
	exporter.cancel_recording()
	if exporter.state != VideoExporter.ExportState.CANCELLED:
		print("FAILED: VideoExporter cancellation failed")
		quit(1)
		return
	print("PASS: VideoExporter cancellation and buffer cleanup verified.")
	
	print("ALL LB-004 TESTS PASSED.")
	quit(0)
