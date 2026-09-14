extends Node

enum AgeStageType {CHILD,TEEN,ADULT}
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
## 出生日期
var birth_year:int=1430
var birth_month:int=4
var birth_day:int=1

# 生病了吗
var is_ill:bool = false

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
