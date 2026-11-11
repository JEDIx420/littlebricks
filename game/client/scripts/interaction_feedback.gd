extends RefCounted
class_name InteractionFeedback

## Translates semantic interaction and accepted session events into sound,
## animation, and optional haptics (LB-041).
## Strictly deduplicates live events by session + event ID to avoid double-clicks or buzzes.

var audio_director = null
var haptics_adapter = null
var settings_manager = null

var _handled_event_ids: Dictionary = {}
var _last_valid_state: bool = false
var _has_valid_state_initialized: bool = false

func _init(p_audio = null, p_haptics = null, p_settings = null) -> void:
	audio_director = p_audio
	haptics_adapter = p_haptics
	settings_manager = p_settings

func notify_piece_selected(_part_id: String, _color: Color) -> void:
	if audio_director:
		audio_director.play_pickup()
	if haptics_adapter:
		haptics_adapter.vibrate_light()

func notify_rotation_changed(_step: int) -> void:
	if audio_director:
		audio_director.play_rotate()

func notify_preview_validity_changed(is_valid: bool) -> void:
	if not _has_valid_state_initialized:
		_last_valid_state = is_valid
		_has_valid_state_initialized = true
		return
	if is_valid and not _last_valid_state:
		# Meaningful validity transition (from invalid to legal)
		if audio_director and audio_director.has_method("play_tick"):
			audio_director.play_tick()
	_last_valid_state = is_valid

func notify_placement_accepted(event_id: String, placed_node: Node3D = null, is_remote: bool = false, is_replay: bool = false) -> void:
	# Deduplicate by event_id
	if not event_id.is_empty():
		if _handled_event_ids.has(event_id):
			return # Avoid repeating feedback for retransmitted acknowledgements
		_handled_event_ids[event_id] = true
		
	# Audio: play crisp click
	if audio_director:
		audio_director.play_click(event_id)
		
	# Haptics: only local live placements produce physical vibrations (PC-10)
	if not is_remote and not is_replay and haptics_adapter:
		haptics_adapter.vibrate_placement()
		
	# Visual settle animation: restrained 80-140ms drop onto studs (LB-041)
	if placed_node and not (settings_manager and settings_manager.reduced_motion):
		animate_settle(placed_node)

func notify_placement_rejected(_reason: String) -> void:
	if audio_director:
		audio_director.play_reject()
	if haptics_adapter:
		haptics_adapter.vibrate_error()

func notify_undo() -> void:
	if audio_director:
		audio_director.play_pickup()

func notify_redo() -> void:
	if audio_director:
		audio_director.play_rotate()

func notify_turn_changed(_player_name: String) -> void:
	if audio_director and audio_director.has_method("play_turn_cue"):
		audio_director.play_turn_cue()

func notify_build_finished() -> void:
	if audio_director:
		audio_director.play_chime()

func animate_settle(node: Node3D) -> void:
	if not node or not node.is_inside_tree():
		return
	# Move the whole rendered piece. Imported and authored bricks both have
	# multiple meshes, so moving one child would briefly pull the studs apart.
	var resting_position := node.position
	node.position = resting_position + Vector3(0, 0.15, 0)
	node.create_tween().tween_property(node, "position", resting_position, 0.12) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
