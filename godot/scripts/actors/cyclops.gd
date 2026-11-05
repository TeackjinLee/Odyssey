class_name Cyclops
extends Node2D
## 챕터 3 폴리페모스(외눈 거인). 사람의 세 배 — 칼로는 쓰러뜨릴 수 없다(그룹 "actors"에 넣지 않아 칼·화살·봇이 무시한다).
## 상태: 순찰·지킴(자리마다 시야 부채꼴로 둘러봄) — 보이거나(밝을수록 멀리) 냄새 원 안에 오래 있으면 의심이 차고,
## 다 차면 그 사람(오디세우스든 부하든)을 쫓아와 곤봉 내려치기·움켜잡기. 잡힌 부하는 끌려간다(crew_taken).
## 소리(미끼 돌·달리기)가 나면 그곳으로 가서 둘러본다(INVESTIGATE). 포도주를 든 오디세우스는 치지 않고 기다린다.
## → 취해 비틀거리며 침상으로 → 잠듦(뛰는 소리에 뒤척임) → 눈을 잃고 날뜀(RAMPAGE: 소리 난 곳으로 돌진해 내려침, 벽에 부딪히면 멈칫)
## → 입구에 앉아 지킴(GUARD: 가까이 오거나 뛰는 소리가 나면 그쪽을 움켜잡음).
## 그림: assets/sprites/polyphemus(대기·걷기)·polyphemus_combat(곤봉·움켜잡기), 칸 320×320, 한 줄 = 한 방향.
## 취함·잠듦·눈 부상·더듬기 동작은 받았으나 아직 묶지 않아 대기 그림을 기울이거나 눕혀 쓴다(sprite_request/ch3_kit/polyphemus/states).

enum Mode { AWAY, WALK, WATCH, CHASE, ATTACK, WAIT_WINE, DRUNK, SLEEP, BLIND, GUARD, INVESTIGATE, RAMPAGE, CHARGE, STUNNED }

## 시야: 땅 거리(밝은 곳 기준, 어두우면 DARK_K배), 부채꼴 각도(도), 이만큼(초) 계속 보이면 쫓는다
const SIGHT := 210.0
const DARK_K := 0.42
const ARC := 84.0
const NOTICE := 1.0
## 냄새 원: 이 땅 거리 안에 SMELL_TIME초 머물면 부채꼴 밖이어도 알아챈다(여럿이 모여 있으면 원이 커진다)
const SMELL_R := 78.0
const SMELL_GROUP := 26.0
const SMELL_TIME := 1.6
const WALK_SPEED := 34.0
const CHASE_SPEED := 54.0
const DRUNK_SPEED := 24.0
const CHARGE_SPEED := 140.0
## 쫓다가 이만큼 못 보면 자리로 돌아감
const LOSE_TIME := 3.5
## 공격: 프레임 6장 6fps, 4번째 장면(0.67초)에 맞음. at = 몸에서 앞쪽 거리, r = 맞는 반지름(땅 거리)
## 움켜잡기 48 × 세 번이면 오디세우스(140)가 쓰러진다
const SLAM := {"anim": "club_slam", "hit": 0.67, "dur": 1.0, "at": 50.0, "r": 38.0, "dmg": 34.0, "kb": 240.0}
const GRAB := {"anim": "grab", "hit": 0.67, "dur": 1.0, "at": 62.0, "r": 30.0, "dmg": 48.0, "kb": 300.0}
## 날뛸 때 돌진 끝 내려치기(예고가 조금 짧다)
const RAM_SLAM := {"anim": "club_slam", "hit": 0.5, "dur": 0.9, "at": 30.0, "r": 46.0, "dmg": 40.0, "kb": 280.0}
const ATTACK_CD := 1.1
## 소리 난 곳에서 둘러보는 시간
const INVESTIGATE_TIME := 3.0
## 잠든 거인 곁에서 뛰면 차는 뒤척임(1이면 깨어 주위를 움켜잡음)
const WAKE_RADIUS := 160.0
const WAKE_RATE := 0.45
## 눈 먼 거인이 듣는 거리: 뛰는 소리 / 걷는 소리(가까이) / 바로 곁
const HEAR_RADIUS := 230.0
const HEAR_WALK := 95.0
const FEEL_RADIUS := 95.0
## 날뛰다 벽에 부딪히면 멈칫하는 시간
const STUN_TIME := 2.0
## 날뛸 때 냄새로 사람을 더듬어 가는 거리·빠르기(오디세우스 걷기 72보다 느리다)
const TRACK_RADIUS := 320.0
const TRACK_SPEED := 30.0

signal woke
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
var body: AnimatedSprite2D
var fight: AnimatedSprite2D


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


## 눈을 잃고 날뛴다: 소리 난 곳으로 돌진해 내려친다
func rampage() -> void:
	blind()
	mode = Mode.RAMPAGE
	_goal = Vector2.INF
	_cd = 1.5


func guard_at(pos: Vector2, look: Vector2) -> void:
	mode = Mode.GUARD
	global_position = pos
	face(look)
	body.rotation = 0.0


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
	Fx.text(global_position + Vector2(0, -170), "?", Color(1, 0.9, 0.5))
	face(pos - global_position)
	_inv_t = INVESTIGATE_TIME
	walk_to(pos, func(): mode = Mode.INVESTIGATE, WALK_SPEED * 1.3, Mode.WALK)


func _charge(pos: Vector2) -> void:
	_hear_cd = 0.6
	mode = Mode.CHARGE
	_goal = pos
	face(pos - global_position)
	Sfx.at("thunder", global_position, -6.0)
	Fx.text(global_position + Vector2(0, -170), Lines.t("fx.who"), Color(1, 0.45, 0.3))


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
	return SMELL_R + SMELL_GROUP * n


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
	match mode:
		Mode.WALK, Mode.DRUNK:
			_step_walk(delta)
			if mode == Mode.DRUNK:
				body.rotation = 0.12 * sin(_t * 2.3)
			_look_for(delta)
		Mode.WATCH:
			_play("idle")
			if not posts.is_empty():
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
		Mode.STUNNED:
			_play("idle")
			body.rotation = 0.15 * sin(_t * 9.0)
			_stun_t -= delta
			if _stun_t <= 0.0:
				body.rotation = 0.0
				mode = Mode.RAMPAGE
		Mode.GUARD:
			_guard(p)


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
	_play("walk")
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
			Fx.text(global_position + Vector2(0, -170), Lines.t("fx.smell_wine"), Color(1, 0.85, 0.5))
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
	mode = Mode.CHASE
	suspicion = 1.0
	_lost = 0.0
	_path = PackedVector2Array()
	Sfx.at("thunder", global_position, -2.0)
	Game.shake(4.0)
	Fx.text(global_position + Vector2(0, -170), Lines.t("fx.giant_seen"), Color(1, 0.35, 0.25))
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
			Fx.text(global_position + Vector2(0, -170), "?", Color(1, 0.9, 0.5))
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
	var heavy_slam: bool = _atk["anim"] == "club_slam"
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


## 바닥에 그리는 공격 예고(빨간 타원)·돌진 길·냄새 원 — 레벨이 시야 층에 그린다
func draw_warning(c: CanvasItem) -> void:
	if mode == Mode.CHARGE and _goal != Vector2.INF:
		c.draw_line(global_position, _goal, Color(1.0, 0.3, 0.2, 0.35), 3.0)
	if watching() or mode == Mode.CHASE:
		var p: Player = Game.player
		if p and p.visible:
			var k: float = clampf(_smell.get(p, 0.0) / SMELL_TIME, 0.0, 1.0)
			c.draw_set_transform(global_position, 0.0, Vector2(1.0, 1.0 / Combat.Y_STRETCH))
			c.draw_arc(Vector2.ZERO, SMELL_R, 0.0, TAU, 40, Color(0.75, 0.9, 0.5, 0.18 + 0.4 * k), 1.0 + 2.0 * k)
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
		Fx.text(global_position + Vector2(0, -170), "!!", Color(1, 0.8, 0.4))
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
			Fx.text(global_position + Vector2(0, -170), Lines.t("fx.who"), Color(1, 0.5, 0.35))
		_start_attack(spec, p.global_position)
		_cd = 2.2
