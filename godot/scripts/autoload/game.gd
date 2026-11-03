extends Node
## 전역 상태: 입력 키 등록, 히트스톱·화면 흔들림, 현재 레벨·플레이어·부대 참조, HUD로 가는 신호.

signal objective_changed(title: String, text: String)
signal hint(text: String)
signal boss_changed(actor)
signal dialogue_requested(lines: Array, on_done: Callable)
signal chapter_cleared(stats: Dictionary)
signal player_died

var level: Node = null
var player: Node = null
var squad: Node = null
var hud: Node = null
var shake_amount := 0.0
var quest_marker := Vector2.INF
## 골라서 하는 목표 자리(미니맵에 빈 원으로 표시, 끝나면 레벨이 뺀다)
var side_markers: Array = []
var autoplay := false
## 자동 플레이 봇이 들키지 않게 활·뒤 처치로 지나가는지 (--auto=stealth)
var stealth_bot := false
## 오디세우스가 입은 옷(= assets/sprites/<이름>.png). 시트가 없는 이름은 기본 옷으로 돌아간다
const OUTFITS := ["odysseus", "odysseus_helm", "odysseus_king", "odysseus_sea", "odysseus_beggar", "odysseus_beggar_hood"]
## 챕터별 기본 옷(기획: 전투 갑옷 1·3·4, 항해복 2·5, 거지 변장 6). 시트가 없으면 기본 옷
const CHAPTER_OUTFITS := {1: "odysseus_king", 2: "odysseus_sea", 3: "odysseus_king", 4: "odysseus_king", 5: "odysseus_sea", 6: "odysseus_beggar_hood"}
## 무기를 숨기는 옷(변장)
const UNARMED_OUTFITS := ["odysseus_beggar", "odysseus_beggar_hood"]
var outfit := "odysseus"
var outfit_locked := false   # --outfit으로 골랐으면 챕터가 바꾸지 않는다
var stats := {"kills": 0, "time": 0.0, "downs": 0, "silent": 0, "alarms": 0, "detected": 0, "retries": 0}
## 마지막 체크포인트: {"id", "stats", "scout", "armory", "guards"} — 챕터를 처음 시작하면 비운다(레벨이 채움)
var checkpoint: Dictionary = {}

var ui_font: SystemFont

const KEYS := {
	"move_up": [KEY_W, KEY_UP],
	"move_down": [KEY_S, KEY_DOWN],
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"run": [KEY_SHIFT],
	"dodge": [KEY_SPACE],
	"heavy": [KEY_F],
	"switch_weapon": [KEY_Q],
	"interact": [KEY_E],
	"skill": [KEY_R],
	"cmd_follow": [KEY_1],
	"cmd_hold": [KEY_2],
	"cmd_focus": [KEY_3],
	"cmd_regroup": [KEY_4],
	"help": [KEY_F1, KEY_TAB],
	"pause": [KEY_ESCAPE],
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_register_input()
	ui_font = SystemFont.new()
	ui_font.font_names = PackedStringArray(["Apple SD Gothic Neo", "Noto Sans CJK KR", "Noto Sans KR", "Malgun Gothic", "NanumGothic"])
	ui_font.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
	var theme := Theme.new()
	theme.default_font = ui_font
	theme.default_font_size = 9
	get_tree().root.theme = theme
	var cmd := OS.get_cmdline_user_args()
	autoplay = "--auto" in cmd or "--auto=stealth" in cmd
	stealth_bot = "--auto=stealth" in cmd
	for a in cmd:
		if a.begins_with("--outfit="):
			set_outfit(a.get_slice("=", 1))
			outfit_locked = true


## 옷을 바꾼다. 시트가 있는 이름만 받는다. 플레이어가 있으면 바로 갈아입힌다
func set_outfit(id: String) -> void:
	if not ResourceLoader.exists("res://assets/sprites/%s.png" % id):
		return
	outfit = id
	if player and player.has_method("wear"):
		player.wear(id)


## 챕터 번호(1부터)의 기본 옷으로 갈아입는다
func apply_chapter_outfit(chapter: int) -> void:
	if not outfit_locked:
		set_outfit(CHAPTER_OUTFITS.get(chapter, "odysseus"))


## 입을 수 있는 다음 옷(시트가 있는 것만)
func next_outfit() -> String:
	var have: Array = OUTFITS.filter(func(n): return ResourceLoader.exists("res://assets/sprites/%s.png" % n))
	return have[(have.find(outfit) + 1) % have.size()] if have.size() > 0 else outfit


func _register_input() -> void:
	for action in KEYS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in KEYS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)
	for pair in [["attack", MOUSE_BUTTON_LEFT], ["block", MOUSE_BUTTON_RIGHT]]:
		if not InputMap.has_action(pair[0]):
			InputMap.add_action(pair[0])
		var mb := InputEventMouseButton.new()
		mb.button_index = pair[1]
		InputMap.action_add_event(pair[0], mb)
	var z := InputEventKey.new()
	z.physical_keycode = KEY_Z
	InputMap.action_add_event("attack", z)
	var k := InputEventKey.new()
	k.physical_keycode = KEY_K
	InputMap.action_add_event("block", k)
	# 메뉴·결과 화면 버튼: 방향키 외에 WASD로 고르고 E로도 누른다
	for pair in [["ui_up", KEY_W], ["ui_down", KEY_S], ["ui_left", KEY_A], ["ui_right", KEY_D], ["ui_accept", KEY_E]]:
		var ev := InputEventKey.new()
		ev.physical_keycode = pair[1]
		InputMap.action_add_event(pair[0], ev)


func reset_run() -> void:
	stats = {"kills": 0, "time": 0.0, "downs": 0, "silent": 0, "alarms": 0, "detected": 0, "retries": 0}
	shake_amount = 0.0
	quest_marker = Vector2.INF
	side_markers = []
	Engine.time_scale = 1.0


## 타격감: 아주 짧게 시간을 멈춘다 (실제 시간 기준으로 풀림).
func hitstop(duration: float) -> void:
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0


func shake(amount: float) -> void:
	shake_amount = max(shake_amount, amount)


func set_objective(title: String, text: String) -> void:
	objective_changed.emit(title, text)


func show_hint(text: String) -> void:
	hint.emit(text)


func say(lines: Array, on_done: Callable = Callable()) -> void:
	dialogue_requested.emit(lines, on_done)
