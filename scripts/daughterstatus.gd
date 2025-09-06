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
}

## 年龄
var age:int = 10
var age_stage:AgeStageType = AgeStageType.CHILD
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

## 信赖度
var trust:int = 0
## 魔化度
var demonization:int = 0
