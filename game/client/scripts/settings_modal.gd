extends Control
class_name SettingsModal

## Settings and accessibility configuration modal (LB-040 / LB-043).
## Exposes independent audio volume sliders, mute, haptics, and reduced motion.

signal closed()

const BODY_FONT = preload("res://assets/ui/fonts/DM-Sans.ttf")
const TITLE_FONT = preload("res://assets/ui/fonts/DM-Serif-Text.ttf")

@onready var check_sound: CheckBox = %CheckSound
@onready var slider_master: HSlider = %SliderMaster
@onready var slider_music: HSlider = %SliderMusic
@onready var slider_sfx: HSlider = %SliderSFX
@onready var check_haptics: CheckBox = %CheckHaptics
@onready var check_reduced_motion: CheckBox = %CheckReducedMotion
@onready var check_high_contrast: CheckBox = %CheckHighContrast
@onready var label_build_info: Label = %LabelBuildInfo
@onready var btn_close: Button = %BtnClose

var settings_manager: SettingsManager
var audio_director: AudioDirector
var haptics_adapter: HapticsAdapter

var _previous_focus: Control
var _open_transition: Tween

func setup(p_settings: SettingsManager, p_audio: AudioDirector, p_haptics: HapticsAdapter) -> void:
	settings_manager = p_settings
	audio_director = p_audio
	haptics_adapter = p_haptics
	_sync_ui_to_settings()

func _ready() -> void:
	_apply_theme()
	resized.connect(_update_panel_size)
	get_viewport().size_changed.connect(_update_panel_size)
	_update_panel_size()
	visibility_changed.connect(_on_visibility_changed)

	var focus_order: Array[Control] = [
		btn_close, check_sound, slider_master, slider_music, slider_sfx,
		check_haptics, check_reduced_motion, check_high_contrast,
	]
	for index in focus_order.size():
		var control := focus_order[index]
		control.focus_next = control.get_path_to(focus_order[(index + 1) % focus_order.size()])
		control.focus_previous = control.get_path_to(focus_order[posmod(index - 1, focus_order.size())])
		control.focus_neighbor_top = control.focus_previous
		control.focus_neighbor_bottom = control.focus_next
		if not control is HSlider:
			control.focus_neighbor_left = control.focus_previous
			control.focus_neighbor_right = control.focus_next

	btn_close.pressed.connect(_on_close_pressed)
	check_sound.toggled.connect(_on_sound_toggled)
	for slider in [slider_master, slider_music, slider_sfx]:
		slider.value_changed.connect(_on_volumes_changed)
	check_haptics.toggled.connect(_on_haptics_toggled)
	check_reduced_motion.toggled.connect(_on_reduced_motion_toggled)
	check_high_contrast.toggled.connect(_on_high_contrast_toggled)

func _apply_theme() -> void:
	var palette := Theme.new()
	palette.default_font = _scalable_font(BODY_FONT)
	palette.default_font_size = 16
	palette.set_color("font_color", "Label", WorkbenchHUD.INK)

	var card := WorkbenchHUD.surface(Color("#15352b"), Color("#c2a263"), 16, 0)
	card.shadow_color = Color(0.03, 0.05, 0.04, 0.55)
	card.shadow_size = 15
	card.shadow_offset = Vector2(0, 7)
	palette.set_stylebox("panel", "PanelContainer", card)

	var focus := WorkbenchHUD.surface(Color.TRANSPARENT, WorkbenchHUD.ACTIVE, 8, 0)
	focus.set_border_width_all(2)
	palette.set_stylebox("focus", "Button", focus)
	palette.set_stylebox("focus", "CheckBox", focus)
	for state in ["font_color", "font_pressed_color", "font_hover_color", "font_hover_pressed_color", "font_focus_color"]:
		palette.set_color(state, "CheckBox", WorkbenchHUD.INK)
	palette.set_stylebox("normal", "CheckBox", WorkbenchHUD.surface(Color("#1f4437"), Color("#1f4437"), 8, 9))
	palette.set_stylebox("pressed", "CheckBox", WorkbenchHUD.surface(Color("#1f4437"), Color("#1f4437"), 8, 9))
	var toggle_hover := WorkbenchHUD.surface(Color("#305747"), Color("#9a9866"), 8, 9)
	palette.set_stylebox("hover", "CheckBox", toggle_hover)
	palette.set_stylebox("hover_pressed", "CheckBox", toggle_hover)
	palette.set_constant("h_separation", "CheckBox", 10)
	palette.set_icon("checked", "CheckBox", _checkbox_icon(true))
	palette.set_icon("unchecked", "CheckBox", _checkbox_icon(false))

	var rail := _rail(Color("#576b60"), Color("#9aab9c"))
	var filled := _rail(WorkbenchHUD.ACTIVE, WorkbenchHUD.ACTIVE)
	palette.set_stylebox("slider", "HSlider", rail)
	palette.set_stylebox("grabber_area", "HSlider", filled)
	palette.set_stylebox("grabber_area_highlight", "HSlider", filled)
	palette.set_icon("grabber", "HSlider", _thumb_icon(false))
	palette.set_icon("grabber_highlight", "HSlider", _thumb_icon(true))

	var divider := StyleBoxLine.new()
	divider.color = Color("#737950")
	palette.set_stylebox("separator", "HSeparator", divider)
	theme = palette
	%Title.add_theme_font_override("font", _scalable_font(TITLE_FONT))
	WorkbenchHUD.select(btn_close, true)
	btn_close.add_theme_stylebox_override("pressed", WorkbenchHUD.surface(Color("#bf9a58"), Color("#bf9a58")))
	btn_close.add_theme_stylebox_override("focus", focus)
	btn_close.add_theme_color_override("font_pressed_color", WorkbenchHUD.DARK)
	btn_close.add_theme_color_override("font_focus_color", WorkbenchHUD.DARK)
	for slider in [slider_master, slider_music, slider_sfx]:
		slider.focus_entered.connect(slider.queue_redraw)
		slider.focus_exited.connect(slider.queue_redraw)
		slider.draw.connect(func():
			if slider.has_focus():
				slider.draw_style_box(focus, Rect2(Vector2.ONE, slider.size - Vector2(2, 2)))
		)

func _scalable_font(source: FontFile) -> FontFile:
	# Keep glyphs crisp when the modal counteracts the workshop canvas scale.
	var font := source.duplicate() as FontFile
	font.multichannel_signed_distance_field = true
	return font

func _rail(fill: Color, border: Color) -> StyleBoxFlat:
	var rail := WorkbenchHUD.surface(fill, border, 4, 0)
	rail.content_margin_top = 4
	rail.content_margin_bottom = 4
	return rail

func _checkbox_icon(checked: bool) -> ImageTexture:
	var image := Image.create(22, 22, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	image.fill_rect(Rect2i(1, 1, 20, 20), WorkbenchHUD.ACTIVE if checked else Color("#a9b9a8"))
	if checked:
		for i in range(5):
			image.fill_rect(Rect2i(4 + i, 10 + i, 3, 3), WorkbenchHUD.DARK)
		for i in range(8):
			image.fill_rect(Rect2i(9 + i, 13 - i, 3, 3), WorkbenchHUD.DARK)
	else:
		image.fill_rect(Rect2i(3, 3, 16, 16), Color("#1f4437"))
	return ImageTexture.create_from_image(image)

func _thumb_icon(highlighted: bool) -> ImageTexture:
	var image := Image.create(22, 22, false, Image.FORMAT_RGBA8)
	var outer := WorkbenchHUD.ACTIVE if highlighted else Color("#171d1b")
	for y in 22:
		for x in 22:
			var distance := Vector2(x, y).distance_to(Vector2(10.5, 10.5))
			if distance <= 10.0:
				image.set_pixel(x, y, WorkbenchHUD.INK if distance <= 7.5 else outer)
	return ImageTexture.create_from_image(image)

func _update_panel_size() -> void:
	var panel: PanelContainer = %Panel
	# The workshop's wide base viewport can shrink text on a narrow screen.
	# Keep the settings controls at their design size in screen pixels.
	var canvas_scale := get_viewport().get_final_transform().get_scale().x
	var ui_scale := maxf(1.0, 1.0 / maxf(canvas_scale, 0.01))
	var available := size / ui_scale - Vector2(20.0, 24.0)
	panel.custom_minimum_size = available.min(Vector2(500.0, 536.0)).max(Vector2.ZERO)
	panel.size = panel.custom_minimum_size
	panel.scale = Vector2.ONE * ui_scale
	_center_panel()

func _center_panel() -> void:
	var panel: PanelContainer = %Panel
	panel.position = (size - panel.size) * 0.5
	panel.pivot_offset = panel.size * 0.5

func _on_visibility_changed() -> void:
	var panel: Control = %Panel
	if _open_transition:
		_open_transition.kill()
	panel.modulate.a = 1.0
	if visible:
		_previous_focus = get_viewport().gui_get_focus_owner()
		var scroll := find_child("Scroll") as ScrollContainer
		if (%Panel as Control).size.y < 500.0:
			btn_close.grab_focus()
			scroll.set_deferred("scroll_vertical", 0)
		else:
			slider_master.grab_focus()
		if not get_tree().get_meta("littlebricks_reduced_motion", false):
			panel.modulate.a = 0.50
			_open_transition = create_tween()
			_open_transition.tween_property(panel, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	elif is_instance_valid(_previous_focus) and _previous_focus.is_visible_in_tree():
		_previous_focus.grab_focus()

func _input(event: InputEvent) -> void:
	if is_visible_in_tree() and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_close_pressed()

func _sync_ui_to_settings() -> void:
	check_sound.set_pressed_no_signal(settings_manager.sound_enabled)
	slider_master.set_value_no_signal(settings_manager.master_volume * 100.0)
	slider_music.set_value_no_signal(settings_manager.music_volume * 100.0)
	slider_sfx.set_value_no_signal(settings_manager.sfx_volume * 100.0)
	check_haptics.set_pressed_no_signal(settings_manager.haptics_enabled)
	check_reduced_motion.set_pressed_no_signal(settings_manager.reduced_motion)
	check_high_contrast.set_pressed_no_signal(settings_manager.high_contrast_cues)
	label_build_info.text = BuildInfo.get_build_summary()
	_update_volume_labels()

func _update_volume_labels() -> void:
	%ValueMaster.text = "%d%%" % roundi(slider_master.value)
	%ValueMusic.text = "%d%%" % roundi(slider_music.value)
	%ValueSFX.text = "%d%%" % roundi(slider_sfx.value)

func _on_sound_toggled(pressed: bool) -> void:
	if settings_manager:
		settings_manager.sound_enabled = pressed
		settings_manager.save_settings()
	if audio_director:
		audio_director.set_mute(not pressed)

func _on_volumes_changed(_value: float) -> void:
	_update_volume_labels()
	if not settings_manager:
		return
	var master := slider_master.value / 100.0
	var music := slider_music.value / 100.0
	var brick_sounds := slider_sfx.value / 100.0
	settings_manager.master_volume = master
	settings_manager.music_volume = music
	settings_manager.sfx_volume = brick_sounds
	settings_manager.save_settings()
	if audio_director:
		audio_director.set_volumes(master, music, brick_sounds)

func _on_haptics_toggled(pressed: bool) -> void:
	if settings_manager:
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
	hide()
	closed.emit()
