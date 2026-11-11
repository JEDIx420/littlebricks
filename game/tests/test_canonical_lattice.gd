extends SceneTree

## Dedicated regression suite for Canonical Stud Lattice & Pivot Contract (LB-054, PC-04, PC-05, PC-06).

const PlacementRules = preload("res://core/placement_rules.gd")
const PartCatalog = preload("res://core/part_catalog.gd")
const TableView = preload("res://client/scripts/table_view.gd")

func _init() -> void:
	print("--- Running LittleBricks Canonical Stud Lattice Suite (LB-054) ---")
	var catalog: PartCatalog = PartCatalog.new()
	var loaded = catalog.load_catalog("res://assets/catalog/parts_manifest.json")
	if not loaded:
		print("FAILED: Could not load parts manifest.")
		quit(1)
		return
		
	var rules: PlacementRules = PlacementRules.new(catalog)
	
	# =========================================================================
	# Test Group 1: PC-04 Golden Fixture (1x4 on 2x4 at all 4 rotations)
	# =========================================================================
	print("\n[Group 1: PC-04 Golden Fixture 1x4 on 2x4]")
	
	# Base 2x4 at (8, 8, z=0, rot=0)
	var board_rot0: Array = [
		{"part_id": "brick_2x4", "grid_x": 8, "grid_z": 8, "layer_plate": 0, "rotation_step": 0}
	]
	
	# Verify base 2x4 studs in canonical grid coordinates
	var top_studs_2x4: Array[Vector3i] = rules.get_absolute_top_studs("brick_2x4", 8, 8, 0, 0)
	assert_eq(top_studs_2x4.size(), 8, "2x4 must have exactly 8 top studs")
	for s in top_studs_2x4:
		if s.x < 8 or s.x > 9 or s.z < 8 or s.z > 11 or s.y != 3:
			print("FAILED: 2x4 stud out of expected footprint [8..9, 8..11, y=3]: %s" % str(s))
			quit(1)
			return
	print("PASS: 2x4 top studs exactly cover x={8, 9}, z={8..11} at plate 3.")
	
	# 1x4 at rot=0 on Row 0 (gx=8) -> must have 4 matching studs
	var r_row0 = rules.validate_placement("brick_1x4", 8, 8, 3, 0, board_rot0)
	assert_true(r_row0.get("valid", false), "1x4 on Row 0 (gx=8, rot=0) must be VALID")
	assert_eq(r_row0.get("connected_studs", 0), 4, "1x4 on Row 0 must have 4 connected studs")
	print("PASS: 1x4 cleanly aligns with Row 0 (x=8) at rot=0.")
	
	# 1x4 at rot=0 on Row 1 (gx=9) -> must have 4 matching studs
	var r_row1 = rules.validate_placement("brick_1x4", 9, 8, 3, 0, board_rot0)
	assert_true(r_row1.get("valid", false), "1x4 on Row 1 (gx=9, rot=0) must be VALID")
	assert_eq(r_row1.get("connected_studs", 0), 4, "1x4 on Row 1 must have 4 connected studs")
	print("PASS: 1x4 cleanly aligns with Row 1 (x=9) at rot=0.")
	
	# 1x4 off the piece (gx=10) -> must be FLOATING
	var r_off = rules.validate_placement("brick_1x4", 10, 8, 3, 0, board_rot0)
	assert_false(r_off.get("valid", false), "1x4 at gx=10 must be FLOATING")
	assert_eq(r_off.get("code", ""), "FLOATING", "Code must be FLOATING")
	print("PASS: 1x4 at gx=10 correctly rejected as FLOATING.")
	
	# 1x4 at rot=2 (180 deg) on Row 0 and Row 1
	var r_rot2_row0 = rules.validate_placement("brick_1x4", 8, 8, 3, 2, board_rot0)
	assert_true(r_rot2_row0.get("valid", false), "1x4 at rot=2 on Row 0 must be VALID")
	assert_eq(r_rot2_row0.get("connected_studs", 0), 4, "1x4 at rot=2 must connect 4 studs")
	var r_rot2_row1 = rules.validate_placement("brick_1x4", 9, 8, 3, 2, board_rot0)
	assert_true(r_rot2_row1.get("valid", false), "1x4 at rot=2 on Row 1 must be VALID")
	assert_eq(r_rot2_row1.get("connected_studs", 0), 4, "1x4 at rot=2 must connect 4 studs")
	print("PASS: 1x4 at rot=2 (180°) cleanly aligns with Row 0 and Row 1.")
	
	# Now test 2x4 at rot=1 (90 deg): footprint is (4, 2), studs at x={8..11}, z={8, 9}
	var board_rot1: Array = [
		{"part_id": "brick_2x4", "grid_x": 8, "grid_z": 8, "layer_plate": 0, "rotation_step": 1}
	]
	var r_rot1_row0 = rules.validate_placement("brick_1x4", 8, 8, 3, 1, board_rot1)
	assert_true(r_rot1_row0.get("valid", false), "1x4 at rot=1 on Row 0 (gz=8) must be VALID")
	assert_eq(r_rot1_row0.get("connected_studs", 0), 4, "1x4 at rot=1 on Row 0 must have 4 connected studs")
	var r_rot1_row1 = rules.validate_placement("brick_1x4", 8, 9, 3, 1, board_rot1)
	assert_true(r_rot1_row1.get("valid", false), "1x4 at rot=1 on Row 1 (gz=9) must be VALID")
	assert_eq(r_rot1_row1.get("connected_studs", 0), 4, "1x4 at rot=1 on Row 1 must have 4 connected studs")
	var r_rot1_off = rules.validate_placement("brick_1x4", 8, 10, 3, 1, board_rot1)
	assert_false(r_rot1_off.get("valid", false), "1x4 at gz=10 must be FLOATING")
	print("PASS: 1x4 at rot=1 (90°) cleanly aligns with Row 0 (z=8) and Row 1 (z=9).")
	
	# Test 2x4 at rot=3 (270 deg)
	var board_rot3: Array = [
		{"part_id": "brick_2x4", "grid_x": 8, "grid_z": 8, "layer_plate": 0, "rotation_step": 3}
	]
	var r_rot3_row0 = rules.validate_placement("brick_1x4", 8, 8, 3, 3, board_rot3)
	assert_true(r_rot3_row0.get("valid", false), "1x4 at rot=3 on Row 0 must be VALID")
	var r_rot3_row1 = rules.validate_placement("brick_1x4", 8, 9, 3, 3, board_rot3)
	assert_true(r_rot3_row1.get("valid", false), "1x4 at rot=3 on Row 1 must be VALID")
	print("PASS: 1x4 at rot=3 (270°) cleanly aligns with Row 0 and Row 1.")
	
	# Cross-stacking: 1x4 at rot=1 placed across 2x4 at rot=0
	var r_cross = rules.validate_placement("brick_1x4", 7, 9, 3, 1, board_rot0)
	assert_true(r_cross.get("valid", false), "1x4 cross-stacking across 2x4 must be VALID")
	assert_eq(r_cross.get("connected_studs", 0), 2, "Cross-stacking 1x4 across 2x4 connects exactly 2 studs")
	print("PASS: Cross-stacking 1x4 across 2x4 connects exactly 2 studs.")
	
	# =========================================================================
	# Test Group 2: PC-05 Odd and Even Parity Check
	# =========================================================================
	print("\n[Group 2: PC-05 Odd & Even Parity Check]")
	var test_parts: Array[String] = [
		"brick_1x1", "brick_1x2", "brick_1x3", "brick_1x4",
		"brick_2x2", "brick_2x3", "brick_2x4",
		"plate_1x2", "plate_2x2", "tile_1x4", "tile_2x2"
	]
	for pid in test_parts:
		var pdef = catalog.get_part(pid)
		var dims = pdef.get("dimensions_studs", [1, 3, 1])
		for rot in range(4):
			var sockets = rules.get_absolute_bottom_sockets(pid, 10, 10, 0, rot)
			for s in sockets:
				# Must be exact integer coordinates
				assert_eq(s.y, 0, "%s socket y must match z_plate" % pid)
			var studs = rules.get_absolute_top_studs(pid, 10, 10, 0, rot)
			for s in studs:
				assert_eq(s.y, int(dims[1]), "%s stud y must be z_plate + height" % pid)
				
			# Check round-trip world_to_grid and grid_to_world
			var wpos = PlacementRules.grid_to_world(10, 10, 0, dims, rot)
			var recovered_grid = PlacementRules.world_to_grid(wpos, dims, rot)
			assert_eq(recovered_grid, Vector2i(10, 10), "%s round-trip grid_to_world -> world_to_grid failed" % pid)
			
	print("PASS: All 11 odd/even parts preserve integer stud addresses and round-trip world coordinates.")
	
	# Smooth tiles must reject stacking
	var tile_board: Array = [
		{"part_id": "tile_1x4", "grid_x": 12, "grid_z": 12, "layer_plate": 0, "rotation_step": 0}
	]
	var r_tile_stack = rules.validate_placement("brick_1x1", 12, 12, 1, 0, tile_board)
	assert_false(r_tile_stack.get("valid", false), "Stacking on smooth tile must be rejected")
	assert_eq(r_tile_stack.get("code", ""), "FLOATING", "Stacking on tile must report FLOATING")
	print("PASS: Smooth tile_1x4 top surface correctly rejects stacking as FLOATING.")
	
	# =========================================================================
	# Test Group 3: PC-06 Baseplate Boundaries and Corners
	# =========================================================================
	print("\n[Group 3: PC-06 Baseplate Boundaries & Corners]")
	var empty_board: Array = []
	
	# Corners: (0, 0), (30, 0), (0, 28), (30, 28) for 2x4
	assert_true(rules.validate_placement("brick_2x4", 0, 0, 0, 0, empty_board).get("valid", false), "Corner (0, 0) must be VALID")
	assert_true(rules.validate_placement("brick_2x4", 30, 0, 0, 0, empty_board).get("valid", false), "Corner (30, 0) must be VALID")
	assert_true(rules.validate_placement("brick_2x4", 0, 28, 0, 0, empty_board).get("valid", false), "Corner (0, 28) must be VALID")
	assert_true(rules.validate_placement("brick_2x4", 30, 28, 0, 0, empty_board).get("valid", false), "Corner (30, 28) must be VALID")
	print("PASS: All 4 baseplate corners accept 2x4 placement.")
	
	# Out of bounds
	assert_false(rules.validate_placement("brick_2x4", -1, 0, 0, 0, empty_board).get("valid", false), "Negative X must be OUT_OF_BOUNDS")
	assert_false(rules.validate_placement("brick_2x4", 0, -1, 0, 0, empty_board).get("valid", false), "Negative Z must be OUT_OF_BOUNDS")
	assert_false(rules.validate_placement("brick_2x4", 31, 0, 0, 0, empty_board).get("valid", false), "X=31 for 2x4 must be OUT_OF_BOUNDS")
	assert_false(rules.validate_placement("brick_2x4", 0, 29, 0, 0, empty_board).get("valid", false), "Z=29 for 2x4 must be OUT_OF_BOUNDS")
	assert_false(rules.validate_placement("brick_2x4", 0, 0, -1, 0, empty_board).get("valid", false), "Negative layer must be OUT_OF_BOUNDS")
	assert_false(rules.validate_placement("brick_2x4", 0, 0, 120, 0, empty_board).get("valid", false), "Exceeding max height must be OUT_OF_BOUNDS")
	print("PASS: Negative coords, board overflow, and height limits strictly rejected as OUT_OF_BOUNDS.")
	
	# =========================================================================
	# Test Group 4: Rotation Degrees Parity with PartCatalog.rotate_coord
	# =========================================================================
	print("\n[Group 4: 3D Rotation Contract Parity]")
	for rot in range(4):
		var rot_deg = PlacementRules.get_rotation_degrees(rot)
		assert_eq(rot_deg.x, 0.0, "Rotation X must be 0")
		assert_eq(rot_deg.z, 0.0, "Rotation Z must be 0")
		assert_eq(rot_deg.y, -float(rot) * 90.0, "Rotation Y must match -rot * 90 deg")
	print("PASS: PlacementRules.get_rotation_degrees matches clockwise Y rotation.")
	
	print("\nALL LB-054 CANONICAL STUD LATTICE REGRESSION CHECKS PASSED.")
	quit(0)

func assert_true(val: bool, msg: String) -> void:
	if not val:
		print("ASSERTION FAILED (expected true): %s" % msg)
		quit(1)

func assert_false(val: bool, msg: String) -> void:
	if val:
		print("ASSERTION FAILED (expected false): %s" % msg)
		quit(1)

func assert_eq(a, b, msg: String) -> void:
	if a != b:
		print("ASSERTION FAILED (%s != %s): %s" % [str(a), str(b), msg])
		quit(1)
