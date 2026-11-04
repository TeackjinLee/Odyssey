class_name Sfx
## 효과음. assets/audio/sfx/<이름>.wav|.ogg (또는 <이름>_1, _2 … 변형 여럿 → 무작위)가 있으면 그 파일을 쓰고,
## 없으면 코드로 합성한 소리를 쓴다(_make). 파일은 tools/gen_audio.py가 만든다 — 녹음한 소리로 바꾸려면 같은 이름으로 덮어쓴다.
## play: 화면 어디서 나든 같은 크기 · at: 오디세우스와 멀수록 작게(멀면 안 남)

const RATE := 22050
const DIR := "res://assets/audio/sfx/"
## 같은 소리가 이 시간 안에 또 나면 겹쳐 울리지 않게 건너뛴다(화살비·여럿이 동시에 맞을 때)
const MIN_GAP := 0.035
## 소리마다 따로 둔 최소 간격(적이 줄줄이 알아챌 때 경고음이 한 번만)
const GAP := {"alert": 2.5, "shout": 0.3, "death": 0.12}
## 음높이를 흔들지 않는 소리(음이 있는 소리)
const STEADY := ["ui", "ui_ok", "checkpoint", "bell", "gate", "horn", "cry", "fire_burst"]
## 파일이 없을 때 코드 합성으로 대신 낼 소리
const FALLBACK := {"swing_heavy": "swing", "arrow_hit": "block", "shout": "cry", "winch": "step", "ui_ok": "ui",
	"checkpoint": "ui", "alert": "block", "takedown": "hit", "torch_out": "step", "torch_on": "swing", "fire_burst": "gate",
	"stone": "block", "switch": "ui", "horn": "bell"}

static var _streams := {}
static var _players: Array = []
static var _next := 0
static var _last := {}


static func play(name: String, volume_db := -8.0) -> void:
	if Game == null or not Game.is_inside_tree():
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(_last.get(name, -99.0)) < GAP.get(name, MIN_GAP):
		return
	_last[name] = now
	if _players.is_empty():
		for i in 16:
			var p := AudioStreamPlayer.new()
			p.bus = "SFX"
			Game.add_child(p)
			_players.append(p)
	var list: Array = _variants(name)
	var player: AudioStreamPlayer = _players[_next]
	_next = (_next + 1) % _players.size()
	player.stream = list[randi() % list.size()]
	player.volume_db = volume_db
	player.pitch_scale = 1.0 if name in STEADY else randf_range(0.93, 1.07)
	player.play()


## 자리가 있는 소리: 오디세우스와의 거리로 줄인다(80px까지 그대로, 그 뒤 100px마다 -6dB, 520px 넘으면 안 냄).
static func at(name: String, pos: Vector2, volume_db := -8.0) -> void:
	var p: Node2D = Game.player
	if p == null or not is_instance_valid(p):
		play(name, volume_db)
		return
	var d := pos.distance_to(p.global_position)
	if d > 520.0:
		return
	play(name, volume_db - maxf(0.0, d - 80.0) * 0.06)


static func _variants(name: String) -> Array:
	if _streams.has(name):
		return _streams[name]
	var list: Array = []
	for ext in ["wav", "ogg"]:
		var one: String = DIR + name + "." + ext
		if ResourceLoader.exists(one):
			list.append(load(one))
		for i in range(1, 9):
			var v: String = DIR + "%s_%d.%s" % [name, i, ext]
			if not ResourceLoader.exists(v):
				break
			list.append(load(v))
	if list.is_empty():
		list.append(_make(FALLBACK.get(name, name)))
	_streams[name] = list
	return list


static func _make(name: String) -> AudioStreamWAV:
	var spec := {
		"swing": [0.14, 0.0, 1.0, 900.0],
		"hit": [0.12, 110.0, 0.7, 500.0],
		"hit_heavy": [0.22, 70.0, 0.8, 300.0],
		"block": [0.16, 880.0, 0.25, 2500.0],
		"parry": [0.3, 1320.0, 0.15, 3000.0],
		"bow": [0.18, 220.0, 0.2, 1200.0],
		"cry": [0.7, 140.0, 0.35, 600.0],
		"gate": [1.2, 45.0, 0.6, 200.0],
		"ui": [0.06, 660.0, 0.05, 2000.0],
		"death": [0.4, 90.0, 0.5, 400.0],
		"step": [0.05, 0.0, 1.0, 400.0],
		"bell": [1.6, 620.0, 0.03, 3000.0],
	}
	var s: Array = spec.get(name, spec["ui"])
	var length: float = s[0]
	var tone: float = s[1]
	var noise_amt: float = s[2]
	var cutoff: float = s[3]
	var n := int(RATE * length)
	var data := PackedByteArray()
	data.resize(n * 2)
	var lp := 0.0
	var alpha: float = clamp(cutoff / RATE * 6.0, 0.01, 1.0)
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		var env: float = pow(1.0 - float(i) / n, 2.0) * min(1.0, t * 200.0)
		lp += alpha * (randf() * 2.0 - 1.0 - lp)
		var f := tone
		if name == "cry":
			f = tone * (1.0 + t * 0.6)
		elif name == "bow":
			f = tone * (1.0 - t * 1.5)
		phase += TAU * f / RATE
		var v: float = (lp * noise_amt + sin(phase) * (1.0 - noise_amt)) * env
		if name == "bell":
			v += sin(phase * 2.76) * 0.35 * env  # 종소리 배음
		var iv := int(clamp(v, -1.0, 1.0) * 26000.0)
		data.encode_s16(i * 2, iv)
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	return w


## 끝낼 때 잡고 있던 소리·재생기를 놓는다(Game._exit_tree)
static func clear() -> void:
	for p in _players:
		if is_instance_valid(p):
			p.stop()
			p.stream = null
	_streams.clear()
	_players.clear()
