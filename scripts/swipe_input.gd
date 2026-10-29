extends Node
## Kontrol sentuh tak terlihat (Android/HP).
## - Geser (swipe) ke kiri/kanan/atas/bawah lalu tahan → pemain terus bergerak ke arah itu.
##   Geser ke arah lain tanpa melepas jari → arah ikut berganti.
## - Sentuh dan tahan di tempat (tanpa geser) → tombol aksi (pakai Doa / melambai).
## Berlaku di area layar mana saja. UI (Control dengan mouse_filter STOP, mis. tombol/panel)
## memakan sentuhan lebih dulu karena kita pakai _unhandled_input.

const SWIPE_DIST := 24.0 # jarak geser minimum agar dianggap swipe (patokan layar 720 px)
const MAX_RADIUS := 64.0 # titik pusat ikut tertarik kalau jari menjauh lebih dari ini
const HOLD_TIME := 0.18 # detik diam sebelum dianggap "tahan aksi"

const DIR_ACTIONS: Array[String] = ["move_left", "move_right", "move_up", "move_down"]

## Data per jari: { "anchor": Vector2, "pos": Vector2, "t": float, "mode": int, "dir": String }
var _touches: Dictionary = {}

enum Mode { UNDECIDED, SWIPE, ACTION }


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var e := event as InputEventScreenTouch
		if e.pressed:
			_touches[e.index] = {"anchor": e.position, "pos": e.position, "t": 0.0,
				"mode": Mode.UNDECIDED, "dir": ""}
		elif _touches.has(e.index):
			var d: Dictionary = _touches[e.index]
			if d["mode"] == Mode.UNDECIDED:
				_tap_action() # ketuk singkat = tekan aksi sekali
			_touches.erase(e.index)
			_refresh()
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		var e := event as InputEventScreenDrag
		if not _touches.has(e.index):
			return
		var d: Dictionary = _touches[e.index]
		d["pos"] = e.position
		if d["mode"] != Mode.ACTION:
			_update_dir(d)
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	var changed := false
	for d: Dictionary in _touches.values():
		if d["mode"] == Mode.UNDECIDED:
			d["t"] = float(d["t"]) + delta
			if float(d["t"]) >= HOLD_TIME:
				d["mode"] = Mode.ACTION
				changed = true
	if changed:
		_refresh()


## Lepas semua jari (dipakai saat jeda / akhir sesi).
func reset() -> void:
	_touches.clear()
	_refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		_touches.clear()
		_refresh()


func _update_dir(d: Dictionary) -> void:
	var anchor: Vector2 = d["anchor"]
	var pos: Vector2 = d["pos"]
	var off := pos - anchor
	var dist := _px(SWIPE_DIST)
	if off.length() < dist:
		return
	var dir: String
	if absf(off.x) >= absf(off.y):
		dir = "move_right" if off.x > 0.0 else "move_left"
	else:
		dir = "move_down" if off.y > 0.0 else "move_up"
	# Pusat ikut jari supaya ganti arah terasa cepat.
	var max_r := _px(MAX_RADIUS)
	if off.length() > max_r:
		d["anchor"] = pos - off.normalized() * max_r
	if d["mode"] != Mode.SWIPE or d["dir"] != dir:
		d["mode"] = Mode.SWIPE
		d["dir"] = dir
		_refresh()


## Skala jarak supaya terasa sama di layar kecil maupun besar (patokan sisi pendek 720 px).
func _px(v: float) -> float:
	var s := get_viewport().get_visible_rect().size
	return v * minf(s.x, s.y) / 720.0


## Terapkan status semua jari ke Input action.
func _refresh() -> void:
	var want: Dictionary = {}
	var action := false
	for d: Dictionary in _touches.values():
		if d["mode"] == Mode.SWIPE:
			want[d["dir"]] = true
		elif d["mode"] == Mode.ACTION:
			action = true
	for a in DIR_ACTIONS:
		_set_action(a, want.has(a))
	_set_action("action", action)


var _pressed: Dictionary = {}


func _set_action(a: String, on: bool) -> void:
	var was: bool = _pressed.get(a, false)
	if on == was:
		return
	_pressed[a] = on
	if on:
		Input.action_press(a)
	else:
		Input.action_release(a)


func _tap_action() -> void:
	if _pressed.get("action", false):
		return
	Input.action_press("action")
	# Lepas di frame berikutnya supaya is_action_just_pressed sempat terbaca.
	await get_tree().process_frame
	await get_tree().process_frame
	if not _pressed.get("action", false):
		Input.action_release("action")
