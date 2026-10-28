shader_type canvas_item;

// Angin: menggeser piksel ke samping, makin ke atas makin jauh.
// Geseran dibulatkan ke piksel penuh supaya gambar tetap tajam.

uniform float strength = 1.5; // geseran maksimum (piksel) di ujung atas
uniform float speed = 1.5;
uniform float wave = 0.045;   // beda fase antar posisi, biar tidak bergerak serempak

varying float phase;

void vertex() {
	vec2 world_pos = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xy;
	phase = world_pos.x * wave + world_pos.y * wave * 0.5;
}

void fragment() {
	float h = 1.0 - UV.y;
	float s = sin(TIME * speed + phase) * 0.7 + sin(TIME * speed * 2.3 + phase * 1.7) * 0.3;
	float off = floor(s * strength * h * h + 0.5);
	COLOR = texture(TEXTURE, UV + vec2(off * TEXTURE_PIXEL_SIZE.x, 0.0));
}
