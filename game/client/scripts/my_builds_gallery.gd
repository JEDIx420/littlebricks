extends Control
class_name MyBuildsGallery

## Creation library and save manager view (LB-064).
## Displays saved creations with thumbnails, names, timestamps, piece counts,
## open and delete actions, empty states, and honest corrupt-save handling.

signal open_creation_requested(save_file_path: String)
signal start_new_build_requested()
signal back_pressed()

const SaveManager = preload("res://core/save_manager.gd")
const Studio = preload("res://client/scripts/menu_studio.gd")
const Packs = preload("res://core/brick_packs.gd")

# Draw a lightweight model sketch from saved positions. Each shelf card
# shares one catalogue and needs no additional 3D viewport.
class BuildSketch extends Control:
	var pieces: Array[Dictionary] = []
	var ink := Color("#a4442d")
	var bounds := Rect2()
	var _background := Studio.surface(Color("#18392f"), 10, Color("#aa8b56"))

	func configure(saved: Array, catalog: PartCatalog) -> void:
		# Very large builds still get a recognizable silhouette without
		# constructing a full mesh for each thumbnail.
		var step := maxi(1, ceili(saved.size() / 450.0))
		for index in range(0, saved.size(), step):
			var record = saved[index]
			if not record is Dictionary:
				continue
			var part := catalog.get_part(str(record.get("part_id", "")))
			if part.is_empty():
				continue
			var dimensions: Array = part["dimensions_studs"]
			var rotation := int(record.get("rotation_step", 0))
			var footprint := PlacementRules.get_part_footprint(dimensions, rotation)
			var span := Vector3(footprint.x, float(dimensions[1]) * PlacementRules.PLATE_HEIGHT, footprint.y)
			var base := Vector3(float(record.get("grid_x", 0)), float(record.get("layer_plate", 0)) * PlacementRules.PLATE_HEIGHT, float(record.get("grid_z", 0)))
			var color := Color.from_string(str(record.get("color_hex", "#d3a65c")), Color("#d3a65c"))
			pieces.append({"base": base, "span": span, "ink": color})
			for x in [0.0, span.x]:
				for y in [0.0, span.y]:
					for z in [0.0, span.z]:
						var point := _project(base + Vector3(x, y, z))
						bounds = Rect2(point, Vector2.ZERO) if bounds == Rect2() else bounds.expand(point)
		pieces.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			var first: Vector3 = a.base + a.span
			var second: Vector3 = b.base + b.span
			return first.x + first.z + first.y * 0.15 < second.x + second.z + second.y * 0.15
		)

	func _draw() -> void:
		draw_style_box(_background, Rect2(Vector2.ZERO, size))
		for x in range(12, int(size.x), 13):
			for y in range(12, int(size.y), 13):
				draw_circle(Vector2(x, y), 1.0, Color("#d0be8335"))
		if pieces.is_empty():
			_piece(Vector3.ZERO, Vector3(2.0, 0.9, 2.0), ink, size / 2.0, 14.0)
			return
		var space := size - Vector2(26.0, 20.0)
		var zoom := minf(16.0, minf(space.x / maxf(bounds.size.x, 0.1), space.y / maxf(bounds.size.y, 0.1)))
		var origin := size * 0.5 - bounds.get_center() * zoom
		for piece in pieces:
			_piece(piece.base, piece.span, piece.ink, origin, zoom)

	func _piece(base: Vector3, span: Vector3, color: Color, origin: Vector2, zoom: float) -> void:
		var a := origin + _project(base + Vector3(0, span.y, 0)) * zoom
		var b := origin + _project(base + Vector3(span.x, span.y, 0)) * zoom
		var c := origin + _project(base + span) * zoom
		var d := origin + _project(base + Vector3(0, span.y, span.z)) * zoom
		var drop := Vector2(0, span.y * zoom)
		draw_colored_polygon(PackedVector2Array([b, c, c + drop, b + drop]), color.darkened(0.36))
		draw_colored_polygon(PackedVector2Array([d, c, c + drop, d + drop]), color.darkened(0.18))
		draw_colored_polygon(PackedVector2Array([a, b, c, d]), color.lightened(0.12))

	func _project(point: Vector3) -> Vector2:
		return Vector2(point.x - point.z, (point.x + point.z) * 0.45 - point.y)


@onready var btn_back: Button = %BtnBack
@onready var grid_container: HFlowContainer = %GridContainer
@onready var empty_card: PanelContainer = %EmptyCard
@onready var btn_start_new: Button = %BtnStartNew

var _catalog := PartCatalog.new()
var _initialized := false

func _ready() -> void:
	if _initialized:
		return
	_initialized = true
	Studio.apply_theme(self, true)
	Studio.dark_button(btn_back)
	Studio.style_label($MainLayout/HeadingBox/Heading, 42, true, Studio.IVORY)
	Studio.style_label(empty_card.find_child("EmptyTitle"), 29, true)
	Studio.style_label(empty_card.find_child("EmptyDesc"), 15, false, Studio.MUTED)
	empty_card.add_theme_stylebox_override("panel", Studio.surface(Studio.PAPER, 16, Studio.BRASS, true))
	Studio.button(btn_start_new, true)
	btn_back.pressed.connect(_on_back_clicked)
	btn_start_new.pressed.connect(_on_start_new_clicked)
	resized.connect(_layout_shelf)
	_catalog.load_catalog("res://assets/catalog/parts_manifest.json")
	_layout_shelf()
	refresh_builds()

func _layout_shelf() -> void:
	var gutter := 12.0 if size.x < 600.0 else 26.0
	$TopBar.offset_left = gutter
	$TopBar.offset_right = -gutter
	$TopBar.offset_top = 8.0 if size.y < 500.0 else 20.0
	$MainLayout.offset_left = gutter
	$MainLayout.offset_right = -gutter
	$MainLayout.offset_top = 62.0 if size.y < 500.0 else 78.0
	$MainLayout.offset_bottom = -12.0
	# CenterWrapper fills the scroll width. Flow cards wrap at that width.
	grid_container.custom_minimum_size.x = maxf(0.0, size.x - 2.0 * gutter - 12.0)
	for card in grid_container.get_children():
		card.custom_minimum_size.x = _card_width()
		var preview := card.find_child("BuildSketch", true, false) as Control
		if preview:
			preview.custom_minimum_size.y = 66.0 if size.y < 460.0 else 112.0

func _card_width() -> float:
	return minf(272.0, maxf(236.0, size.x - 38.0))

func refresh_builds() -> void:
	if not grid_container:
		return
		
	for child in grid_container.get_children():
		grid_container.remove_child(child)
		child.queue_free()
		
	var save_files = _find_all_saves()
	if save_files.is_empty():
		if empty_card: empty_card.visible = true
		grid_container.visible = false
		Studio.enter(empty_card)
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
	card.custom_minimum_size.x = _card_width()
	card.add_theme_stylebox_override("panel", Studio.surface(Studio.PAPER, 15, Studio.BRASS, true))
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 7)
	card.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 7)
	margin.add_child(vbox)
	
	if not res.get("success", false):
		# Corrupt save state
		var title = Label.new()
		title.text = "[Corrupt Save] " + file_path.get_file().get_basename()
		title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		Studio.style_label(title, 16, false, Color("#8d3325"))
		vbox.add_child(title)
		
		var desc = Label.new()
		desc.text = "This file could not be parsed: %s" % res.get("error", "Invalid JSON")
		Studio.style_label(desc, 14, false, Studio.MUTED)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vbox.add_child(desc)
		
		var btn_del = Button.new()
		btn_del.text = "Delete File"
		btn_del.custom_minimum_size = Vector2(0, 44)
		Studio.button(btn_del)
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
	var pack_index := Packs.IDS.find(theme_id)
	var theme_name: String = Packs.LABELS[pack_index] if pack_index >= 0 else "Custom build"

	var preview := BuildSketch.new()
	preview.name = "BuildSketch"
	preview.custom_minimum_size.y = 66.0 if size.y < 460.0 else 112.0
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.configure(data.get("placements", []), _catalog)
	vbox.add_child(preview)
	var title = Label.new()
	title.text = c_name
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	Studio.style_label(title, 23, true)
	vbox.add_child(title)
	
	var info = Label.new()
	info.text = "%s • %d brick%s" % [theme_name, pieces_count, "" if pieces_count == 1 else "s"]
	Studio.style_label(info, 14, false, Studio.MUTED)
	info.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(info)
	
	var btn_box = HBoxContainer.new()
	btn_box.add_theme_constant_override("separation", 8)
	vbox.add_child(btn_box)
	
	var btn_open = Button.new()
	btn_open.text = "Open"
	btn_open.custom_minimum_size = Vector2(0, 44)
	btn_open.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Studio.button(btn_open, true)
	btn_open.pressed.connect(func():
		open_creation_requested.emit(file_path)
	)
	btn_box.add_child(btn_open)
	
	var btn_delete = Button.new()
	btn_delete.text = "Delete"
	btn_delete.custom_minimum_size = Vector2(80, 44)
	Studio.button(btn_delete)
	btn_delete.pressed.connect(func():
		DirAccess.remove_absolute(file_path)
		refresh_builds()
	)
	btn_box.add_child(btn_delete)
	
	grid_container.add_child(card)
	Studio.enter(card, minf(0.13, 0.03 * card.get_index()))

func _on_back_clicked() -> void:
	back_pressed.emit()

func _on_start_new_clicked() -> void:
	start_new_build_requested.emit()
