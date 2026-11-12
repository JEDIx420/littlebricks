extends Node
class_name LittleBricksServer

## Authoritative WebSocket game server for LittleBricks private rooms (LB-044).
## Supports 2-4 player rooms, turn-based synchronization, idempotency,
## snapshot recovery, and client reconnection (LB-045).

const RoomAuthority = preload("res://server/room_authority.gd")
const NetworkProtocol = preload("res://server/network_protocol.gd")
const SessionManager = preload("res://core/session_manager.gd")
const PartCatalog = preload("res://core/part_catalog.gd")
const SaveManager = preload("res://core/save_manager.gd")
const CODE_ALPHABET := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
const PlacementRules = preload("res://core/placement_rules.gd")

var tcp_server: TCPServer
var is_running: bool = false
var server_port: int = 9080

# room_code (String) -> RoomAuthority
var rooms: Dictionary = {}

# Active connected client sessions
# [{ "ws": WebSocketPeer, "token": String, "room_code": String, "player_id": String, "name": String }]
var clients: Array[Dictionary] = []

var catalog: PartCatalog
var rules: PlacementRules

func _init() -> void:
	name = "LittleBricksServer"
	catalog = PartCatalog.new()
	catalog.load_catalog("res://assets/catalog/parts_manifest.json")
	rules = PlacementRules.new(catalog)

func _process(_delta: float) -> void:
	if is_running:
		poll()

func start(port: int = 9080, bind_address: String = "0.0.0.0") -> Error:
	server_port = port
	tcp_server = TCPServer.new()
	var err = tcp_server.listen(port, bind_address)
	if err != OK:
		print("[Server] FAILED to listen on %s:%d (Error: %d)" % [bind_address, port, err])
		return err
	is_running = true
	print("[Server] LittleBricks Authoritative Server listening on %s:%d" % [bind_address, port])
	return OK

func stop() -> void:
	if not is_running:
		return
	for c in clients:
		if c["ws"]:
			c["ws"].close(1000, "Server shutting down")
	clients.clear()
	if tcp_server:
		tcp_server.stop()
	is_running = false
	print("[Server] Server stopped.")

func poll() -> void:
	if not is_running or not tcp_server:
		return
		
	# 1. Accept new incoming TCP connections
	while tcp_server.is_connection_available():
		var tcp_conn = tcp_server.take_connection()
		var ws = WebSocketPeer.new()
		var err = ws.accept_stream(tcp_conn)
		if err == OK:
			clients.append({
				"ws": ws,
				"token": "",
				"room_code": "",
				"player_id": "",
				"name": ""
			})
			print("[Server] Accepted new incoming WebSocket stream (total: %d)" % clients.size())
			
	# 2. Poll existing connected clients
	var to_remove: Array[int] = []
	for i in range(clients.size()):
		var c = clients[i]
		var ws: WebSocketPeer = c["ws"]
		ws.poll()
		
		var state = ws.get_ready_state()
		if state == WebSocketPeer.STATE_OPEN:
			while ws.get_available_packet_count() > 0:
				var raw_pkt = ws.get_packet().get_string_from_utf8()
				_process_client_packet(i, raw_pkt)
		elif state == WebSocketPeer.STATE_CLOSED or state == WebSocketPeer.STATE_CLOSING:
			_handle_client_disconnected(c)
			to_remove.append(i)
			
	# Remove closed clients in reverse order
	to_remove.reverse()
	for idx in to_remove:
		clients.remove_at(idx)

func _get_or_create_room(room_code: String) -> RoomAuthority:
	var code = room_code.to_upper().strip_edges()
	if not rooms.has(code):
		var session = SessionManager.new(catalog, rules)
		rooms[code] = RoomAuthority.new(code, session)
		print("[Server] Created new room authority: %s" % code)
	return rooms[code]

func _process_client_packet(client_idx: int, raw_json: String) -> void:
	var json = JSON.new()
	var parse_err = json.parse(raw_json)
	if parse_err != OK or not (json.data is Dictionary):
		_send_to_client(clients[client_idx], NetworkProtocol.make_command_rejected("", "MALFORMED_JSON", "Invalid JSON payload"))
		return
		
	var msg: Dictionary = json.data
	var op = msg.get("op", "")
	var c = clients[client_idx]
	
	match op:
		NetworkProtocol.OP_CREATE_ROOM:
			_handle_join(c, msg, true)
		NetworkProtocol.OP_JOIN_ROOM:
			_handle_join(c, msg)
		NetworkProtocol.OP_SUBMIT_PLACEMENT:
			_handle_submit_placement(c, msg)
		NetworkProtocol.OP_VOTE_READY:
			_handle_vote_ready(c, msg)
		NetworkProtocol.OP_RECONNECT:
			_handle_reconnect(c, msg)
		NetworkProtocol.OP_REPORT_USER:
			_handle_report_user(c, msg)
		_:
			_send_to_client(c, NetworkProtocol.make_command_rejected(msg.get("request_id", ""), "UNKNOWN_OPCODE", "Unknown opcode: %s" % op))

func _handle_join(client: Dictionary, msg: Dictionary, create: bool = false) -> void:
	if not client["room_code"].is_empty():
		_send_to_client(client, NetworkProtocol.make_command_rejected("", "JOIN_FAILED", "Already in a room"))
		return
	var room_code := str(msg.get("room_code", "")).to_upper().strip_edges()
	var player_name := str(msg.get("player_name", "")).strip_edges().left(24)
	if player_name.is_empty():
		player_name = "Builder"

	if create:
		room_code = _new_room_code()
		_get_or_create_room(room_code).private_lobby = true
	elif room_code.is_empty() or (msg.get("invite_only", false) and (not rooms.has(room_code) or not rooms[room_code].private_lobby)):
		_send_to_client(client, NetworkProtocol.make_command_rejected("", "JOIN_FAILED", "Room code not found. Check the code and try again."))
		return

	var room = _get_or_create_room(room_code)
	if room.private_lobby and room.session.phase != SessionManager.SessionPhase.LOBBY:
		_send_to_client(client, NetworkProtocol.make_command_rejected("", "JOIN_FAILED", "This room has already started building."))
		return
	var res = room.handle_join(player_name)
	
	if not res.get("success", false):
		_send_to_client(client, {
			"version": NetworkProtocol.PROTOCOL_VERSION,
			"op": NetworkProtocol.OP_COMMAND_REJECTED,
			"code": res.get("code", "JOIN_FAILED"),
			"error": res.get("error", "Could not join room")
		})
		return
		
	client["room_code"] = room_code
	client["token"] = res["player_token"]
	client["player_id"] = res["player_id"]
	client["name"] = player_name
	
	var join_ack = {
		"version": NetworkProtocol.PROTOCOL_VERSION,
		"op": NetworkProtocol.OP_JOIN_ACK,
		"success": true,
		"room_code": room_code,
		"player_id": res["player_id"],
		"player_token": res["player_token"],
		"assigned_slot": res["assigned_slot"],
		"session_snapshot": res["session_snapshot"]
	}
	_send_to_client(client, join_ack)
	
	_broadcast_roster(room)

func _new_room_code() -> String:
	while true:
		var code := ""
		for byte in Crypto.new().generate_random_bytes(6):
			code += CODE_ALPHABET[byte % CODE_ALPHABET.length()]
		if not rooms.has(code):
			return code
	return ""

func _broadcast_roster(room: RoomAuthority) -> void:
	var roster: Array = []
	for p_info in room.player_tokens.values():
		roster.append({
			"id": p_info["player_id"],
			"name": p_info["name"],
			"is_online": p_info.get("is_online", true),
			"is_ready": p_info.get("lobby_ready", false)
		})
	_broadcast_to_room(room.room_code, NetworkProtocol.make_roster_update(roster, room.session.get_current_player_id()))

func _handle_submit_placement(client: Dictionary, msg: Dictionary) -> void:
	var room_code = client.get("room_code", msg.get("room_code", "")).to_upper()
	if not rooms.has(room_code):
		_send_to_client(client, NetworkProtocol.make_command_rejected(msg.get("request_id", ""), "ROOM_NOT_FOUND", "Room not found"))
		return
		
	var room = rooms[room_code]
	if client["token"].is_empty() or msg.get("player_token", "") != client["token"]:
		_send_to_client(client, NetworkProtocol.make_command_rejected(str(msg.get("request_id", "")), "INVALID_TOKEN", "Join the room before placing a brick"))
		return
	var res = room.handle_submit_placement(msg)
	
	if not res.get("success", false):
		_send_to_client(client, NetworkProtocol.make_command_rejected(msg.get("request_id", ""), res.get("code", "REJECTED"), res.get("error", "Placement rejected")))
		return
		
	# Broadcast accepted placement to all players in the room
	_broadcast_to_room(room_code, res)

func _handle_vote_ready(client: Dictionary, msg: Dictionary) -> void:
	var room_code = client.get("room_code", "").to_upper()
	if not rooms.has(room_code):
		return
	var room = rooms[room_code]
	var token = msg.get("player_token", client.get("token", ""))
	var is_ready = msg.get("is_ready", true)
	
	if token != client["token"] or not room.player_tokens.has(token):
		return
	if room.private_lobby and room.session.phase == SessionManager.SessionPhase.LOBBY:
		room.player_tokens[token]["lobby_ready"] = bool(is_ready)
		var names: Array[String] = []
		for player in room.player_tokens.values():
			if not player.get("lobby_ready", false):
				_broadcast_roster(room)
				return
			names.append(player["name"])
		if names.size() >= 2:
			room.session.setup_session(SessionManager.GameMode.ONLINE_ROOM, names, "harbour", false)
			var index := 0
			for player_token in room.player_tokens:
				room.player_tokens[player_token]["player_id"] = room.session.players[index]["id"]
				index += 1
			var snapshot := SaveManager.serialize_session(room.session)
			for connection in clients:
				if connection["room_code"] == room_code and room.player_tokens.has(connection["token"]):
					connection["player_id"] = room.player_tokens[connection["token"]]["player_id"]
					_send_to_client(connection, {
						"op": NetworkProtocol.OP_BUILD_STARTED,
						"session_snapshot": snapshot,
						"player_id": connection["player_id"]
					})
		else:
			_broadcast_roster(room)
		return
	var p_id = room.player_tokens[token]["player_id"]
	room.session.set_ready_to_explore(p_id, is_ready)
	
	var ready_count = 0
	for p in room.session.players:
		if p.get("is_ready_to_explore", false):
			ready_count += 1
			
	var vote_update = {
		"version": NetworkProtocol.PROTOCOL_VERSION,
		"op": NetworkProtocol.OP_PHASE_UPDATE,
		"phase": int(room.session.phase),
		"ready_count": ready_count,
		"total_players": room.session.players.size()
	}
	_broadcast_to_room(room_code, vote_update)

func _handle_reconnect(client: Dictionary, msg: Dictionary) -> void:
	var room_code = msg.get("room_code", "").to_upper()
	var token = msg.get("player_token", "")
	var last_seq = msg.get("last_seq", 0)
	
	if not rooms.has(room_code):
		_send_to_client(client, NetworkProtocol.make_command_rejected("", "ROOM_NOT_FOUND", "Room expired or not found"))
		return
		
	var room = rooms[room_code]
	var res = room.handle_reconnect(token, last_seq)
	if not res.get("success", false):
		_send_to_client(client, NetworkProtocol.make_command_rejected("", res.get("code", "RECONNECT_FAILED"), res.get("error", "Reconnect rejected")))
		return
		
	client["room_code"] = room_code
	client["token"] = token
	client["player_id"] = res["player_id"]
	client["name"] = room.player_tokens[token].get("name", "Player")
	
	var ack = {
		"version": NetworkProtocol.PROTOCOL_VERSION,
		"op": NetworkProtocol.OP_RECONNECT_ACK,
		"success": true,
		"room_code": room_code,
		"player_id": res["player_id"],
		"session_phase": res["session_phase"],
		"build_revision": res["build_revision"],
		"current_turn": res["current_turn"],
		"snapshot": res["snapshot"],
		"event_tail": res["event_tail"]
	}
	_send_to_client(client, ack)
	print("[Server] Player %s reconnected to room %s with tail length %d" % [res["player_id"], room_code, res["event_tail"].size()])

func _handle_report_user(client: Dictionary, msg: Dictionary) -> void:
	var room_code = client.get("room_code", "").to_upper()
	if not rooms.has(room_code):
		return
	var room = rooms[room_code]
	var res = room.handle_report_user(msg.get("reporter_token", client.get("token", "")), msg.get("reported_id", ""), msg.get("reason", "Inappropriate content"))
	_send_to_client(client, {
		"version": NetworkProtocol.PROTOCOL_VERSION,
		"op": NetworkProtocol.OP_MODERATION_ACTION,
		"result": res
	})

func _handle_client_disconnected(client: Dictionary) -> void:
	var room_code = client.get("room_code", "")
	var token = client.get("token", "")
	if room_code.is_empty() or not rooms.has(room_code):
		return
	var room = rooms[room_code]
	if room.player_tokens.has(token):
		room.player_tokens[token]["is_online"] = false
		print("[Server] Client disconnected: %s in room %s" % [client.get("player_id", "anon"), room_code])
		
		if room.private_lobby and room.session.phase == SessionManager.SessionPhase.LOBBY:
			room.player_tokens.erase(token)
			if room.player_tokens.is_empty():
				rooms.erase(room_code)
				return
			# Lobby slots may move before the build starts. Reserve the
			# session's fixed player IDs in current roster order at start.
			for player in room.player_tokens.values():
				player["lobby_ready"] = false
		if room.private_lobby and not room.player_tokens.values().any(func(player): return player["is_online"]):
			rooms.erase(room_code)
			return
		_broadcast_roster(room)

func _broadcast_to_room(room_code: String, message: Dictionary, exclude_token: String = "") -> void:
	var text = JSON.stringify(message)
	for c in clients:
		if c.get("room_code", "") == room_code:
			if exclude_token.is_empty() or c.get("token", "") != exclude_token:
				var ws: WebSocketPeer = c["ws"]
				if ws and ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
					ws.send_text(text)

func _send_to_client(client: Dictionary, message: Dictionary) -> void:
	var ws: WebSocketPeer = client.get("ws", null)
	if ws and ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		ws.send_text(JSON.stringify(message))
