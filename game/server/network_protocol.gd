extends RefCounted
class_name NetworkProtocol

## Wire protocol opcodes, message builders, and validation contracts for LittleBricks WSS networking.

const PROTOCOL_VERSION: String = "1.0.0"

# Client -> Server Opcodes
const OP_JOIN_ROOM: String = "join_room"
const OP_SUBMIT_PLACEMENT: String = "submit_placement"
const OP_VOTE_READY: String = "vote_ready"
const OP_RECONNECT: String = "reconnect"
const OP_EXPLORER_MOVE: String = "explorer_move"
const OP_REPORT_USER: String = "report_user"

# Server -> Client Opcodes
const OP_JOIN_ACK: String = "join_ack"
const OP_PLACEMENT_BROADCAST: String = "placement_broadcast"
const OP_COMMAND_REJECTED: String = "command_rejected"
const OP_RECONNECT_ACK: String = "reconnect_ack"
const OP_PHASE_UPDATE: String = "phase_update"
const OP_ROSTER_UPDATE: String = "roster_update"
const OP_MODERATION_ACTION: String = "moderation_action"

static func make_join_request(room_code: String, player_name: String) -> Dictionary:
	return {
		"version": PROTOCOL_VERSION,
		"op": OP_JOIN_ROOM,
		"room_code": room_code.to_upper(),
		"player_name": player_name
	}

static func make_placement_submission(req_id: String, token: String, slot_idx: int, gx: int, gz: int, z: int, rot: int) -> Dictionary:
	return {
		"version": PROTOCOL_VERSION,
		"op": OP_SUBMIT_PLACEMENT,
		"request_id": req_id,
		"player_token": token,
		"slot_idx": slot_idx,
		"grid_x": gx,
		"grid_z": gz,
		"layer_plate": z,
		"rotation_step": rot
	}

static func make_reconnect_request(room_code: String, token: String, last_seq: int) -> Dictionary:
	return {
		"version": PROTOCOL_VERSION,
		"op": OP_RECONNECT,
		"room_code": room_code.to_upper(),
		"player_token": token,
		"last_seq": last_seq
	}

static func make_vote_ready_request(token: String, is_ready: bool) -> Dictionary:
	return {
		"version": PROTOCOL_VERSION,
		"op": OP_VOTE_READY,
		"player_token": token,
		"is_ready": is_ready
	}

static func make_command_rejected(req_id: String, code: String, error_msg: String) -> Dictionary:
	return {
		"version": PROTOCOL_VERSION,
		"op": OP_COMMAND_REJECTED,
		"request_id": req_id,
		"code": code,
		"error": error_msg
	}

static func make_roster_update(players: Array, current_turn_id: String) -> Dictionary:
	return {
		"version": PROTOCOL_VERSION,
		"op": OP_ROSTER_UPDATE,
		"players": players,
		"current_turn": current_turn_id
	}
