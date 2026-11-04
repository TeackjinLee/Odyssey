class_name Bgm
## 배경 음악과 환경음. 파일은 assets/audio/music/<이름>.ogg · assets/audio/amb/<이름>.ogg (tools/gen_audio.py가 만든다).
## 파일이 없으면 조용히 넘어간다(음악 없이도 게임은 돌아간다).
## - play(이름): 지금 곡에서 새 곡으로 엇갈려 바꾼다(크로스페이드). 같은 곡이면 그대로
## - sting(이름): 짧은 곡(승리·패배)을 한 번. 배경 곡은 그동안 줄인다
## - amb(이름, 크기 0~1): 환경음 층(바람·불·파도·먼 전투)을 겹쳐 틀고 크기를 천천히 맞춘다
## 일시정지 중에도 이어서 울린다(Game이 PROCESS_MODE_ALWAYS).

const MUSIC_DIR := "res://assets/audio/music/"
const AMB_DIR := "res://assets/audio/amb/"
## 곡마다 기본 크기(dB)
const MUSIC_DB := {"theme": -6.0, "stealth": -7.0, "battle": -6.0, "siege": -5.0, "ending": -5.0, "victory": -4.0, "defeat": -4.0}
const AMB_DB := -4.0
const SILENT := -60.0

static var _a: AudioStreamPlayer
static var _b: AudioStreamPlayer
static var _sting: AudioStreamPlayer
static var current := ""
static var _tweens := {}
static var _amb := {}
static var _amb_target := {}


static func _ready_players() -> bool:
	if Game == null or not Game.is_inside_tree():
		return false
	if _a == null or not is_instance_valid(_a):
		_a = _new_player("Music")
		_b = _new_player("Music")
		_sting = _new_player("Music")
	return true


static func _new_player(bus: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus
	p.volume_db = SILENT
	Game.add_child(p)
	return p


static func _load(dir: String, name: String, loop: bool) -> AudioStream:
	for ext in ["ogg", "wav"]:
		var path: String = dir + name + "." + ext
		if ResourceLoader.exists(path):
			var s: AudioStream = load(path)
			if s is AudioStreamOggVorbis:
				s.loop = loop
			elif s is AudioStreamWAV and loop:
				s.loop_mode = AudioStreamWAV.LOOP_FORWARD
				s.loop_end = int(s.get_length() * s.mix_rate)
			return s
	return null


static func _fade(p: AudioStreamPlayer, to_db: float, time: float, stop_after := false) -> void:
	if _tweens.has(p) and _tweens[p].is_valid():
		_tweens[p].kill()
	var tw := Game.create_tween()
	tw.tween_property(p, "volume_db", to_db, maxf(time, 0.01))
	if stop_after:
		tw.tween_callback(p.stop)
	_tweens[p] = tw


## 배경 곡 바꾸기. 이름이 ""이면 끈다.
static func play(name: String, fade := 2.0) -> void:
	if not _ready_players() or name == current:
		return
	current = name
	var old := _a if _a.playing else null
	if old:
		_fade(old, SILENT, fade, true)
		var t := _a
		_a = _b
		_b = t
	if name == "":
		return
	var s := _load(MUSIC_DIR, name, true)
	if s == null:
		return
	_a.stream = s
	_a.volume_db = SILENT
	_a.play()
	_fade(_a, MUSIC_DB.get(name, -6.0), fade)


static func stop(fade := 2.0) -> void:
	play("", fade)


## 짧은 곡 한 번(승리·패배): 배경 곡은 꺼진다(다음 play로 다시 튼다).
static func sting(name: String) -> void:
	if not _ready_players():
		return
	var s := _load(MUSIC_DIR, name, false)
	if s == null:
		return
	if _a.playing:
		_fade(_a, SILENT, 0.6, true)
	current = ""
	_sting.stream = s
	_sting.volume_db = MUSIC_DB.get(name, -4.0)
	_sting.play()


## 환경음 층 크기(0~1). 처음 부르면 틀기 시작한다.
static func amb(name: String, volume: float, fade := 1.5) -> void:
	if not _ready_players():
		return
	volume = clampf(volume, 0.0, 1.0)
	if is_equal_approx(float(_amb_target.get(name, -1.0)), volume):
		return
	_amb_target[name] = volume
	var p: AudioStreamPlayer = _amb.get(name)
	if p == null or not is_instance_valid(p):
		var s := _load(AMB_DIR, name, true)
		if s == null:
			return
		p = _new_player("SFX")
		p.stream = s
		_amb[name] = p
	if volume > 0.001 and not p.playing:
		p.play(randf() * maxf(0.0, p.stream.get_length() - 1.0))
	_fade(p, AMB_DB + linear_to_db(volume) if volume > 0.001 else SILENT, fade, volume <= 0.001)


static func amb_stop_all(fade := 1.5) -> void:
	for name in _amb.keys():
		amb(name, 0.0, fade)


## 끝낼 때 잡고 있던 재생기·트윈을 놓는다(Game._exit_tree)
static func clear() -> void:
	for tw in _tweens.values():
		if tw.is_valid():
			tw.kill()
	_tweens.clear()
	for p in [_a, _b, _sting] + _amb.values():
		if p and is_instance_valid(p):
			p.stop()
			p.stream = null
	_amb.clear()
	_amb_target.clear()
	_a = null
	_b = null
	_sting = null
	current = ""
