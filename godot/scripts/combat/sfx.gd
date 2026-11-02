class_name Sfx
## 효과음을 코드로 합성한다(오디오 파일 없음). 나중에 실제 소리 파일로 바꾸려면 _make()만 고친다.

const RATE := 22050
static var _streams := {}
static var _players: Array = []
static var _next := 0


static func play(name: String, volume_db := -8.0) -> void:
	if Game == null or not Game.is_inside_tree():
		return
	if _players.is_empty():
		for i in 10:
			var p := AudioStreamPlayer.new()
			Game.add_child(p)
			_players.append(p)
	if not _streams.has(name):
		_streams[name] = _make(name)
	var player: AudioStreamPlayer = _players[_next]
	_next = (_next + 1) % _players.size()
	player.stream = _streams[name]
	player.volume_db = volume_db
	player.pitch_scale = randf_range(0.92, 1.08)
	player.play()


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
