class_name Interactable
extends Node2D
## E로 쓰는 지점(대화·권양기·쓰러진 부하). hold_time > 0이면 그만큼 길게 눌러야 한다.

var label := "조사하기"
var hold_time := 0.0
var radius := 28.0
var enabled := true
## 0~1이면 길게 누르기가 끝나지 않고, 누르고 있는 동안 레벨이 올리는 이 값을 막대로 보여 준다(권양기)
var progress := -1.0
var on_use: Callable


func _ready() -> void:
	add_to_group("interactable")


func use(by: Node) -> void:
	if enabled and on_use.is_valid():
		on_use.call(by)
