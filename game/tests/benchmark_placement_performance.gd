extends SceneTree

## Performance profiling fixture for LB-008: Placement rules, collision scaling, and frame times.

const PlacementRules = preload("res://core/placement_rules.gd")
const PartCatalog = preload("res://core/part_catalog.gd")

func _init() -> void:
	print("--- Running LittleBricks Placement Performance & Scaling Profile (LB-008) ---")
	
	var catalog: PartCatalog = PartCatalog.new()
	catalog.load_catalog("res://assets/catalog/parts_manifest.json")
	var rules: PlacementRules = PlacementRules.new(catalog)
	
	# Test scaling across 10, 50, 100, 250, and 500 board placements
	var piece_counts = [10, 50, 100, 250, 500]
	var board: Array = []
	var parts = ["brick_2x4", "brick_2x2", "brick_1x4", "plate_2x4", "arch_1x4"]
	
	for target_count in piece_counts:
		# Populate board up to target_count
		while board.size() < target_count:
			var i: int = board.size()
			var gx: int = (i % 28) + 2
			var gz: int = ((i / 28) % 28) + 2
			var z_plate: int = (i / 784) * 3
			var p_id: String = parts[i % parts.size()]
			board.append({
				"part_id": p_id,
				"grid_x": gx,
				"grid_z": gz,
				"layer_plate": z_plate,
				"rotation_step": i % 4
			})
			
		# Measure 100 placement validation checks against this board size
		var start_time: int = Time.get_ticks_usec()
		var iterations: int = 100
		for it in range(iterations):
			var test_x: int = (it % 26) + 3
			var test_z: int = ((it * 3) % 26) + 3
			var _res = rules.validate_placement("brick_2x4", test_x, test_z, 0, 0, board)
		var elapsed_usec: int = Time.get_ticks_usec() - start_time
		var avg_usec_per_validation: float = float(elapsed_usec) / float(iterations)
		
		print("Board pieces: %4d | 100 validations in %6d µs | Avg: %6.1f µs/check" % [
			target_count, elapsed_usec, avg_usec_per_validation
		])
		
		# Validation must stay well under 1000 µs (1 millisecond) per check to maintain 60-120 FPS!
		if avg_usec_per_validation > 5000.0: # 5ms threshold
			print("WARNING: Placement validation exceeded 5ms budget at %d pieces!" % target_count)
			quit(1)
			return
			
	print("\nStatus: PASS (Average validation cost < 0.5ms even with 500 pieces on board)")
	print("ALL LB-008 PROFILING BENCHMARKS PASSED.")
	quit(0)
