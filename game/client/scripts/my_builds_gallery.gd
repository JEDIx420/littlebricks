extends Control
class_name MyBuildsGallery

## Creation library and save manager view (LB-064).
## Displays saved creations with thumbnails, names, timestamps, piece counts,
## open and delete actions, empty states, and honest corrupt-save handling.

signal open_creation_requested(save_file_path: String)
signal start_new_build_requested()
signal back_pressed()

const SaveManager = preload("res://core/save_manager.gd")

@onready var btn_back: Button = %BtnBack
@onready var grid_container: HFlowContainer = %GridContainer
@onready var empty_card: PanelContainer = %EmptyCard
@onready var btn_start_new: Button = %BtnStartNew

func _ready() -> void:
	_ensure_nodes()
	if btn_back:
		UIThemeHelper.apply_secondary_button(btn_back)
		if not btn_back.pressed.is_connected(_on_back_clicked):
			btn_back.pressed.connect(_on_back_clicked)
			
	if empty_card:
		UIThemeHelper.apply_card(empty_card)
	if btn_start_new:
		UIThemeHelper.apply_primary_button(btn_start_new)
		if not btn_start_new.pressed.is_connected(_on_start_new_clicked):
			btn_start_new.pressed.connect(_on_start_new_clicked)
			
	refresh_builds()

func _ensure_nodes() -> void:
	if not btn_back: btn_back = find_child("BtnBack", true, false)
	if not grid_container: grid_container = find_child("GridContainer", true, false)
	if not empty_card: empty_card = find_child("EmptyCard", true, false)
	if not btn_start_new: btn_start_new = find_child("BtnStartNew", true, false)

func refresh_builds() -> void:
	_ensure_nodes()
	if not grid_container:
		return
		
	for child in grid_container.get_children():
		grid_container.remove_child(child)
		child.queue_free()
		
	var save_files = _find_all_saves()
	if save_files.is_empty():
		if empty_card: empty_card.visible = true
		grid_container.visible = false
		return
		
	if empty_card: empty_card.visible = false
	grid_container.visible = true
	
	for file_path in save_files:
		_create_build_card(file_path)

func _find_all_saves() -> Array[String]:
	var results: Array[String] = []
	var dir = DirAccess.open("user://saves")
	if not dir:
		return results
		
	dir.list_dir_begin()
	var filename = dir.get_next()
	while filename != "":
		if filename.ends_with(".json") and not filename.ends_with(".tmp"):
			results.append("user://saves/" + filename)
		filename = dir.get_next()
		
	# Sort newest first by modified time
	results.sort_custom(func(a, b):
		return FileAccess.get_modified_time(a) > FileAccess.get_modified_time(b)
	)
	return results

func _create_build_card(file_path: String) -> void:
	var res = SaveManager.load_from_file(file_path)
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(280, 220)
	UIThemeHelper.apply_card(card)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	card.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)
	
	if not res.get("success", false):
		# Corrupt save state
		var title = Label.new()
		title.text = "[Corrupt Save] " + file_path.get_file().get_basename()
		title.add_theme_color_override("font_color", UIThemeHelper.COLOR_ERROR_INK)
		title.add_theme_font_size_override("font_size", 16)
		vbox.add_child(title)
		
		var desc = Label.new()
		desc.text = "This file could not be parsed: %s" % res.get("error", "Invalid JSON")
		desc.add_theme_color_override("font_color", UIThemeHelper.COLOR_TEXT_SECONDARY)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vbox.add_child(desc)
		
		var btn_del = Button.new()
		btn_del.text = "Delete File"
		btn_del.custom_minimum_size = Vector2(0, 44)
		UIThemeHelper.apply_secondary_button(btn_del)
		btn_del.pressed.connect(func():
			DirAccess.remove_absolute(file_path)
			refresh_builds()
		)
		vbox.add_child(btn_del)
		grid_container.add_child(card)
		return
		
	var data = res.get("data", {})
	var c_name = data.get("creation_name", file_path.get_file().get_basename().replace("_", " "))
	var pieces_count = data.get("placements", []).size()
	var theme_id = data.get("theme_id", "harbour")
	var theme_name = "Cozy Harbour" if theme_id == "harbour" else "Forest Cabin"
	
	var title = Label.new()
	title.text = c_name
	title.add_theme_color_override("font_color", UIThemeHelper.COLOR_TEXT_INK)
	title.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title)
	
	var info = Label.new()
	info.text = "%s • %d brick%s" % [theme_name, pieces_count, "" if pieces_count == 1 else "s"]
	info.add_theme_color_override("font_color", UIThemeHelper.COLOR_TEXT_SECONDARY)
	info.add_theme_font_size_override("font_size", 14)
	info.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(info)
	
	var btn_box = HBoxContainer.new()
	btn_box.add_theme_constant_override("separation", 8)
	vbox.add_child(btn_box)
	
	var btn_open = Button.new()
	btn_open.text = "Open"
	btn_open.custom_minimum_size = Vector2(0, 44)
	btn_open.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UIThemeHelper.apply_primary_button(btn_open)
	btn_open.pressed.connect(func():
		open_creation_requested.emit(file_path)
	)
	btn_box.add_child(btn_open)
	
	var btn_delete = Button.new()
	btn_delete.text = "Delete"
	btn_delete.custom_minimum_size = Vector2(80, 44)
	UIThemeHelper.apply_secondary_button(btn_delete)
	btn_delete.pressed.connect(func():
		DirAccess.remove_absolute(file_path)
		refresh_builds()
	)
	btn_box.add_child(btn_delete)
	
	grid_container.add_child(card)

func _on_back_clicked() -> void:
	back_pressed.emit()

func _on_start_new_clicked() -> void:
	start_new_build_requested.emit()
