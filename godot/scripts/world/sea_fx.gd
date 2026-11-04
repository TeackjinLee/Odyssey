class_name SeaFx
extends Node
## 폭풍 바다 이펙트(챕터 2): 그림 이펙트(assets/fx/storm_*, tools/gen_storm.py)를 카메라 둘레 바다에 뿌린다.
## - 부서지는 파도머리·빗방울(물 위, 배 아래) · 바람에 흘러가는 거품 띠 · 물안개 · 빠를 때 뱃머리 물보라
## - crash(): 파도가 뱃전을 칠 때 바람 쪽 뱃전에 큰 파도
## strength 0~1은 레벨이 올리고 내린다(폭풍 화면 세기). 그림이 없으면 아무것도 안 한다.

## fx_layer(z 50) 안의 상대 z: 물 위·배 아래(바닥 -10 < 이것 -6 < 인물 0)
const Z_SURFACE := -56
const VIEW := Vector2(360, 210)

var strength := 0.0
var ship: Ship
var _ok := false
var _acc := {}
var _spray_t := 0.0
var _foam_tex: Array = []
var _foams: Array = []


func _ready() -> void:
	_ok = ResourceLoader.exists("res://assets/fx/storm_whitecap_a.png")
	if _ok and ResourceLoader.exists("res://assets/fx/storm_foam_streak.png"):
		var tex: Texture2D = load("res://assets/fx/storm_foam_streak.png")
		var n := 2
		var fw := tex.get_width() / n
		for i in n:
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(i * fw, 0, fw, tex.get_height())
			_foam_tex.append(at)


## 바람이 불어 가는 쪽(월드, 길이 1)
func _wind_world() -> Vector2:
	var w: Vector2 = Game.level.get("wind")
	return (Iso.ex * w.x + Iso.ey * w.y).normalized()


## 파도가 뱃전을 침: 바람 쪽(파도가 오는 쪽) 뱃전에. 그림은 왼쪽에서 오는 파도라 바람 쪽이 화면 오른쪽이면 뒤집는다
func crash(big: bool) -> void:
	if not _ok or ship == null:
		return
	var up := -_wind_world()
	var pos := ship.global_position + up * (18.0 if big else 24.0) + Vector2(0, 6)
	Fx.anim("storm_wave_crash", pos, up.x > 0.0, 95)


func _process(delta: float) -> void:
	_update_foam(delta)
	if not _ok or strength <= 0.02 or Game.level == null or Game.level.camera == null:
		return
	var cam: Vector2 = Game.level.camera.global_position
	var wd := _wind_world()
	var flip := wd.x < 0.0
	_spawn("cap", 9.0, delta, func():
		var p: Variant = _sea_point(cam)
		if p != null:
			Fx.anim("storm_whitecap_a" if randf() < 0.5 else "storm_whitecap_b", p, flip, Z_SURFACE))
	_spawn("rain", 36.0, delta, func():
		var p: Variant = _sea_point(cam)
		if p != null:
			Fx.anim("storm_rain_splash", p, false, Z_SURFACE))
	_spawn("mist", 1.6, delta, func():
		var p: Variant = _sea_point(cam)
		if p != null:
			Fx.anim("storm_spray_drift", p, flip, 80))
	_spawn("foam", 0.9, delta, func():
		if _foams.size() < int(7 * strength) and not _foam_tex.is_empty():
			var p: Variant = _sea_point(cam)
			if p != null:
				_add_foam(p, flip))
	# 뱃머리 물보라: 빠를 때 파도를 가르며
	_spray_t -= delta
	if ship and absf(ship.speed) > 0.3 and _spray_t <= 0.0:
		_spray_t = randf_range(0.35, 0.7) / strength
		var f := ship.fwd() * signf(ship.speed)
		var fw := (Iso.ex * f.x + Iso.ey * f.y)
		Fx.anim("storm_bow_spray", ship.global_position + fw * 2.1 + Vector2(0, 4), fw.x < 0.0, 92)


## 초당 rate × 세기만큼 고르게 부른다
func _spawn(key: String, rate: float, delta: float, f: Callable) -> void:
	var a: float = _acc.get(key, 0.0) + rate * strength * delta
	while a >= 1.0:
		a -= 1.0
		f.call()
	_acc[key] = a


## 화면 안 바다(맵 밖 열린 바다 포함) 한 점, 땅·암초면 null
func _sea_point(cam: Vector2) -> Variant:
	var p := cam + Vector2(randf_range(-VIEW.x, VIEW.x), randf_range(-VIEW.y, VIEW.y))
	var c := Iso.world_to_grid(p)
	var cell := Vector2i(floori(c.x), floori(c.y))
	var lv: IsoLevel = Game.level
	if lv.in_bounds(cell) and (lv.floor_kind.get(cell, "") != "water" or lv.reefs.has(cell)):
		return null
	if ship and p.distance_to(ship.global_position) < 70.0:
		return null
	return p.round()


func _add_foam(p: Vector2, flip: bool) -> void:
	var s := Sprite2D.new()
	s.texture = _foam_tex.pick_random()
	s.flip_h = flip
	s.position = p
	s.z_index = Z_SURFACE
	s.modulate.a = 0.0
	Game.level.fx_layer.add_child(s)
	_foams.append({"s": s, "t": 0.0, "life": randf_range(4.0, 6.5)})


## 거품 띠: 바람 쪽으로 흘러가며 나타났다 사라진다
func _update_foam(delta: float) -> void:
	if _foams.is_empty():
		return
	var v := _wind_world() * 14.0
	for i in range(_foams.size() - 1, -1, -1):
		var f: Dictionary = _foams[i]
		var s: Sprite2D = f["s"]
		if not is_instance_valid(s):
			_foams.remove_at(i)
			continue
		f["t"] += delta
		var t: float = f["t"]
		var life: float = f["life"]
		s.position += v * delta
		s.modulate.a = minf(1.0, minf(t / 0.8, (life - t) / 1.2)) * clampf(strength * 1.5, 0.0, 1.0) * 0.85
		if t >= life:
			s.queue_free()
			_foams.remove_at(i)
