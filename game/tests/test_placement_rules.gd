extends SceneTree

## Comprehensive test suite for PlacementRules (LB-005).

const PlacementRules = preload("res://core/placement_rules.gd")
const PartCatalog = preload("res://core/part_catalog.gd")

func _init() -> void:
	print("--- Running LittleBricks PlacementRules Test Suite ---")
	var catalog: PartCatalog = PartCatalog.new()
	catalog.load_catalog("res://assets/catalog/parts_manifest.json")
	var rules: PlacementRules = PlacementRules.new(catalog)
	
	var board: Array = []
	
	# Test 1: Legal placement on baseplate (z=0)
	var r1 = rules.validate_placement("brick_2x4", 10, 10, 0, 0, board)
	if not r1.get("valid", false):
		print("FAILED Test 1: Legal placement on baseplate rejected: %s" % str(r1))
		quit(1)
		return
	print("PASS Test 1: Legal placement on baseplate accepted.")
	
	# Add brick to board
	board.append({"part_id": "brick_2x4", "grid_x": 10, "grid_z": 10, "layer_plate": 0, "rotation_step": 0})
	
	# Test 2: Out of bounds (negative coordinate)
	var r2 = rules.validate_placement("brick_2x4", 0, 0, 0, 0, board)
	# 2x4 centered at (0, 0) has sockets at -1.5, -0.5, etc -> extends to -1 which is < 0!
	if r2.get("valid", false):
		print("FAILED Test 2: Out of bounds placement was accepted!")
		quit(1)
		return
	print("PASS Test 2: Out of bounds placement correctly rejected (Code: %s)." % r2.get("code"))
	
	# Test 3: Collision with existing brick
	var r3 = rules.validate_placement("brick_2x2", 10, 10, 0, 0, board)
	if r3.get("valid", false) or r3.get("code") != "COLLISION":
		print("FAILED Test 3: Direct body collision was not rejected: %s" % str(r3))
		quit(1)
		return
	print("PASS Test 3: Collision with existing brick correctly rejected.")
	
	# Test 4: Floating piece rejected
	var r4 = rules.validate_placement("brick_2x2", 20, 20, 3, 0, board)
	if r4.get("valid", false) or r4.get("code") != "FLOATING":
		print("FAILED Test 4: Floating brick was not rejected: %s" % str(r4))
		quit(1)
		return
	print("PASS Test 4: Floating piece correctly rejected.")
	
	# Test 5: Legal stacking at z=3 (brick is 3 plates tall)
	var r5 = rules.validate_placement("brick_2x2", 10, 10, 3, 0, board)
	if not r5.get("valid", false):
		print("FAILED Test 5: Legal stacking on brick at z=3 was rejected: %s" % str(r5))
		quit(1)
		return
	print("PASS Test 5: Legal stacking at z=3 accepted.")
	
	# Test 6: Supported overhang (cross-bonding bricks)
	var r6 = rules.validate_placement("brick_2x4", 10, 11, 3, 1, board) # 90 deg rotated across
	if not r6.get("valid", false):
		print("FAILED Test 6: Supported overhang / rotated stack was rejected: %s" % str(r6))
		quit(1)
		return
	print("PASS Test 6: Supported overhang accepted.")
	
	# Test 7: Stacking on smooth tile rejected (tiles have no top studs)
	var tile_board: Array = [
		{"part_id": "tile_2x2", "grid_x": 15, "grid_z": 15, "layer_plate": 0, "rotation_step": 0}
	]
	var r7 = rules.validate_placement("brick_2x2", 15, 15, 1, 0, tile_board)
	if r7.get("valid", false) or r7.get("code") != "FLOATING":
		print("FAILED Test 7: Stacking on smooth tile was not rejected as floating: %s" % str(r7))
		quit(1)
		return
	print("PASS Test 7: Stacking on smooth tile rejected (tile has no studs).")
	
	# Test 8: Arch opening preservation (1x4 arch has open clearance underneath)
	var arch_board: Array = [
		{"part_id": "arch_1x4", "grid_x": 20, "grid_z": 20, "layer_plate": 0, "rotation_step": 0}
	]
	# Arch center is open up to height 0.8; placing a 1x1 plate (height 0.4) in the center (grid 20, 20) at z=0 should NOT collide!
	var r8 = rules.validate_placement("plate_1x2", 20, 20, 0, 0, arch_board)
	if not r8.get("valid", false):
		print("FAILED Test 8: Arch opening was blocked by false collision: %s" % str(r8))
		quit(1)
		return
	print("PASS Test 8: Arch opening preserved (piece fits inside arch portal without collision).")
	
	print("\nALL LB-005 PLACEMENT RULE TESTS PASSED.")
	quit(0)
