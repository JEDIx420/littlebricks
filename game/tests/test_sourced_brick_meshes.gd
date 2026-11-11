extends SceneTree

const PartMeshBuilder = preload("res://core/part_mesh_builder.gd")
const PartCatalog = preload("res://core/part_catalog.gd")

func _init() -> void:
	print("--- Testing Sourced 3D Brick Mesh Loading ---")
	var catalog = PartCatalog.new()
	assert(catalog.load_catalog(), "Failed to load catalog")
	
	var test_ids = ["brick_2x4", "plate_2x4", "slope_2x2", "steering_wheel_2x2", "slope_curved_1x4", "window_1x2x2"]
	for pid in test_ids:
		var pdef = catalog.get_part(pid)
		var node = PartMeshBuilder.build_part_node(pdef, Color.RED)
		assert(node != null, "Node must not be null for " + pid)
		assert(node.get_child_count() > 0, "Node must have children for " + pid)
		print("  ✓ Built part node for %s with %d child(ren)" % [pid, node.get_child_count()])
		node.queue_free()
		
	print("ALL SOURCED 3D BRICK MESH TESTS PASSED.")
	quit(0)
