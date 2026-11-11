extends SceneTree

## Automated test suite for LB-061: Tactile Building & Catalogue UI.
## Verifies HUD declutter (hidden coords, friendly family messages),
## visual brick hand styling with selection states, and catalogue modal responsive filtering.

const MainScene = preload("res://client/scenes/main.tscn")
const SessionManager = preload("res://core/session_manager.gd")
const PartCatalog = preload("res://core/part_catalog.gd")
const PlacementRules = preload("res://core/placement_rules.gd")

func _init() -> void:
	print("--- Running Test: LB-061 Tactile Building & Catalogue UI ---")
	
	test_hud_declutter_and_friendly_messages()
	test_visual_inventory_tray()
	test_catalog_modal_filtering()
	
	print("--- All LB-061 Tactile Building & Catalogue UI tests passed! ---")
	quit(0)

func test_hud_declutter_and_friendly_messages() -> void:
	print("Testing HUD Declutter & Friendly Messages...")
	var main = MainScene.instantiate()
	root.add_child(main)
	if not main.is_node_ready():
		main._ready()
		
	var label_coords = main.find_child("LabelCoords", true, false) as Label
	assert(label_coords != null, "LabelCoords exists")
	assert(not label_coords.visible, "LabelCoords is hidden by default for clean family HUD")
	
	# Test friendly message mapping
	var valid_msg = main._format_friendly_validation_message(true, "OK", "OK")
	assert(valid_msg == "Ready to place on table" or valid_msg == "Ready to place", "Friendly valid msg: %s" % valid_msg)
	
	var col_msg = main._format_friendly_validation_message(false, "COLLISION", "Overlaps brick")
	assert(col_msg == "Space is already occupied", "Friendly collision msg: %s" % col_msg)
	
	var float_msg = main._format_friendly_validation_message(false, "FLOATING", "No support")
	assert(float_msg == "Needs support underneath", "Friendly floating msg: %s" % float_msg)
	
	var oob_msg = main._format_friendly_validation_message(false, "OUT_OF_BOUNDS", "Outside")
	assert(oob_msg == "Must stay on the table" or oob_msg == "Must stay on the baseplate", "Friendly bounds msg: %s" % oob_msg)
	
	main.queue_free()
	print("  ✓ HUD declutter & friendly messages verified")

func test_visual_inventory_tray() -> void:
	print("Testing Visual Inventory Tray...")
	var main = MainScene.instantiate()
	root.add_child(main)
	if not main.is_node_ready():
		main._ready()
		
	var tray = main.find_child("TrayContainer", true, false) as HBoxContainer
	assert(tray != null, "TrayContainer exists")
	
	main._setup_inventory_tray()
	assert(tray.get_child_count() == 6, "Tray has 6 hand slots")
	
	var first_btn = tray.get_child(0) as Button
	assert(first_btn != null, "First slot button exists")
	assert(first_btn.custom_minimum_size.y >= 48, "Slot button touch height >= 48px")
	assert(not first_btn.text.is_empty(), "Slot button has part name text")
	
	# Verify selection changes active slot
	var second_btn = tray.get_child(1) as Button
	second_btn.pressed.emit()
	assert(main.selected_hand_slot == 1, "Slot 1 selected after clicking second button")
	
	main.queue_free()
	print("  ✓ Visual inventory tray verified")

func test_catalog_modal_filtering() -> void:
	print("Testing Catalogue Modal Filtering...")
	var main = MainScene.instantiate()
	root.add_child(main)
	if not main.is_node_ready():
		main._ready()
		
	var modal = main.find_child("CatalogModal", true, false) as Control
	var grid = main.find_child("CatalogGrid", true, false) as GridContainer
	var search = main.find_child("LineCatalogSearch", true, false) as LineEdit
	
	assert(modal != null and grid != null and search != null, "Catalog controls exist")
	
	# Open catalog
	main._toggle_catalog_modal()
	assert(modal.visible, "Catalog modal opened")
	assert(grid.get_child_count() > 0, "Catalog populated with parts")
	
	# Test search filter
	search.text = "brick_2x4"
	main._populate_catalog_grid()
	assert(grid.get_child_count() >= 1, "Search for brick_2x4 found at least 1 match")
	
	# Test empty search filter
	search.text = "nonexistent_part_xyz"
	main._populate_catalog_grid()
	var empty_child = grid.get_child(0) as Label
	assert(empty_child != null, "Empty search shows label")
	assert("No parts match" in empty_child.text, "Empty label explains no match")
	
	main.queue_free()
	print("  ✓ Catalogue modal filtering verified")
