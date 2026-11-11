extends Node
class_name AudioDirector

## AudioDirector manages the original score and interactive brick sounds.
## Provides bus routing, deduplication, voice pooling, single-gain mix path,
## seamless looping, smooth crossfades, ducking, focus change handling, and web audio unlock (LB-062).

const SOUNDS = {
	"click": preload("res://assets/audio/click_place.wav"),
	"pickup": preload("res://assets/audio/pickup.wav"),
	"rotate": preload("res://assets/audio/rotate.wav"),
	"reject": preload("res://assets/audio/reject.wav"),
	"chime": preload("res://assets/audio/chime.wav"),
	"music_menu": preload("res://assets/audio/music_menu.ogg"),
	"music_building": preload("res://assets/audio/music_building.ogg")
}

var _music_player_a: AudioStreamPlayer
var _music_player_b: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_pool_index: int = 0
const POOL_SIZE: int = 8

var _active_music_is_a: bool = true
var _current_music_track: String = ""
var _is_muted: bool = false
var _master_vol_linear: float = 1.0
var _music_vol_linear: float = 0.7
var _sfx_vol_linear: float = 0.9
var _is_unlocked: bool = false
var _is_focused: bool = true
var _music_transition: Tween
var _music_duck: Tween

# Deduplication tracking for accepted events
var _handled_event_ids: Dictionary = {}

func _init() -> void:
	name = "AudioDirector"
	_setup_audio_players()

func _ready() -> void:
	_apply_bus_volumes()

func _setup_audio_players() -> void:
	if _music_player_a:
		return
		
	_music_player_a = AudioStreamPlayer.new()
	_music_player_a.name = "MusicPlayerA"
	_music_player_a.bus = "Music" if _bus_exists("Music") else "Master"
	add_child(_music_player_a)
	
	_music_player_b = AudioStreamPlayer.new()
	_music_player_b.name = "MusicPlayerB"
	_music_player_b.bus = "Music" if _bus_exists("Music") else "Master"
	add_child(_music_player_b)
	
	for i in range(POOL_SIZE):
		var p = AudioStreamPlayer.new()
		p.name = "SFX_%d" % i
		p.bus = "Bricks" if _bus_exists("Bricks") else "Master"
		add_child(p)
		_sfx_pool.append(p)

func _bus_exists(bus_name: String) -> bool:
	for i in range(AudioServer.get_bus_count()):
		if AudioServer.get_bus_name(i) == bus_name:
			return true
	return false

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_is_focused = false
		_apply_bus_volumes()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_is_focused = true
		_apply_bus_volumes()

## Browser audio starts during the first real input, including clicks on GUI buttons.
func unlock_audio() -> void:
	if _is_unlocked:
		return
	_is_unlocked = true
	if OS.has_feature("web") and not _current_music_track.is_empty():
		_play_music(_current_music_track, true)

func play_click(event_id: String = "") -> void:
	if not event_id.is_empty():
		if _handled_event_ids.has(event_id):
			return # Deduplicate event (PC-09 / LB-041)
		_handled_event_ids[event_id] = true
	_play_sfx("click", 0.0, 0.03)
	duck_music_for_placement()

func play_pickup() -> void:
	_play_sfx("pickup", -2.0, 0.04)

func play_rotate() -> void:
	_play_sfx("rotate", -1.0, 0.03)

func play_tick() -> void:
	_play_sfx("rotate", -6.0, 0.02)

func play_reject() -> void:
	_play_sfx("reject", 0.0, 0.0)

func play_chime() -> void:
	_play_sfx("chime", 1.0, 0.0)

func play_turn_cue() -> void:
	_play_sfx("chime", -3.0, 0.02)

func play_menu_music() -> void:
	_play_music("music_menu")

func play_building_music() -> void:
	_play_music("music_building")

## Subtle music ducking during rapid placement to maintain clarity and headroom
func duck_music_for_placement(amount_db: float = -2.5, duration: float = 0.35) -> void:
	var active_music = _music_player_a if _active_music_is_a else _music_player_b
	if not active_music or not active_music.playing or _is_muted or not is_inside_tree():
		return
	if _music_transition and _music_transition.is_running():
		return
	if _music_duck:
		_music_duck.kill()
	active_music.volume_db = amount_db
	_music_duck = create_tween()
	_music_duck.tween_property(active_music, "volume_db", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _play_sfx(sound_name: String, vol_offset_db: float = 0.0, pitch_var: float = 0.0) -> void:
	if _sfx_pool.is_empty():
		_setup_audio_players()
	if _is_muted or not SOUNDS.has(sound_name) or not is_inside_tree():
		return
	var player = _sfx_pool[_sfx_pool_index]
	_sfx_pool_index = (_sfx_pool_index + 1) % POOL_SIZE
	
	player.stream = SOUNDS[sound_name]
	player.volume_db = vol_offset_db
	if pitch_var > 0.0:
		player.pitch_scale = randf_range(1.0 - pitch_var, 1.0 + pitch_var)
	else:
		player.pitch_scale = 1.0
	player.play()

func _play_music(track_name: String, force_restart: bool = false) -> void:
	if not SOUNDS.has(track_name):
		return
	if _current_music_track == track_name and not force_restart:
		return
	_current_music_track = track_name
	if not is_inside_tree() or (OS.has_feature("web") and not _is_unlocked):
		return

	if _music_transition:
		_music_transition.kill()
	if _music_duck:
		_music_duck.kill()
	var incoming = _music_player_b if _active_music_is_a else _music_player_a
	var outgoing = _music_player_a if _active_music_is_a else _music_player_b
	_active_music_is_a = not _active_music_is_a

	var stream: AudioStreamOggVorbis = SOUNDS[track_name]
	stream.loop = true
	incoming.stop()
	incoming.stream = stream
	incoming.volume_db = -24.0
	incoming.play()

	_music_transition = create_tween().set_parallel(true)
	_music_transition.tween_property(incoming, "volume_db", 0.0, 0.8).set_trans(Tween.TRANS_SINE)
	if outgoing.playing:
		_music_transition.tween_property(outgoing, "volume_db", -35.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		_music_transition.chain().tween_callback(outgoing.stop)

func set_mute(muted: bool) -> void:
	_is_muted = muted
	_apply_bus_volumes()

func set_volumes(master: float, music: float, sfx: float) -> void:
	_master_vol_linear = clamp(master, 0.0, 1.0)
	_music_vol_linear = clamp(music, 0.0, 1.0)
	_sfx_vol_linear = clamp(sfx, 0.0, 1.0)
	_apply_bus_volumes()

func _calc_db(linear_val: float) -> float:
	if linear_val <= 0.001:
		return -80.0
	return linear_to_db(linear_val)

## Single-gain mix path: AudioServer buses own the gain calculations.
## AudioStreamPlayer gain handles crossfades, ducking, and per-cue trim.
func _apply_bus_volumes() -> void:
	var master_mute = _is_muted or not _is_focused
	var master_idx = AudioServer.get_bus_index("Master")
	if master_idx >= 0:
		AudioServer.set_bus_volume_db(master_idx, _calc_db(_master_vol_linear) if not master_mute else -80.0)
		AudioServer.set_bus_mute(master_idx, master_mute)
		
	var music_idx = AudioServer.get_bus_index("Music")
	if music_idx >= 0:
		AudioServer.set_bus_volume_db(music_idx, _calc_db(_music_vol_linear))
		
	var bricks_idx = AudioServer.get_bus_index("Bricks")
	if bricks_idx >= 0:
		AudioServer.set_bus_volume_db(bricks_idx, _calc_db(_sfx_vol_linear))
		
	var ui_idx = AudioServer.get_bus_index("UI")
	if ui_idx >= 0:
		AudioServer.set_bus_volume_db(ui_idx, _calc_db(_sfx_vol_linear))
