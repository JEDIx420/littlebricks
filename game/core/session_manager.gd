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

## Attempt placement on current turn
func request_placement(player_id: String, hand_slot_idx: int, gx: int, gz: int, z_plate: int, rot_step: int) -> bool:
	if phase != SessionPhase.BUILDING:
		placement_rejected.emit("Not in building phase", "INVALID_PHASE")
		return false
		
	if player_id != get_current_player_id():
		placement_rejected.emit("Not this player's turn", "WRONG_TURN")
		return false
		
	var player = players[current_player_idx]
	var hand: Array = player["hand"]
	if hand_slot_idx < 0 or hand_slot_idx >= hand.size():
		placement_rejected.emit("Invalid hand slot", "INVALID_SLOT")
		return false
		
	var piece_item: Dictionary = hand[hand_slot_idx]
	var part_id: String = piece_item.get("part_id", "")
	var piece_color: Color = piece_item.get("color", player["color"])
	
	# Authoritative rule check
	var val_res = rules.validate_placement(part_id, gx, gz, z_plate, rot_step, placements)
	if not val_res.get("valid", false):
		placement_rejected.emit(val_res.get("reason", "Placement invalid"), val_res.get("code", "INVALID"))
		return false
		
	# Placement accepted!
	var placement_record = {
		"placement_id": "pl_%d" % (placements.size() + 1),
		"sequence": _next_event_seq,
		"player_id": player_id,
		"part_id": part_id,
		"grid_x": gx,
		"grid_z": gz,
		"layer_plate": z_plate,
		"rotation_step": rot_step,
		"color": piece_color
	}
	placements.append(placement_record)
	
	# Record accepted event
	_record_event("PLACEMENT_ACCEPTED", placement_record)
	
	# Refill hand slot
	var new_piece = _draw_piece_from_theme(hand_slot_idx, player["hand"])
	player["hand"][hand_slot_idx] = new_piece
	inventory_refilled.emit(player_id, new_piece, hand_slot_idx)
	
	# Any new placement clears readiness votes
	_clear_all_readiness()
	
	placement_accepted.emit(placement_record)
	
	# Advance turn
	_advance_turn()
	return true

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

## Undo the last placement with dependent-move protection
func undo_last_placement() -> Dictionary:
	if placements.is_empty():
		return {"success": false, "reason": "No placements to undo", "code": "EMPTY"}
		
	var last_placement = placements.back()
	
	# In cooperative mode, verify no piece has been placed on top of it (dependent move check)
	var top_z = int(last_placement.get("layer_plate", 0)) + 1
	for p in placements:
		if p == last_placement:
			continue
		if int(p.get("layer_plate", 0)) >= top_z:
			# Check if p depends on last_placement
			var sockets = rules.get_absolute_bottom_sockets(
				p.get("part_id", ""),
				p.get("grid_x", 0),
				p.get("grid_z", 0),
				p.get("layer_plate", 0),
				p.get("rotation_step", 0)
			)
			var last_studs = rules.get_absolute_top_studs(
				last_placement.get("part_id", ""),
				last_placement.get("grid_x", 0),
				last_placement.get("grid_z", 0),
				last_placement.get("layer_plate", 0),
				last_placement.get("rotation_step", 0)
			)
			for s in sockets:
				for ts in last_studs:
					if s.x == ts.x and s.z == ts.z and s.y == ts.y:
						return {
							"success": false,
							"reason": "Cannot undo: later placement depends on this piece",
							"code": "DEPENDENT_MOVE_EXISTS"
						}
						
	# Safe to undo
	placements.pop_back()
	redo_stack.append(last_placement)
	
	_record_event("PLACEMENT_UNDONE", {
		"placement_id": last_placement.get("placement_id", ""),
		"part_id": last_placement.get("part_id", ""),
		"sequence": last_placement.get("sequence", 0)
	})
	
	_clear_all_readiness()
	return {"success": true, "undone_placement": last_placement}

## Redo an undone placement
func redo_placement() -> Dictionary:
	if redo_stack.is_empty():
		return {"success": false, "reason": "No actions to redo", "code": "EMPTY"}
		
	var to_redo = redo_stack.pop_back()
	
	# Validate move against current board
	var val_res = rules.validate_placement(
		to_redo.get("part_id", ""),
		to_redo.get("grid_x", 0),
		to_redo.get("grid_z", 0),
		to_redo.get("layer_plate", 0),
		to_redo.get("rotation_step", 0),
		placements
	)
	
	if not val_res.get("valid", false):
		return {"success": false, "reason": "Cannot redo: position is now invalid", "code": "INVALID_STATE"}
		
	placements.append(to_redo)
	_record_event("PLACEMENT_REDONE", {
		"placement_id": to_redo.get("placement_id", ""),
		"part_id": to_redo.get("part_id", ""),
		"sequence": _next_event_seq
	})
	
	_clear_all_readiness()
	return {"success": true, "redone_placement": to_redo}

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
	var theme_parts = catalog.get_theme_parts(theme_id)
	if theme_parts.is_empty():
		theme_parts = catalog.get_theme_parts("core")
		
	# Pacing improvement (LB-012): Ensure hand always contains at least 2 basic structural bricks
	var structural_count: int = 0
	for idx in range(player_hand.size()):
		if idx == slot_idx:
			continue # Skip the slot being replaced
		var item = player_hand[idx]
		var p_id: String = item.get("part_id", "")
		var p_cat: String = catalog.get_part(p_id).get("category", "")
		if p_cat == "brick":
			structural_count += 1
			
	var candidate_parts: Array[Dictionary] = []
	if structural_count < 2:
		# Filter to structural bricks to guarantee unblocked hands
		for p in theme_parts:
			if p.get("category") == "brick":
				candidate_parts.append(p)
	if candidate_parts.is_empty():
		candidate_parts = theme_parts
		
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
	
	return {
		"instance_id": "item_%d_%d" % [Time.get_ticks_msec(), slot_idx],
		"part_id": chosen_part.get("id", "brick_2x4"),
		"name": chosen_part.get("name", "Brick"),
		"color": palette[_rng.randi() % palette.size()]
	}
