extends Node2D
## Kuil pusat. Bisa di-upgrade dengan Doa (Lv 1–5): kekuatan roh kuil bertambah.
## Lv2: 1 Kitsune-bi tiap malam (Lv3: 2, Lv4+: 3).
## Lv3: Komainu berjaga di kedua pagar tiap malam.
## Lv4: Kodama merawat semua bangunan tiap pagi (+10 kondisi).
## Lv5: pengunjung kuil membawa 3 Doa; semua roh pelindung +1 nyawa.
## Hiasan kuil ikut bertambah: lentera batu, patung Komainu, pohon suci, cahaya emas.

const MAX_LEVEL := 5
const COSTS: Array[int] = [0, 6, 10, 15, 20] # biaya naik ke level berikutnya (indeks = level sekarang)
const SLOT := preload("res://sprites/slots.png")

const DESC := {
	2: "Kitsune-bi menjaga gang di malam hari.",
	3: "Komainu berjaga di pagar. Kitsune-bi bertambah.",
	4: "Kodama merawat bangunan tiap pagi.",
	5: "Pengunjung membawa lebih banyak Doa. Roh pelindung makin kuat.",
}

var world: Node = null
var level := 1
var paid := 0
var show_slots := false:
	set(v):
		if v != show_slots:
			show_slots = v
			queue_redraw()

var _anim := 0.0
var _glow := 0.0


func _process(delta: float) -> void:
	_anim += delta
	_glow = maxf(_glow - delta, 0.0)
	if level >= 2 or _glow > 0.0:
		queue_redraw()


# ---------------------------------------------------------------- dipakai kucing

func cost() -> int:
	return COSTS[level] if level < MAX_LEVEL else 0


func can_take_coin() -> bool:
	return level < MAX_LEVEL


func add_coin() -> void:
	paid += 1
	world.sfx.play("drop")
	if paid >= cost():
		paid = 0
		level += 1
		_glow = 1.5
		world.sfx.play("floor")
		world.shake(1.5)
		world.say("Kuil naik ke Lv %d! %s" % [level, DESC[level]])
	queue_redraw()


func fox_count() -> int:
	return clampi(level - 1, 0, 3)


# ---------------------------------------------------------------- gambar

func _draw() -> void:
	# lentera batu di kiri-kanan (Lv2+)
	if level >= 2:
		for sx: float in [-17.0, 13.0]:
			draw_rect(Rect2(sx + 1, -3, 3, 3), Color("8a8a86"))
			draw_rect(Rect2(sx + 2, -7, 1, 4), Color("8a8a86"))
			draw_rect(Rect2(sx, -10, 5, 3), Color("9a9a96"))
			var flick: float = 0.75 + 0.25 * sin(_anim * 7.0 + sx)
			draw_rect(Rect2(sx + 1, -9, 3, 1), Color(1, 0.8, 0.4, flick))
			draw_rect(Rect2(sx - 1, -11, 7, 1), Color("7a7a76"))
	# patung Komainu kecil (Lv3+)
	if level >= 3:
		for sx: float in [-23.0, 19.0]:
			draw_rect(Rect2(sx, -2, 4, 2), Color("6a6a68"))
			draw_rect(Rect2(sx, -5, 3, 3), Color("9a9a96"))
			draw_rect(Rect2(sx + 1, -7, 3, 2), Color("8a8a86"))
	# pohon suci bertali shimenawa (Lv4+)
	if level >= 4:
		var tx := -30.0
		draw_rect(Rect2(tx, -18, 3, 18), Color("5a3a24"))
		draw_rect(Rect2(tx - 6, -30, 15, 8), Color("3a6a3a"))
		draw_rect(Rect2(tx - 4, -34, 11, 5), Color("4a7a44"))
		draw_rect(Rect2(tx - 1, -12, 5, 1), Color("e8dcb0"))
		draw_rect(Rect2(tx + 1, -11, 1, 2), Color("f4f0e6"))
	# cahaya emas (Lv5)
	if level >= 5:
		var a: float = 0.12 + 0.06 * sin(_anim * 2.0)
		draw_rect(Rect2(-14, -36, 28, 36), Color(1, 0.85, 0.4, a))
	if _glow > 0.0:
		draw_rect(Rect2(-18, -40, 36, 40), Color(1, 0.95, 0.7, _glow * 0.3))
	# lingkaran Doa untuk naik level
	if show_slots and can_take_coin():
		var n := cost()
		var per_row := 10
		for i in n:
			var row: int = floori(i / float(per_row))
			var col: int = i % per_row
			var cnt: int = mini(n - row * per_row, per_row)
			var x := -cnt * 3.0 + col * 6.0
			var src := Rect2(5 if i < paid else 0, 0, 5, 5)
			draw_texture_rect_region(SLOT, Rect2(Vector2(x, -46 + row * 7), Vector2(5, 5)), src)
