extends RefCounted
class_name SaveManager

## Atomic, versioned persistence manager for LittleBricks creations and event journals.
## Safely writes temporary files, handles schema migrations, and protects against corruption.

const CURRENT_SCHEMA_VERSION: String = "1.0.0"
const DEFAULT_SAVE_DIR: String = "user://saves"

const PlacementRules = preload("res://core/placement_rules.gd")
const SessionManager = preload("res://core/session_manager.gd")

signal save_completed(filepath: String)
signal save_failed(reason: String)
signal load_completed(session_data: Dictionary)
signal load_failed(reason: String, code: String)

## Serialize session snapshot and event journal to a dictionary
static func serialize_session(session: SessionManager) -> Dictionary:
	var placements_serializable: Array = []
	for placement in session.placements:
		placements_serializable.append(_encode_placement(placement))

	var players_serializable: Array = []
	for pl in session.players:
		var hand_serializable: Array = []
		for h in pl.get("hand", []):
			hand_serializable.append({
				"instance_id": h.get("instance_id", ""),
				"part_id": h.get("part_id", ""),
				"name": h.get("name", ""),
				"color_hex": (h.get("color", Color.WHITE) as Color).to_html()
			})
		players_serializable.append({
			"id": pl.get("id", ""),
			"name": pl.get("name", ""),
			"color_hex": (pl.get("color", Color.WHITE) as Color).to_html(),
			"hand": hand_serializable,
			"is_ready_to_explore": pl.get("is_ready_to_explore", false)
		})
		
	var snapshot := {
		"schema_version": CURRENT_SCHEMA_VERSION,
		"rules_version": PlacementRules.VERSION,
		"catalog_version": session.catalog.get_version(),
		"timestamp": Time.get_unix_time_from_system(),
		"mode": int(session.mode),
		"phase": int(session.phase),
		"theme_id": session.theme_id,
		"build_revision": session.build_revision,
		"current_player_idx": session.current_player_idx,
		"timer_enabled": session.timer_enabled,
		"timer_duration_sec": session.timer_duration_sec,
		"time_remaining_sec": session.time_remaining_sec,
		"placements": placements_serializable,
		"event_journal": session.event_journal,
		"players": players_serializable
	}
	if session.mode != SessionManager.GameMode.ONLINE_ROOM:
		snapshot["edit_history"] = _serialize_edit_history(session.get_edit_history())
	return snapshot

static func _encode_placement(placement: Dictionary) -> Dictionary:
	var record := placement.duplicate()
	record["color_hex"] = (record.get("color", Color.WHITE) as Color).to_html()
	record.erase("color")
	return record

static func _decode_placement(record: Dictionary) -> Dictionary:
	return {
		"placement_id": str(record.get("placement_id", "")),
		"sequence": int(record.get("sequence", 0)),
		"player_id": str(record.get("player_id", "")),
		"part_id": str(record.get("part_id", "")),
		"grid_x": int(record.get("grid_x", 0)),
		"grid_z": int(record.get("grid_z", 0)),
		"layer_plate": int(record.get("layer_plate", 0)),
		"rotation_step": int(record.get("rotation_step", 0)),
		"color": Color.from_string(record.get("color_hex", "#ffffff"), Color.WHITE),
	}

static func _serialize_edit_history(history: Dictionary) -> Dictionary:
	for stack in history.values():
		for action in stack:
			action["placement"] = _encode_placement(action["placement"])
	return history

static func _restore_edit_stack(raw: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if raw is Array:
		for action in raw:
			if action is Dictionary and action.get("kind", "") in ["place", "erase"] and action.get("placement") is Dictionary:
				var record := _decode_placement(action["placement"])
				if not record["placement_id"].is_empty():
					result.append({"kind": action["kind"], "index": int(action.get("index", 0)), "placement": record})
	return result

## Atomically save session data to disk using temporary write & swap
static func save_to_file(session_dict: Dictionary, filepath: String) -> bool:
	var dir_path: String = filepath.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)
		
	var tmp_path: String = filepath + ".tmp"
	var bak_path: String = filepath + ".bak"
	
	var json_str: String = JSON.stringify(session_dict, "  ")
	
	# 1. Write to temporary file
	var file = FileAccess.open(tmp_path, FileAccess.WRITE)
	if not file:
		push_error("SaveManager: Cannot open tmp file %s" % tmp_path)
		return false
	file.store_string(json_str)
	file.flush()
	file.close()
	
	# 2. Backup existing save if present
	if FileAccess.file_exists(filepath):
		if FileAccess.file_exists(bak_path):
			DirAccess.remove_absolute(bak_path)
		DirAccess.copy_absolute(filepath, bak_path)
		
	# 3. Rename tmp to target
	if FileAccess.file_exists(filepath):
		DirAccess.remove_absolute(filepath)
		
	var err = DirAccess.rename_absolute(tmp_path, filepath)
	return err == OK

## Load, validate schema, and deserialize session dictionary
static func load_from_file(filepath: String) -> Dictionary:
	if not FileAccess.file_exists(filepath):
		return {"success": false, "code": "FILE_NOT_FOUND", "error": "Save file does not exist"}
		
	var file = FileAccess.open(filepath, FileAccess.READ)
	if not file:
		return {"success": false, "code": "CANNOT_OPEN", "error": "Cannot open save file"}
		
	var content: String = file.get_as_text()
	file.close()
	
	var json: JSON = JSON.new()
	var err = json.parse(content)
	if err != OK:
		# File corrupt, attempt recovery from .bak if present
		var bak_path: String = filepath + ".bak"
		if FileAccess.file_exists(bak_path):
			var bak_file = FileAccess.open(bak_path, FileAccess.READ)
			if bak_file:
				var bak_content = bak_file.get_as_text()
				bak_file.close()
				if json.parse(bak_content) == OK and json.data is Dictionary:
					var recovered = json.data
					recovered["_recovered_from_backup"] = true
					return {"success": true, "data": recovered}
		return {"success": false, "code": "CORRUPT_JSON", "error": "JSON parse error: %s" % json.get_error_message()}
		
	var data = json.data
	if not (data is Dictionary):
		return {"success": false, "code": "INVALID_FORMAT", "error": "Save root is not a dictionary"}
		
	# Check schema version
	var ver: String = str(data.get("schema_version", ""))
	if ver != CURRENT_SCHEMA_VERSION and ver != "1":
		return {
			"success": false,
			"code": "UNSUPPORTED_VERSION",
			"error": "Unsupported schema version: '%s' (current is %s)" % [ver, CURRENT_SCHEMA_VERSION]
		}
		
	return {"success": true, "data": data}

## Apply restored session dictionary into SessionManager
static func restore_into_session(session: SessionManager, data: Dictionary) -> bool:
	session.mode = data.get("mode", SessionManager.GameMode.SOLO_CREATIVE)
	session.phase = data.get("phase", SessionManager.SessionPhase.BUILDING)
	session.theme_id = data.get("theme_id", "harbour")
	session.build_revision = data.get("build_revision", 1)
	session.current_player_idx = data.get("current_player_idx", 0)
	session.timer_enabled = bool(data.get("timer_enabled", session.timer_enabled))
	session.timer_duration_sec = maxf(1.0, float(data.get("timer_duration_sec", session.timer_duration_sec)))
	session.time_remaining_sec = clampf(float(data.get("time_remaining_sec", session.timer_duration_sec)), 0.0, session.timer_duration_sec)
	session.event_journal.clear()
	var last_sequence: int = 0
	for ev in data.get("event_journal", []):
		if ev is Dictionary:
			session.event_journal.append(ev)
			last_sequence = maxi(last_sequence, int(ev.get("seq", 0)))
	
	# Keep legacy IDs when they are unique. Older handmade saves may omit IDs,
	# or have duplicates from the previous count-based allocator.
	var id_counts: Dictionary = {}
	session.placements.clear()
	for record in data.get("placements", []):
		if record is Dictionary:
			var placement := _decode_placement(record)
			session.placements.append(placement)
			last_sequence = maxi(last_sequence, placement["sequence"])
			var id: String = placement["placement_id"]
			if id.begins_with("pl_") and id.substr(3).is_valid_int():
				last_sequence = maxi(last_sequence, int(id.substr(3)))
			id_counts[id] = int(id_counts.get(id, 0)) + 1
	var migrated_ids := false
	for placement in session.placements:
		var id: String = placement["placement_id"]
		if id.is_empty() or int(id_counts[id]) > 1:
			last_sequence += 1
			placement["placement_id"] = "pl_%d" % last_sequence
			migrated_ids = true

	var history = data.get("edit_history")
	if history is Dictionary and not migrated_ids and history.get("undo") is Array and history.get("redo") is Array:
		var undo := _restore_edit_stack(history["undo"])
		var redo := _restore_edit_stack(history["redo"])
		for stack in [undo, redo]:
			for action in stack:
				last_sequence = maxi(last_sequence, action["placement"]["sequence"])
		session.restore_edit_history(undo, redo)
	elif session.mode != SessionManager.GameMode.ONLINE_ROOM:
		session.seed_placement_history()

	# Restore players
	session.players.clear()
	for pl in data.get("players", []):
		var p_col: Color = Color.from_string(pl.get("color_hex", "#ff0000"), Color.RED)
		var hand: Array = []
		for h in pl.get("hand", []):
			hand.append({
				"instance_id": h.get("instance_id", ""),
				"part_id": h.get("part_id", ""),
				"name": h.get("name", ""),
				"color": Color.from_string(h.get("color_hex", "#ffffff"), Color.WHITE)
			})
		session.players.append({
			"id": pl.get("id", ""),
			"name": pl.get("name", ""),
			"color": p_col,
			"hand": hand,
			"is_ready_to_explore": pl.get("is_ready_to_explore", false)
		})
		
	session.current_player_idx = clampi(session.current_player_idx, 0, maxi(0, session.players.size() - 1))
	session._next_event_seq = last_sequence + 1
	return true
