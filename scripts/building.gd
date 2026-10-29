extends Node2D
## Satu petak bangunan. floors = 0 berarti tanah kosong.
## Lantai 1 = toko, lantai 2+ = apartemen. Tiap lantai = 1 keluarga penghuni.
## Roh tidak membangun sendiri: roh MENGABULKAN keinginan pemilik (gelembung di atas
## bangunan) dengan Doa, lalu tukang datang membangun/memperbaiki.
## Penghuni keluar berdoa di siang hari (ke hokora sendiri atau kuil pusat) → Doa muncul.
## Bangunan menua tiap bulan. Kusam = penghuni jarang berdoa, bobrok = tidak berdoa sama
## sekali dan jadi incaran developer.

const W := 48
const FLOOR_H := 32
const MAX_FLOORS := 5
const PRAY_INTERVAL := 30.0 # detik antar warga keluar berdoa, dibagi jumlah penghuni
const HOKORA_COST := 3
const REPAIR_AT := 75.0 # di bawah ini bangunan bisa dirawat
const DULL := 60.0 # di bawah ini kusam
const RUIN := 30.0 # di bawah ini bobrok
const CLEANSE_COST := 3 # cabut papan DIJUAL
const RECLAIM_COST := 10 # rebut kembali petak yang digusur

enum Job { NONE, BUILD, REPAIR, CLEANSE, RECLAIM, HOKORA }

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
var has_hokora := false # kuil kecil di depan bangunan
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
var _pray_timer := 0.0
var _fix_t := 0.0 # tukang sedang memperbaiki
var _anim := 0.0
var _wind_mat: ShaderMaterial
var _paid: Dictionary = {} # koin tertanam per jenis tugas
var _overlay: Node2D


func _ready() -> void:
	_wind_mat = ShaderMaterial.new()
	_wind_mat.shader = WIND_SHADER
	_wind_mat.set_shader_parameter("strength", 1.5)
	_pray_timer = randf_range(2.0, 10.0)
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
	# penghuni keluar berdoa selama siang
	if floors >= 1 and not owned and world and world.prayer_time() and condition >= RUIN:
		_pray_timer -= delta
		if _pray_timer <= 0.0:
			var slow: float = 1.7 if condition < DULL else 1.0
			_pray_timer = PRAY_INTERVAL / floors * slow * randf_range(0.8, 1.2)
			world.send_worshipper(self)
	# tukang bekerja (animasi)
	_fix_t = maxf(_fix_t - delta, 0.0)
	if constructing or _fix_t > 0.0:
		_anim += delta
		_overlay.queue_redraw()


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
	if not on_roof and floors > 0 and not has_hokora:
		return Job.HOKORA
	return Job.NONE


## Keinginan utama pemilik (ditampilkan di gelembung).
func wish() -> Job:
	var j := job_for(false)
	if j == Job.NONE or j == Job.HOKORA:
		var r: Job = job_for(true) if floors > 0 else Job.NONE
		if r != Job.NONE:
			return r
	return j


## Titik hokora (tempat penghuni berdoa).
func hokora_x() -> float:
	return position.x + 6.0


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
		Job.HOKORA:
			return HOKORA_COST
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
		_fix_t = 4.0
		world.sfx.play("repair")
		world.pop_text(Vector2(center_x(), roof_y() - 12.0), "berkah!", Color("9fe0a0"))
		if condition >= REPAIR_AT:
			world.say("Pemilik jadi rajin merawat. Tukang datang memperbaiki.")
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
			world.say("Keinginan terkabul! Rezeki pemilik lancar, tukang mulai membangun.")
		Job.CLEANSE:
			signed = false
			world.sfx.play("build")
			world.say("Pemilik batal menjual tanahnya. Papan DIJUAL dicabut!")
		Job.RECLAIM:
			owned = false
			condition = 100.0
			world.sfx.play("floor")
			world.say("Proyek developer bangkrut! Warga membeli kembali petak ini.")
		Job.HOKORA:
			has_hokora = true
			world.sfx.play("floor")
			world.say("Penghuni memasang hokora. Mereka bisa berdoa di depan rumah.")
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
	has_hokora = false
	_paid.clear()
	rebuild()


## Lambaian Rezeki: toko ramai, pengunjung yang bersyukur ikut berdoa.
func lucky_wave(n: int = 3) -> void:
	for i in n:
		world.send_worshipper(self, true)


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
	if has_hokora and not owned:
		_draw_hokora(o)
	if constructing:
		_draw_workers(o, 2)
	elif _fix_t > 0.0:
		_draw_workers(o, 1)
	if owned:
		pass
	elif signed:
		# papan DIJUAL merah di tiang
		o.draw_rect(Rect2(8, -12, 1, 12), Color("5a3a24"))
		o.draw_rect(Rect2(2, -20, 14, 9), Color("f2f0e6"))
		o.draw_rect(Rect2(3, -19, 12, 7), Color("d03838"))
		o.draw_rect(Rect2(5, -17, 8, 1), Color("f2f0e6"))
		o.draw_rect(Rect2(5, -15, 5, 1), Color("f2f0e6"))
	# gelembung keinginan pemilik
	if not show_slots:
		_draw_wish(o, wish())
	# lingkaran Doa di atas titik tugas
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


func _draw_hokora(o: Node2D) -> void:
	# kuil kecil kayu beratap merah di kiri depan bangunan
	var x := 2.0
	o.draw_rect(Rect2(x + 1, -6, 6, 6), Color("7a5230"))
	o.draw_rect(Rect2(x + 2, -5, 4, 4), Color("3a2418"))
	o.draw_rect(Rect2(x + 3, -4, 2, 2), Color("ffd890"))
	o.draw_rect(Rect2(x, -8, 8, 2), Color("c03838"))
	o.draw_rect(Rect2(x + 1, -9, 6, 1), Color("c03838"))
	o.draw_rect(Rect2(x - 1, -7, 10, 1), Color("8a2424"))


func _draw_workers(o: Node2D, n: int) -> void:
	# tukang berhelm kuning memalu
	for i in n:
		var x := 12.0 + i * 20.0
		var up: int = 2 if int((_anim + i * 0.3) * 5.0) % 2 == 0 else 0
		o.draw_rect(Rect2(x - 1, -4, 1, 4), Color("3a3f5a"))
		o.draw_rect(Rect2(x + 1, -4, 1, 4), Color("3a3f5a"))
		o.draw_rect(Rect2(x - 1, -9, 3, 5), Color("4a7ab0"))
		o.draw_rect(Rect2(x - 1, -12, 3, 3), Color("e0b088"))
		o.draw_rect(Rect2(x - 2, -13, 5, 1), Color("f0c030"))
		o.draw_rect(Rect2(x - 1, -14, 3, 1), Color("f0c030"))
		o.draw_rect(Rect2(x + 2, -9 - up, 1, 3), Color("e0b088"))
		o.draw_rect(Rect2(x + 2, -11 - up, 2, 2), Color("8a8a8a"))


func _draw_wish(o: Node2D, j: Job) -> void:
	if j == Job.NONE:
		return
	var top: float = -30.0 if floors == 0 else roof_y() - 24.0
	if floors >= 3:
		top -= 8.0
	var bx := W / 2.0 - 6.0
	var by := top
	var paper := Color(1, 0.98, 0.92, 0.92)
	o.draw_rect(Rect2(bx, by, 12, 9), paper)
	o.draw_rect(Rect2(bx + 1, by - 1, 10, 1), paper)
	o.draw_rect(Rect2(bx + 1, by + 9, 10, 1), paper)
	o.draw_rect(Rect2(bx + 3, by + 11, 2, 1), paper)
	o.draw_rect(Rect2(bx + 2, by + 13, 1, 1), paper)
	var ix := bx + 3.0
	var iy := by + 1.0
	match j:
		Job.BUILD:
			# rumah (+ kalau tambah lantai)
			o.draw_rect(Rect2(ix + 1, iy + 3, 5, 4), Color("d07a48"))
			o.draw_rect(Rect2(ix, iy + 2, 7, 1), Color("c03838"))
			o.draw_rect(Rect2(ix + 1, iy + 1, 5, 1), Color("c03838"))
			o.draw_rect(Rect2(ix + 2, iy, 3, 1), Color("c03838"))
			o.draw_rect(Rect2(ix + 3, iy + 5, 1, 2), Color("3a2418"))
		Job.REPAIR:
			# palu
			o.draw_rect(Rect2(ix + 1, iy + 1, 5, 2), Color("6a6a72"))
			o.draw_rect(Rect2(ix + 3, iy + 3, 1, 4), Color("8a5a30"))
		Job.CLEANSE:
			# papan dicoret
			o.draw_rect(Rect2(ix, iy + 1, 7, 5), Color("d03838"))
			for k in 5:
				o.draw_rect(Rect2(ix + 1 + k, iy + 1 + k, 1, 1), Color("f2f0e6"))
		Job.RECLAIM:
			# rumah abu-abu
			o.draw_rect(Rect2(ix + 1, iy + 3, 5, 4), Color("8a96a8"))
			o.draw_rect(Rect2(ix, iy + 2, 7, 1), Color("5a6478"))
			o.draw_rect(Rect2(ix + 2, iy + 1, 3, 1), Color("5a6478"))
		Job.HOKORA:
			# torii kecil
			o.draw_rect(Rect2(ix, iy + 1, 7, 1), Color("c03838"))
			o.draw_rect(Rect2(ix + 1, iy + 3, 5, 1), Color("c03838"))
			o.draw_rect(Rect2(ix + 1, iy + 2, 1, 5), Color("c03838"))
			o.draw_rect(Rect2(ix + 5, iy + 2, 1, 5), Color("c03838"))
