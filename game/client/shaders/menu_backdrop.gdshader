shader_type canvas_item;
render_mode unshaded;

uniform vec4 paper : source_color = vec4(0.99, 0.965, 0.895, 1.0);
uniform vec4 edge : source_color = vec4(0.91, 0.863, 0.785, 1.0);

void fragment() {
	vec2 page = UV;
	float light = max(0.0, 1.0 - length((page - vec2(0.22, 0.12)) * vec2(0.86, 1.06)));
	vec3 ground = mix(edge.rgb, paper.rgb, light);
	vec2 cell = fract(FRAGCOORD.xy / 24.0) - vec2(0.5);
	float dot_mask = 1.0 - smoothstep(0.049, 0.072, length(cell));
	float edge_pattern = smoothstep(0.30, 0.51, abs(page.x - 0.50));
	COLOR = vec4(ground * (1.0 - dot_mask * edge_pattern * 0.076), 1.0);
}
