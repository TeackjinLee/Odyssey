class_name Cyclops
extends Node2D
## 챕터 3 폴리페모스(외눈 거인). 사람의 세 배 — 칼로는 쓰러뜨릴 수 없다(그룹 "actors"에 넣지 않아 칼·화살·봇이 무시한다).
## 상태: 순찰·지킴(자리마다 시야 부채꼴로 둘러봄) — 보이거나(밝을수록 멀리) 냄새 원 안에 오래 있으면 의심이 차고,
## 다 차면 그 사람(오디세우스든 부하든)을 쫓아와 곤봉 내려치기·움켜잡기. 잡힌 부하는 끌려간다(crew_taken).
## 소리(미끼 돌·달리기)가 나면 그곳으로 가서 둘러본다(INVESTIGATE). 포도주를 든 오디세우스는 치지 않고 기다린다.
## → 취해 비틀거리며 침상으로 → 잠듦(뛰는 소리에 뒤척임) → 눈을 잃고 날뜀(RAMPAGE: 소리 난 곳으로 돌진해 내려침, 벽에 부딪히면 멈칫)
## → 입구에 앉아 지킴(GUARD: 가까이 오거나 뛰는 소리가 나면 그쪽을 움켜잡음).
## 그림: assets/sprites/polyphemus(대기·걷기·취함·더듬기·포효)·polyphemus_combat(곤봉·움켜잡기·눈 부상)·polyphemus_sleep(잠듦 2줄),
## 2배 밀도 시트(scale 0.5, tools/pack_polyphemus_hd.py). 시트에 없는 동작은 대기·걷기 그림을 기울이거나 눕혀 대신한다.
## 무서움: 노란 외눈 불빛, 땅을 울리는 발소리(가까울수록 화면이 흔들림), 쫓을 때 포효, 가까우면 심장 소리.

enum Mode { AWAY, WALK, WATCH, CHASE, ATTACK, WAIT_WINE, DRUNK, SLEEP, BLIND, GUARD, INVESTIGATE, RAMPAGE, CHARGE, STUNNED, DRINK, SWIPE, ROAR, WOUND }

## 서 있는 키(화면 px, 오디세우스 약 60의 두 배쯤) — 머리 위 글·눈 높이의 기준
const HEIGHT := 125.0
const TEXT_Y := -HEIGHT - 22.0

## 시야: 땅 거리(밝은 곳 기준, 어두우면 DARK_K배), 부채꼴 각도(도), 이만큼(초) 계속 보이면 쫓는다
const SIGHT := 210.0
const DARK_K := 0.5
const ARC := 84.0
const NOTICE := 0.8
## 냄새 원: 이 땅 거리 안에 SMELL_TIME초 머물면 부채꼴 밖이어도 알아챈다(여럿이 모여 있으면 원이 커진다)
const SMELL_R := 84.0
const SMELL_GROUP := 26.0
const SMELL_TIME := 1.2
## 킁킁: 지킬 때 SNIFF_EVERY초마다 SNIFF_TIME초 동안 멈춰 냄새를 맡는다 — 냄새 원이 SNIFF_K배로 커진다
const SNIFF_EVERY := 11.0
const SNIFF_TIME := 2.6
const SNIFF_K := 1.7
const WALK_SPEED := 34.0
const CHASE_SPEED := 64.0
const DRUNK_SPEED := 24.0
const CHARGE_SPEED := 175.0
## 쫓다가 이만큼 못 보면 자리로 돌아감
const LOSE_TIME := 4.5
## 공격: 프레임 6장 6fps, 4번째 장면(0.67초)에 맞음. at = 몸에서 앞쪽 거리, r = 맞는 반지름(땅 거리)
## 움켜잡기 두 번 + 내려치기 한 번이면 오디세우스(140)가 쓰러진다
const SLAM := {"anim": "club_slam", "hit": 0.67, "dur": 1.0, "at": 44.0, "r": 38.0, "dmg": 45.0, "kb": 240.0}
const GRAB := {"anim": "grab", "hit": 0.67, "dur": 1.0, "at": 54.0, "r": 32.0, "dmg": 58.0, "kb": 300.0}
## 날뛸 때 돌진 끝 내려치기(예고가 조금 짧다)
const RAM_SLAM := {"anim": "club_slam", "hit": 0.5, "dur": 0.9, "at": 28.0, "r": 48.0, "dmg": 52.0, "kb": 280.0}
const ATTACK_CD := 0.9
## 소리 난 곳에서 둘러보는 시간
const INVESTIGATE_TIME := 3.0
## 잠든 거인 곁에서 뛰면 차는 뒤척임(1이면 깨어 주위를 움켜잡음)
const WAKE_RADIUS := 160.0
const WAKE_RATE := 0.7
## 잠결 뒤척임: STIR_EVERY초 안팎마다 STIR_TIME초 — 그동안은 곁(WAKE_RADIUS)에서 걷기만 해도 깬다
const STIR_EVERY := 10.0
const STIR_TIME := 1.8
## 깨어 움켜쥐는 힘
const WAKE_GRAB := 34.0
## 눈 먼 거인이 듣는 거리: 뛰는 소리 / 걷는 소리(가까이) / 바로 곁
const HEAR_RADIUS := 260.0
const HEAR_WALK := 115.0
const FEEL_RADIUS := 110.0
## 날뛰다 벽에 부딪히면 멈칫하는 시간
const STUN_TIME := 2.0
## 날뛸 때 냄새로 사람을 더듬어 가는 거리·빠르기(오디세우스 걷기 72보다 느리다)
const TRACK_RADIUS := 320.0
const TRACK_SPEED := 42.0

## 포도주: 한 잔 마시는 시간, 잔마다 휘두르는 횟수(2 + 잔), 잔마다 예고가 느려지고(+0.1초) 넓어지고(+10) 엉뚱해진다(+28)
const DRINK_TIME := 2.2
const SWIPE_SLOW := 0.1
const SWIPE_WIDE := 10.0
const SWIPE_MISS := 28.0
## 이 땅 거리 안에서만 휘두른다. 멀면 이 빠르기로 비틀거리며 다가온다
const SWIPE_REACH := 110.0
const LURCH_SPEED := 52.0

signal woke
signal swipes_done
signal crew_taken(c: Node2D)

var mode: int = Mode.AWAY
var facing := Vector2(1, 0.5).normalized()
var dir := 1
## 지금 가장 의심하는 사람의 의심(시야 부채꼴 색)
var suspicion := 0.0
var wake := 0.0
var level: IsoLevel
## 쫓는 사람(오디세우스 또는 부하)
var target: Node2D = null
## 사람마다 의심·냄새 시간
var _sus := {}
var _smell := {}
## 지킬 자리들: [위치, 바라볼 쪽]. 자리마다 watch_time초 머물고 다음 자리로
var posts: Array = []
var post_i := 0
var watch_time := 9.0
## 순찰 중에 부하도 노리는지(1막 밤)
var hunts_crew := false
var _watch_t := 0.0
var _goal := Vector2.INF
var _on_arrive: Callable
var _speed := WALK_SPEED
var _path := PackedVector2Array()
var _repath := 0.0
var _lost := 0.0
var _atk: Dictionary = {}
var _atk_t := 0.0
var _atk_at := Vector2.ZERO
var _hit_done := false
var _after_attack: int = Mode.CHASE
var _cd := 0.0
var _t := 0.0
var _say_cd := 0.0
var _inv_t := 0.0
var _stun_t := 0.0
var _hear_cd := 0.0
var _repick := 0.0
## 마신 잔 수(0~3)
var drunk_k := 0
var _drink_t := 0.0
var _after_drink: Callable
var _swipes_left := 0
var _swipe_gap := 0.0
## 지금까지 휘두른 횟수(봇 REPORT)
var swings := 0
var body: AnimatedSprite2D
var fight: AnimatedSprite2D
var sleeper: AnimatedSprite2D
## 외눈 불빛(눈을 잃으면 꺼짐)
var eye_light: PointLight2D
var _sniff_t := 0.0
var _sniffing := 0.0
var _sniff_told := false
var _stir_t := STIR_EVERY
var _stirring := 0.0
var _roar_t := 0.0
var _after_roar: Callable
var _step_frame := -1
var _beat_t := 0.0
var blinded := false
## 그림을 담는 틀(발 밑이 원점). 동작 그림이 없을 때 숨쉬기·걸음·내려치기 자세를 이 틀을 기울이고 늘여 낸다
var rig: Node2D
## 지금 동작을 그림 대신 코드 자세로 내는지
var _proc := true
var _anim := "idle"
var _walk_ph := 0.0


func _ready() -> void:
	z_index = 0
	rig = Node2D.new()
	add_child(rig)
	body = _sheet("polyphemus")
	if ResourceLoader.exists("res://assets/sprites/polyphemus_combat.png"):
		fight = _sheet("polyphemus_combat")
		fight.visible = false
	if ResourceLoader.exists("res://assets/sprites/polyphemus_sleep.png"):
		sleeper = _sheet("polyphemus_sleep")
		sleeper.visible = false
	body.frame_changed.connect(_on_frame)
	eye_light = PointLight2D.new()
	eye_light.texture = AssetLibrary.light_texture()
	eye_light.color = Color(1.0, 0.85, 0.3)
	eye_light.energy = 0.9
	eye_light.texture_scale = 0.32
	add_child(eye_light)
	_play("idle")


func _sheet(sheet: String) -> AnimatedSprite2D:
	var s := AnimatedSprite2D.new()
	s.centered = false
	s.sprite_frames = AssetLibrary.character_frames(sheet)
	s.offset = -AssetLibrary.character_anchor(sheet)
	var k := AssetLibrary.character_scale(sheet)
	s.scale = Vector2(k, k)
	rig.add_child(s)
	return s


## 눈 높이(취했을 때 말뚝을 찌를 곳). 잠들면 머리가 왼쪽(누운 그림)
func eye_pos() -> Vector2:
	if mode == Mode.SLEEP:
		return global_position + (Vector2(-66, -30) if sleeper else Vector2(-100, -16))
	return global_position + Vector2(facing.x * 8.0, -HEIGHT * 0.84)


func face(v: Vector2) -> void:
	if v.length() < 0.01:
		return
	facing = v.normalized()
	dir = posmod(roundi(facing.angle() / (PI / 4.0)), 8)


## 동작 재생: 그 동작이 있는 시트를 보이고 나머지는 숨긴다. 어느 시트에도 없으면 비슷한 동작으로 대신한다
const STAND_IN := {"walk": "idle", "club_slam": "idle", "grab": "idle", "roar": "idle", "drunk": "idle_shut",
	"grope": "idle_wound", "eye_wound": "idle_wound", "sleep": "idle_shut"}

func has_anim(anim: String) -> bool:
	for s in [body, fight, sleeper]:
		if s and s.sprite_frames.has_animation("%s_0" % anim):
			return true
	return false


## 걸음이 땅에 닿을 때: 쿵 소리, 가까우면 화면이 흔들린다
func _footstep() -> void:
	var p: Player = Game.player
	if p == null:
		return
	var d := Combat.ground_dist(global_position, p.global_position)
	if d > 420.0:
		return
	var near := 1.0 - d / 420.0
	Sfx.at("giant_step", global_position, -12.0 + 10.0 * near)
	if d < 240.0 and mode != Mode.DRUNK:
		Game.shake(0.6 + 2.2 * near * near)


func _on_frame() -> void:
	if not _proc and body.visible and body.animation.begins_with("walk") and body.frame % 3 == 0:
		_footstep()


## 무서움: 노려보거나 쫓는 거인이 가까우면 심장이 뛴다(가까울수록 빠르고 크게)
const DREAD_R := 220.0
func _dread(p: Player, delta: float) -> void:
	_beat_t -= delta
	if p == null or not p.is_alive() or Game.cutscene or _beat_t > 0.0:
		return
	if not mode in [Mode.WATCH, Mode.INVESTIGATE, Mode.CHASE, Mode.ATTACK, Mode.RAMPAGE, Mode.CHARGE, Mode.ROAR, Mode.GUARD, Mode.SWIPE, Mode.WALK]:
		return
	var d := Combat.ground_dist(global_position, p.global_position)
	if d > DREAD_R:
		return
	var k := 1.0 - d / DREAD_R
	_beat_t = lerpf(1.15, 0.5, k)
	Sfx.play("heartbeat", -16.0 + 12.0 * k)


## 코드 자세: 동작 그림이 없는 동작을 틀의 기울기·늘임·흔들림으로 낸다(그림이 있으면 바로 세움)
func _pose(delta: float) -> void:
	var pos := Vector2.ZERO
	var rot := 0.0
	var sc := Vector2.ONE
	var lean := signf(facing.x) if absf(facing.x) > 0.2 else 0.0
	var breathe := sin(_t * 1.7)
	eye_light.position = rig.position + Vector2(facing.x * 8.0, -HEIGHT * 0.84 + (6.0 if facing.y < -0.3 else 0.0))
	eye_light.energy = (0.9 if facing.y > -0.3 else 0.35) * (1.0 + 0.15 * sin(_t * 5.0))
	eye_light.enabled = not blinded and mode != Mode.SLEEP and mode != Mode.DRUNK
	if not _proc:
		rig.position = Vector2.ZERO
		rig.rotation = 0.0
		rig.scale = Vector2.ONE
		return
	match _anim:
		"walk", "drunk", "grope":
			var spd := maxf(_speed, 20.0) * (2.2 if mode == Mode.CHARGE else 1.0)
			var before := sin(_walk_ph)
			_walk_ph += delta * spd / 22.0
			var st := sin(_walk_ph)
			if signf(before) != signf(st):
				_footstep()
			pos.y = -absf(st) * 3.5
			rot = 0.045 * st + lean * (0.14 if mode == Mode.CHARGE else 0.05)
			sc = Vector2(1.0 + 0.02 * absf(st), 1.0 - 0.025 * absf(cos(_walk_ph)))
			if _anim == "drunk":
				rot += 0.13 * sin(_t * 2.3)
			elif _anim == "grope":
				rot += 0.07 * sin(_t * 1.3)
				pos.x = 4.0 * sin(_t * 1.3)
		"club_slam", "grab":
			var hit := float(_atk.get("hit", 0.6))
			var u := _atk_t / maxf(0.05, hit)
			if u < 1.0:   # 예고: 뒤로 젖혀 크게 들어 올림(곤봉) / 몸을 낮춰 웅크림(잡기)
				var e := u * u
				if _anim == "club_slam":
					rot = -lean * 0.2 * e
					sc = Vector2(1.0 - 0.04 * e, 1.0 + 0.09 * e)
					pos.y = -5.0 * e
				else:
					rot = -lean * 0.1 * e
					sc = Vector2(1.0 + 0.06 * e, 1.0 - 0.07 * e)
			else:   # 내려침·뻗음 뒤 천천히 복귀
				var r := clampf((_atk_t - hit) / maxf(0.1, float(_atk.get("dur", 1.0)) - hit), 0.0, 1.0)
				var f := 1.0 - r
				if _anim == "club_slam":
					rot = lean * 0.24 * f
					sc = Vector2(1.0 + 0.07 * f, 1.0 - 0.12 * f)
				else:
					pos = facing * 20.0 * f
					rot = lean * 0.16 * f
					sc = Vector2(1.0 + 0.04 * f, 1.0 - 0.04 * f)
		"roar":
			var up := minf(1.0, (1.0 - clampf(_roar_t / 0.9, 0.0, 1.0)) * 3.0)
			rot = -lean * 0.08 * up + 0.025 * sin(_t * 38.0) * up
			sc = Vector2(1.0 + 0.05 * up, 1.0 + 0.08 * up)
		"eye_wound":
			rot = 0.12 * sin(_t * 23.0) * clampf(_roar_t, 0.0, 1.0) + 0.06 * sin(_t * 3.0)
			sc = Vector2(1.0 + 0.04 * sin(_t * 9.0), 0.94 + 0.04 * sin(_t * 7.0))
		"sleep":
			rot = -PI * 0.47
			sc = Vector2(0.78 + 0.02 * breathe, 1.0)
			if _stirring > 0.0:
				rot += 0.08 * sin(_t * 6.0)
		_:
			var sniff := _sniffing > 0.0
			sc = Vector2(1.0 - 0.008 * breathe, 1.0 + (0.035 * sin(_t * 9.0) if sniff else 0.018 * breathe))
			if sniff:
				rot = -lean * 0.05
				pos.y = -2.0
			if mode == Mode.STUNNED:
				rot = 0.15 * sin(_t * 9.0)
			elif mode == Mode.DRINK:
				rot = -lean * 0.2 * sin(clampf(1.0 - _drink_t / DRINK_TIME, 0.0, 1.0) * PI)
			elif mode == Mode.SWIPE:
				rot = 0.05 * drunk_k * sin(_t * 2.1)
	var w := minf(1.0, delta * 14.0)
	rig.position = rig.position.lerp(pos, w)
	rig.rotation = rot if _anim == "sleep" else lerp_angle(rig.rotation, rot, w)
	rig.scale = sc if _anim == "sleep" else rig.scale.lerp(sc, w)


## 킁킁 냄새 맡기(지킬 때): 맡는 중이면 true
func _sniff(delta: float) -> bool:
	if _sniffing > 0.0:
		_sniffing -= delta
		return _sniffing > 0.0
	_sniff_t += delta
	if _sniff_t >= SNIFF_EVERY:
		_sniff_t = randf_range(-2.5, 2.5)
		_sniffing = SNIFF_TIME
		Fx.text(global_position + Vector2(0, TEXT_Y), Lines.t("fx.sniff"), Color(0.8, 0.95, 0.6))
		Sfx.at("roar", global_position, -20.0)
		if not _sniff_told:
			_sniff_told = true
			Game.show_hint(Lines.t("hint.sniff"))
		return true
	return false


func _play(anim: String) -> void:
	_anim = anim
	_proc = not has_anim(anim)
	if _proc:
		anim = STAND_IN.get(anim, "idle")
		if blinded and anim == "idle" and has_anim("idle_wound"):
			anim = "idle_wound"
		if not has_anim(anim):
			anim = "idle"
	var spr := body
	for s in [fight, sleeper]:
		if s and s.sprite_frames.has_animation("%s_0" % anim):
			spr = s
	var d := dir
	if spr == sleeper:
		d = 1 if _stirring > 0.0 else 0
	for s in [body, fight, sleeper]:
		if s:
			s.visible = s == spr
	var key := "%s_%d" % [anim, d]
	if spr.animation != key or not spr.is_playing():
		spr.play(key)


# ── 바깥에서 부르는 것 ─────────────────────────────────
## goal로 걸어가서 도착하면 done을 부른다(연출·자리 옮기기)
func walk_to(goal: Vector2, done: Callable = Callable(), speed := WALK_SPEED, m := Mode.WALK) -> void:
	mode = m
	_goal = goal
	_on_arrive = done
	_speed = speed
	_path = PackedVector2Array()
	_repath = 0.0


func watch() -> void:
	mode = Mode.WATCH
	suspicion = 0.0
	_sus.clear()
	_smell.clear()
	_watch_t = 0.0
	if not posts.is_empty():
		face(posts[post_i][1])


func sleep_on(pos: Vector2) -> void:
	mode = Mode.SLEEP
	global_position = pos
	wake = 0.0
	dir = 2
	_stir_t = STIR_EVERY
	_stirring = 0.0
	_play("sleep")
	body.modulate = Color(0.85, 0.85, 0.9)
	z_index = 1   # 침상 그림 위에 눕는다


func blind() -> void:
	mode = Mode.BLIND
	blinded = true
	z_index = 0
	body.speed_scale = 1.0
	body.modulate = Color(1, 1, 1)
	suspicion = 0.0


## 눈을 찔린 직후: 일어서서 얼굴을 움켜쥐고 울부짖는다(그림이 있으면 그 길이, 없으면 1.6초), 끝나면 then
func wound(then: Callable) -> void:
	blind()
	mode = Mode.WOUND
	_after_roar = then
	_play("eye_wound")
	_roar_t = _anim_len("eye_wound") if not _proc else 1.6
	Sfx.at("roar", global_position, 2.0)
	Game.shake(10.0)


## 포효(쫓기 전 예고): 멈춰 울부짖고 나서 then
func roar(then: Callable) -> void:
	mode = Mode.ROAR
	_after_roar = then
	_goal = Vector2.INF
	_play("roar")
	_roar_t = 0.9 if _proc else maxf(0.9, _anim_len("roar"))
	Sfx.at("roar", global_position, 0.0)
	Game.shake(6.0)


func _anim_len(anim: String) -> float:
	for s in [body, fight]:
		if s == null:
			continue
		var key := "%s_%d" % [anim, dir]
		if s.sprite_frames.has_animation(key):
			return s.sprite_frames.get_frame_count(key) / maxf(1.0, s.sprite_frames.get_animation_speed(key))
	return 1.0


## 눈을 잃고 날뛴다: 소리 난 곳으로 돌진해 내려친다
func rampage() -> void:
	blind()
	mode = Mode.RAMPAGE
	_goal = Vector2.INF
	_on_arrive = Callable()
	_cd = 1.5


func guard_at(pos: Vector2, look: Vector2) -> void:
	mode = Mode.GUARD
	global_position = pos
	face(look)
	body.rotation = 0.0


## 포도주 한 잔: 마시고 나서 then을 부른다
func drink(cup: int, then: Callable) -> void:
	mode = Mode.DRINK
	drunk_k = cup
	_drink_t = DRINK_TIME
	_after_drink = then
	_goal = Vector2.INF
	Sfx.at("eat", global_position, -2.0)


## 취해서 n번 휘두른다(빨간 예고 원). 끝나면 swipes_done
func swipe(n: int) -> void:
	mode = Mode.SWIPE
	_swipes_left = n
	_swipe_gap = 0.7


## 소리: loud는 0~1(미끼 돌 1, 달리기 0.6). 깨어 있으면 가서 둘러보고, 날뛰는 중이면 돌진, 자는 중이면 뒤척임이 찬다
func hear(pos: Vector2, loud := 1.0) -> void:
	if _hear_cd > 0.0:
		return
	match mode:
		Mode.WATCH, Mode.INVESTIGATE:
			_investigate(pos)
		Mode.WALK:
			if _on_arrive.is_null() or _on_arrive == watch:
				_investigate(pos)
		Mode.RAMPAGE:
			_charge(pos)
		Mode.SLEEP:
			wake += 0.25 * loud


func _investigate(pos: Vector2) -> void:
	_hear_cd = 1.0
	Fx.text(global_position + Vector2(0, TEXT_Y), "?", Color(1, 0.9, 0.5))
	face(pos - global_position)
	_inv_t = INVESTIGATE_TIME
	walk_to(pos, func(): mode = Mode.INVESTIGATE, WALK_SPEED * 1.3, Mode.WALK)


func _charge(pos: Vector2) -> void:
	_hear_cd = 0.6
	mode = Mode.CHARGE
	_goal = pos
	face(pos - global_position)
	Sfx.at("thunder", global_position, -6.0)
	Fx.text(global_position + Vector2(0, TEXT_Y), Lines.t("fx.who"), Color(1, 0.45, 0.3))


## 오디세우스가 보이는지(시야 부채꼴 + 밝기 + 벽). 부하에게도 쓴다
func sees(p: Node2D) -> bool:
	var to := p.global_position - global_position
	if absf(rad_to_deg(facing.angle_to(to))) > ARC * 0.5:
		return false
	if Combat.ground_dist(global_position, p.global_position) > sight_range(p.global_position):
		return false
	return level.line_clear(global_position + facing * 20.0, p.global_position, 2.0)


func sight_range(pos: Vector2) -> float:
	return SIGHT * lerpf(DARK_K, 1.0, level.light_at(pos))


## 그 사람 둘레 냄새 원 반지름(곁에 모인 사람 수만큼 커짐)
func smell_radius(p: Node2D) -> float:
	var n := 0
	for o in _people():
		if o != p and o.global_position.distance_to(p.global_position) < 50.0:
			n += 1
	return SMELL_R * (SNIFF_K if _sniffing > 0.0 else 1.0) + SMELL_GROUP * n


## 시야 부채꼴을 그릴 때인지
func watching() -> bool:
	return mode == Mode.WATCH or mode == Mode.INVESTIGATE or (mode == Mode.WALK and (_on_arrive.is_null() or _on_arrive == watch))


## 노릴 수 있는 사람: 오디세우스 + (밤에는) 보이는 부하
func _people() -> Array:
	var out: Array = []
	var p: Player = Game.player
	if p and p.is_alive() and p.visible:
		out.append(p)
	if hunts_crew and Game.squad:
		for c in Game.squad.members:
			if is_instance_valid(c) and c.visible and c.is_alive():
				out.append(c)
	return out


## 오디세우스 + 부하 모두(날뛸 때)
func _all_people() -> Array:
	var keep := hunts_crew
	hunts_crew = true
	var out := _people()
	hunts_crew = keep
	return out


# ── 매 프레임 ─────────────────────────────────────────
func _process(delta: float) -> void:
	if mode == Mode.AWAY:
		visible = false
		return
	visible = true
	_t += delta
	_cd -= delta
	_say_cd -= delta
	_hear_cd -= delta
	var p: Player = Game.player
	_dread(p, delta)
	_update(p, delta)
	_pose(delta)


func _update(p: Player, delta: float) -> void:
	match mode:
		Mode.WALK, Mode.DRUNK:
			_step_walk(delta)
			_look_for(delta)
		Mode.ROAR, Mode.WOUND:
			_roar_t -= delta
			if mode == Mode.ROAR and target and is_instance_valid(target):
				face(target.global_position - global_position)
			if _roar_t <= 0.0:
				var cb := _after_roar
				_after_roar = Callable()
				if cb.is_valid():
					cb.call()
		Mode.WATCH:
			_play("idle")
			if _sniff(delta):
				pass
			elif not posts.is_empty():
				var base: Vector2 = posts[post_i][1]
				face(base.rotated(0.55 * sin(_t * 0.6)))
				_watch_t += delta
				if _watch_t > watch_time and posts.size() > 1:
					post_i = (post_i + 1) % posts.size()
					walk_to(posts[post_i][0], watch)
			_look_for(delta)
		Mode.INVESTIGATE:
			_play("idle")
			face(facing.rotated(delta * 1.4 * (1.0 if fmod(_t, 2.0) < 1.0 else -1.0)))
			_inv_t -= delta
			_look_for(delta)
			if mode == Mode.INVESTIGATE and _inv_t <= 0.0:
				_back_to_post()
		Mode.CHASE:
			_chase(delta)
		Mode.ATTACK:
			_attack_update(delta)
		Mode.WAIT_WINE:
			_play("idle")
			if p:
				face(p.global_position - global_position)
			if not level.call("holding_wine"):
				_start_chase(p)
		Mode.SLEEP:
			_sleep(p, delta)
		Mode.BLIND:
			_step_walk(delta)
		Mode.RAMPAGE:
			_rampage(delta)
		Mode.CHARGE:
			_charge_step(delta)
		Mode.DRINK:
			_play("idle")
			_drink_t -= delta
			if _drink_t <= 0.0:
				mode = Mode.WAIT_WINE
				var cb := _after_drink
				_after_drink = Callable()
				if cb.is_valid():
					cb.call()
		Mode.SWIPE:
			_swipe_step(delta, p)
		Mode.STUNNED:
			_play("idle")
			_stun_t -= delta
			if _stun_t <= 0.0:
				mode = Mode.RAMPAGE
		Mode.GUARD:
			_guard(p)


## 취한 휘두르기: 오디세우스 쪽(잔이 늘수록 엉뚱하게)으로 내려치기·움켜잡기를 번갈아
func _swipe_step(delta: float, p: Player) -> void:
	_play("idle")
	_swipe_gap -= delta
	if _swipe_gap > 0.0:
		return
	if _swipes_left <= 0 or p == null or not p.is_alive():
		mode = Mode.WAIT_WINE
		swipes_done.emit()
		return
	# 멀리 물러나면 비틀거리며 다가온다(곁에서 휘두른 것만 센다 — 도망쳐서는 끝나지 않는다)
	var dist := Combat.ground_dist(global_position, p.global_position)
	if dist > SWIPE_REACH:
		var v := (p.global_position - global_position).normalized() * LURCH_SPEED
		global_position += v.rotated(0.4 * sin(_t * 1.9)) * delta
		face(v)
		_play("walk")
		return
	_swipes_left -= 1
	var base: Dictionary = SLAM if _swipes_left % 2 == 0 else GRAB
	var spec := base.duplicate()
	spec["hit"] = float(base["hit"]) + SWIPE_SLOW * drunk_k
	spec["dur"] = float(base["dur"]) + SWIPE_SLOW * drunk_k
	spec["r"] = float(base["r"]) + SWIPE_WIDE * drunk_k
	var miss := Vector2(randf_range(-1, 1), randf_range(-0.5, 0.5)) * SWIPE_MISS * drunk_k
	_after_attack = Mode.SWIPE
	_start_attack(spec, p.global_position + p.velocity * 0.3 + miss)
	# 사람 쪽으로 닿게: 앞 거리를 오디세우스까지(최대 90)
	var reach := clampf(dist, 30.0, 95.0)
	_atk_at = global_position + facing * reach + miss * 0.5
	_swipe_gap = maxf(0.3, 0.55 - 0.08 * drunk_k)


func _step_walk(delta: float) -> void:
	if _goal == Vector2.INF:
		_play("idle")
		return
	if global_position.distance_to(_goal) < 6.0:
		_goal = Vector2.INF
		_play("idle")
		var cb := _on_arrive
		_on_arrive = Callable()
		if cb.is_valid():
			cb.call()
		return
	_repath -= delta
	if _path.is_empty() or _repath <= 0.0:
		_path = level.find_path(global_position, _goal)
		_repath = 1.0
		if _path.is_empty():
			_path = PackedVector2Array([_goal])
	var next := _path[0]
	if global_position.distance_to(next) < 5.0 and _path.size() > 1:
		_path.remove_at(0)
		next = _path[0]
	var v := (next - global_position).normalized() * _speed
	if mode == Mode.DRUNK or mode == Mode.BLIND or mode == Mode.RAMPAGE:
		v = v.rotated(0.5 * sin(_t * 1.7))
	global_position += v * delta
	face(v)
	_play("drunk" if mode == Mode.DRUNK else ("grope" if blinded else "walk"))
	body.speed_scale = _speed / WALK_SPEED


## 보기·냄새: 사람마다 의심을 채우고, 다 찬 사람을 쫓는다
func _look_for(delta: float) -> void:
	if mode == Mode.DRUNK or Game.cutscene:
		suspicion = maxf(0.0, suspicion - delta * 0.5)
		return
	var p: Player = Game.player
	if p and p.visible and level.call("holding_wine") and sees(p):
		mode = Mode.WAIT_WINE
		_goal = Vector2.INF
		if _say_cd <= 0.0:
			_say_cd = 6.0
			Fx.text(global_position + Vector2(0, TEXT_Y), Lines.t("fx.smell_wine"), Color(1, 0.85, 0.5))
		return
	var top := 0.0
	for who in _people():
		var s: float = _sus.get(who, 0.0)
		var d := Combat.ground_dist(global_position, who.global_position)
		var seen := sees(who)
		if seen:
			var near := 1.0 + 1.5 * (1.0 - d / SIGHT)
			var fast := 1.5 if who.velocity.length() > 85.0 else 1.0
			s = minf(1.0, s + delta / NOTICE * near * fast)
		else:
			s = maxf(0.0, s - delta * 0.35)
		# 냄새: 원 안에 오래 있으면 돌아보고 알아챈다
		var sm: float = _smell.get(who, 0.0)
		if d < smell_radius(who):
			sm += delta
			if sm > SMELL_TIME * 0.5 and not seen:
				face(facing.slerp((who.global_position - global_position).normalized(), minf(1.0, delta * 3.0)))
			if sm >= SMELL_TIME:
				s = 1.0
		else:
			sm = maxf(0.0, sm - delta * 0.5)
		_smell[who] = sm
		_sus[who] = s
		top = maxf(top, s)
		if s >= 1.0:
			_start_chase(who)
			return
	suspicion = top


func _start_chase(who: Node2D) -> void:
	if who == null:
		return
	target = who
	suspicion = 1.0
	_lost = 0.0
	_path = PackedVector2Array()
	face(who.global_position - global_position)
	Fx.text(global_position + Vector2(0, TEXT_Y), Lines.t("fx.giant_seen"), Color(1, 0.35, 0.25))
	roar(func(): mode = Mode.CHASE)
	if who is Player:
		Game.stats["giant_seen"] = Game.stats.get("giant_seen", 0) + 1
	elif level.has_method("on_crew_spotted"):
		level.on_crew_spotted(who)


func _chase(delta: float) -> void:
	if target == null or not is_instance_valid(target) or not target.visible or (target.has_method("is_alive") and not target.is_alive()):
		_back_to_post()
		return
	if target is Player and level.call("holding_wine"):
		mode = Mode.WAIT_WINE
		return
	if sees(target) or Combat.ground_dist(global_position, target.global_position) < 90.0:
		_lost = 0.0
	else:
		_lost += delta
		if _lost > LOSE_TIME:
			Fx.text(global_position + Vector2(0, TEXT_Y), "?", Color(1, 0.9, 0.5))
			_back_to_post()
			return
	var d := Combat.ground_dist(global_position, target.global_position)
	if d < 70.0 and _cd <= 0.0:
		_after_attack = Mode.CHASE
		_start_attack(GRAB if d > 52.0 or not target is Player else SLAM, target.global_position)
		return
	_goal = target.global_position
	_speed = CHASE_SPEED
	_repath = minf(_repath, 0.4)
	_step_walk(delta)


func _back_to_post() -> void:
	suspicion = 0.0
	target = null
	_sus.clear()
	_smell.clear()
	if posts.is_empty():
		mode = Mode.WATCH
		return
	walk_to(posts[post_i][0], watch)


func _start_attack(spec: Dictionary, at: Vector2) -> void:
	mode = Mode.ATTACK
	swings += 1
	_atk = spec
	_atk_t = 0.0
	_hit_done = false
	face(at - global_position)
	_atk_at = global_position + facing * float(spec["at"])
	_play(spec["anim"])


func _attack_update(_delta: float) -> void:
	_atk_t += get_process_delta_time()
	if not _hit_done and _atk_t >= float(_atk["hit"]):
		_hit_done = true
		_resolve_hit()
	if _atk_t >= float(_atk["dur"]):
		_cd = ATTACK_CD
		mode = _after_attack
		_after_attack = Mode.CHASE
		if mode == Mode.CHASE:
			_lost = 0.0
		_play("idle")


## 공격이 닿는 순간: 오디세우스는 다치고(움켜잡기면 잠시 꼼짝 못함), 부하는 끌려간다
func _resolve_hit() -> void:
	var heavy_slam: bool = _atk.get("anim", "") == "club_slam"
	Game.shake(7.0 if heavy_slam else 4.0)
	Sfx.at("hit_heavy", _atk_at, 0.0)
	Fx.ring(_atk_at, float(_atk["r"]) * 1.2, Color(0.9, 0.75, 0.55), 0.4)
	if heavy_slam:
		Fx.anim("dust", _atk_at)
	var r := float(_atk["r"]) + 8.0
	var p: Player = Game.player
	if p and p.is_alive() and p.visible and Combat.ground_dist(_atk_at, p.global_position) < r:
		var res := p.take_hit(float(_atk["dmg"]), self, float(_atk["kb"]), true)
		if res == "hit" or res == "killed":
			Game.hitstop(0.08)
			if not heavy_slam:
				p.stagger(0.9)
				Fx.text(p.global_position + Vector2(0, -64), Lines.t("fx.grabbed"), Color(1, 0.5, 0.35))
	if Game.squad:
		for c in Game.squad.members.duplicate():
			if is_instance_valid(c) and c.visible and Combat.ground_dist(_atk_at, c.global_position) < r:
				crew_taken.emit(c)
				break
	if target and not is_instance_valid(target):
		target = null


## 아직 맞지 않은 공격이 pos에 닿는지: 닿으면 예고 진행(0~1), 아니면 -1 (봇이 구르기에 씀)
func danger_at(pos: Vector2) -> float:
	if mode != Mode.ATTACK or _hit_done:
		return -1.0
	if Combat.ground_dist(_atk_at, pos) > float(_atk["r"]) + 10.0:
		return -1.0
	return clampf(_atk_t / float(_atk["hit"]), 0.0, 1.0)


## 바닥에 그리는 공격 예고(빨간 타원)·돌진 길·냄새 원 — 레벨이 시야 층에 그린다
func draw_warning(c: CanvasItem) -> void:
	if mode == Mode.CHARGE and _goal != Vector2.INF:
		c.draw_line(global_position, _goal, Color(1.0, 0.3, 0.2, 0.35), 3.0)
	if watching() or mode == Mode.CHASE:
		var p: Player = Game.player
		if p and p.visible:
			var k: float = clampf(_smell.get(p, 0.0) / SMELL_TIME, 0.0, 1.0)
			c.draw_set_transform(global_position, 0.0, Vector2(1.0, 1.0 / Combat.Y_STRETCH))
			var sr := smell_radius(p) if _sniffing > 0.0 else SMELL_R
			c.draw_arc(Vector2.ZERO, sr, 0.0, TAU, 40, Color(0.75, 0.9, 0.5, 0.18 + 0.4 * k + (0.25 if _sniffing > 0.0 else 0.0)), 1.0 + 2.0 * k)
			c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if mode != Mode.ATTACK or _hit_done:
		return
	var k2 := clampf(_atk_t / float(_atk["hit"]), 0.0, 1.0)
	var rr := float(_atk["r"])
	c.draw_set_transform(_atk_at, 0.0, Vector2(1.0, 1.0 / Combat.Y_STRETCH))
	c.draw_circle(Vector2.ZERO, rr, Color(1.0, 0.2, 0.1, 0.12 + 0.25 * k2))
	c.draw_arc(Vector2.ZERO, rr * k2, 0.0, TAU, 28, Color(1.0, 0.35, 0.2, 0.7), 1.5)
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _sleep(p: Player, delta: float) -> void:
	_play("sleep")
	if fmod(_t, 2.6) < delta:
		Fx.text(global_position + Vector2(-90, -60), "Z z", Color(0.75, 0.8, 1.0))
	# 뒤척임: 그동안은 곁에서 걷기만 해도 깬다
	_stir_t -= delta
	if _stirring > 0.0:
		_stirring -= delta
	elif _stir_t <= 0.0:
		_stir_t = STIR_EVERY + randf_range(-3.0, 3.0)
		_stirring = STIR_TIME
		Sfx.at("roar", global_position, -18.0)
		Fx.text(global_position + Vector2(-60, -70), Lines.t("fx.stir"), Color(1, 0.7, 0.5))
	var d := Combat.ground_dist(global_position, p.global_position) if p and p.is_alive() else INF
	var v := p.velocity.length() if p else 0.0
	if v > 85.0 and d < WAKE_RADIUS:
		wake += delta * WAKE_RATE
	elif v > 10.0 and _stirring > 0.0 and d < WAKE_RADIUS:
		wake += delta * 0.9
	elif v > 10.0 and d < WAKE_RADIUS * 0.4:
		wake += delta * 0.18
	else:
		wake = maxf(0.0, wake - delta * 0.12)
	if wake >= 1.0:
		wake = 0.35
		woke.emit()
		Sfx.at("thunder", global_position, -6.0)
		Game.shake(3.0)
		Fx.text(global_position + Vector2(-60, -90), Lines.t("fx.stir"), Color(1, 0.6, 0.4))
		# 누운 채로 소리 난 쪽을 더듬어 움켜쥔다
		if p and Combat.ground_dist(global_position + Vector2(-60, 0), p.global_position) < 120.0:
			var hit := p.take_hit(WAKE_GRAB, self, 200.0, true)
			if hit == "hit":
				p.stagger(0.6)


## 날뜀: 천천히 더듬어 돌다가, 들리면 돌진. 오디세우스는 뛰면 멀리서, 걸어도 가까우면 들린다. 움직이는 부하도 들린다
func _rampage(delta: float) -> void:
	# 냄새로 가장 가까운 사람 쪽을 더듬어 간다(가만히 서 있으면 결국 찾아온다). 없으면 아무 데나
	var near: Node2D = null
	var nd := TRACK_RADIUS
	for who in _all_people():
		var d := Combat.ground_dist(global_position, who.global_position)
		if d < nd:
			nd = d
			near = who
	_repick -= delta
	if near and _repick <= 0.0:
		_repick = 1.5
		_goal = near.global_position + Vector2(randf_range(-30, 30), randf_range(-16, 16))
	elif _goal == Vector2.INF or global_position.distance_to(_goal) < 8.0:
		_goal = global_position + Vector2(randf_range(-90, 90), randf_range(-50, 50))
		if level.is_blocked_world(_goal):
			_goal = Vector2.INF
	_speed = TRACK_SPEED
	_step_walk(delta)
	if _cd > 0.0:
		return
	var p: Player = Game.player
	if p and p.is_alive() and p.visible:
		var d := Combat.ground_dist(global_position, p.global_position)
		var v := p.velocity.length()
		if (v > 85.0 and d < HEAR_RADIUS) or (v > 10.0 and d < HEAR_WALK) or d < 40.0:
			_charge(p.global_position)
			return
	if Game.squad:
		for c in Game.squad.members:
			if is_instance_valid(c) and c.visible and c.velocity.length() > 30.0 \
					and Combat.ground_dist(global_position, c.global_position) < HEAR_RADIUS * 0.8:
				_charge(c.global_position)
				return


func _charge_step(delta: float) -> void:
	var to := _goal - global_position
	if to.length() < 14.0:
		_after_attack = Mode.RAMPAGE
		_start_attack(RAM_SLAM, _goal)
		_cd = 1.6
		return
	var step := to.normalized() * CHARGE_SPEED * delta
	if level.is_blocked_world(global_position + to.normalized() * 24.0):
		# 벽·바위에 부딪힘: 멈칫
		mode = Mode.STUNNED
		_stun_t = STUN_TIME
		_goal = Vector2.INF
		_cd = STUN_TIME
		Game.shake(8.0)
		Sfx.at("stone", global_position, 0.0)
		Fx.anim("dust", global_position + to.normalized() * 24.0)
		Fx.text(global_position + Vector2(0, TEXT_Y), "!!", Color(1, 0.8, 0.4))
		if level.has_method("on_giant_wall"):
			level.on_giant_wall(global_position + to.normalized() * 24.0)
		return
	global_position += step
	face(to)
	_play("walk")
	body.speed_scale = 2.4


func _guard(p: Player) -> void:
	_play("idle")
	if p == null or not p.is_alive() or not p.visible or _cd > 0.0:
		return
	var d := Combat.ground_dist(global_position, p.global_position)
	if d < FEEL_RADIUS or (p.velocity.length() > 85.0 and d < HEAR_RADIUS * 0.75):
		_after_attack = Mode.GUARD
		var spec := GRAB if d > 52.0 else SLAM
		if _say_cd <= 0.0:
			_say_cd = 5.0
			Fx.text(global_position + Vector2(0, TEXT_Y), Lines.t("fx.who"), Color(1, 0.5, 0.35))
		_start_attack(spec, p.global_position)
		_cd = 2.2
