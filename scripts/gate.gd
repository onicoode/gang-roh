extends Node2D
## Pagar bambu di ujung gang. Menahan developer di malam hari.
## Tanam koin di dekatnya: tiap koin = +1 kekuatan (maks MAX_HP).
## Developer yang mendorong pagar mengurangi kekuatan sedikit demi sedikit.

const MAX_HP := 4
const W := 14

const POST := Color("6b4a32")
const POST_D := Color("4a3222")
const BAMBOO := Color("b9a75a")
const BAMBOO_D := Color("8a7a3a")
const ROPE := Color("d8cfb0")
const SLOT := preload("res://sprites/slots.png")

var world: Node = null
var hp := 0
var show_slots := false:
	set(v):
		if v != show_slots:
			show_slots = v
			queue_redraw()

var _shake := 0.0


func _process(delta: float) -> void:
	if _shake > 0.0:
		_shake = maxf(_shake - delta, 0.0)
		queue_redraw()


# ---------------------------------------------------------------- dipakai kucing (sama seperti bangunan)

func cost() -> int:
	return MAX_HP - hp


func add_coin() -> void:
	hp = mini(hp + 1, MAX_HP)
	if hp == MAX_HP:
		world.say("Pagar kokoh!")
	world.sfx.play("repair")
	queue_redraw()


func can_take_coin() -> bool:
	return hp < MAX_HP


## Didorong developer. Mengembalikan true kalau pagar jebol.
func hit() -> bool:
	hp = maxi(hp - 1, 0)
	_shake = 0.25
	queue_redraw()
	return hp == 0


func _draw() -> void:
	var sx: float = roundf(sin(_shake * 60.0)) if _shake > 0.0 else 0.0
	var x0 := -W / 2.0 + sx
	# tiang
	var post_h: float = 16.0 if hp > 0 else 6.0
	for px: float in [x0, x0 + W - 3.0]:
		draw_rect(Rect2(px, -post_h, 3, post_h), POST)
		draw_rect(Rect2(px + 2.0, -post_h, 1, post_h), POST_D)
	# batang bambu sesuai kekuatan
	for i in hp:
		var y := -4.0 - i * 3.0
		draw_rect(Rect2(x0 - 1.0, y - 2.0, W + 2.0, 2), BAMBOO)
		draw_rect(Rect2(x0 - 1.0, y - 1.0, W + 2.0, 1), BAMBOO_D)
	if hp > 0:
		draw_rect(Rect2(x0 + 1.0, -post_h + 2.0, 1, 2), ROPE)
		draw_rect(Rect2(x0 + W - 2.0, -post_h + 2.0, 1, 2), ROPE)
	# lingkaran koin
	if show_slots and hp < MAX_HP:
		var n := cost()
		var start := -n * 3.0
		for i in n:
			draw_texture_rect_region(SLOT, Rect2(Vector2(start + i * 6, -26), Vector2(5, 5)), Rect2(0, 0, 5, 5))
