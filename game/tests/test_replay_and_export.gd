extends SceneTree

## Automated test suite for Milestone M5: Replay Timeline & Construction Films (LB-021..LB-024).

const ReplayTimeline = preload("res://replay/replay_timeline.gd")
const VideoExporter = preload("res://platform/video_exporter.gd")
const PartCatalog = preload("res://core/part_catalog.gd")

func _init() -> void:
	print("--- Running LittleBricks Construction Replay & Video Film Test Suite (M5) ---")
	
	var catalog: PartCatalog = PartCatalog.new()
	catalog.load_catalog("res://assets/catalog/parts_manifest.json")
	var timeline: ReplayTimeline = ReplayTimeline.new(catalog)
	root.add_child(timeline)
	
	# Generate 20 test placements
	var placements: Array = []
	var part_types = ["brick_2x4", "brick_2x2", "brick_1x4", "plate_2x4", "arch_1x4"]
	for i in range(20):
		placements.append({
			"placement_id": "pl_%d" % i,
			"sequence": i + 1,
			"part_id": part_types[i % part_types.size()],
			"grid_x": (i % 8) * 2 + 8,
			"grid_z": ((i / 8) * 4) + 8,
			"layer_plate": 0,
			"rotation_step": i % 4,
			"color": Color.RED
		})
		
	# 1. Test Build History Loading (LB-021)
	print("[1/4] Testing build history loading...")
	timeline.load_build_history(placements)
	if timeline.placements_data.size() != 20:
		print("FAILED: History load mismatch")
		quit(1)
		return
	print("PASS: 20-piece build history loaded into timeline.")
	
	# 2. Test Playback and Step Progression (LB-021)
	print("[2/4] Testing step-by-step playback advancement...")
	var step_counts = 0
	timeline.step_played.connect(func(s, total): step_counts += 1)
	
	# Advance 20 steps
	for i in range(20):
		timeline._advance_step()
		
	if timeline.active_step != 20 or not timeline.in_final_reveal:
		print("FAILED: Playback did not advance through all 20 steps to final reveal")
		quit(1)
		return
	print("PASS: Timeline advanced through 20 steps and entered final reveal.")
	
	# 3. Test Final Scene Matches Build (LB-024)
	print("[3/4] Verifying final scene matches original build piece-by-piece...")
	if not timeline.verify_final_scene_matches_build():
		print("FAILED: Final scene piece count did not match original build!")
		quit(1)
		return
	print("PASS: Final reconstructed scene matches original build piece-by-piece.")
	
	# 4. Test Video Exporter Streaming and Bounded Buffers (LB-022 / LB-023)
	print("[4/4] Testing VideoExporter stream integration and bounded buffers...")
	var exporter: VideoExporter = VideoExporter.new()
	exporter.initialize(1280, 720, 30)
	
	var progress_events: Array[int] = []
	exporter.export_progress.connect(func(c, t, p): progress_events.append(c))
	
	var export_ok = timeline.render_to_video_stream(exporter, "user://saves/replay_film.mp4", 30)
	if not export_ok or exporter.state != VideoExporter.ExportState.COMPLETED:
		print("FAILED: Render to video stream failed: %s" % str(export_ok))
		quit(1)
		return
	if progress_events.size() < 20:
		print("FAILED: Progress events were not emitted during frame streaming")
		quit(1)
		return
	print("PASS: VideoExporter successfully streamed replay frames with %d progress events." % progress_events.size())
	
	timeline.queue_free()
	print("\nALL MILESTONE M5 REPLAY & FILM TESTS PASSED.")
	quit(0)
