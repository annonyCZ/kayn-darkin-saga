shader_type spatial;
// Slope-blended terrain: grass on flats, cliff rock on slopes, world-space UVs, anti-tiling.
uniform sampler2D grass_tex : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D rock_tex : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform vec3 grass_tint : source_color = vec3(0.28, 0.42, 0.16);
uniform vec3 dry_tint : source_color = vec3(0.45, 0.42, 0.22);
uniform vec3 rock_tint : source_color = vec3(0.5, 0.47, 0.45);
uniform float grass_scale = 0.16;
uniform float rock_scale = 0.09;

varying vec3 wpos;
varying vec3 wnrm;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

vec3 triplanar(sampler2D t, vec3 p, vec3 n, float s) {
	vec3 w = pow(abs(n), vec3(4.0));
	w /= (w.x + w.y + w.z);
	return texture(t, p.zy * s).rgb * w.x + texture(t, p.xz * s).rgb * w.y + texture(t, p.xy * s).rgb * w.z;
}

void fragment() {
	vec3 n = normalize(wnrm);
	// two scales mixed to hide tiling
	vec3 g1 = texture(grass_tex, wpos.xz * grass_scale).rgb;
	vec3 g2 = texture(grass_tex, wpos.xz * grass_scale * 0.23 + 0.37).rgb;
	vec3 grass = mix(g1, g2, 0.45) * 1.7;
	float patch = texture(grass_tex, wpos.xz * 0.02).r;
	grass *= mix(grass_tint, dry_tint, smoothstep(0.35, 0.75, patch));
	vec3 rock = triplanar(rock_tex, wpos, n, rock_scale) * rock_tint * 1.5;
	float slope = 1.0 - n.y;
	float t = smoothstep(0.16, 0.34, slope + (patch - 0.5) * 0.12);
	ALBEDO = mix(grass, rock, t);
	ROUGHNESS = mix(0.95, 0.85, t);
	SPECULAR = 0.2;
}
