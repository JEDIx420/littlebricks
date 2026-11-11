extends SceneTree

## Automated session and pacing test suite for LB-012:
## Simulates solo, paired 2-player, and 4-player building loops, tracking placement pacing and hand balance.

const SessionManager = preload("res://core/session_manager.gd")
const SaveManager = preload("res://core/save_manager.gd")
const PartCatalog = preload("res://core/part_catalog.gd")
const PlacementRules = preload("res://core/placement_rules.gd")

func _init() -> void:
	print("--- Running LittleBricks Local Sessions & Pacing Test Suite (LB-012) ---")
	
	var catalog: PartCatalog = PartCatalog.new()
	catalog.load_catalog("res://assets/catalog/parts_manifest.json")
	var rules: PlacementRules = PlacementRules.new(catalog)
	
	# 1. Simulate 2-Player Paired Session (30 turns)
	print("[1/3] Simulating 2-Player Pass-and-Play Paired Session...")
	var sm2: SessionManager = SessionManager.new(catalog, rules)
	sm2.setup_session(SessionManager.GameMode.PASS_AND_PLAY, ["Player1", "Player2"], "harbour", true)
	
	var blocked_hands_count: int = 0
	var successful_placements: int = 0
	
	for turn in range(30):
		var p_id = sm2.get_current_player_id()
		var player = sm2.get_current_player()
		
		# Check structural guarantee
		var struct_count: int = 0
		for item in player["hand"]:
			if catalog.get_part(item["part_id"]).get("category") == "brick":
				struct_count += 1
		if struct_count < 2:
			blocked_hands_count += 1
			
		# Attempt a legal placement on baseplate or layer
		var placed = false
		for slot in range(player["hand"].size()):
			var gx = (turn % 14) * 2 + 2
			var gz = ((turn / 14) * 4) + 4
			if sm2.request_placement(p_id, slot, gx, gz, 0, 0):
				successful_placements += 1
				placed = true
				break
				
		if not placed:
			# Skip if no slot matched baseplate cell
			sm2.skip_turn()
			
	print("2-Player Session complete: %d placements accepted, Blocked Hands: %d" % [
		successful_placements, blocked_hands_count
	])
	if blocked_hands_count > 0:
		print("FAILED: Player hand had fewer than 2 structural pieces!")
		quit(1)
		return
	print("PASS: 2-Player session completed with 0% blocked hands.")
	
	# 2. Simulate 4-Player Session (60 turns)
	print("[2/3] Simulating 4-Player Pass-and-Play Session...")
	var sm4: SessionManager = SessionManager.new(catalog, rules)
	sm4.setup_session(SessionManager.GameMode.PASS_AND_PLAY, ["Alice", "Bob", "Charlie", "Diana"], "cabin", true)
	
	var p4_blocked_hands: int = 0
	var p4_placements: int = 0
	for turn in range(60):
		var p_id = sm4.get_current_player_id()
		var player = sm4.get_current_player()
		var struct_count: int = 0
		for item in player["hand"]:
			if catalog.get_part(item["part_id"]).get("category") == "brick":
				struct_count += 1
		if struct_count < 2:
			p4_blocked_hands += 1
			
		var gx = (turn % 12) * 2 + 4
		var gz = ((turn / 12) * 4) + 4
		if sm4.request_placement(p_id, 0, gx, gz, 0, 0):
			p4_placements += 1
		else:
			sm4.skip_turn()
			
	print("4-Player Session complete: %d placements accepted, Blocked Hands: %d" % [
		p4_placements, p4_blocked_hands
	])
	if p4_blocked_hands > 0:
		print("FAILED: 4-Player session encountered blocked hands!")
		quit(1)
		return
	print("PASS: 4-Player session completed with guaranteed structural pieces.")
	
	# 3. Simulate Voluntary Repeat Play & Save/Resume
	print("[3/3] Simulating Voluntary Repeat Play & Save Reopening...")
	var save_path = "user://saves/paired_session_pacing.json"
	SaveManager.save_to_file(SaveManager.serialize_session(sm2), save_path)
	var loaded = SaveManager.load_from_file(save_path)
	if not loaded.get("success", false) or loaded["data"]["placements"].size() != successful_placements:
		print("FAILED: Reopened session did not match placed creations")
		quit(1)
		return
	print("PASS: Creation reopened cleanly from saved build.")
	
	print("\nALL LB-012 SESSION & PACING TESTS PASSED.")
	quit(0)
