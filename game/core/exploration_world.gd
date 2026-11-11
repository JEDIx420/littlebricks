extends RefCounted
class_name ExplorationWorld

## Generates smooth static collision and validates character spawn/clearance for frozen builds (LB-013).
## Studs are smoothed over to prevent character jitter while openings and walkaways are preserved.

const PartCatalog = preload("res://core/part_catalog.gd")
const TableView = preload("res://client/scripts/table_view.gd")

const EXPLORER_CAPSULE_RADIUS: float = 0.65
const EXPLORER_CAPSULE_HEIGHT: float = 4.0
const REQUIRED_HEAD_CLEARANCE: float = 4.5 # units
const EPSILON: float = 0.05

var catalog: PartCatalog

func _init(p_catalog: PartCatalog = null) -> void:
	if p_catalog:
		catalog = p_catalog
	else:
		catalog = PartCatalog.new()
		catalog.load_catalog("res://assets/catalog/parts_manifest.json")

## Construct static collision bodies for the entire frozen build
func generate_world_colliders(placements: Array) -> StaticBody3D:
	var world_body: StaticBody3D = StaticBody3D.new()
	world_body.name = "ExplorationStaticWorld"
	
	# 1. Baseplate ground collider
	var ground_col: CollisionShape3D = CollisionShape3D.new()
	var ground_box: BoxShape3D = BoxShape3D.new()
	ground_box.size = Vector3(32.0, 0.4, 32.0)
	ground_col.shape = ground_box
	ground_col.position = Vector3(0.0, -0.1, 0.0) # Baseplate surface is at Y = 0.1
	world_body.add_child(ground_col)
	
	# 2. Colliders for each placed piece (smoothing over top studs)
	for p in placements:
		var part_id: String = p.get("part_id", "")
		var gx: int = p.get("grid_x", 0)
		var gz: int = p.get("grid_z", 0)
		var z_plate: int = p.get("layer_plate", 0)
		var rot_step: int = p.get("rotation_step", 0)
		
		var p_def: Dictionary = catalog.get_part(part_id)
		if p_def.is_empty():
			continue
			
		var col_boxes: Array = p_def.get("collision_boxes", [])
		var base_world: Vector3 = TableView.grid_to_world(gx, gz, z_plate)
		
		for b in col_boxes:
			var c_raw: Array = b.get("center", [0.0, 0.6, 0.0])
			var s_raw: Array = b.get("size", [1.0, 1.2, 1.0])
			
			var rot_c2d: Vector2 = PartCatalog.rotate_coord(c_raw[0], c_raw[2], rot_step)
			var box_center: Vector3 = base_world + Vector3(rot_c2d.x, float(c_raw[1]), rot_c2d.y)
			
			var box_size: Vector3
			if (rot_step % 2) == 1:
				box_size = Vector3(float(s_raw[2]), float(s_raw[1]), float(s_raw[0]))
			else:
				box_size = Vector3(float(s_raw[0]), float(s_raw[1]), float(s_raw[2]))
				
			var cshape: CollisionShape3D = CollisionShape3D.new()
			var bshape: BoxShape3D = BoxShape3D.new()
			bshape.size = box_size
			cshape.shape = bshape
			cshape.position = box_center
			world_body.add_child(cshape)
			
	return world_body

## Validate whether an explorer can spawn at given grid coordinate and plate height
func validate_spawn(gx: int, gz: int, z_plate: int, placements: Array) -> Dictionary:
	# 1. Bounds check
	if gx < 1 or gx > 30 or gz < 1 or gz > 30:
		return {"valid": false, "reason": "Spawn point outside safe baseplate bounds"}
		
	var spawn_world_y: float = 0.1 + (float(z_plate) * TableView.PLATE_HEIGHT)
	var spawn_center_y: float = spawn_world_y + (EXPLORER_CAPSULE_HEIGHT * 0.5)
	var spawn_center: Vector3 = TableView.grid_to_world(gx, gz, z_plate)
	spawn_center.y = spawn_center_y
	
	# 2. Check collision with any existing piece's collision boxes
	for p in placements:
		var part_id: String = p.get("part_id", "")
		var pgx: int = p.get("grid_x", 0)
		var pgz: int = p.get("grid_z", 0)
		var pz: int = p.get("layer_plate", 0)
		var prot: int = p.get("rotation_step", 0)
		
		var p_def: Dictionary = catalog.get_part(part_id)
		var col_boxes: Array = p_def.get("collision_boxes", [])
		var base_w: Vector3 = TableView.grid_to_world(pgx, pgz, pz)
		
		for b in col_boxes:
			var c_raw: Array = b.get("center", [0.0, 0.6, 0.0])
			var s_raw: Array = b.get("size", [1.0, 1.2, 1.0])
			var rot_c2d: Vector2 = PartCatalog.rotate_coord(c_raw[0], c_raw[2], prot)
			var bc: Vector3 = base_w + Vector3(rot_c2d.x, float(c_raw[1]), rot_c2d.y)
			
			var bs: Vector3
			if (prot % 2) == 1:
				bs = Vector3(float(s_raw[2]), float(s_raw[1]), float(s_raw[0]))
			else:
				bs = Vector3(float(s_raw[0]), float(s_raw[1]), float(s_raw[2]))
				
			# Check overlap between explorer capsule proxy box and brick box
			var x_overlap: bool = abs(spawn_center.x - bc.x) < ((EXPLORER_CAPSULE_RADIUS * 2.0 + bs.x) * 0.5 - EPSILON)
			var y_overlap: bool = abs(spawn_center.y - bc.y) < ((EXPLORER_CAPSULE_HEIGHT + bs.y) * 0.5 - EPSILON)
			var z_overlap: bool = abs(spawn_center.z - bc.z) < ((EXPLORER_CAPSULE_RADIUS * 2.0 + bs.z) * 0.5 - EPSILON)
			
			if x_overlap and y_overlap and z_overlap:
				return {
					"valid": false,
					"reason": "Spawn location intersects with solid piece (%s at %d, %d)" % [part_id, pgx, pgz]
				}
				
	return {
		"valid": true,
		"reason": "Clearance valid",
		"world_position": Vector3(spawn_center.x, spawn_world_y, spawn_center.z)
	}

## Find the nearest valid spawn location on the baseplate
func find_default_spawn(placements: Array) -> Vector3:
	# Try candidates near corners/edges of baseplate (gx=4, gz=4)
	var candidates = [
		Vector2i(4, 4), Vector2i(4, 28), Vector2i(28, 4), Vector2i(28, 28),
		Vector2i(16, 4), Vector2i(16, 28), Vector2i(4, 16), Vector2i(28, 16)
	]
	
	for c in candidates:
		var res = validate_spawn(c.x, c.y, 0, placements)
		if res.get("valid", false):
			return res["world_position"]
			
	# Fallback to (2, 2)
	return TableView.grid_to_world(2, 2, 0)
