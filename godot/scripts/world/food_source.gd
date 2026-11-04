class_name FoodSource
extends Interactable
## 먹을 것이 있는 지점(docs/NUTRITION.md §4): 채집(나무·덤불·좌판·항아리) · 고기(잡은 동물이 남김) · 낚시터.
## 음식 값은 data/food.json. 길게 눌러 먹고, 다 먹으면 regrow초 뒤 다시 열린다(0이면 사라짐).
## 배의 식량 창고가 있는 챕터(레벨에 rations)에서는 짧게 눌러 창고에 넣는다(부하 몫 — Rations.units_of).

var food_id := ""
var info: Dictionary = {}
var left := 1
var _regrow_t := 0.0
var _t := 0.0
## 그림: "" 아무것도 안 그림(소품이 보임) · "fruit" 열매(먹을 수 있는 만큼) · "meat" 고기 한 점 · "bob" 낚시찌
## 그려 받은 음식 그림 assets/sprites/food_icons.png(tools/gen_food.py)에 그 음식 칸이 있으면 그것, 없으면 코드 그림
var look := ""
static var _icons: Texture2D = null
static var _icon_meta: Dictionary = {}
var fruit_color := Color(0.75, 0.25, 0.45)


func setup(id: String, look_kind := "") -> FoodSource:
	food_id = id
	info = Nutrition.food(id)
	look = look_kind
	left = int(info.get("servings", 1))
	label = "%s %s" % [info.get("name", id), info.get("verb", "먹기")]
	if Game.level and Game.level.get("rations") != null and info.get("kind", "") != "fish" and not info.has("no_store"):
		label = "%s — 길게: %s · 짧게: 배 창고에(+%d)" % [info.get("name", id), info.get("verb", "먹기"), Rations.units_of(info)]
	hold_time = 3.5 if info.get("kind", "") == "fish" else (1.0 if info.get("kind", "") == "meat" else 0.7)
	radius = 26.0
	on_use = _eat
	return self


func _ready() -> void:
	super._ready()
	add_to_group("food")
	z_index = 1 if look == "bob" else 0


func _eat(by) -> void:
	if not by is Player:
		return
	by.eat(food_id)
	if info.get("kind", "") == "fish":
		Sfx.at("splash", global_position, -8.0)
	_use_one()


## 짧게: 배의 식량 창고에 넣는다(창고가 없는 챕터에서는 아무 일도 없음)
func tap(by) -> void:
	var r = Game.level.get("rations") if Game.level else null
	if r == null or not by is Player or info.get("kind", "") == "fish":
		return
	if info.has("no_store"):
		Game.show_hint(String(info["no_store"]))
		return
	var n: int = r.add(Rations.units_of(info))
	Fx.text(global_position + Vector2(0, -30), "창고 +%d" % n if n > 0 else "창고가 가득 찼다", Color(0.75, 0.9, 1.0))
	Sfx.play("ui_ok", -10.0)
	Game.stats["stored"] = Game.stats.get("stored", 0) + n
	_use_one()


func _use_one() -> void:
	left -= 1
	if left > 0:
		return
	enabled = false
	var regrow := float(info.get("regrow", 0))
	if regrow > 0.0:
		_regrow_t = regrow
	else:
		queue_free()
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	if not enabled and _regrow_t > 0.0:
		_regrow_t -= delta
		if _regrow_t <= 0.0:
			enabled = true
			left = int(info.get("servings", 1))
	if look != "":
		queue_redraw()


func _draw() -> void:
	if not enabled:
		return
	match look:
		"fruit":
			if _icon(food_id, Vector2.ZERO, 0.4, left):
				return
			for i in left:
				var p := Vector2(-4 + i * 6, -3 + sin(_t * 2.0 + i) * 0.5)
				draw_circle(p, 2.0, Color(0.1, 0.05, 0.05))
				draw_circle(p, 1.4, fruit_color)
				draw_rect(Rect2(p + Vector2(-0.5, -1.4), Vector2(1, 1)), Color(1, 1, 1, 0.7))
		"meat":
			if _icon("meat", Vector2.ZERO, 0.5):
				return
			draw_circle(Vector2(0, -2), 4.5, Color(0.12, 0.05, 0.04))
			draw_circle(Vector2(0, -2), 3.6, Color(0.72, 0.28, 0.22))
			draw_circle(Vector2(-1, -3), 1.4, Color(0.95, 0.75, 0.65))
			draw_line(Vector2(3, -1), Vector2(7, 1), Color(0.9, 0.88, 0.8), 2.0)
		"bob":
			var y := sin(_t * 2.4) * 1.2
			for r in [5.0, 8.0]:
				var a := 0.35 * (1.0 - fmod(_t * 0.5 + r * 0.1, 1.0))
				draw_arc(Vector2(0, 2), r, 0, TAU, 16, Color(0.8, 0.9, 1.0, a), 1.0)
			if _icon("bob", Vector2(0, 2 + y), 0.3):
				return
			draw_rect(Rect2(-1.5, -4 + y, 3, 3), Color(0.9, 0.2, 0.15))
			draw_rect(Rect2(-1.5, -1 + y, 3, 2), Color(0.95, 0.95, 0.9))
			draw_line(Vector2(0, -4 + y), Vector2(-14, -22), Color(0.8, 0.8, 0.75, 0.5), 1.0)


## 음식 그림 칸 하나를 발 기준점 at에 n개 나란히 그린다(그림이 없거나 그 칸이 없으면 false)
func _icon(id: String, at: Vector2, k: float, n := 1) -> bool:
	if _icons == null:
		if not ResourceLoader.exists("res://assets/sprites/food_icons.png"):
			return false
		_icons = load("res://assets/sprites/food_icons.png")
		_icon_meta = JSON.parse_string(FileAccess.get_file_as_string("res://assets/sprites/food_icons.json"))
	var items: Dictionary = _icon_meta.get("items", {})
	if not items.has(id):
		return false
	var fw := float(_icon_meta["frame"][0])
	var fh := float(_icon_meta["frame"][1])
	var src := Rect2(int(items[id]) * fw, 0, fw, fh)
	var anchor := Vector2(_icon_meta["anchor"][0], _icon_meta["anchor"][1]) * k
	var gap := fw * k * 0.55
	for i in n:
		var p := at + Vector2((i - (n - 1) * 0.5) * gap, sin(_t * 2.0 + i) * 0.4) - anchor
		draw_texture_rect_region(_icons, Rect2(p.round(), Vector2(fw, fh) * k), src)
	return true
