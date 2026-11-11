extends Node
class_name PresentationController

## Controls table, exploration, and finished-build presentation (LB-042).
## Manages warm Compatibility lighting presets, soft table shadows,
## finished-build showcase framing, and reduced-motion paths.

const THEMES = {
	"harbour": {
		"name": "Cozy Coastal Harbour",
		"sun_color": Color(1.0, 0.96, 0.90),
		"sun_energy": 1.15,
		"sun_rotation": Vector3(-50.0, 35.0, 0.0),
		"sky_top": Color(0.40, 0.58, 0.82),
		"sky_horizon": Color(0.72, 0.78, 0.85),
		"ambient_color": Color(0.85, 0.88, 0.92),
		"table_color": Color(0.55, 0.40, 0.28) # Warm oak
	},
	"cabin": {
		"name": "Alpine Pine Cabin",
		"sun_color": Color(1.0, 0.88, 0.72), # Golden hour
		"sun_energy": 1.20,
		"sun_rotation": Vector3(-40.0, 45.0, 0.0),
		"sky_top": Color(0.35, 0.45, 0.65),
		"sky_horizon": Color(0.85, 0.70, 0.55),
		"ambient_color": Color(0.90, 0.82, 0.75),
		"table_color": Color(0.38, 0.25, 0.16) # Rich dark timber
	},
	"studio": {
		"name": "Clean Creator Studio",
		"sun_color": Color(0.98, 0.98, 1.0),
		"sun_energy": 1.10,
		"sun_rotation": Vector3(-55.0, 30.0, 0.0),
		"sky_top": Color(0.50, 0.60, 0.75),
		"sky_horizon": Color(0.80, 0.82, 0.85),
		"ambient_color": Color(0.92, 0.92, 0.95),
		"table_color": Color(0.70, 0.68, 0.64) # Neutral ash wood
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
		sun.rotation_degrees = t_data["sun_rotation"]
		sun.shadow_enabled = (current_quality != "economy")
		sun.shadow_bias = 0.04
		
	if world_env and world_env.environment:
		var env = world_env.environment
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = t_data["ambient_color"]
		env.ambient_light_energy = 0.8
		env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
		
		if env.sky and env.sky.sky_material is ProceduralSkyMaterial:
			var sky_mat = env.sky.sky_material as ProceduralSkyMaterial
			sky_mat.sky_top_color = t_data["sky_top"]
			sky_mat.sky_horizon_color = t_data["sky_horizon"]

	if table_view and table_view.has_node("TableMesh"):
		var tm = table_view.get_node("TableMesh") as MeshInstance3D
		if tm:
			var mat = StandardMaterial3D.new()
			mat.albedo_color = t_data["table_color"]
			mat.roughness = 0.75
			tm.material_override = mat

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
