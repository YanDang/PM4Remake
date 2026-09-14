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

# 记录访问过的商店
var visited_shops: Dictionary = {}

# 事件标记
var flags: Dictionary = {}

# 角色好感度
var affection: Dictionary = {
	"lise": 0,
	"marie": 0,
	"christina": 0,
	"lee": 0,
	"charles": 0,
	"baora": 0
}

# 本月行动
var month_plan:Array
# 本月结束日期
var month_end_day:int
# 当前执行到第几个行动计划 (0, 1, 2)
var schedule_plan_index:int = 0
# 外出状态
var is_outing_mode:bool = false
var outing_actions_left:int = 3

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
	},
	"money":30
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

# 房间挂画等级 (0: 无挂画, 1: 中级郁金香, 2: 上级几何苹果, 3: 专业大师风景)
var art_painting_level: int = 0

# 记录各季度已触发过的度假剧情事件，键为 "年_季节索引" (例如 "1440_0")
var triggered_vacation_events: Dictionary = {}

# 获取当前季节索引: 0:春(3-5月), 1:夏(6-8月), 2:秋(9-11月), 3:冬(12,1,2月)
func get_current_season_index() -> int:
	match month:
		3, 4, 5:
			return 0
		6, 7, 8:
			return 1
		9, 10, 11:
			return 2
		12, 1, 2:
			return 3
		_:
			return 0

# 获取当前季节名称
func get_current_season_name() -> String:
	match get_current_season_index():
		0: return "春"
		1: return "夏"
		2: return "秋"
		3: return "冬"
		_: return "春"

# 获取房间主背景图片路径 (gd_000005.png ~ gd_000020.png)
func get_room_background_path() -> String:
	var season_idx = get_current_season_index()
	var painting_idx = clampi(art_painting_level, 0, 3)
	var bg_num = 5 + season_idx * 4 + painting_idx
	return "res://assets/Backgrounds/gd_%06d.png" % bg_num

# 根据年月日计算星期索引 (0: 周日, 1: 周一, ..., 6: 周六)
func get_weekday(y: int = year, m: int = month, d: int = day) -> int:
	var t = [0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4]
	var calc_y = y
	if m < 3:
		calc_y -= 1
	return (calc_y + int(calc_y / 4) - int(calc_y / 100) + int(calc_y / 400) + t[m - 1] + d) % 7

# 同步校准当前的 week_index
func sync_week_index() -> void:
	week_index = get_weekday(year, month, day)

# 计算指定年月的天数（支持闰年）
func get_days_in_month(y: int = year, m: int = month) -> int:
	var days_in_months = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
	var is_leap = (y % 4 == 0 and y % 100 != 0) or (y % 400 == 0)
	if m == 2 and is_leap:
		return 29
	else:
		return days_in_months[clampi(m - 1, 0, 11)]

# 获取当月最后一天的日期 (28/29/30/31)
func get_current_month_end_day() -> int:
	return get_days_in_month(year, month)
