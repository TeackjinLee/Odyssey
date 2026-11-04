class_name StormFx
extends CanvasLayer
## 폭풍 화면 효과(챕터 2): 화면 좌표로 그리는 사선 빗줄기와 번개(화면 전체 번쩍임).
## strength 0~1(빗줄기 양·진하기)은 레벨이 올리고 내린다. lightning()은 한 번 번쩍.
## HUD(층 10) 아래, 월드 위(층 5)에 그린다. 기준 화면 640×360.
## 그림(assets/fx/storm_rain_streak·storm_lightning, tools/gen_storm.py)이 있으면 빗줄기·번개 줄기를 그림으로, 없으면 선.

const DROPS := 170
var strength := 0.0
var flash := 0.0
## 비가 기우는 방향(화면). 레벨이 바람에 맞춰 바꾼다
var lean := Vector2(-0.35, 1.0)
var _drops: Array = []
var _canvas: Node2D
## 빗줄기 그림(왼쪽 아래로 기운 것 · 뒤집은 것)과 번개 그림
var _streaks: Array = []
var _streaks_flip: Array = []
var _bolts: Array = []
var _bolt := -1
var _bolt_x := 0.0


func _ready() -> void:
	layer = 5
	_canvas = Node2D.new()
	add_child(_canvas)
	_canvas.draw.connect(_draw_fx)
	for i in DROPS:
		_drops.append(Vector3(randf() * 640.0, randf() * 360.0, randf_range(0.55, 1.0)))
	_streaks = _strip("res://assets/fx/storm_rain_streak", false)
	_streaks_flip = _strip("res://assets/fx/storm_rain_streak", true)
	_bolts = _strip("res://assets/fx/storm_lightning", false)


## 가로로 늘어놓은 프레임 한 장(.png + .json의 frames) → 프레임 텍스처들
func _strip(base: String, flip: bool) -> Array:
	var out := []
	if not ResourceLoader.exists(base + ".png") or not FileAccess.file_exists(base + ".json"):
		return out
	var meta: Variant = JSON.parse_string(FileAccess.get_file_as_string(base + ".json"))
	var tex: Texture2D = load(base + ".png")
	var img := tex.get_image()
	var n := int(meta["frames"])
	var fw := img.get_width() / n
	for i in n:
		var part := img.get_region(Rect2i(i * fw, 0, fw, img.get_height()))
		if flip:
			part.flip_x()
		out.append(ImageTexture.create_from_image(part))
	return out


func lightning() -> void:
	flash = 1.0
	if not _bolts.is_empty():
		_bolt = randi() % _bolts.size()
		_bolt_x = randf_range(10.0, 190.0) if randf() < 0.5 else randf_range(370.0, 550.0)   # 가운데(배)는 피해서


func _process(delta: float) -> void:
	flash = maxf(0.0, flash - delta * 3.2)
	if strength <= 0.01 and flash <= 0.0:
		_canvas.queue_redraw()
		return
	var v := lean.normalized() * 560.0
	for i in _drops.size():
		var d: Vector3 = _drops[i]
		d.x = fposmod(d.x + v.x * d.z * delta, 660.0) - 10.0
		d.y += v.y * d.z * delta
		if d.y > 370.0:
			d.y -= 380.0
			d.x = randf() * 660.0 - 10.0
		_drops[i] = d
	_canvas.queue_redraw()


func _draw_fx() -> void:
	if strength > 0.01:
		var v := lean.normalized()
		var n := int(_drops.size() * strength)
		var set: Array = _streaks_flip if lean.x > 0.0 else _streaks
		for i in n:
			var d: Vector3 = _drops[i]
			var p := Vector2(d.x, d.y).round()
			if set.is_empty():
				_canvas.draw_line(p, p - v * 9.0 * d.z, Color(0.72, 0.8, 0.95, 0.45 * d.z * strength), 1.0)
			elif i % 2 == 0:   # 그림 빗줄기는 길어서 반만
				var tx: Texture2D = set[i % set.size()]
				_canvas.draw_texture(tx, p - tx.get_size() * 0.5, Color(1, 1, 1, 0.5 * d.z * strength))
	if flash > 0.0:
		_canvas.draw_rect(Rect2(0, 0, 640, 360), Color(0.88, 0.92, 1.0, 0.5 * flash * flash))
		# 번개 줄기: 번쩍임이 셀 때만, 깜박이며
		if _bolt >= 0 and flash > 0.35 and fmod(flash * 10.0, 2.0) > 0.5:
			_canvas.draw_texture(_bolts[_bolt], Vector2(_bolt_x, 0.0).round())
