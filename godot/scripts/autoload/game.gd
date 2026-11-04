extends Node
## 전역 상태: 입력 키 등록, 히트스톱·화면 흔들림, 현재 레벨·플레이어·부대 참조, HUD로 가는 신호,
## 설정(user://settings.json: 음량·전체 화면·키 바꾸기)과 진행 저장(user://save.json: 깬 챕터·마지막 체크포인트).

signal objective_changed(title: String, text: String)
signal hint(text: String)
signal boss_changed(actor)
signal dialogue_requested(lines: Array, on_done: Callable)
signal chapter_cleared(stats: Dictionary)
signal player_died
## 튜토리얼 카드: text가 비면 닫기, done이면 ✓ 표시 뒤 닫힘. slot은 하단 슬롯 번호(-1 없음, 깜빡여 알려 줌)
signal tutorial_changed(text: String, done: bool, slot: int)

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
const OUTFITS := ["odysseus_ch1", "odysseus", "odysseus_helm", "odysseus_king", "odysseus_sea", "odysseus_beggar", "odysseus_beggar_hood"]
## 챕터별 기본 옷(기획: 전투 갑옷 1·3·4, 항해복 2·5, 거지 변장 6). 시트가 없으면 기본 옷
const CHAPTER_OUTFITS := {1: "odysseus_ch1", 2: "odysseus_sea", 3: "odysseus_king", 4: "odysseus_king", 5: "odysseus_sea", 6: "odysseus_beggar_hood"}
## 무기를 숨기는 옷(변장)
const UNARMED_OUTFITS := ["odysseus_beggar", "odysseus_beggar_hood"]
var outfit := "odysseus"
var outfit_locked := false   # --outfit으로 골랐으면 챕터가 바꾸지 않는다
## 연출 중: 오디세우스가 입력을 받지 않는다(Player.script_goal이 있으면 그리로 걷는다)
var cutscene := false
var stats := {"kills": 0, "time": 0.0, "downs": 0, "silent": 0, "alarms": 0, "detected": 0, "retries": 0, "meals": 0}
## 마지막 체크포인트: {"chapter", "id", "stats", "food", …챕터마다 더} — 챕터를 처음 시작하면 비운다(레벨이 채움)
var checkpoint: Dictionary = {}
## 지금 하는 챕터 번호(1부터)
var chapter := 1

var ui_font: SystemFont
var _key_re: RegEx

const SETTINGS_PATH := "user://settings.json"
const SAVE_PATH := "user://save.json"
const DEFAULT_SETTINGS := {"vol_master": 1.0, "vol_music": 0.8, "vol_sfx": 1.0, "fullscreen": false, "keys": {}}
## 설정: 음량 0~1(전체·음악·효과음), 전체 화면, 바꾼 키 {동작: [물리 키 코드…]}
var settings: Dictionary = {}
## 진행: {"cleared": [깬 챕터 번호…], "checkpoint": 마지막 체크포인트(Game.checkpoint와 같은 모양),
##   "carry": {"<다음 챕터 번호>": 이어받을 값}} — 이어받을 값은 carry_for 참고
var progress: Dictionary = {"cleared": [], "checkpoint": {}, "carry": {}}
## 키 바꾸기 화면에 나오는 동작과 이름
const REBIND := [["move_up", "위로 이동"], ["move_down", "아래로 이동"], ["move_left", "왼쪽 이동"], ["move_right", "오른쪽 이동"],
	["run", "달리기"], ["attack", "공격"], ["block", "방패 막기"], ["heavy", "강공격"], ["dodge", "구르기"],
	["switch_weapon", "검 ↔ 활"], ["interact", "상호작용"], ["skill", "전투의 함성"], ["decoy", "미끼 던지기"],
	["cmd_follow", "부대: 따라오기"], ["cmd_hold", "부대: 위치 사수"], ["cmd_focus", "부대: 집중 공격"],
	["cmd_regroup", "부대: 후퇴·집결"], ["cmd_special", "부대 특수 명령"]]

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
	"cmd_special": [KEY_5],
	"decoy": [KEY_C],
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
	_setup_buses()
	settings = DEFAULT_SETTINGS.duplicate(true)
	var st = _read_json(SETTINGS_PATH)
	if st is Dictionary:
		settings.merge(st, true)
	var pg = _read_json(SAVE_PATH)
	if pg is Dictionary:
		progress.merge(pg, true)
	apply_settings()
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
func apply_chapter_outfit(ch: int) -> void:
	if not outfit_locked:
		set_outfit(CHAPTER_OUTFITS.get(ch, "odysseus"))


## 입을 수 있는 다음 옷(시트가 있는 것만)
func next_outfit() -> String:
	var have: Array = OUTFITS.filter(func(n): return ResourceLoader.exists("res://assets/sprites/%s.png" % n))
	return have[(have.find(outfit) + 1) % have.size()] if have.size() > 0 else outfit


# ── 설정·저장 ─────────────────────────────────────────
func _exit_tree() -> void:
	Sfx.clear()
	Bgm.clear()


func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	return JSON.parse_string(FileAccess.get_file_as_string(path))


func _write_json(path: String, data: Dictionary) -> void:
	if autoplay:
		return   # 검증용 봇은 사람의 저장을 건드리지 않는다
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))


## 음악·효과음 버스(없으면 만든다). 효과음은 Sfx가 "SFX" 버스로 낸다
func _setup_buses() -> void:
	for bus in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus) == -1:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, bus)
			AudioServer.set_bus_send(i, "Master")


func apply_settings() -> void:
	for pair in [["Master", "vol_master"], ["Music", "vol_music"], ["SFX", "vol_sfx"]]:
		var i := AudioServer.get_bus_index(pair[0])
		var v: float = float(settings.get(pair[1], 1.0))
		AudioServer.set_bus_mute(i, v <= 0.001)
		AudioServer.set_bus_volume_db(i, linear_to_db(maxf(v, 0.001)))
	if DisplayServer.get_name() != "headless":
		var fs: bool = settings.get("fullscreen", false)
		var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fs else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != mode:
			DisplayServer.window_set_mode(mode)
	var keys: Dictionary = settings.get("keys", {})
	for action in keys:
		if InputMap.has_action(action):
			_set_keys(action, keys[action])


func save_settings() -> void:
	_write_json(SETTINGS_PATH, settings)


## 동작의 키보드 키를 바꾼다(마우스 버튼은 그대로 둔다)
func _set_keys(action: String, codes: Array) -> void:
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey:
			InputMap.action_erase_event(action, ev)
	for k in codes:
		var ev := InputEventKey.new()
		ev.physical_keycode = int(k)
		InputMap.action_add_event(action, ev)


func rebind(action: String, physical_keycode: int) -> void:
	settings["keys"][action] = [physical_keycode]
	_set_keys(action, [physical_keycode])
	save_settings()


## 키를 모두 처음대로
func reset_keys() -> void:
	settings["keys"] = {}
	for action in KEYS:
		_set_keys(action, KEYS[action])
	_set_keys("attack", [KEY_Z])
	_set_keys("block", [KEY_K])
	save_settings()


## 화면에 보일 키 이름(첫 키보드 키). 예: "C", "Space", "Shift"
func key_label(action: String) -> String:
	if not InputMap.has_action(action):
		return "?"
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey:
			return OS.get_keycode_string(ev.physical_keycode)
	return "-"


## 글 속 {동작}을 지금 묶인 키 이름으로 바꾼다. 예: "{interact} — 말 걸기" → "E — 말 걸기".
## 키를 바꾸면 바로 반영되게 HUD가 그릴 때마다 부른다(튜토리얼 카드·목표·알림·대사).
func keys_text(s: String) -> String:
	if s.find("{") < 0:
		return s
	if _key_re == null:
		_key_re = RegEx.create_from_string("\\{([a-z_]+)\\}")
	var out := s
	for m in _key_re.search_all(s):
		var a := m.get_string(1)
		if InputMap.has_action(a):
			out = out.replace(m.get_string(), key_label(a))
	return out


## 진행 저장: 체크포인트가 생기거나 바뀔 때, 챕터를 깼을 때
func save_progress() -> void:
	progress["checkpoint"] = checkpoint.duplicate(true)
	_write_json(SAVE_PATH, progress)


func mark_cleared(ch: int) -> void:
	if not is_cleared(ch):
		progress["cleared"].append(ch)
	checkpoint = {}
	save_progress()


func is_cleared(ch: int) -> bool:
	return progress["cleared"].any(func(c): return int(c) == ch)


## 챕터를 깨면 다음 챕터로 넘길 값을 적는다: {"food": 영양 state(), "crew": [[역할, 이름]…], "rations": 식량 창고, "fullness": 부하 배부름}
func set_carry(to_chapter: int, data: Dictionary) -> void:
	if not progress.has("carry") or not progress["carry"] is Dictionary:
		progress["carry"] = {}
	progress["carry"][str(to_chapter)] = data.duplicate(true)
	save_progress()


## 그 챕터가 이어받을 값(앞 챕터를 깬 적이 없으면 빈 사전 → 챕터가 기본값을 쓴다)
func carry_for(ch: int) -> Dictionary:
	var c: Variant = progress.get("carry", {})
	if c is Dictionary and c.get(str(ch)) is Dictionary:
		return c[str(ch)].duplicate(true)
	return {}


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
	stats = {"kills": 0, "time": 0.0, "downs": 0, "silent": 0, "alarms": 0, "detected": 0, "retries": 0, "meals": 0}
	shake_amount = 0.0
	quest_marker = Vector2.INF
	side_markers = []
	cutscene = false
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


## 튜토리얼 카드 띄우기(한 번에 하나). 끝나면 tutorial_done()
func tutorial(text: String, slot := -1) -> void:
	tutorial_changed.emit(text, false, slot)


func tutorial_done() -> void:
	tutorial_changed.emit("", true, -1)


func say(lines: Array, on_done: Callable = Callable()) -> void:
	dialogue_requested.emit(lines, on_done)
