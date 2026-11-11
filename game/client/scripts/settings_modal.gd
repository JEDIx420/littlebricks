extends Control
class_name SettingsModal

## Settings and accessibility configuration modal (LB-040 / LB-043).
## Exposes independent audio volume sliders, mute, haptics, and reduced motion.

signal closed()

@onready var check_sound: CheckBox = %CheckSound
@onready var slider_master: HSlider = %SliderMaster
@onready var slider_music: HSlider = %SliderMusic
@onready var slider_sfx: HSlider = %SliderSFX
@onready var slider_ambience: HSlider = %SliderAmbience
@onready var check_haptics: CheckBox = %CheckHaptics
@onready var check_reduced_motion: CheckBox = %CheckReducedMotion
@onready var check_high_contrast: CheckBox = %CheckHighContrast
@onready var label_build_info: Label = %LabelBuildInfo
@onready var btn_close: Button = %BtnClose

var settings_manager: SettingsManager
var audio_director: AudioDirector
var haptics_adapter: HapticsAdapter

func _ensure_nodes() -> void:
	if not check_sound: check_sound = find_child("CheckSound", true, false)
	if not slider_master: slider_master = find_child("SliderMaster", true, false)
	if not slider_music: slider_music = find_child("SliderMusic", true, false)
	if not slider_sfx: slider_sfx = find_child("SliderSFX", true, false)
	if not slider_ambience: slider_ambience = find_child("SliderAmbience", true, false)
	if not check_haptics: check_haptics = find_child("CheckHaptics", true, false)
	if not check_reduced_motion: check_reduced_motion = find_child("CheckReducedMotion", true, false)
	if not check_high_contrast: check_high_contrast = find_child("CheckHighContrast", true, false)
	if not label_build_info: label_build_info = find_child("LabelBuildInfo", true, false)
	if not btn_close: btn_close = find_child("BtnClose", true, false)

func setup(p_settings: SettingsManager, p_audio: AudioDirector, p_haptics: HapticsAdapter) -> void:
	settings_manager = p_settings
	audio_director = p_audio
	haptics_adapter = p_haptics
	_ensure_nodes()
	_sync_ui_to_settings()

func _ready() -> void:
	_ensure_nodes()
	
	var panel = find_child("Panel", true, false) as PanelContainer
	if panel:
		UIThemeHelper.apply_card(panel)
	if btn_close:
		UIThemeHelper.apply_secondary_button(btn_close)
		
	if btn_close and not btn_close.pressed.is_connected(_on_close_pressed):
		btn_close.pressed.connect(_on_close_pressed)
	if check_sound and not check_sound.toggled.is_connected(_on_sound_toggled):
		check_sound.toggled.connect(_on_sound_toggled)
	if slider_master and not slider_master.value_changed.is_connected(_on_volumes_changed):
		slider_master.value_changed.connect(_on_volumes_changed)
	if slider_music and not slider_music.value_changed.is_connected(_on_volumes_changed):
		slider_music.value_changed.connect(_on_volumes_changed)
	if slider_sfx and not slider_sfx.value_changed.is_connected(_on_volumes_changed):
		slider_sfx.value_changed.connect(_on_volumes_changed)
	if slider_ambience and not slider_ambience.value_changed.is_connected(_on_volumes_changed):
		slider_ambience.value_changed.connect(_on_volumes_changed)
	if check_haptics and not check_haptics.toggled.is_connected(_on_haptics_toggled):
		check_haptics.toggled.connect(_on_haptics_toggled)
	if check_reduced_motion and not check_reduced_motion.toggled.is_connected(_on_reduced_motion_toggled):
		check_reduced_motion.toggled.connect(_on_reduced_motion_toggled)
	if check_high_contrast and not check_high_contrast.toggled.is_connected(_on_high_contrast_toggled):
		check_high_contrast.toggled.connect(_on_high_contrast_toggled)

func _sync_ui_to_settings() -> void:
	if not settings_manager:
		return
	if check_sound: check_sound.button_pressed = settings_manager.sound_enabled
	if slider_master: slider_master.value = settings_manager.master_volume * 100.0
	if slider_music: slider_music.value = settings_manager.music_volume * 100.0 if "music_volume" in settings_manager else 70.0
	if slider_sfx: slider_sfx.value = settings_manager.sfx_volume * 100.0 if "sfx_volume" in settings_manager else 90.0
	if slider_ambience: slider_ambience.value = settings_manager.ambience_volume * 100.0 if "ambience_volume" in settings_manager else 50.0
	if check_haptics: check_haptics.button_pressed = settings_manager.haptics_enabled if "haptics_enabled" in settings_manager else true
	if check_reduced_motion: check_reduced_motion.button_pressed = settings_manager.reduced_motion
	if check_high_contrast: check_high_contrast.button_pressed = settings_manager.high_contrast_cues
	if label_build_info: label_build_info.text = BuildInfo.get_build_summary()

func _on_sound_toggled(pressed: bool) -> void:
	if settings_manager:
		settings_manager.sound_enabled = pressed
		settings_manager.save_settings()
	if audio_director:
		audio_director.set_mute(not pressed)

func _on_volumes_changed(_val: float) -> void:
	if not settings_manager:
		return
	var m = slider_master.value / 100.0 if slider_master else 1.0
	var mu = slider_music.value / 100.0 if slider_music else 0.7
	var sf = slider_sfx.value / 100.0 if slider_sfx else 0.9
	var amb = slider_ambience.value / 100.0 if slider_ambience else 0.5
	
	settings_manager.master_volume = m
	if "music_volume" in settings_manager: settings_manager.music_volume = mu
	if "sfx_volume" in settings_manager: settings_manager.sfx_volume = sf
	if "ambience_volume" in settings_manager: settings_manager.ambience_volume = amb
	settings_manager.save_settings()
	
	if audio_director:
		audio_director.set_volumes(m, mu, sf, amb)

func _on_haptics_toggled(pressed: bool) -> void:
	if settings_manager and "haptics_enabled" in settings_manager:
		settings_manager.haptics_enabled = pressed
		settings_manager.save_settings()
	if haptics_adapter:
		haptics_adapter.is_enabled = pressed

func _on_reduced_motion_toggled(pressed: bool) -> void:
	if settings_manager:
		settings_manager.reduced_motion = pressed
		settings_manager.save_settings()

func _on_high_contrast_toggled(pressed: bool) -> void:
	if settings_manager:
		settings_manager.high_contrast_cues = pressed
		settings_manager.save_settings()

func _on_close_pressed() -> void:
	visible = false
	closed.emit()
