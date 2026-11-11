extends RefCounted

const Rules = preload("res://core/placement_rules.gd")
const BOARD_PLANE: float = 0.1
const HALF_BOARD: float = Rules.GRID_SIZE * Rules.STUD_SPACING * 0.5
const BOARD_ORIGIN := Vector3(-HALF_BOARD + 0.5, BOARD_PLANE, -HALF_BOARD + 0.5)
const SNAP_HYSTERESIS: float = 0.10
const EDGE_SNAP_RADIUS: float = 0.80

## Target a solid piece's surface or the exposed baseplate. The returned layer
## is its connector plane; visual stud caps are never included in brick height.
static func resolve(
		from: Vector3, direction: Vector3, rules: Rules, board: Array,
		part_id: String, rotation_step: int, manual_layer: int = -1,
		previous_anchor: Vector2i = Vector2i(-1, -1), previous_layer: int = -1
	) -> Dictionary:
	if direction.y >= -0.0001:
		return {"valid": false}

	var dims: Array = rules.catalog.get_part(part_id).get("dimensions_studs", [1, 3, 1])
	var layer: int = maxi(0, manual_layer)
	var plane_y: float = BOARD_PLANE + layer * Rules.PLATE_HEIGHT
	var distance: float = (plane_y - from.y) / direction.y
	var point: Vector3 = from + direction * distance
	var hit_board: bool = distance > 0.0 and absf(point.x) <= HALF_BOARD and absf(point.z) <= HALF_BOARD
	var nearest: float = distance if hit_board else INF

	if manual_layer < 0:
		for brick in board:
			var brick_id: String = brick.get("part_id", "")
			var brick_layer: int = brick.get("layer_plate", 0)
			var boxes = rules.get_part_aabbs(brick_id, brick.get("grid_x", 0), brick.get("grid_z", 0), brick_layer, brick.get("rotation_step", 0))
			for box in boxes:
				var world_box := AABB(box.min_pos + BOARD_ORIGIN, box.max_pos - box.min_pos)
				var hit = world_box.intersects_ray(from, direction)
				if hit == null:
					continue
				var hit_distance: float = (hit - from).dot(direction) / direction.length_squared()
				if hit_distance <= 0.0 or hit_distance >= nearest:
					continue
				nearest = hit_distance
				layer = roundi(box.max_pos.y / Rules.PLATE_HEIGHT)
				point = Vector3(hit.x, BOARD_PLANE + layer * Rules.PLATE_HEIGHT, hit.z)

	if not is_finite(nearest):
		return {"valid": false}

	var anchor := Rules.world_to_grid(point, dims, rotation_step)
	if manual_layer < 0:
		anchor = _stabilize_snap(point, anchor, layer, part_id, dims, rotation_step, rules, board, previous_anchor, previous_layer)
	return {"valid": true, "grid_pos": anchor, "layer_plate": layer, "hit_pos": point}

static func _stabilize_snap(
		point: Vector3, anchor: Vector2i, layer: int, part_id: String, dims: Array,
		rotation_step: int, rules: Rules, board: Array,
		previous_anchor: Vector2i, previous_layer: int
	) -> Vector2i:
	var center: Vector3 = Rules.grid_to_world(anchor.x, anchor.y, layer, dims, rotation_step)
	var center_distance: float = point.distance_to(center)
	var can_keep_previous: bool = previous_layer == layer and previous_anchor != anchor and previous_anchor.distance_squared_to(anchor) <= 2
	if layer == 0 and not can_keep_previous:
		return anchor
	var exact: Dictionary = rules.validate_placement(part_id, anchor.x, anchor.y, layer, rotation_step, board)
	if exact.get("valid", false):
		if can_keep_previous:
			var previous_center: Vector3 = Rules.grid_to_world(previous_anchor.x, previous_anchor.y, layer, dims, rotation_step)
			if point.distance_to(previous_center) <= center_distance + SNAP_HYSTERESIS:
				if rules.validate_placement(part_id, previous_anchor.x, previous_anchor.y, layer, rotation_step, board).get("valid", false):
					return previous_anchor
		return anchor

	# A close socket may miss a stud when the pointer sits right on an edge.
	# Keep deliberate collision/board errors visible, and never jump floors.
	if layer == 0 or exact.get("code", "") != "FLOATING":
		return anchor
	var best := anchor
	var best_distance: float = center_distance + EDGE_SNAP_RADIUS
	for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var nearby: Vector2i = anchor + offset
		var nearby_center: Vector3 = Rules.grid_to_world(nearby.x, nearby.y, layer, dims, rotation_step)
		var candidate_distance: float = point.distance_to(nearby_center)
		if candidate_distance >= best_distance:
			continue
		if rules.validate_placement(part_id, nearby.x, nearby.y, layer, rotation_step, board).get("valid", false):
			best = nearby
			best_distance = candidate_distance
	return best
