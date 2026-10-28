extends Node2D
## Gang: deretan petak bangunan, kuil kecil, koin, dan siklus hari.
## 1 hari di game = 1 bulan bagi manusia. Sesi pendek = 12 bulan.

signal message(text: String)
signal session_ended

const PLOT_W := 56
const N_PLOTS := 8
const MARGIN := 48
const SHRINE_PLOT := 3
const START_SHOP_PLOT := 2
const MONTHS := 12
const DAY_LENGTH := 120.0 # detik nyata per bulan

const BuildingScene := preload("res://scenes/building.tscn")
const CoinScene := preload("res://scenes/coin.tscn")

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
	var cam: Camera2D = player.get_node("Camera2D")
	cam.limit_left = 0
	cam.limit_right = world_w
	cam.limit_bottom = 40
	cam.limit_top = -480

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


## Bangunan yang titik bangunnya sedang didekati kucing (tanah kosong atau atap).
func build_target(cat: Node2D) -> Node:
	for b in buildings:
		if not b.can_build_more():
			continue
		if b.floors == 0 and cat.state == cat.State.GROUND and absf(cat.position.x - b.center_x()) < 18.0:
			return b
		if b.floors > 0 and cat.state == cat.State.ROOF and cat.roof_building == b:
			return b
	return null


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


func summary() -> String:
	var total := 0
	var shops := 0
	var tallest := 0
	for b in buildings:
		total += b.floors
		if b.floors > 0:
			shops += 1
		tallest = maxi(tallest, b.floors)
	return "Toko berdiri: %d\nTotal lantai: %d\nGedung tertinggi: %d lantai" % [shops, total, tallest]


# ---------------------------------------------------------------- waktu

func _new_month() -> void:
	if month >= MONTHS:
		ended = true
		session_ended.emit()
		return
	month += 1
	for b in buildings:
		b.on_new_month()
	_shrine_offering()


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
	var cam: Camera2D = player.get_node("Camera2D")
	var cam_x := cam.get_screen_center_position().x
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
		elif arg.begins_with("--time="):
			day_t = float(arg.substr(7))
