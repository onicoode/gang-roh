shader_type canvas_item;

// Langit bergradasi dengan pita warna kasar (terasa pixel art).

uniform vec4 top_color : source_color = vec4(0.6, 0.75, 0.85, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.95, 0.88, 0.75, 1.0);

void fragment() {
	float y = floor(UV.y * 16.0) / 15.0;
	COLOR = mix(top_color, bottom_color, y);
}
