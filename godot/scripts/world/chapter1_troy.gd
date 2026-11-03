class_name Chapter1Troy
extends IsoLevel
## CHAPTER 1 — 트로이의 목마.
## 밤, 불타는 트로이. 오디세우스가 혼자 목마에서 내려(부하는 목마 안에 대기) 세 갈래 길 —
## 횃불이 늘어선 대로, 어두운 서쪽 뒷골목, 불타는 구역을 지나 시장으로 이어지는 동쪽 길 — 중 하나로 성문 앞 북쪽 가로까지 몰래 간다.
## 가로 끝의 꺼진 횃불에 불을 붙여 시논에게 신호를 보내면 부하들이 합류하고,
## 성문 경비대(수비대장) 처치 → 권양기로 성문 개방 → 아카이아 증원군과 성문 거점 사수.
## 들키면 경보병이 갈래마다 하나 있는 경보 종으로 달려가고, 종이 울리면 성문 경비가 2명씩 는다.
## 골라서 하는 목표: 바다 문 밖 부두에 묶인 정찰병 구출(부하 +1), 뒷골목 성벽 밑 무기고 불태우기(마지막 반격에 궁수 없음).
## 권양기는 E를 누르고 있는 동안만 돌아가고 손을 떼면 성문이 다시 내려간다(부하를 2 위치 사수로 곁에 세워 지킴).
## 사수 반격 3파: 방패벽 → 높은 곳 궁수 → 권양기 돌격(트로이군이 권양기를 돌려 성문을 닫으면 다시 열어야 함).
## 체크포인트: 잠입 시작(시논 대화 뒤) · 부하 합류 · 권양기 앞. 죽으면 그 자리부터 다시 하고, 골라서 하는 목표는 이룬 그대로 둔다.
## 튜토리얼: 목마 광장에서 시논이 연습을 시킨다 — 이동 → 말 걸기 → 졸고 있는 보초 조용히 처치 → 횃불 끄기 → 활로 쏘기.
## 그 뒤로는 처음 겪는 일(의심·전투·부하 합류·권양기·보스)마다 튜토리얼 카드가 하나씩 뜬다(_tut, HUD 하단).
## 성문이 열리면 아카이아 대군이 줄지어 들어오고(ARMY_SIZE), 불이 도시로 번지며, 트로이군이 네 차례 대규모로 반격한다
## (방패벽 → 궁수 → 권양기 돌격 → 왕자 데이포보스의 총공세).
##
## 격자(48×50): x는 화면 오른쪽 아래, y는 왼쪽 아래로 늘어난다. 성벽은 네 변(y=3 · x=2 · x=35 · y=49),
## 앞쪽 두 변(x=35, y=49)은 오디세우스를 가리면 반투명해진다. x=36부터는 바위 해안과 바다(지나갈 수 없음, 엔딩에 배가 나아가는 곳).
## 위(북)부터: 성문 광장 y4~9(서쪽 나무 종탑, 동쪽 아테나 신전) · 북쪽 가로 y10~12 ·
## 세 갈래 y13~37(뒷골목 x3~6, 대로 x16~20, 동쪽 길 x27~32 = 위쪽 불타는 구역 + 아래쪽 시장,
## 가운데 분수 광장 y22~25로 서로 이어짐) · 목마 광장 y38~48(목마는 서쪽).
## 시장 남쪽 골목(y33~34) 끝의 바다 문(35,33)을 나가면 부두 — 묶인 정찰병은 가운데 부두 끝에 있다.

const GATE_CELLS := [Vector2i(17, 3), Vector2i(18, 3)]
const ZONE_CELL := Vector2(18.0, 6.5)
const ZONE_RADIUS := 56.0
## 신호 횃불 자리: 갈래마다 하나 (뒷골목 · 대로 · 시장 끝)
const SIGNAL_CELLS := [Vector2i(4, 12), Vector2i(15, 12), Vector2i(33, 11)]
## 묶인 정찰병 자리(바다 문 밖 가운데 부두 끝)와 무기고(뒷골목 성벽 밑, 화로 옆)
const SCOUT_CELL := Vector2(40.4, 38.6)
## 동쪽 성벽의 바다 문(시장 남쪽 골목 끝 → 부두), 목마(서쪽 성벽 가까이, 4×2), 분수(대로 한가운데, 2×2)
const SEA_GATE := Vector2i(35, 33)
const HORSE_CELL := Vector2i(9, 41)
const FOUNTAIN_CELL := Vector2i(17, 23)
const ARMORY_CELLS := [Vector2i(3, 22), Vector2i(3, 23), Vector2i(3, 24)]
## 높은 곳 궁수가 올라서는 자리(북쪽 가로 서쪽 짐더미 · 신전 계단 가운데)
const PERCH_CELLS := [Vector2i(12, 10), Vector2i(30, 8)]
## 권양기: 처음 여는 데 / 다시 여는 데 / 트로이군이 닫는 데 걸리는 시간, 손을 떼면 내려가는 빠르기(1초에)
const WINCH_TIME := 12.0
const REOPEN_TIME := 5.0
const CLOSE_TIME := 4.0
const WINCH_DROP := 0.04
## 트로이 돌격병이 서서 권양기를 돌리는 자리(권양기 칸 바로 앞)
const WINCH_STAND := Vector2(20.5, 6.6)
## 거점 점령 속도(초당 %): 싸우는 동안 / 알아챈 적이 없을 때(파 사이에 오래 서 있지 않게)
const CAPTURE_RATE := 1.9
const CAPTURE_CALM := 3.2
## 오디세우스가 사다리로 내려와 서는 자리(목마 동쪽 옆)
const START_CELL := Vector2(13.8, 43.2)
## 연습 보초 자리: 졸고 있는 보초(조용히 처치 연습) · 횃불 빛 안의 보초(활 연습)와 그 옆 횃불
const DRILL_SNEAK := Vector2(21.5, 44.5)
const DRILL_BOW := Vector2(29.5, 45.5)
const DRILL_TORCH := Vector2i(27, 44)
## 성문이 열린 뒤 들어오는 아카이아 대군: 병사 수, 한 명씩 들어오는 간격(초), 맡을 자리(북쪽 가로·세 갈래 입구·성문 광장)
const ARMY_SIZE := 24
const ARMY_INTERVAL := 0.45
const ARMY_POSTS := [Vector2(6.0, 11.0), Vector2(30.0, 11.0), Vector2(18.5, 14.0), Vector2(10.0, 11.5), Vector2(26.0, 11.5),
	Vector2(4.5, 14.0), Vector2(30.0, 14.5), Vector2(16.5, 15.0), Vector2(20.5, 15.0), Vector2(14.0, 11.0), Vector2(22.5, 11.0),
	Vector2(13.0, 8.0), Vector2(23.5, 8.0)]
## 트로이군 물결: 반격 n파 뒤 살아 있는 트로이군이 TIDE_MIN보다 적으면 세 갈래 중 한 곳에서 셋씩 더 몰려온다.
## 파마다 더 보낼 수 있는 수(TIDE_BUDGET)가 정해져 있어, 다 막으면 숨 돌릴 틈(점령이 차는 시간)이 생긴다
const TIDE_MIN := [8, 11, 13, 16]
const TIDE_BUDGET := [6, 9, 9, 9]
const TIDE_INTERVAL := 2.2
## 반격 2파부터 파마다 오디세우스가 회복하는 체력
const WAVE_HEAL := 50.0
## 왕자가 살아 있으면 점령이 여기서 멈춘다
const PRINCE_CAP := 95.0
## 경보 종이 울릴 때마다 성문 경비대에 붙는 병사
const ALARM_GUARDS := [["trojan_sword", Vector2(17.5, 7.5)], ["trojan_spear", Vector2(18.5, 8.0)]]

var step := -1
var gate_sprites: Array = []
var winch_point: Interactable
var sinon: Npc
var stealth_group: Array = []
var guard_group: Array = []
var signals: Array = []
var capture := 0.0
var waves_sent := 0
var zone_pos := Vector2.ZERO
var _done := false
var scout: Npc
var scout_freed := false
var armory_point: Interactable
var armory_sprites: Array = []
var armory_burned := false
var gate_open := false
var opened_once := false
var winch_progress := 0.0
var close_progress := 0.0
var _cranked := false
var _crank_frame := -1
var _winch_attacks := 0
var captain: Enemy
var _boss_hint := false
## 튜토리얼 카드 줄: [글, 끝났는지 묻는 Callable, 깜빡일 하단 슬롯, 넘어가는 시간(0이면 끝날 때까지)]
var _tut_queue: Array = []
var _tut_cur: Array = []
var _tut_time := 0.0
var _tut_gap := 0.0
var _tut_seen := {}
## 앞에 끼운 카드 수(다음 카드가 뜨면 0)
var _tut_front := 0
## step 0 안의 연습 단계: 0 시논에게 가기 · 1 조용히 처치 · 2 횃불 끄기 · 3 활 · 4 끝
var drill_phase := 0
var drill: Array = []
var drill_torch: Dictionary = {}
var _drill_swapped := false
var _sneak_card: Array = []
var _start_pos := Vector2.ZERO
## 아카이아 대군: 남은 병사, 다음 병사까지 남은 시간, 들어온 병사 수
var _army_left := 0
var _army_timer := 0.0
var _army_in := 0
## 성문이 열리면 불이 번지는 집들: [Sprite2D, 그림 이름] (build의 houses에서 "spread")
var _houses: Array = []
var prince: Enemy
var _routed := false
var _tide_timer := 0.0
var _tide_left := 0
## 엔딩: 부두의 갤리선과 그 불빛, 엔딩 때 불이 붙는 동쪽 집들(부두에서 보임), 건너뛰기, 끝났는지
var _galley: Sprite2D
var _galley_light: PointLight2D
var _late_houses: Array = []
var _ending := false
var _skip := false
var ending_done := false


func build() -> void:
	chapter_title = "CHAPTER 1 — 트로이의 목마"
	W = 48
	H = 50
	canvas_mod.color = Color(0.5, 0.5, 0.74)
	# 바닥: 성 밖(위·왼쪽 풀밭, 오른쪽 바다), 성 안 구역
	fill(Rect2i(0, 0, 36, 3), "grass")
	fill(Rect2i(0, 0, 2, 50), "grass")
	fill(Rect2i(16, 0, 4, 3), "road")
	fill(Rect2i(36, 0, 12, 50), "water")
	fill(Rect2i(36, 0, 1, 50), "sand")
	fill(Rect2i(12, 4, 13, 6), "plaza")
	fill(Rect2i(26, 4, 9, 6), "plaza")
	fill(Rect2i(3, 10, 32, 3), "dirt")
	fill(Rect2i(16, 13, 5, 26), "road")
	fill(Rect2i(3, 13, 4, 35), "dirt")
	fill(Rect2i(27, 13, 6, 9), "ash")
	fill(Rect2i(27, 22, 6, 17), "plaza")
	fill(Rect2i(6, 22, 10, 4), "plaza")
	fill(Rect2i(21, 22, 6, 4), "plaza")
	fill(Rect2i(21, 30, 6, 2), "dirt")
	fill(Rect2i(7, 38, 26, 10), "plaza")
	# 바다 문 밖 부두: 성벽을 따라 난 나무 길 + 바다로 뻗은 부두 셋
	fill(Rect2i(36, 31, 1, 15), "planks")
	fill(Rect2i(37, 33, 4, 2), "planks")
	fill(Rect2i(37, 38, 5, 2), "planks")
	fill(Rect2i(37, 43, 3, 2), "planks")
	for c in floor_kind:
		if floor_kind[c] in ["water", "sand"]:
			set_solid(c)
	# 성벽·탑·성문: 네 변. 화면 앞쪽 두 변(x=35, y=49)은 오디세우스를 가리면 반투명해진다
	for x in range(2, 36):
		var c := Vector2i(x, 3)
		if c in GATE_CELLS:
			continue
		add_prop("tower" if x in [2, 8, 16, 19, 26, 35] else "wall", c, true, false)
	for y in range(4, H):
		add_prop("tower" if y in [10, 18, 26, 34, 42] else "wall", Vector2i(2, y), true, false)
	for y in range(4, H):
		var c := Vector2i(35, y)
		if c == SEA_GATE:
			continue
		add_prop("tower" if y in [10, 18, 26, 32, 34, 42, 49] else "wall", c, true, true)
	for x in range(3, 35):
		add_prop("tower" if x in [10, 18, 26] else "wall", Vector2i(x, 49), true, true)
	for c in GATE_CELLS:
		gate_sprites.append(add_prop("gate_closed", c, true, false))
	add_prop("gate_open", SEA_GATE, false, true)
	# 집 (이름, 칸, "burnt" 처음부터 불탐 · "spread" 성문이 열리면 불이 번짐 · "" 그대로)
	var houses := [
		# 성문 광장 서쪽 (동쪽은 신전 언덕)
		["house_b", Vector2i(4, 6), "spread"], ["house_a", Vector2i(9, 6), "burnt"],
		# 서쪽 덩어리 (뒷골목과 대로 사이)
		["house_b", Vector2i(7, 13), "spread"], ["house_c", Vector2i(11, 13), ""], ["house_d", Vector2i(14, 13), "spread"],
		["house_a", Vector2i(7, 16), ""], ["house_d", Vector2i(10, 17), ""], ["house_c", Vector2i(13, 16), ""],
		["house_c", Vector2i(7, 19), ""], ["house_a", Vector2i(10, 20), "spread"], ["house_b", Vector2i(13, 20), ""],
		["house_b", Vector2i(7, 26), ""], ["house_a", Vector2i(11, 26), "spread"], ["house_d", Vector2i(14, 26), "burnt"],
		["house_d", Vector2i(7, 29), ""], ["house_c", Vector2i(10, 29), ""], ["house_a", Vector2i(13, 30), ""],
		["house_a", Vector2i(7, 33), ""], ["house_b", Vector2i(10, 33), ""], ["house_c", Vector2i(14, 33), "burnt"],
		["house_d", Vector2i(7, 36), "spread"],
		# 동쪽 덩어리 (대로와 시장 사이)
		["house_c", Vector2i(21, 13), ""], ["house_a", Vector2i(24, 13), "spread"],
		["house_d", Vector2i(24, 16), ""], ["house_a", Vector2i(21, 17), "burnt"],
		["house_b", Vector2i(21, 20), "spread"], ["house_a", Vector2i(24, 20), ""],
		["house_d", Vector2i(21, 26), ""], ["house_c", Vector2i(24, 26), ""], ["house_a", Vector2i(21, 28), ""],
		["house_b", Vector2i(21, 32), ""], ["house_a", Vector2i(24, 33), ""],
		["house_d", Vector2i(21, 35), "spread"], ["house_a", Vector2i(24, 36), ""],
		# 동쪽 끝: 위쪽 둘은 불타는 구역, 아래 셋은 시장
		["house_c", Vector2i(33, 13), "burnt"], ["house_a", Vector2i(33, 18), "burnt"], ["house_d", Vector2i(33, 24), "spread"],
		["house_c", Vector2i(33, 30), ""], ["house_a", Vector2i(33, 35), ""],
	]
	for h in houses:
		if h[2] == "burnt":
			add_burning_house(h[0], h[1])
		else:
			var s := add_prop(h[0], h[1])
			if h[2] == "spread":
				_houses.append([s, h[0]])
			elif h[1].x >= 21:
				_late_houses.append([s, h[0]])
	# 성문 광장: 서쪽 나무 종탑, 동쪽 높은 터 위 아테나 신전 + 계단·사자상
	add_prop("bell_tower", Vector2i(10, 4))
	add_prop("temple", Vector2i(29, 5))
	for c in [Vector2i(29, 8), Vector2i(31, 8)]:
		add_prop("steps", c, false, false)
	for c in [Vector2i(28, 8), Vector2i(32, 8)]:
		add_prop("lion", c, true, false)
	for c in [Vector2i(27, 4), Vector2i(33, 4)]:
		add_prop("cypress", c, true, false)
	# 목마 광장: 서쪽 성벽 가까이 목마, 옆구리에 기댄 사다리(오디세우스가 내려온 곳)
	add_prop("horse", HORSE_CELL)
	add_prop("ladder", HORSE_CELL + Vector2i(4, 0), false, false)
	for c in [Vector2i(15, 40), Vector2i(26, 40), Vector2i(15, 46), Vector2i(26, 46)]:
		add_prop("column", c)
	add_light(Iso.grid_to_world(Vector2(HORSE_CELL) + Vector2(2, 2)), Color(0.55, 0.65, 1.0), 0.5, 2.5, false)
	# 횃불: 대로는 밝은 곳과 그늘이 번갈아, 뒷골목은 종 옆에 하나, 시장 하나(+화로), 성문 광장 둘, 부두 하나
	for c in [Vector2i(16, 15), Vector2i(20, 15), Vector2i(16, 28), Vector2i(20, 28), Vector2i(16, 36), Vector2i(20, 36),
			Vector2i(6, 31), Vector2i(27, 23), Vector2i(12, 8), Vector2i(23, 8), Vector2i(34, 26), Vector2i(37, 37)]:
		add_torch(c)
	drill_torch = add_torch(DRILL_TORCH)
	for c in [Vector2i(15, 4), Vector2i(21, 4), Vector2i(30, 31), Vector2i(5, 21)]:
		var b := add_prop("brazier", c, true, false)
		add_fire(b, Vector2(0, -16), 0.6)
	# 경보 종: 뒷골목 · 분수 광장 · 불타는 구역
	for c in [Vector2i(3, 30), Vector2i(20, 23), Vector2i(32, 21)]:
		add_bell(c)
	for c in [Vector2i(12, 4), Vector2i(23, 4), Vector2i(16, 38), Vector2i(20, 38)]:
		add_prop("banner_troy", c, true, false)
	# 분수 광장(세 갈래가 만나는 가운데 가로): 대로 한가운데 분수, 양쪽 차양 좌판
	add_prop("fountain", FOUNTAIN_CELL)
	add_light(Iso.grid_to_world(Vector2(FOUNTAIN_CELL) + Vector2(1, 1)), Color(0.5, 0.7, 1.0), 0.35, 1.2, false, 0.3)
	add_prop("stall_red", Vector2i(12, 22))
	add_prop("stall_white", Vector2i(24, 25))
	for c in [Vector2i(9, 25), Vector2i(15, 25), Vector2i(22, 22)]:
		add_prop("pot", c, true, false)
	# 불타는 구역(동쪽 길 위쪽): 부서진 기둥·돌무더기. 가운데(x29~30)는 반격 무리가 지나가게 비운다
	for c in [Vector2i(28, 15), Vector2i(31, 14), Vector2i(32, 19), Vector2i(27, 20)]:
		add_prop("rubble", c, true, false)
	for c in [Vector2i(28, 18), Vector2i(32, 16)]:
		add_prop("column_broken", c, true, false)
	# 시장(동쪽 길 아래쪽): 짐더미·좌판
	for c in [Vector2i(31, 23), Vector2i(29, 26), Vector2i(28, 28), Vector2i(31, 28), Vector2i(28, 33), Vector2i(31, 34),
			Vector2i(29, 37), Vector2i(11, 9), Vector2i(25, 9), Vector2i(10, 44), Vector2i(30, 44), Vector2i(4, 38)]:
		add_prop("crate" if hash(c) % 2 == 0 else "barrel", c, true, false)
	add_prop("cart", Vector2i(28, 31))
	add_prop("stall_red", Vector2i(31, 25))
	add_prop("stall_white", Vector2i(32, 37))
	for c in [Vector2i(30, 24), Vector2i(29, 35), Vector2i(12, 47)]:
		add_prop("amphora", c, true, false)
	for c in [Vector2i(19, 9), Vector2i(5, 41)]:
		add_prop("rubble", c, true, false)
	add_prop("winch", Vector2i(20, 5))
	# 서쪽 뒷골목: 사이프러스·화분(나무는 시야를 가리는 엄폐물)
	for c in [Vector2i(3, 17), Vector2i(6, 19), Vector2i(3, 34), Vector2i(6, 26)]:
		add_prop("cypress", c, true, true)
	for c in [Vector2i(3, 27), Vector2i(6, 40)]:
		add_prop("pot", c, true, false)
	# 무기고: 통·창걸이·상자 (화로 불빛 안)
	for i in ARMORY_CELLS.size():
		armory_sprites.append(add_prop(["barrel", "spear_rack", "crate"][i], ARMORY_CELLS[i], true, false))
	# 높은 곳 궁수 발판(지나갈 수 있음 — 화살이 막히지 않게): 북쪽 가로 서쪽 짐더미, 신전 계단 가운데
	add_prop("crate", PERCH_CELLS[0], false, false)
	add_prop("steps", PERCH_CELLS[1], false, false)
	# 부두: 갤리선·작은 배·말뚝, 해안 바위
	_galley = add_prop("galley", Vector2i(37, 40), true, true)
	add_prop("boat", Vector2i(38, 36), true, false)
	for c in [Vector2i(41, 33), Vector2i(41, 34), Vector2i(40, 43), Vector2i(40, 44)]:
		add_prop("pier_post", c, false, false)
	_galley_light = add_light(Iso.grid_to_world(Vector2(39.5, 41.0)), Color(1.0, 0.6, 0.3), 0.45, 0.9)
	for y in [1, 6, 13, 20, 27, 47]:
		add_prop("rock", Vector2i(36, y), true, false)
	# 성 밖 나무
	for c in [Vector2i(5, 1), Vector2i(10, 0), Vector2i(24, 1), Vector2i(29, 0), Vector2i(33, 1)]:
		add_prop("pine", c, true, false)
	for c in [Vector2i(0, 9), Vector2i(1, 21), Vector2i(0, 33), Vector2i(1, 45)]:
		add_prop("cypress", c, true, false)


func start() -> void:
	zone_pos = Iso.grid_to_world(ZONE_CELL)
	player = Player.new()
	player.position = Iso.grid_to_world(START_CELL)
	world.add_child(player)
	player.face(_gdir(Vector2(1, 0)))
	_start_pos = player.position
	sinon = Npc.new()
	sinon.setup("greek_archer", "시논", _talk_sinon)
	sinon.position = Iso.grid_to_world(START_CELL + Vector2(2.6, 0.6))
	world.add_child(sinon)
	var south := _gdir(Vector2(0, 1))
	stealth_group = [
		# 대로: 입구 보초 · 오르내리는 창병 · 가운데 궁수
		_spawn("trojan_sword", Vector2(18.5, 37.0), [], south),
		_spawn("trojan_spear", Vector2(17.5, 34.0), [Vector2(17.5, 34.0), Vector2(17.5, 17.0)]),
		_spawn("trojan_archer", Vector2(19.0, 26.5), [], south),
		# 뒷골목: 오르내리는 검병 · 위쪽 보초
		_spawn("trojan_sword", Vector2(4.5, 45.0), [Vector2(4.5, 45.0), Vector2(4.5, 23.6)]),
		_spawn("trojan_sword", Vector2(4.5, 15.0), [], south),
		# 시장: 짐더미 사이를 도는 창병 · 위쪽 보초
		_spawn("trojan_spear", Vector2(28.5, 37.0), [Vector2(28.5, 37.0), Vector2(31.5, 31.0), Vector2(28.5, 25.0),
			Vector2(31.5, 18.0), Vector2(28.5, 25.0), Vector2(31.5, 31.0)]),
		_spawn("trojan_sword", Vector2(30.0, 14.5), [], south),
		# 부두: 묶인 정찰병을 지키는 보초(부두 끝 쪽을 봄 — 성벽 길로 오면 등 뒤)
		_spawn("trojan_sword", SCOUT_CELL + Vector2(-2.8, 0.0), [], _gdir(Vector2(1, 0))),
	]
	guard_group = [
		_spawn("trojan_sword", Vector2(15.5, 6.5)),
		_spawn("trojan_sword", Vector2(20.5, 7.0)),
		_spawn("trojan_spear", Vector2(16.5, 8.5)),
		_spawn("trojan_spear", Vector2(19.5, 8.5)),
		_spawn("trojan_archer", Vector2(23.5, 6.0)),
		_spawn("trojan_captain", Vector2(18.0, 5.2)),
	]
	captain = guard_group[5]
	# 연습 보초: 시야가 짧고 들켜도 경보를 울리지 않는다
	drill = [_spawn("trojan_sword", DRILL_SNEAK, [], _gdir(Vector2(1, 0))), _spawn("trojan_sword", DRILL_BOW, [], _gdir(Vector2(1, 0)))]
	for d in drill:
		d.vision = 60.0
		d.raises_alarm = false
	for g in guard_group:
		g.vision = 130.0
		g.raises_alarm = false
	for c in SIGNAL_CELLS:
		var s := add_prop("torch_post_off", c, true, false)
		var it := Interactable.new()
		it.label = "횃불로 신호 보내기"
		it.hold_time = 1.2
		it.radius = 30.0
		it.enabled = false
		it.position = s.global_position + Vector2(0, 6)
		it.on_use = func(_by): _send_signal(s)
		world.add_child(it)
		signals.append(it)
	alarm_rung.connect(_on_alarm)
	scout = Npc.new()
	scout.setup("greek_sword", "정찰병 테르산드로스", _free_scout)
	scout.talk.label = "묶인 정찰병 풀어 주기"
	scout.talk.hold_time = 1.5
	scout.fixed_dir = Iso.dir8(_gdir(Vector2(-1, 0)))
	scout.fixed_anim = "downed"
	scout.position = Iso.grid_to_world(SCOUT_CELL)
	world.add_child(scout)
	armory_point = Interactable.new()
	armory_point.label = "무기고에 불 지르기"
	armory_point.hold_time = 1.5
	armory_point.radius = 26.0
	armory_point.position = Iso.grid_to_world(Vector2(4.6, 23.5))
	armory_point.on_use = func(_by): _burn_armory(false)
	world.add_child(armory_point)
	Game.side_markers = [scout.global_position, armory_point.global_position]
	winch_point = Interactable.new()
	winch_point.label = "권양기 돌리기"
	winch_point.hold_time = 999.0   # 끝나지 않음 — 누르고 있는 동안 _update_winch가 돌린다
	winch_point.progress = 0.0
	winch_point.radius = 30.0
	winch_point.enabled = false
	winch_point.position = Iso.grid_to_world(Vector2(20.5, 5.5)) + Vector2(0, 10)
	world.add_child(winch_point)
	_set_step(0)


## 격자 방향 → 화면 방향 (적이 바라볼 쪽)
func _gdir(g: Vector2) -> Vector2:
	return (Iso.grid_to_world(g) - Iso.grid_to_world(Vector2.ZERO)).normalized()


func _spawn(kind: String, g: Vector2, route := [], facing_dir := Vector2.ZERO) -> Enemy:
	var e := Enemy.new()
	e.setup(kind)
	e.position = Iso.grid_to_world(g)
	for r in route:
		e.patrol.append(Iso.grid_to_world(r))
	world.add_child(e)
	if facing_dir != Vector2.ZERO:
		e.face(facing_dir)
		e.home_facing = facing_dir
	return e


func _spawn_crew(at: Vector2) -> void:
	var crew := [["sword", "에우릴로코스"], ["spear", "폴리테스"], ["archer", "엘페노르"]]
	for i in crew.size():
		var c := Companion.new()
		c.setup(crew[i][0], crew[i][1])
		c.position = at + Vector2(-20 + i * 20, 18)
		world.add_child(c)
		squad.add_member(c)


# ── 체크포인트 ──────────────────────────────────────
func _save_checkpoint(id: String) -> void:
	Game.checkpoint = {"id": id, "stats": Game.stats.duplicate(), "scout": scout_freed, "armory": armory_burned,
		"guards": guard_group.size()}
	Game.save_progress()
	if id != "stealth":
		Fx.text(player.global_position + Vector2(0, -64), "체크포인트", Color(0.55, 0.85, 1.0))


## 체크포인트에서 다시: 그 단계의 시작으로 옮기고, 그 뒤에 이룬 골라서 하는 목표·경보로 는 경비도 되살린다.
func restore_checkpoint(cp: Dictionary) -> void:
	sinon.talk.enabled = false
	if cp.get("armory", false):
		_burn_armory(true)
	_end_drill()
	match cp["id"]:
		"stealth":
			_set_step(1)
		"merge":
			skip_to_gate()
			for i in (int(cp.get("guards", 6)) - 6) / 2:
				_on_alarm({})
			Game.checkpoint["guards"] = guard_group.size()
		"winch":
			skip_to_winch()
	if cp.get("scout", false) and not scout_freed:
		scout_freed = true
		Game.side_markers.erase(scout.global_position)
		scout.queue_free()
		_add_scout(player.global_position + Vector2(-20, 24))
		_refresh_side()
	Game.show_hint("체크포인트에서 다시 시작")


## 검증용(--start=gate): 잠입을 건너뛰고 부하와 함께 성문 경비대 앞에서 시작
func skip_to_gate() -> void:
	_end_drill()
	for e in stealth_group:
		e.queue_free()
	stealth_group.clear()
	sinon.talk.enabled = false
	for it in signals:
		it.enabled = false
	player.position = Iso.grid_to_world(Vector2(18.5, 13.5))
	_spawn_crew(player.position)
	_set_step(2)


## 검증용(--start=winch): 성문 경비대까지 치운 뒤 권양기 앞에서 시작
func skip_to_winch() -> void:
	skip_to_gate()
	for e in guard_group:
		e.queue_free()
	guard_group.clear()
	player.position = Iso.grid_to_world(Vector2(20.0, 7.5))
	for i in squad.members.size():
		squad.members[i].position = player.position + Vector2(-20 + i * 20, 18)
	_set_step(3)


## 검증용(--start=ending): 성문 거점을 다 차지한 것으로 하고 바로 엔딩
func skip_to_ending() -> void:
	skip_to_winch()
	_set_gate(true)
	opened_once = true
	winch_point.enabled = false
	waves_sent = 4
	_routed = true
	_set_step(4)
	capture = 100.0


# ── 퀘스트 ────────────────────────────────────────────
func _set_step(s: int) -> void:
	step = s
	if s in [1, 2, 3]:
		_save_checkpoint(["stealth", "merge", "winch"][s - 1])
	match s:
		0:
			Game.set_objective(chapter_title, "목마에서 내려왔다. 목마 옆의 첩자 시논에게 가라")
			Game.quest_marker = sinon.global_position
			_tut("WASD / 방향키 — 이동\nShift를 누르고 있으면 달린다 (빠르지만 발소리가 난다)",
				func(): return player.position.distance_to(_start_pos) > 40.0)
			_tut("E — 시논에게 말 걸기", func(): return drill_phase >= 1 or step != 0)
		1:
			_tut_clear()
			Game.set_objective(chapter_title, "들키지 않고 성문 앞 북쪽 가로까지 가서 횃불로 신호를 보내라" + _side_text())
			for it in signals:
				it.enabled = true
			Game.quest_marker = signals[1].global_position
			Game.show_hint("길은 셋 — 횃불이 늘어선 대로 · 어두운 서쪽 뒷골목 · 불타는 동쪽 길(밝다). 원하는 길로 가라")
			_tut("세 갈래 중 하나를 골라 북쪽 가로까지\n미니맵의 노란 점이 목표, 빈 원은 골라서 하는 목표", Callable(), -1, 7.0)
			_tut("C — 미끼 던지기 (조준한 쪽으로 돌멩이)\n떨어진 곳으로 보초가 고개를 돌려 살피러 간다. 그 틈에 지나가거나 뒤로 돌아가라",
				func(): return player.decoy_cd > 0.0, 6, 16.0)
		2:
			Game.set_objective(chapter_title, "성문 앞 광장의 경비대를 처치하라  (0/%d)" % guard_group.size() + _side_text())
			Game.quest_marker = Iso.grid_to_world(Vector2(18, 7))
			_tut_once("squad", "부하 셋이 합류했다 — 1~4 부대 명령\n1 따라오기 · 2 위치 사수 · 3 집중 공격 · 4 후퇴·집결", Callable(), -1, 7.0)
			_tut_once("focus", "3 — 조준한 적을 부하들이 한꺼번에 친다\n먼저 궁수를 노려라",
				func(): return squad.mode == Squad.Mode.FOCUS, -1, 16.0)
			_tut_once("special", "5 — 부대 특수 명령 (조준한 곳, 쿨타임 18초)\n검병 방패벽(화살을 막음) · 창병 창 던지기 · 궁병 일제 사격",
				func(): return squad.special_cd > 0.0, 7, 16.0)
			_tut_once("cry", "R — 전투의 함성: 주변 부하 회복·강화, 가까운 적은 휘청인다",
				func(): return player.skill_cd > 0.0, 5, 16.0)
		3:
			winch_point.enabled = true
			Game.quest_marker = winch_point.global_position
			Game.boss_changed.emit(null)
			_tut_seen["winch"] = true
			_tut_urgent("E를 누르고 있기 — 권양기 돌리기\n손을 떼면 성문이 다시 내려간다. 2(위치 사수)로 부하를 곁에 세워라",
				func(): return winch_progress > 0.25, -1, 25.0)
		4:
			Game.set_objective(chapter_title, "성문 거점을 사수하라  (0%)")
			Game.quest_marker = zone_pos
			_tut_seen["zone"] = true
			_tut_urgent("붉은 원 안에 머물러라 — 원이 다 차면 승리\n적이 원 안에 있으면 멈춘다. 대군이 들어올 시간을 벌어라",
				func(): return capture > 12.0, -1, 14.0)


func _talk_sinon(_by) -> void:
	if step != 0 or drill_phase > 0:
		Game.say([["시논", "성문 앞 북쪽 가로에 닿으면 꺼진 횃불에 불을 붙이십시오. 부하들을 보내겠습니다."]])
		return
	sinon.talk.enabled = false
	drill_phase = 1
	Game.say([
		["시논", "오디세우스 님! 트로이 놈들은 목마를 신의 선물이라 믿고 밤새 잔치를 벌였습니다."],
		["오디세우스", "부하들은 아직 목마 안에 둔다. 내가 먼저 성문까지 길을 살피겠다."],
		["시논", "그럼 몸부터 푸시지요. 저기 동쪽 기둥 너머에 술에 취해 졸고 있는 보초가 있습니다. 등 뒤로 다가가 소리 없이 처리해 보십시오."],
	], _drill_sneak)


# ── 튜토리얼: 목마 광장 연습 ─────────────────────────
func _drill_sneak() -> void:
	Game.set_objective(chapter_title, "연습 1/3 — 졸고 있는 보초를 조용히 처치하라")
	Game.quest_marker = drill[0].global_position
	_sneak_card = _tut("적의 등 뒤로 다가가 E — 조용히 처치\n바닥의 옅은 부채꼴이 적의 시야다. 그 안으로 들어가지 마라",
		func(): return not drill[0].is_alive())


func _drill_torch() -> void:
	drill_phase = 2
	Game.set_objective(chapter_title, "연습 2/3 — 동쪽 보초 옆의 횃불을 꺼라")
	Game.quest_marker = drill_torch["point"].global_position
	_tut("E — 횃불 끄기\n불빛 안에선 적이 멀리서도 본다. 어두우면 바로 앞까지 와야 본다",
		func(): return not drill_torch["lit"] or not drill[1].is_alive())


func _drill_bow() -> void:
	drill_phase = 3
	Game.set_objective(chapter_title, "연습 3/3 — 활로 보초를 쏘아라")
	Game.quest_marker = drill[1].global_position
	_tut("Q — 활로 바꾸기 · J/좌클릭을 누르고 있다가 떼면 발사\n눈치채지 못한 적은 한 발에 쓰러진다",
		func(): return not drill[1].is_alive(), 0)


func _drill_end() -> void:
	drill_phase = 4
	Game.say([
		["시논", "훌륭하십니다. 이제 진짜입니다."],
		["시논", "성문 앞 북쪽 가로 끝마다 꺼진 횃불이 있습니다. 불을 붙이시면 그걸 신호로 부하들을 보내겠습니다."],
		["시논", "들키면 놈들이 경보 종으로 달려갑니다. 종이 울리면 성문 경비가 늘어날 겁니다."],
		["시논", "그리고… 시장 남쪽 골목 끝 바다 문 밖, 부두에 우리 정찰병이 묶여 있습니다. 뒷골목 성벽 밑 무기고를 태우면 놈들 궁수가 화살을 못 챙길 겁니다."],
		["오디세우스", "대로, 뒷골목, 불타는 동쪽 길… 길은 셋이군. 소리 없이 가겠다."],
	], func(): _set_step(1))


## 연습 단계 진행: 하나 끝날 때마다 다음 연습으로. 들키면 싸우는 법을 알려 준다.
func _update_drill() -> void:
	if drill_phase == 1 and not _drill_swapped and drill[0].is_alive() and drill[0].alerted:
		_drill_swapped = true
		_sneak_card[0] = "들켰다! J/좌클릭 — 검 3연타로 쓰러뜨려라\n다음엔 등 뒤로, 걸어서 다가가라"
		_sneak_card[2] = 1
		if _tut_cur == _sneak_card:
			Game.tutorial(_sneak_card[0], 1)
	match drill_phase:
		1:
			if not drill[0].is_alive():
				_drill_torch()
		2:
			if not drill_torch["lit"] or not drill[1].is_alive():
				_drill_bow()
		3:
			if not drill[1].is_alive():
				_drill_end()


## 연습을 건너뛸 때(체크포인트·검증용 시작): 연습 보초를 치우고 연습을 끝낸 것으로 친다.
func _end_drill() -> void:
	drill_phase = 4
	for d in drill:
		if is_instance_valid(d):
			d.queue_free()
	drill.clear()
	_tut_clear()


# ── 튜토리얼 카드 ─────────────────────────────────────
## 카드 하나를 줄에 넣는다. done이 참이 되거나 timeout(0이면 없음)이 지나면 ✓ 표시 뒤 다음 카드.
## front면 기다리는 카드들 앞(앞에 끼운 카드들 뒤)에 넣는다. front가 아닌 카드는 그 단계(step)가 지나면 버린다.
func _tut(text: String, done: Callable, slot := -1, timeout := 0.0, front := false) -> Array:
	var card := [text, done, slot, timeout, -1 if front else step]
	if front:
		_tut_queue.insert(mini(_tut_front, _tut_queue.size()), card)
		_tut_front += 1
	else:
		_tut_queue.append(card)
	return card


## 한 판에 한 번만 띄우는 카드
func _tut_once(id: String, text: String, done: Callable, slot := -1, timeout := 0.0, front := false) -> void:
	if _tut_seen.has(id):
		return
	_tut_seen[id] = true
	_tut(text, done, slot, timeout, front)


## 급한 카드(보스 등): 지금 카드를 미뤄 두고 바로 띄운다.
func _tut_urgent(text: String, done: Callable, slot := -1, timeout := 0.0) -> void:
	if not _tut_cur.is_empty():
		_tut_queue.push_front(_tut_cur)
		_tut_cur = []
	_tut_queue.push_front([text, done, slot, timeout, step])
	_tut_gap = 0.0


func _tut_clear() -> void:
	_tut_queue.clear()
	_tut_front = 0
	if not _tut_cur.is_empty():
		_tut_cur = []
		Game.tutorial_done()


func _update_tutorial(delta: float) -> void:
	if _tut_gap > 0.0:
		_tut_gap -= delta
		return
	if _tut_cur.is_empty():
		while not _tut_queue.is_empty() and _tut_queue[0][4] >= 0 and _tut_queue[0][4] != step:
			_tut_queue.pop_front()
		if _tut_queue.is_empty():
			return
		_tut_cur = _tut_queue.pop_front()
		_tut_time = 0.0
		_tut_front = 0
		Game.tutorial(_tut_cur[0], _tut_cur[2])
		return
	_tut_time += delta
	var done: Callable = _tut_cur[1]
	var timeout: float = _tut_cur[3]
	if (done.is_valid() and done.call()) or (timeout > 0.0 and _tut_time >= timeout):
		_tut_cur = []
		_tut_gap = 1.2
		Game.tutorial_done()


## 처음 겪는 일마다 카드: 의심 · 첫 전투(연타 → 막기 → 구르기 → 강공격) · 보스
func _watch_firsts() -> void:
	if step == 1 and not _tut_seen.has("sus"):
		for e in enemies():
			if not e.alerted and e.suspicion > 0.3 and e not in drill:
				_tut_once("sus", "적 머리 위 ? — 의심하는 중\n시야(부채꼴) 밖 그늘로 물러나면 의심이 풀린다",
					func(): return enemies().all(func(x): return x.alerted or x.suspicion <= 0.0), -1, 7.0)
				break
	if step in [1, 2] and not _tut_seen.has("atk") and enemies().any(func(e): return e.alerted and e not in drill):
		_tut_once("atk", "싸움이다! J/좌클릭 — 검 3연타 (세 번째가 가장 세다)", func(): return player.state == Actor.St.ATTACK, 1, 10.0, true)
		_tut_once("blk", "K/우클릭 — 방패 막기\n적이 붉게 깜빡이는 순간 막으면 패링: 적이 휘청인다",
			func(): return player.state == Actor.St.BLOCK, 3, 12.0, true)
		_tut_once("dodge", "Space — 구르기: 구르는 동안은 맞지 않는다 (스태미나 소모)",
			func(): return player.state == Actor.St.DODGE, 4, 12.0, true)
		_tut_once("heavy", "F — 강공격: 방패를 든 적의 방어를 부순다", func(): return player.heavy_cd > 0.0, 2, 12.0, true)


func _send_signal(torch: Sprite2D) -> void:
	if step != 1:
		return
	for it in signals:
		it.enabled = false
	torch.texture = AssetLibrary.prop_texture("torch_post")
	add_light(torch.global_position + Vector2(1, -20), Color(1.0, 0.55, 0.25), 0.6, 0.85)
	Sfx.play("cry", -10.0)
	_spawn_crew(player.global_position + Vector2(0, 30))
	Game.say([
		["에우릴로코스", "장군! 시논의 신호를 받고 그림자를 따라 왔습니다."],
		["오디세우스", "성문 경비를 치운다. 내 명령을 따르라."],
	], func(): _set_step(2))


func _side_text() -> String:
	return "\n선택  %s 정찰병 구출 · %s 무기고 불태우기" % ["●" if scout_freed else "○", "●" if armory_burned else "○"]


## 묶인 정찰병을 풀면 부하가 되어 바로 따라온다.
func _free_scout(_by) -> void:
	if scout_freed:
		return
	scout_freed = true
	var at := scout.global_position
	scout.queue_free()
	Game.side_markers.erase(at)
	_add_scout(at)
	Sfx.play("ui")
	Game.say([["테르산드로스", "장군! 살았습니다. 이 칼로 은혜를 갚겠습니다."]])
	_refresh_side()


func _add_scout(at: Vector2) -> void:
	var c := Companion.new()
	c.setup("sword", "테르산드로스")
	c.position = at
	world.add_child(c)
	squad.add_member(c)
	c.face(player.global_position - at)
	if not Game.checkpoint.is_empty():
		Game.checkpoint["scout"] = true
		Game.save_progress()


## 무기고에 불을 지르면 불빛이 퍼지고 타는 소리에 가까운 적이 의심한다(quiet: 체크포인트에서 되살릴 때).
func _burn_armory(quiet := false) -> void:
	if armory_burned:
		return
	armory_burned = true
	armory_point.enabled = false
	Game.side_markers.erase(armory_point.global_position)
	if not Game.checkpoint.is_empty():
		Game.checkpoint["armory"] = true
		Game.save_progress()
	for i in armory_sprites.size():
		var sp: Sprite2D = armory_sprites[i]
		add_fire(sp, Vector2(randf_range(-3, 3), -10), 0.7 + 0.15 * i, i == 1)
	add_smoke(armory_sprites[1], Vector2(0, -40), 1.0)
	if quiet:
		return
	Sfx.play("cry", -14.0)
	noise(armory_point.global_position, 130.0, 0.6)
	Fx.text(armory_point.global_position + Vector2(0, -40), "무기고가 탄다", Color(1, 0.7, 0.3))
	Game.show_hint("무기고가 탄다 — 마지막 반격에 궁수가 오지 못한다. 불빛에 들키지 않게 물러나라")
	_refresh_side()


func _refresh_side() -> void:
	if step == 1:
		Game.set_objective(chapter_title, "들키지 않고 성문 앞 북쪽 가로까지 가서 횃불로 신호를 보내라" + _side_text())


## 성문을 열거나 닫는다(통과 가능 여부·그림·소리).
func _set_gate(open: bool) -> void:
	gate_open = open
	Sfx.play("gate", -2.0)
	Game.shake(6.0 if open else 4.0)
	var pname := "gate_open" if open else "gate_closed"
	var meta: Dictionary = AssetLibrary.prop(pname)
	for i in GATE_CELLS.size():
		set_solid(GATE_CELLS[i], not open)
		var sp: Sprite2D = gate_sprites[i]
		sp.texture = AssetLibrary.prop_texture(pname)
		sp.offset = -Vector2(meta["anchor"][0], meta["anchor"][1])


## 닫힌 성문: 오디세우스가 권양기를 누르고 있으면 올라가고, 놓으면 천천히 내려간다.
func _update_winch(delta: float) -> void:
	var need := REOPEN_TIME if opened_once else WINCH_TIME
	if player.state == Actor.St.INTERACT and player.interact_target == winch_point:
		winch_progress = minf(1.0, winch_progress + delta / need)
	else:
		winch_progress = maxf(0.0, winch_progress - delta * WINCH_DROP)
	winch_point.progress = winch_progress
	if not opened_once and _winch_attacks < 2 and winch_progress >= [0.15, 0.55][_winch_attacks]:
		_send_winch_attack(_winch_attacks)
		_winch_attacks += 1
	if winch_progress >= 1.0:
		winch_progress = 0.0
		winch_point.enabled = false
		if opened_once:
			_set_gate(true)
			Game.show_hint("성문을 다시 열었다!")
		else:
			_open_gate()
		return
	if step == 3:
		Game.set_objective(chapter_title, "권양기를 돌려 성문을 열어라  [E 누르고 있기]  %d%%\n손을 떼면 성문이 다시 내려간다" % int(winch_progress * 100.0) + _side_text())


## 권양기 소리를 듣고 몰려오는 트로이군 (처음 열 때 두 번)
func _send_winch_attack(i: int) -> void:
	var groups := [
		[["trojan_sword", Vector2(30.0, 11.0)], ["trojan_spear", Vector2(31.0, 11.5)], ["trojan_sword", Vector2(29.0, 10.5)]],
		[["trojan_sword", Vector2(6.0, 11.0)], ["trojan_spear", Vector2(7.0, 11.5)], ["trojan_sword", Vector2(18.5, 15.0)], ["trojan_archer", Vector2(18.0, 16.0)]],
	]
	Game.show_hint(["권양기 소리에 트로이군이 몰려온다! 부하를 곁에 세워 막게 하라",
		"또 몰려온다 — 궁수도 있다! 손을 떼고 쏘거나 3(집중 공격)으로 부하를 보내라"][i])
	for g in groups[i]:
		var e := _spawn(g[0], g[1])
		e.raises_alarm = false
		e.alert(player)


## 트로이 돌격병이 권양기를 돌린다(Enemy._run_crank가 부름). 다 돌리면 성문이 닫힌다.
func crank_gate(delta: float) -> void:
	if not gate_open or step != 4 or _done or _crank_frame == Engine.get_physics_frames():
		return   # 여럿이 붙어도 한 프레임에 한 번만 — 닫히는 데 늘 CLOSE_TIME
	_crank_frame = Engine.get_physics_frames()
	_cranked = true
	close_progress = minf(1.0, close_progress + delta / CLOSE_TIME)
	if close_progress >= 1.0:
		close_progress = 0.0
		_set_gate(false)
		winch_progress = 0.0
		winch_point.enabled = true
		Game.show_hint("성문이 닫혔다! 권양기를 다시 돌려라 (%d초)" % int(REOPEN_TIME))
		for e in enemies():
			if e.phase == "crank":
				e.crank_pos = Vector2.INF
				e._set_phase("chase")
				e.target = player


## 아게노르 2페이즈: 뿔나팔 소리에 북쪽 가로 양쪽에서 검병 둘이 뛰어온다(경비대 수에 더함).
func on_boss_horn(_boss: Enemy) -> void:
	for g in [Vector2(11.0, 10.5), Vector2(25.5, 10.5)]:
		var e := _spawn("trojan_sword", g)
		e.raises_alarm = false
		e.alert(player)
		if step == 2:
			guard_group.append(e)
	var who: String = _boss.display_name.get_slice(" ", _boss.display_name.count(" "))
	Game.show_hint("%s가 뿔나팔로 검병을 불렀다! 방패 돌진(붉은 길)은 옆으로 피하라 — 벽에 박히면 2초 무방비" % who)


func _on_alarm(_bell: Dictionary) -> void:
	if step > 2:
		return
	for a in ALARM_GUARDS:
		var e := _spawn(a[0], a[1])
		e.vision = 130.0
		e.raises_alarm = false
		guard_group.append(e)
	Game.show_hint("경보가 울렸다! 성문 경비가 2명 늘었다")


func _process(delta: float) -> void:
	super._process(delta)
	if _done:
		return
	_update_tutorial(delta)
	_watch_firsts()
	match step:
		0:
			_update_drill()
		2:
			if not _boss_hint and is_instance_valid(captain) and captain.alerted:
				_boss_hint = true
				_tut_urgent("아게노르 — 3연타 뒤 크게 붉게 깜빡이면 내려찍기\n그 순간 K/우클릭으로 패링하면 2초 동안 무방비",
					func(): return not is_instance_valid(captain) or not captain.is_alive(), 3, 18.0)
			var n := _dead_count(guard_group)
			Game.set_objective(chapter_title, "성문 앞 광장의 경비대를 처치하라  (%d/%d)" % [n, guard_group.size()] + _side_text())
			if n >= guard_group.size():
				_set_step(3)
		3:
			if not gate_open:
				_update_winch(delta)
		4:
			_update_army(delta)
			if gate_open:
				if not _cranked:
					close_progress = maxf(0.0, close_progress - delta * 0.3)
				_cranked = false
			else:
				_update_winch(delta)
			_update_capture(delta)
	queue_redraw()


func _dead_count(group: Array) -> int:
	var n := 0
	for e in group:
		if not is_instance_valid(e) or not e.is_alive():
			n += 1
	return n


func _open_gate() -> void:
	winch_point.enabled = false
	opened_once = true
	_set_gate(true)
	# 성문 바로 안을 지키는 선봉 넷(거점 둘레) + 뒤이어 줄지어 들어오는 대군
	var allies := [["sword", "아카이아 검병"], ["spear", "아카이아 창병"], ["sword", "아카이아 검병"], ["spear", "아카이아 창병"]]
	for i in allies.size():
		var c := _add_soldier(allies[i][0], allies[i][1], Iso.grid_to_world(Vector2(17.2 + (i % 2) * 1.2, 0.6 + (i / 2) * 1.0)))
		c.hold_anchor = zone_pos + Vector2(-30 + i * 20, 10 + (i % 2) * 8)
	_army_left = ARMY_SIZE
	_army_timer = 1.5
	# 성이 이미 뚫렸으니 남은 보초도 더는 경보 종을 치지 않는다(클리어 기록의 경보 수는 잠입 결과만 센다)
	for e in enemies():
		e.raises_alarm = false
	_ignite_city()
	Sfx.play("cry", -2.0)
	Game.shake(9.0)
	if Game.hud:
		Game.hud.show_title(["트로이 함락의 밤", "아카이아 대군 입성", "대군이 다 들어올 때까지 성문을 지켜라"])
	Game.say([
		["아카이아 병사", "성문이 열렸다! 이타카의 왕이 길을 열었다!"],
		["아가멤논의 전령", "전군, 진격하라! 트로이는 오늘 밤 무너진다!"],
		["오디세우스", "트로이 놈들이 전부 몰려올 것이다. 성문을 지켜라 — 우리 군이 다 들어올 때까지!"],
	], func(): _set_step(4))


func _add_soldier(role: String, who: String, at: Vector2) -> Companion:
	var c := Companion.new()
	c.setup(role, who)
	c.independent = true
	c.position = at
	world.add_child(c)
	return c


## 대군이 성문 밖에서 한 명씩 들어와 맡은 자리(북쪽 가로·세 갈래 입구)로 달려간다.
func _update_army(delta: float) -> void:
	if _army_left <= 0:
		return
	_army_timer -= delta
	if _army_timer > 0.0:
		return
	_army_timer = ARMY_INTERVAL
	_army_left -= 1
	var roles := ["sword", "spear", "sword", "archer"]
	var role: String = roles[_army_in % roles.size()]
	var at := Iso.grid_to_world(Vector2(17.3 + randf() * 1.4, 0.4 + randf() * 1.2))
	var c := _add_soldier(role, "아카이아 " + Companion.ROLE_NAMES[role], at)
	var post: Vector2 = ARMY_POSTS[_army_in % ARMY_POSTS.size()]
	c.hold_anchor = Iso.grid_to_world(post + Vector2(randf_range(-0.6, 0.6), randf_range(-0.6, 0.6)))
	_army_in += 1
	if _army_in == 1:
		Fx.text(at + Vector2(0, -50), "아카이아 대군!", Color(0.6, 0.85, 1.0))
	if _army_left == 0:
		Game.show_hint("아카이아 대군 %d명이 성 안에 들어왔다! 트로이군을 막아라" % (ARMY_SIZE + 4))


## 성문이 열리면 불이 도시로 번진다(정해 둔 집에 차례로 불).
func _ignite_city() -> void:
	for k in _houses.size():
		var h: Array = _houses[k]
		get_tree().create_timer(0.6 + k * 0.7).timeout.connect(func(): ignite_house(h[0], h[1]))
	_houses.clear()


func _update_capture(delta: float) -> void:
	var p_in := player.is_alive() and Combat.ground_dist(player.global_position, zone_pos) < ZONE_RADIUS
	var contested := false
	for e in enemies():
		if Combat.ground_dist(e.global_position, zone_pos) < ZONE_RADIUS:
			contested = true
			break
	var calm := not enemies().any(func(e): return e.alerted)
	var cap_max := 100.0
	if waves_sent >= 4 and is_instance_valid(prince) and prince.is_alive():
		cap_max = PRINCE_CAP
	if p_in and not contested and gate_open:
		capture = minf(cap_max, capture + delta * (CAPTURE_CALM if calm else CAPTURE_RATE))
	_update_tide(delta)
	var wave_at := [0.0, 22.0, 45.0, 70.0]
	if waves_sent < wave_at.size() and capture >= wave_at[waves_sent]:
		_send_wave(waves_sent)
		waves_sent += 1
	var status := "" if p_in else "  — 원 안으로 들어가라"
	if contested:
		status = "  — 적이 거점에 있다!"
	if capture >= PRINCE_CAP - 0.01 and cap_max < 100.0:
		status = "\n왕자 데이포보스를 쓰러뜨려라!"
	if not gate_open:
		status = "\n성문이 닫혔다! 권양기를 다시 돌려라  %d%%" % int(winch_progress * 100.0)
	elif close_progress > 0.0:
		status += "\n트로이군이 권양기를 돌린다! 성문이 닫힌다  %d%%" % int(close_progress * 100.0)
	Game.set_objective(chapter_title, "성문 거점을 사수하라  (%d%%)%s" % [int(capture), status])
	if waves_sent >= 4 and is_instance_valid(prince) and not prince.is_alive() and not _routed:
		_routed = true
		_rout()
	if capture >= 100.0:
		_finish()


## 반격 4파: [종류, 칸, 역할("wall" 방패벽 · "perch" 높은 곳 궁수 · "crank" 권양기 돌격 · "prince" 총대장 · "" 보통)]
## 세 갈래(뒷골목 x4.5 · 대로 x18.5 · 시장 x30)에서 한꺼번에 몰려온다. 마지막 파는 왕자 데이포보스가 이끄는 총공세.
func _send_wave(i: int) -> void:
	var waves := []
	var w0 := []
	for row in 2:
		for col in 4:
			w0.append([["trojan_spear", "trojan_sword"][(col + row) % 2], Vector2(16.5 + col, 17.0 + row), "wall"])
	w0 += _route_squad(["trojan_sword", "trojan_spear"], 20.0, [4.5, 30.0])
	waves.append(w0)
	var w1 := [["trojan_archer", Vector2(PERCH_CELLS[0]) + Vector2(0.5, 0.5), "perch"], ["trojan_archer", Vector2(PERCH_CELLS[1]) + Vector2(0.5, 0.5), "perch"]]
	w1 += _route_squad(["trojan_sword", "trojan_sword", "trojan_archer"], 18.0)
	waves.append(w1)
	var w2 := [["trojan_sword", Vector2(7.0, 11.0), "crank"], ["trojan_sword", Vector2(29.5, 11.0), "crank"], ["trojan_sword", Vector2(18.5, 15.0), "crank"]]
	w2 += _route_squad(["trojan_spear", "trojan_sword", "trojan_spear", "trojan_archer"], 18.0)
	waves.append(w2)
	var w3 := [["trojan_prince", Vector2(18.5, 19.0), "prince"]]
	w3 += _route_squad(["trojan_sword", "trojan_spear", "trojan_sword", "trojan_archer"], 21.0)
	waves.append(w3)
	var hints := [
		"반격 1/4 — 트로이군이 세 갈래로 몰려온다! 대로엔 방패벽: F 강공격으로 부수고, 몰린 곳엔 5 일제 사격",
		"반격 2/4 — 짐더미 위의 궁수! Q 활로 쏘거나 5(부대 특수 명령) 방패벽으로 화살을 막아라",
		"반격 3/4 — 트로이군이 권양기로 달려간다! 돌리면 성문이 닫힌다 — 막아라",
		"반격 4/4 — 트로이 왕자 데이포보스의 총공세! 왕자를 쓰러뜨리면 트로이군이 무너진다",
	]
	Game.show_hint(hints[i] + ("  (무기고가 타서 궁수가 줄었다)" if armory_burned and i >= 2 else ""))
	# 반격 사이 숨 돌리기: 대군의 함성에 오디세우스가 기운을 차린다(체력 회복·함성 다시 쓸 수 있음)
	if i > 0 and player.is_alive():
		player.heal(WAVE_HEAL)
		player.skill_cd = 0.0
		Fx.text(player.global_position + Vector2(0, -70), "대군의 함성 — 기운이 솟는다", Color(0.6, 1.0, 0.6))
	Sfx.play("cry", -6.0)
	Game.shake(4.0)
	_tide_left = TIDE_BUDGET[i]
	for w in waves[i]:
		if i >= 2 and w[0] == "trojan_archer" and armory_burned:
			continue
		var e := _spawn(w[0], w[1])
		e.hunts_player = true
		e.raises_alarm = false
		match w[2]:
			"wall":
				e.shield_wall = true
			"perch":
				e.perch = true
				e.body.position.y = -14.0
			"crank":
				e.start_crank(Iso.grid_to_world(WINCH_STAND))
				continue
			"prince":
				prince = e
		e.alert(player)
	if i == 3:
		_tut_seen["prince"] = true
		_tut_urgent("왕자 데이포보스 — 아게노르처럼 붉게 깜빡이면 패링(K/우클릭)\n쓰러뜨리면 남은 트로이군이 무너진다",
			func(): return not is_instance_valid(prince) or not prince.is_alive(), 3, 20.0)


## 세 갈래 길 입구마다 같은 무리를 하나씩: kinds를 y 줄에서 x로 조금씩 벌려 세운다.
func _route_squad(kinds: Array, y: float, xs := [4.5, 18.5, 30.0]) -> Array:
	var out := []
	for x in xs:
		for j in kinds.size():
			out.append([kinds[j], Vector2(x + (j % 2) * 1.0 - 0.5, y + j * 0.9), ""])
	return out


## 끝없이 몰려오는 트로이군: 반격이 시작되면 수가 줄 때마다 세 갈래 입구에서 무리를 더 보낸다(왕자가 쓰러지면 멈춤).
func _update_tide(delta: float) -> void:
	if waves_sent == 0 or _routed:
		return
	_tide_timer -= delta
	if _tide_timer > 0.0:
		return
	_tide_timer = TIDE_INTERVAL
	if _tide_left <= 0 or enemies().size() >= TIDE_MIN[waves_sent - 1]:
		return
	_tide_left -= 3
	var x: float = [4.5, 18.5, 30.0][randi() % 3]
	var kinds := ["trojan_sword", "trojan_spear", "trojan_sword"]
	for j in kinds.size():
		var e := _spawn(kinds[j], Vector2(x + (j % 2) - 0.5, 21.0 + j * 0.9))
		e.hunts_player = true
		e.raises_alarm = false
		e.alert(player)


## 왕자가 쓰러지면 남은 트로이군이 무너진다: 모두 휘청이며 크게 다치고, 거점 점령이 곧 끝난다.
func _rout() -> void:
	Game.show_hint("데이포보스가 쓰러졌다! 트로이군이 무너진다!")
	Fx.text(player.global_position + Vector2(0, -70), "트로이군 붕괴!", Color(1, 0.85, 0.35))
	Sfx.play("cry", -2.0)
	Game.shake(6.0)
	for e in enemies():
		e.take_hit(e.max_hp * 0.6, player, 40.0)
		e.stagger(1.5)
	capture = maxf(capture, 92.0)


func _finish() -> void:
	_done = true
	Game.quest_marker = Vector2.INF
	Game.side_markers = []
	Game.stats["scout"] = scout_freed
	Game.stats["armory"] = armory_burned
	for c in squad.members:
		c.revive(0.6)
	Game.set_objective(chapter_title, "성문 점령 완료 — 트로이 함락")
	if Game.hud:
		Game.hud.show_title(["CHAPTER 1 CLEAR", "트로이 함락", "십 년의 전쟁이 끝났다"])
	Game.say([
		["아카이아 병사", "트로이가 무너졌다! 오디세우스! 오디세우스!"],
		["오디세우스", "트로이의 성문은 우리 것이다. 십 년의 전쟁이 오늘 밤 끝난다."],
		["에우릴로코스", "장군, 이제… 이타카로 돌아가는 겁니까?"],
		["오디세우스", "그래. 배를 준비해라. 고향이 기다린다."],
	], _play_ending)


# ── 엔딩: 불타는 트로이를 뒤로 부두에서 배에 오른다 → 출항 → 챕터 2 예고 ──────────
## E / Space / 클릭으로 건너뛴다(대화 중에는 대화를 넘김). 끝나면 결과 화면(chapter_cleared).
func _play_ending() -> void:
	_ending = true
	Game.cutscene = true
	var hud: Hud = Game.hud
	if hud:
		hud.cinematic = true
		hud.fade_to(1.0, 0.8)
	await _wait(0.9)
	# 검은 화면 뒤에서: 남은 트로이군을 치우고, 오디세우스와 부하를 바다 문 밖 성벽 길로 옮긴다
	for e in enemies():
		e.queue_free()
	if is_instance_valid(scout) and not scout_freed:
		scout.queue_free()   # 풀어 주지 못한 정찰병은 대군이 구했다
	player.position = Iso.grid_to_world(Vector2(36.5, 35.2))
	player.face(_gdir(Vector2(-1, -1)))
	for i in squad.members.size():
		var c: Companion = squad.members[i]
		c.position = Iso.grid_to_world(Vector2(36.5, 33.4 - i * 0.6))
		c.face(_gdir(Vector2(0, 1)))
	squad.set_mode(Squad.Mode.FOLLOW)
	occluders.erase(_galley)
	# 부두에서 보이는 동쪽 집들에도 불이 번진다
	for k in mini(_late_houses.size(), 8):
		var h: Array = _late_houses[_late_houses.size() - 1 - k]
		get_tree().create_timer(0.2 + k * 0.5).timeout.connect(func(): ignite_house(h[0], h[1]))
	_late_houses.clear()
	if hud:
		hud.fade_to(0.0, 1.2)
	await _wait(1.6)
	await _say_wait([
		["에우릴로코스", "배는 준비됐습니다, 장군. 열두 척 모두 이타카의 깃발을 달았습니다."],
		["오디세우스", "십 년이다… 저 불길을 잘 봐 두어라. 우리가 무엇을 하고 이 땅을 떠나는지."],
		["폴리테스", "이제 집으로 가는 겁니다. 바람만 좋으면 열흘이면 닿겠지요."],
	])
	# 부두를 따라 배까지 걷는다(부하는 따라온다)
	for goal in [Vector2(36.5, 38.6), Vector2(39.6, 38.7)]:
		player.script_goal = Iso.grid_to_world(goal)
		var t := 0.0
		while not _skip and t < 6.0 and player.global_position.distance_to(player.script_goal) > 8.0:
			await get_tree().process_frame
			if not get_tree().paused:
				t += get_process_delta_time()
	player.script_goal = Vector2.INF
	# 배에 오른다
	var board := create_tween().set_parallel(true)
	for a in [player] + squad.members:
		board.tween_property(a, "modulate:a", 0.0, 0.6)
	await _wait(0.8)
	player.visible = false
	for c in squad.members:
		c.visible = false
	# 출항: 갤리선이 바다로 나아가고 카메라가 따라간다
	camera_target = _galley
	var sail := create_tween().set_parallel(true)
	var off := Iso.grid_to_world(Vector2(7, -3)) - Iso.grid_to_world(Vector2.ZERO)
	sail.tween_property(_galley, "position", _galley.position + off, 11.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	sail.tween_property(_galley_light, "position", _galley_light.position + off, 11.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	sail.tween_property(_galley, "modulate:a", 0.0, 2.5).set_delay(9.5)
	Sfx.play("cry", -12.0)
	for line in ["트로이는 하룻밤 사이에 불타 무너졌다.",
			"오디세우스와 부하들은 이타카로 뱃머리를 돌렸다.",
			"그러나 바다의 신 포세이돈은 그들을 쉽게 보내 주지 않았다…"]:
		if hud:
			hud.caption(line, 3.4)
		await _wait(3.6)
	if hud:
		hud.fade_to(1.0, 1.0)
	await _wait(1.2)
	if hud and not _skip:
		hud.show_title(["CHAPTER 2", "귀환의 시작", "배를 몰아 이타카로 — 준비 중"])
		await _wait(4.2)
	_end_ending()


func _end_ending() -> void:
	if ending_done:
		return
	ending_done = true
	sail_stop()
	Game.mark_cleared(1)
	Game.cutscene = false
	if Game.hud:
		Game.hud.cinematic = false
		Game.hud.fade_to(0.0, 0.01)
		Game.hud.title_time = 0.0
	Game.chapter_cleared.emit(Game.stats.duplicate())


## 건너뛰면 남은 움직임은 멈춘다(결과 화면 뒤에서 계속 돌지 않게)
func sail_stop() -> void:
	for t in get_tree().get_processed_tweens():
		t.kill()


## t초 기다림(건너뛰면 바로 끝)
func _wait(t: float) -> void:
	while t > 0.0 and not _skip:
		await get_tree().create_timer(0.1, false).timeout   # 일시정지 중에는 멈춘다
		t -= 0.1


func _say_wait(lines: Array) -> void:
	if _skip:
		return
	var done := [false]
	Game.say(lines, func(): done[0] = true)
	while not done[0]:
		await get_tree().process_frame


func _unhandled_input(event: InputEvent) -> void:
	if not _ending or _skip or (Game.hud and Game.hud.dialogue.size() > 0):
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("dodge") or event.is_action_pressed("attack"):
		_skip = true
		get_viewport().set_input_as_handled()


func _draw() -> void:
	if _done:
		return
	# 권양기 둘레: 파랑 = 여는 정도, 빨강 = 트로이군이 닫는 정도
	if step >= 3:
		var wp := winch_point.global_position
		if not gate_open:
			_draw_ring(wp, 16.0, 1.0, Color(0, 0, 0, 0.5), 3.0)
			_draw_ring(wp, 16.0, winch_progress, Color(0.45, 0.75, 1.0, 0.95), 2.0)
		elif close_progress > 0.0:
			_draw_ring(wp, 16.0, 1.0, Color(0, 0, 0, 0.5), 3.0)
			_draw_ring(wp, 16.0, close_progress, Color(1.0, 0.3, 0.2, 0.95), 2.0)
	if step != 4:
		return
	var pts := PackedVector2Array()
	for i in 41:
		var a := TAU * i / 40.0
		pts.append(zone_pos + Vector2(cos(a) * ZONE_RADIUS, sin(a) * ZONE_RADIUS / Combat.Y_STRETCH))
	var c := Color(1, 0.3, 0.2, 0.75)
	draw_polyline(pts, c, 1.5)
	var fill_pts := PackedVector2Array()
	var k := capture / 100.0
	for i in 41:
		var a := TAU * i / 40.0
		fill_pts.append(zone_pos + Vector2(cos(a) * ZONE_RADIUS * k, sin(a) * ZONE_RADIUS * k / Combat.Y_STRETCH))
	if k > 0.02:
		draw_colored_polygon(fill_pts, Color(0.4, 0.6, 1.0, 0.18))


## 땅 위 타원 고리의 frac만큼(12시부터 시계 방향)
func _draw_ring(o: Vector2, r: float, frac: float, col: Color, width: float) -> void:
	if frac <= 0.0:
		return
	var n := maxi(2, int(40 * frac))
	var pts := PackedVector2Array()
	for i in n + 1:
		var a := -PI / 2.0 + TAU * frac * i / n
		pts.append(o + Vector2(cos(a) * r, sin(a) * r / Combat.Y_STRETCH))
	draw_polyline(pts, col, width)
