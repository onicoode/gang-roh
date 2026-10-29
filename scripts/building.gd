extends Node2D
## Satu petak bangunan. floors = 0 berarti tanah kosong.
## Lantai 1 = toko (koin selama siang), lantai 2+ = apartemen (sewa tiap awal bulan).
## Bangunan menua tiap bulan (condition turun). Kusam = koin berkurang, bobrok = tidak
## menghasilkan dan jadi incaran developer. Rawat dengan menanam koin di depan pintu.

const W := 48
const FLOOR_H := 32
const MAX_FLOORS := 5
const SHOP_INTERVAL := 14.0
const REPAIR_AT := 75.0 # di bawah ini bangunan bisa dirawat
const DULL := 60.0 # di bawah ini kusam
const RUIN := 30.0 # di bawah ini bobrok
const CLEANSE_COST := 3 # cabut papan DIJUAL
const RECLAIM_COST := 10 # rebut kembali petak yang digusur

enum Job { NONE, BUILD, REPAIR, CLEANSE, RECLAIM }

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
var constructing := false # selesai di awal bulan berikutnya
var condition := 100.0 # 0..100, turun tiap bulan
var signed := false # papan DIJUAL dari developer
var owned := false # sudah digusur, milik developer
var job := Job.NONE # tugas koin saat ini (diatur world.build_target lewat set_job)
var job_on_roof := false
var show_slots := false:
	set(v):
		if v != show_slots:
			show_slots = v
			if _overlay:
				_overlay.queue_redraw()

var _parts: Array[Node] = []
var _acs: Array[Sprite2D] = []
var _ac_t := 0.0
var _shop_timer := 0.0
var _wind_mat: ShaderMaterial
var _paid: Dictionary = {} # koin tertanam per jenis tugas
var _overlay: Node2D


func _ready() -> void:
	_wind_mat = ShaderMaterial.new()
	_wind_mat.shader = WIND_SHADER
	_wind_mat.set_shader_parameter("strength", 1.5)
	_shop_timer = randf_range(2.0, SHOP_INTERVAL)
	_overlay = Node2D.new()
	_overlay.draw.connect(_draw_overlay)
	add_child(_overlay)
	rebuild()


func _process(delta: float) -> void:
	# kipas AC berputar
	_ac_t += delta
	if _ac_t > 0.08:
		_ac_t = 0.0
		for ac in _acs:
			ac.frame = 1 - ac.frame
	# toko menghasilkan koin selama jam buka
	if floors >= 1 and world and world.is_open() and condition >= RUIN:
		_shop_timer -= delta
		if _shop_timer <= 0.0:
			var slow: float = 1.6 if condition < DULL else 1.0
			_shop_timer = SHOP_INTERVAL * slow * randf_range(0.8, 1.2)
			world.spawn_coin(Vector2(door_x(), -2))


# ---------------------------------------------------------------- query

## Tugas koin yang tersedia dari tanah (on_roof = false) atau dari atap.
func job_for(on_roof: bool) -> Job:
	if owned:
		return Job.NONE if on_roof else Job.RECLAIM
	if signed:
		return Job.CLEANSE
	if floors > 0 and condition < REPAIR_AT:
		return Job.REPAIR
	if can_build_more() and on_roof == (floors > 0):
		return Job.BUILD
	return Job.NONE


func set_job(j: Job, on_roof: bool) -> void:
	if j != job or on_roof != job_on_roof:
		job = j
		job_on_roof = on_roof
		if _overlay:
			_overlay.queue_redraw()


func cost() -> int:
	match job:
		Job.RECLAIM:
			return RECLAIM_COST
		Job.CLEANSE:
			return CLEANSE_COST
		Job.REPAIR:
			return maxi(ceili((REPAIR_AT + 1.0 - condition) / 25.0), 1)
	return 4 if floors == 0 else 4 + floors * 3


func paid() -> int:
	return int(_paid.get(job, 0))


func can_build_more() -> bool:
	return not constructing and not owned and floors < MAX_FLOORS


## Incaran developer: tanah kosong, atau bangunan bobrok.
func vulnerable() -> bool:
	if owned:
		return false
	if floors == 0:
		return not constructing
	return condition < RUIN


func state_name() -> String:
	if condition < RUIN:
		return "bobrok"
	if condition < DULL:
		return "kusam"
	return "terawat"


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
	if job == Job.REPAIR:
		condition = minf(condition + 25.0, 100.0)
		world.sfx.play("repair")
		world.pop_text(Vector2(center_x(), roof_y() - 12.0), "dirawat", Color("9fe0a0"))
		if condition >= REPAIR_AT:
			world.say("Bangunan kembali terawat.")
		rebuild()
		return
	var n := paid() + 1
	world.sfx.play("drop")
	if n < cost():
		_paid[job] = n
		_overlay.queue_redraw()
		return
	_paid[job] = 0
	match job:
		Job.BUILD:
			constructing = true
			world.sfx.play("build")
			world.say("Pembangunan dimulai! Selesai bulan depan.")
		Job.CLEANSE:
			signed = false
			world.sfx.play("build")
			world.say("Papan DIJUAL dicabut!")
		Job.RECLAIM:
			owned = false
			condition = 100.0
			world.sfx.play("floor")
			world.say("Petak berhasil direbut kembali!")
	rebuild()


## Developer memasang papan DIJUAL.
func put_sign() -> void:
	signed = true
	rebuild()


## Digusur developer: bangunan hilang, petak jadi milik developer.
func evict() -> void:
	owned = true
	signed = false
	constructing = false
	floors = 0
	condition = 100.0
	_paid.clear()
	rebuild()


func lucky_wave() -> void:
	for i in 3:
		world.spawn_coin(Vector2(door_x(), -2))


func on_new_month() -> void:
	if constructing:
		constructing = false
		floors += 1
		condition = minf(condition + 30.0, 100.0)
		rebuild()
		world.say("Toko baru buka!" if floors == 1 else "Lantai %d berdiri!" % floors)
		world.sfx.play("floor")
		world.shake(1.5)
	elif floors > 0:
		# menua: makin tinggi makin cepat
		condition = maxf(condition - randf_range(14.0, 22.0) - floors * 2.0, 0.0)
		if condition <= 0.0 and floors > 1:
			floors -= 1
			condition = RUIN
			world.say("Penghuni lantai atas pindah... bangunan terlalu bobrok.")
		rebuild()
	# sewa apartemen (bangunan bobrok tidak bayar sewa)
	if condition >= RUIN:
		for i in maxi(floors - 1, 0):
			world.spawn_coin(Vector2(door_x(), -2))


# ---------------------------------------------------------------- visual

func rebuild() -> void:
	for p in _parts:
		p.queue_free()
	_parts.clear()
	_acs.clear()
	# makin tua makin kusam
	var k := 1.0 - condition / 100.0
	modulate = Color(1, 1, 1).lerp(Color(0.66, 0.6, 0.56), k) if floors > 0 else Color(1, 1, 1)
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
	if _overlay:
		move_child(_overlay, -1)
		_overlay.queue_redraw()


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
	if condition < RUIN:
		s.modulate.a = 0.0 # bobrok: lampu mati
	elif condition < DULL:
		s.modulate.a = 0.55
	world.lights.add_child(s)
	_parts.append(s)


## Digambar di atas sprite: retakan, papan DIJUAL, pagar proyek, lingkaran koin.
func _draw_overlay() -> void:
	var o := _overlay
	if floors > 0 and condition < DULL:
		# noda dan retakan
		var rng := RandomNumberGenerator.new()
		rng.seed = int(position.x) * 31 + floors
		var n: int = 3 if condition >= RUIN else 7
		for i in n:
			var x := rng.randi_range(3, W - 6)
			var y := -rng.randi_range(4, floors * FLOOR_H - 4)
			o.draw_rect(Rect2(x, y, 1, 3), Color(0.2, 0.16, 0.14, 0.55))
			o.draw_rect(Rect2(x + 1, y + 2, 1, 2), Color(0.2, 0.16, 0.14, 0.55))
			if condition < RUIN:
				o.draw_rect(Rect2(x - 2, y + 3, 4, 3), Color(0.35, 0.4, 0.3, 0.35))
	if owned:
		# pagar seng proyek milik developer
		for i in 6:
			var c: Color = Color("8a96a8") if i % 2 == 0 else Color("76829a")
			o.draw_rect(Rect2(i * 8, -14, 8, 14), c)
		for i in 12:
			o.draw_rect(Rect2(i * 4, -14, 2, 2), Color("e8c040") if i % 2 == 0 else Color("202020"))
		o.draw_rect(Rect2(16, -11, 16, 7), Color("eeeeee"))
		o.draw_rect(Rect2(18, -9, 12, 1), Color("c03040"))
		o.draw_rect(Rect2(18, -7, 8, 1), Color("3a3f5a"))
	elif signed:
		# papan DIJUAL merah di tiang
		o.draw_rect(Rect2(8, -12, 1, 12), Color("5a3a24"))
		o.draw_rect(Rect2(2, -20, 14, 9), Color("f2f0e6"))
		o.draw_rect(Rect2(3, -19, 12, 7), Color("d03838"))
		o.draw_rect(Rect2(5, -17, 8, 1), Color("f2f0e6"))
		o.draw_rect(Rect2(5, -15, 5, 1), Color("f2f0e6"))
	# lingkaran koin di atas titik tugas
	if not show_slots or job == Job.NONE:
		return
	var total := cost()
	var p := paid()
	var y0 := -30.0 # tugas dari tanah
	if job_on_roof:
		y0 = roof_y() - 18.0
	elif floors > 0:
		y0 = -FLOOR_H - 8.0 # di atas pintu toko
	var start_x := W / 2.0 - total * 3.0
	for i in total:
		var src := Rect2(5 if i < p else 0, 0, 5, 5)
		o.draw_texture_rect_region(TEX_SLOTS, Rect2(Vector2(start_x + i * 6, y0), Vector2(5, 5)), src)
