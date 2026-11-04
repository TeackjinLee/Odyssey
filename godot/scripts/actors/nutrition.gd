class_name Nutrition
extends RefCounted
## 영양(docs/NUTRITION.md): 탄수화물 = 체력 회복, 단백질 = 힘(공격력), 지방 = 둘이 먼저 떨어지지 않게 대신 태우는 완충
## (대신 60을 넘으면 느려짐). 탄·단이 100을 넘게 먹으면 넘친 몫이 지방이 된다. 값은 모두 0~100.
## 음식 표는 data/food.json (Nutrition.food(id)).

const START := {"carb": 70.0, "protein": 65.0, "fat": 35.0}
## 초당 줄어드는 양: 늘 · 달리는 동안 더 · 싸우는 동안 더
const CARB_BASE := 0.10
const CARB_RUN := 0.18
const CARB_FIGHT := 0.10
## 스태미나 1을 쓸 때 줄어드는 탄수화물
const CARB_PER_STAMINA := 0.03
const PROTEIN_BASE := 0.06
## 한 번 할 때 줄어드는 단백질
const PROTEIN_SWING := 0.12
const PROTEIN_HEAVY := 0.25
const PROTEIN_SHOT := 0.1
## 지방이 대신 내는 몫(그 영양이 LOW 아래면 더 많이), 지방은 낸 몫 × FAT_COST만큼 준다(열량이 높아서)
const FAT_SHARE := 0.35
const FAT_SHARE_LOW := 0.75
const LOW := 30.0
const FAT_COST := 0.5
## 100을 넘게 먹은 탄·단 중 지방이 되는 비율
const OVERFLOW_TO_FAT := 0.6
## 효과 경계
const CARB_FULL := 70.0          # 이 위면 회복이 빨라짐
const PROTEIN_OK := 40.0         # 이 아래면 공격력이 줄고, 위면 오름
const FAT_HEAVY := 60.0          # 이 위면 느려짐
const STARVE_HP := 0.6           # 굶주림(탄 0): 초당 잃는 체력
const STARVE_FLOOR := 0.3        # 굶주림으로는 최대 체력의 이만큼 아래로 안 내려감

var carb := 70.0
var protein := 65.0
var fat := 35.0

static var _foods := {}


static func food(id: String) -> Dictionary:
	if _foods.is_empty():
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/food.json"))
		_foods = d if d is Dictionary else {}
	return _foods.get(id, {})


func load_state(d: Dictionary) -> void:
	carb = float(d.get("carb", START["carb"]))
	protein = float(d.get("protein", START["protein"]))
	fat = float(d.get("fat", START["fat"]))


func state() -> Dictionary:
	return {"carb": snappedf(carb, 0.1), "protein": snappedf(protein, 0.1), "fat": snappedf(fat, 0.1)}


## 탄수화물·단백질을 amount만큼 쓴다. 지방이 있으면 그 일부를 대신 낸다.
func spend(kind: String, amount: float) -> void:
	if amount <= 0.0:
		return
	var cur: float = carb if kind == "carb" else protein
	var paid := 0.0
	if fat > 0.0:
		paid = amount * (FAT_SHARE_LOW if cur < LOW else FAT_SHARE)
		var fat_use := minf(fat, paid * FAT_COST)
		paid = fat_use / FAT_COST
		fat -= fat_use
	cur = maxf(0.0, cur - (amount - paid))
	if kind == "carb":
		carb = cur
	else:
		protein = cur


## 시간에 따라 줄어듦. running·fighting은 플레이어가 알려 준다.
func tick(delta: float, running: bool, fighting: bool) -> void:
	spend("carb", (CARB_BASE + (CARB_RUN if running else 0.0) + (CARB_FIGHT if fighting else 0.0)) * delta)
	spend("protein", PROTEIN_BASE * delta)


## 먹기: 오른 양을 돌려준다 {"carb", "protein", "fat", "to_fat"(넘쳐서 지방이 된 몫)}
func eat(f: Dictionary) -> Dictionary:
	var add_c := float(f.get("carb", 0))
	var add_p := float(f.get("protein", 0))
	var add_f := float(f.get("fat", 0))
	var over := maxf(0.0, carb + add_c - 100.0) + maxf(0.0, protein + add_p - 100.0)
	carb = minf(100.0, carb + add_c)
	protein = minf(100.0, protein + add_p)
	var to_fat := over * OVERFLOW_TO_FAT
	fat = minf(100.0, fat + add_f + to_fat)
	return {"carb": add_c, "protein": add_p, "fat": add_f, "to_fat": to_fat}


## 체력 회복 배율(탄수화물): 0 → 0, LOW → 1, CARB_FULL 넘으면 100에서 1.4
func regen_mult() -> float:
	if carb < LOW:
		return carb / LOW
	if carb > CARB_FULL:
		return 1.0 + 0.4 * (carb - CARB_FULL) / (100.0 - CARB_FULL)
	return 1.0


func starving() -> bool:
	return carb <= 0.0


## 공격력 배율(단백질): 0 → 0.75, PROTEIN_OK → 1, 100 → 1.15
func power_mult() -> float:
	if protein < PROTEIN_OK:
		return 0.75 + 0.25 * protein / PROTEIN_OK
	return 1.0 + 0.15 * (protein - PROTEIN_OK) / (100.0 - PROTEIN_OK)


## 속도 배율(지방): FAT_HEAVY까지 1, 100에서 0.75
func speed_mult() -> float:
	if fat <= FAT_HEAVY:
		return 1.0
	return 1.0 - 0.25 * (fat - FAT_HEAVY) / (100.0 - FAT_HEAVY)


## 지금 걸린 효과 이름들(HUD 표시용)
func effects() -> Array:
	var out := []
	if starving():
		out.append("굶주림")
	elif carb < LOW:
		out.append("배고픔")
	if protein < PROTEIN_OK:
		out.append("힘 빠짐")
	if fat > FAT_HEAVY:
		out.append("무거움")
	return out
