shader_type canvas_item;
// Cinematic overlay: vignette, film grain, red flash when hurt, pulsing edge when low on health.
uniform float hurt : hint_range(0.0, 1.0) = 0.0;
uniform float low_health : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 uv = UV - 0.5;
	float d = dot(uv, uv);
	float vig = smoothstep(0.12, 0.55, d);
	float pulse = 0.5 + 0.5 * sin(TIME * 4.0);
	float edge = vig * (0.35 + hurt * 0.5 + low_health * (0.2 + 0.3 * pulse));
	float grain = (fract(sin(dot(UV * 1000.0 + TIME, vec2(12.9898, 78.233))) * 43758.5453) - 0.5) * 0.04;
	vec3 col = mix(vec3(0.0), vec3(0.55, 0.0, 0.02), clamp(hurt + low_health * 0.7, 0.0, 1.0));
	COLOR = vec4(col + grain, clamp(edge + abs(grain), 0.0, 0.85));
}
