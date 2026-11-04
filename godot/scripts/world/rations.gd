class_name Rations
extends RefCounted
## 배의 식량 창고와 부하의 배부름(docs/NUTRITION.md §7). 챕터 2부터.
## 창고: 빵·올리브·말린 고기를 "몫"으로 센다(부하 한 명이 하루 먹는 양 = 1몫).
## 하루: 배를 타고 DAY_LEN초가 지나면 하루. 부하마다 1몫씩 먹는다 — 먹은 사람 비율만큼 배부름이 차고, 못 먹은 비율만큼 준다.
## 배부름이 HUNGRY 아래면 부하의 체력 회복과 공격력(갑판 사격 포함)이 준다. 오디세우스는 자기 영양(Nutrition)을 따로 쓴다.

const DAY_LEN := 50.0
const FED_GAIN := 30.0
const MISS_LOSS := 40.0
const HUNGRY := 50.0
const START_STORE := 6
const STORE_MAX := 60

var store := START_STORE
var fullness := 100.0
var day := 0
var _day_t := 0.0


func load_state(d: Dictionary) -> void:
	store = int(d.get("rations", START_STORE))
	fullness = float(d.get("fullness", 100.0))


func state() -> Dictionary:
	return {"rations": store, "fullness": snappedf(fullness, 0.1)}


func add(n: int) -> int:
	var before := store
	store = mini(STORE_MAX, store + n)
	return store - before


## 음식 하나를 창고에 넣으면 몇 몫인지(data/food.json 값 합 / 20, 적어도 1)
static func units_of(f: Dictionary) -> int:
	return maxi(1, roundi((float(f.get("carb", 0)) + float(f.get("protein", 0)) + float(f.get("fat", 0))) / 20.0))


## 배 위에서 시간이 흐른다. 하루가 지나면 {"ate", "missed"}를, 아니면 빈 사전을 돌려준다
func tick_sea(delta: float, crew: int) -> Dictionary:
	_day_t += delta
	if _day_t < DAY_LEN:
		return {}
	_day_t -= DAY_LEN
	return pass_day(crew)


func pass_day(crew: int) -> Dictionary:
	day += 1
	if crew <= 0:
		return {"ate": 0, "missed": 0}
	var ate := mini(store, crew)
	store -= ate
	var missed := crew - ate
	fullness = clampf(fullness + FED_GAIN * ate / crew - MISS_LOSS * missed / crew, 0.0, 100.0)
	return {"ate": ate, "missed": missed}


## 이번 하루가 얼마나 지났는지 0~1 (HUD)
func day_progress() -> float:
	return _day_t / DAY_LEN


## 부하 체력 회복 배율: HUNGRY 위 1, 0에서 0
func crew_regen() -> float:
	return 1.0 if fullness >= HUNGRY else fullness / HUNGRY


## 부하 공격력 배율: HUNGRY 위 1, 0에서 0.7
func crew_power() -> float:
	return 1.0 if fullness >= HUNGRY else 0.7 + 0.3 * fullness / HUNGRY
