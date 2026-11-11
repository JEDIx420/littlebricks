extends RefCounted
class_name PlacementRules

## Deterministic brick placement and connection validity engine for LittleBricks.
## Pure GDScript module shared across client preview, local game, and authoritative server.

const GRID_SIZE: int = 32
const MAX_LAYER_PLATES: int = 120 # 40 bricks tall
const PLATE_HEIGHT: float = 0.4
const STUD_SPACING: float = 1.0
const EPSILON: float = 0.01

const PartCatalog = preload("res://core/part_catalog.gd")

var catalog: PartCatalog

func _init(p_catalog: PartCatalog = null) -> void:
	if p_catalog:
		catalog = p_catalog
	else:
		catalog = PartCatalog.new()
		catalog.load_catalog("res://assets/catalog/parts_manifest.json")

## AABB in continuous grid coordinates [x_min, x_max, y_min, y_max, z_min, z_max]
class GridAABB:
	var min_pos: Vector3
	var max_pos: Vector3
	
	func _init(c: Vector3, s: Vector3) -> void:
		min_pos = c - (s * 0.5)
		max_pos = c + (s * 0.5)
		
	func intersects(other: GridAABB) -> bool:
		if max_pos.x <= other.min_pos.x + EPSILON or min_pos.x >= other.max_pos.x - EPSILON:
			return false
		if max_pos.y <= other.min_pos.y + EPSILON or min_pos.y >= other.max_pos.y - EPSILON:
			return false
		if max_pos.z <= other.min_pos.z + EPSILON or min_pos.z >= other.max_pos.z - EPSILON:
			return false
		return true

## Transform all collision boxes of a part into world-grid space
func get_part_aabbs(part_id: String, gx: int, gz: int, z_plate: int, rot_step: int) -> Array[GridAABB]:
	var p: Dictionary = catalog.get_part(part_id)
	var boxes: Array = p.get("collision_boxes", [])
	var res: Array[GridAABB] = []
	
	var base_y: float = float(z_plate) * PLATE_HEIGHT
	
	for b in boxes:
		var raw_c: Array = b.get("center", [0.0, 0.6, 0.0])
		var raw_s: Array = b.get("size", [1.0, 1.2, 1.0])
		
		# Rotate center around Y axis
		var rot_c2d: Vector2 = PartCatalog.rotate_coord(raw_c[0], raw_c[2], rot_step)
		var center_world: Vector3 = Vector3(float(gx) + rot_c2d.x, base_y + float(raw_c[1]), float(gz) + rot_c2d.y)
		
		# Size swaps width and depth if rotated 90 or 270 deg
		var size_world: Vector3
		if (rot_step % 2) == 1:
			size_world = Vector3(float(raw_s[2]), float(raw_s[1]), float(raw_s[0]))
		else:
			size_world = Vector3(float(raw_s[0]), float(raw_s[1]), float(raw_s[2]))
			
		res.append(GridAABB.new(center_world, size_world))
		
	return res

## Calculate all absolute stud positions occupied by bottom sockets of a piece
func get_absolute_bottom_sockets(part_id: String, gx: int, gz: int, z_plate: int, rot_step: int) -> Array[Vector3i]:
	var local_sockets: Array[Vector2] = catalog.get_bottom_sockets(part_id, rot_step)
	var res: Array[Vector3i] = []
	for s in local_sockets:
		var sx: int = int(round(float(gx) + s.x))
		var sz: int = int(round(float(gz) + s.y))
		res.append(Vector3i(sx, z_plate, sz))
	return res

## Calculate all absolute stud positions occupied by top studs of a piece
func get_absolute_top_studs(part_id: String, gx: int, gz: int, z_plate: int, rot_step: int) -> Array[Vector3i]:
	var p: Dictionary = catalog.get_part(part_id)
	var dims: Array = p.get("dimensions_studs", [1, 3, 1])
	var top_z_plate: int = z_plate + int(dims[1])
	
	var local_studs: Array[Vector2] = catalog.get_top_studs(part_id, rot_step)
	var res: Array[Vector3i] = []
	for s in local_studs:
		var sx: int = int(round(float(gx) + s.x))
		var sz: int = int(round(float(gz) + s.y))
		res.append(Vector3i(sx, top_z_plate, sz))
	return res

## Validate placement against all game rules
func validate_placement(part_id: String, gx: int, gz: int, z_plate: int, rot_step: int, board_placements: Array) -> Dictionary:
	var p: Dictionary = catalog.get_part(part_id)
	if p.is_empty():
		return {"valid": false, "code": "UNKNOWN_PART", "reason": "Part ID not found in catalog"}
		
	# 1. Allowed rotation
	var allowed_rot: Array = p.get("allowed_rotations", [0, 1, 2, 3])
	var is_rot_allowed: bool = false
	for r in allowed_rot:
		if int(r) == rot_step:
			is_rot_allowed = true
			break
	if not is_rot_allowed:
		return {"valid": false, "code": "INVALID_ROTATION", "reason": "Rotation orientation not allowed"}
		
	# 2. Board and height bounds
	var dims: Array = p.get("dimensions_studs", [1, 3, 1])
	var height_plates: int = int(dims[1])
	if z_plate < 0:
		return {"valid": false, "code": "OUT_OF_BOUNDS", "reason": "Placement height cannot be negative"}
	if (z_plate + height_plates) > MAX_LAYER_PLATES:
		return {"valid": false, "code": "OUT_OF_BOUNDS", "reason": "Placement exceeds maximum height limit"}
		
	# Check all socket and body bounds
	var sockets: Array[Vector3i] = get_absolute_bottom_sockets(part_id, gx, gz, z_plate, rot_step)
	for s in sockets:
		if s.x < 0 or s.x >= GRID_SIZE or s.z < 0 or s.z >= GRID_SIZE:
			return {"valid": false, "code": "OUT_OF_BOUNDS", "reason": "Piece footprint extends outside 32x32 baseplate"}
			
	# 3. Collision / Body Overlap
	var new_aabbs: Array[GridAABB] = get_part_aabbs(part_id, gx, gz, z_plate, rot_step)
	for placed in board_placements:
		var placed_id: String = placed.get("part_id", "")
		var pgx: int = placed.get("grid_x", 0)
		var pgz: int = placed.get("grid_z", 0)
		var pz: int = placed.get("layer_plate", 0)
		var prot: int = placed.get("rotation_step", 0)
		
		var placed_aabbs: Array[GridAABB] = get_part_aabbs(placed_id, pgx, pgz, pz, prot)
		for na in new_aabbs:
			for pa in placed_aabbs:
				if na.intersects(pa):
					return {
						"valid": false,
						"code": "COLLISION",
						"reason": "Collides with existing piece (%s at %d, %d)" % [placed_id, pgx, pgz]
					}
					
	# 4. Connector Compatibility & Anchor check
	# If z_plate == 0, baseplate is ground anchor
	if z_plate == 0:
		return {
			"valid": true,
			"code": "OK",
			"reason": "Placed on baseplate anchor",
			"connected_studs": sockets.size(),
			"anchored": true
		}
		
	# For z_plate > 0, piece must connect to underlying top studs
	var connected_count: int = 0
	for placed in board_placements:
		var placed_id: String = placed.get("part_id", "")
		var pgx: int = placed.get("grid_x", 0)
		var pgz: int = placed.get("grid_z", 0)
		var pz: int = placed.get("layer_plate", 0)
		var prot: int = placed.get("rotation_step", 0)
		
		var top_studs: Array[Vector3i] = get_absolute_top_studs(placed_id, pgx, pgz, pz, prot)
		for s in sockets:
			for ts in top_studs:
				# Must match exact grid position and vertical layer
				if s.x == ts.x and s.z == ts.z and s.y == ts.y:
					connected_count += 1
					
	if connected_count == 0:
		return {
			"valid": false,
			"code": "FLOATING",
			"reason": "Piece is floating in air or stacking on a smooth tile without studs"
		}
		
	return {
		"valid": true,
		"code": "OK",
		"reason": "Connected to underlying structure",
		"connected_studs": connected_count,
		"anchored": true
	}
