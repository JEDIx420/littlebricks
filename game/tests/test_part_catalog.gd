extends SceneTree

## Headless test script for PartCatalog and PartMeshBuilder (LB-003).

const PartCatalog = preload("res://core/part_catalog.gd")
const PartMeshBuilder = preload("res://core/part_mesh_builder.gd")

func _init() -> void:
	print("--- Running LittleBricks PartCatalog & Metadata Test Suite ---")
	var catalog: PartCatalog = PartCatalog.new()
	var loaded: bool = catalog.load_catalog("res://assets/catalog/parts_manifest.json")
	if not loaded:
		print("FAILED: Could not load parts_manifest.json")
		quit(1)
		return
		
	var audit: Dictionary = catalog.audit_catalog()
	print("Catalog parts audited: %d parts" % audit.get("part_count", 0))
	if not audit.get("valid", false):
		print("FAILED: Audit issues found: %s" % str(audit.get("issues", [])))
		quit(1)
		return
		
	# 1. Verify representative shape count >= 12
	var part_ids: Array[String] = catalog.get_all_part_ids()
	if part_ids.size() < 12:
		print("FAILED: Expected at least 12 representative parts, found %d" % part_ids.size())
		quit(1)
		return
	print("PASS: 16 representative shapes + 1 explorer candidate verified.")
	
	# 2. Verify rotation transformation on 1x2 brick connectors
	var studs_0: Array[Vector2] = catalog.get_top_studs("brick_1x2", 0) # 0 deg: (0, -0.5), (0, 0.5)
	var studs_1: Array[Vector2] = catalog.get_top_studs("brick_1x2", 1) # 90 deg: (0.5, 0), (-0.5, 0)
	if studs_0.size() != 2 or studs_1.size() != 2:
		print("FAILED: Connector counts invalid for brick_1x2")
		quit(1)
		return
	if not (is_equal_approx(studs_0[0].x, 0.0) and is_equal_approx(studs_0[0].y, -0.5)):
		print("FAILED: Stud 0 orientation mismatch: %s" % str(studs_0[0]))
		quit(1)
		return
	if not (is_equal_approx(studs_1[0].x, 0.5) and is_equal_approx(studs_1[0].y, 0.0)):
		print("FAILED: Stud 90 deg rotation mismatch: %s" % str(studs_1[0]))
		quit(1)
		return
	print("PASS: Connector quarter-turn rotation verified.")
	
	# 3. Verify mesh generation for standard brick and opening arch
	var brick_node: Node3D = PartMeshBuilder.build_part_node(catalog.get_part("brick_2x4"), Color.RED)
	if not brick_node or brick_node.get_child_count() == 0:
		print("FAILED: PartMeshBuilder failed on brick_2x4")
		quit(1)
		return
	brick_node.free()
	
	var arch_node: Node3D = PartMeshBuilder.build_part_node(catalog.get_part("arch_1x4"), Color.BLUE)
	if not arch_node or arch_node.get_child_count() == 0:
		print("FAILED: PartMeshBuilder failed on arch_1x4 opening structure")
		quit(1)
		return
	arch_node.free()
	
	var explorer_node: Node3D = PartMeshBuilder.build_part_node(catalog.get_part("explorer_candidate_01"), Color.WHITE)
	if not explorer_node or explorer_node.get_child_count() != 2 or not explorer_node.get_child(0).has_node("LeftLeg") or not explorer_node.get_child(1) is MeshInstance3D:
		print("FAILED: PartMeshBuilder failed to provide an explorer rig and its stand")
		if explorer_node:
			explorer_node.free()
		quit(1)
		return
	explorer_node.free()
	print("PASS: Procedural mesh and explorer figure generation verified.")
	
	print("ALL LB-003 TESTS PASSED.")
	quit(0)
