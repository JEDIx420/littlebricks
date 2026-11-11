extends RefCounted
class_name SettingsManager

## Persistent configuration manager for LittleBricks accessibility, audio, and gameplay preferences (LB-026).

const SETTINGS_FILE: String = "user://settings.json"

signal settings_changed()

var sound_enabled: bool = true
var master_volume: float = 0.8
var music_volume: float = 0.7
var sfx_volume: float = 0.9
var ambience_volume: float = 0.5
var haptics_enabled: bool = true
var timer_default_enabled: bool = false
var timer_duration_sec: float = 20.0
var reduced_motion: bool = false
var high_contrast_cues: bool = true
var preferred_theme: String = "harbour"

func _init() -> void:
	load_settings()

func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_FILE):
		return
		
	var f = FileAccess.open(SETTINGS_FILE, FileAccess.READ)
	if not f:
		return
	var text = f.get_as_text()
	f.close()
	
	var json = JSON.new()
	if json.parse(text) == OK and json.data is Dictionary:
		var d = json.data
		sound_enabled = d.get("sound_enabled", true)
		master_volume = d.get("master_volume", 0.8)
		music_volume = d.get("music_volume", 0.7)
		sfx_volume = d.get("sfx_volume", 0.9)
		ambience_volume = d.get("ambience_volume", 0.5)
		haptics_enabled = d.get("haptics_enabled", true)
		timer_default_enabled = d.get("timer_default_enabled", false)
		timer_duration_sec = d.get("timer_duration_sec", 20.0)
		reduced_motion = d.get("reduced_motion", false)
		high_contrast_cues = d.get("high_contrast_cues", true)
		preferred_theme = d.get("preferred_theme", "harbour")

func save_settings() -> bool:
	var d = {
		"sound_enabled": sound_enabled,
		"master_volume": master_volume,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"ambience_volume": ambience_volume,
		"haptics_enabled": haptics_enabled,
		"timer_default_enabled": timer_default_enabled,
		"timer_duration_sec": timer_duration_sec,
		"reduced_motion": reduced_motion,
		"high_contrast_cues": high_contrast_cues,
		"preferred_theme": preferred_theme
	}
	var f = FileAccess.open(SETTINGS_FILE, FileAccess.WRITE)
	if not f:
		return false
	f.store_string(JSON.stringify(d, "  "))
	f.close()
	settings_changed.emit()
	return true
