shader_type canvas_item;
render_mode unshaded;

uniform vec4 paper : source_color = vec4(0.99, 0.967, 0.902, 1.0);
uniform vec4 edge : source_color = vec4(0.936, 0.885, 0.797, 1.0);
uniform vec4 studs : source_color = vec4(0.49, 0.37, 0.22, 1.0);
uniform float stud_weight = 0.15;

void fragment() {
	vec2 page = UV;
	float light = max(0.0, 1.0 - length((page - vec2(0.71, 0.23)) * vec2(0.96, 1.12)));
	vec3 ground = mix(edge.rgb, paper.rgb, light);
	vec2 dot = fract(FRAGCOORD.xy / 23.0) - vec2(0.50);
	float stud = 1.0 - smoothstep(0.120, 0.156, length(dot));
	float edge_studs = smoothstep(0.23, 0.50, abs(page.x - 0.50));
	edge_studs = max(edge_studs, smoothstep(0.31, 0.50, abs(page.y - 0.50)) * 0.54);
	COLOR = vec4(mix(ground, studs.rgb, stud * edge_studs * stud_weight), 1.0);
}
