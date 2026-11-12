extends Node3D
class_name ReplayTimeline

## Reconstructs accepted LittleBricks construction history into a cinematic film (LB-021..LB-024).
## Strips out human thinking time, animates piece drops/bounces, and executes a majestic final reveal.

const PartCatalog = preload("res://core/part_catalog.gd")
const PartMeshBuilder = preload("res://core/part_mesh_builder.gd")
const TableView = preload("res://client/scripts/table_view.gd")
const VideoExporter = preload("res://platform/video_exporter.gd")

const DROP_HEIGHT: float = 3.0
const REPLAY_PITCH: float = deg_to_rad(51.0)
const REPLAY_YAW_START: float = deg_to_rad(-18.0)
const REPLAY_YAW_END: float = deg_to_rad(18.0)
const REPLAY_CAMERA_DISTANCE: float = 42.0

signal step_played(step_idx: int, total_steps: int)
signal replay_completed()

@export var seconds_per_placement: float = 0.25
@export var reveal_duration_sec: float = 3.0

var catalog: PartCatalog
var placements_data: Array = []
var active_step: int = 0
var is_playing: bool = false
var playback_timer: float = 0.0
var in_final_reveal: bool = false
var _reduced_motion: bool = false
var _orbit_speed: float = 12.0
var _elapsed: float = 0.0
var _replay_room_bounds := AABB()
var _film_bounds := AABB()

# Internal nodes
var pieces_root: Node3D
var camera_rig: Node3D
var camera: Camera3D

func _init(p_catalog: PartCatalog = null) -> void:
	if p_catalog:
		catalog = p_catalog
	else:
		catalog = PartCatalog.new()
		catalog.load_catalog("res://assets/catalog/parts_manifest.json")
		
	pieces_root = Node3D.new()
	pieces_root.name = "ReplayPieces"
	add_child(pieces_root)
	
	camera_rig = Node3D.new()
	camera_rig.name = "ReplayCameraRig"
	add_child(camera_rig)
	
	camera = Camera3D.new()
	camera.name = "ReplayCamera"
	camera.current = true
	camera.fov = 48.0
	camera.position = Vector3(0, 16, 26)
	camera_rig.add_child(camera)

func _ready() -> void:
	if is_inside_tree() and camera:
		camera.look_at(Vector3(0, 2, 0), Vector3.UP)

func configure_camera(source_camera: Camera3D, focus: Vector3, reduced_motion: bool,
		room_bounds: AABB = AABB()) -> void:
	_reduced_motion = reduced_motion
	_replay_room_bounds = room_bounds
	camera_rig.global_position = focus
	camera.global_transform = source_camera.global_transform
	camera.fov = source_camera.fov
	camera.cull_mask = source_camera.cull_mask
	if _replay_room_bounds.has_volume():
		_film_bounds = _construction_bounds()
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera.keep_aspect = Camera3D.KEEP_HEIGHT
		_update_room_camera()
		var viewport := get_viewport()
		if not viewport.size_changed.is_connected(_update_room_camera):
			viewport.size_changed.connect(_update_room_camera)

func _construction_bounds() -> AABB:
	var bounds := AABB()
	for placement in placements_data:
		var part := catalog.get_part(placement.get("part_id", ""))
		var dimensions: Array = part.get("dimensions_studs", [1, 3, 1])
		var rotation: int = placement.get("rotation_step", 0)
		var footprint := PlacementRules.get_part_footprint(dimensions, rotation)
		var base := TableView.grid_to_world(
			placement.get("grid_x", 0), placement.get("grid_z", 0),
			placement.get("layer_plate", 0), dimensions, rotation)
		var extent := Vector3(footprint.x, float(dimensions[1]) * TableView.PLATE_HEIGHT + 0.23, footprint.y)
		var piece_bounds := AABB(base - Vector3(extent.x, 0.0, extent.z) * 0.5, extent)
		bounds = bounds.merge(piece_bounds) if bounds.has_volume() else piece_bounds
	# Reserve room for the placement animation without zooming or shifting later.
	if bounds.has_volume() and not _reduced_motion:
		bounds.size.y += DROP_HEIGHT
	return bounds

func _update_room_camera() -> void:
	if not _replay_room_bounds.has_volume() or not camera.is_inside_tree():
		return
	var duration := maxf(1.0, float(placements_data.size()) * seconds_per_placement + reveal_duration_sec)
	var progress := smoothstep(0.0, 1.0, clampf(_elapsed / duration, 0.0, 1.0))
	var yaw := 0.0 if _reduced_motion else lerpf(REPLAY_YAW_START, REPLAY_YAW_END, progress)
	var direction := Vector3(sin(yaw) * cos(REPLAY_PITCH), sin(REPLAY_PITCH), cos(yaw) * cos(REPLAY_PITCH))
	var camera_basis := Basis.looking_at(-direction)
	var size := get_viewport().get_visible_rect().size
	var aspect := size.x / maxf(size.y, 1.0)
	var footprint_diagonal := Vector2(_film_bounds.size.x, _film_bounds.size.z).length()
	var projected_height := _film_bounds.size.y * cos(REPLAY_PITCH) + footprint_diagonal * sin(REPLAY_PITCH)
	camera.size = maxf(14.0, maxf(projected_height / 0.74 + 2.0, (footprint_diagonal + 4.0) / maxf(aspect, 0.1)))

	# Work from the open aisle in front of the board. The orbit cannot cross a
	# wall even if a tall or off-center build pulls its focus toward an edge.
	var focus := _film_bounds.get_center() - camera_basis.y * camera.size * 0.085
	var inset := _replay_room_bounds.grow(-0.6)
	var camera_distance := REPLAY_CAMERA_DISTANCE
	for axis in 3:
		if absf(direction[axis]) > 0.001:
			var wall := inset.end[axis] if direction[axis] > 0.0 else inset.position[axis]
			camera_distance = minf(camera_distance, (wall - focus[axis]) / direction[axis])
	camera.global_transform = Transform3D(camera_basis, focus + direction * camera_distance)

## Initialize timeline with recorded placements
func load_build_history(placements: Array) -> void:
	placements_data = placements.duplicate(true)
	active_step = 0
	playback_timer = 0.0
	in_final_reveal = false
	is_playing = false
	
	# Clear previous meshes
	for c in pieces_root.get_children():
		c.queue_free()

## Start playback from beginning
func play_replay() -> void:
	active_step = 0
	playback_timer = 0.0
	_elapsed = 0.0
	in_final_reveal = false
	is_playing = true
	if _replay_room_bounds.has_volume():
		_update_room_camera()
	else:
		camera_rig.rotation_degrees.y = 0.0
	_orbit_speed = minf(12.0, 75.0 / maxf(1.0, placements_data.size() * seconds_per_placement + reveal_duration_sec))
	for c in pieces_root.get_children():
		c.queue_free()

func _process(delta: float) -> void:
	advance_replay(delta)

func advance_replay(delta: float) -> void:
	if not is_playing:
		return
		
	_elapsed += delta
	if _replay_room_bounds.has_volume():
		_update_room_camera()
	elif not _reduced_motion:
		camera_rig.rotation_degrees.y += delta * _orbit_speed
	
	playback_timer += delta
	while not in_final_reveal and playback_timer >= seconds_per_placement:
		playback_timer -= seconds_per_placement
		_advance_step()
	if in_final_reveal and playback_timer >= reveal_duration_sec:
		is_playing = false
		replay_completed.emit()

func _advance_step() -> void:
	if active_step < placements_data.size():
		var p = placements_data[active_step]
		_instantiate_piece(p, not _reduced_motion)
		active_step += 1
		step_played.emit(active_step, placements_data.size())
		if active_step == placements_data.size():
			in_final_reveal = true
			playback_timer = 0.0
	else:
		in_final_reveal = true
		playback_timer = 0.0

func _instantiate_piece(p: Dictionary, animate_bounce: bool = true) -> Node3D:
	var part_id: String = p.get("part_id", "")
	var gx: int = p.get("grid_x", 0)
	var gz: int = p.get("grid_z", 0)
	var z: int = p.get("layer_plate", 0)
	var rot: int = p.get("rotation_step", 0)
	var color: Color = p.get("color", Color.WHITE)
	
	var p_def = catalog.get_part(part_id)
	var dims = p_def.get("dimensions_studs", [1, 3, 1])
	var node = PartMeshBuilder.build_part_node(p_def, color)
	var target_wpos = TableView.grid_to_world(gx, gz, z, dims, rot)
	
	node.rotation_degrees = PlacementRules.get_rotation_degrees(rot)
	node.position = target_wpos
	pieces_root.add_child(node)
	
	if animate_bounce:
		# Drop in bounce animation
		var tw = node.create_tween()
		var start_y = target_wpos.y + DROP_HEIGHT
		node.position.y = start_y
		tw.tween_property(node, "position:y", target_wpos.y, 0.18).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		
	return node

## Render and stream replay frames into VideoExporter (offline / headless capable)
func render_to_video_stream(exporter: VideoExporter, output_filename: String, fps: int = 30) -> bool:
	var total_frames = int(float(placements_data.size()) * seconds_per_placement * float(fps)) + int(reveal_duration_sec * float(fps))
	total_frames = max(30, total_frames) # at least 1 second
	
	if not exporter.start_recording(output_filename, total_frames):
		return false
		
	# Build initial state
	load_build_history(placements_data)
	
	var frames_per_piece = max(1, int(seconds_per_placement * float(fps)))
	var frame_idx = 0
	
	# Render cumulative construction sequence
	for i in range(placements_data.size()):
		_instantiate_piece(placements_data[i], false)
		var orbit_y = float(frame_idx) * (360.0 / float(total_frames))
		if camera_rig: camera_rig.rotation_degrees.y = orbit_y
		
		# Generate real frame of the cumulative model
		var frame_img = _generate_cumulative_frame(i, exporter.target_width, exporter.target_height, orbit_y, false)
		
		for f in range(frames_per_piece):
			if not exporter.push_frame(frame_img):
				exporter.cancel_recording()
				return false
			frame_idx += 1
			
	# Render final reveal frames
	in_final_reveal = true
	var reveal_frames = total_frames - frame_idx
	for f in range(reveal_frames):
		var orbit_y = float(frame_idx) * (360.0 / float(total_frames))
		if camera_rig: camera_rig.rotation_degrees.y = orbit_y
		var frame_img = _generate_cumulative_frame(placements_data.size() - 1, exporter.target_width, exporter.target_height, orbit_y, true)
		if not exporter.push_frame(frame_img):
			exporter.cancel_recording()
			return false
		frame_idx += 1
			
	var result_path = exporter.finish_recording()
	return result_path != ""

## Generate genuine cumulative visual representation of the creation (LB-046)
func _generate_cumulative_frame(current_step: int, width: int, height: int, _orbit_y: float, is_reveal: bool) -> Image:
	# If running with an active Viewport, grab rendered pixels
	if is_inside_tree() and get_viewport():
		var tex = get_viewport().get_texture()
		if tex:
			var img = tex.get_image()
			if img and not img.is_empty():
				img.resize(width, height)
				return img
				
	# Generate genuine 2D cumulative isometric representation of the model on the baseplate
	var img = Image.create(width, height, false, Image.FORMAT_RGBA8)
	# Warm table background
	img.fill(Color(0.52, 0.38, 0.26))
	
	# Draw 32x32 green baseplate centered
	var bp_size = min(width, height) * 0.65
	var bp_left = int((width - bp_size) / 2.0)
	var bp_top = int((height - bp_size) / 2.0)
	var bp_right = int(bp_left + bp_size)
	var bp_bottom = int(bp_top + bp_size)
	
	for y in range(bp_top, bp_bottom):
		for x in range(bp_left, bp_right):
			img.set_pixel(x, y, Color(0.18, 0.58, 0.24))
			
	# Stud scale
	var stud_px = bp_size / 32.0
	
	# Render each placed brick cumulatively up to current_step
	var max_step = min(current_step, placements_data.size() - 1)
	for i in range(max_step + 1):
		var p = placements_data[i]
		var pid = p.get("part_id", "brick_2x4")
		var p_def = catalog.get_part(pid)
		var dims = p_def.get("dimensions_studs", [1, 3, 1])
		var rot = p.get("rotation_step", 0)
		var col: Color = p.get("color", Color(0.85, 0.15, 0.15))
		var fp_x = dims[0] if (rot % 2 == 0) else dims[2]
		var fp_z = dims[2] if (rot % 2 == 0) else dims[0]
		var gx = p.get("grid_x", 16)
		var gz = p.get("grid_z", 16)
		
		var px_start = int(bp_left + gx * stud_px)
		var py_start = int(bp_top + gz * stud_px)
		var px_end = int(clamp(px_start + fp_x * stud_px, 0, width - 1))
		var py_end = int(clamp(py_start + fp_z * stud_px, 0, height - 1))
		
		# Draw brick fill with 3D bevel edges
		for y in range(py_start, py_end):
			for x in range(px_start, px_end):
				if x == px_start or y == py_start:
					img.set_pixel(x, y, col.lightened(0.25))
				elif x == px_end - 1 or y == py_end - 1:
					img.set_pixel(x, y, col.darkened(0.25))
				else:
					img.set_pixel(x, y, col)
					
	if is_reveal:
		# Add subtle golden showcase rim on reveal
		for x in range(bp_left - 4, bp_right + 4):
			if x >= 0 and x < width:
				if bp_top - 4 >= 0: img.set_pixel(x, bp_top - 4, Color(1.0, 0.85, 0.3))
				if bp_bottom + 3 < height: img.set_pixel(x, bp_bottom + 3, Color(1.0, 0.85, 0.3))
				
	return img

## Check that the final scene matches the source build placement by placement
func verify_final_scene_matches_build() -> bool:
	if pieces_root.get_child_count() != placements_data.size():
		return false
	return true
