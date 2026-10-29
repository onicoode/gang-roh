extends Node2D
## Tsukumogami: benda tua yang hidup karena dirawat. Lahir tiap malam dari bangunan
## (jumlah sesuai lantai & kondisi), menjaga sekitar rumahnya, melawan yōkai.
## - Bakezōri (sandal): cepat, serangan dekat.
## - Karakasa (payung): kuat menahan serangan, serangan dekat.
## - Chōchin (lentera): lemah, menembak api dari jauh.

enum Kind { ZORI, KASA, CHOCHIN }

const LEASH := 56.0 # jarak maksimal dari rumah
const AGGRO := 50.0 # jarak melihat yōkai

## Kind: [hp, kecepatan, jangkauan, jeda serang]
const STATS := {
	Kind.ZORI: [3, 26.0, 6.0, 0.8],
	Kind.KASA: [6, 16.0, 7.0, 1.1],
	Kind.CHOCHIN: [2, 14.0, 40.0, 1.6],
}

const STRAW := Color("d8b878")
const STRAW_D := Color("a0804a")
const STRAP := Color("b03838")
const KASA := Color("8a3a6a")
const KASA_D := Color("5a2448")
const WOOD := Color("7a5230")
const PAPER := Color("f2a64a")
const PAPER_L := Color("ffd890")
const RIB := Color("a0602a")
const EYE := Color("1a1418")
const WHITE := Color("f4f0e6")
const TONGUE := Color("e05060")
const FIRE := Color("ffb040")
const SHADOW := Color(0, 0, 0, 0.3)

var world: Node = null
var kind := Kind.ZORI
var home_x := 0.0
var hp := 3
var dead := false
var leaving := false

var _max_hp := 3
var _speed := 20.0
var _range := 6.0
var _cd_time := 1.0
var _cd := 0.0
var _dir := 1
var _anim := 0.0
var _flash := 0.0
var _moving := false
var _wander := 0.0
var _bolt_t := 0.0
var _bolt_to := Vector2.ZERO


func _ready() -> void:
	var st: Array = STATS[kind]
	_max_hp = int(st[0])
	hp = _max_hp
	_speed = float(st[1])
	_range = float(st[2])
	_cd_time = float(st[3])
	_anim = randf() * 3.0
	_wander = home_x + randf_range(-20.0, 20.0)
	modulate.a = 0.0 # muncul perlahan


func _process(delta: float) -> void:
	if world.ended:
		return
	_anim += delta
	_flash = maxf(_flash - delta, 0.0)
	_bolt_t = maxf(_bolt_t - delta, 0.0)
	_moving = false
	if leaving:
		modulate.a -= delta
		if modulate.a <= 0.0:
			queue_free()
		queue_redraw()
		return
	modulate.a = minf(modulate.a + delta * 2.0, 1.0)
	_cd -= delta
	var target: Node = world.nearest_yokai(position.x, AGGRO)
	if target != null and absf(target.position.x - home_x) > LEASH + _range:
		target = null
	if target != null:
		var dx: float = target.position.x - position.x
		_dir = 1 if dx > 0.0 else -1
		if absf(dx) > _range:
			_move(_dir, delta)
		elif _cd <= 0.0:
			_cd = _cd_time
			_attack(target)
	else:
		# berkeliling di sekitar rumah
		if absf(_wander - position.x) < 2.0:
			_wander = home_x + randf_range(-24.0, 24.0)
		var d: float = _wander - position.x
		_dir = 1 if d > 0.0 else -1
		_move(_dir, delta * 0.5)
	queue_redraw()


func _move(dir: int, delta: float) -> void:
	var nx := position.x + dir * _speed * delta
	position.x = clampf(nx, home_x - LEASH, home_x + LEASH)
	position.x = clampf(position.x, 4.0, float(world.world_w) - 4.0)
	_moving = true


func _attack(target: Node) -> void:
	if kind == Kind.CHOCHIN:
		_bolt_t = 0.2
		_bolt_to = target.position + Vector2(0, -6) - position
		world.sfx.play("fire")
	target.take_hit(1)


func take_hit(dmg: int) -> void:
	if dead or leaving:
		return
	hp -= dmg
	_flash = 0.15
	if hp <= 0:
		dead = true
		world.pop_text(position + Vector2(0, -14), "tertidur", Color("d0c8e0"))
		world.sfx.play("poof")
		queue_free()


func fade() -> void:
	leaving = true


# ---------------------------------------------------------------- gambar

func _draw() -> void:
	var hop := 0.0
	if kind != Kind.CHOCHIN and _moving:
		hop = -absf(sin(_anim * 10.0)) * 2.0
	draw_rect(Rect2(-3, 0, 7, 1), SHADOW)
	draw_set_transform(Vector2(0, roundf(hop)), 0.0, Vector2(_dir, 1.0))
	var fl := _flash > 0.0
	match kind:
		Kind.ZORI:
			_draw_zori(fl)
		Kind.KASA:
			_draw_kasa(fl)
		Kind.CHOCHIN:
			_draw_chochin(fl)
	draw_set_transform(Vector2.ZERO)
	if _bolt_t > 0.0:
		var a := Vector2(0, -8)
		var b := _bolt_to
		draw_line(a, a.lerp(b, 0.5), FIRE, 1.0)
		draw_rect(Rect2(b - Vector2(1, 1), Vector2(2, 2)), PAPER_L)
	if hp < _max_hp:
		var w := _max_hp * 1.0
		draw_rect(Rect2(-w / 2.0, -18, w, 1), Color(0.1, 0.1, 0.2, 0.8))
		draw_rect(Rect2(-w / 2.0, -18, hp, 1), Color("9fe0a0"))


func _c(col: Color, fl: bool) -> Color:
	return Color.WHITE if fl else col


func _draw_zori(fl: bool) -> void:
	# sandal jerami berdiri, bermata satu, bertangan kecil
	draw_rect(Rect2(-3, -8, 6, 8), _c(STRAW, fl))
	draw_rect(Rect2(-3, -1, 6, 1), _c(STRAW_D, fl))
	draw_rect(Rect2(-2, -9, 4, 1), _c(STRAW, fl))
	draw_rect(Rect2(-1, -7, 2, 3), _c(STRAP, fl))
	draw_rect(Rect2(0, -6, 2, 2), WHITE)
	draw_rect(Rect2(1, -6, 1, 1), EYE)
	var wave: int = 1 if int(_anim * 4.0) % 2 == 0 else 0
	draw_rect(Rect2(3, -5 - wave, 2, 1), _c(STRAW_D, fl))
	draw_rect(Rect2(-5, -5, 2, 1), _c(STRAW_D, fl))


func _draw_kasa(fl: bool) -> void:
	# payung tertutup bermata satu, lidah menjulur, satu kaki kayu
	draw_rect(Rect2(0, -4, 1, 4), _c(WOOD, fl))
	draw_rect(Rect2(-1, -1, 3, 1), _c(WOOD, fl))
	draw_rect(Rect2(-3, -8, 7, 4), _c(KASA, fl))
	draw_rect(Rect2(-2, -11, 5, 3), _c(KASA, fl))
	draw_rect(Rect2(-1, -13, 3, 2), _c(KASA, fl))
	draw_rect(Rect2(0, -15, 1, 2), _c(WOOD, fl))
	draw_rect(Rect2(-3, -5, 7, 1), _c(KASA_D, fl))
	draw_rect(Rect2(0, -10, 3, 2), WHITE)
	draw_rect(Rect2(1, -10, 1, 2), EYE)
	var lick: int = 1 if int(_anim * 3.0) % 2 == 0 else 0
	draw_rect(Rect2(2, -7, 1, 2 + lick), TONGUE)


func _draw_chochin(fl: bool) -> void:
	# lentera kertas melayang, menyala
	var by := roundf(sin(_anim * 3.0) * 1.5) - 6.0
	draw_rect(Rect2(-4, by - 6, 8, 8), Color(1, 0.7, 0.3, 0.18))
	draw_rect(Rect2(-1, by - 8, 3, 1), _c(EYE, fl))
	draw_rect(Rect2(-3, by - 7, 6, 7), _c(PAPER, fl))
	draw_rect(Rect2(-2, by - 7, 4, 7), _c(PAPER_L, fl))
	draw_rect(Rect2(-3, by - 5, 6, 1), _c(RIB, fl))
	draw_rect(Rect2(-3, by - 2, 6, 1), _c(RIB, fl))
	draw_rect(Rect2(-1, by, 3, 1), _c(EYE, fl))
	draw_rect(Rect2(1, by - 6, 1, 1), EYE)
	draw_rect(Rect2(0, by - 4, 2, 1), EYE)
	draw_rect(Rect2(1, by - 3, 1, 2), TONGUE)
