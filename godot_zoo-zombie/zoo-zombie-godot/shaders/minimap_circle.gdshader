shader_type canvas_item;

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	float radius = length(UV - vec2(0.5));
	float mask = 1.0 - smoothstep(0.49, 0.5, radius);
	COLOR = vec4(color.rgb, color.a * mask);
}
