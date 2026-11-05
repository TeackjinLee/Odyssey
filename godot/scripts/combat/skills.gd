class_name Skills
## 기술 효과: 오디세우스의 미끼 던지기(C), 부대 특수 명령의 궁병 일제 사격(5).
## 그림(assets/fx/decoy_stone·volley·volley_fire, tools/fx_layout.py skills)이 있으면 그림, 없으면 도형으로 그린다.

## 미끼: 떨어진 자리에서 이 땅 거리 안의 알아채지 못한 적이 소리를 듣고 살피러 간다
const DECOY_HEAR := 130.0
const DECOY_FLIGHT := 0.55
## 일제 사격: 반지름, 화살비 시간, 피해(불화살이면 FIRE_MULT배)
const VOLLEY_RADIUS := 52.0
const VOLLEY_TIME := 0.7
const VOLLEY_DMG := 16.0
const FIRE_MULT := 1.5


## assets/fx/<이름>.png 띠 그림의 i번째 칸(칸 폭은 FRAME_W, 없으면 높이와 같음). 그림이 없으면 null
const FRAME_W := {"volley": 128, "volley_fire": 128, "javelin": 64}
static func strip_frame(name: String, i: int) -> AtlasTexture:
	var path := "res://assets/fx/%s.png" % name
	if not ResourceLoader.exists(path):
		return null
	var tex: Texture2D = AssetLibrary.texture(path)
	var fw: int = FRAME_W.get(name, tex.get_height())
	var n := maxi(1, tex.get_width() / fw)
	var at := AtlasTexture.new()
	at.atlas = tex
	at.region = Rect2(fw * clampi(i, 0, n - 1), 0, fw, tex.get_height())
	return at


## from에서 to로 돌멩이를 던진다. 떨어지면 소리가 나 주변 보초가 그쪽을 살피러 간다(Enemy.lure).
static func throw_decoy(from: Vector2, to: Vector2) -> void:
	var s := Stone.new()
	s.from = from
	s.to = to
	Game.level.fx_layer.add_child(s)
	Sfx.play("swing", -16.0)


static func _decoy_land(pos: Vector2) -> void:
	Sfx.at("stone", pos, -6.0)
	if not Fx.anim("decoy_dust", pos):
		Fx.spark(pos + Vector2(0, -2), Color(0.85, 0.8, 0.7), 6)
	Fx.ring(pos, DECOY_HEAR * 0.6, Color(1.0, 0.9, 0.55, 0.6), 0.6)
	for e in Game.level.enemies():
		if Combat.ground_dist(pos, e.global_position) < DECOY_HEAR:
			e.lure(pos)


## shooter(궁병)가 center에 화살비를 내린다. burning이면 불화살(더 아프고 불꽃이 튄다).
static func volley(shooter: Actor, center: Vector2, burning := false) -> void:
	var v := Volley.new()
	v.shooter = shooter
	v.position = center
	v.burning = burning
	Game.level.fx_layer.add_child(v)
	Sfx.at("bow", shooter.global_position, -4.0)
	Sfx.at("shout", shooter.global_position, -12.0)


## 던진 돌멩이: 포물선으로 날아가 떨어진다.
class Stone:
	extends Node2D
	var from := Vector2.ZERO
	var to := Vector2.ZERO
	var t := 0.0

	func _ready() -> void:
		z_index = 60
		position = from

	func _process(delta: float) -> void:
		t += delta / Skills.DECOY_FLIGHT
		if t >= 1.0:
			Skills._decoy_land(to)
			queue_free()
			return
		position = from.lerp(to, t)
		queue_redraw()

	func _draw() -> void:
		var h := -sin(t * PI) * 40.0 - 14.0 * (1.0 - t)
		draw_circle(Vector2(0, 1), 2.0, Color(0, 0, 0, 0.35))
		var fr := Skills.strip_frame("decoy_stone", int(t * 8.0) % 4)
		if fr:   # 32칸에 돌멩이가 7px쯤 — 가운데를 그 높이에
			draw_texture(fr, Vector2(-16, h - 16))
			return
		draw_circle(Vector2(0, h), 2.2, Color(0.75, 0.72, 0.66))
		draw_circle(Vector2(0, h), 2.2, Color(0.2, 0.18, 0.16), false, 1.0)


## 화살비: 바닥에 붉은 원으로 예고하고, 화살 줄기가 쏟아진 뒤 원 안의 적이 맞는다.
class Volley:
	extends Node2D
	var shooter: Actor
	var burning := false
	var t := 0.0
	var _hit := false
	var _streaks: Array = []

	func _ready() -> void:
		z_index = 60
		for i in 26:
			var a := randf() * TAU
			var r := sqrt(randf()) * Skills.VOLLEY_RADIUS
			_streaks.append([Vector2(cos(a) * r, sin(a) * r / Combat.Y_STRETCH), randf() * 0.5])

	func _process(delta: float) -> void:
		t += delta
		if not _hit and t >= Skills.VOLLEY_TIME:
			_hit = true
			_land()
		if t > Skills.VOLLEY_TIME + 0.35:
			queue_free()
		queue_redraw()

	func _land() -> void:
		var dmg := Skills.VOLLEY_DMG * (Skills.FIRE_MULT if burning else 1.0)
		for a in Game.level.enemies():
			if Combat.ground_dist(global_position, a.global_position) <= Skills.VOLLEY_RADIUS:
				var src: Node2D = shooter if is_instance_valid(shooter) else self
				var r: String = a.take_hit(dmg, src, 30.0, false, true)
				if r == "killed":
					Game.stats["kills"] += 1
				if not a.alerted and is_instance_valid(shooter) and Game.player:
					a.alert(Game.player)
		Fx.spark(global_position + Vector2(0, -4), Color(1, 0.55, 0.2) if burning else Color(0.85, 0.8, 0.7), 14)
		Game.shake(2.0)

	func _draw() -> void:
		var k: float = clamp(t / Skills.VOLLEY_TIME, 0.0, 1.0)
		# 그림: 0~3칸 떨어지는 중 · 4칸 꽂히는 순간 · 5칸 꽂힘. 칸 128×96, 바닥 타원 가운데가 (64, 76)
		var fi := mini(int(k * 4.0), 3) if t < Skills.VOLLEY_TIME else (4 if t < Skills.VOLLEY_TIME + 0.15 else 5)
		var fr := Skills.strip_frame("volley_fire" if burning else "volley", fi)
		if fr:
			draw_texture(fr, Vector2(-64, -76))
			return
		var col := Color(1.0, 0.45, 0.2) if burning else Color(1.0, 0.85, 0.5)
		var pts := PackedVector2Array()
		for i in 33:
			var a := TAU * i / 32.0
			pts.append(Vector2(cos(a) * Skills.VOLLEY_RADIUS, sin(a) * Skills.VOLLEY_RADIUS / Combat.Y_STRETCH))
		draw_polyline(pts, Color(col, 0.35 + 0.4 * k), 1.0)
		if t < Skills.VOLLEY_TIME * 0.35 or t > Skills.VOLLEY_TIME + 0.2:
			return
		# 위에서 비스듬히 떨어지는 화살 줄기
		for s in _streaks:
			var local_k: float = clamp((t - Skills.VOLLEY_TIME * 0.35 - s[1] * 0.3) / (Skills.VOLLEY_TIME * 0.5), 0.0, 1.0)
			if local_k <= 0.0 or local_k >= 1.0:
				continue
			var ground: Vector2 = s[0]
			var head := ground + Vector2(-30, -110) * (1.0 - local_k)
			draw_line(head, head + Vector2(-5, -14), Color(col, 0.9), 1.0)
