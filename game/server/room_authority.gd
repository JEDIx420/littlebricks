extends RefCounted
class_name RoomAuthority

## Authoritative room coordinator managing validation, idempotency, reconnects, and persistence (LB-017..LB-020).

const SessionManager = preload("res://core/session_manager.gd")
const SaveManager = preload("res://core/save_manager.gd")
const NetworkProtocol = preload("res://server/network_protocol.gd")

const MAX_PLAYERS: int = 4
const DISCONNECT_GRACE_PERIOD_SEC: float = 30.0

var room_code: String = "LBRICK"
var session: SessionManager

# Token -> Player Info (token, id, name, is_online, last_seen_time, blocked)
var player_tokens: Dictionary = {}
# Idempotency cache: request_id -> response dictionary
var processed_requests: Dictionary = {}

# Moderation reports
var reported_users: Array[Dictionary] = []
var blocked_tokens: Array[String] = []

func _init(p_room_code: String, p_session: SessionManager = null) -> void:
	room_code = p_room_code.to_upper()
	if p_session:
		session = p_session
	else:
		session = SessionManager.new()

## Join room or create new player slot
func handle_join(player_name: String) -> Dictionary:
	if player_tokens.size() >= MAX_PLAYERS:
		return {"success": false, "code": "ROOM_FULL", "error": "Room already has 4 players"}
		
	var p_idx = player_tokens.size()
	var p_id = "p_%d" % (p_idx + 1)
	var token = "tok_%s_%d_%d" % [p_id, Time.get_unix_time_from_system(), randi() % 10000]
	
	player_tokens[token] = {
		"token": token,
		"player_id": p_id,
		"name": player_name,
		"is_online": true,
		"last_seen": Time.get_unix_time_from_system()
	}
	
	# If first 2 players joined, start session if not started
	if player_tokens.size() == 2 and session.phase == SessionManager.SessionPhase.LOBBY:
		var names: Array[String] = []
		for p in player_tokens.values():
			names.append(p["name"])
		session.setup_session(SessionManager.GameMode.ONLINE_ROOM, names, "harbour", true)
		
	return {
		"success": true,
		"room_code": room_code,
		"player_token": token,
		"player_id": p_id,
		"assigned_slot": p_idx,
		"session_snapshot": SaveManager.serialize_session(session)
	}

## Authoritative placement command handler with strict idempotency
func handle_submit_placement(cmd: Dictionary) -> Dictionary:
	var req_id: String = cmd.get("request_id", "")
	var token: String = cmd.get("player_token", "")
	
	# 1. Idempotency check: repeated request ID returns exact cached response
	if processed_requests.has(req_id):
		return processed_requests[req_id]
		
	# 2. Token authentication & moderation check
	if token in blocked_tokens:
		var blk_resp = {"success": false, "code": "BLOCKED", "error": "User blocked by moderation"}
		processed_requests[req_id] = blk_resp
		return blk_resp
		
	if not player_tokens.has(token):
		var auth_resp = {"success": false, "code": "INVALID_TOKEN", "error": "Unrecognized session token"}
		processed_requests[req_id] = auth_resp
		return auth_resp
		
	var player_info = player_tokens[token]
	var p_id: String = player_info["player_id"]
	player_info["last_seen"] = Time.get_unix_time_from_system()
	
	# 3. Check turn ownership
	if p_id != session.get_current_player_id():
		var turn_resp = {
			"success": false,
			"code": "WRONG_TURN",
			"error": "Not your turn (Active player is %s)" % session.get_current_player_id()
		}
		processed_requests[req_id] = turn_resp
		return turn_resp
		
	var slot_idx: int = cmd.get("slot_idx", 0)
	var gx: int = cmd.get("grid_x", 0)
	var gz: int = cmd.get("grid_z", 0)
	var z: int = cmd.get("layer_plate", 0)
	var rot: int = cmd.get("rotation_step", 0)
	
	# 4. Authoritative placement attempt
	var ok: bool = session.request_placement(p_id, slot_idx, gx, gz, z, rot)
	if not ok:
		var rej_resp = {
			"success": false,
			"code": "ILLEGAL_MOVE",
			"error": "Move rejected by placement rules"
		}
		processed_requests[req_id] = rej_resp
		return rej_resp
		
	# 5. Success! Prepare broadcast
	var latest_placement = session.placements.back()
	var accept_resp = {
		"success": true,
		"op": NetworkProtocol.OP_PLACEMENT_BROADCAST,
		"request_id": req_id,
		"placement": latest_placement,
		"next_player_id": session.get_current_player_id(),
		"build_revision": session.build_revision,
		"sequence": latest_placement.get("sequence", 0)
	}
	
	# Cache result for idempotency
	processed_requests[req_id] = accept_resp
	return accept_resp

## Handle reconnect with snapshot-plus-tail event synchronization
func handle_reconnect(token: String, last_received_seq: int) -> Dictionary:
	if not player_tokens.has(token):
		return {"success": false, "code": "EXPIRED_SESSION", "error": "Session token invalid or expired"}
		
	var p_info = player_tokens[token]
	p_info["is_online"] = true
	p_info["last_seen"] = Time.get_unix_time_from_system()
	
	# Build event tail (all events after last_received_seq)
	var tail: Array = []
	for ev in session.event_journal:
		if int(ev.get("seq", 0)) > last_received_seq:
			tail.append(ev)
			
	return {
		"success": true,
		"room_code": room_code,
		"player_id": p_info["player_id"],
		"session_phase": int(session.phase),
		"build_revision": session.build_revision,
		"current_turn": session.get_current_player_id(),
		"snapshot": SaveManager.serialize_session(session),
		"event_tail": tail
	}

## Moderation: report and block user for user-generated content safety
func handle_report_user(reporter_token: String, reported_id: String, reason: String) -> Dictionary:
	reported_users.append({
		"reporter": reporter_token,
		"reported_player_id": reported_id,
		"reason": reason,
		"timestamp": Time.get_unix_time_from_system()
	})
	
	# Find token and block
	for t in player_tokens.keys():
		if player_tokens[t]["player_id"] == reported_id:
			blocked_tokens.append(t)
			player_tokens[t]["is_online"] = false
			break
			
	return {"success": true, "code": "REPORT_RECORDED", "reported_id": reported_id}
