extends Control
## Layar game: dunia dalam SubViewport (pixel-perfect) + HUD + menu jeda + panel akhir sesi.
## Kontrol sentuh = swipe tak terlihat (node Swipe, scripts/swipe_input.gd).
## Ukuran dunia menyesuaikan layar: sisi terpendek selalu sekitar 180 piksel game,
## jadi di HP portrait terlihat lebih tinggi, di landscape lebih lebar.

const TARGET_SHORT := 180.0
const UiTheme := preload("res://scripts/ui_theme.gd")
const DOA_TEX := preload("res://sprites/coin.png")
const MENU_SCENE := "res://scenes/menu.tscn"

var _msg_t := 0.0
var _blink := 0.0
var _theme: Theme
var _doa_icon: TextureRect
var _warn: Label
var _pause_btn: Button
var _pause_panel: PanelContainer

@onready var game_view: SubViewportContainer = $GameView
@onready var world: Node2D = $GameView/SubViewport/World
@onready var swipe: Node = $Swipe
@onready var ui: CanvasLayer = $UI
@onready var hud_month: Label = $UI/Month
@onready var hud_coins: Label = $UI/Coins
@onready var message: Label = $UI/Message
@onready var end_panel: PanelContainer = $UI/EndPanel
@onready var end_title: Label = $UI/EndPanel/VBox/Title
@onready var end_label: Label = $UI/EndPanel/VBox/Summary
@onready var restart_btn: Button = $UI/EndPanel/VBox/Restart


func _ready() -> void:
	# UI tetap jalan saat jeda; dunia dan swipe ikut berhenti.
	process_mode = Node.PROCESS_MODE_ALWAYS
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	swipe.process_mode = Node.PROCESS_MODE_PAUSABLE
	_theme = UiTheme.make()
	_build_hud()
	get_viewport().size_changed.connect(_layout)
	world.message.connect(show_message)
	world.session_ended.connect(_on_session_ended)
	end_panel.theme = _theme
	restart_btn.text = "Persiapan & main lagi"
	restart_btn.custom_minimum_size = Vector2(360, 64)
	restart_btn.pressed.connect(_go_menu.bind(true))
	var menu_btn := _button("Menu utama", _go_menu.bind(false))
	end_label.get_parent().add_child(menu_btn)
	end_panel.visible = false
	_layout()
	show_message("Warga berdoa → Doa muncul. Pungut, lalu kabulkan keinginan warga (gelembung).")


func _process(delta: float) -> void:
	hud_month.text = "Bulan %d / %d  ·  %s" % [world.month, world.MONTHS, world.phase_name()]
	hud_coins.text = "%d / %d" % [world.player.coins, world.player.max_coins]
	var threat: String = world.threat_text()
	_warn.text = threat
	_warn.visible = threat != "" and not world.ended
	if _warn.visible:
		_blink += delta
		_warn.modulate.a = 0.55 + 0.45 * absf(sin(_blink * 4.0))
	_msg_t -= delta
	message.modulate.a = clampf(_msg_t, 0.0, 1.0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_toggle_pause()
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_toggle_pause() # tombol Back Android = jeda
	elif what == NOTIFICATION_APPLICATION_PAUSED and not world.ended:
		_set_paused(true) # aplikasi diminimalkan


func show_message(text: String) -> void:
	message.text = text
	_msg_t = 3.0


# ---------------------------------------------------------------- HUD & jeda

func _build_hud() -> void:
	hud_coins.add_theme_color_override("font_color", UiTheme.DOA)
	var atlas := AtlasTexture.new()
	atlas.atlas = DOA_TEX
	atlas.region = Rect2(0, 0, 6, 6)
	_doa_icon = TextureRect.new()
	_doa_icon.texture = atlas
	_doa_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_doa_icon.scale = Vector2(5, 5)
	_doa_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(_doa_icon)

	_warn = Label.new()
	_warn.text = "! Developer di gang !"
	_warn.add_theme_font_size_override("font_size", 26)
	_warn.add_theme_color_override("font_color", UiTheme.RED)
	_warn.add_theme_color_override("font_outline_color", UiTheme.INK)
	_warn.add_theme_constant_override("outline_size", 8)
	_warn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_warn.visible = false
	ui.add_child(_warn)

	_pause_btn = _button("II", _toggle_pause)
	_pause_btn.custom_minimum_size = Vector2(76, 68)
	ui.add_child(_pause_btn)

	_pause_panel = PanelContainer.new()
	_pause_panel.theme = _theme
	_pause_panel.visible = false
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	_pause_panel.add_child(v)
	var t := Label.new()
	t.text = "Jeda"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 40)
	t.add_theme_color_override("font_color", UiTheme.GOLD)
	v.add_child(t)
	v.add_child(_button("Lanjut", _set_paused.bind(false)))
	v.add_child(_button("Ulang sesi", _restart))
	v.add_child(_button("Menu utama", _go_menu.bind(false)))
	ui.add_child(_pause_panel)


func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.theme = _theme
	b.custom_minimum_size = Vector2(300, 64)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(cb)
	return b


func _toggle_pause() -> void:
	if world.ended:
		return
	_set_paused(not get_tree().paused)


func _set_paused(on: bool) -> void:
	get_tree().paused = on
	_pause_panel.visible = on
	_pause_btn.visible = not on
	swipe.reset() # lepas semua arah/aksi yang sedang ditahan
	_layout()


func _restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _go_menu(prepare: bool) -> void:
	get_tree().paused = false
	Save.open_prepare = prepare
	get_tree().change_scene_to_file(MENU_SCENE)


func _layout() -> void:
	var s := get_viewport_rect().size
	var short := minf(s.x, s.y)
	game_view.stretch_shrink = maxi(1, int(short / TARGET_SHORT))
	var k := short / 720.0
	ui.scale = Vector2(k, k)
	var u := s / k # ukuran layar dalam satuan UI
	hud_month.position = Vector2(24, 16)
	_doa_icon.position = Vector2(26, 60)
	hud_coins.position = Vector2(68, 54)
	_warn.position = Vector2(24, 92)
	message.position = Vector2(16, 132)
	message.size = Vector2(u.x - 32, 80)
	_pause_btn.position = Vector2(u.x - 76 - 20, 16)
	_pause_panel.reset_size()
	_pause_panel.position = (u - _pause_panel.size) / 2.0
	end_panel.reset_size()
	end_panel.position = (u - end_panel.size) / 2.0


func _on_session_ended() -> void:
	swipe.reset()
	_pause_btn.visible = false
	var gained: int = Save.finish_session(world.month, world.total_floors(), world.lost)
	end_title.text = "Gang tergusur... kuil ikut dibongkar." if world.lost else "Satu tahun berlalu..."
	end_label.text = world.summary() + "\n\nEma didapat: +%d  (total %d)" % [gained, Save.ema]
	end_panel.visible = true
	_layout.call_deferred()
