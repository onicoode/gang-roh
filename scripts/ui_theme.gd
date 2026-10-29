extends RefCounted
## Tema UI bersama untuk menu dan HUD. Pakai: theme = UiTheme.make()

const INK := Color(0.16, 0.13, 0.18)
const PAPER := Color(1, 0.96, 0.88)
const GOLD := Color(1, 0.84, 0.42)
const DOA := Color(0.72, 0.92, 1.0)
const RED := Color(0.95, 0.42, 0.4)


static func _box(bg: Color, border: Color, radius: int = 10, pad: int = 14) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(3)
	s.set_corner_radius_all(radius)
	s.content_margin_left = pad + 4
	s.content_margin_right = pad + 4
	s.content_margin_top = pad
	s.content_margin_bottom = pad
	return s


static func make() -> Theme:
	var t := Theme.new()
	t.default_font_size = 26
	# tombol
	t.set_stylebox("normal", "Button", _box(Color(0.33, 0.22, 0.3), Color(0.55, 0.36, 0.42)))
	t.set_stylebox("hover", "Button", _box(Color(0.42, 0.28, 0.36), GOLD))
	t.set_stylebox("pressed", "Button", _box(Color(0.24, 0.16, 0.22), GOLD))
	t.set_stylebox("disabled", "Button", _box(Color(0.22, 0.2, 0.24), Color(0.3, 0.28, 0.32)))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", PAPER)
	t.set_color("font_hover_color", "Button", GOLD)
	t.set_color("font_pressed_color", "Button", GOLD)
	t.set_color("font_disabled_color", "Button", Color(0.55, 0.52, 0.56))
	# panel
	t.set_stylebox("panel", "PanelContainer", _box(Color(0.12, 0.1, 0.16, 0.94), Color(0.55, 0.36, 0.42), 14, 22))
	# label
	t.set_color("font_color", "Label", PAPER)
	t.set_color("font_outline_color", "Label", INK)
	t.set_constant("outline_size", "Label", 8)
	return t
