class_name BlueprintModels
extends RefCounted

## Authored finished models built on the same stud lattice as live creations.
## These records are reference art and never enter a player's board or history.
const THEMES := ["harbour", "cabin", "galaxy", "heroes", "castle"]
const LABELS := ["Harbour", "Cabin", "Galaxy", "Heroes", "Castle"]

static func get_model(theme_id: String) -> Dictionary:
	match theme_id:
		"cabin":
			return {"title": "Pinewood Cabin", "accent": Color("#d8b883"), "pieces": _cabin()}
		"galaxy":
			return {"title": "Moon Skimmer", "accent": Color("#a7daee"), "pieces": _galaxy()}
		"heroes":
			return {"title": "Rooftop Rescue", "accent": Color("#ffbf91"), "pieces": _heroes()}
		"castle":
			return {"title": "Castle Gatehouse", "accent": Color("#efc67d"), "pieces": _castle()}
		_:
			return {"title": "Beacon Point", "accent": Color("#a9e0d5"), "pieces": _harbour()}

static func _put(pieces: Array[Dictionary], part_id: String, x: int, z: int, layer: int, color: String, rotation: int = 0) -> void:
	pieces.append({
		"part_id": part_id, "grid_x": x, "grid_z": z, "layer_plate": layer,
		"color": Color(color), "rotation_step": rotation,
	})

static func _harbour() -> Array[Dictionary]:
	var pieces: Array[Dictionary] = []
	_put(pieces, "plate_8x8", 12, 12, 0, "#597f82")
	_put(pieces, "plate_4x4", 12, 12, 1, "#cfb58a")
	_put(pieces, "brick_round_4x4", 12, 12, 2, "#e7e1ce")
	_put(pieces, "brick_round_4x4", 12, 12, 5, "#c43f35")
	_put(pieces, "brick_round_4x4", 12, 12, 8, "#e7e1ce")
	_put(pieces, "brick_round_4x4", 12, 12, 11, "#c43f35")
	_put(pieces, "plate_round_4x4", 12, 12, 14, "#d7a34b")
	_put(pieces, "lighthouse_top_4x4", 12, 12, 15, "#d7a34b")
	for x in [13, 14, 15, 18]:
		_put(pieces, "tile_1x4", x, 16, 1, "#977052" if x % 2 else "#b78761")
	_put(pieces, "bollard_1x1", 12, 18, 1, "#45434b")
	_put(pieces, "bollard_1x1", 19, 18, 1, "#45434b")
	_put(pieces, "crate_2x2", 16, 17, 1, "#aa7150")
	_put(pieces, "buoy_marker_1x1", 19, 17, 1, "#e7a845")
	return pieces

static func _cabin() -> Array[Dictionary]:
	var pieces: Array[Dictionary] = []
	_put(pieces, "plate_8x8", 12, 12, 0, "#6d8755")
	_put(pieces, "plate_4x6", 13, 13, 1, "#c49a66", 1)
	for layer in [2, 5, 8]:
		var timber: String = "#ad754b" if layer == 5 else "#875738"
		_put(pieces, "brick_1x6", 13, 13, layer, timber, 1)
		_put(pieces, "brick_1x3", 13, 14, layer, timber)
		_put(pieces, "brick_1x3", 18, 14, layer, timber)
		_put(pieces, "brick_1x1", 14, 16, layer, timber)
		_put(pieces, "brick_1x1", 17, 16, layer, timber)
	_put(pieces, "arch_1x4", 14, 16, 11, "#d6b281", 1)
	_put(pieces, "brick_1x6", 13, 13, 11, "#ad754b", 1)
	_put(pieces, "brick_1x3", 13, 14, 11, "#ad754b")
	_put(pieces, "brick_1x3", 18, 14, 11, "#ad754b")
	_put(pieces, "plate_4x6", 13, 13, 14, "#654633", 1)
	for x in [13, 15, 17]:
		_put(pieces, "slope_2x2", x, 13, 15, "#894b40")
		_put(pieces, "slope_2x2", x, 15, 15, "#a65e4b", 2)
	_put(pieces, "tree_cone_2x2x4", 12, 18, 1, "#587857")
	_put(pieces, "bench_1x4", 15, 18, 1, "#d0ae7d", 1)
	return pieces

static func _galaxy() -> Array[Dictionary]:
	var pieces: Array[Dictionary] = []
	_put(pieces, "plate_8x8", 12, 12, 0, "#475870")
	_put(pieces, "plate_2x8", 15, 12, 1, "#cddde5")
	for x in [13, 17]:
		_put(pieces, "plate_2x4", x, 14, 1, "#cddde5")
		_put(pieces, "plate_2x2", x, 16, 2, "#bacbd7")
	_put(pieces, "plate_1x4", 12, 15, 1, "#79b9c8")
	_put(pieces, "plate_1x4", 19, 15, 1, "#79b9c8")
	_put(pieces, "slope_2x2", 15, 18, 2, "#e6e0ce", 2)
	_put(pieces, "brick_2x3", 15, 15, 2, "#e6e0ce")
	_put(pieces, "slope_2x2", 15, 15, 5, "#538eb0", 2)
	_put(pieces, "tile_2x2", 15, 13, 2, "#d99a59")
	for x in [13, 17]:
		_put(pieces, "brick_round_2x2", x, 14, 2, "#617b8a")
		_put(pieces, "plate_round_2x2", x, 14, 5, "#e7b36c")
	_put(pieces, "tile_1x2", 12, 15, 2, "#f7d396")
	_put(pieces, "tile_1x2", 19, 15, 2, "#f7d396")
	return pieces

static func _heroes() -> Array[Dictionary]:
	var pieces: Array[Dictionary] = []
	_put(pieces, "plate_8x8", 12, 12, 0, "#756e74")
	for layer in [1, 4, 7]:
		var brick: String = "#54697e" if layer == 4 else "#3e5167"
		_put(pieces, "brick_1x6", 13, 13, layer, brick, 1)
		_put(pieces, "brick_1x4", 13, 14, layer, brick)
		_put(pieces, "brick_1x4", 18, 14, layer, brick)
		_put(pieces, "brick_1x1", 14, 17, layer, brick)
		_put(pieces, "brick_1x1", 17, 17, layer, brick)
	_put(pieces, "window_1x2x3", 15, 17, 1, "#87bac4", 1)
	_put(pieces, "plate_4x6", 13, 13, 10, "#c37c57", 1)
	_put(pieces, "plate_1x6", 13, 17, 10, "#dda974", 1)
	_put(pieces, "toy_explorer_marina", 15, 15, 11, "#e9ad68", 2)
	_put(pieces, "lantern_post_1x1x3", 18, 13, 11, "#c4905f")
	_put(pieces, "flag_1x2", 13, 13, 11, "#c85c5a")
	_put(pieces, "crate_2x2", 16, 18, 1, "#bd8b69")
	return pieces

static func _castle() -> Array[Dictionary]:
	var pieces: Array[Dictionary] = []
	_put(pieces, "plate_6x6", 10, 14, 0, "#74866a")
	_put(pieces, "plate_6x6", 16, 14, 0, "#74866a")
	for x in [11, 19]:
		for layer in [1, 4, 7, 10]:
			_put(pieces, "brick_2x2", x, 15, layer, "#bab8a8" if layer % 2 else "#a39d91")
		_put(pieces, "plate_3x3", x, 14, 13, "#a5a093")
		for dx in [0, 2]:
			for dz in [0, 2]:
				_put(pieces, "brick_1x1", x + dx, 14 + dz, 14, "#cac7b9")
		_put(pieces, "flag_1x2", x + 1, 14, 14, "#a64c49")
	for x in [13, 18]:
		_put(pieces, "brick_1x1", x, 15, 1, "#bab8a8")
		_put(pieces, "brick_1x1", x, 15, 4, "#a39d91")
		_put(pieces, "brick_1x1", x, 15, 7, "#bab8a8")
	_put(pieces, "arch_1x6", 13, 15, 10, "#c3bba9", 1)
	for x in [14, 16]:
		_put(pieces, "tile_1x2", x, 16, 1, "#ad9b85", 1)
	return pieces
