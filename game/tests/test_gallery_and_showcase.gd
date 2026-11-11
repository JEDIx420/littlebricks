extends SceneTree

## Automated test suite for LB-063 (Showcase & Replay) and LB-064 (My Builds Gallery).
## Verifies creation showcase overlay, replay timeline signaling, video export trigger,
## and gallery creation cards with open/delete and corrupt-save handling.

const MyBuildsGalleryScene = preload("res://client/scenes/my_builds_gallery.tscn")
const ShowcaseOverlayScene = preload("res://client/scenes/showcase_overlay.tscn")
const SaveManager = preload("res://core/save_manager.gd")
const SessionManager = preload("res://core/session_manager.gd")

func _init() -> void:
	print("--- Running Test: LB-063 & LB-064 Showcase & Gallery Suite ---")
	
	test_showcase_overlay()
	test_my_builds_gallery()
	
	print("--- All LB-063 & LB-064 tests passed successfully! ---")
	quit(0)

func test_showcase_overlay() -> void:
	print("Testing Showcase Overlay...")
	var showcase = ShowcaseOverlayScene.instantiate()
	root.add_child(showcase)
	if not showcase.is_node_ready():
		showcase._ready()
		
	showcase.configure_showcase("Coastal Lighthouse", 14)
	
	var title = showcase.find_child("Title", true, false) as Label
	var subtitle = showcase.find_child("Subtitle", true, false) as Label
	var btn_explore = showcase.find_child("BtnExplore", true, false) as Button
	var btn_watch = showcase.find_child("BtnWatchBuild", true, false) as Button
	var btn_keep = showcase.find_child("BtnKeepBuilding", true, false) as Button
	
	assert(title != null and title.text == "Creation Complete!", "Showcase has celebratory title")
	assert(subtitle != null and "Coastal Lighthouse" in subtitle.text and "14 bricks" in subtitle.text, "Showcase subtitle has creation name & count")
	assert(btn_explore != null and btn_explore.custom_minimum_size.y >= 48, "BtnExplore touch height >= 48px")
	assert(btn_watch != null and btn_watch.custom_minimum_size.y >= 44, "BtnWatchBuild touch height >= 44px")
	assert(btn_keep != null and btn_keep.custom_minimum_size.y >= 44, "BtnKeepBuilding touch height >= 44px")
	
	# Signal tests
	var explore_signaled = []
	showcase.explore_requested.connect(func(): explore_signaled.append(true))
	btn_explore.pressed.emit()
	assert(explore_signaled.size() == 1, "Explore signal emitted")
	
	var watch_signaled = []
	showcase.watch_build_requested.connect(func(): watch_signaled.append(true))
	btn_watch.pressed.emit()
	assert(watch_signaled.size() == 1, "Watch build signal emitted")
	
	# Verify replay box is now visible
	var replay_box = showcase.find_child("ReplayBox", true, false) as Control
	assert(replay_box != null and replay_box.visible, "Replay sub-panel visible after clicking Watch Build")
	
	showcase.update_replay_progress(5, 14)
	var pbar = showcase.find_child("ProgressBar", true, false) as ProgressBar
	assert(pbar.value == 5.0 and pbar.max_value == 14.0, "Progress bar updated to step 5/14")
	
	var export_signaled = []
	showcase.video_export_requested.connect(func(): export_signaled.append(true))
	var btn_export = showcase.find_child("BtnExportVideo", true, false) as Button
	btn_export.pressed.emit()
	assert(export_signaled.size() == 1, "Video export signal emitted")
	
	var keep_signaled = []
	showcase.keep_building_requested.connect(func(): keep_signaled.append(true))
	btn_keep.pressed.emit()
	assert(keep_signaled.size() == 1, "Keep building signal emitted")
	
	showcase.queue_free()
	print("  ✓ Showcase Overlay verified")

func test_my_builds_gallery() -> void:
	print("Testing My Builds Gallery...")
	# Stage sample test save and a corrupt save
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("saves"):
		dir.make_dir("saves")
		
	var valid_save_path = "user://saves/Test_Castle.json"
	var test_data = {
		"schema_version": "1.0.0",
		"creation_name": "Test Castle",
		"theme_id": "harbour",
		"mode": 0,
		"players": [{"id": "p0", "name": "Builder"}],
		"placements": [
			{"part_id": "brick_2x4", "color_hex": "dd2222", "grid_x": 16, "grid_z": 16, "layer_plate": 0, "rotation_step": 0}
		]
	}
	SaveManager.save_to_file(test_data, valid_save_path)
	
	var corrupt_save_path = "user://saves/Corrupt_File.json"
	var f = FileAccess.open(corrupt_save_path, FileAccess.WRITE)
	f.store_string("THIS IS NOT VALID JSON {{{{")
	f.close()
	
	var gallery = MyBuildsGalleryScene.instantiate()
	root.add_child(gallery)
	if not gallery.is_node_ready():
		gallery._ready()
		
	var grid = gallery.find_child("GridContainer", true, false) as HFlowContainer
	assert(grid != null, "GridContainer exists")
	assert(grid.get_child_count() >= 2, "Gallery rendered cards for both valid and corrupt saves")
	
	# Verify open signal emission on valid save card
	var open_signaled = []
	gallery.open_creation_requested.connect(func(path): open_signaled.append(path))
	
	var open_btn: Button = null
	for card in grid.get_children():
		for b in card.find_children("*", "Button", true, false):
			if b.text == "Open":
				open_btn = b
				break
		if open_btn:
			break
			
	assert(open_btn != null, "Open button exists on valid creation card")
	open_btn.pressed.emit()
	assert(open_signaled.size() == 1, "Open creation requested signal emitted with valid path")
	
	# Verify delete button removes card
	var before_count = grid.get_child_count()
	var del_btn: Button = null
	for card in grid.get_children():
		for b in card.find_children("*", "Button", true, false):
			if b.text == "Delete" or b.text == "Delete File":
				del_btn = b
				break
		if del_btn:
			break
			
	assert(del_btn != null, "Delete button exists on card")
	del_btn.pressed.emit()
	assert(grid.get_child_count() == before_count - 1, "Delete button removed save card and refreshed")
	
	# Clean up remaining test files
	if FileAccess.file_exists(valid_save_path):
		DirAccess.remove_absolute(valid_save_path)
	if FileAccess.file_exists(corrupt_save_path):
		DirAccess.remove_absolute(corrupt_save_path)
		
	gallery.queue_free()
	print("  ✓ My Builds Gallery verified")
