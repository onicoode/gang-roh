extends Node2D
## Gang: deretan petak bangunan, kuil kecil, koin, dan siklus hari.
## 1 hari di game = 1 bulan bagi manusia. Sesi pendek = 12 bulan.
## Mulai bulan 2, developer rakus datang tiap malam (firasat muncul sore hari).
## Kalah kalau developer menguasai LOSE_PLOTS petak (kuil ikut tergusur).

signal message(text: String)
signal session_ended

const PLOT_W := 56
const N_PLOTS := 8
const MARGIN := 48
const SHRINE_PLOT := 3
const START_SHOP_PLOT := 2
const MONTHS := 12
const DAY_LENGTH := 120.0 # detik nyata per bulan
const LOSE_PLOTS := 4
const WARN_T := 0.55 # sore: firasat developer
const DEV_T := 0.72 # malam: developer datang
const BOTH_SIDES_MONTH := 7 # mulai bulan ini developer datang dari dua ujung

const BuildingScene := preload("res://scenes/building.tscn")
const CoinScene := preload("res://scenes/coin.tscn")
const Building := preload("res://scripts/building.gd")
const DevScript := preload("res://scripts/developer.gd")
const GateScript := preload("res://scripts/gate.gd")
const SfxScript := preload("res://scripts/sfx.gd")

# Warna langit sepanjang hari (0 = pagi, 1 = pagi berikutnya)
const TIME_KEYS := [0.0, 0.3, 0.62, 0.75, 0.9, 1.0]
const SKY_TOP := [Color("9ec3d6"), Color("8fb8d8"), Color("f2b066"), Color("6a4f86"), Color("1c2140"), Color("9ec3d6")]
const SKY_BOTTOM := [Color("f4e2c0"), Color("dfe8ea"), Color("f8cf86"), Color("d98a6a"), Color("34305a"), Color("f4e2c0")]
const TINT := [Color(1, 0.96, 0.92), Color(1, 1, 1), Color(1, 0.86, 0.74), Color(0.72, 0.64, 0.84), Color(0.42, 0.45, 0.66), Color(1, 0.96, 0.92)]
const LIGHT_ALPHA := [0.0, 0.0, 0.0, 0.8, 1.0, 0.0]

var world_w := MARGIN * 2 + PLOT_W * N_PLOTS
var buildings: Array = []
var month := 1
var day_t := 0.0
var ended := false
var lost := false
var gates: Array = [] # [kiri, kanan]
var sfx: Node

var warn_t := WARN_T
var _focus: Node = null # target koin yang lingkarannya sedang ditampilkan
var _dev_warned := false
var _dev_spawned := false
var _dev_sides: Array[int] = []
var _shake := 0.0
var _cam: Camera2D
var _actors: Node2D
var _devs: Node2D
var _fx: Node2D

@onready var sky: ColorRect = $SkyLayer/Sky
@onready var tinted: Node2D = $Tinted
@onready var clouds: Node2D = $Tinted/Clouds
@onready var city_far: Sprite2D = $Tinted/CityFar
@onready var city_mid: Sprite2D = $Tinted/CityMid
@onready var street: Sprite2D = $Tinted/Street
@onready var shrine: Sprite2D = $Tinted/Shrine
@onready var buildings_node: Node2D = $Tinted/Buildings
@onready var coins_node: Node2D = $Tinted/Coins
@onready var player: Node2D = $Tinted/Player
@onready var lights: Node2D = $Lights


func _ready() -> void:
	sfx = SfxScript.new()
	add_child(sfx)
	_actors = Node2D.new()
	tinted.add_child(_actors)
	tinted.move_child(_actors, player.get_index())
	_devs = Node2D.new()
	_actors.add_child(_devs)
	_fx = Node2D.new()
	add_child(_fx)
	for side in [-1, 1]:
		var g = GateScript.new()
		g.world = self
		g.position = Vector2(MARGIN / 2.0 if side < 0 else world_w - MARGIN / 2.0, 0)
		_actors.add_child(g)
		gates.append(g)

	street.region_rect = Rect2(0, 0, world_w, 40)
	shrine.position = Vector2(MARGIN + SHRINE_PLOT * PLOT_W + PLOT_W / 2.0, 0)

	for i in N_PLOTS:
		if i == SHRINE_PLOT:
			continue
		var b = BuildingScene.instantiate()
		b.world = self
		b.position = Vector2(MARGIN + i * PLOT_W + 4, 0)
		b.style = (i * 2 + 1) % 3
		if i == START_SHOP_PLOT:
			b.floors = 1
		buildings_node.add_child(b)
		buildings.append(b)

	player.world = self
	player.position = Vector2(shrine.position.x + 14, 0)
	_cam = player.get_node("Camera2D")
	_cam.limit_left = 0
	_cam.limit_right = world_w
	_cam.limit_bottom = 40
	_cam.limit_top = -480

	_apply_upgrades()
	_apply_debug_args()
	_shrine_offering()
	_apply_time()


func _process(delta: float) -> void:
	if ended:
		return
	day_t += delta / DAY_LENGTH
	if day_t >= 1.0:
		day_t -= 1.0
		_new_month()
		if ended:
			return
	_update_developers()
	_update_focus()
	_update_shake(delta)
	_apply_time()
	_update_parallax(delta)


# ---------------------------------------------------------------- query (dipakai script lain)

func is_open() -> bool:
	return day_t < 0.7


func phase_name() -> String:
	if day_t < 0.1:
		return "Pagi"
	if day_t < 0.5:
		return "Siang"
	if day_t < 0.7:
		return "Sore"
	return "Malam"


func ladder_at(x: float) -> Node:
	for b in buildings:
		if b.floors > 0 and absf(x - b.ladder_x()) < 5.0:
			return b
	return null


func shop_near(x: float) -> Node:
	for b in buildings:
		if b.floors > 0 and absf(x - b.door_x()) < 12.0:
			return b
	return null


## Benda yang bisa menerima koin di dekat kucing: developer (uang rokok), pagar,
## atau bangunan (bangun / rawat / cabut papan / rebut petak).
func build_target(cat: Node2D) -> Node:
	var on_ground: bool = cat.state == cat.State.GROUND
	var on_roof: bool = cat.state == cat.State.ROOF
	if on_ground:
		for d in _devs.get_children():
			if d.can_take_coin() and absf(cat.position.x - d.position.x) < 14.0:
				return d
		for g in gates:
			if g.can_take_coin() and absf(cat.position.x - g.position.x) < 14.0:
				return g
	for b in buildings:
		var j: int = Building.Job.NONE
		if on_ground and absf(cat.position.x - b.center_x()) < 18.0:
			j = b.job_for(false)
		elif on_roof and cat.roof_building == b:
			j = b.job_for(true)
		if j != Building.Job.NONE:
			b.set_job(j, on_roof)
			return b
	return null


# ---------------------------------------------------------------- developer

func dev_count() -> int:
	return _devs.get_child_count()


func dev_wants(b: Node) -> bool:
	return b.signed or b.vulnerable()


## Petak incaran terdekat di depan developer (searah jalannya).
func dev_next_target(x: float, dir: int) -> Node:
	var best: Node = null
	var best_d := INF
	for b in buildings:
		var ahead: float = (b.center_x() - x) * dir
		if ahead >= -1.0 and ahead < best_d and dev_wants(b):
			best = b
			best_d = ahead
	return best


func dev_claim(b: Node) -> void:
	if ended:
		return
	if b.signed:
		b.evict()
		sfx.play("evict")
		shake(2.5)
		var n := owned_count()
		say("Petak digusur! Developer menguasai %d / %d petak." % [n, LOSE_PLOTS])
		if n >= LOSE_PLOTS:
			_lose()
	else:
		b.put_sign()
		sfx.play("alert")
		say("Papan DIJUAL dipasang! Cabut (3 Doa) sebelum developer kembali.")


func owned_count() -> int:
	var n := 0
	for b in buildings:
		if b.owned:
			n += 1
	return n


# ---------------------------------------------------------------- efek

func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


func pop_text(pos: Vector2, text: String, color: Color = Color.WHITE) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.16, 0.13, 0.18))
	l.add_theme_constant_override("outline_size", 3)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.size = Vector2(60, 12)
	l.position = pos - Vector2(30, 8)
	_fx.add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "position:y", l.position.y - 12.0, 0.8)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.5).set_delay(0.3)
	tw.tween_callback(l.queue_free)


func say(text: String) -> void:
	message.emit(text)


func spawn_coin(pos: Vector2) -> void:
	if coins_node.get_child_count() >= 60:
		return
	var c = CoinScene.instantiate()
	c.world = self
	c.position = pos
	c.velocity = Vector2(randf_range(-35.0, 35.0), randf_range(-80.0, -55.0))
	coins_node.add_child(c)


func total_floors() -> int:
	var n := 0
	for b in buildings:
		n += b.floors
	return n


## Efek kemampuan permanen roh (dibeli di layar Persiapan dengan Ema).
func _apply_upgrades() -> void:
	player.speed_mult = 1.0 + 0.1 * Save.level("langkah")
	player.max_coins = 8 + 2 * Save.level("kantong")
	player.coins = mini(3 + 2 * Save.level("berkah"), player.max_coins)
	var firasat: int = Save.level("firasat")
	warn_t = WARN_T - 0.04 * firasat
	for g in gates:
		g.hp = floori(firasat / 2.0)
		g.queue_redraw()
	var pesona: int = Save.level("pesona")
	player.wave_cooldown = player.WAVE_COOLDOWN - 2.5 * pesona
	player.wave_bonus = 3 + floori(pesona / 2.0)


func summary() -> String:
	var total := 0
	var shops := 0
	var tallest := 0
	for b in buildings:
		total += b.floors
		if b.floors > 0:
			shops += 1
		tallest = maxi(tallest, b.floors)
	var ruined := 0
	for b in buildings:
		if b.floors > 0 and b.condition < Building.RUIN:
			ruined += 1
	return "Toko berdiri: %d\nTotal lantai: %d\nGedung tertinggi: %d lantai\nBangunan bobrok: %d\nPetak digusur: %d" % [
		shops, total, tallest, ruined, owned_count()]


# ---------------------------------------------------------------- waktu

func _new_month() -> void:
	if month >= MONTHS:
		ended = true
		session_ended.emit()
		return
	month += 1
	_dev_warned = false
	_dev_spawned = false
	for d in _devs.get_children():
		d.leave() # pagi: developer pulang
	for b in buildings:
		b.on_new_month()
	_shrine_offering()


func _lose() -> void:
	ended = true
	lost = true
	session_ended.emit()


func _update_developers() -> void:
	if day_t >= warn_t and not _dev_warned:
		_dev_warned = true
		_dev_sides.clear()
		if month == 1:
			say("Mulai bulan depan developer rakus datang tiap malam. Pasang pagar di ujung gang!")
			return
		if month >= BOTH_SIDES_MONTH:
			_dev_sides.append(-1)
			_dev_sides.append(1)
		else:
			_dev_sides.append(-1 if randf() < 0.5 else 1)
		var where: String = "kedua ujung"
		if _dev_sides.size() == 1:
			where = "ujung kiri" if _dev_sides[0] < 0 else "ujung kanan"
		say("Firasat: orang berjas mengintai dari %s gang..." % where)
		sfx.play("alert")
	if day_t >= DEV_T and not _dev_spawned:
		_dev_spawned = true
		for side in _dev_sides:
			var d = DevScript.new()
			d.world = self
			d.dir = 1 if side < 0 else -1
			d.gate = gates[0] if side < 0 else gates[1]
			d.bribe_cost = 2 + int(month / 3.0)
			d.position = Vector2(-8.0 if side < 0 else world_w + 8.0, 0)
			_devs.add_child(d)
		if not _dev_sides.is_empty():
			say("Developer datang!")


func _update_focus() -> void:
	var t: Node = build_target(player)
	if t == _focus:
		return
	if is_instance_valid(_focus):
		_focus.show_slots = false
	_focus = t
	if t != null:
		t.show_slots = true


func _update_shake(delta: float) -> void:
	if _shake <= 0.0:
		return
	_shake = maxf(_shake - delta * 5.0, 0.0)
	_cam.offset = Vector2(roundf(randf_range(-_shake, _shake)), roundf(randf_range(-_shake, _shake)))


func _shrine_offering() -> void:
	var n := 2
	for b in buildings:
		if b.floors > 0:
			n += 1
	for i in n:
		spawn_coin(shrine.position + Vector2(0, -6))


func _apply_time() -> void:
	var i := 0
	while i < TIME_KEYS.size() - 2 and day_t > TIME_KEYS[i + 1]:
		i += 1
	var t := inverse_lerp(TIME_KEYS[i], TIME_KEYS[i + 1], day_t)
	var mat := sky.material as ShaderMaterial
	mat.set_shader_parameter("top_color", SKY_TOP[i].lerp(SKY_TOP[i + 1], t))
	mat.set_shader_parameter("bottom_color", SKY_BOTTOM[i].lerp(SKY_BOTTOM[i + 1], t))
	tinted.modulate = TINT[i].lerp(TINT[i + 1], t)
	lights.modulate.a = lerpf(LIGHT_ALPHA[i], LIGHT_ALPHA[i + 1], t)


func _update_parallax(delta: float) -> void:
	var cam_x := _cam.get_screen_center_position().x
	city_far.position.x = cam_x * 0.7 - 1000.0
	city_mid.position.x = cam_x * 0.45 - 1000.0
	for c in clouds.get_children():
		c.position.x += delta * (3.0 + c.get_index())
		if c.position.x > world_w + 60:
			c.position.x = -60


func _apply_debug_args() -> void:
	# Untuk screenshot/tes: godot -- --demo --time=0.8
	for arg in OS.get_cmdline_user_args():
		if arg == "--demo":
			var f := [2, 4, 0, 3, 1, 5, 2]
			for i in buildings.size():
				buildings[i].floors = f[i % f.size()]
				buildings[i].rebuild()
			player.coins = 8
			var cond := [100.0, 50.0, 20.0, 80.0, 40.0, 100.0, 25.0]
			for i in buildings.size():
				buildings[i].condition = cond[i % cond.size()]
				buildings[i].rebuild()
			buildings[1].signed = true
			buildings[1].rebuild()
			gates[0].hp = 2
			gates[0].queue_redraw()
		elif arg.begins_with("--time="):
			day_t = float(arg.substr(7))
		elif arg.begins_with("--month="):
			month = clampi(int(arg.substr(8)), 1, MONTHS)
		elif arg.begins_with("--speed="):
			Engine.time_scale = float(arg.substr(8))
