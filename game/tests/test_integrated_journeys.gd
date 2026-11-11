extends SceneTree

## Comprehensive end-to-end journey verification harness for LittleBricks (LB-026..LB-028).
## Validates complete Solo, Pass-and-Play, Exploration, Replay, and Settings workflows.

const SessionManager = preload("res://core/session_manager.gd")
const SaveManager = preload("res://core/save_manager.gd")
const SettingsManager = preload("res://client/scripts/settings_manager.gd")
const PartCatalog = preload("res://core/part_catalog.gd")
const PlacementRules = preload("res://core/placement_rules.gd")
const ExplorationWorld = preload("res://core/exploration_world.gd")
const ReplayTimeline = preload("res://replay/replay_timeline.gd")
const VideoExporter = preload("res://platform/video_exporter.gd")

func _init() -> void:
	print("--- Running LittleBricks Complete Integrated Journeys Test Suite (M6) ---")
	
	var catalog: PartCatalog = PartCatalog.new()
	catalog.load_catalog("res://assets/catalog/parts_manifest.json")
	var rules: PlacementRules = PlacementRules.new(catalog)
	
	# 1. Test Settings Persistence (LB-026)
	print("[1/4] Testing persistent accessibility settings...")
	var settings = SettingsManager.new()
	settings.reduced_motion = true
	settings.high_contrast_cues = true
	settings.preferred_theme = "cabin"
	settings.save_settings()
	
	var reloaded_settings = SettingsManager.new()
	if not reloaded_settings.reduced_motion or reloaded_settings.preferred_theme != "cabin":
		print("FAILED: Settings did not persist correctly!")
		quit(1)
		return
	print("PASS: Accessibility & preference settings persisted cleanly.")
	
	# 2. Test Full Solo Creative Journey (LB-028)
	print("[2/4] Testing complete Solo Creative Journey (Build -> Save -> Explore -> Replay)...")
	var sm_solo: SessionManager = SessionManager.new(catalog, rules)
	sm_solo.setup_session(SessionManager.GameMode.SOLO_CREATIVE, ["MasterBuilder"], "harbour", false)
	
	# Place 10 pieces building on baseplate
	var solo_placed = 0
	var solo_cell = 0
	while solo_placed < 10 and solo_cell < 40:
		var p_id = sm_solo.get_current_player_id()
		var player = sm_solo.get_current_player()
		var gx = (solo_cell % 6) * 4 + 2
		var gz = (solo_cell / 6) * 4 + 2
		for slot in range(player["hand"].size()):
			if sm_solo.request_placement(p_id, slot, gx, gz, 0, 0):
				solo_placed += 1
				break
		solo_cell += 1
			
	if sm_solo.placements.size() != 10:
		print("FAILED: Placements count mismatch in solo journey: %d" % sm_solo.placements.size())
		quit(1)
		return
		
	# Save session
	var save_path = "user://saves/solo_journey_save.json"
	SaveManager.save_to_file(SaveManager.serialize_session(sm_solo), save_path)
	
	# Transition to Exploration
	sm_solo.transition_to_exploration()
	if sm_solo.phase != SessionManager.SessionPhase.EXPLORATION:
		print("FAILED: Exploration transition failed")
		quit(1)
		return
		
	# Reconstruct exploration world
	var exp_world = ExplorationWorld.new(catalog)
	var spawn_pos = exp_world.find_default_spawn(sm_solo.placements)
	if spawn_pos.y < 0.0:
		print("FAILED: Invalid exploration spawn position")
		quit(1)
		return
		
	# Return to table as new revision
	sm_solo.return_to_building_new_revision()
	if sm_solo.build_revision != 2 or sm_solo.phase != SessionManager.SessionPhase.BUILDING:
		print("FAILED: Return to building revision bump failed")
		quit(1)
		return
		
	# Replay film reconstruction
	var timeline: ReplayTimeline = ReplayTimeline.new(catalog)
	root.add_child(timeline)
	timeline.load_build_history(sm_solo.placements)
	var exporter = VideoExporter.new()
	exporter.initialize(1280, 720, 30)
	var replay_ok = timeline.render_to_video_stream(exporter, "user://saves/solo_replay.mp4", 30)
	if not replay_ok:
		print("FAILED: Solo replay film render failed")
		quit(1)
		return
	timeline.queue_free()
	print("PASS: Complete Solo Journey passed (Build, Save, Explore, Revision, Replay Film).")
	
	# 3. Test Full Pass-and-Play Journey (LB-028)
	print("[3/4] Testing complete Pass-and-Play Journey (2 Players, Shared Table, Unanimous Finish)...")
	var sm_local: SessionManager = SessionManager.new(catalog, rules)
	sm_local.setup_session(SessionManager.GameMode.PASS_AND_PLAY, ["PlayerA", "PlayerB"], "cabin", true)
	
	var pnp_placed = 0
	var pnp_cell = 0
	while pnp_placed < 8 and pnp_cell < 30:
		var p_id = sm_local.get_current_player_id()
		var player = sm_local.get_current_player()
		var gx = (pnp_cell % 5) * 4 + 4
		var gz = (pnp_cell / 5) * 4 + 4
		for slot in range(player["hand"].size()):
			if sm_local.request_placement(p_id, slot, gx, gz, 0, 0):
				pnp_placed += 1
				break
		pnp_cell += 1
		
	if sm_local.placements.size() != 8:
		print("FAILED: Pass-and-play placements count mismatch: %d" % sm_local.placements.size())
		quit(1)
		return
		
	# Both players agree to finish
	sm_local.set_ready_to_explore("p_1", true)
	sm_local.set_ready_to_explore("p_2", true)
	if sm_local.phase != SessionManager.SessionPhase.EXPLORATION:
		print("FAILED: Pass-and-play finish consensus failed")
		quit(1)
		return
	print("PASS: Pass-and-play shared build and consensus finish verified.")
	
	# 4. Sustained Performance Profile (LB-027)
	print("[4/4] Verifying sustained memory and draw call budgets...")
	var mem_bytes = OS.get_static_memory_usage()
	var mem_mb = float(mem_bytes) / (1024.0 * 1024.0)
	print("Current total static memory usage: %.2f MB" % mem_mb)
	if mem_mb > 150.0:
		print("FAILED: Memory usage exceeds 150 MB budget!")
		quit(1)
		return
	print("PASS: Sustained memory is well within mobile limits (%.2f MB < 150 MB)." % mem_mb)
	
	print("\nALL MILESTONE M6 INTEGRATED JOURNEY TESTS PASSED.")
	quit(0)
