extends Node2D
## Maneki-neko, roh penjaga gang.
## Kiri/kanan: jalan. Atas/bawah: naik/turun tangga. Aksi (tahan): tanam koin
## (bangun, rawat bangunan, cabut papan DIJUAL, perkuat pagar, uang rokok developer).
## Aksi di depan toko: "Lambaian Rezeki" (koin bonus, ada jeda).

enum State { GROUND, CLIMB, ROOF }

const SPEED := 52.0
const CLIMB_SPEED := 40.0
const DROP_INTERVAL := 0.22
const WAVE_COOLDOWN := 20.0

const ANIMS := {
	"idle": {"frames": [0, 1, 2, 3], "fps": 3.0},
	"walk": {"frames": [4, 5, 6, 7], "fps": 10.0},
	"climb": {"frames": [8, 9], "fps": 6.0},
	"wave": {"frames": [10, 11], "fps": 6.0},
}

var world: Node = null
var state := State.GROUND
var roof_building: Node = null # bangunan yang tangganya/atapnya sedang dipakai
var coins := 3
var max_coins := 8

var _drop_timer := 0.0
var _wave_cd := 0.0
var _wave_t := 0.0
var _anim := "idle"
var _anim_t := 0.0

@onready var sprite: Sprite2D = $Sprite2D


func _process(delta: float) -> void:
	if world == null or world.ended:
		return
	var h := Input.get_axis("move_left", "move_right")
	var v := Input.get_axis("move_up", "move_down")
	var moving := false
	_wave_cd = maxf(_wave_cd - delta, 0.0)
	_wave_t = maxf(_wave_t - delta, 0.0)

	match state:
		State.GROUND:
			if absf(h) > 0.1:
				position.x = clampf(position.x + h * SPEED * delta, 8.0, world.world_w - 8.0)
				moving = true
			if v < -0.5:
				var b = world.ladder_at(position.x)
				if b:
					roof_building = b
					state = State.CLIMB
					position.x = b.ladder_x()
		State.CLIMB:
			var b = roof_building
			if absf(v) > 0.1:
				position.y = clampf(position.y + v * CLIMB_SPEED * delta, b.roof_y(), 0.0)
				moving = true
			if position.y >= 0.0 and (v > 0.5 or absf(h) > 0.5):
				state = State.GROUND
				position.y = 0.0
			elif position.y <= b.roof_y() and absf(h) > 0.5:
				state = State.ROOF
		State.ROOF:
			var b = roof_building
			position.y = b.roof_y() # ikut naik kalau lantai bertambah
			if absf(h) > 0.1:
				position.x = clampf(position.x + h * SPEED * delta, b.position.x + 4.0, b.ladder_x())
				moving = true
			if v > 0.5 and absf(position.x - b.ladder_x()) < 4.0:
				state = State.CLIMB
				position.x = b.ladder_x()

	if absf(h) > 0.1 and state != State.CLIMB:
		sprite.flip_h = h < 0.0

	_handle_action(delta)
	_update_anim(delta, moving)


func _handle_action(delta: float) -> void:
	if not Input.is_action_pressed("action"):
		_drop_timer = 0.0
		return
	var target = world.build_target(self)
	if target and coins > 0:
		_drop_timer -= delta
		if _drop_timer <= 0.0:
			_drop_timer = DROP_INTERVAL
			coins -= 1
			target.add_coin()
	elif Input.is_action_just_pressed("action"):
		if target and coins == 0:
			world.say("Kantong kosong. Pungut koin dulu.")
		elif state == State.GROUND:
			_try_wave()


func _try_wave() -> void:
	var shop = world.shop_near(position.x)
	if shop == null:
		return
	if not world.is_open():
		world.say("Toko sudah tutup.")
	elif _wave_cd > 0.0:
		world.say("Lambaian belum siap (%d dtk)" % ceili(_wave_cd))
	else:
		_wave_cd = WAVE_COOLDOWN
		_wave_t = 0.8
		shop.lucky_wave()
		world.sfx.play("wave")
		world.say("Lambaian Rezeki!")


func _update_anim(delta: float, moving: bool) -> void:
	var next := "idle"
	if _wave_t > 0.0:
		next = "wave"
	elif state == State.CLIMB:
		next = "climb"
	elif moving:
		next = "walk"
	if next != _anim:
		_anim = next
		_anim_t = 0.0
	if next != "climb" or moving:
		_anim_t += delta
	var a: Dictionary = ANIMS[_anim]
	var frames: Array = a["frames"]
	sprite.frame = frames[int(_anim_t * float(a["fps"])) % frames.size()]
