extends RefCounted
class_name SessionManager

## Session state machine, turn controller, inventory deal, and finish agreement.
## Shared pure logic across local pass-and-play, solo, and authoritative server.

enum GameMode { SOLO_CREATIVE, SOLO_CHALLENGE, PASS_AND_PLAY, ONLINE_ROOM }
enum SessionPhase { LOBBY, BUILDING, FINISH_AGREEMENT, EXPLORATION, REPLAY }

signal phase_changed(new_phase: SessionPhase)
signal turn_advanced(player_id: String, player_idx: int)
signal placement_accepted(placement_event: Dictionary)
signal placement_rejected(reason: String, code: String)
signal inventory_refilled(player_id: String, new_piece: Dictionary, slot_idx: int)
signal timer_ticked(seconds_remaining: float)
signal timer_expired(skipped_player_id: String)
signal ready_status_changed(player_id: String, is_ready: bool, total_ready: int, total_players: int)

const PartCatalog = preload("res://core/part_catalog.gd")
const PlacementRules = preload("res://core/placement_rules.gd")

var mode: GameMode = GameMode.SOLO_CREATIVE
var phase: SessionPhase = SessionPhase.LOBBY
var theme_id: String = "harbour"

var catalog: PartCatalog
var rules: PlacementRules

# Players & turn state
var players: Array[Dictionary] = []
var current_player_idx: int = 0
var timer_enabled: bool = false
var timer_duration_sec: float = 20.0
var time_remaining_sec: float = 20.0

# Board & history
var placements: Array[Dictionary] = []
var event_journal: Array[Dictionary] = []
var redo_stack: Array[Dictionary] = []
var _undo_stack: Array[Dictionary] = []
var build_revision: int = 1
var _next_event_seq: int = 1

# Themed bag state
var _rng: RandomNumberGenerator

func _init(p_catalog: PartCatalog = null, p_rules: PlacementRules = null) -> void:
	if p_catalog:
		catalog = p_catalog
	else:
		catalog = PartCatalog.new()
		catalog.load_catalog("res://assets/catalog/parts_manifest.json")
		
	if p_rules:
		rules = p_rules
	else:
		rules = PlacementRules.new(catalog)
		
	_rng = RandomNumberGenerator.new()
	_rng.randomize()

func setup_session(p_mode: GameMode, player_names: Array[String], p_theme: String = "harbour", p_timer: bool = false) -> void:
	mode = p_mode
	theme_id = p_theme
	timer_enabled = p_timer
	phase = SessionPhase.BUILDING
	current_player_idx = 0
	time_remaining_sec = timer_duration_sec
	
	players.clear()
	placements.clear()
	event_journal.clear()
	_undo_stack.clear()
	redo_stack.clear()
	build_revision = 1
	_next_event_seq = 1
	
	var default_colors = [
		Color(0.85, 0.15, 0.15), # Red
		Color(0.15, 0.35, 0.85), # Blue
		Color(0.9, 0.75, 0.1),   # Yellow
		Color(0.18, 0.65, 0.25)  # Green
	]
	
	for i in range(player_names.size()):
		var p_id: String = "p_%d" % (i + 1)
		var p_color: Color = default_colors[i % default_colors.size()]
		var player_dict: Dictionary = {
			"id": p_id,
			"name": player_names[i],
			"color": p_color,
			"hand": [],
			"is_ready_to_explore": false
		}
		
		# Deal 6 pieces to each player's hand
		for slot in range(6):
			player_dict["hand"].append(_draw_piece_from_theme(slot, player_dict["hand"]))
			
		players.append(player_dict)
		
	phase_changed.emit(phase)
	var active_id = get_current_player_id()
	turn_advanced.emit(active_id, current_player_idx)

func get_current_player_id() -> String:
	if players.is_empty():
		return ""
	return players[current_player_idx]["id"]

func get_current_player() -> Dictionary:
	if players.is_empty():
		return {}
	return players[current_player_idx]

## Tick turn timer if enabled
func tick_timer(delta: float) -> void:
	if not timer_enabled or phase != SessionPhase.BUILDING:
		return
		
	time_remaining_sec -= delta
	timer_ticked.emit(max(0.0, time_remaining_sec))
	
	if time_remaining_sec <= 0.0:
		skip_turn()

## Skip turn on timeout or user voluntary skip
func skip_turn() -> void:
	if phase != SessionPhase.BUILDING or players.is_empty():
		return
		
	var skipped_id = get_current_player_id()
	timer_expired.emit(skipped_id)
	
	# Record skip event
	_record_event("TURN_SKIPPED", {
		"player_id": skipped_id,
		"reason": "TIMEOUT_OR_PASS"
	})
	
	# Advance turn without consuming any pieces
	_advance_turn()

## Attempt placement on current turn (Authoritative)
func request_placement(player_id: String, hand_slot_idx: int, gx: int, gz: int, z_plate: int, rot_step: int, piece_color = null, part_id_override: String = "") -> bool:
	if phase != SessionPhase.BUILDING:
		placement_rejected.emit("Not in building phase", "INVALID_PHASE")
		return false
		
	if mode == GameMode.SOLO_CREATIVE:
		var part_id = part_id_override
		if part_id.is_empty():
			if not players.is_empty() and hand_slot_idx >= 0 and hand_slot_idx < players[current_player_idx]["hand"].size():
				part_id = players[current_player_idx]["hand"][hand_slot_idx].get("part_id", "brick_2x4")
			else:
				part_id = "brick_2x4"
				
		var col = piece_color
		if col == null:
			if not players.is_empty():
				col = players[current_player_idx].get("color", Color.WHITE)
			else:
				col = Color.WHITE
				
		var val_res = rules.validate_placement(part_id, gx, gz, z_plate, rot_step, placements)
		if not val_res.get("valid", false):
			placement_rejected.emit(val_res.get("reason", "Placement invalid"), val_res.get("code", "INVALID"))
			return false
			
		var placement_record = {
			"placement_id": "pl_%d" % _next_event_seq,
			"sequence": _next_event_seq,
			"player_id": player_id,
			"part_id": part_id,
			"grid_x": gx,
			"grid_z": gz,
			"layer_plate": z_plate,
			"rotation_step": rot_step,
			"color": col
		}
		_accept_placement(placement_record)
		_record_event("PLACEMENT_ACCEPTED", placement_record)
		_clear_all_readiness()
		placement_accepted.emit(placement_record)
		return true

	# Bag / Pass & Play / Online mode: strictly validate active player and hand slot
	if player_id != get_current_player_id():
		placement_rejected.emit("Not this player's turn", "WRONG_TURN")
		return false
		
	var player = players[current_player_idx]
	var hand: Array = player["hand"]
	var slot_to_use: int = hand_slot_idx
	if slot_to_use < 0 or slot_to_use >= hand.size() or (not part_id_override.is_empty() and hand[slot_to_use].get("part_id") != part_id_override):
		# Search hand for part_id_override
		var found_slot: int = -1
		if not part_id_override.is_empty():
			for i in range(hand.size()):
				if hand[i].get("part_id") == part_id_override:
					found_slot = i
					break
		if found_slot != -1:
			slot_to_use = found_slot
		else:
			if not part_id_override.is_empty():
				placement_rejected.emit("Selected part '%s' is not in active hand" % part_id_override, "OUTSIDE_HAND")
			else:
				placement_rejected.emit("Invalid hand slot", "INVALID_SLOT")
			return false
		
	var piece_item: Dictionary = hand[slot_to_use]
	var part_id: String = piece_item.get("part_id", "")
	var col = piece_color if piece_color != null else piece_item.get("color", player["color"])
	
	# Authoritative rule check
	var val_res = rules.validate_placement(part_id, gx, gz, z_plate, rot_step, placements)
	if not val_res.get("valid", false):
		placement_rejected.emit(val_res.get("reason", "Placement invalid"), val_res.get("code", "INVALID"))
		return false
		
	# Placement accepted!
	var placement_record = {
		"placement_id": "pl_%d" % _next_event_seq,
		"sequence": _next_event_seq,
		"player_id": player_id,
		"part_id": part_id,
		"grid_x": gx,
		"grid_z": gz,
		"layer_plate": z_plate,
		"rotation_step": rot_step,
		"color": col
	}
	_accept_placement(placement_record)
	_record_event("PLACEMENT_ACCEPTED", placement_record)
	
	# Refill hand slot
	var new_piece = _draw_piece_from_theme(slot_to_use, player["hand"])
	player["hand"][slot_to_use] = new_piece
	inventory_refilled.emit(player_id, new_piece, slot_to_use)
	
	_clear_all_readiness()
	placement_accepted.emit(placement_record)
	
	# Advance turn
	if players.size() > 1:
		_advance_turn()
	return true

## Submit placement directly by part_id (used by TableView/solo builder and authoritative router)
func submit_placement(player_id: String, part_id: String, gx: int, gz: int, z_plate: int, rot_step: int, piece_color = null) -> bool:
	var slot_idx: int = -1
	if not players.is_empty():
		var hand = players[current_player_idx].get("hand", [])
		for i in range(hand.size()):
			if hand[i].get("part_id") == part_id:
				slot_idx = i
				break
	return request_placement(player_id, slot_idx, gx, gz, z_plate, rot_step, piece_color, part_id)

## Vote ready to explore
func set_ready_to_explore(player_id: String, is_ready: bool) -> void:
	var p_found = false
	for p in players:
		if p["id"] == player_id:
			p["is_ready_to_explore"] = is_ready
			p_found = true
			break
			
	if not p_found:
		return
		
	var ready_count: int = 0
	for p in players:
		if p.get("is_ready_to_explore", false):
			ready_count += 1
			
	ready_status_changed.emit(player_id, is_ready, ready_count, players.size())
	
	# If solo or all active players agree, transition to exploration
	if ready_count == players.size():
		transition_to_exploration()

func transition_to_exploration() -> void:
	phase = SessionPhase.EXPLORATION
	_record_event("PHASE_CHANGED", {"new_phase": "EXPLORATION", "revision": build_revision})
	phase_changed.emit(phase)

func return_to_building_new_revision() -> void:
	phase = SessionPhase.BUILDING
	build_revision += 1
	_clear_all_readiness()
	_record_event("PHASE_CHANGED", {"new_phase": "BUILDING", "revision": build_revision})
	phase_changed.emit(phase)

func _clear_all_readiness() -> void:
	for p in players:
		p["is_ready_to_explore"] = false

func _advance_turn() -> void:
	current_player_idx = (current_player_idx + 1) % players.size()
	time_remaining_sec = timer_duration_sec
	var active_id = get_current_player_id()
	turn_advanced.emit(active_id, current_player_idx)

func _accept_placement(placement: Dictionary) -> void:
	if mode != GameMode.ONLINE_ROOM:
		_undo_stack.append({"kind": "place", "placement": placement, "index": placements.size()})
		redo_stack.clear()
	placements.append(placement)

## Erase a specific brick during solo building, preserving the rest of the board.
func erase_placement(placement_id: String) -> Dictionary:
	if mode != GameMode.SOLO_CREATIVE and mode != GameMode.SOLO_CHALLENGE:
		return _edit_error("You can erase individual bricks in solo builds.", "SOLO_ONLY")
	if phase != SessionPhase.BUILDING:
		return _edit_error("Return to building to erase a brick.", "INVALID_PHASE")
	var index := _find_placement(placement_id)
	if index < 0:
		return _edit_error("That brick is no longer on the plate.", "NOT_FOUND")
	var action := {"kind": "erase", "placement": placements[index], "index": index}
	var result := _remove_placement(index, "PLACEMENT_ERASED", "removed_placement")
	if result["success"]:
		_undo_stack.append(action)
		redo_stack.clear()
	return result

## Undo the most recent edit. A placement is removed and an erase is restored.
func undo_last_placement() -> Dictionary:
	if _undo_stack.is_empty():
		return _edit_error("No actions to undo", "EMPTY")
	var action: Dictionary = _undo_stack.back()
	var result: Dictionary
	if action["kind"] == "erase":
		result = _restore_placement(action, "PLACEMENT_ERASE_UNDONE", "restored_placement")
	else:
		var index := _find_placement(action["placement"].get("placement_id", ""))
		result = _remove_placement(index, "PLACEMENT_UNDONE", "undone_placement")
	if result["success"]:
		_undo_stack.pop_back()
		redo_stack.append(action)
	return result

## Redo the next edit in the same order it happened originally.
func redo_placement() -> Dictionary:
	if redo_stack.is_empty():
		return _edit_error("No actions to redo", "EMPTY")
	var action: Dictionary = redo_stack.back()
	var result: Dictionary
	if action["kind"] == "erase":
		var index := _find_placement(action["placement"].get("placement_id", ""))
		result = _remove_placement(index, "PLACEMENT_ERASE_REDONE", "removed_placement")
	else:
		result = _restore_placement(action, "PLACEMENT_REDONE", "redone_placement")
	if result["success"]:
		redo_stack.pop_back()
		_undo_stack.append(action)
	return result

func _find_placement(id: String) -> int:
	if not id.is_empty():
		for i in range(placements.size()):
			if placements[i].get("placement_id", "") == id:
				return i
	return -1

func _remove_placement(index: int, event_type: String, result_key: String) -> Dictionary:
	if index < 0:
		return _edit_error("That brick is no longer on the plate.", "NOT_FOUND")
	var placement: Dictionary = placements[index]
	if _has_dependent_placement(index):
		return _edit_error("Remove the bricks resting on this one first.", "DEPENDENT_MOVE_EXISTS")
	placements.remove_at(index)
	_record_edit_event(event_type, placement)
	_clear_all_readiness()
	return {"success": true, result_key: placement}

func _restore_placement(action: Dictionary, event_type: String, result_key: String) -> Dictionary:
	var placement: Dictionary = action["placement"]
	if _find_placement(placement.get("placement_id", "")) >= 0 or not _validate_record(placement, placements):
		return _edit_error("That brick no longer fits in this spot.", "INVALID_STATE")
	placements.insert(clampi(int(action["index"]), 0, placements.size()), placement)
	_record_edit_event(event_type, placement)
	_clear_all_readiness()
	return {"success": true, result_key: placement}

func _record_edit_event(event_type: String, placement: Dictionary) -> void:
	var record := placement.duplicate()
	record["color_hex"] = (record.get("color", Color.WHITE) as Color).to_html()
	record.erase("color")
	_record_event(event_type, record)

func _validate_record(placement: Dictionary, board: Array) -> bool:
	return rules.validate_placement(
		placement.get("part_id", ""), placement.get("grid_x", 0), placement.get("grid_z", 0),
		placement.get("layer_plate", 0), placement.get("rotation_step", 0), board
	).get("valid", false)

func _top_studs(placement: Dictionary) -> Array[Vector3i]:
	return rules.get_absolute_top_studs(
		placement.get("part_id", ""), placement.get("grid_x", 0), placement.get("grid_z", 0),
		placement.get("layer_plate", 0), placement.get("rotation_step", 0)
	)

func _bottom_sockets(placement: Dictionary) -> Array[Vector3i]:
	return rules.get_absolute_bottom_sockets(
		placement.get("part_id", ""), placement.get("grid_x", 0), placement.get("grid_z", 0),
		placement.get("layer_plate", 0), placement.get("rotation_step", 0)
	)

func _has_dependent_placement(removed_index: int) -> bool:
	var lost_studs := _top_studs(placements[removed_index])
	if lost_studs.is_empty():
		return false
	var remaining_studs: Dictionary = {}
	for i in range(placements.size()):
		if i != removed_index:
			for stud in _top_studs(placements[i]):
				remaining_studs[stud] = int(remaining_studs.get(stud, 0)) + 1
	for i in range(placements.size()):
		if i == removed_index or int(placements[i].get("layer_plate", 0)) == 0:
			continue
		var lost_support := false
		var stays_supported := false
		var brick_studs := _top_studs(placements[i])
		for socket in _bottom_sockets(placements[i]):
			lost_support = lost_support or socket in lost_studs
			var self_support: int = 1 if socket in brick_studs else 0
			stays_supported = stays_supported or int(remaining_studs.get(socket, 0)) > self_support
		if lost_support and not stays_supported:
			return true
	return false

func _edit_error(reason: String, code: String) -> Dictionary:
	return {"success": false, "reason": reason, "code": code}

## Return the final model's bricks in a buildable order for the construction film.
## A span may now use an alternate support that was added after the span.
func get_replay_placements() -> Array[Dictionary]:
	var pending := placements.duplicate()
	var ordered: Array[Dictionary] = []
	var supports: Dictionary = {}
	while not pending.is_empty():
		var deferred: Array[Dictionary] = []
		for placement in pending:
			var anchored: bool = int(placement.get("layer_plate", 0)) == 0
			if not anchored:
				for socket in _bottom_sockets(placement):
					if socket in supports:
						anchored = true
						break
			if anchored:
				ordered.append(placement)
				for stud in _top_studs(placement):
					supports[stud] = true
			else:
				deferred.append(placement)
		if deferred.size() == pending.size():
			# Older saves may contain placements accepted under earlier rules.
			ordered.append_array(deferred)
			break
		pending = deferred
	return ordered

func get_edit_history() -> Dictionary:
	return {"undo": _undo_stack.duplicate(true), "redo": redo_stack.duplicate(true)}

func restore_edit_history(undo: Array[Dictionary], redo: Array[Dictionary]) -> void:
	_undo_stack.assign(undo)
	redo_stack.assign(redo)

## Pre-erase saves have no edit history; their surviving bricks can still be undone.
func seed_placement_history() -> void:
	_undo_stack.clear()
	redo_stack.clear()
	for index in range(placements.size()):
		_undo_stack.append({"kind": "place", "index": index, "placement": placements[index]})

func _record_event(type: String, data: Dictionary) -> void:
	var event: Dictionary = {
		"seq": _next_event_seq,
		"type": type,
		"timestamp": Time.get_unix_time_from_system(),
		"revision": build_revision,
		"data": data
	}
	_next_event_seq += 1
	event_journal.append(event)

func _draw_piece_from_theme(slot_idx: int, player_hand: Array = []) -> Dictionary:
	var pack: Dictionary = catalog.get_theme(theme_id)
	var is_expansion: bool = pack.get("include_core", false)
	var theme_parts = catalog.get_theme_parts(theme_id)
	if theme_parts.is_empty():
		theme_parts = catalog.get_theme_parts("core")
		
	# Balanced hand distribution (LB-073):
	# Target: 70-80% common structural (bricks & plates), 20-30% specialty accents.
	# Guarantees at least 2 foundational bricks and at least 4 total structural pieces in every 6-slot hand.
	var brick_count: int = 0
	var plate_count: int = 0
	var has_pack_part: bool = false
	for idx in range(player_hand.size()):
		if idx == slot_idx:
			continue # Skip the slot being replaced
		var item = player_hand[idx]
		var p_id: String = item.get("part_id", "")
		var hand_part := catalog.get_part(p_id)
		var p_cat: String = hand_part.get("category", "")
		has_pack_part = has_pack_part or theme_id in hand_part.get("theme_tags", [])
		if p_cat == "brick":
			brick_count += 1
		elif p_cat == "plate":
			plate_count += 1
			
	var candidate_parts: Array[Dictionary] = []
	if brick_count < 2:
		# Guarantee at least 2 classic structural bricks (2x4, 2x2, 1x4, etc.)
		for p in theme_parts:
			if p.get("category") == "brick":
				candidate_parts.append(p)
	elif (brick_count + plate_count) < 4:
		# Guarantee at least 4 total structural pieces (bricks + plates)
		for p in theme_parts:
			var c = p.get("category", "")
			if c == "brick" or c == "plate":
				candidate_parts.append(p)
	else:
		candidate_parts = theme_parts
		
	if candidate_parts.is_empty():
		candidate_parts = theme_parts
	if is_expansion and not has_pack_part:
		var themed_choices := candidate_parts.filter(func(part: Dictionary) -> bool:
			return theme_id in part.get("theme_tags", [])
		)
		if not themed_choices.is_empty():
			candidate_parts = themed_choices

	# Select weighted piece
	var total_weight: int = 0
	for p in candidate_parts:
		total_weight += int(p.get("bag_weight", 10))
		
	var pick = _rng.randi_range(1, max(1, total_weight))
	var cum: int = 0
	var chosen_part: Dictionary = candidate_parts[0]
	for p in candidate_parts:
		cum += int(p.get("bag_weight", 10))
		if pick <= cum:
			chosen_part = p
			break
			
	var palette = [
		Color(0.85, 0.15, 0.15), Color(0.15, 0.35, 0.85),
		Color(0.9, 0.75, 0.1), Color(0.92, 0.92, 0.92),
		Color(0.2, 0.55, 0.25), Color(0.4, 0.25, 0.15)
	]
	if is_expansion and not pack.get("palette", []).is_empty():
		palette.clear()
		for swatch in pack["palette"]:
			palette.append(Color.from_string(String(swatch), Color.WHITE))

	return {
		"instance_id": "item_%d_%d" % [Time.get_ticks_msec(), slot_idx],
		"part_id": chosen_part.get("id", "brick_2x4"),
		"name": chosen_part.get("name", "Brick"),
		"color": palette[_rng.randi() % palette.size()]
	}
