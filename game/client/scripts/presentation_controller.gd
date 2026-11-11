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
	},
	"cabin": {
		"name": "Alpine Pine Cabin",
		"sun_color": Color(1.0, 0.88, 0.72),
		"sun_energy": 0.63,
		"ambient_color": Color("#f0e1d0"),
		"table_color": Color("#8b5e42"),
		"plate_color": Color("#738674"),
	},
	"studio": {
		"name": "Clean Creator Studio",
		"sun_color": Color("#fff3e6"),
		"sun_energy": 0.73,
		"ambient_color": Color("#f3eee9"),
		"table_color": Color("#b48764"),
		"plate_color": Color("#70838b"),
	}
}

var current_theme_id: String = "harbour"
var current_quality: String = "balanced" # "economy", "balanced", "showcase"
var is_reduced_motion: bool = false

func apply_presentation(theme_id: String, world_env: WorldEnvironment, sun: DirectionalLight3D, table_view = null) -> void:
	current_theme_id = theme_id if THEMES.has(theme_id) else "harbour"
	var t_data = THEMES[current_theme_id]
	
	if sun:
		sun.light_color = t_data["sun_color"]
		sun.light_energy = t_data["sun_energy"]
		sun.rotation_degrees = Vector3(-27.0, 211.0, 0.0)
		sun.shadow_enabled = (current_quality != "economy")
		sun.shadow_bias = 0.04
		
	if world_env and world_env.environment:
		var env = world_env.environment
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = t_data["ambient_color"]
		env.ambient_light_energy = 0.61
		env.tonemap_mode = Environment.TONE_MAPPER_LINEAR

	if table_view and table_view.has_method("set_palette"):
		table_view.set_palette(t_data["table_color"], t_data["plate_color"])

func apply_quality(profile: String, sun: DirectionalLight3D) -> void:
	current_quality = profile
	if sun:
		sun.shadow_enabled = (profile != "economy")

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
