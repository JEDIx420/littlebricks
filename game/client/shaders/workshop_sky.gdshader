shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;

uniform float daylight : hint_range(0.0, 1.0) = 1.0;
uniform float sunset : hint_range(0.0, 1.0) = 0.0;
uniform float rain : hint_range(0.0, 1.0) = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(cell), hash(cell + vec2(1, 0)), f.x),
		mix(hash(cell + vec2(0, 1)), hash(cell + vec2(1)), f.x), f.y);
}

void fragment() {
	float height = 1.0 - UV.y;
	vec3 night = mix(vec3(0.072, 0.12, 0.21), vec3(0.018, 0.032, 0.087), height);
	vec3 day = mix(vec3(0.78, 0.84, 0.77), vec3(0.39, 0.60, 0.76), height);
	vec3 sky = mix(night, day, daylight);
	vec3 twilight = mix(vec3(0.86, 0.53, 0.41), vec3(0.24, 0.28, 0.45), height);
	sky = mix(sky, twilight, sunset * 0.86);
	vec3 overcast = mix(vec3(0.46, 0.55, 0.57), vec3(0.26, 0.34, 0.41), height);
	sky = mix(sky, overcast, rain * mix(0.44, 0.89, daylight));

	vec2 scaled = UV * vec2(15.0, 12.0);
	float clouds = noise(scaled * vec2(0.46, 1.38)) * 0.62 + noise(scaled * 1.8) * 0.38;
	float cloud_mask = smoothstep(0.45 - rain * 0.12, 0.72, clouds);
	sky = mix(sky, mix(night * 1.35, vec3(0.85, 0.88, 0.85), daylight),
		cloud_mask * mix(0.40, 0.21, rain));

	vec2 star_grid = UV * vec2(130.0, 75.0);
	vec2 cell = floor(star_grid);
	float star_size = hash(cell + 27.3);
	float star = (1.0 - smoothstep(0.01, 0.15, length(fract(star_grid) - 0.5))) * step(0.89, star_size);
	sky += vec3(0.58, 0.68, 0.85) * star * (1.0 - daylight) * (1.0 - rain) * (1.0 - sunset);
	vec2 moon_uv = (UV - vec2(0.420, 0.535)) * vec2(1.78, 1.0);
	float moon = 1.0 - smoothstep(0.016, 0.018, length(moon_uv));
	float shadow = 1.0 - smoothstep(0.015, 0.017, length(moon_uv - vec2(0.009, -0.005)));
	sky += vec3(0.71, 0.78, 0.84) * moon * (1.0 - shadow) * (1.0 - daylight) * (1.0 - rain) * (1.0 - sunset);
	ALBEDO = sky;
}
