extends RefCounted
class_name SaveManager

## Atomic, versioned persistence manager for LittleBricks creations and event journals.
## Safely writes temporary files, handles schema migrations, and protects against corruption.

const CURRENT_SCHEMA_VERSION: String = "1.0.0"
const DEFAULT_SAVE_DIR: String = "user://saves"

const SessionManager = preload("res://core/session_manager.gd")

signal save_completed(filepath: String)
signal save_failed(reason: String)
signal load_completed(session_data: Dictionary)
signal load_failed(reason: String, code: String)

## Serialize session snapshot and event journal to a dictionary
static func serialize_session(session: SessionManager) -> Dictionary:
	var placements_serializable: Array = []
	for p in session.placements:
		placements_serializable.append({
			"placement_id": p.get("placement_id", ""),
			"sequence": p.get("sequence", 0),
			"player_id": p.get("player_id", ""),
			"part_id": p.get("part_id", ""),
			"grid_x": p.get("grid_x", 0),
			"grid_z": p.get("grid_z", 0),
			"layer_plate": p.get("layer_plate", 0),
			"rotation_step": p.get("rotation_step", 0),
			"color_hex": (p.get("color", Color.WHITE) as Color).to_html()
		})
		
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
		
	return {
		"schema_version": CURRENT_SCHEMA_VERSION,
		"rules_version": "1.0.0",
		"catalog_version": "1.0.0",
		"timestamp": Time.get_unix_time_from_system(),
		"mode": int(session.mode),
		"phase": int(session.phase),
		"theme_id": session.theme_id,
		"build_revision": session.build_revision,
		"current_player_idx": session.current_player_idx,
		"placements": placements_serializable,
		"event_journal": session.event_journal,
		"players": players_serializable
	}

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
	var ver: String = data.get("schema_version", "")
	if ver != CURRENT_SCHEMA_VERSION:
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
	session.event_journal.clear()
	for ev in data.get("event_journal", []):
		if ev is Dictionary:
			session.event_journal.append(ev)
	
	# Restore placements
	session.placements.clear()
	for p in data.get("placements", []):
		var col: Color = Color.from_string(p.get("color_hex", "#ffffff"), Color.WHITE)
		session.placements.append({
			"placement_id": p.get("placement_id", ""),
			"sequence": p.get("sequence", 0),
			"player_id": p.get("player_id", ""),
			"part_id": p.get("part_id", ""),
			"grid_x": p.get("grid_x", 0),
			"grid_z": p.get("grid_z", 0),
			"layer_plate": p.get("layer_plate", 0),
			"rotation_step": p.get("rotation_step", 0),
			"color": col
		})
		
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
		
	return true
