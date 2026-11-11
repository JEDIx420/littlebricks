extends Node
class_name AudioDirector

## AudioDirector manages all background music, theme ambience, and interactive sound effects.
## Provides bus routing, deduplication, voice pooling, single-gain mix path,
## seamless looping, smooth crossfades, ducking, focus change handling, and web audio unlock (LB-062).

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
var _current_ambience_track: String = ""
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
	_music_player_a.finished.connect(func(): _on_music_finished(_music_player_a))
	add_child(_music_player_a)
	
	_music_player_b = AudioStreamPlayer.new()
	_music_player_b.name = "MusicPlayerB"
	_music_player_b.bus = "Music" if _bus_exists("Music") else "Master"
	_music_player_b.finished.connect(func(): _on_music_finished(_music_player_b))
	add_child(_music_player_b)
	
	_ambience_player = AudioStreamPlayer.new()
	_ambience_player.name = "AmbiencePlayer"
	_ambience_player.bus = "Ambience" if _bus_exists("Ambience") else "Master"
	_ambience_player.finished.connect(_on_ambience_finished)
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
		_apply_bus_volumes()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_is_focused = true
		_apply_bus_volumes()

func _on_music_finished(player: AudioStreamPlayer) -> void:
	# Ensure seamless continuous looping across cue lengths
	var active_player = _music_player_a if _active_music_is_a else _music_player_b
	if player == active_player and not _current_music_track.is_empty():
		player.play()

func _on_ambience_finished() -> void:
	if _ambience_player and not _current_ambience_track.is_empty():
		_ambience_player.play()

## Browser Audio Unlock helper: called on user's first click or tap
func unlock_audio() -> void:
	if _is_unlocked:
		return
	_is_unlocked = true
	# In web builds, resume AudioContext / playback on user gesture
	if not _current_music_track.is_empty():
		var active_player = _music_player_a if _active_music_is_a else _music_player_b
		if active_player and not active_player.playing:
			active_player.play()
	if not _current_ambience_track.is_empty():
		if _ambience_player and not _ambience_player.playing:
			_ambience_player.play()

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
	active_music.volume_db = amount_db
	var tw = create_tween()
	if tw:
		tw.tween_property(active_music, "volume_db", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func set_theme_ambience(theme_id: String) -> void:
	if not _ambience_player:
		_setup_audio_players()
	var track = "ambience_harbour" if theme_id == "harbour" else "ambience_cabin"
	if not SOUNDS.has(track):
		return
	_current_ambience_track = track
	if not is_inside_tree():
		return
	var stream = SOUNDS[track]
	_configure_stream_loop(stream)
	if _ambience_player.stream == stream and _ambience_player.playing:
		return
	_ambience_player.stream = stream
	_ambience_player.volume_db = 0.0
	_ambience_player.play()

func stop_theme_ambience() -> void:
	_current_ambience_track = ""
	if _ambience_player and _ambience_player.playing:
		_ambience_player.stop()

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

func _configure_stream_loop(stream: AudioStream) -> void:
	if stream is AudioStreamWAV:
		var wav = stream as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		if wav.loop_end <= 0:
			wav.loop_end = int(wav.get_length() * float(wav.mix_rate))

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
	
	var stream = SOUNDS[track_name]
	_configure_stream_loop(stream)
	
	incoming.stream = stream
	incoming.volume_db = 0.0
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
	_apply_bus_volumes()

func set_volumes(master: float, music: float, sfx: float, ambience: float) -> void:
	_master_vol_linear = clamp(master, 0.0, 1.0)
	_music_vol_linear = clamp(music, 0.0, 1.0)
	_sfx_vol_linear = clamp(sfx, 0.0, 1.0)
	_ambience_vol_linear = clamp(ambience, 0.0, 1.0)
	_apply_bus_volumes()

func _calc_db(linear_val: float) -> float:
	if linear_val <= 0.001:
		return -80.0
	return linear_to_db(linear_val)

## Single-gain mix path: AudioServer buses own the gain calculations.
## AudioStreamPlayer nodes stay at 0.0 dB (plus temporary ducking), preventing square attenuation.
func _apply_bus_volumes() -> void:
	var master_mute = _is_muted or not _is_focused
	var master_idx = AudioServer.get_bus_index("Master")
	if master_idx >= 0:
		AudioServer.set_bus_volume_db(master_idx, _calc_db(_master_vol_linear) if not master_mute else -80.0)
		AudioServer.set_bus_mute(master_idx, master_mute)
		
	var music_idx = AudioServer.get_bus_index("Music")
	if music_idx >= 0:
		AudioServer.set_bus_volume_db(music_idx, _calc_db(_music_vol_linear))
		
	var amb_idx = AudioServer.get_bus_index("Ambience")
	if amb_idx >= 0:
		AudioServer.set_bus_volume_db(amb_idx, _calc_db(_ambience_vol_linear))
		
	var bricks_idx = AudioServer.get_bus_index("Bricks")
	if bricks_idx >= 0:
		AudioServer.set_bus_volume_db(bricks_idx, _calc_db(_sfx_vol_linear))
		
	var ui_idx = AudioServer.get_bus_index("UI")
	if ui_idx >= 0:
		AudioServer.set_bus_volume_db(ui_idx, _calc_db(_sfx_vol_linear))
