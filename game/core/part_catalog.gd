extends RefCounted
class_name PartCatalog

## In-memory registry and query engine for versioned LittleBricks parts.
## Shared cleanly between client, server, and validation test suites.

const MANIFEST_PATH: String = "res://assets/catalog/parts_manifest.json"

var _parts_by_id: Dictionary = {}
var _themes_by_id: Dictionary = {}
var _catalog_metadata: Dictionary = {}
var _is_loaded: bool = false

func load_catalog(path: String = MANIFEST_PATH) -> bool:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("PartCatalog: Failed to open manifest at %s" % path)
		return false
	
	var json_text: String = file.get_as_text()
	file.close()
	
	var json: JSON = JSON.new()
	var err: Error = json.parse(json_text)
	if err != OK:
		push_error("PartCatalog: JSON parse error in %s: %s" % [path, json.get_error_message()])
		return false
	
	var data = json.data
	if not (data is Dictionary and data.has("parts")):
		push_error("PartCatalog: Invalid manifest structure (missing 'parts')")
		return false
		
	_catalog_metadata = {
		"catalog_version": data.get("catalog_version", "1.0.0"),
		"catalog_name": data.get("catalog_name", "Unknown"),
		"license_default": data.get("license_default", "CC0-1.0"),
		"stud_spacing": data.get("stud_spacing", 1.0),
		"plate_height": data.get("plate_height", 0.4),
		"brick_height": data.get("brick_height", 1.2)
	}
	
	_themes_by_id.clear()
	for theme in data.get("themes", []):
		if theme is Dictionary and theme.has("id"):
			_themes_by_id[theme["id"]] = theme

	_parts_by_id.clear()
	for p in data["parts"]:
		if p is Dictionary and p.has("id"):
			_parts_by_id[p["id"]] = p
			
	_is_loaded = true
	return true

func is_loaded() -> bool:
	return _is_loaded

func get_part(part_id: String) -> Dictionary:
	return _parts_by_id.get(part_id, {})

func get_all_part_ids() -> Array[String]:
	var ids: Array[String] = []
	for k in _parts_by_id.keys():
		ids.append(k)
	return ids

func get_parts_by_category(cat: String) -> Array[Dictionary]:
	var res: Array[Dictionary] = []
	for p in _parts_by_id.values():
		if p.get("category") == cat:
			res.append(p)
	return res

func get_theme(theme_id: String) -> Dictionary:
	return _themes_by_id.get(theme_id, {})

func get_theme_parts(theme_tag: String, include_shared: bool = true) -> Array[Dictionary]:
	var include_core: bool = include_shared and get_theme(theme_tag).get("include_core", false)
	var result: Array[Dictionary] = []
	for part in _parts_by_id.values():
		var tags: Array = part.get("theme_tags", [])
		var common_part: bool = include_core and "core" in tags and part.get("category", "") in ["brick", "plate", "tile"]
		if theme_tag in tags or common_part:
			result.append(part)
	return result

## Rotate a 2D local stud/socket coordinate (x, z) by quarter-turn (0, 1, 2, 3 -> 0, 90, 180, 270 deg)
static func rotate_coord(x: float, z: float, rot_step: int) -> Vector2:
	match rot_step % 4:
		0: return Vector2(x, z)
		1: return Vector2(-z, x)
		2: return Vector2(-x, -z)
		3: return Vector2(z, -x)
	return Vector2(x, z)

func get_version() -> String:
	return _catalog_metadata.get("catalog_version", "1.0.0")

## Returns the local, rotated (stud X, height in plates, stud Z) positions.
## Flat bricks omit the per-stud height and use the body height.
func get_top_stud_layers(part_id: String, rot_step: int) -> Array[Vector3]:
	var part := get_part(part_id)
	var default_height: int = int(part.get("dimensions_studs", [1, 3, 1])[1])
	var raw_studs: Array = part.get("connectors", {}).get("studs_top", [])
	var rotated: Array[Vector3] = []
	for stud in raw_studs:
		if stud is Array and stud.size() >= 2:
			var xz := rotate_coord(stud[0], stud[1], rot_step)
			rotated.append(Vector3(xz.x, float(stud[2]) if stud.size() > 2 else default_height, xz.y))
	return rotated

func get_top_studs(part_id: String, rot_step: int) -> Array[Vector2]:
	var xz: Array[Vector2] = []
	for stud in get_top_stud_layers(part_id, rot_step):
		xz.append(Vector2(stud.x, stud.z))
	return xz

## Return transformed bottom socket coordinates relative to brick center
func get_bottom_sockets(part_id: String, rot_step: int) -> Array[Vector2]:
	var p: Dictionary = get_part(part_id)
	var conns: Dictionary = p.get("connectors", {})
	var raw_sockets: Array = conns.get("sockets_bottom", [])
	var rotated: Array[Vector2] = []
	for s in raw_sockets:
		if s is Array and s.size() >= 2:
			rotated.append(rotate_coord(s[0], s[1], rot_step))
	return rotated

## Comprehensive catalog audit check for test runner
func audit_catalog() -> Dictionary:
	var issues: Array[String] = []
	var part_count: int = _parts_by_id.size()
	
	for id in _parts_by_id.keys():
		var p: Dictionary = _parts_by_id[id]
		if not p.has("category"):
			issues.append("Part %s missing category" % id)
		if not p.has("license"):
			issues.append("Part %s missing license notice" % id)
		if not p.has("dimensions_studs"):
			issues.append("Part %s missing dimensions_studs" % id)
		if p.get("category") != "character":
			if not p.has("connectors"):
				issues.append("Part %s missing connectors" % id)
			if not p.has("collision_boxes"):
				issues.append("Part %s missing collision_boxes" % id)
	
	return {
		"valid": issues.is_empty(),
		"part_count": part_count,
		"issues": issues
	}
