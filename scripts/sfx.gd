extends Node
## Efek suara sederhana yang dibuat dari kode (tanpa file audio).
## Pakai: world.sfx.play("pickup")

const RATE := 22050
const VOICES := 6

## nama: [daftar nada (Hz), durasi tiap nada (detik), bentuk gelombang]
const SOUNDS := {
	"pickup": [[988.0, 1319.0], 0.05, "square"],
	"drop": [[523.0], 0.06, "square"],
	"build": [[523.0, 659.0, 784.0], 0.07, "square"],
	"floor": [[392.0, 523.0, 659.0, 784.0, 1047.0], 0.08, "square"],
	"repair": [[659.0, 880.0], 0.05, "tri"],
	"bribe": [[1175.0, 1568.0, 1175.0, 1568.0], 0.04, "square"],
	"alert": [[220.0, 0.0, 220.0, 175.0], 0.12, "tri"],
	"bonk": [[90.0], 0.12, "noise"],
	"evict": [[311.0, 262.0, 196.0, 147.0], 0.14, "square"],
	"wave": [[784.0, 988.0, 1175.0], 0.06, "tri"],
	"hit": [[180.0], 0.05, "noise"],
	"poof": [[523.0, 392.0, 262.0], 0.05, "tri"],
	"fire": [[880.0, 660.0], 0.04, "noise"],
	"pray": [[1319.0, 1760.0], 0.07, "tri"],
	"jinx": [[392.0, 370.0, 349.0, 330.0], 0.07, "tri"],
}

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0


func _ready() -> void:
	for n: String in SOUNDS.keys():
		var def: Array = SOUNDS[n]
		_streams[n] = _make(def[0], float(def[1]), str(def[2]))
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		p.volume_db = -12.0
		add_child(p)
		_players.append(p)


func play(n: String) -> void:
	if not _streams.has(n):
		return
	var p := _players[_next]
	_next = (_next + 1) % VOICES
	p.stream = _streams[n]
	p.pitch_scale = randf_range(0.97, 1.03)
	p.play()


func _make(notes: Array, dur: float, wave: String) -> AudioStreamWAV:
	var per := int(dur * RATE)
	var total := per * notes.size()
	var data := PackedByteArray()
	data.resize(total * 2)
	var phase := 0.0
	var noise := 0.0
	for i in total:
		var f: float = notes[floori(float(i) / per)]
		var k := float(i % per) / float(per) # posisi di dalam nada (0..1)
		var env := minf(k * 20.0, 1.0) * (1.0 - k) # serang cepat, lalu memudar
		var v := 0.0
		if f > 0.0:
			phase = fmod(phase + f / RATE, 1.0)
			match wave:
				"square":
					v = 0.5 if phase < 0.5 else -0.5
				"tri":
					v = 2.0 * absf(2.0 * phase - 1.0) - 1.0
				"noise":
					if i % 3 == 0:
						noise = randf_range(-1.0, 1.0)
					v = noise
		data.encode_s16(i * 2, int(clampf(v * env, -1.0, 1.0) * 12000.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	s.data = data
	return s
