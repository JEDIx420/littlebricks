extends RefCounted
class_name ExplorationWorld

## Generates smooth static collision and validates character spawn/clearance for frozen builds (LB-013).
## Studs are smoothed over to prevent character jitter while openings and walkaways are preserved.

const PartCatalog = preload("res://core/part_catalog.gd")
const TableView = preload("res://client/scripts/table_view.gd")
const PlacementRules = preload("res://core/placement_rules.gd")

const EXPLORER_CAPSULE_RADIUS: float = 0.65
const EXPLORER_CAPSULE_HEIGHT: float = 4.0
const REQUIRED_HEAD_CLEARANCE: float = 4.5 # units
const EPSILON: float = 0.05
const PERIMETER_LAYER: int = 1 << 2
const BASEPLATE_HALF_SPAN: float = PlacementRules.GRID_SIZE * PlacementRules.STUD_SPACING * 0.5
const PERIMETER_CLEARANCE: float = 0.20
const PERIMETER_THICKNESS: float = 0.5

var catalog: PartCatalog
var _rules: PlacementRules

func _init(p_catalog: PartCatalog = null) -> void:
	if p_catalog:
		catalog = p_catalog
	else:
		catalog = PartCatalog.new()
		catalog.load_catalog("res://assets/catalog/parts_manifest.json")
	_rules = PlacementRules.new(catalog)

## Construct static collision bodies for the entire frozen build
func generate_world_colliders(placements: Array) -> StaticBody3D:
	var world_body: StaticBody3D = StaticBody3D.new()
	world_body.name = "ExplorationStaticWorld"
	
	# 1. Baseplate ground collider
	var ground_col: CollisionShape3D = CollisionShape3D.new()
	var ground_box: BoxShape3D = BoxShape3D.new()
	# Support the narrow margin up to the barrier so there is no gap.
	var floor_span := (BASEPLATE_HALF_SPAN + PERIMETER_CLEARANCE) * 2.0
	ground_box.size = Vector3(floor_span, 0.4, floor_span)
	ground_col.shape = ground_box
	ground_col.position = Vector3(0.0, -0.1, 0.0) # Baseplate surface is at Y = 0.1
	world_body.add_child(ground_col)
	
	# Smoothed collision boxes are shared with spawn clearance.
	for box in _placed_boxes(placements):
		_add_box(world_body, box.get_center(), box.size)

	world_body.add_child(_generate_perimeter())
	return world_body

func _generate_perimeter() -> StaticBody3D:
	var barrier := StaticBody3D.new()
	barrier.name = "ExplorerPerimeter"
	# The character collides with these walls. The third-person spring arm
	# stays on the normal world mask so it can frame the plate from outside.
	barrier.collision_layer = PERIMETER_LAYER
	barrier.collision_mask = 0
	var inside_edge := BASEPLATE_HALF_SPAN + PERIMETER_CLEARANCE
	var span := (inside_edge + PERIMETER_THICKNESS) * 2.0
	var offset := inside_edge + PERIMETER_THICKNESS * 0.5
	var height := PlacementRules.MAX_LAYER_PLATES * PlacementRules.PLATE_HEIGHT + EXPLORER_CAPSULE_HEIGHT + 1.0
	var midpoint_y := height * 0.5 - 0.4
	for sign_value in [-1.0, 1.0]:
		_add_box(barrier, Vector3(sign_value * offset, midpoint_y, 0.0), Vector3(PERIMETER_THICKNESS, height, span))
		_add_box(barrier, Vector3(0.0, midpoint_y, sign_value * offset), Vector3(span, height, PERIMETER_THICKNESS))
	return barrier

func _add_box(body: StaticBody3D, center: Vector3, dimensions: Vector3) -> void:
	var collider := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = dimensions
	collider.shape = box
	collider.position = center
	body.add_child(collider)

func _placed_boxes(placements: Array) -> Array[AABB]:
	var result: Array[AABB] = []
	var grid_origin := TableView.grid_to_world(0, 0, 0)
	for piece in placements:
		for box in _rules.get_part_aabbs(
			piece.get("part_id", ""), piece.get("grid_x", 0), piece.get("grid_z", 0),
			piece.get("layer_plate", 0), piece.get("rotation_step", 0)
		):
			result.append(AABB(grid_origin + box.min_pos, box.max_pos - box.min_pos))
	return result

func _has_spawn_clearance(feet: Vector3, boxes: Array[AABB]) -> bool:
	var radius := EXPLORER_CAPSULE_RADIUS - EPSILON
	var lower := feet + Vector3(-radius, EPSILON, -radius)
	var clearance := AABB(lower, Vector3(2.0 * radius, EXPLORER_CAPSULE_HEIGHT - 2.0 * EPSILON, 2.0 * radius))
	for box in boxes:
		if clearance.intersects(box):
			return false
	return true

## Validate the capsule's clearance at a given stud and layer.
func validate_spawn(gx: int, gz: int, z_plate: int, placements: Array) -> Dictionary:
	if gx < 1 or gx >= PlacementRules.GRID_SIZE - 1 or gz < 1 or gz >= PlacementRules.GRID_SIZE - 1:
		return {"valid": false, "reason": "Spawn point outside safe baseplate bounds"}
	var feet := TableView.grid_to_world(gx, gz, z_plate)
	if not _has_spawn_clearance(feet, _placed_boxes(placements)):
		return {"valid": false, "reason": "Spawn location intersects a placed piece"}
	return {"valid": true, "reason": "Clearance valid", "world_position": feet}

## Prefer corners and edges, then look for any clear spot on the board.
func find_default_spawn(placements: Array) -> Vector3:
	var boxes := _placed_boxes(placements)
	var candidates := [
		Vector2i(4, 4), Vector2i(4, 28), Vector2i(28, 4), Vector2i(28, 28),
		Vector2i(16, 4), Vector2i(16, 28), Vector2i(4, 16), Vector2i(28, 16),
	]
	for candidate: Vector2i in candidates:
		var feet := TableView.grid_to_world(candidate.x, candidate.y, 0)
		if _has_spawn_clearance(feet, boxes):
			return feet
	for z in range(1, PlacementRules.GRID_SIZE - 1):
		for x in range(1, PlacementRules.GRID_SIZE - 1):
			var feet := TableView.grid_to_world(x, z, 0)
			if _has_spawn_clearance(feet, boxes):
				return feet

	# A fully covered baseplate still has a safe surface above the solid build.
	# Pick the highest available collider so the capsule cannot start inside it.
	var highest := TableView.grid_to_world(PlacementRules.GRID_SIZE / 2, PlacementRules.GRID_SIZE / 2, 0)
	var limit := BASEPLATE_HALF_SPAN - EXPLORER_CAPSULE_RADIUS
	for box in boxes:
		if box.end.y <= highest.y:
			continue
		var center := box.get_center()
		highest = Vector3(clampf(center.x, -limit, limit), box.end.y, clampf(center.z, -limit, limit))
	return highest + Vector3.UP * EPSILON
