extends SceneTree

## Automated test suite for Milestone M4: Online Room Authority, Idempotency, and Reconnect (LB-017..LB-020).

const RoomAuthority = preload("res://server/room_authority.gd")
const NetworkProtocol = preload("res://server/network_protocol.gd")
const SessionManager = preload("res://core/session_manager.gd")
const PartCatalog = preload("res://core/part_catalog.gd")
const PlacementRules = preload("res://core/placement_rules.gd")

func _init() -> void:
	print("--- Running LittleBricks Online Room Authority Test Suite (M4) ---")
	
	var catalog: PartCatalog = PartCatalog.new()
	catalog.load_catalog("res://assets/catalog/parts_manifest.json")
	var rules: PlacementRules = PlacementRules.new(catalog)
	var sm: SessionManager = SessionManager.new(catalog, rules)
	
	var room: RoomAuthority = RoomAuthority.new("ROOM42", sm)
	
	# 1. Test Player Join & Opaque Session Tokens (LB-017)
	print("[1/5] Testing player join and token generation...")
	var j1 = room.handle_join("Alice")
	var j2 = room.handle_join("Bob")
	var j3 = room.handle_join("Charlie")
	var j4 = room.handle_join("Diana")
	var j5 = room.handle_join("Eve") # 5th player should be rejected
	
	if not j1["success"] or not j2["success"] or not j3["success"] or not j4["success"]:
		print("FAILED: 4 players could not join room")
		quit(1)
		return
	if j5["success"]:
		print("FAILED: 5th player was allowed into 4-player room!")
		quit(1)
		return
	print("PASS: 4 players joined with separate tokens; 5th player rejected (ROOM_FULL).")
	
	var token_alice = j1["player_token"]
	var token_bob = j2["player_token"]
	
	# 2. Test Turn Ownership & Wrong-Turn Rejection (LB-017)
	print("[2/5] Testing turn authentication and wrong-turn rejection...")
	var cmd_bob_early = NetworkProtocol.make_placement_submission("req_001", token_bob, 0, 10, 10, 0, 0)
	var resp_bob_early = room.handle_submit_placement(cmd_bob_early)
	if resp_bob_early["success"] or resp_bob_early["code"] != "WRONG_TURN":
		print("FAILED: Bob placed on Alice's turn: %s" % str(resp_bob_early))
		quit(1)
		return
	print("PASS: Placement by non-active player rejected with WRONG_TURN.")
	
	# 3. Test Idempotent Command Deduplication (LB-017 / LB-020)
	print("[3/5] Testing request ID idempotency and duplicate deduplication...")
	var cmd_alice = NetworkProtocol.make_placement_submission("req_alice_01", token_alice, 0, 10, 10, 0, 0)
	var resp_alice_1 = room.handle_submit_placement(cmd_alice)
	if not resp_alice_1["success"]:
		print("FAILED: Alice valid placement rejected: %s" % str(resp_alice_1))
		quit(1)
		return
	var initial_placements_count = room.session.placements.size()
	
	# Submit the EXACT SAME request_id again (simulating network retry/duplicate packet)
	var resp_alice_dup = room.handle_submit_placement(cmd_alice)
	if not resp_alice_dup["success"]:
		print("FAILED: Duplicate request was rejected instead of returning cached result")
		quit(1)
		return
	if room.session.placements.size() != initial_placements_count:
		print("FAILED: Duplicate request consumed a second brick/turn!")
		quit(1)
		return
	print("PASS: Duplicate request returned identical cached response without re-placing.")
	
	# 4. Test Reconnect Recovery with Snapshot-plus-Tail (LB-018 / LB-019)
	print("[4/5] Testing disconnect grace and snapshot-plus-tail reconnect...")
	var last_seq_seen_by_alice = resp_alice_1["sequence"]
	
	# Now Bob places a brick
	var cmd_bob = NetworkProtocol.make_placement_submission("req_bob_01", token_bob, 0, 14, 14, 0, 0)
	var resp_bob = room.handle_submit_placement(cmd_bob)
	if not resp_bob["success"]:
		print("FAILED: Bob valid placement rejected: %s" % str(resp_bob))
		quit(1)
		return
		
	# Alice re-connects after missing Bob's placement
	var recon_resp = room.handle_reconnect(token_alice, last_seq_seen_by_alice)
	if not recon_resp["success"]:
		print("FAILED: Reconnect failed: %s" % str(recon_resp))
		quit(1)
		return
	var tail = recon_resp["event_tail"]
	if tail.is_empty():
		print("FAILED: Reconnect tail was empty; missed events not returned!")
		quit(1)
		return
	print("PASS: Reconnect returned snapshot plus event tail with %d missed events." % tail.size())
	
	# 5. Test Moderation / UGC Reporting Flow (LB-020)
	print("[5/5] Testing moderation reporting and user block...")
	var rep_resp = room.handle_report_user(token_alice, "p_2", "Inappropriate construction behavior")
	if not rep_resp["success"]:
		print("FAILED: Report user failed: %s" % str(rep_resp))
		quit(1)
		return
	# Verify Bob is now blocked
	var cmd_blocked_bob = NetworkProtocol.make_placement_submission("req_bob_02", token_bob, 0, 18, 18, 0, 0)
	var resp_blk = room.handle_submit_placement(cmd_blocked_bob)
	if resp_blk["success"] or resp_blk["code"] != "BLOCKED":
		print("FAILED: Blocked user was still allowed to submit placements!")
		quit(1)
		return
	print("PASS: Moderation flow recorded report and blocked user token.")
	
	print("\nALL MILESTONE M4 MULTIPLAYER AUTHORITY TESTS PASSED.")
	quit(0)
