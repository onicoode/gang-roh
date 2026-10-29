extends Node2D
## Warga (manusia). Keluar dari rumah atau datang dari ujung gang, berjalan ke tempat doa
## (kuil pusat atau hokora di depan bangunan), berdoa sebentar, lalu pulang.
## Doa hanya muncul dari warga yang sedang berdoa: inilah sumber energi roh.

enum St { WALK, PRAY, BACK }

const SPEED := 14.0
const PRAY_TIME := 2.6
const HOME_T := 0.66 # menjelang malam semua warga pulang

const SKINS: Array[Color] = [Color("f0c8a0"), Color("d8a878"), Color("c08a60")]
const HAIRS: Array[Color] = [Color("2a2228"), Color("4a3428"), Color("8a8a8a")]
const SHIRTS: Array[Color] = [Color("d05a5a"), Color("5a8ad0"), Color("e0b040"), Color("6ab07a"), Color("b07ad0"), Color("e8e4dc")]
const PANTS: Array[Color] = [Color("3a3f5a"), Color("4a3a30"), Color("2a2a2a")]
const SHADOW := Color(0, 0, 0, 0.3)

var world: Node = null
var start_x := 0.0 # tempat muncul & pulang
var spot_x := 0.0 # tempat berdoa
var amount := 1 # Doa yang muncul saat selesai berdoa
var from_edge := false # pengunjung dari luar gang

var _state := St.WALK
var _t := 0.0
var _anim := 0.0
var _dir := 1
var _skin := Color.WHITE
var _hair := Color.WHITE
var _shirt := Color.WHITE
var _pants := Color.WHITE
var _tall := 0


func _ready() -> void:
	_skin = SKINS.pick_random()
	_hair = HAIRS.pick_random()
	_shirt = SHIRTS.pick_random()
	_pants = PANTS.pick_random()
	_tall = randi() % 2
	_anim = randf() * 3.0
	spot_x += randf_range(-3.0, 3.0)
	modulate.a = 0.0


func _process(delta: float) -> void:
	if world.ended:
		return
	_anim += delta
	if _state != St.BACK and world.day_t >= HOME_T:
		_state = St.BACK
	match _state:
		St.WALK:
			modulate.a = minf(modulate.a + delta * 3.0, 1.0)
			if _walk_to(spot_x, delta):
				_state = St.PRAY
				_t = 0.0
		St.PRAY:
			_t += delta
			if _t >= PRAY_TIME:
				for i in amount:
					world.spawn_coin(position + Vector2(0, -12))
				world.sfx.play("pray")
				_state = St.BACK
		St.BACK:
			var sp: float = 1.6 if world.day_t >= HOME_T else 1.0
			if _walk_to(start_x, delta * sp):
				modulate.a -= delta * 3.0
				if modulate.a <= 0.0:
					queue_free()
	queue_redraw()


## Jalan ke x. Mengembalikan true kalau sudah sampai.
func _walk_to(x: float, delta: float) -> bool:
	var d := x - position.x
	if absf(d) < 1.0:
		return true
	_dir = 1 if d > 0.0 else -1
	position.x += _dir * minf(SPEED * delta, absf(d))
	return false


func is_praying() -> bool:
	return _state == St.PRAY


func _draw() -> void:
	draw_rect(Rect2(-3, 0, 6, 1), SHADOW)
	if _state == St.PRAY:
		_draw_pray()
		return
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(_dir, 1.0))
	var step: int = 1 if int(_anim * 6.0) % 2 == 0 else -1
	var h := _tall
	draw_rect(Rect2(-2 + step, -4, 1, 4), _pants)
	draw_rect(Rect2(1 - step, -4, 1, 4), _pants)
	draw_rect(Rect2(-2, -9 - h, 4, 5 + h), _shirt)
	draw_rect(Rect2(-2, -12 - h, 4, 3), _skin)
	draw_rect(Rect2(-2, -13 - h, 4, 1), _hair)
	draw_rect(Rect2(-2, -12 - h, 1, 2), _hair)
	draw_rect(Rect2(1, -11 - h, 1, 1), Color("2a2228"))
	draw_set_transform(Vector2.ZERO)


func _draw_pray() -> void:
	# membungkuk, tangan dirapatkan, cahaya kecil naik
	var h := _tall
	var bow: int = 1 if fmod(_t, 1.3) < 0.65 else 0
	draw_rect(Rect2(-2, -4, 1, 4), _pants)
	draw_rect(Rect2(1, -4, 1, 4), _pants)
	draw_rect(Rect2(-2, -9 - h + bow, 4, 5 + h - bow), _shirt)
	draw_rect(Rect2(-2, -12 - h + bow, 4, 3), _skin)
	draw_rect(Rect2(-2, -13 - h + bow, 4, 1), _hair)
	draw_rect(Rect2(0, -9 - h + bow, 1, 2), _skin) # tangan
	var glow := fmod(_t * 8.0, 8.0)
	draw_rect(Rect2(0, -16 - h - glow, 1, 1), Color(0.75, 0.92, 1.0, 1.0 - glow / 8.0))
