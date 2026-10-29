extends Control
## Menu utama + layar Persiapan Roh (upgrade permanen dengan Ema) sebelum sesi.
## UI dibuat dari kode supaya scene tetap sederhana.
## Argumen debug apa pun (mis. -- --demo) langsung masuk game, kecuali -- --menu.

const UiTheme := preload("res://scripts/ui_theme.gd")
const CAT_TEX := preload("res://sprites/cat.png")
const SHRINE_TEX := preload("res://sprites/shrine.png")
const STREET_TEX := preload("res://sprites/street.png")
const GAME_SCENE := "res://scenes/main.tscn"

var _root: Control
var _main_box: VBoxContainer
var _prep_panel: PanelContainer
var _ema_main: Label
var _ema_prep: Label
var _stats: Label
var _rows: Dictionary = {} # id -> {"lv": Label, "btn": Button}
var _cat_atlas: AtlasTexture
var _scene_box: Control
var _t := 0.0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty() and not args.has("--menu"):
		get_tree().change_scene_to_file.call_deferred(GAME_SCENE)
		return
	theme = UiTheme.make()
	_build()
	get_viewport().size_changed.connect(_layout)
	_layout()
	_show_prepare(Save.open_prepare)
	Save.open_prepare = false
	if args.has("--menu"):
		# uji CI: buka layar persiapan dan coba beli
		_show_prepare(true)
		_on_buy("langkah")


func _process(delta: float) -> void:
	_t += delta
	if _cat_atlas:
		_cat_atlas.region = Rect2((int(_t * 3.0) % 4) * 16, 0, 16, 16)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if _prep_panel and _prep_panel.visible:
			_show_prepare(false)
		else:
			get_tree().quit()


# ---------------------------------------------------------------- susun UI

func _build() -> void:
	# langit
	var sky := TextureRect.new()
	var grad := Gradient.new()
	grad.set_color(0, Color("f2b066"))
	grad.set_color(1, Color("6a4f86"))
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_from = Vector2(0, 1)
	gt.fill_to = Vector2(0, 0)
	sky.texture = gt
	sky.stretch_mode = TextureRect.STRETCH_SCALE
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sky)

	_root = Control.new()
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	# pemandangan kecil: jalan, kuil, kucing
	_scene_box = Control.new()
	_scene_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_scene_box)
	var street := TextureRect.new()
	street.texture = STREET_TEX
	street.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	street.stretch_mode = TextureRect.STRETCH_TILE
	street.position = Vector2(-2000, 0)
	street.size = Vector2(4000 / 6.0, 40)
	street.scale = Vector2(6, 6)
	_scene_box.add_child(street)
	var shrine := TextureRect.new()
	shrine.texture = SHRINE_TEX
	shrine.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	shrine.scale = Vector2(6, 6)
	shrine.position = Vector2(-SHRINE_TEX.get_width() * 6 - 20, -SHRINE_TEX.get_height() * 6)
	_scene_box.add_child(shrine)
	_cat_atlas = AtlasTexture.new()
	_cat_atlas.atlas = CAT_TEX
	_cat_atlas.region = Rect2(0, 0, 16, 16)
	var cat := TextureRect.new()
	cat.texture = _cat_atlas
	cat.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	cat.scale = Vector2(8, 8)
	cat.position = Vector2(30, -16 * 8)
	_scene_box.add_child(cat)

	# --- menu utama
	_main_box = VBoxContainer.new()
	_main_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_main_box.add_theme_constant_override("separation", 18)
	_root.add_child(_main_box)
	var title := _label("Gang Roh", 84, UiTheme.GOLD)
	title.add_theme_constant_override("outline_size", 16)
	_main_box.add_child(title)
	_main_box.add_child(_label("Roh penjaga gang kecil", 26, UiTheme.PAPER))
	_ema_main = _label("", 28, UiTheme.GOLD)
	_main_box.add_child(_ema_main)
	_main_box.add_child(_spacer(12))
	_main_box.add_child(_button("Mulai", func(): _show_prepare(true)))
	if not OS.has_feature("web"):
		_main_box.add_child(_button("Keluar", func(): get_tree().quit()))
	_stats = _label("", 20, Color(1, 0.95, 0.85, 0.8))
	_main_box.add_child(_stats)

	# --- layar persiapan (upgrade)
	_prep_panel = PanelContainer.new()
	_root.add_child(_prep_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	_prep_panel.add_child(v)
	v.add_child(_label("Persiapan Roh: Maneki-neko", 34, UiTheme.GOLD))
	_ema_prep = _label("", 26, UiTheme.GOLD)
	v.add_child(_ema_prep)
	for id: String in Save.ORDER:
		var def: Array = Save.SKILLS[id]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_constant_override("separation", 0)
		var name_l := _label(str(def[0]), 26, UiTheme.PAPER)
		name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		info.add_child(name_l)
		var desc := _label(str(def[1]), 18, Color(0.85, 0.82, 0.86))
		desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.custom_minimum_size = Vector2(300, 0)
		info.add_child(desc)
		row.add_child(info)
		var lv := _label("", 24, UiTheme.DOA)
		lv.custom_minimum_size = Vector2(90, 0)
		row.add_child(lv)
		var btn := _button("", _on_buy.bind(id))
		btn.custom_minimum_size = Vector2(170, 60)
		btn.add_theme_font_size_override("font_size", 22)
		row.add_child(btn)
		v.add_child(row)
		_rows[id] = {"lv": lv, "btn": btn}
	v.add_child(_spacer(6))
	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 20)
	bottom.add_child(_button("Kembali", func(): _show_prepare(false)))
	var go := _button("Mulai Sesi", _start_game)
	go.add_theme_color_override("font_color", UiTheme.GOLD)
	bottom.add_child(go)
	v.add_child(bottom)
	_refresh()


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(260, 68)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(cb)
	return b


func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


func _layout() -> void:
	var s := get_viewport_rect().size
	var k := minf(s.x, s.y) / 720.0
	_root.scale = Vector2(k, k)
	var u := s / k
	_root.size = u
	_scene_box.position = Vector2(u.x / 2.0, u.y - 60.0)
	_main_box.size = Vector2(u.x, 0)
	_main_box.reset_size()
	_main_box.size.x = u.x
	_main_box.position = Vector2(0, maxf(u.y * 0.12, 24.0))
	var pw := minf(u.x - 32.0, 700.0)
	_prep_panel.custom_minimum_size = Vector2(pw, 0)
	_prep_panel.reset_size()
	_prep_panel.position = Vector2((u.x - pw) / 2.0, maxf((u.y - _prep_panel.size.y) / 2.0, 12.0))


# ---------------------------------------------------------------- aksi

func _show_prepare(on: bool) -> void:
	_main_box.visible = not on
	_prep_panel.visible = on
	_scene_box.visible = not on or get_viewport_rect().size.y > get_viewport_rect().size.x
	_refresh()
	_layout.call_deferred()


func _refresh() -> void:
	_ema_main.text = "Ema: %d" % Save.ema
	_ema_prep.text = "Ema tersedia: %d" % Save.ema
	_stats.text = "Sesi dimainkan: %d  ·  Gedung tertinggi: %d lantai" % [Save.sessions, Save.best_floors]
	for id: String in Save.ORDER:
		var r: Dictionary = _rows[id]
		var lv: Label = r["lv"]
		var btn: Button = r["btn"]
		var n: int = Save.level(id)
		lv.text = "Lv %d/%d" % [n, Save.MAX_LEVEL]
		if n >= Save.MAX_LEVEL:
			btn.text = "Maks"
			btn.disabled = true
		else:
			btn.text = "+  %d Ema" % Save.cost(id)
			btn.disabled = not Save.can_buy(id)


func _on_buy(id: String) -> void:
	Save.buy(id)
	_refresh()


func _start_game() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)
