extends Node

const FINAL_YEAR := 1448
const FINAL_MONTH := 3
const ENDING_SCENE := "res://sences/ending.tscn"
const HARVEST_SCENE := "res://sences/harvest.tscn"
const HARVEST_MONTH := 9
const VACATION_COST := 100
const COURSE_LEVEL_NAMES := ["初级", "中级", "高级", "专家"]
const COURSE_PROMOTION_COUNTS := [4, 12, 24]

var week_list = ["周日","周一","周二","周三","周四","周五","周六"]
var health_tactics = ["顺其自然","活泼取向","娴静取向","进行减肥"]

# 当前年月日
var year:int = 1440
var month:int = 4
var day:int = 1
var week_index = 3

# 父亲姓名（新游戏命名时可修改）
var father_name: String = "海威尔"

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
	"baora": 0,
	"karen": 0,
	"jeep": 0,
	"father": 0,
	"chris": 0
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
var completed_vacation_months: Dictionary = {}

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

func IsHarvestMonth() -> bool:
	return month == HARVEST_MONTH and year < FINAL_YEAR

func GetPlanEndDay(index: int) -> int:
	return get_current_month_end_day() if index == 2 else (index + 1) * 10

func GetPlanExpense(action: String, start_day: int, end_day: int) -> int:
	if action == "vacation":
		return VACATION_COST
	if action == "recover":
		return 0
	var level := "level%d" % category_stage[action][0]
	var activity: Dictionary = Globaljson.category_data[action][level]
	if activity["type"] != "LESSON" or activity["money"] >= 0:
		return 0
	var class_days := 0
	for date_day in range(start_day, end_day + 1):
		if get_weekday(year, month, date_day) != 0:
			class_days += 1
	return class_days * -int(activity["money"])

func GetDailyWage(action: String) -> int:
	var activity: Dictionary = Globaljson.category_data[action]["level0"]
	var completed_terms: int = category_stage[action][1]
	var raises := mini(3, floori(completed_terms / 5.0))
	var story_raise: int = activity["money_growth"] if action == "casino" and flags.get("work_casino_master", false) else 0
	return int(activity["money"] + activity["money_growth"] * raises) + story_raise

func GetWinterVacationKey(calendar_year: int, calendar_month: int) -> String:
	var winter_start_year := calendar_year - 1 if calendar_month < 3 else calendar_year
	return "winter_%d" % winter_start_year

func GetStoryDialogue(event: Dictionary) -> Array:
	var dialogue: Array = event.get("dialogue_script", [])
	var crime: float = Daughterstatus.attributes["crime"]
	var morals: float = Daughterstatus.attributes["morals"]
	if crime >= 100 and crime > morals and event.has("rebellious_dialogue"):
		return event["rebellious_dialogue"] + dialogue
	return dialogue

func UpdateCourseRank(action: String) -> void:
	var progress: Array = category_stage[action]
	var levels: Dictionary = Globaljson.category_data.get(action, {})
	var base_level: Dictionary = levels.get("level0", {})
	if progress[0] < 0 or base_level.get("type") != "LESSON":
		return
	for index in range(COURSE_PROMOTION_COUNTS.size()):
		var rank := index + 1
		if progress[1] >= COURSE_PROMOTION_COUNTS[index] and levels.has("level%d" % rank):
			progress[0] = maxi(progress[0], rank)
	if action == "art":
		art_painting_level = maxi(art_painting_level, progress[0])

func sync_calendar() -> void:
	sync_week_index()
	var previous_stage := Daughterstatus.age_stage
	Daughterstatus.sync_age(year, month, day)
	if previous_stage != Daughterstatus.age_stage:
		Clothing.EnsureAgeCompatibleOutfit()
		UpdateGrowthRates()

func UpdateGrowthRates() -> void:
	var stage: String = Daughterstatus.age_stage_names[Daughterstatus.age_stage]
	growth_rates = Globaljson.health_growth[stage][health_tactics[health_index]].duplicate(true)

func ApplyMonthlyGrowth() -> void:
	var rates: Dictionary = growth_rates["monthly"]
	for part in Daughterstatus.body_stats:
		var growth_key: String = "hip" if part == "hips" else part
		Daughterstatus.body_stats[part] = maxf(1.0, Daughterstatus.body_stats[part] + rates.get(growth_key, 0))
	Daughterstatus.AddAttribute("stamina", rates.get("stamina", 0))

func advance_day() -> void:
	day += 1
	if day > get_current_month_end_day():
		day = 1
		month += 1
		if month > 12:
			month = 1
			year += 1
	sync_calendar()

func passed_training_deadline() -> bool:
	return year * 100 + month > FINAL_YEAR * 100 + FINAL_MONTH

func finish_training_month() -> void:
	if SceneTransition.is_transitioning or day != get_current_month_end_day():
		return
	ApplyMonthlyGrowth()
	Inventory.ApplyMonthlyItemEffects()
	Daughterstatus.CheckOverwork()
	already_talk = false
	schedule_plan_index = 0
	if year * 100 + month >= FINAL_YEAR * 100 + FINAL_MONTH:
		SceneTransition.ChangeScene(ENDING_SCENE)
		return
	advance_day()
	month_end_day = get_current_month_end_day()
	get_tree().change_scene_to_file("res://sences/main.tscn")

func MeetsHomeEventConditions(cond: Dictionary) -> bool:
	for flag in cond.get("flags_required", []):
		if not flags.get(flag, false):
			return false
	for flag in cond.get("flags_banned", []):
		if flags.get(flag, false):
			return false
	if year < cond.get("min_year", year) or year > cond.get("max_year", year):
		return false
	if month < cond.get("min_month", month) or month > cond.get("max_month", month):
		return false
	if day < cond.get("min_day", day) or day > cond.get("max_day", day):
		return false
	var current_month := year * 100 + month
	if current_month < cond.get("min_year_month", current_month) or current_month > cond.get("max_year_month", current_month):
		return false
	if cond.get("is_birth_month", false) and month != Daughterstatus.birth_month:
		return false
	var vacation_months: Array = cond.get("vacation_months_any", [])
	if not vacation_months.is_empty() and not vacation_months.any(
		func(required_month): return completed_vacation_months.get(required_month, false)
	):
		return false
	var combined_affection: Dictionary = cond.get("combined_affection", {})
	if not combined_affection.is_empty():
		var total := 0.0
		for character in combined_affection["characters"]:
			total += affection.get(character, 0)
		if total <= combined_affection["above"]:
			return false
	for character in cond.get("min_affection", {}):
		if affection.get(character, 0) < cond["min_affection"][character]:
			return false
	for character in cond.get("max_affection", {}):
		if affection.get(character, 0) > cond["max_affection"][character]:
			return false
	for stat in cond.get("min_stats", {}):
		var value = Daughterstatus.attributes.get(stat, Daughterstatus.body_stats.get(stat))
		if value == null or value < cond["min_stats"][stat]:
			return false
	for stat in cond.get("max_stats", {}):
		var value = Daughterstatus.attributes.get(stat, Daughterstatus.body_stats.get(stat))
		if value != null and value > cond["max_stats"][stat]:
			return false
	for stat in cond.get("stats_below", {}):
		var value = Daughterstatus.attributes.get(stat, Daughterstatus.body_stats.get(stat))
		if value == null or value >= cond["stats_below"][stat]:
			return false
	return true
