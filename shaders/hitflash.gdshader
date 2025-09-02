shader_type canvas_item;

uniform float amplifier = 0.0;

void fragment() {
	vec4 ogColor = texture(TEXTURE, UV);
	vec4 amplifiedColor = vec4(min(ogColor.r + amplifier, 1.0), min(ogColor.g + amplifier, 1.0), min(ogColor.b + amplifier, 1.0), ogColor.a);
	COLOR = amplifiedColor;
}