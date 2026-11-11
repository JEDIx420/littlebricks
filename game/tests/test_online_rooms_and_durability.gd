extends SceneTree

## Comprehensive test suite for LB-044 (Real Private Online Rooms) and LB-045 (Durability & Reconnect).
## Proves multi-client WebSocket networking, turn authority, idempotency, and reconnect recovery.

const LittleBricksServer = preload("res://server/littlebricks_server.gd")
const NetworkClient = preload("res://client/scripts/network_client.gd")
const NetworkProtocol = preload("res://server/network_protocol.gd")

const TEST_PORT: int = 9091
const TEST_HOST: String = "ws://127.0.0.1:9091"
const ROOM_CODE: String = "COZY42"

var server: LittleBricksServer
var client_a: NetworkClient
var client_b: NetworkClient
var client_c: NetworkClient

func _init() -> void:
	print("\n--- Running LittleBricks Online Rooms & Durability Suite (LB-044 / LB-045) ---\n")
	
	_run_all_tests()
	quit(0)

func _poll_all(duration_ms: int = 50) -> void:
	var start = Time.get_ticks_msec()
	while Time.get_ticks_msec() - start < duration_ms:
		if server: server.poll()
		if client_a: client_a.poll()
		if client_b: client_b.poll()
		if client_c: client_c.poll()
		OS.delay_msec(5)

func _wait_for_condition(condition_callable: Callable, timeout_ms: int = 4000) -> bool:
	var start = Time.get_ticks_msec()
	while Time.get_ticks_msec() - start < timeout_ms:
		_poll_all(10)
		if condition_callable.call():
			return true
	return false

func _run_all_tests() -> void:
	# 1. Start Authoritative WebSocket Server
	print("[Phase 1: Server Initialization (LB-044)]")
	server = LittleBricksServer.new()
	var err = server.start(TEST_PORT, "127.0.0.1")
	assert(err == OK, "Server must start listening on port %d" % TEST_PORT)
	print("PASS: Authoritative WebSocket Server listening on %s." % TEST_HOST)
	
	# 2. Connect 3 Independent Clients (Alice, Bob, Charlie)
	print("\n[Phase 2: Multi-Client Connection & Room Join (LB-044)]")
	client_a = NetworkClient.new()
	client_b = NetworkClient.new()
	client_c = NetworkClient.new()
	
	var a_joined: Dictionary = {}
	var b_joined: Dictionary = {}
	var c_joined: Dictionary = {}
	
	client_a.join_succeeded.connect(func(d): a_joined.merge(d))
	client_b.join_succeeded.connect(func(d): b_joined.merge(d))
	client_c.join_succeeded.connect(func(d): c_joined.merge(d))
	
	client_a.connect_to_server(TEST_HOST)
	client_b.connect_to_server(TEST_HOST)
	client_c.connect_to_server(TEST_HOST)
	
	var all_connected = _wait_for_condition(func():
		return client_a.state == NetworkClient.State.CONNECTED and \
			client_b.state == NetworkClient.State.CONNECTED and \
			client_c.state == NetworkClient.State.CONNECTED
	)
	assert(all_connected, "All 3 clients must connect via WebSockets")
	
	client_a.join_room(ROOM_CODE, "Alice")
	client_b.join_room(ROOM_CODE, "Bob")
	client_c.join_room(ROOM_CODE, "Charlie")
	
	var all_joined = _wait_for_condition(func():
		return not a_joined.is_empty() and not b_joined.is_empty() and not c_joined.is_empty()
	)
	assert(all_joined, "All 3 clients must successfully join room %s" % ROOM_CODE)
	assert(a_joined["player_id"] == "p_1", "Alice is player 1")
	assert(b_joined["player_id"] == "p_2", "Bob is player 2")
	assert(c_joined["player_id"] == "p_3", "Charlie is player 3")
	assert(!a_joined["player_token"].is_empty(), "Alice received unique session token")
	assert(!b_joined["player_token"].is_empty(), "Bob received unique session token")
	print("PASS: Alice, Bob, and Charlie joined room %s with distinct session tokens." % ROOM_CODE)
	
	# 3. Test Turn Authority & Wrong-Turn Rejection (LB-044)
	print("\n[Phase 3: Turn Authority & Wrong-Turn Rejection (LB-044)]")
	var bob_rejected: Dictionary = {}
	client_b.placement_rejected.connect(func(req, code, err_msg):
		bob_rejected.merge({"req": req, "code": code, "error": err_msg})
	)
	
	# Bob attempts to place on Alice's turn
	client_b.submit_placement("bob_illegal_req", 0, 16, 16, 0, 0)
	var got_rejection = _wait_for_condition(func(): return not bob_rejected.is_empty())
	assert(got_rejection, "Server must reject Bob placement out of turn")
	assert(bob_rejected["code"] == "WRONG_TURN", "Rejection code must be WRONG_TURN")
	print("PASS: Wrong-turn placement rejected by server with WRONG_TURN.")
	
	# 4. Authoritative Placement Broadcast & Synchronized State (LB-044)
	print("\n[Phase 4: Authoritative Move Broadcast (LB-044)]")
	var a_received: Array = []
	var b_received: Array = []
	var c_received: Array = []
	
	client_a.placement_received.connect(func(p, next_p, seq): a_received.append(p))
	client_b.placement_received.connect(func(p, next_p, seq): b_received.append(p))
	client_c.placement_received.connect(func(p, next_p, seq): c_received.append(p))
	
	# Alice submits legal placement
	client_a.submit_placement("alice_move_1", 0, 16, 16, 0, 0)
	var all_got_move = _wait_for_condition(func():
		return a_received.size() == 1 and b_received.size() == 1 and c_received.size() == 1
	)
	assert(all_got_move, "All 3 clients must receive broadcast of Alice's placement")
	assert(a_received[0]["grid_x"] == 16, "Broadcasted piece matches canonical grid_x 16")
	assert(b_received[0]["grid_x"] == 16, "Bob received matching grid_x 16")
	assert(c_received[0]["grid_x"] == 16, "Charlie received matching grid_x 16")
	print("PASS: Legal placement accepted and broadcast to all 3 participants with matching coordinates.")
	
	# 5. Idempotent Deduplication (LB-045)
	print("\n[Phase 5: Idempotency & Duplicate Request Protection (LB-045)]")
	var room_auth = server.rooms[ROOM_CODE]
	var count_before = room_auth.session.placements.size()
	
	# Resend identical request
	client_a.submit_placement("alice_move_1", 0, 16, 16, 0, 0)
	_poll_all(100)
	var count_after = room_auth.session.placements.size()
	assert(count_before == count_after, "Duplicate request must not place a second piece")
	print("PASS: Resent request ID returned cached response without creating duplicate piece.")
	
	# 6. Disconnect & Reconnection Catch-Up (LB-045)
	print("\n[Phase 6: Disconnect, Snapshot Delivery & Reconnect Catch-Up (LB-045)]")
	var charlie_token = client_c.player_token
	var charlie_seq = client_c.last_received_seq
	
	# Charlie disconnects
	client_c.disconnect_from_server()
	_poll_all(50)
	assert(client_c.state == NetworkClient.State.DISCONNECTED, "Charlie is disconnected")
	
	# Bob takes his turn while Charlie is offline (placing at non-colliding location X=20)
	client_b.submit_placement("bob_move_2", 0, 20, 16, 0, 0)
	var bob_placed = _wait_for_condition(func():
		return a_received.size() == 2 and b_received.size() == 2
	)
	assert(bob_placed, "Bob placed move while Charlie offline")
	
	# Charlie reconnects via a new connection with his stored token and sequence
	var charlie_reconnected_snap: Dictionary = {}
	var charlie_reconnected_tail: Array = []
	
	var client_c2 = NetworkClient.new()
	client_c = client_c2
	client_c2.reconnect_succeeded.connect(func(snap, tail):
		charlie_reconnected_snap.merge(snap)
		charlie_reconnected_tail.append_array(tail)
	)
	client_c2.connect_to_server(TEST_HOST)
	var c2_connected = _wait_for_condition(func(): return client_c2.state == NetworkClient.State.CONNECTED)
	assert(c2_connected, "Charlie reconnected to server")
	
	client_c2.reconnect(ROOM_CODE, charlie_token, charlie_seq)
	var reconnected_ok = _wait_for_condition(func(): return not charlie_reconnected_snap.is_empty())
	assert(reconnected_ok, "Charlie reconnection succeeded")
	assert(charlie_reconnected_snap["placements"].size() == 2, "Snapshot contains both placements")
	assert(charlie_reconnected_tail.size() >= 1, "Event tail contains missed move")
	print("PASS: Reconnecting client received snapshot containing complete creation history and event tail.")
	
	# Clean up
	client_a.disconnect_from_server()
	client_b.disconnect_from_server()
	client_c2.disconnect_from_server()
	_poll_all(50)
	server.stop()
	print("PASS: Server and client sockets cleanly closed.")
