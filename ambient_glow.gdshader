shader_type canvas_item;
render_mode blend_add;

// ─── AMBIENT GLOW SHADER ──────────────────────────────────────────────────────
// Low-overhead GPU ambient pulse shader with additive blending.
// Creates a soothing, living atmosphere without washing out background art.

uniform vec4 glow_color : source_color = vec4(0.55, 0.38, 0.95, 1.0); // Ambient palette purple/indigo
uniform float pulse_speed : hint_range(0.1, 2.0) = 0.45;               // Frequency of the sine breathing pulse
uniform float base_intensity : hint_range(0.0, 0.15) = 0.055;          // Minimum glow baseline
uniform float pulse_amount : hint_range(0.0, 0.15) = 0.025;            // Amplitude of the sine wave pulse

void fragment() {
	// Slow sine wave breathing cycle (0.0 to 1.0)
	float pulse = sin(TIME * pulse_speed) * 0.5 + 0.5;
	
	// Total opacity stays strictly around ~0.055 - 0.080 for low-profile additive wash
	float alpha = base_intensity + (pulse * pulse_amount);
	
	// Soft vignette falloff from the screen center outward
	vec2 center_dist = UV - vec2(0.5, 0.45);
	float dist = length(center_dist);
	float radial_vignette = smoothstep(0.85, 0.15, dist);
	
	COLOR = vec4(glow_color.rgb, alpha * radial_vignette);
}
