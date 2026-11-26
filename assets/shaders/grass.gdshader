shader_type spatial;
render_mode cull_disabled;
// Procedural grass blade (no texture) with wind sway; UV.y = 0 at tip, 1 at root.
uniform vec3 root_col : source_color = vec3(0.04, 0.08, 0.03);
uniform vec3 tip_col : source_color = vec3(0.30, 0.38, 0.14);
uniform float wind = 0.22;

void vertex() {
	float h = 1.0 - UV.y;
	vec2 p = MODEL_MATRIX[3].xz;
	float s = sin(TIME * 1.6 + p.x * 0.35 + p.y * 0.21) + 0.5 * sin(TIME * 3.1 + p.x * 0.9);
	VERTEX.x += s * wind * h * h;
	VERTEX.z += s * wind * 0.5 * h * h;
}

void fragment() {
	float h = 1.0 - UV.y;
	float x = UV.x * 3.0;
	float id = floor(x);
	float w = abs(fract(x) - 0.5) * 2.0;
	float bh = 0.65 + 0.35 * fract(id * 0.618 + MODEL_MATRIX[3].x * 0.37);
	float hh = h / bh;
	if (hh > 1.0 || w > 1.0 - hh * 0.92) { discard; }
	float var_ = 0.75 + 0.5 * fract(sin(dot(MODEL_MATRIX[3].xz + id, vec2(12.9898, 78.233))) * 43758.5453);
	ALBEDO = mix(root_col, tip_col, hh * hh) * var_;
	NORMAL = vec3(0.0, 0.0, 1.0);
	ROUGHNESS = 0.8;
	SPECULAR = 0.1;
}
