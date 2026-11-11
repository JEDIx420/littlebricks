shader_type spatial;

uniform vec4 wood : source_color = vec4(0.62, 0.41, 0.26, 1.0);
uniform vec3 grain_axis = vec3(1.0, 0.0, 0.0);
uniform float matte = 0.54;
uniform bool floor_boards = false;
varying vec3 room_position;

void vertex() {
	room_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 p = room_position;
	float along = dot(p, grain_axis);
	vec3 across_axis = abs(grain_axis.z) > 0.5 ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 0.0, 1.0);
	float across = dot(p, across_axis) + 0.37 * p.y;
	float drift = 0.37 * sin(along * 0.12 + across * 0.53) + 0.22 * sin(along * 0.34);
	float band = across + drift;
	float grain = 0.032 * sin(band * 6.8) + 0.028 * sin(band * 15.8 + along * 0.09);
	float figure = 0.052 * sin(band * 1.8 + along * 0.14) + 0.03 * sin(band * 0.51);
	float boards = 0.0;
	if (floor_boards) {
		float row = floor(p.x / 4.1);
		float stagger = fract(row * 0.618) * 15.0;
		float column = floor((p.z + stagger) / 15.0);
		vec2 within = fract(vec2(p.x / 4.1, (p.z + stagger) / 15.0));
		float seam = max(1.0 - smoothstep(0.0, 0.022, min(within.x, 1.0 - within.x)), 1.0 - smoothstep(0.0, 0.007, min(within.y, 1.0 - within.y)));
		float tone = fract(sin(row * 53.2 + column * 17.7) * 4375.0);
		boards = (tone - 0.5) * 0.18 - seam * 0.19;
	}
	ALBEDO = wood.rgb * (1.0 + grain + figure + boards);
	ROUGHNESS = matte;
	SPECULAR = 0.28;
}
