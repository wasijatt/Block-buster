shader_type canvas_item;

uniform vec4 color_top : source_color = vec4(0.12, 0.10, 0.22, 1.0);
uniform vec4 color_bottom : source_color = vec4(0.06, 0.05, 0.10, 1.0);
uniform float speed : hint_range(0.0, 2.0) = 0.15;

void fragment() {
	float wave = sin(UV.x * 3.0 + TIME * speed) * 0.05;
	vec4 base = mix(color_bottom, color_top, UV.y + wave);
	
	float glow = sin(TIME * speed * 0.5 + UV.x * 6.0) * 0.5 + 0.5;
	float dist = distance(UV, vec2(0.5 + sin(TIME * 0.1) * 0.2, 0.3));
	float orb = smoothstep(0.4, 0.0, dist) * 0.08 * glow;
	
	base.rgb += orb * vec3(1.0, 0.6, 0.3);
	COLOR = base;
}
