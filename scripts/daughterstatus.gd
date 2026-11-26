extends Node

signal health_changed

enum AgeStageType {CHILD,TEEN,ADULT}
const HOSPITAL_TREATMENT := [
	{"character": "nakras", "text": "你需要先好好休息。我已经做了处理，回家后这几天别太累。"},
	{"character": "daughter", "emotion": "calm", "text": "感觉比刚才好多了。谢谢您。"}
]
@onready var age_stage_names = ["child","teen","adult"]

## 名字
var firstname:String="帕特莉希娅"
var secondname:String="海威尔"
## 体力
## 智力
## 魅力
## 自尊
## 道德
## 气质
## 感受
## 体贴
## 知名度
## 武术
## 魔法
## 罪孽
## 疲劳
## 信赖度
## 魔化度
var attributes = {
	"stamina": 50,
	"smarts": 25,
	"charm": 25,
	"pride": 25,
	"morals": 20,
	"highclass": 25,
	"sensitive": 25,
	"temper": 20,
	"fame": 0,
	"martial": 20,
	"magic": 20,
	"crime": 0,
	"stress": 0,
	"trust":0,
	"demonization":0
}

## 年龄
var age:int = 10
var age_stage:AgeStageType = AgeStageType.CHILD
## 当前衣服ID (用于立绘显示，如 01=便装)
var current_clothes_id:String = "01"
## 当前衣服名称 (用于服装保存与持久化)
var current_clothes_name:String = "常服"
# Actual worn-clothing contribution, separate from permanent character growth.
var clothing_bonus: Dictionary = {}
var equipped_gear := {"weapon": "", "armor": ""}
## 出生日期
var birth_year:int=1430
var birth_month:int=4
var birth_day:int=1

# 生病了吗
var is_ill:bool = false:
	set(value):
		if is_ill != value:
			is_ill = value
			health_changed.emit()

## 血型
var bloodtype:String="O"
## 身高
## 体重
## 胸围
## 腰围
## 臀围
var body_stats = {
	"height": 140,  # cm
	"weight": 38,   # kg
	"bust": 66.0,   # cm
	"waist": 55.0,  # cm
	"hips": 68.0,   # cm
}

func age_on(year: int, month: int, day: int, born_year: int, born_month: int, born_day: int) -> int:
	var anniversary_day := mini(born_day, Global.get_days_in_month(year, born_month))
	var years := year - born_year
	if month * 100 + day < born_month * 100 + anniversary_day:
		years -= 1
	return maxi(0, years)

func sync_age(year: int, month: int, day: int) -> void:
	age = age_on(year, month, day, birth_year, birth_month, birth_day)
	if age >= 16:
		age_stage = AgeStageType.ADULT
	elif age >= 13:
		age_stage = AgeStageType.TEEN
	else:
		age_stage = AgeStageType.CHILD

func CheckOverwork() -> void:
	if attributes["stress"] >= maxf(50.0, attributes["stamina"]):
		is_ill = true

func TryFinishHomeRecovery() -> void:
	if attributes["stress"] < maxf(50.0, attributes["stamina"]) * 0.5:
		is_ill = false

func FinishHospitalTreatment(_choice_index: int) -> void:
	if is_ill:
		is_ill = false
		attributes["stress"] = minf(attributes["stress"], maxf(50.0, attributes["stamina"]) * 0.5)

func PortraitEmotion(emotion: String) -> String:
	return "sick" if is_ill else emotion

func StandingPortraitPath(emotion_code: String) -> String:
	var age_code: String = ["c", "l", "h"][age_stage]
	return "res://assets/" + Globaljson.stand_sprite_data["daughter"].replace(
		"{emotion}", emotion_code
	).replace("{age}", age_code).replace("{cloth}", current_clothes_id)

# 修改单个属性并执行下限(默认0.0)与上限(默认999.0)检查，返回实际变化量
func AddAttribute(attr_name: String, delta: float, min_val: float = 0.0, max_val: float = 999.0) -> float:
	if attributes.has(attr_name):
		var old_val: float = float(attributes[attr_name])
		attributes[attr_name] = clampf(old_val + delta, min_val, max_val)
		return attributes[attr_name] - old_val
	return 0.0

# 批量应用属性字典（is_add=true 为购买/获得增加，is_add=false 为出售扣除）
func ApplyAttributeDict(attr_dict: Dictionary, is_add: bool = true, min_val: float = 0.0, max_val: float = 999.0) -> Dictionary:
	var actual_changes: Dictionary = {}
	for key in attr_dict.keys():
		if attributes.has(key):
			var delta: float = float(attr_dict[key]) if is_add else -float(attr_dict[key])
			actual_changes[key] = AddAttribute(key, delta, min_val, max_val)
	return actual_changes

# 检查并修正所有属性下限（保证不低于 min_val，且不超过 max_val）
func EnsureAttributesBounds(min_val: float = 0.0, max_val: float = 999.0) -> void:
	for key in attributes.keys():
		attributes[key] = clampf(float(attributes[key]), min_val, max_val)
