shader_type canvas_item;

uniform vec4 border_color : source_color = vec4(1.0, 0.84, 0.35, 1.0);
uniform float border_width : hint_range(0.0, 0.2) = 0.06;
uniform vec4 bg_color : source_color = vec4(0.18, 0.12, 0.08, 0.7);

void fragment() {
	vec2 uv = UV - vec2(0.5);
	float dist = length(uv);
	if (dist > 0.5) {
		COLOR.a = 0.0;
	} else if (dist > 0.5 - border_width) {
		COLOR = border_color;
	} else {
		vec4 tex = texture(TEXTURE, UV);
		COLOR = mix(bg_color, tex, tex.a);
		COLOR.a = 1.0;
	}
}
