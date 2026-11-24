shader_type canvas_item;
// Main-menu key art: soft fade on the left edge (blends into the dark menu side), slight bottom fade.
uniform float fade_start = 0.0;
uniform float fade_end = 0.30;
uniform float bottom_fade = 0.10;
uniform float brightness = 1.0;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float a = smoothstep(fade_start, fade_end, UV.x);
	a *= smoothstep(1.0, 1.0 - bottom_fade, UV.y);
	COLOR = vec4(c.rgb * brightness, c.a * a);
}
