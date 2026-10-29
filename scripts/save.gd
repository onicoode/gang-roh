extends Node
## Autoload "Save": progres permanen (Ema + level kemampuan roh), disimpan di user://save.cfg.
## Dipakai menu (beli upgrade) dan game (efek upgrade, Ema di akhir sesi).

const PATH := "user://save.cfg"
const MAX_LEVEL := 5

## id: [nama, penjelasan, biaya dasar]
const SKILLS := {
	"langkah": ["Langkah", "Jalan & memanjat lebih cepat (+10%/lv)", 3],
	"kantong": ["Kantong", "Bawa Doa lebih banyak (+2/lv)", 3],
	"berkah": ["Berkah", "Doa awal sesi lebih banyak (+2/lv)", 4],
	"firasat": ["Firasat", "Firasat developer lebih awal; pagar awal lebih kuat", 4],
	"pesona": ["Pesona", "Lambaian Rezeki lebih sering & lebih banyak Doa", 5],
}
const ORDER: Array[String] = ["langkah", "kantong", "berkah", "firasat", "pesona"]

var ema := 0
var levels: Dictionary = {}
var sessions := 0
var best_floors := 0
## Diisi menu sebelum pindah scene: true = langsung buka layar persiapan (upgrade).
var open_prepare := false


func _ready() -> void:
	load_data()


func level(id: String) -> int:
	return int(levels.get(id, 0))


func cost(id: String) -> int:
	var def: Array = SKILLS[id]
	return int(def[2]) * (level(id) + 1)


func can_buy(id: String) -> bool:
	return level(id) < MAX_LEVEL and ema >= cost(id)


func buy(id: String) -> bool:
	if not can_buy(id):
		return false
	ema -= cost(id)
	levels[id] = level(id) + 1
	save_data()
	return true


## Hitung Ema dari hasil sesi, tambahkan, lalu simpan. Mengembalikan Ema yang didapat.
func finish_session(months: int, floors: int, lost: bool) -> int:
	var gained := months + floors
	if not lost:
		gained += 10 # bonus bertahan setahun
	else:
		gained = int(gained / 2.0)
	gained = maxi(gained, 1)
	ema += gained
	sessions += 1
	best_floors = maxi(best_floors, floors)
	save_data()
	return gained


func reset_data() -> void:
	ema = 0
	levels = {}
	sessions = 0
	best_floors = 0
	save_data()


func save_data() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progres", "ema", ema)
	cfg.set_value("progres", "levels", levels)
	cfg.set_value("progres", "sessions", sessions)
	cfg.set_value("progres", "best_floors", best_floors)
	cfg.save(PATH)


func load_data() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	ema = int(cfg.get_value("progres", "ema", 0))
	var lv = cfg.get_value("progres", "levels", {})
	if lv is Dictionary:
		levels = lv
	sessions = int(cfg.get_value("progres", "sessions", 0))
	best_floors = int(cfg.get_value("progres", "best_floors", 0))
