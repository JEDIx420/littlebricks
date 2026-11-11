extends Node3D

## Controller for the Miniature Exploration phase (LB-015 & LB-016).
## Manages static collider instantiation, explorer spawning, camera modes,
## reset figure, and clean return to tabletop editing.

const ExplorationWorld = preload("res://core/exploration_world.gd")
const PartCatalog = preload("res://core/part_catalog.gd")
const PartMeshBuilder = preload("res://core/part_mesh_builder.gd")
const TableView = preload("res://client/scripts/table_view.gd")
const ToyExplorer = preload("res://client/scripts/toy_explorer.gd")

signal return_to_table(save_state: bool)
signal return_to_table_requested()

@onready var world_colliders_container: Node3D = $WorldColliders
@onready var visual_pieces_container: Node3D = $VisualPieces
@onready var explorer_container: Node3D = $ExplorerContainer
@onready var btn_toggle_pov: Button = %BtnTogglePOV
@onready var btn_reset_fig: Button = %BtnResetFig
@onready var btn_return_table: Button = %BtnReturnTable
@onready var label_pov_mode: Label = %LabelPOVMode
@onready var touch_stick: Control = %TouchStick
@onready var controls_hint: Label = %ControlsHint

var catalog: PartCatalog
var world_gen: ExplorationWorld
var explorer_instance: ToyExplorer = null

func _ready() -> void:
	catalog = PartCatalog.new()
	catalog.load_catalog("res://assets/catalog/parts_manifest.json")
	world_gen = ExplorationWorld.new(catalog)
	_connect_ui()
	_style_hud()
	_touch_controls(DisplayServer.is_touchscreen_available() or OS.has_feature("mobile"))

func _connect_ui() -> void:
	if btn_toggle_pov and not btn_toggle_pov.pressed.is_connected(_on_toggle_pov):
		btn_toggle_pov.pressed.connect(_on_toggle_pov)
	if btn_reset_fig and not btn_reset_fig.pressed.is_connected(_on_reset_figure):
		btn_reset_fig.pressed.connect(_on_reset_figure)
	if btn_return_table and not btn_return_table.pressed.is_connected(_on_return_to_table):
		btn_return_table.pressed.connect(_on_return_to_table)

func _style_hud() -> void:
	for panel in [%InfoCard, %ActionCard, %HintCard]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("#2b2922e9")
		style.border_color = Color("#826947")
		style.set_border_width_all(1)
		style.set_corner_radius_all(16)
		style.set_content_margin_all(8)
		panel.add_theme_stylebox_override("panel", style)
	UIThemeHelper.apply_primary_button(btn_return_table)
	UIThemeHelper.apply_secondary_button(btn_toggle_pov)
	UIThemeHelper.apply_secondary_button(btn_reset_fig)

func _touch_controls(enabled: bool) -> void:
	touch_stick.visible = enabled
	controls_hint.text = "Stick to walk  ·  Drag the scene to look" if enabled else "WASD / arrows to walk  ·  Right-drag to look"

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed and touch_stick and not touch_stick.visible:
		_touch_controls(true)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_on_return_to_table()

func _ensure_nodes() -> void:
	if not world_colliders_container:
		world_colliders_container = $WorldColliders
	if not visual_pieces_container:
		visual_pieces_container = $VisualPieces
	if not explorer_container:
		explorer_container = $ExplorerContainer
	if not catalog:
		catalog = PartCatalog.new()
		catalog.load_catalog("res://assets/catalog/parts_manifest.json")
	if not world_gen:
		world_gen = ExplorationWorld.new(catalog)

func setup_exploration(placements: Array, theme_id: String = "harbour") -> void:
	setup_exploration_scene(placements, theme_id)

## Initialize exploration world from frozen build placements
func setup_exploration_scene(placements: Array, theme_id: String = "harbour") -> void:
	_ensure_nodes()
	
	# Apply theme presentation lighting (LB-063)
	var world_env = find_child("WorldEnvironment", true, false) as WorldEnvironment
	var sun = find_child("DirectionalLight3D", true, false) as DirectionalLight3D
	var pres = PresentationController.new()
	pres.apply_presentation(theme_id, world_env, sun, $TableView)
	pres.free()
	# At toy height the sunlit walls and shiny brick tops fill much more of the
	# frame. Soften the same window light so those surfaces retain their colors.
	if sun:
		sun.light_energy *= 0.74
	if world_env and world_env.environment:
		world_env.environment.ambient_light_energy *= 0.90
	
	# Clear previous instances
	for c in world_colliders_container.get_children():
		c.queue_free()
	for c in visual_pieces_container.get_children():
		c.queue_free()
	if explorer_instance:
		if touch_stick and touch_stick.direction_changed.is_connected(explorer_instance.set_virtual_input):
			touch_stick.direction_changed.disconnect(explorer_instance.set_virtual_input)
		explorer_instance.queue_free()
		explorer_instance = null
		
	# 1. Generate smoothed static collision hierarchy
	var colliders = world_gen.generate_world_colliders(placements)
	world_colliders_container.add_child(colliders)
	
	# 2. Render frozen pieces visual geometry
	for p in placements:
		var part_id: String = p.get("part_id", "")
		var gx: int = p.get("grid_x", 0)
		var gz: int = p.get("grid_z", 0)
		var z_plate: int = p.get("layer_plate", 0)
		var rot_step: int = p.get("rotation_step", 0)
		var color: Color = p.get("color", Color.WHITE)
		
		var p_def = catalog.get_part(part_id)
		var dims = p_def.get("dimensions_studs", [1, 3, 1])
		var p_node = PartMeshBuilder.build_part_node(p_def, color)
		p_node.position = TableView.grid_to_world(gx, gz, z_plate, dims, rot_step)
		p_node.rotation_degrees = PlacementRules.get_rotation_degrees(rot_step)
		visual_pieces_container.add_child(p_node)
		
	# 3. Instantiate explorer at valid spawn facing toward creation (LB-063)
	var spawn_pos = world_gen.find_default_spawn(placements)
	var exp_scene: PackedScene = load("res://client/scenes/explorer.tscn")
	explorer_instance = exp_scene.instantiate() as ToyExplorer
	explorer_instance.position = spawn_pos
	
	explorer_container.add_child(explorer_instance)

	# Face toward the center of the build
	if not placements.is_empty():
		var sum_x: float = 0.0
		var sum_z: float = 0.0
		for p in placements:
			var gx = p.get("grid_x", 16)
			var gz = p.get("grid_z", 16)
			var w = TableView.grid_to_world(gx, gz, 0)
			sum_x += w.x
			sum_z += w.z
		var center_target = Vector3(sum_x / float(placements.size()), spawn_pos.y, sum_z / float(placements.size()))
		if spawn_pos.distance_squared_to(center_target) > 0.1:
			if explorer_instance.is_inside_tree():
				explorer_instance.look_at(center_target, Vector3.UP)
			else:
				explorer_instance.look_at_from_position(spawn_pos, center_target, Vector3.UP)

	explorer_instance.remember_spawn()
	explorer_instance.camera_mode_changed.connect(_on_camera_mode_changed)
	if touch_stick:
		touch_stick.direction_changed.connect(explorer_instance.set_virtual_input)

	_update_pov_label()

func _on_toggle_pov() -> void:
	if explorer_instance:
		explorer_instance.toggle_camera_mode()

func _on_reset_figure() -> void:
	if explorer_instance:
		explorer_instance.reset_to_spawn()

func _on_return_to_table() -> void:
	return_to_table.emit(true)
	return_to_table_requested.emit()

func _on_camera_mode_changed(_mode: ToyExplorer.CameraMode) -> void:
	_update_pov_label()

func _update_pov_label() -> void:
	if not explorer_instance or not label_pov_mode:
		return
	if explorer_instance.camera_mode == ToyExplorer.CameraMode.FIRST_PERSON:
		label_pov_mode.text = "First-person view"
		btn_toggle_pov.text = "Figure view"
	else:
		label_pov_mode.text = "Figure view"
		btn_toggle_pov.text = "First person"
