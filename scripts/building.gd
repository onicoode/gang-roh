extends Node2D
## Satu petak bangunan. floors = 0 berarti tanah kosong.
## Lantai 1 = toko (koin selama siang), lantai 2+ = apartemen (sewa tiap awal bulan).

const W := 48
const FLOOR_H := 32
const MAX_FLOORS := 5
const SHOP_INTERVAL := 14.0

const TEX_LOT := preload("res://sprites/lot.png")
const TEX_SHOP := preload("res://sprites/shop.png")
const TEX_SHOP_LIGHT := preload("res://sprites/shop_lights.png")
const TEX_APT := preload("res://sprites/apt.png")
const TEX_APT_LIGHT := preload("res://sprites/apt_lights.png")
const TEX_ROOF := preload("res://sprites/roof.png")
const TEX_TANK := preload("res://sprites/tank.png")
const TEX_LADDER := preload("res://sprites/ladder.png")
const TEX_SCAFFOLD := preload("res://sprites/scaffold.png")
const TEX_AC := preload("res://sprites/ac.png")
const TEX_PLANT := preload("res://sprites/plant.png")
const TEX_LAUNDRY := preload("res://sprites/laundry.png")
const TEX_SLOTS := preload("res://sprites/slots.png")
const WIND_SHADER := preload("res://shaders/wind.gdshader")

var world: Node = null
var style := 0
var floors := 0
var paid := 0 # koin yang sudah ditanam untuk pembangunan berikutnya
var constructing := false # selesai di awal bulan berikutnya
var show_slots := false:
	set(v):
		if v != show_slots:
			show_slots = v
			queue_redraw()

var _parts: Array[Node] = []
var _acs: Array[Sprite2D] = []
var _ac_t := 0.0
var _shop_timer := 0.0
var _wind_mat: ShaderMaterial


func _ready() -> void:
	_wind_mat = ShaderMaterial.new()
	_wind_mat.shader = WIND_SHADER
	_wind_mat.set_shader_parameter("strength", 1.5)
	_shop_timer = randf_range(2.0, SHOP_INTERVAL)
	rebuild()


func _process(delta: float) -> void:
	# kipas AC berputar
	_ac_t += delta
	if _ac_t > 0.08:
		_ac_t = 0.0
		for ac in _acs:
			ac.frame = 1 - ac.frame
	# toko menghasilkan koin selama jam buka
	if floors >= 1 and world and world.is_open():
		_shop_timer -= delta
		if _shop_timer <= 0.0:
			_shop_timer = SHOP_INTERVAL * randf_range(0.8, 1.2)
			world.spawn_coin(Vector2(door_x(), -2))


# ---------------------------------------------------------------- query

func cost() -> int:
	return 4 if floors == 0 else 4 + floors * 3


func can_build_more() -> bool:
	return not constructing and floors < MAX_FLOORS


func roof_y() -> float:
	return -floors * FLOOR_H


func ladder_x() -> float:
	return position.x + W + 3


func door_x() -> float:
	return position.x + 35


func center_x() -> float:
	return position.x + W / 2.0


# ---------------------------------------------------------------- aksi

func add_coin() -> void:
	paid += 1
	if paid >= cost():
		paid = 0
		constructing = true
		world.say("Pembangunan dimulai! Selesai bulan depan.")
		rebuild()
	queue_redraw()


func lucky_wave() -> void:
	for i in 3:
		world.spawn_coin(Vector2(door_x(), -2))


func on_new_month() -> void:
	if constructing:
		constructing = false
		floors += 1
		rebuild()
		world.say("Toko baru buka!" if floors == 1 else "Lantai %d berdiri!" % floors)
	# sewa apartemen
	for i in maxi(floors - 1, 0):
		world.spawn_coin(Vector2(door_x(), -2))


# ---------------------------------------------------------------- visual

func rebuild() -> void:
	for p in _parts:
		p.queue_free()
	_parts.clear()
	_acs.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = int(position.x) * 7919 + style

	if floors == 0:
		_add(TEX_LOT, 1, 0, Vector2(0, -16))
	else:
		_add(TEX_SHOP, 3, style, Vector2(0, -FLOOR_H))
		_add_light(TEX_SHOP_LIGHT, style, Vector2(0, -FLOOR_H))
		for f in range(1, floors):
			var y := -(f + 1) * FLOOR_H
			_add(TEX_APT, 3, style, Vector2(0, y))
			_add_light(TEX_APT_LIGHT, style, Vector2(0, y))
			if rng.randf() < 0.6:
				_acs.append(_add(TEX_AC, 2, 0, Vector2(rng.randi_range(30, 35), y + 5)))
			match rng.randi() % 3:
				0:
					_add(TEX_LAUNDRY, 1, 0, Vector2(rng.randi_range(6, 24), y + 7), _wind_mat)
				1:
					_add(TEX_PLANT, 2, rng.randi() % 2, Vector2(rng.randi_range(4, 36), y + 6), _wind_mat)
		_add(TEX_ROOF, 3, style, Vector2(0, roof_y() - 10))
		if floors >= 3:
			_add(TEX_TANK, 1, 0, Vector2(6, roof_y() - 22))
		var lad := Sprite2D.new()
		lad.texture = TEX_LADDER
		lad.centered = false
		lad.region_enabled = true
		lad.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		lad.region_rect = Rect2(0, 0, 6, floors * FLOOR_H)
		lad.position = Vector2(W, roof_y())
		add_child(lad)
		_parts.append(lad)

	if constructing:
		var sy: float = -FLOOR_H if floors == 0 else roof_y() - FLOOR_H
		_add(TEX_SCAFFOLD, 1, 0, Vector2(0, sy))
	queue_redraw()


func _add(tex: Texture2D, hframes: int, frame: int, pos: Vector2, mat: Material = null) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.hframes = hframes
	s.frame = frame
	s.position = pos
	s.material = mat
	add_child(s)
	_parts.append(s)
	return s


func _add_light(tex: Texture2D, frame: int, pos: Vector2) -> void:
	# lampu jendela ada di layer terpisah supaya tidak ikut digelapkan malam
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.hframes = 3
	s.frame = frame
	s.position = position + pos
	world.lights.add_child(s)
	_parts.append(s)


func _draw() -> void:
	# lingkaran koin di atas titik bangun
	if not show_slots or not can_build_more():
		return
	var n := cost()
	var y: float = -22.0 if floors == 0 else roof_y() - 18.0
	var start_x := W / 2.0 - n * 3.0
	for i in n:
		var src := Rect2(5 if i < paid else 0, 0, 5, 5)
		draw_texture_rect_region(TEX_SLOTS, Rect2(Vector2(start_x + i * 6, y), Vector2(5, 5)), src)
