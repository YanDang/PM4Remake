extends Node

var week_list = ["周日","周一","周二","周三","周四","周五","周六"]
var health_tactics = ["顺其自然","活泼取向","娴静取向","进行减肥"]

# 当前年月日
var year:int = 1440
var month:int = 4
var day:int = 1
var week_index = 3

# 所持金
var money:int = clamp(2000,-5000,9999999)
# 健康策略
var health_index:int = 0

# 这个月对话了吗
var already_talk:bool = false

# 月度增长（monthly growth）
# 年度增长（annual growth）
var growth_rates = {
	"monthly": {
		"height": 0.39,
		"weight": 0.26,
		"bust": 0.3,
		"waist": 0.15,
		"hip": 0.33,
		"stamina": 0
	},
	"annual": {
		"height": 4.68,
		"weight": 3.12,
		"bust": 3.6,
		"waist": 1.8,
		"hip": 3.96,
		"stamina": 0
	}
}

# [阶段，次数]
var category_stage = { 
	"theory": [0, 0], 
	"martialArts": [0, 0],
	"magic": [0, 0],
	"etiquette": [-1, 0],
	"art": [0, 0],
	"dance": [-1, 0],
	"housework": [0, 0],
	"nanny": [0, 0],
	"farm": [0, 0], 
	"church": [0, 0], 
	"restaurant": [-1, 0], 
	"maid": [-1, 0], 
	"inn": [-1, 0], 
	"logging": [-1, 0], 
	"market": [-1, 0],
	"hotel": [-1, 0],
	"tutor": [-1, 0],
	"maidHotel": [-1, 0],
	"strangeHotel": [-1, 0],
	"casino": [-1, 0],
	"rest": [0, 0],
	"vacation": [0, 0],
	"outing": [0, 0],
	"recover": [-1, 0]
}
