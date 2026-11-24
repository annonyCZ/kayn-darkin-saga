shader_type canvas_item;
// Cinematic grade for the main menu: vignette, dark left side for the UI, red tint at the edges, film grain.
uniform float left_width = 0.55;
uniform float left_dark = 0.80;
uniform float vignette = 0.85;
uniform float grain = 0.05;

float hash(vec2 p) {
	p = fract(p * vec2(443.897, 441.423));
	p += dot(p, p.yx + 19.19);
	return fract((p.x + p.y) * p.x);
}
void fragment() {
	vec2 uv = UV;
	float d = distance(uv * vec2(1.0, 0.8), vec2(0.64, 0.4));
	float vig = smoothstep(0.38, 1.0, d) * vignette;
	float left = (1.0 - smoothstep(0.0, left_width, uv.x));
	left = left * left * left_dark;
	float a = clamp(vig + left, 0.0, 0.94);
	vec3 col = mix(vec3(0.0), vec3(0.07, 0.0, 0.015), smoothstep(0.0, 1.0, vig));
	float g = hash(floor(uv * vec2(1280.0, 720.0)) + floor(TIME * 24.0)) - 0.5;
	COLOR = vec4(col + g * grain, clamp(a + abs(g) * grain * 0.6, 0.0, 1.0));
}
