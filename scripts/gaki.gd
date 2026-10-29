extends Node2D
## Gaki: hantu lapar, yōkai kesialan paling lemah. Datang malam hari bergerombol dari ujung
## gang (tertahan pagar) atau dari sarang (bangunan bobrok / petak tergusur).
## Memakan Doa di jalan, mencuri persembahan kalau sampai di kuil.
## Dilawan Tsukumogami, atau dilempar Doa oleh kucing (tanam Doa di dekatnya).

const SPEED := 12.0
const MAX_HP := 3
const HIT_TIME := 1.5 # detik per serangan ke roh pelindung
const GATE_HIT_TIME := 4.0 # detik per serangan ke pagar
const THROW_DMG := 2 # kerusakan dari Doa yang dilempar kucing

const SKIN := Color("a8b89a")
const SKIN_D := Color("6a7a5e")
const EYE := Color("ff4a4a")
const MOUTH := Color("2a2228")
const SHADOW := Color(0, 0, 0, 0.3)

var world: Node = null
var dir := 1
var gate: Node = null
var hp := MAX_HP
var dead := false
var leaving := false # fajar: memudar
var show_slots := false:
	set(v):
		if v != show_slots:
			show_slots = v
			queue_redraw()

var _t := 0.0
var _anim := 0.0
var _flash := 0.0
var _moving := false
var _bob := 0.0


func _ready() -> void:
	_anim = randf() * 3.0
	_t = randf() * HIT_TIME


func _process(delta: float) -> void:
	if world.ended:
		return
	_anim += delta
	_flash = maxf(_flash - delta, 0.0)
	_moving = false
	if leaving:
		modulate.a -= delta
		if modulate.a <= 0.0:
			queue_free()
		queue_redraw()
		return
	_t += delta
	# makan Doa yang tergeletak
	var c: Node = world.coin_near(position.x, 5.0)
	if c != null:
		c.queue_free()
		world.pop_text(position + Vector2(0, -16), "nyam", Color("ff8a8a"))
	# lawan roh pelindung yang menempel
	var s: Node = world.nearest_spirit(position.x, 7.0)
	if s != null:
		dir = 1 if s.position.x > position.x else -1
		if _t >= HIT_TIME:
			_t = 0.0
			s.take_hit(1)
		queue_redraw()
		return
	# pagar di depan
	if gate != null and gate.hp > 0:
		var to_gate: float = (gate.position.x - position.x) * dir
		if to_gate > 0.0 and to_gate <= 9.0:
			if _t >= GATE_HIT_TIME:
				_t = 0.0
				world.sfx.play("bonk")
				if gate.hit():
					world.say("Pagar jebol! Gaki masuk gang.")
			queue_redraw()
			return
	# jalan ke kuil
	var to_shrine: float = world.shrine.position.x - position.x
	dir = 1 if to_shrine > 0.0 else -1
	position.x += dir * SPEED * delta
	_moving = true
	if absf(to_shrine) < 4.0:
		world.gaki_at_shrine()
		queue_free()
	queue_redraw()


func take_hit(dmg: int) -> void:
	if dead:
		return
	hp -= dmg
	_flash = 0.15
	world.sfx.play("hit")
	if hp <= 0:
		dead = true
		world.yokai_defeated(self)
		queue_free()


func fade() -> void:
	leaving = true
	show_slots = false


# ---------------------------------------------------------------- dilempar Doa (dipakai kucing)

func cost() -> int:
	return 1


func can_take_coin() -> bool:
	return not dead and not leaving


func add_coin() -> void:
	world.pop_text(position + Vector2(0, -16), "-%d" % THROW_DMG, Color("b8ebff"))
	take_hit(THROW_DMG)


# ---------------------------------------------------------------- gambar

func _draw() -> void:
	draw_rect(Rect2(-3, 0, 7, 1), SHADOW)
	var skin: Color = Color.WHITE if _flash > 0.0 else SKIN
	var dark: Color = Color.WHITE if _flash > 0.0 else SKIN_D
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(dir, 1.0))
	var step := 0
	if _moving:
		step = 1 if int(_anim * 5.0) % 2 == 0 else 0
	# kaki kurus
	draw_rect(Rect2(-2, -3 + step, 1, 3 - step), dark)
	draw_rect(Rect2(1, -3 + (1 - step), 1, 3 - (1 - step)), dark)
	# perut buncit
	draw_rect(Rect2(-3, -7, 6, 4), skin)
	draw_rect(Rect2(-2, -8, 4, 1), skin)
	draw_rect(Rect2(-3, -4, 6, 1), dark)
	# kepala besar
	draw_rect(Rect2(-2, -12, 5, 4), skin)
	draw_rect(Rect2(-2, -13, 3, 1), dark)
	draw_rect(Rect2(1, -11, 1, 1), EYE)
	draw_rect(Rect2(3, -11, 1, 1), EYE)
	draw_rect(Rect2(1, -9, 3, 1), MOUTH)
	# tangan menjulur
	var reach: int = 1 if int(_anim * 3.0) % 2 == 0 else 0
	draw_rect(Rect2(3, -7, 2 + reach, 1), dark)
	draw_set_transform(Vector2.ZERO)
	# bar nyawa kecil
	if hp < MAX_HP:
		draw_rect(Rect2(-3, -16, 6, 1), Color(0.2, 0.1, 0.1, 0.8))
		draw_rect(Rect2(-3, -16, 2 * hp, 1), EYE)
	# lingkaran Doa (lempar)
	if show_slots and can_take_coin():
		draw_texture_rect_region(preload("res://sprites/slots.png"), Rect2(Vector2(-2, -24), Vector2(5, 5)), Rect2(0, 0, 5, 5))
