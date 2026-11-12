shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

uniform float rain : hint_range(0.0, 1.0) = 0.0;
uniform float animation_time = 0.0;
uniform float layer_seed = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 p = UV;
	float speed = mix(1.45, 2.05, layer_seed);
	vec2 grid = vec2((p.x - p.y * 0.12) * mix(92.0, 77.0, layer_seed),
		(p.y - animation_time * speed) * 11.0);
	vec2 cell = floor(grid);
	vec2 local = fract(grid);
	float seed = hash(cell + layer_seed * 32.8);
	float offset = mix(0.23, 0.77, hash(cell + 14.6));
	float width = mix(0.052, 0.13, seed);
	float line = 1.0 - smoothstep(width * 0.45, width, abs(local.x - offset));
	float end = mix(0.20, 0.56, hash(cell + 3.4));
	float streak = smoothstep(0.025, 0.10, local.y) * (1.0 - smoothstep(end * 0.54, end, local.y));
	float edges = smoothstep(0.0, 0.12, p.x) * smoothstep(0.0, 0.12, 1.0 - p.x)
		* smoothstep(0.0, 0.10, p.y) * smoothstep(0.0, 0.10, 1.0 - p.y);
	ALBEDO = vec3(0.75, 0.86, 0.92);
	ALPHA = line * streak * step(0.56, seed) * rain * edges * mix(0.68, 0.52, layer_seed);
}
