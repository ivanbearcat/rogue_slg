shader_type canvas_item;

uniform vec4 old_color: source_color;
uniform vec4 new_color: source_color;

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	if (length(color.rgb - old_color.rgb) < 0.01){
		COLOR = new_color;
	}
}

