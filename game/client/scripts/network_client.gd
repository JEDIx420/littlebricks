extends Node
class_name NetworkClient

## Client-side WebSocket networking adapter for LittleBricks online rooms (LB-044).
## Handles connection lifecycle, commands, incoming broadcasts, and reconnect catch-up (LB-045).

const NetworkProtocol = preload("res://server/network_protocol.gd")

signal connected()
signal disconnected()
signal connection_failed(error_code: int)
signal join_succeeded(data: Dictionary)
signal join_failed(code: String, error: String)
signal placement_received(placement: Dictionary, next_player_id: String, sequence: int)
signal placement_rejected(req_id: String, code: String, error: String)
signal roster_updated(players: Array, current_turn: String)
signal reconnect_succeeded(snapshot: Dictionary, event_tail: Array)
signal reconnect_failed(code: String, error: String)
signal phase_updated(phase: int, ready_count: int, total_players: int)

enum State {
	DISCONNECTED,
	CONNECTING,
	CONNECTED
}

var state: State = State.DISCONNECTED
var ws: WebSocketPeer
var server_url: String = "ws://127.0.0.1:9080"

var current_room_code: String = ""
var player_token: String = ""
var player_id: String = ""
var last_received_seq: int = 0

# Track request IDs
var pending_requests: Dictionary = {}

func _init() -> void:
	name = "NetworkClient"
	ws = WebSocketPeer.new()

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	poll()

func connect_to_server(url: String = "") -> Error:
	if not url.is_empty():
		server_url = url
		
	ws = WebSocketPeer.new()
	var err = ws.connect_to_url(server_url)
	if err != OK:
		print("[NetworkClient] FAILED to connect to %s (Error: %d)" % [server_url, err])
		state = State.DISCONNECTED
		connection_failed.emit(err)
		return err
		
	state = State.CONNECTING
	print("[NetworkClient] Connecting to %s..." % server_url)
	return OK

func disconnect_from_server() -> void:
	if ws and state != State.DISCONNECTED:
		ws.close(1000, "Normal closure")
	state = State.DISCONNECTED
	disconnected.emit()

func poll() -> void:
	if not ws or state == State.DISCONNECTED:
		return
		
	ws.poll()
	var ws_state = ws.get_ready_state()
	
	if state == State.CONNECTING:
		if ws_state == WebSocketPeer.STATE_OPEN:
			state = State.CONNECTED
			print("[NetworkClient] Connected successfully to server.")
			connected.emit()
		elif ws_state == WebSocketPeer.STATE_CLOSED:
			state = State.DISCONNECTED
			print("[NetworkClient] Connection failed during handshake.")
			connection_failed.emit(ERR_CANT_CONNECT)
			return
			
	if state == State.CONNECTED:
		if ws_state == WebSocketPeer.STATE_CLOSED or ws_state == WebSocketPeer.STATE_CLOSING:
			state = State.DISCONNECTED
			print("[NetworkClient] Disconnected from server.")
			disconnected.emit()
			return
			
		while ws.get_available_packet_count() > 0:
			var raw = ws.get_packet().get_string_from_utf8()
			_handle_server_message(raw)

func join_room(room_code: String, player_name: String) -> void:
	current_room_code = room_code.to_upper().strip_edges()
	var req = NetworkProtocol.make_join_request(current_room_code, player_name)
	_send_json(req)

func submit_placement(req_id: String, slot_idx: int, gx: int, gz: int, z: int, rot: int) -> void:
	var req = NetworkProtocol.make_placement_submission(req_id, player_token, slot_idx, gx, gz, z, rot)
	req["room_code"] = current_room_code
	pending_requests[req_id] = req
	_send_json(req)

func vote_ready(is_ready: bool) -> void:
	var req = NetworkProtocol.make_vote_ready_request(player_token, is_ready)
	req["room_code"] = current_room_code
	_send_json(req)

func reconnect(room_code: String = "", token: String = "", seq: int = -1) -> void:
	var c_code = room_code if not room_code.is_empty() else current_room_code
	var tok = token if not token.is_empty() else player_token
	var s = seq if seq >= 0 else last_received_seq
	
	var req = NetworkProtocol.make_reconnect_request(c_code, tok, s)
	_send_json(req)

func _send_json(data: Dictionary) -> void:
	if ws and ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		ws.send_text(JSON.stringify(data))

func _handle_server_message(raw_json: String) -> void:
	var json = JSON.new()
	if json.parse(raw_json) != OK or not (json.data is Dictionary):
		return
		
	var msg: Dictionary = json.data
	var op = msg.get("op", "")
	
	match op:
		NetworkProtocol.OP_JOIN_ACK:
			player_token = msg.get("player_token", "")
			player_id = msg.get("player_id", "")
			current_room_code = msg.get("room_code", "")
			join_succeeded.emit(msg)
			
		NetworkProtocol.OP_COMMAND_REJECTED:
			var req_id = msg.get("request_id", "")
			var code = msg.get("code", "")
			var err_msg = msg.get("error", "")
			if pending_requests.has(req_id):
				pending_requests.erase(req_id)
				placement_rejected.emit(req_id, code, err_msg)
			elif code == "JOIN_FAILED" or code == "ROOM_FULL":
				join_failed.emit(code, err_msg)
			elif code == "RECONNECT_FAILED":
				reconnect_failed.emit(code, err_msg)
				
		NetworkProtocol.OP_PLACEMENT_BROADCAST:
			var req_id = msg.get("request_id", "")
			if pending_requests.has(req_id):
				pending_requests.erase(req_id)
				
			var placement = msg.get("placement", {})
			var next_p = msg.get("next_player_id", "")
			var seq = msg.get("sequence", 0)
			if seq > last_received_seq:
				last_received_seq = seq
			placement_received.emit(placement, next_p, seq)
			
		NetworkProtocol.OP_ROSTER_UPDATE:
			var roster = msg.get("players", [])
			var cur_turn = msg.get("current_turn", "")
			roster_updated.emit(roster, cur_turn)
			
		NetworkProtocol.OP_PHASE_UPDATE:
			var phase = msg.get("phase", 0)
			var ready_count = msg.get("ready_count", 0)
			var total_players = msg.get("total_players", 0)
			phase_updated.emit(phase, ready_count, total_players)
			
		NetworkProtocol.OP_RECONNECT_ACK:
			player_id = msg.get("player_id", "")
			var snap = msg.get("snapshot", {})
			var tail = msg.get("event_tail", [])
			if snap.has("placements"):
				for p in snap["placements"]:
					var s = p.get("sequence", 0)
					if s > last_received_seq:
						last_received_seq = s
			reconnect_succeeded.emit(snap, tail)
