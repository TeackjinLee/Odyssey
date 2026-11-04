class_name Enemy
extends Actor
## 트로이 병사. 순찰/대기 → 발견(주변 동료에게 알림) → 추적 → 공격 예고(붉게 깜빡임) → 공격 → 회복.
## 방패병은 상대가 휘두르는 걸 보면 막고, 궁수는 거리를 벌려 쏘며, 체력이 낮으면 잠깐 물러난다.
## 수비대장 아게노르는 경직 저항(강공격·패링에만 경직)이 있다. 1페이즈: 3연타 → 내려찍기(막는 순간 패링하면 2초 무방비).
## 2페이즈(체력 절반 이하): 둘레를 방패로 밀쳐낸 뒤 뿔나팔로 검병 둘을 부르고, 방패 돌진(붉은 길로 예고, 옆으로 피함 — 벽에 박히면 2초 무방비)을 섞는다.
## 잠입: 알아채기 전에는 앞쪽 부채꼴(VIEW_ARC)로 오디세우스만 본다. 보이는 거리는 그 자리의 밝기에 따라
## SIGHT_DARK~vision. 보이거나 소리가 나면 의심("?")이 차고, 다 차면 알아챈다. 뒤에서는 E로 조용히 처치되고,
## 알아채기 전에 화살을 맞으면 한 발에 쓰러진다. 꺼진 횃불을 보면 가서 다시 켠다.
## 직접 알아채면 주변의 알아챈 동료 중 오디세우스에게서 가장 먼 하나가 경보병이 되어 가까운 경보 종으로 뛴다.
## 성문 사수 반격: 방패벽(정면은 늘 막으며 밀고 옴, 강공격에 방패가 부서짐) · 높은 곳 궁수(제자리에서 멀리 쏨, 밀리지 않음)
## · 권양기 돌격병(권양기로 뛰어가 돌려 성문을 닫음, 맞아 비틀거려도 다시 뜀).

const KINDS := {
	"trojan_sword": {"name": "트로이 검병", "hp": 42.0, "speed": 54.0, "reach": 21.0, "dmg": 8.0, "windup": 0.45, "dur": 0.36, "arc": 120.0, "shield": true, "cd": 1.3},
	"trojan_spear": {"name": "트로이 창병", "hp": 38.0, "speed": 52.0, "reach": 34.0, "dmg": 10.0, "windup": 0.55, "dur": 0.42, "arc": 45.0, "shield": true, "cd": 1.6},
	"trojan_archer": {"name": "트로이 궁수", "hp": 26.0, "speed": 50.0, "reach": 160.0, "dmg": 7.0, "windup": 0.65, "dur": 0.3, "arc": 0.0, "shield": false, "cd": 2.2, "ranged": true},
	"trojan_captain": {"name": "성문 수비대장 아게노르", "hp": 300.0, "speed": 50.0, "reach": 27.0, "dmg": 13.0, "windup": 0.6, "dur": 0.45, "arc": 140.0, "shield": true, "cd": 0.9, "boss": true},
	## 마지막 총공세를 이끄는 트로이 왕자(그림은 아게노르 것을 쓴다)
	"trojan_prince": {"name": "트로이 왕자 데이포보스", "sheet": "trojan_captain", "hp": 320.0, "speed": 54.0, "reach": 27.0, "dmg": 14.0, "windup": 0.55, "dur": 0.45, "arc": 140.0, "shield": true, "cd": 0.85, "boss": true},
	## 챕터 2 이스마로스의 키코네스족(그림은 트로이 병사 것을 색만 바꿔 쓴다 — ART_PLAN §4.8 키코네스 전사·궁수를 받으면 sheet만 바꿈)
	"cicones_sword": {"name": "키코네스 전사", "sheet": "trojan_sword", "tint": Color(0.95, 1.08, 0.82), "hp": 40.0, "speed": 56.0, "reach": 21.0, "dmg": 8.0, "windup": 0.45, "dur": 0.36, "arc": 120.0, "shield": true, "cd": 1.3},
	"cicones_spear": {"name": "키코네스 창병", "sheet": "trojan_spear", "tint": Color(0.95, 1.08, 0.82), "hp": 36.0, "speed": 54.0, "reach": 34.0, "dmg": 10.0, "windup": 0.55, "dur": 0.42, "arc": 45.0, "shield": true, "cd": 1.6},
	"cicones_archer": {"name": "키코네스 궁수", "sheet": "trojan_archer", "tint": Color(0.95, 1.08, 0.82), "hp": 24.0, "speed": 52.0, "reach": 160.0, "dmg": 6.0, "windup": 0.65, "dur": 0.3, "arc": 0.0, "shield": false, "cd": 2.2, "ranged": true},
	## 내륙에서 달려오는 키코네스 기병대장(말 그림이 없어 걷는 대장 — 그림은 아게노르 것)
	"cicones_chief": {"name": "키코네스 전사장", "sheet": "trojan_captain", "tint": Color(0.95, 1.08, 0.82), "hp": 200.0, "speed": 56.0, "reach": 27.0, "dmg": 12.0, "windup": 0.6, "dur": 0.45, "arc": 140.0, "shield": true, "cd": 1.0, "boss": true},
}

var kind := "trojan_sword"
var cfg: Dictionary = {}
var target: Actor = null
var alerted := false
var phase := "idle"
var phase_time := 0.0
var attack_cd := 0.0
var scan := 0.0
var home := Vector2.ZERO
var patrol: Array = []
var patrol_i := 0
var strafe_sign := 1.0
var strikes := 0
var retreated := false
var vision := 150.0
var suspicion := 0.0
var look_pos := Vector2.INF
var calm_delay := 0.0
var home_facing := Vector2(0, 1)
var glance := 0.0
var errand: Dictionary = {}
var errand_time := 0.0
var takedown: Interactable
var _quiet := false
var raises_alarm := true
## 반격군: 노리던 상대가 쓰러지면 멀리 있어도 가장 가까운 그리스군을 쫓는다
var hunts_player := false
var bell: Dictionary = {}
var shield_wall := false
var perch := false
var crank_pos := Vector2.INF
var hit_done := false
var slam := false
var horn_done := false
var _horn_blown := false
var charge_cd := 0.0
var charge_dir := Vector2.ZERO
var _charge_from := Vector2.ZERO
var _charge_hit: Array = []
var _seen_attack := -1.0

## 한 대상을 동시에 노리는 근접 공격 수 상한 (나머지는 둘레를 돌며 기회를 본다)
const MAX_ATTACKERS := 2
## 시야 부채꼴 각도, 어두운 곳에서 보이는 거리
const VIEW_ARC := 70.0
const SIGHT_DARK := 55.0
## 높은 곳 궁수가 쏘는 거리
const PERCH_REACH := 250.0
## 수비대장: 연타 사이 예고 시간, 패링·벽 충돌 뒤 무방비 시간, 방패 돌진(예고·빠르기·거리·쿨타임·피해)
const COMBO_WINDUP := 0.26
const OPEN_TIME := 2.0
const CHARGE_WINDUP := 0.8
const CHARGE_SPEED := 240.0
const CHARGE_LEN := 210.0
const CHARGE_CD := 5.5
const CHARGE_DMG := 16.0
const CHARGE_MIN := 32.0
## 뿔나팔을 불기 직전 방패로 밀쳐내는 거리·세기 (둘러싼 그리스인을 떼어 내 돌진할 틈을 만든다)
const SHOVE_RADIUS := 80.0
const SHOVE_KB := 300.0


func _attackers_on(t: Actor) -> int:
	var n := 0
	for e in Game.level.enemies():
		if e != self and e.target == t and (e.phase == "windup" or e.phase == "strike") and not e.cfg.get("ranged", false):
			n += 1
	return n


func setup(k: String) -> void:
	kind = k
	cfg = KINDS[k]
	sheet = cfg.get("sheet", k)
	tint = cfg.get("tint", Color(1, 1, 1))
	team = Team.TROJAN
	display_name = cfg["name"]
	max_hp = cfg["hp"]
	walk_speed = cfg["speed"]
	run_speed = cfg["speed"] * 1.45
	has_shield = cfg["shield"]
	poise = cfg.get("boss", false)
	head_height = 58.0 if poise else 46.0
	strafe_sign = 1.0 if randf() < 0.5 else -1.0


func _ready() -> void:
	super._ready()
	add_to_group("enemies")
	home = global_position
	home_facing = facing
	glance = randf_range(1.5, 3.5)
	attack_cd = randf_range(0.2, 0.9)
	takedown = Interactable.new()
	takedown.label = "조용히 처치"
	takedown.radius = 24.0
	takedown.enabled = false
	takedown.on_use = func(by):
		if by is Player:
			by.takedown(self)
	add_child(takedown)


func alert(t: Actor) -> void:
	if t == null:
		return
	target = t
	if alerted:
		return
	alerted = true
	suspicion = 1.0
	_drop_errand()
	takedown.enabled = false
	Fx.text(global_position + Vector2(0, -head_height - 4), "!", Color(1, 0.35, 0.25))
	Sfx.at("alert", global_position, -10.0)
	if phase == "idle":
		phase = "chase"
	if cfg.get("boss", false):
		Game.boss_changed.emit(self)
	for e in Game.level.enemies():
		if e != self and not e.alerted and e.global_position.distance_to(global_position) < 150.0:
			e.alert(t)


func think(delta: float) -> void:
	attack_cd -= delta
	charge_cd -= delta
	phase_time += delta
	scan -= delta
	if not alerted:
		_perceive(delta)
	if scan <= 0.0:
		scan = 0.3
		_pick_target()
		if not alerted and errand.is_empty() and suspicion <= 0.0:
			_look_for_torch()
	match phase:
		"alarm":
			_run_alarm(delta)
			return
		"crank":
			_run_crank(delta)
			return
		"horn":
			_horn()
			return
		"charge_windup":
			_charge_windup()
			return
		"charge":
			_charge()
			return
		"windup":
			_windup(delta)
			return
		"strike":
			_strike()
			return
		"block":
			play("block")
			if target:
				face(target.global_position - global_position)
			if phase_time > 0.6:
				_set_phase("chase")
			return
		"retreat":
			if target:
				var away := (global_position - target.global_position).normalized()
				desired_velocity = nav_velocity(global_position + away * 60.0, run_speed, delta)
				face(desired_velocity)
				play("run")
			if phase_time > 1.3:
				_set_phase("chase")
			return
	if target == null or not target.is_alive():
		target = null
		if not alerted and suspicion > 0.0:
			_investigate(delta)
		elif not errand.is_empty():
			_do_errand(delta)
		else:
			_idle_patrol(delta)
		return
	var d := Combat.ground_dist(global_position, target.global_position)
	var to := target.global_position - global_position
	# 방패병: 상대가 나를 향해 휘두르면 막는다
	if has_shield and target.state == St.ATTACK and d < 42.0 and target.facing.dot(-to.normalized()) > 0.5 and _seen_attack != target.state_time:
		_seen_attack = target.state_time
		if target.state_time < 0.12 and randf() < (0.45 if not poise else 0.3):
			_set_phase("block")
			set_state(St.BLOCK)
			return
	if hp < max_hp * 0.28 and not retreated and not poise and not perch and not shield_wall and randf() < 0.5:
		retreated = true
		_set_phase("retreat")
		return
	if poise and not horn_done and hp <= max_hp * 0.5:
		horn_done = true
		_set_phase("horn")
		_shove()
		return
	if poise and horn_done and charge_cd <= 0.0 and d > CHARGE_MIN and d < 190.0 and phase == "chase" \
			and Game.level.line_clear(global_position, target.global_position, 4.0):
		_start_charge()
		return
	if perch:
		# 높은 곳: 움직이지 않고 보이면 쏜다
		if attack_cd <= 0.0 and d < PERCH_REACH and Game.level.line_clear(global_position, target.global_position, 1.0):
			_start_windup()
			return
	elif cfg.get("ranged", false):
		var los: bool = Game.level.line_clear(global_position, target.global_position, 1.0)
		var back := global_position - to.normalized() * 50.0
		var cornered: bool = Game.level.is_blocked_world(back) or not Game.level.line_clear(global_position, back, 3.0)
		if d < 75.0 and not cornered:
			desired_velocity = nav_velocity(back, walk_speed, delta)
		elif d < 75.0 and attack_cd <= 0.0:
			_start_windup()
			return
		elif d > cfg["reach"] or not los:
			desired_velocity = nav_velocity(target.global_position, walk_speed, delta)
		elif attack_cd <= 0.0:
			_start_windup()
			return
		else:
			desired_velocity = Vector2(-to.y, to.x).normalized() * 22.0 * strafe_sign
	else:
		if shield_wall and d < 110.0 and not (d <= cfg["reach"] + 2.0 and attack_cd <= 0.0):
			# 방패벽: 방패를 든 채 천천히 밀고 들어온다
			face(to)
			set_state(St.BLOCK)
			play("block")
			if d > cfg["reach"]:
				desired_velocity = nav_velocity(target.global_position, walk_speed * 0.5, delta, cfg["reach"] * 0.7)
			return
		if shield_wall and state == St.BLOCK:
			set_state(St.IDLE)
		if d > cfg["reach"] + 2.0:
			var speed: float = run_speed if d > 90.0 else walk_speed
			desired_velocity = nav_velocity(target.global_position, speed, delta, cfg["reach"] * 0.7)
		elif attack_cd <= 0.0 and _attackers_on(target) < MAX_ATTACKERS:
			_start_windup()
			return
		else:
			desired_velocity = Vector2(-to.y, to.x).normalized() * 18.0 * strafe_sign - to.normalized() * 6.0
			if randf() < 0.01:
				strafe_sign = -strafe_sign
	face(to)
	if desired_velocity.length() > 8.0:
		play("run" if desired_velocity.length() > walk_speed + 1.0 else "walk")
	else:
		play("idle")


## 알아챈 뒤에만: 가까운 그리스인을 고른다 (알아채기 전에는 _perceive가 본다)
func _pick_target() -> void:
	if not alerted:
		return
	var best: Actor = null
	var best_d := INF
	for a in Game.level.greeks():
		var d := global_position.distance_to(a.global_position)
		if a is Player:
			d *= 0.8
		if d < 240.0 and d < best_d and (d < 40.0 or Game.level.line_clear(global_position, a.global_position, 1.0)):
			best_d = d
			best = a
	if best:
		target = best
	elif target == null or not target.is_alive():
		target = null
		# 몰려오는 반격군(hunts_player)은 노리던 상대가 쓰러지면 거리와 상관없이 가장 가까운 그리스군을 쫓는다
		# (태어난 자리에 멍하니 서 있지 않게. 오디세우스 한 명에게만 몰리지 않게 부하·대군도 노린다)
		if hunts_player:
			for a in Game.level.greeks():
				var d := global_position.distance_to(a.global_position)
				if d < best_d:
					best_d = d
					target = a


# ── 잠입: 보기·듣기·의심 ──────────────────────────────
## 그 자리에서 오디세우스가 보이는 거리 (어두우면 SIGHT_DARK, 횃불 빛 안이면 vision)
func sight_range(pos: Vector2) -> float:
	return lerpf(SIGHT_DARK, vision, Game.level.light_at(pos))


func _perceive(delta: float) -> void:
	var p: Player = Game.player
	var stim := false
	if p and p.is_alive() and p.get("riding") == null:
		var to := p.global_position - global_position
		var d := Combat.ground_dist(global_position, p.global_position)
		var r := sight_range(p.global_position)
		if d < r and absf(rad_to_deg(facing.angle_to(to))) < VIEW_ARC * 0.5 \
				and (d < 30.0 or Game.level.line_clear(global_position, p.global_position, 1.0)):
			suspicion += delta / (0.35 + 0.8 * d / r)
			look_pos = p.global_position
			stim = true
		elif p.velocity.length() > p.walk_speed + 8.0 and d < 55.0:
			hear(p.global_position, 1.3 * delta)
			stim = true
	calm_delay -= delta
	if not stim and calm_delay <= 0.0:
		suspicion = max(0.0, suspicion - 0.4 * delta)
	if suspicion >= 1.0 and p:
		Game.stats["detected"] = Game.stats.get("detected", 0) + 1
		alert(p)
		call_alarm()
	takedown.enabled = not poise and p != null and p.is_alive() \
			and Combat.ground_dist(global_position, p.global_position) < 24.0 \
			and facing.dot((p.global_position - global_position).normalized()) < -0.2


# ── 경보 ──────────────────────────────────────────────
## 직접 알아챘을 때: 주변(160px)의 알아챈 동료 중 오디세우스에게서 가장 먼 하나가 가까운 빈 종으로 뛴다.
func call_alarm() -> void:
	if not raises_alarm or Game.player == null:
		return
	var b: Dictionary = Game.level.free_bell(global_position)
	if b.is_empty():
		return
	var runner: Enemy = null
	var best := -1.0
	for e in Game.level.enemies():
		if e.alerted and e.raises_alarm and e.bell.is_empty() and e.global_position.distance_to(global_position) < 160.0:
			var d: float = e.global_position.distance_to(Game.player.global_position)
			if d > best:
				best = d
				runner = e
	if runner:
		runner.start_alarm(b)


func start_alarm(b: Dictionary) -> void:
	bell = b
	b["runner"] = self
	telegraph = 0.0
	_set_phase("alarm")
	Fx.text(global_position + Vector2(0, -head_height - 4), "경보다!", Color(1, 0.35, 0.25))
	Game.show_hint("경보병이 종으로 달려간다! 종을 치기 전에 쓰러뜨려라")


## 종까지 뛰어가 0.8초 동안 쳐서 울린다. 그 사이에 쓰러지면 아무 일도 없다.
func _run_alarm(delta: float) -> void:
	if bell.is_empty() or bell["rung"]:
		_drop_bell()
		_set_phase("chase")
		return
	var pos: Vector2 = bell["sprite"].global_position
	if global_position.distance_to(pos) > 26.0:
		desired_velocity = nav_velocity(pos, run_speed, delta, 22.0)
		face(desired_velocity)
		play("run")
		phase_time = 0.0
		return
	face(pos - global_position)
	play("interact")
	if phase_time > 0.8:
		Game.level.ring_bell(bell)
		bell = {}
		_set_phase("chase")


## 권양기 돌격병이 된다: 싸우지 않고 권양기로 뛰어가 돌린다(Game.level.crank_gate).
func start_crank(pos: Vector2) -> void:
	crank_pos = pos
	alerted = true
	suspicion = 1.0
	takedown.enabled = false
	_set_phase("crank")


func _run_crank(delta: float) -> void:
	if global_position.distance_to(crank_pos) > 12.0:
		desired_velocity = nav_velocity(crank_pos, run_speed, delta, 8.0)
		face(desired_velocity)
		play("run")
		return
	face(crank_pos + Vector2(8, -12) - global_position)
	play("interact")
	if Game.level.has_method("crank_gate"):
		Game.level.crank_gate(delta)


func _drop_bell() -> void:
	if not bell.is_empty() and bell["runner"] == self:
		bell["runner"] = null
	bell = {}


## 소리를 들으면 의심이 차고 그쪽을 본다.
func hear(pos: Vector2, amount: float) -> void:
	if alerted or not is_alive():
		return
	suspicion = min(1.0, suspicion + amount)
	look_pos = pos
	calm_delay = 1.0
	_drop_errand()


## 미끼(던진 돌 소리): 그쪽을 반 넘게 의심해 살피러 간다. 알아채기(1.0)까지는 올리지 않는다 —
## 다만 살피러 간 김에 오디세우스를 보면 금방 알아챈다.
func lure(pos: Vector2) -> void:
	if alerted or not is_alive() or poise or phase != "idle" and phase != "chase":
		return
	suspicion = clampf(suspicion + 0.65, 0.6, 0.9)
	look_pos = pos
	calm_delay = 3.0
	_drop_errand()
	Fx.text(global_position + Vector2(0, -head_height - 4), "?", Color(1, 0.9, 0.5))


## 의심 중: 멈춰서 그쪽을 보고, 반 넘게 차면 천천히 다가가 살핀다.
func _investigate(delta: float) -> void:
	if look_pos == Vector2.INF:
		play("idle")
		return
	var to := look_pos - global_position
	if suspicion > 0.5 and to.length() > 14.0:
		desired_velocity = nav_velocity(look_pos, walk_speed * 0.5, delta, 12.0)
		play("walk")
	else:
		play("idle")
	face(to)


func _look_for_torch() -> void:
	for t in Game.level.torches:
		if t["lit"] or t["claimed"] != null:
			continue
		var pos: Vector2 = t["sprite"].global_position
		# 횃불대 칸은 막혀 있으니 바로 앞(24px)까지 트였는지 본다
		var front := pos + (global_position - pos).normalized() * 24.0
		if global_position.distance_to(pos) < vision and Game.level.line_clear(global_position, front, 1.0):
			errand = t
			errand_time = 0.0
			t["claimed"] = self
			Fx.text(global_position + Vector2(0, -head_height - 4), "?", Color(1, 0.9, 0.5))
			return


## 꺼진 횃불로 가서 다시 켠다.
func _do_errand(delta: float) -> void:
	var pos: Vector2 = errand["sprite"].global_position
	if global_position.distance_to(pos) > 24.0:
		desired_velocity = nav_velocity(pos, walk_speed * 0.8, delta, 20.0)
		face(desired_velocity)
		play("walk")
		return
	face(pos - global_position)
	play("interact")
	errand_time += delta
	if errand_time > 1.4:
		Game.level.set_torch(errand, true)
		_drop_errand()


func _drop_errand() -> void:
	if not errand.is_empty() and errand["claimed"] == self:
		errand["claimed"] = null
	errand = {}


## 조용히 쓰러진다 (뒤에서 처치·알아채기 전 화살). count_kill: 처치 수를 여기서 셀지
func silent_kill(count_kill: bool) -> void:
	if not is_alive():
		return
	hp = 0.0
	_quiet = true
	if count_kill:
		Game.stats["kills"] += 1
	Game.stats["silent"] += 1
	Fx.text(global_position + Vector2(0, -head_height), "조용히", Color(0.7, 0.85, 1.0))
	Sfx.play("takedown", -6.0)
	Fx.anim("takedown", global_position + Vector2(0, -16))
	_die()


func take_hit(dmg: float, src: Node2D, kb := 60.0, heavy := false, ranged := false) -> String:
	var by: Node = (src as Projectile).shooter if src is Projectile else src
	if not alerted and is_alive() and ranged and not poise and src is Projectile and by is Player:
		silent_kill(false)
		return "killed"
	if shield_wall and heavy and state == St.BLOCK and src and facing.dot((src.global_position - global_position).normalized()) > 0.15:
		stamina = min(stamina, 30.0)   # 강공격(막기 비용 45)이면 방패가 부서진다
	var r := super.take_hit(dmg, src, kb, heavy, ranged)
	if perch:
		knock = Vector2.ZERO
	if r != "miss" and is_alive() and not alerted:
		if by is Actor:
			alert(by)
			call_alarm()
	return r


func _idle_patrol(delta: float) -> void:
	if not alerted and patrol.is_empty():
		# 서 있는 보초: 이따금 좌우를 둘러본다
		glance -= delta
		if glance <= 0.0:
			glance = randf_range(2.0, 4.0)
			face(home_facing.rotated(randf_range(-0.9, 0.9)))
		if global_position.distance_to(home) > 10.0:
			desired_velocity = nav_velocity(home, walk_speed * 0.7, delta, 8.0)
			face(desired_velocity)
			play("walk")
		else:
			play("idle")
		return
	if patrol.size() > 0:
		var goal: Vector2 = patrol[patrol_i]
		if global_position.distance_to(goal) < 8.0:
			patrol_i = (patrol_i + 1) % patrol.size()
		desired_velocity = nav_velocity(goal, walk_speed * 0.6, delta)
		face(desired_velocity)
		play("walk" if desired_velocity.length() > 4.0 else "idle")
	elif alerted:
		desired_velocity = nav_velocity(home, walk_speed, delta, 8.0)
		face(desired_velocity)
		play("walk" if desired_velocity.length() > 4.0 else "idle")
	else:
		play("idle")


func _set_phase(p: String) -> void:
	phase = p
	phase_time = 0.0
	if state != St.HIT:
		set_state(St.IDLE)


func _start_windup() -> void:
	_set_phase("windup")
	slam = poise and strikes % 4 == 3
	var anim := "heavy" if slam else ("bow" if cfg.get("ranged", false) else "attack1")
	set_state(St.ATTACK)
	play(anim, true)
	body.pause()
	body.frame = 0 if anim != "bow" else 1


func _windup(_delta: float) -> void:
	var w: float = cfg["windup"] * (1.3 if slam else 1.0)
	if poise and strikes % 4 in [1, 2]:
		w = COMBO_WINDUP   # 3연타의 둘째·셋째 타는 짧게 이어 친다
	telegraph = clamp(phase_time / w, 0.0, 1.0)
	if target and phase_time < w * 0.6:
		face(target.global_position - global_position)
	if phase_time >= w:
		telegraph = 0.0
		_set_phase("strike")
		set_state(St.ATTACK)
		hit_done = false
		if cfg.get("ranged", false):
			body.frame = 2
		else:
			play_timed("heavy" if slam else ["attack1", "attack2", "attack3"][strikes % 4 if poise else randi() % 2], cfg["dur"] * (1.4 if slam else 1.0))
			Sfx.at("swing", global_position, -12.0)


func _strike() -> void:
	var dur: float = cfg["dur"] * (1.4 if slam else 1.0)
	if not cfg.get("ranged", false) and phase_time < dur * 0.35:
		desired_velocity = facing * 70.0 * (1.0 - phase_time / (dur * 0.35))
	if not hit_done and phase_time >= dur * 0.35:
		hit_done = true
		if cfg.get("ranged", false):
			if target and target.is_alive():
				Combat.shoot(self, target.global_position + target.velocity * 0.2, cfg["dmg"], 250.0)
			body.frame = 3
		elif slam:
			var c := global_position + facing * 14.0
			# 막기 시작 직후(패링 타이밍)에 정면으로 받으면 오디세우스는 다치지 않고 아게노르가 무방비가 된다
			var p: Actor = Game.player
			if p and p.is_alive() and p.state == St.BLOCK and p.block_time < 0.3 and Combat.ground_dist(c, p.global_position) <= 46.0 \
					and p.facing.dot((global_position - p.global_position).normalized()) > 0.15:
				p.invuln = 0.05
				Fx.impact("parry", p.global_position + Vector2(0, -20), Color(1, 0.85, 0.3), 16)
				Fx.text(p.global_position + Vector2(0, -p.head_height), "패링!", Color(1, 0.85, 0.3))
				Sfx.play("parry", -4.0)
				Combat.area(self, c, 46.0, cfg["dmg"] * 1.3, 200.0)
				_open_up()
				return
			Combat.area(self, c, 46.0, cfg["dmg"] * 1.3, 200.0)
			Fx.ring(c, 46.0, Color(1, 0.6, 0.3), 0.4)
			Game.shake(5.0)
		else:
			Combat.melee(self, cfg["reach"], cfg["arc"], cfg["dmg"], 80.0)
			Fx.slash(self, cfg["reach"], cfg["arc"], Color(1, 0.45, 0.35), strikes % 2 == 1, 4.0)
	var chain := poise and not slam and strikes % 4 in [0, 1]   # 3연타 중간은 거의 쉬지 않고 다음 타로
	if phase_time >= dur + (0.05 if chain else 0.3):
		strikes += 1
		attack_cd = cfg["cd"] * randf_range(0.8, 1.3)
		if poise and strikes % 4 in [1, 2]:
			attack_cd = 0.05
		_set_phase("chase")


# ── 수비대장 ────────────────────────────────────────
## 무방비: 오래 비틀거린다(패링한 내려찍기, 벽에 박힌 돌진)
func _open_up() -> void:
	strikes = 0
	Fx.text(global_position + Vector2(0, -head_height - 6), "무방비!", Color(1, 0.85, 0.3))
	Game.shake(4.0)
	_set_phase("chase")
	stagger(OPEN_TIME)


## 방패로 둘레를 밀쳐냄: 가까운 그리스인을 크게 밀고 잠깐 비틀거리게 한다(피해는 없음)
func _shove() -> void:
	Fx.text(global_position + Vector2(0, -head_height - 6), "밀쳐내기!", Color(1, 0.7, 0.35))
	Fx.ring(global_position, SHOVE_RADIUS, Color(1, 0.8, 0.5), 0.4)
	Sfx.at("hit_heavy", global_position, -4.0)
	Game.shake(4.0)
	for a in Game.level.greeks():
		var to: Vector2 = a.global_position - global_position
		if Combat.ground_dist(global_position, a.global_position) < SHOVE_RADIUS:
			a.stagger(0.5)
			a.knock = to.normalized() * SHOVE_KB


## 뿔나팔: 멈춰 서서 불고, 레벨이 검병을 부른다(on_boss_horn).
func _horn() -> void:
	play("interact")
	if target:
		face(target.global_position - global_position)
	if phase_time >= 0.5 and not _horn_blown:
		_horn_blown = true
		Fx.text(global_position + Vector2(0, -head_height - 6), "뿔나팔!", Color(1, 0.55, 0.3))
		Fx.ring(global_position, 60.0, Color(1, 0.55, 0.3), 0.6)
		Sfx.at("horn", global_position, -2.0)
		Game.shake(3.0)
		if Game.level.has_method("on_boss_horn"):
			Game.level.on_boss_horn(self)
	if phase_time >= 1.3:
		charge_cd = 0.3
		_set_phase("chase")


func _start_charge() -> void:
	charge_dir = (target.global_position - global_position).normalized()
	_set_phase("charge_windup")
	set_state(St.ATTACK)
	play("block")
	face(charge_dir)


## 돌진 예고: 처음 절반은 목표 쪽으로 방향을 맞추고, 그 뒤로는 고정(옆으로 피할 틈)
func _charge_windup() -> void:
	telegraph = clamp(phase_time / CHARGE_WINDUP, 0.0, 1.0)
	if target and phase_time < CHARGE_WINDUP * 0.5:
		charge_dir = (target.global_position - global_position).normalized()
		face(charge_dir)
	if phase_time >= CHARGE_WINDUP:
		telegraph = 0.0
		_charge_from = global_position
		_charge_hit = []
		_set_phase("charge")
		set_state(St.ATTACK)
		Sfx.at("swing_heavy", global_position, -4.0)


func _charge() -> void:
	play("run")
	face(charge_dir)
	desired_velocity = charge_dir * CHARGE_SPEED
	var stuck := phase_time > 0.12 and get_real_velocity().length() < CHARGE_SPEED * 0.3
	if Game.level.is_blocked_world(global_position + charge_dir * 12.0) or stuck:
		desired_velocity = Vector2.ZERO
		knock = -charge_dir * 60.0
		charge_cd = CHARGE_CD
		Fx.spark(global_position + charge_dir * 10.0 + Vector2(0, -20), Color(1, 0.9, 0.6), 14)
		Sfx.at("hit_heavy", global_position, -4.0)
		_open_up()
		return
	for a in Game.level.greeks():
		if a not in _charge_hit and Combat.ground_dist(global_position, a.global_position) < 18.0:
			_charge_hit.append(a)
			a.take_hit(CHARGE_DMG, self, 240.0, true)
	if global_position.distance_to(_charge_from) >= CHARGE_LEN:
		charge_cd = CHARGE_CD
		attack_cd = 0.6
		_set_phase("chase")


func on_interrupted() -> void:
	telegraph = 0.0
	if phase in ["windup", "strike", "block", "charge_windup", "charge"]:
		phase = "chase"
		phase_time = 0.0
		attack_cd = max(attack_cd, 0.5)


func _die() -> void:
	super._die()
	_drop_errand()
	_drop_bell()
	takedown.enabled = false
	if not _quiet:
		Sfx.at("death", global_position, -9.0)
	remove_from_group("enemies")
	await get_tree().create_timer(5.0).timeout
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 1.0)
	tw.tween_callback(queue_free)


func _draw() -> void:
	super._draw()
	if not is_alive():
		return
	if phase == "charge_windup":
		# 돌진 길 예고(땅 위 띠)
		var side := charge_dir.orthogonal() * 9.0
		var reach := 8.0
		while reach < CHARGE_LEN and not Game.level.is_blocked_world(global_position + charge_dir * reach):
			reach += 6.0   # 벽에 닿는 데까지만 그린다(거기 박히면 무방비)
		var end := charge_dir * minf(reach, CHARGE_LEN)
		var a := 0.12 + 0.25 * telegraph
		draw_colored_polygon(PackedVector2Array([side, end + side, end - side, -side]), Color(1, 0.25, 0.15, a))
	if phase == "alarm" or phase == "crank":
		var ya := -head_height - 8.0
		var tag := "! 경보" if phase == "alarm" else "! 권양기"
		draw_string_outline(Game.ui_font, Vector2(-24, ya), tag, HORIZONTAL_ALIGNMENT_CENTER, 48, 10, 4, Color(0, 0, 0, 0.85))
		draw_string(Game.ui_font, Vector2(-24, ya), tag, HORIZONTAL_ALIGNMENT_CENTER, 48, 10, Color(1, 0.35, 0.25))
		return
	if alerted or suspicion <= 0.02:
		return
	var y := -head_height - 8.0
	var col := Color(1, 0.95, 0.6).lerp(Color(1, 0.3, 0.2), suspicion)
	draw_string_outline(Game.ui_font, Vector2(-8, y), "?", HORIZONTAL_ALIGNMENT_CENTER, 16, 15, 4, Color(0, 0, 0, 0.85))
	draw_string(Game.ui_font, Vector2(-8, y), "?", HORIZONTAL_ALIGNMENT_CENTER, 16, 15, col)
	draw_rect(Rect2(-8, y + 3, 16, 3), Color(0, 0, 0, 0.75))
	draw_rect(Rect2(-8, y + 3, 16 * suspicion, 3), col)
