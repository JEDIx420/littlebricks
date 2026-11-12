extends SceneTree

const Models := preload("res://core/blueprint_models.gd")
const Catalog := preload("res://core/part_catalog.gd")
const Rules := preload("res://core/placement_rules.gd")

func _initialize() -> void:
	var catalog := Catalog.new()
	catalog.load_catalog("res://assets/catalog/parts_manifest.json")
	var rules := Rules.new(catalog)
	var failures: int = 0
	for theme_id in Models.THEMES:
		var model := Models.get_model(theme_id)
		var placed: Array = []
		for record in model.pieces:
			var result := rules.validate_placement(record.part_id, record.grid_x, record.grid_z, record.layer_plate, record.rotation_step, placed)
			if not result.get("valid", false):
				push_error("%s reference: %s at (%d, %d, %d) is %s" % [
					theme_id, record.part_id, record.grid_x, record.grid_z, record.layer_plate, result.get("code", "invalid"),
				])
				failures += 1
			placed.append(record)
		if placed.is_empty():
			push_error("%s reference has no pieces" % theme_id)
			failures += 1
		print("%s: %d reference placements checked" % [theme_id, placed.size()])
	quit(1 if failures else 0)
