extends Node2D
## Developer rakus. Datang malam hari dari ujung gang, mengincar petak kosong
## atau bangunan bobrok, lalu memasang papan DIJUAL. Kalau papan itu masih ada
## saat dia datang lagi, petak digusur.
## Cara mengusir: pagar di ujung gang, atau "uang rokok" (tanam Doa di dekatnya).

enum St { WALK, PUSH, WORK, LEAVE }

const SPEED := 16.0
const PUSH_TIME := 7.0 # detik per dorongan ke pagar (pagar penuh ≈ tahan satu malam)
const WORK_TIME := 3.0 # lama memasang papan / menggusur
const SLOT := preload("res://sprites/slots.png")

const SKIN := Color("f0c8a0")
const HAIR := Color("2a2228")
const SUIT := Color("3a3f5a")
const SUIT_D := Color("262a3e")
const SHIRT := Color("eeeeee")
const TIE := Color("c03040")
const SHOE := Color("141414")
const CASE := Color("7a5230")
const SHADOW := Color(0, 0, 0, 0.3)

var world: Node = null
var dir := 1 # +1 = berjalan dari kiri ke kanan
var gate: Node = null # pagar di ujung asalnya
var state := St.WALK
var target: Node = null
var paid := 0
var bribe_cost := 3
var show_slots := false:
	set(v):
		if v != show_slots:
			show_slots = v
			queue_redraw()

var _t := 0.0
var _anim := 0.0
var _moving := false


func _process(delta: float) -> void:
	if world.ended:
		return
	_anim += delta
	_moving = false
	match state:
		St.WALK:
			_walk(delta)
		St.PUSH:
			_t += delta
			if gate.hp <= 0:
				state = St.WALK
			elif _t >= PUSH_TIME:
				_t = 0.0
				var near: bool = absf(world.player.position.x - position.x) < 120.0
				world.sfx.play("bonk")
				if near:
					world.shake(1.0)
				if gate.hit():
					world.say("Pagar jebol! Developer masuk gang.")
					state = St.WALK
		St.WORK:
			_t += delta
			if _t >= WORK_TIME:
				if target != null and world.dev_wants(target):
					world.dev_claim(target)
				leave()
		St.LEAVE:
			position.x -= dir * SPEED * 1.5 * delta
			_moving = true
			if position.x < -16.0 or position.x > float(world.world_w) + 16.0:
				queue_free()
	queue_redraw()


func _walk(delta: float) -> void:
	# pagar di depan dan masih berdiri → dorong
	if gate != null and gate.hp > 0:
		var to_gate: float = (gate.position.x - position.x) * dir
		if to_gate > 0.0 and to_gate <= 10.0:
			state = St.PUSH
			_t = 0.0
			return
	if target == null or not world.dev_wants(target):
		target = world.dev_next_target(position.x, dir)
		if target == null:
			# tidak ada yang bisa dibeli → jalan terus sampai ujung lain, lalu pergi
			if (dir > 0 and position.x > float(world.world_w) - 20.0) or (dir < 0 and position.x < 20.0):
				leave()
				return
	var tx: float = target.center_x() if target != null else position.x + dir * 100.0
	position.x += dir * SPEED * delta
	_moving = true
	if target != null and (tx - position.x) * dir <= 0.0:
		position.x = tx
		state = St.WORK
		_t = 0.0


func leave() -> void:
	if state == St.LEAVE:
		return
	state = St.LEAVE
	show_slots = false


# ---------------------------------------------------------------- uang rokok (dipakai kucing)

func cost() -> int:
	return bribe_cost


func can_take_coin() -> bool:
	return state != St.LEAVE


func add_coin() -> void:
	paid += 1
	world.sfx.play("bribe")
	if paid >= bribe_cost:
		world.say("Developer menerima uang rokok dan pergi... untuk malam ini.")
		world.pop_text(position + Vector2(0, -22), "pergi!", Color("ffd36a"))
		leave()
	queue_redraw()


# ---------------------------------------------------------------- gambar (pixel art sederhana)

func _draw() -> void:
	draw_rect(Rect2(-4, 0, 9, 1), SHADOW)
	var face: float = 1.0 if state != St.LEAVE else -1.0
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(dir * face, 1.0))
	var step := 0
	if _moving:
		step = 1 if int(_anim * 6.0) % 2 == 0 else -1
	# kaki
	draw_rect(Rect2(-2 + step, -6, 2, 6), SUIT_D)
	draw_rect(Rect2(1 - step, -6, 2, 6), SUIT_D)
	draw_rect(Rect2(-2 + step, -1, 2, 1), SHOE)
	draw_rect(Rect2(1 - step, -1, 3, 1), SHOE)
	# badan + kemeja + dasi
	draw_rect(Rect2(-3, -13, 6, 7), SUIT)
	draw_rect(Rect2(1, -13, 2, 2), SHIRT)
	draw_rect(Rect2(2, -12, 1, 4), TIE)
	# kepala, rambut klimis, kacamata hitam
	draw_rect(Rect2(-2, -17, 5, 4), SKIN)
	draw_rect(Rect2(-2, -18, 5, 1), HAIR)
	draw_rect(Rect2(-2, -17, 2, 2), HAIR)
	draw_rect(Rect2(1, -16, 3, 1), SHOE)
	# tangan
	match state:
		St.PUSH:
			var push: int = 1 if int(_anim * 4.0) % 2 == 0 else 0
			draw_rect(Rect2(3, -11, 2 + push, 2), SUIT_D)
			draw_rect(Rect2(5 + push, -11, 1, 2), SKIN)
		St.WORK:
			var up: int = 2 if int(_anim * 5.0) % 2 == 0 else 0
			draw_rect(Rect2(3, -12 - up, 2, 3), SUIT_D)
			draw_rect(Rect2(3, -13 - up, 2, 1), SKIN)
		_:
			draw_rect(Rect2(-1, -12, 2, 5), SUIT_D)
			draw_rect(Rect2(-2, -6, 5, 4), CASE)
			draw_rect(Rect2(-1, -7, 3, 1), SHOE)
	draw_set_transform(Vector2.ZERO)
	# lingkaran koin uang rokok
	if show_slots and can_take_coin():
		var start := -bribe_cost * 3.0
		for i in bribe_cost:
			var src := Rect2(5 if i < paid else 0, 0, 5, 5)
			draw_texture_rect_region(SLOT, Rect2(Vector2(start + i * 6, -26), Vector2(5, 5)), src)
