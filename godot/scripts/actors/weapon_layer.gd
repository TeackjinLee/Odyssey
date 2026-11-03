class_name WeaponLayer
extends RefCounted
## 몸 그림과 따로 그린 무기를 손 위치(시트 .json의 hands)에 붙여 그린다.
## 오른손 = 검(활을 들 땐 숨김), 왼손 = 방패(활을 들 땐 활, 방패는 등에 멘다).
## 방향에 따라 무기를 몸 앞/뒤로 보내고, 방패는 보이는 각도에 맞는 그림(정면·비스듬히·옆·뒷면)으로 바꾼다.
## 공격 중에는 검을 손을 축으로 휘두른다. 그려 받은 공격 그림이면 그 프레임의 주먹에 붙이고 팔 방향으로 세운다.

# 방향: 0 동 1 남동 2 남 3 남서 4 서 5 북서 6 북 7 북동
const MAIN_FRONT := [0, 1, 2, 3, 6, 7]
const OFF_FRONT := [0, 1, 2, 3, 4]
const SHIELD_VIEW := {
	0: ["side", false], 1: ["three_quarter", false], 2: ["front", false], 3: ["three_quarter", true],
	4: ["side", true], 5: ["back", true], 6: ["back", false], 7: ["back", false],
}
# 휘두르는 각도(도, 바라보는 쪽 기준): 시작 → 끝
const SWINGS := {
	"attack1": [-125.0, 75.0], "attack2": [125.0, -75.0], "attack3": [-175.0, 15.0], "heavy": [-170.0, 190.0],
}
const SWEEP_TIME := 0.08
const SHIELD_SCALE := 0.8   # 방패를 머리 크기에 맞게 줄인다(그려 받은 기준 그림의 크기)
const ARM_FACE_BIAS := 6.0   # 주먹이 가슴 가까이 있을 때 칼끝이 바라보는 쪽으로 기울게

var actor: Actor
var main: Sprite2D
var off: Sprite2D
var slung: Sprite2D
var _meta: Dictionary
var _k := 0.5


func attach(a: Actor) -> void:
	actor = a
	_meta = AssetLibrary.weapons()
	_k = float(_meta.get("scale", 0.5))
	main = _sprite()
	off = _sprite()
	slung = _sprite()


func _sprite() -> Sprite2D:
	var s := Sprite2D.new()
	s.centered = false
	s.scale = Vector2(_k, _k)
	actor.add_child(s)
	return s


func _tex_set(s: Sprite2D, file: String, grip: Array, flip := false) -> void:
	s.texture = AssetLibrary.weapon_texture(file)
	var g := Vector2(grip[0], grip[1])
	s.flip_h = flip
	if flip:
		g.x = s.texture.get_width() - g.x
	s.offset = -g


func _order(s: Sprite2D, front: bool) -> void:
	var bi := actor.body.get_index()
	var si := s.get_index()
	if front and si < bi:
		actor.move_child(s, bi)
	elif not front and si > bi:
		actor.move_child(s, bi)


func update() -> void:
	var hands := AssetLibrary.character_hands(actor.sheet)
	var down := actor.state == Actor.St.DEAD or actor.state == Actor.St.DOWNED
	if hands.is_empty() or down:
		main.visible = false
		off.visible = false
		slung.visible = false
		return
	var table: Array = hands.get(actor.anim_base, hands["idle"])
	var row: Array = table[min(actor.body.frame, table.size() - 1)]
	var h: Array = row[actor.dir]
	var anchor := AssetLibrary.character_anchor(actor.sheet)
	var bk := actor.body.scale.x
	var rh := (Vector2(h[0], h[1]) - anchor) * bk
	var lh := (Vector2(h[2], h[3]) - anchor) * bk
	var d := actor.dir
	var fv := actor.facing
	var fa := fv.angle()
	var bow_mode: bool = actor.get("weapon") == "bow"
	var chest := Vector2(0, -26) + actor.body.position

	# ── 오른손: 검 ──
	main.visible = not bow_mode and actor.state != Actor.St.INTERACT
	if main.visible:
		_tex_set(main, _meta["sword"]["file"], _meta["sword"]["grip"])
		var rest := Vector2(fv.x * 0.6, 1.0).angle()
		var ang := rest
		var pos := rh
		var front := d in MAIN_FRONT
		if actor.state == Actor.St.ATTACK and actor.get("current") is Dictionary:
			var spec: Dictionary = actor.get("current")
			var anim: String = spec.get("anim", "")
			if anim in AssetLibrary.character_drawn(actor.sheet):
				# 그려 받은 공격 그림: 주먹에 붙이고 칼끝은 팔이 뻗은 쪽(가슴 → 주먹)으로 — 팔을 뻗으면 앞을 향한다
				pos = rh
				# 시트가 프레임마다 재 둔 칼끝 각도(어깨→주먹)가 있으면 그것을, 없으면 가슴→주먹 방향을 쓴다
				ang = deg_to_rad(float(h[4])) if h.size() > 4 else (rh - chest + fv * ARM_FACE_BIAS).angle()
				front = true
			elif SWINGS.has(anim):
				var t := actor.state_time
				var hit: float = spec["hit"]
				var a0: float = fa + deg_to_rad(SWINGS[anim][0])
				var a1: float = fa + deg_to_rad(SWINGS[anim][1])
				var reach := 0.0
				if t < hit:
					var k := ease(t / hit, 0.4)
					ang = lerp_angle(rest, a0, k) if anim != "heavy" else lerp(rest, a0, k)
				elif t < hit + SWEEP_TIME:
					var k := (t - hit) / SWEEP_TIME
					ang = lerp(a0, a1, k)
					reach = sin(k * PI)
				else:
					ang = a1
				pos = rh.lerp(chest + fv * 6.0, 0.35) + fv * 6.0 * reach
				front = true
		elif actor.state == Actor.St.BLOCK:
			ang = Vector2(fv.x * 0.3, -1.0).angle()
		main.position = pos
		main.rotation = ang + PI / 2.0
		_order(main, front)

	# ── 왼손: 방패 또는 활 ──
	off.visible = true
	off.scale = Vector2(_k, _k) * (1.0 if bow_mode else SHIELD_SCALE)
	slung.scale = Vector2(_k, _k) * SHIELD_SCALE
	if bow_mode:
		_tex_set(off, _meta["bow"]["file"], _meta["bow"]["grip"])
		if actor.state == Actor.St.BOW:
			off.position = chest + fv * 8.0
			off.rotation = fa
			off.flip_v = false
			_order(off, fv.y > -0.3)
		else:
			off.position = lh
			off.rotation = 0.0
			off.flip_h = fv.x < 0.0
			_order(off, d in OFF_FRONT)
		_place_slung(chest, fv)
	else:
		slung.visible = false
		if actor.state == Actor.St.BLOCK:
			var view := "front" if fv.y > 0.3 else ("back" if fv.y < -0.6 else "three_quarter")
			_tex_set(off, _meta["shield"]["views"][view], _meta["shield"]["grip"], fv.x < 0.0 and view == "three_quarter")
			off.position = chest + Vector2(0, 4) + fv * Vector2(8.0, 5.0)
			_order(off, fv.y > -0.3)
		else:
			var sv: Array = SHIELD_VIEW[d]
			_tex_set(off, _meta["shield"]["views"][sv[0]], _meta["shield"]["grip"], sv[1])
			off.position = lh + Vector2(0, 2)
			_order(off, d in OFF_FRONT)
		off.rotation = 0.0


func _place_slung(chest: Vector2, fv: Vector2) -> void:
	slung.visible = true
	var away := fv.y < -0.3
	_tex_set(slung, _meta["shield"]["views"]["front" if away else "back"], _meta["shield"]["grip"])
	slung.position = chest + Vector2(0, 2) - fv * Vector2(3.0, 2.0)
	slung.rotation = 0.0
	_order(slung, away)
