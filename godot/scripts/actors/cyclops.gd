class_name Cyclops
extends Node2D
## 챕터 3 폴리페모스(외눈 거인). 사람의 세 배 — 칼로는 쓰러뜨릴 수 없다(그룹 "actors"에 넣지 않아 칼·화살·봇이 무시한다).
## 상태: 지킴(자리마다 시야 부채꼴로 둘러봄) → 보이면 의심이 차고 다 차면 쫓아와 곤봉 내려치기·움켜잡기
## → 포도주를 든 오디세우스는 치지 않고 기다림 → 취해 비틀거리며 침상으로 → 잠듦(뛰는 소리에 뒤척임)
## → 눈을 잃음: 더듬어 입구로 가 바위를 치우고 앉아 지킨다(가까이 오거나 뛰는 소리가 나면 그쪽을 움켜잡음).
## 그림: assets/sprites/polyphemus(대기·걷기)·polyphemus_combat(곤봉·움켜잡기), 칸 320×320, 한 줄 = 한 방향.
## 취함·잠듦·눈 부상 동작은 아직 없어 대기 그림을 기울이거나 눕혀 쓴다(ART_PLAN C3-POL).

enum Mode { AWAY, WALK, WATCH, CHASE, ATTACK, WAIT_WINE, DRUNK, SLEEP, BLIND, GUARD }

## 시야: 땅 거리, 부채꼴 각도(도), 이만큼(초) 계속 보이면 쫓는다
const SIGHT := 200.0
const ARC := 84.0
const NOTICE := 1.0
const WALK_SPEED := 34.0
const CHASE_SPEED := 50.0
const DRUNK_SPEED := 24.0
## 쫓다가 이만큼 못 보면 자리로 돌아감
const LOSE_TIME := 3.5
## 공격: 프레임 6장 6fps, 4번째 장면(0.67초)에 맞음. at = 몸에서 앞쪽 거리, r = 맞는 반지름(땅 거리)
const SLAM := {"anim": "club_slam", "hit": 0.67, "dur": 1.0, "at": 50.0, "r": 36.0, "dmg": 34.0, "kb": 240.0}
const GRAB := {"anim": "grab", "hit": 0.67, "dur": 1.0, "at": 62.0, "r": 28.0, "dmg": 24.0, "kb": 300.0}
const ATTACK_CD := 1.1
## 잠든 거인 곁에서 뛰면 차는 뒤척임(1이면 깨어 주위를 움켜잡음)
const WAKE_RADIUS := 160.0
const WAKE_RATE := 0.45
## 눈 먼 거인이 듣는 거리(뛰는 소리)와 가까이 오면 바로 아는 거리
const HEAR_RADIUS := 170.0
const FEEL_RADIUS := 95.0

signal woke

var mode: int = Mode.AWAY
var facing := Vector2(1, 0.5).normalized()
var dir := 1
var suspicion := 0.0
var wake := 0.0
var level: IsoLevel
## 지킬 자리들: [위치, 바라볼 쪽]. 자리마다 watch_time초 머물고 다음 자리로
var posts: Array = []
var post_i := 0
var watch_time := 9.0
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
var _cd := 0.0
var _t := 0.0
var _say_cd := 0.0
var body: AnimatedSprite2D
var fight: AnimatedSprite2D
var _shadow_k := 1.0


func _ready() -> void:
	z_index = 0
	body = _sheet("polyphemus")
	fight = _sheet("polyphemus_combat")
	fight.visible = false
	_play("idle")


func _sheet(sheet: String) -> AnimatedSprite2D:
	var s := AnimatedSprite2D.new()
	s.centered = false
	s.sprite_frames = AssetLibrary.character_frames(sheet)
	s.offset = -AssetLibrary.character_anchor(sheet)
	var k := AssetLibrary.character_scale(sheet)
	s.scale = Vector2(k, k)
	add_child(s)
	return s


## 눈 높이(취했을 때 말뚝을 찌를 곳)
func eye_pos() -> Vector2:
	if mode == Mode.SLEEP:
		return global_position + Vector2(-118, -16)
	return global_position + Vector2(0, -132)


func face(v: Vector2) -> void:
	if v.length() < 0.01:
		return
	facing = v.normalized()
	dir = posmod(roundi(facing.angle() / (PI / 4.0)), 8)


func _play(anim: String) -> void:
	var combat := anim == "club_slam" or anim == "grab"
	body.visible = not combat
	fight.visible = combat
	var spr := fight if combat else body
	var key := "%s_%d" % [anim, dir]
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
	_watch_t = 0.0
	if not posts.is_empty():
		face(posts[post_i][1])


func sleep_on(pos: Vector2) -> void:
	mode = Mode.SLEEP
	global_position = pos
	wake = 0.0
	dir = 2
	_play("idle")
	body.speed_scale = 0.35
	body.rotation = -PI * 0.47
	body.modulate = Color(0.85, 0.85, 0.9)
	z_index = 1   # 침상 그림 위에 눕는다


func blind() -> void:
	mode = Mode.BLIND
	z_index = 0
	body.rotation = 0.0
	body.speed_scale = 1.0
	body.modulate = Color(1, 1, 1)
	suspicion = 0.0


func guard_at(pos: Vector2, look: Vector2) -> void:
	mode = Mode.GUARD
	global_position = pos
	face(look)
	body.rotation = 0.0


## 오디세우스가 보이는지(시야 부채꼴 + 밝기 + 벽)
func sees(p: Node2D) -> bool:
	var to := p.global_position - global_position
	if absf(rad_to_deg(facing.angle_to(to))) > ARC * 0.5:
		return false
	var reach := sight_range(p.global_position)
	if Combat.ground_dist(global_position, p.global_position) > reach:
		return false
	return level.line_clear(global_position + facing * 20.0, p.global_position, 2.0)


func sight_range(pos: Vector2) -> float:
	return SIGHT * lerpf(0.6, 1.0, level.light_at(pos))


## 시야 부채꼴을 그릴 때인지
func watching() -> bool:
	return mode == Mode.WATCH or (mode == Mode.WALK and _on_arrive.is_null())


# ── 매 프레임 ─────────────────────────────────────────
func _process(delta: float) -> void:
	if mode == Mode.AWAY:
		visible = false
		return
	visible = true
	_t += delta
	_cd -= delta
	_say_cd -= delta
	var p: Player = Game.player
	match mode:
		Mode.WALK, Mode.DRUNK:
			_step_walk(delta)
			if mode == Mode.DRUNK:
				body.rotation = 0.12 * sin(_t * 2.3)
			_look_for(p, delta)
		Mode.WATCH:
			_play("idle")
			if not posts.is_empty():
				var base: Vector2 = posts[post_i][1]
				face(base.rotated(0.55 * sin(_t * 0.6)))
				_watch_t += delta
				if _watch_t > watch_time and posts.size() > 1:
					post_i = (post_i + 1) % posts.size()
					walk_to(posts[post_i][0], watch)
			_look_for(p, delta)
		Mode.CHASE:
			_chase(p, delta)
		Mode.ATTACK:
			_attack_update(p, delta)
		Mode.WAIT_WINE:
			_play("idle")
			if p:
				face(p.global_position - global_position)
			if not level.call("holding_wine"):
				_start_chase()
		Mode.SLEEP:
			_sleep(p, delta)
		Mode.BLIND:
			_step_walk(delta)
		Mode.GUARD:
			_guard(p, delta)


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
	if mode == Mode.DRUNK or mode == Mode.BLIND:
		v = v.rotated(0.5 * sin(_t * 1.7))
	global_position += v * delta
	face(v)
	_play("walk")
	body.speed_scale = _speed / WALK_SPEED


func _look_for(p: Player, delta: float) -> void:
	if p == null or not p.is_alive() or not p.visible or mode == Mode.DRUNK or Game.cutscene:
		suspicion = maxf(0.0, suspicion - delta * 0.5)
		return
	if level.call("holding_wine") and sees(p):
		mode = Mode.WAIT_WINE
		_goal = Vector2.INF
		if _say_cd <= 0.0:
			_say_cd = 6.0
			Fx.text(global_position + Vector2(0, -170), Lines.t("fx.smell_wine"), Color(1, 0.85, 0.5))
		return
	if sees(p):
		var near := 1.0 + 1.5 * (1.0 - Combat.ground_dist(global_position, p.global_position) / SIGHT)
		suspicion = minf(1.0, suspicion + delta / NOTICE * near * (1.5 if p.running else 1.0))
		if suspicion >= 1.0:
			_start_chase()
	else:
		suspicion = maxf(0.0, suspicion - delta * 0.35)


func _start_chase() -> void:
	mode = Mode.CHASE
	suspicion = 1.0
	_lost = 0.0
	_path = PackedVector2Array()
	Sfx.at("thunder", global_position, -2.0)
	Game.shake(4.0)
	Fx.text(global_position + Vector2(0, -170), Lines.t("fx.giant_seen"), Color(1, 0.35, 0.25))


func _chase(p: Player, delta: float) -> void:
	if p == null or not p.is_alive():
		_back_to_post()
		return
	if level.call("holding_wine"):
		mode = Mode.WAIT_WINE
		return
	if sees(p) or Combat.ground_dist(global_position, p.global_position) < 90.0:
		_lost = 0.0
	else:
		_lost += delta
		if _lost > LOSE_TIME:
			Fx.text(global_position + Vector2(0, -170), "?", Color(1, 0.9, 0.5))
			_back_to_post()
			return
	var d := Combat.ground_dist(global_position, p.global_position)
	if d < 70.0 and _cd <= 0.0:
		_start_attack(GRAB if d > 52.0 else SLAM, p.global_position)
		return
	_goal = p.global_position
	_speed = CHASE_SPEED
	_repath = minf(_repath, 0.4)
	_step_walk(delta)


func _back_to_post() -> void:
	suspicion = 0.0
	if posts.is_empty():
		mode = Mode.WATCH
		return
	walk_to(posts[post_i][0], watch)


func _start_attack(spec: Dictionary, target: Vector2) -> void:
	mode = Mode.ATTACK
	_atk = spec
	_atk_t = 0.0
	_hit_done = false
	face(target - global_position)
	_atk_at = global_position + facing * float(spec["at"])
	_play(spec["anim"])


func _attack_update(p: Player, delta: float) -> void:
	_atk_t += delta
	if not _hit_done and _atk_t >= float(_atk["hit"]):
		_hit_done = true
		Game.shake(7.0 if _atk == SLAM else 4.0)
		Sfx.at("hit_heavy", _atk_at, 0.0)
		Fx.ring(_atk_at, float(_atk["r"]) * 1.2, Color(0.9, 0.75, 0.55), 0.4)
		if _atk == SLAM:
			Fx.anim("dust", _atk_at)
		if p and p.is_alive() and p.visible and Combat.ground_dist(_atk_at, p.global_position) < float(_atk["r"]) + 8.0:
			var r := p.take_hit(float(_atk["dmg"]), self, float(_atk["kb"]), true)
			if r == "hit" or r == "killed":
				Game.hitstop(0.08)
				if _atk == GRAB:
					p.stagger(0.9)
					Fx.text(p.global_position + Vector2(0, -64), Lines.t("fx.grabbed"), Color(1, 0.5, 0.35))
	if _atk_t >= float(_atk["dur"]):
		_cd = ATTACK_CD
		mode = _after_attack
		_after_attack = Mode.CHASE
		if mode == Mode.CHASE:
			_lost = 0.0
		_play("idle")


var _after_attack: int = Mode.CHASE


## 바닥에 그리는 공격 예고(빨간 타원) — 레벨이 시야 층에 그린다
func draw_warning(c: CanvasItem) -> void:
	if mode != Mode.ATTACK or _hit_done:
		return
	var k := clampf(_atk_t / float(_atk["hit"]), 0.0, 1.0)
	var r := float(_atk["r"])
	c.draw_set_transform(_atk_at, 0.0, Vector2(1.0, 1.0 / Combat.Y_STRETCH))
	c.draw_circle(Vector2.ZERO, r, Color(1.0, 0.2, 0.1, 0.12 + 0.25 * k))
	c.draw_arc(Vector2.ZERO, r * k, 0.0, TAU, 28, Color(1.0, 0.35, 0.2, 0.7), 1.5)
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _sleep(p: Player, delta: float) -> void:
	if fmod(_t, 2.6) < delta:
		Fx.text(global_position + Vector2(-90, -60), "Z z", Color(0.75, 0.8, 1.0))
	if p and p.is_alive() and p.velocity.length() > 85.0 and Combat.ground_dist(global_position, p.global_position) < WAKE_RADIUS:
		wake += delta * WAKE_RATE
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
			var hit := p.take_hit(16.0, self, 200.0, true)
			if hit == "hit":
				p.stagger(0.6)


func _guard(p: Player, delta: float) -> void:
	_play("idle")
	if p == null or not p.is_alive() or not p.visible or _cd > 0.0:
		return
	var d := Combat.ground_dist(global_position, p.global_position)
	if d < FEEL_RADIUS or (p.velocity.length() > 85.0 and d < HEAR_RADIUS):
		_after_attack = Mode.GUARD
		var spec := GRAB if d > 52.0 else SLAM
		if _say_cd <= 0.0:
			_say_cd = 5.0
			Fx.text(global_position + Vector2(0, -170), Lines.t("fx.who"), Color(1, 0.5, 0.35))
		_start_attack(spec, p.global_position)
		_cd = 2.2
