extends Control
## Layar utama: dunia game dalam SubViewport (pixel-perfect) + UI.
## Kontrol sentuh = swipe tak terlihat (node Swipe, scripts/swipe_input.gd).
## Ukuran dunia menyesuaikan layar: sisi terpendek selalu sekitar 180 piksel game,
## jadi di HP portrait terlihat lebih tinggi, di landscape lebih lebar.

const TARGET_SHORT := 180.0

var _msg_t := 0.0

@onready var game_view: SubViewportContainer = $GameView
@onready var world: Node2D = $GameView/SubViewport/World
@onready var ui: CanvasLayer = $UI
@onready var hud_month: Label = $UI/Month
@onready var hud_coins: Label = $UI/Coins
@onready var message: Label = $UI/Message
@onready var end_panel: PanelContainer = $UI/EndPanel
@onready var end_title: Label = $UI/EndPanel/VBox/Title
@onready var end_label: Label = $UI/EndPanel/VBox/Summary
@onready var restart_btn: Button = $UI/EndPanel/VBox/Restart


func _ready() -> void:
	get_viewport().size_changed.connect(_layout)
	world.message.connect(show_message)
	world.session_ended.connect(_on_session_ended)
	restart_btn.pressed.connect(func(): get_tree().reload_current_scene())
	end_panel.visible = false
	_layout()
	show_message("Pungut koin persembahan, lalu tanam di tanah kosong.")


func _process(delta: float) -> void:
	var warn: String = "  ·  DEVELOPER!" if world.dev_count() > 0 else ""
	hud_month.text = "Bulan %d / %d  ·  %s%s" % [world.month, world.MONTHS, world.phase_name(), warn]
	hud_coins.text = "Koin: %d / %d" % [world.player.coins, world.player.max_coins]
	_msg_t -= delta
	message.modulate.a = clampf(_msg_t, 0.0, 1.0)


func show_message(text: String) -> void:
	message.text = text
	_msg_t = 3.0


func _layout() -> void:
	var s := get_viewport_rect().size
	var short := minf(s.x, s.y)
	game_view.stretch_shrink = maxi(1, int(short / TARGET_SHORT))
	var k := short / 720.0
	ui.scale = Vector2(k, k)
	var u := s / k # ukuran layar dalam satuan UI
	hud_month.position = Vector2(24, 16)
	hud_coins.position = Vector2(24, 54)
	message.position = Vector2(16, 100)
	message.size = Vector2(u.x - 32, 80)
	end_panel.position = (u - end_panel.size) / 2.0


func _on_session_ended() -> void:
	end_title.text = "Gang tergusur... kuil ikut dibongkar." if world.lost else "Satu tahun berlalu..."
	end_label.text = world.summary()
	end_panel.visible = true
	_layout()
