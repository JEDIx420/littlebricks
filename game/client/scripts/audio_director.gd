extends Node
class_name AudioDirector

## AudioDirector manages all background music, theme ambience, and interactive sound effects.
## Provides bus routing, deduplication, voice pooling, smooth crossfades, ducking,
## focus change handling, and web audio unlock handling (LB-039 / LB-040).

const SOUNDS = {
	"click": preload("res://assets/audio/click_place.wav"),
	"pickup": preload("res://assets/audio/pickup.wav"),
	"rotate": preload("res://assets/audio/rotate.wav"),
	"reject": preload("res://assets/audio/reject.wav"),
	"chime": preload("res://assets/audio/chime.wav"),
	"ambience_harbour": preload("res://assets/audio/ambience_harbour.wav"),
	"ambience_cabin": preload("res://assets/audio/ambience_cabin.wav"),
	"music_menu": preload("res://assets/audio/music_menu.wav"),
	"music_building": preload("res://assets/audio/music_building.wav")
}

var _music_player_a: AudioStreamPlayer
var _music_player_b: AudioStreamPlayer
var _ambience_player: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_pool_index: int = 0
const POOL_SIZE: int = 8

var _active_music_is_a: bool = true
var _current_music_track: String = ""
var _is_muted: bool = false
var _master_vol_linear: float = 1.0
var _music_vol_linear: float = 0.7
var _sfx_vol_linear: float = 0.9
var _ambience_vol_linear: float = 0.5
var _is_unlocked: bool = false
var _is_focused: bool = true

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
	
	_ambience_player = AudioStreamPlayer.new()
	_ambience_player.name = "AmbiencePlayer"
	_ambience_player.bus = "Ambience" if _bus_exists("Ambience") else "Master"
	add_child(_ambience_player)
	
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
		_update_volumes()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_is_focused = true
		_update_volumes()

## Browser Audio Unlock helper: called on user's first click or tap
func unlock_audio() -> void:
	if _is_unlocked:
		return
	_is_unlocked = true
	# In web builds, attempting playback on user gesture unlocks AudioContext
	if not _current_music_track.is_empty():
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
	var base_db = _calc_db(_music_vol_linear * _master_vol_linear)
	active_music.volume_db = base_db + amount_db
	var tw = create_tween()
	if tw:
		tw.tween_property(active_music, "volume_db", base_db, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func set_theme_ambience(theme_id: String) -> void:
	if not _ambience_player:
		_setup_audio_players()
	var track = "ambience_harbour" if theme_id == "harbour" else "ambience_cabin"
	if not SOUNDS.has(track):
		return
	if not is_inside_tree():
		return
	if _ambience_player.stream == SOUNDS[track] and _ambience_player.playing:
		return
	_ambience_player.stream = SOUNDS[track]
	_ambience_player.volume_db = _calc_db(_ambience_vol_linear * _master_vol_linear) if (_is_focused and not _is_muted) else -80.0
	_ambience_player.play()

func _play_sfx(sound_name: String, vol_offset_db: float = 0.0, pitch_var: float = 0.0) -> void:
	if _sfx_pool.is_empty():
		_setup_audio_players()
	if _is_muted or not SOUNDS.has(sound_name) or not is_inside_tree():
		return
	var player = _sfx_pool[_sfx_pool_index]
	_sfx_pool_index = (_sfx_pool_index + 1) % POOL_SIZE
	
	player.stream = SOUNDS[sound_name]
	player.volume_db = _calc_db(_sfx_vol_linear * _master_vol_linear) + vol_offset_db
	if pitch_var > 0.0:
		player.pitch_scale = randf_range(1.0 - pitch_var, 1.0 + pitch_var)
	else:
		player.pitch_scale = 1.0
	player.play()

func _play_music(track_name: String, force_restart: bool = false) -> void:
	if not _music_player_a or not _music_player_b:
		_setup_audio_players()
	if not SOUNDS.has(track_name):
		return
	if _current_music_track == track_name and not force_restart:
		return
	_current_music_track = track_name
	
	if not is_inside_tree():
		return
		
	var incoming = _music_player_b if _active_music_is_a else _music_player_a
	var outgoing = _music_player_a if _active_music_is_a else _music_player_b
	_active_music_is_a = not _active_music_is_a
	
	incoming.stream = SOUNDS[track_name]
	incoming.volume_db = _calc_db(_music_vol_linear * _master_vol_linear) if (_is_focused and not _is_muted) else -80.0
	incoming.play()
	
	if outgoing and outgoing.playing:
		var tw = create_tween()
		if tw:
			tw.tween_property(outgoing, "volume_db", -80.0, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_callback(outgoing.stop)
		else:
			outgoing.stop()

func set_mute(muted: bool) -> void:
	_is_muted = muted
	_update_volumes()
	_apply_bus_volumes()

func set_volumes(master: float, music: float, sfx: float, ambience: float) -> void:
	_master_vol_linear = clamp(master, 0.0, 1.0)
	_music_vol_linear = clamp(music, 0.0, 1.0)
	_sfx_vol_linear = clamp(sfx, 0.0, 1.0)
	_ambience_vol_linear = clamp(ambience, 0.0, 1.0)
	_update_volumes()
	_apply_bus_volumes()

func _calc_db(linear_val: float) -> float:
	if linear_val <= 0.001:
		return -80.0
	return linear_to_db(linear_val)

func _update_volumes() -> void:
	var active_music = _music_player_a if _active_music_is_a else _music_player_b
	if active_music and active_music.playing:
		active_music.volume_db = _calc_db(_music_vol_linear * _master_vol_linear) if (_is_focused and not _is_muted) else -80.0
	if _ambience_player and _ambience_player.playing:
		_ambience_player.volume_db = _calc_db(_ambience_vol_linear * _master_vol_linear) if (_is_focused and not _is_muted) else -80.0

func _apply_bus_volumes() -> void:
	var master_idx = AudioServer.get_bus_index("Master")
	if master_idx >= 0:
		AudioServer.set_bus_volume_db(master_idx, _calc_db(_master_vol_linear) if not _is_muted else -80.0)
		AudioServer.set_bus_mute(master_idx, _is_muted)
		
	var music_idx = AudioServer.get_bus_index("Music")
	if music_idx >= 0:
		AudioServer.set_bus_volume_db(music_idx, _calc_db(_music_vol_linear))
		
	var amb_idx = AudioServer.get_bus_index("Ambience")
	if amb_idx >= 0:
		AudioServer.set_bus_volume_db(amb_idx, _calc_db(_ambience_vol_linear))
		
	var bricks_idx = AudioServer.get_bus_index("Bricks")
	if bricks_idx >= 0:
		AudioServer.set_bus_volume_db(bricks_idx, _calc_db(_sfx_vol_linear))
