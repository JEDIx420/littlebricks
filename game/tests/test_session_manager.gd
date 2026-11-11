extends SceneTree

## Automated test suite for SessionManager (LB-009).

const SessionManager = preload("res://core/session_manager.gd")
const PartCatalog = preload("res://core/part_catalog.gd")
const PlacementRules = preload("res://core/placement_rules.gd")

func _init() -> void:
	print("--- Running LittleBricks SessionManager & Turn Rules Test Suite (LB-009) ---")
	
	var catalog: PartCatalog = PartCatalog.new()
	catalog.load_catalog("res://assets/catalog/parts_manifest.json")
	var rules: PlacementRules = PlacementRules.new(catalog)
	var sm: SessionManager = SessionManager.new(catalog, rules)
	
	# 1. Setup 2-player pass-and-play session
	sm.setup_session(SessionManager.GameMode.PASS_AND_PLAY, ["Alice", "Bob"], "harbour", true)
	if sm.players.size() != 2 or sm.players[0]["hand"].size() != 6:
		print("FAILED: Session setup failed (expected 2 players with 6 pieces each)")
		quit(1)
		return
	print("PASS: 2-player pass-and-play session initialized with 6-piece hands.")
	
	# 2. Test turn ownership: Bob cannot place on Alice's turn
	var wrong_turn = sm.request_placement("p_2", 0, 10, 10, 0, 0)
	if wrong_turn:
		print("FAILED: Bob placed on Alice's turn!")
		quit(1)
		return
	print("PASS: Non-active player placement rejected with WRONG_TURN.")
	
	# 3. Test invalid placement does NOT consume piece or advance turn
	var hand_before = sm.players[0]["hand"][0].duplicate()
	var turn_before = sm.current_player_idx
	# Out of bounds coordinates (gx=-10)
	var invalid_move = sm.request_placement("p_1", 0, -10, 10, 0, 0)
	if invalid_move:
		print("FAILED: Invalid placement was accepted!")
		quit(1)
		return
	if sm.players[0]["hand"][0]["instance_id"] != hand_before["instance_id"]:
		print("FAILED: Invalid placement consumed a piece from player hand!")
		quit(1)
		return
	if sm.current_player_idx != turn_before:
		print("FAILED: Invalid placement advanced the turn!")
		quit(1)
		return
	print("PASS: Invalid placement does not consume piece or advance turn.")
	
	# 4. Test valid placement consumes piece, refills slot, and advances turn
	var valid_move = sm.request_placement("p_1", 0, 12, 12, 0, 0)
	if not valid_move:
		print("FAILED: Valid placement on baseplate rejected!")
		quit(1)
		return
	if sm.placements.size() != 1:
		print("FAILED: Placement was not added to board placements")
		quit(1)
		return
	if sm.current_player_idx != 1:
		print("FAILED: Turn did not advance to Player 2 (Bob)")
		quit(1)
		return
	print("PASS: Valid placement consumes piece, adds to board, and advances turn to Bob.")
	
	# 5. Test timer timeout / skip
	var bob_hand_before = sm.players[1]["hand"][0].duplicate()
	sm.time_remaining_sec = 0.0
	sm.tick_timer(0.1) # Trigger timeout
	if sm.current_player_idx != 0:
		print("FAILED: Timer timeout did not advance turn back to Alice")
		quit(1)
		return
	if sm.players[1]["hand"][0]["instance_id"] != bob_hand_before["instance_id"]:
		print("FAILED: Timeout consumed Bob's piece!")
		quit(1)
		return
	print("PASS: Turn timeout skips turn and preserves player's piece.")
	
	# 6. Test finish agreement
	sm.set_ready_to_explore("p_1", true)
	if sm.phase != SessionManager.SessionPhase.BUILDING:
		print("FAILED: Exploration started with only 1/2 players ready")
		quit(1)
		return
		
	# New placement clears readiness
	sm.request_placement("p_1", 1, 16, 16, 0, 0)
	if sm.players[0]["is_ready_to_explore"]:
		print("FAILED: New placement did not clear Alice's readiness vote")
		quit(1)
		return
	print("PASS: New placement clears existing finish agreement votes.")
	
	# Both players vote ready
	sm.set_ready_to_explore("p_1", true)
	sm.set_ready_to_explore("p_2", true)
	if sm.phase != SessionManager.SessionPhase.EXPLORATION:
		print("FAILED: Phase did not transition to EXPLORATION when all players agreed")
		quit(1)
		return
	print("PASS: Unanimous finish agreement transitions phase to EXPLORATION.")
	
	# 7. Return to building as a new revision
	sm.return_to_building_new_revision()
	if sm.phase != SessionManager.SessionPhase.BUILDING or sm.build_revision != 2:
		print("FAILED: Return to building did not create new build revision")
		quit(1)
		return
	print("PASS: Return to building transitions back to BUILDING with incremented revision (v2).")
	
	print("\nALL LB-009 SESSION MANAGER TESTS PASSED.")
	quit(0)
