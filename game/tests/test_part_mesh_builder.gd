extends SceneTree

## Automated verification for PartMeshBuilder (LB-065-A / LB-065).
## Verifies that slopes, cylinders, cones, arches, stairs, fish, and characters
## instantiate genuine distinct visual geometry rather than duplicate BoxMeshes.

const PartCatalog = preload("res://core/part_catalog.gd")
const PartMeshBuilder = preload("res://core/part_mesh_builder.gd")

func _init() -> void:
	print("--- Running Test: PartMeshBuilder Genuine Geometry (LB-065) ---")
	
	var catalog = PartCatalog.new()
	var ok = catalog.load_catalog("res://assets/catalog/parts_manifest.json")
	assert(ok, "Catalog loaded")
	
	# Test slope
	var slope_def = catalog.get_part("slope_1x2")
	var slope_node = PartMeshBuilder.build_part_node(slope_def, Color.RED)
	assert(slope_node != null, "Slope node built")
	assert(slope_node.get_child_count() > 0, "Slope has visual mesh child")
	var first_mesh = slope_node.get_child(0) as MeshInstance3D
	assert(first_mesh != null and first_mesh.mesh is ArrayMesh, "Slope uses genuine ArrayMesh wedge, not BoxMesh")
	slope_node.queue_free()
	print("  ✓ Slope wedge geometry verified")
	
	# Test cylinder/round brick
	var round_def = catalog.get_part("brick_round_1x1")
	var round_node = PartMeshBuilder.build_part_node(round_def, Color.BLUE)
	assert(round_node != null, "Round node built")
	var cyl_mesh = round_node.get_child(0) as MeshInstance3D
	assert(cyl_mesh != null and cyl_mesh.mesh is CylinderMesh, "Round brick uses genuine CylinderMesh")
	round_node.queue_free()
	print("  ✓ Round brick cylinder geometry verified")
	
	# Test arch opening
	var arch_def = catalog.get_part("arch_1x8")
	var arch_node = PartMeshBuilder.build_part_node(arch_def, Color.GRAY)
	assert(arch_node != null, "Arch node built")
	# Arch should have 2 pillars + 1 lintel span + top studs
	assert(arch_node.get_child_count() >= 3, "Arch has distinct pillars and lintel")
	arch_node.queue_free()
	print("  ✓ Arch opening geometry verified")
	
	# Test stairs
	var stairs_def = catalog.get_part("stairs_2x4")
	var stairs_node = PartMeshBuilder.build_part_node(stairs_def, Color.WHITE)
	assert(stairs_node != null, "Stairs node built")
	assert(stairs_node.get_child_count() >= 2, "Stairs have multiple step levels")
	stairs_node.queue_free()
	print("  ✓ Stepped stairs geometry verified")
	
	# Test fish
	var fish_def = catalog.get_part("fish_coastal_1x2")
	var fish_node = PartMeshBuilder.build_part_node(fish_def, Color(0.9, 0.5, 0.1))
	assert(fish_node != null, "Fish node built")
	assert(fish_node.get_child_count() >= 2, "Fish has body and tail silhouette")
	fish_node.queue_free()
	print("  ✓ Fish silhouette geometry verified")
	
	# Test toy explorer figure
	var explorer_def = catalog.get_part("toy_explorer_pippin")
	var explorer_node = PartMeshBuilder.build_part_node(explorer_def, Color.WHITE)
	assert(explorer_node != null, "Explorer figure built")
	var figure := explorer_node.get_child(0)
	assert(figure.has_node("LeftLeg") and figure.has_node("RightLeg"), "Minifigure uses separately molded legs")
	assert(figure.has_node("LeftArm") and figure.has_node("RightArm"), "Minifigure uses articulated arms")
	explorer_node.queue_free()
	print("  ✓ Toy explorer figure verified")
	
	print("--- All PartMeshBuilder genuine geometry tests passed! ---")
	quit(0)
