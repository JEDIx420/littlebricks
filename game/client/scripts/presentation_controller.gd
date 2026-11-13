extends Node
class_name PresentationController

## Controls table, exploration, and finished-build presentation (LB-042).
## Manages warm Compatibility lighting presets, soft table shadows,
## finished-build showcase framing, and reduced-motion paths.

const THEMES = {
	"harbour": {
		"name": "Cozy Coastal Harbour",
		"sun_color": Color(1.0, 0.96, 0.90),
		"sun_energy": 0.68,
		"ambient_color": Color("#f7efe3"),
		"table_color": Color("#9e6842"),
		"plate_color": Color("#668475"),
		"wall_color": Color("#deccb7"),
		"panel_color": Color("#6d9084"),
		"rug_color": Color("#b46b57"),
	},
	"cabin": {
		"name": "Alpine Pine Cabin",
		"sun_color": Color(1.0, 0.88, 0.72),
		"sun_energy": 0.63,
		"ambient_color": Color("#f0e1d0"),
		"table_color": Color("#8b5e42"),
		"plate_color": Color("#738674"),
		"wall_color": Color("#d4ba9d"),
		"panel_color": Color("#748173"),
		"rug_color": Color("#966556"),
	},
	"studio": {
		"name": "Clean Creator Studio",
		"sun_color": Color("#fff3e6"),
		"sun_energy": 0.73,
		"ambient_color": Color("#f3eee9"),
		"table_color": Color("#b48764"),
		"plate_color": Color("#70838b"),
		"wall_color": Color("#e2d8cb"),
		"panel_color": Color("#7c8896"),
		"rug_color": Color("#819185"),
	}
}

signal atmosphere_changed(mode: String, label: String)

const MODES := ["cycle", "day", "dusk", "night", "rain"]
const CYCLE_SECONDS := 210.0
const MORPH_SECONDS := 5.5
const PRESETS := {
	"day": Vector3(1.0, 0.0, 0.0),
	"dusk": Vector3(0.51, 0.95, 0.0),
	"night": Vector3(0.08, 0.0, 0.0),
	"rain": Vector3(0.79, 0.09, 1.0),
}
# Phase, daylight, sunset warmth, rain. Smooth interpolation keeps the
# workshop clock independent from turn timing and gameplay simulation.
const CYCLE := [
	Vector4(0.00, 1.00, 0.00, 0.00),
	Vector4(0.23, 1.00, 0.00, 0.00),
	Vector4(0.36, 0.49, 1.00, 0.00),
	Vector4(0.51, 0.08, 0.00, 0.00),
	Vector4(0.65, 0.08, 0.00, 0.00),
	Vector4(0.76, 0.45, 0.53, 0.78),
	Vector4(0.87, 0.89, 0.15, 1.00),
	Vector4(0.97, 1.00, 0.00, 0.00),
	Vector4(1.00, 1.00, 0.00, 0.00),
]

var current_theme_id: String = "harbour"
var current_quality: String = "balanced"
var is_reduced_motion: bool = false

var _mode := "cycle"
var _phase := 0.12
var _rain_time := 0.0
var _applied_reduced_motion := false
var _blend := Vector3(1.0, 0.0, 0.0)
var _transition_start := Vector3(1.0, 0.0, 0.0)
var _transition_time := MORPH_SECONDS
var _last_status := ""
var _sun: DirectionalLight3D
var _world_env: WorldEnvironment
var _bounce: OmniLight3D
var _window_fill: DirectionalLight3D
var _table_view: Node
var _light_scale := 1.0
var _base_bounce := 0.42
var _base_fill := 0.23
var _base_shadow_opacity := 0.72

func apply_presentation(theme_id: String, world_env: WorldEnvironment, sun: DirectionalLight3D, table_view = null, light_scale: float = 1.0) -> void:
	current_theme_id = theme_id if THEMES.has(theme_id) else "harbour"
	var theme: Dictionary = THEMES[current_theme_id]
	_light_scale = light_scale
	if _sun != sun:
		_sun = sun
		if _sun:
			_base_shadow_opacity = _sun.shadow_opacity
	if _world_env != world_env and world_env and world_env.environment:
		world_env.environment = world_env.environment.duplicate()
		var room := world_env.get_parent()
		if room:
			_bounce = room.get_node_or_null("BounceLight") as OmniLight3D
			_window_fill = room.get_node_or_null("WindowBounce") as DirectionalLight3D
			if _bounce:
				_base_bounce = _bounce.light_energy
			if _window_fill:
				_base_fill = _window_fill.light_energy
	_world_env = world_env
	_table_view = table_view
	if _table_view and _table_view.has_method("set_palette"):
		_table_view.set_palette(theme["table_color"], theme["plate_color"])
	if _table_view and _table_view.has_method("set_room_palette"):
		_table_view.set_room_palette(theme["wall_color"], theme["panel_color"], theme["rug_color"])
	_apply_light_and_weather()

func apply_quality(profile: String, sun: DirectionalLight3D) -> void:
	current_quality = profile
	if sun:
		_apply_sun_shadow(sun, _blend.x, _blend.z)

func set_atmosphere_mode(mode: String) -> void:
	if not mode in MODES or _mode == mode:
		return
	_mode = mode
	_transition_start = _blend
	_transition_time = 0.0
	if is_reduced_motion:
		_blend = _sample()
		_transition_time = MORPH_SECONDS
		_apply_light_and_weather()
	_publish_atmosphere()

func get_atmosphere_mode() -> String:
	return _mode

func get_atmosphere_label() -> String:
	if _blend.z >= 0.44:
		return "Rain"
	if _blend.x < 0.22:
		return "Night"
	if _blend.x < 0.78:
		return "Dawn" if _mode == "cycle" and _phase > 0.55 else "Dusk"
	return "Day"

func get_atmosphere_state() -> Dictionary:
	var state := {
		"mode": _mode,
		"phase": _phase,
		"is_raining": _blend.z >= 0.44,
		"is_night": _blend.x < 0.22,
		"rain_time": _rain_time,
	}
	if _transition_time < MORPH_SECONDS:
		state["transition_from"] = [_transition_start.x, _transition_start.y, _transition_start.z]
		state["transition_elapsed"] = _transition_time
	return state

func restore_atmosphere_state(state: Dictionary) -> void:
	var mode: String = state.get("mode", "cycle")
	_mode = mode if mode in MODES else "cycle"
	_phase = fposmod(float(state.get("phase", _phase)), 1.0)
	_rain_time = maxf(0.0, float(state.get("rain_time", _rain_time)))
	_blend = _sample()
	_transition_time = MORPH_SECONDS
	var transition_from = state.get("transition_from")
	var elapsed = state.get("transition_elapsed", MORPH_SECONDS)
	if not is_reduced_motion and transition_from is Array and transition_from.size() == 3 \
			and transition_from.all(_is_finite_number) and _is_finite_number(elapsed):
		_transition_start = Vector3(
			clampf(float(transition_from[0]), 0.0, 1.0),
			clampf(float(transition_from[1]), 0.0, 1.0),
			clampf(float(transition_from[2]), 0.0, 1.0)
		)
		_transition_time = clampf(float(elapsed), 0.0, MORPH_SECONDS)
		_blend = _transition_blend(_blend)
	_apply_light_and_weather()
	_publish_atmosphere()

func _is_finite_number(value: Variant) -> bool:
	return (value is float or value is int) and is_finite(float(value))

func _process(delta: float) -> void:
	if not _table_view or not _table_view.is_node_ready():
		return
	if is_reduced_motion != _applied_reduced_motion and _table_view.has_method("set_reduced_motion"):
		_table_view.set_reduced_motion(is_reduced_motion)
		_applied_reduced_motion = is_reduced_motion
	if _mode == "cycle" and not is_reduced_motion:
		_phase = fposmod(_phase + delta / CYCLE_SECONDS, 1.0)
	var next := _sample()
	if _transition_time < MORPH_SECONDS:
		_transition_time = MORPH_SECONDS if is_reduced_motion else minf(_transition_time + delta, MORPH_SECONDS)
		next = _transition_blend(next)
	var animated_rain := next.z > 0.01 and not is_reduced_motion
	if animated_rain:
		_rain_time += delta
	if not _blend.is_equal_approx(next):
		_blend = next
		_apply_light_and_weather()
	elif animated_rain and _table_view.has_method("set_rain_time"):
		_table_view.set_rain_time(_rain_time)
	_publish_atmosphere()

func _transition_blend(target: Vector3) -> Vector3:
	var t := _transition_time / MORPH_SECONDS
	var progress := t * t * t * (t * (t * 6.0 - 15.0) + 10.0)
	var blended := _transition_start.lerp(target, progress)
	# A daylight preset crossing still travels through twilight.
	var sunlight_change := smoothstep(0.40, 0.85, absf(target.x - _transition_start.x))
	var twilight := 4.0 * progress * (1.0 - progress) * sunlight_change * (1.0 - blended.z)
	blended.y = lerpf(blended.y, 0.82, twilight)
	return blended

func _sample() -> Vector3:
	if _mode != "cycle":
		return PRESETS[_mode]
	for i in range(1, CYCLE.size()):
		var next: Vector4 = CYCLE[i]
		if _phase <= next.x:
			var before: Vector4 = CYCLE[i - 1]
			var factor := smoothstep(before.x, next.x, _phase)
			return Vector3(before.y, before.z, before.w).lerp(Vector3(next.y, next.z, next.w), factor)
	return Vector3(1.0, 0.0, 0.0)

func _apply_light_and_weather() -> void:
	var theme: Dictionary = THEMES[current_theme_id]
	var daylight := _blend.x
	var sunset := _blend.y
	var rain := _blend.z
	if _sun:
		var sun_color: Color = theme["sun_color"]
		_sun.light_color = sun_color.lerp(Color("#ffd097"), sunset * 0.8).lerp(Color("#b7cef8"), (1.0 - daylight) * 0.66)
		# Lose the directional contribution before turning off its shadow map.
		# This also keeps the handoff smooth on Compatibility renderers.
		var daylight_above_horizon := maxf(0.0, inverse_lerp(0.22, 1.0, daylight))
		var direct_light := pow(daylight_above_horizon, 1.17)
		direct_light *= 1.0 - smoothstep(0.08, 0.84, rain)
		_sun.light_energy = float(theme["sun_energy"]) * direct_light * _light_scale
		_sun.rotation_degrees = Vector3(lerpf(-12.0, -27.0, daylight), 211.0 - sunset * 4.0, 0.0)
		_apply_sun_shadow(_sun, daylight, rain)
		_sun.shadow_bias = 0.04
	if _world_env and _world_env.environment:
		var env := _world_env.environment
		var ambient_color: Color = theme["ambient_color"]
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = ambient_color.lerp(Color("#acbff0"), (1.0 - daylight) * 0.72 + rain * 0.17)
		env.ambient_light_energy = lerpf(0.33, 0.61, daylight) * lerpf(1.0, 0.94, rain) * _light_scale
		env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	if _bounce:
		_bounce.light_energy = _base_bounce * lerpf(0.83, 1.0, daylight) * _light_scale
		_bounce.light_color = Color("#ffead4").lerp(Color("#ffc689"), (1.0 - daylight) * 0.76)
	if _window_fill:
		_window_fill.light_energy = _base_fill * lerpf(0.45, 1.0, daylight) * _light_scale
	if _table_view and _table_view.has_method("apply_atmosphere"):
		_table_view.apply_atmosphere(daylight, sunset, rain, _rain_time)

func _apply_sun_shadow(sun: DirectionalLight3D, daylight: float, rain: float) -> void:
	var shadow_weight := smoothstep(0.16, 0.82, daylight) * (1.0 - smoothstep(0.08, 0.90, rain))
	sun.shadow_opacity = _base_shadow_opacity * shadow_weight
	var enabled := current_quality != "economy" and shadow_weight > 0.0
	if sun.shadow_enabled != enabled:
		sun.shadow_enabled = enabled

func _publish_atmosphere() -> void:
	var label := get_atmosphere_label()
	var status := "%s|%s|%s|%s" % [_mode, label, _blend.x < 0.22, _blend.z >= 0.44]
	if status == _last_status:
		return
	_last_status = status
	atmosphere_changed.emit(_mode, label)

## Frame the completed creation nicely for showcase/reveal
func frame_creation(pieces_container: Node3D, camera_rig: Node3D) -> AABB:
	var bounds = AABB()
	var has_points = false
	
	if pieces_container:
		for child in pieces_container.get_children():
			if child is Node3D:
				var pos = child.global_position if child.is_inside_tree() else child.position
				if not has_points:
					bounds = AABB(pos, Vector3(0.2, 0.2, 0.2))
					has_points = true
				else:
					bounds = bounds.expand(pos)
					
	if not has_points:
		bounds = AABB(Vector3(-5, 0, -5), Vector3(10, 5, 10))
	else:
		bounds = bounds.grow(0.5)
		
	if camera_rig:
		var center = bounds.get_center()
		camera_rig.position = center
		if camera_rig.has_method("set_target_distance"):
			var max_dim = max(bounds.size.x, bounds.size.z, bounds.size.y)
			camera_rig.set_target_distance(max(15.0, max_dim * 2.2))
			
	return bounds
