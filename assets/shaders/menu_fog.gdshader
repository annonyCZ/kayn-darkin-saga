shader_type canvas_item;
// Drifting procedural mist (value-noise fBm), no textures needed.
uniform vec4 fog_color : source_color = vec4(0.55, 0.5, 0.6, 1.0);
uniform float density = 0.35;
uniform vec2 speed = vec2(0.015, 0.004);
uniform float noise_scale = 2.5;
uniform float aspect = 1.78;
uniform float bottom_bias = 0.0; // 0 = uniform, 1 = only near the bottom edge

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}
float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		v += a * vnoise(p);
		p = p * 2.03 + vec2(7.1, 3.7);
		a *= 0.5;
	}
	return v;
}
void fragment() {
	vec2 uv = vec2(UV.x * aspect, UV.y) * noise_scale;
	float n = fbm(uv + speed * TIME * 6.0);
	float n2 = fbm(uv * 1.7 - speed.yx * TIME * 5.0 + 11.0);
	float m = smoothstep(0.30, 0.85, n * 0.65 + n2 * 0.45);
	float h = mix(1.0, smoothstep(0.35, 1.0, UV.y), bottom_bias);
	COLOR = vec4(fog_color.rgb, m * density * h);
}
