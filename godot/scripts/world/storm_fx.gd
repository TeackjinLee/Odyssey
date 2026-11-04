class_name StormFx
extends CanvasLayer
## 폭풍 화면 효과(챕터 2): 화면 좌표로 그리는 사선 빗줄기와 번개(화면 전체 번쩍임).
## strength 0~1(빗줄기 양·진하기)은 레벨이 올리고 내린다. lightning()은 한 번 번쩍.
## HUD(층 10) 아래, 월드 위(층 5)에 그린다. 기준 화면 640×360.

const DROPS := 170
var strength := 0.0
var flash := 0.0
## 비가 기우는 방향(화면). 레벨이 바람에 맞춰 바꾼다
var lean := Vector2(-0.35, 1.0)
var _drops: Array = []
var _canvas: Node2D


func _ready() -> void:
	layer = 5
	_canvas = Node2D.new()
	add_child(_canvas)
	_canvas.draw.connect(_draw_fx)
	for i in DROPS:
		_drops.append(Vector3(randf() * 640.0, randf() * 360.0, randf_range(0.55, 1.0)))


func lightning() -> void:
	flash = 1.0


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
		for i in n:
			var d: Vector3 = _drops[i]
			var p := Vector2(d.x, d.y).round()
			_canvas.draw_line(p, p - v * 9.0 * d.z, Color(0.72, 0.8, 0.95, 0.45 * d.z * strength), 1.0)
	if flash > 0.0:
		_canvas.draw_rect(Rect2(0, 0, 640, 360), Color(0.88, 0.92, 1.0, 0.5 * flash * flash))
