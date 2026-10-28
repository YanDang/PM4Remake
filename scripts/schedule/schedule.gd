extends Node

@onready var ui: CanvasLayer = $UI
@onready var date: Sprite2D = $UI/Date
@onready var money: Sprite2D = $UI/Money
@onready var schd: Node2D = $UI/Schd
@onready var talk_layer: CanvasLayer = $TalkLayer
@onready var arrtibute: CanvasLayer = $Arrtibute
@onready var texture_rect: TextureRect = $TextureRect
@onready var vacation_ui: Node2D = $UI/Vacation
@onready var vacation_cg: TextureRect = $UI/Vacation/Frame/CG

signal plan_end

enum SchdType {LESSON,WORK,REST}

# 行动名称
var plan_name:String
# 当前行动的level
var plan_level:String 
# 学习，工作还是休息
var plan_type:SchdType

var plan_end_day:int
var is_vacation_running:bool = false

# 各课程/工作的核心主属性映射
var primary_attributes: Dictionary = {
	"theory": "smarts",
	"martialArts": "martial",
	"magic": "magic",
	"etiquette": "highclass",
	"art": "sensitive",
	"dance": "charm",
	"housework": "temper",
	"nanny": "temper",
	"farm": "stamina",
	"church": "morals",
	"restaurant": "temper",
	"maid": "highclass",
	"inn": "stamina",
	"logging": "stamina",
	"market": "smarts",
	"hotel": "charm",
	"tutor": "smarts",
	"maidHotel": "charm",
	"strangeHotel": "charm",
	"casino": "smarts"
}

func _ready() -> void:
	# 初始隐藏
	talk_layer.hide()
	arrtibute.hide()
	Global.sync_week_index()
	date.UpdateStatus()
	RunScheduleLoop()

func RunScheduleLoop() -> void:
	while Global.schedule_plan_index < 3:
		plan_name = Global.month_plan[Global.schedule_plan_index]
		
		# 如果该排程为外出，跳转至 city.tscn
		if plan_name == "outing":
			Global.is_outing_mode = true
			Global.outing_actions_left = 3
			talk_layer.keep_visible_on_end = false
			talk_layer.hide()
			get_tree().change_scene_to_file("res://sences/city.tscn")
			return
			
		# 如果该排程为度假
		if plan_name == "vacation":
			talk_layer.keep_visible_on_end = false
			await ExecuteVacation()
			Global.schedule_plan_index += 1
			continue
			
		await CheckScheduleEvents(plan_name)
		PlanStart()
		await self.plan_end
		Global.schedule_plan_index += 1
		
	# 3个计划全部执行完毕，跨月
	talk_layer.keep_visible_on_end = false
	talk_layer.hide()
	Global.day = 1
	Global.month += 1
	if Global.month > 12:
		Global.month = 1
		Global.year += 1
	Global.schedule_plan_index = 0
	Global.month_end_day = Global.get_current_month_end_day()
	Global.sync_week_index()
	get_tree().change_scene_to_file("res://sences/main.tscn")
	
func PlanStart():
	plan_name = Global.month_plan[Global.schedule_plan_index]
	plan_level = "level%d" % (Global.category_stage[plan_name][0])
	plan_type = SchdType[Globaljson.category_data[plan_name][plan_level]["type"]]
	schd.show()
	schd.LoadSpriteFrames(plan_name)
	if Global.schedule_plan_index == 2:
		plan_end_day = Global.get_current_month_end_day()
	else:
		plan_end_day = (Global.schedule_plan_index + 1) * 10
	talk_layer.keep_visible_on_end = true
	TimeLapse()

# 计算学习或打工的成功率（结合主属性、疲劳压力、熟练度、健康方针）
func CalculateSuccess(target_plan: String, _level_str: String) -> bool:
	var base_rate: float = 75.0
	
	# 1. 主属性门槛加成/惩罚
	var stage_idx = Global.category_stage.get(target_plan, [0, 0])[0]
	var thresholds = [50, 150, 300, 500]
	var target_threshold = thresholds[clampi(stage_idx, 0, 3)]
	
	var main_attr = primary_attributes.get(target_plan, "smarts")
	var daughter_stat = Daughterstatus.attributes.get(main_attr, 30)
	var stat_diff = daughter_stat - target_threshold
	var ability_bonus = clampf(stat_diff * 0.1, -30.0, 20.0)
	
	# 2. 压力/疲劳惩罚 (PM 系列经典机制)
	var stamina = maxf(1.0, float(Daughterstatus.attributes.get("stamina", 50)))
	var stress = float(Daughterstatus.attributes.get("stress", 0))
	var fatigue_penalty: float = 0.0
	if stress > stamina * 0.7:
		fatigue_penalty = (stress - stamina * 0.7) * 0.6
	if stress >= stamina:
		# 严重过劳，大幅增加失败惩罚
		fatigue_penalty += 35.0
		
	# 3. 熟练度加成 (每完成过一次该计划 +1%，上限 +10%)
	var count = Global.category_stage.get(target_plan, [0, 0])[1]
	var exp_bonus = minf(count * 1.0, 10.0)
	
	# 4. 健康方针修正 (Global.health_index: 0:顺其自然, 1:活泼, 2:娴静, 3:减肥)
	var health_bonus: float = 0.0
	match Global.health_index:
		1: # 活泼
			if main_attr in ["stamina", "martial"]:
				health_bonus = 5.0
		2: # 娴静
			if main_attr in ["smarts", "sensitive", "magic"]:
				health_bonus = 5.0
		3: # 减肥
			health_bonus = -5.0
			
	# 5. 道具加成 (油画组/传说的工具提升艺术课成功率, 舞鞋/玻璃舞鞋提升舞蹈课成功率)
	var item_bonus: float = 0.0
	if target_plan == "art":
		if Inventory.HasItem("o20"):
			item_bonus += 10.0
		elif Inventory.HasItem("o01"):
			item_bonus += 5.0
	elif target_plan == "dance":
		if Inventory.HasItem("o21"):
			item_bonus += 10.0
		elif Inventory.HasItem("o02"):
			item_bonus += 5.0

	var final_rate = base_rate + ability_bonus - fatigue_penalty + exp_bonus + health_bonus + item_bonus
	final_rate = clampf(final_rate, 10.0, 95.0)
	
	var roll = randf_range(0.0, 100.0)
	return roll < final_rate

func TimeLapse():
	match plan_type:
		SchdType.LESSON:
			# 周日休息
			if Global.week_index == 0:
				SundayRest()
			else:
				# 成功判定
				if CalculateSuccess(plan_name, plan_level):
					talk_layer.TalkStart([{"character": "",
								"emotion": "",
								"text": "按部就班地学习。",
								"voice": ""}],1,CalArrtibute(true))
				else:
					talk_layer.TalkStart([{"character": "",
								"emotion": "",
								"text": "完全学不进去……",
								"voice": ""}],1,CalArrtibute(false))
				Global.money += Globaljson.category_data[plan_name][plan_level]["money"]
		SchdType.WORK:
			if Global.week_index == 0:
				SundayRest()
			else:
				# 成功判定
				if CalculateSuccess(plan_name, plan_level):
					talk_layer.TalkStart([{"character": "",
								"emotion": "",
								"text": "工作进展顺利。",
								"voice": ""}],1,CalArrtibute(true))
					Global.money += Globaljson.category_data[plan_name][plan_level]["money"]
				else:
					talk_layer.TalkStart([{"character": "",
								"emotion": "",
								"text": "闯祸了……",
								"voice": ""}],1,CalArrtibute(false))
					# 失败收益减半
					Global.money += Globaljson.category_data[plan_name][plan_level]["money"] / 2
		SchdType.REST:
			talk_layer.TalkStart([{"character": "",
								"emotion": "",
								"text": "今天休息。",
								"voice": ""}],1,CalArrtibute(true))
func CalArrtibute(result:bool) -> Dictionary:
	var arrtibute_change:Dictionary
	if result:
		if plan_name == "rest":
			schd.EventHappen("rest")
		else:
			schd.EventHappen("success")
		for key in Daughterstatus.attributes.keys():
			if Globaljson.category_data[plan_name][plan_level][key] != 0:
				arrtibute_change[key] = Globaljson.category_data[plan_name][plan_level][key]
	else:
		schd.EventHappen("fail")
		for key in Daughterstatus.attributes.keys():
			if Globaljson.category_data[plan_name][plan_level][key] != 0:
				if key not in ["stress","crime","demonization"]:
					arrtibute_change[key] = Globaljson.category_data[plan_name][plan_level][key] / 2
				else:
					arrtibute_change[key] = Globaljson.category_data[plan_name][plan_level][key]
	
	# 道具加成计算 (舞鞋, 油画组, 传说的工具, 玻璃舞鞋)
	_apply_item_buffs(arrtibute_change)
	return arrtibute_change

# 计算道具对属性成长的被动加速加成 (舞鞋, 油画组, 传说的工具, 玻璃舞鞋)
func _apply_item_buffs(arrtibute_change: Dictionary) -> void:
	if plan_name == "art":
		var art_mult: float = 1.0
		if Inventory.HasItem("o01"): # 油画组: 感受增长 +25%
			art_mult += 0.25
		if Inventory.HasItem("o20"): # 传说的工具: 感受增长 +50%
			art_mult += 0.50
			
		if art_mult > 1.0 and arrtibute_change.has("sensitive") and arrtibute_change["sensitive"] > 0:
			arrtibute_change["sensitive"] = snappedf(arrtibute_change["sensitive"] * art_mult, 0.01)

	elif plan_name == "dance":
		var dance_mult: float = 1.0
		if Inventory.HasItem("o02"): # 舞鞋: 魅力、气质增长 +25%
			dance_mult += 0.25
		if Inventory.HasItem("o21"): # 玻璃舞鞋: 魅力、气质增长 +50%
			dance_mult += 0.50
			
		if dance_mult > 1.0:
			if arrtibute_change.has("charm") and arrtibute_change["charm"] > 0:
				arrtibute_change["charm"] = snappedf(arrtibute_change["charm"] * dance_mult, 0.01)
			if arrtibute_change.has("highclass") and arrtibute_change["highclass"] > 0:
				arrtibute_change["highclass"] = snappedf(arrtibute_change["highclass"] * dance_mult, 0.01)


func SundayRest() -> void:
	schd.EventHappen("rest")
	talk_layer.TalkStart([{"character": "",
					"emotion": "",
					"text": "周日休息",
					"voice": ""}],1,{"stress":-2})

func _on_talk_layer_talk_end() -> void:
	if is_vacation_running:
		return
	if Global.day >= plan_end_day:
		# 工作|上课次数+1
		Global.category_stage[plan_name][1] += 1
		_check_art_painting_unlock()
		# 若不是最后一旬，推进1天到下一旬的首日（如10日->11日，20日->21日）
		if Global.schedule_plan_index < 2:
			Global.day += 1
			Global.week_index = (Global.week_index + 1) % 7
			date.UpdateStatus()
			money.UpdateStatus()
		call_deferred("emit_signal", "plan_end")
	else:
		Global.day += 1
		# 度过了一天
		Global.week_index = (Global.week_index + 1) % 7
		date.UpdateStatus()
		money.UpdateStatus()
		await get_tree().create_timer(0.05).timeout
		TimeLapse()

func _check_art_painting_unlock() -> void:
	if plan_name == "art":
		var current_stage = Global.category_stage["art"][0]
		# 艺术课程分别达到中级(1)，上级(2)，专业(3)之后，再参加一次课程就会解锁不同的画作
		if current_stage >= 1 and Global.art_painting_level < current_stage:
			Global.art_painting_level = current_stage
			print("[艺术课] 完成艺术课程，解锁对应画作等级: %d" % Global.art_painting_level)

func ExecuteVacation() -> void:
	is_vacation_running = true
	# 立即彻底停止2D排程动画并隐藏，防止后台播放浪费性能
	schd.StopAnimation()
	schd.hide()
	date.hide()
	money.hide()
	talk_layer.keep_visible_on_end = false
	talk_layer.SetStandingSpritesVisible(false)
	
	if Global.schedule_plan_index == 2:
		plan_end_day = Global.get_current_month_end_day()
	else:
		plan_end_day = (Global.schedule_plan_index + 1) * 10
		
	# 1. 检查金钱
	var vacation_cost = 100
	if Global.money < vacation_cost:
		print("[度假] 金钱不足 (%d < %d)，无法外出度假" % [Global.money, vacation_cost])
		var broke_dialogue = [
			{"character": "", "emotion": "", "text": "盘缠不足，无法出远门度假……"},
			{"character": "daughter", "emotion": "calm", "text": "爸爸，家里资金比较紧张呢，度假还是下次再说吧，我们在家休息也挺好的！"}
		]
		var broke_state = {"done": false}
		talk_layer.RegisterCallback(func(_dummy): broke_state["done"] = true)
		talk_layer.TalkStart(broke_dialogue, talk_layer.SettleType.NULL)
		while not broke_state["done"]:
			await get_tree().process_frame
			
		# 在家简单休息，疲劳-30
		arrtibute.AnnotationStart({"stress": -30})
		await arrtibute.settle_end
		
		# 恢复界面并推进时间
		date.show()
		money.show()
		talk_layer.SetStandingSpritesVisible(true)
		await _advance_vacation_time()
		is_vacation_running = false
		return

	# 扣除度假费用
	Global.money -= vacation_cost
	if money and money.has_method("UpdateStatus"):
		money.UpdateStatus()

	# 2. 定位度假事件与对应 CG
	var year_idx = clampi(Global.year - 1440, 0, 7)
	var season_idx = Global.get_current_season_index()
	var season_key = "%d_%d" % [Global.year, season_idx]
	var already_triggered = Global.triggered_vacation_events.get(season_key, false)

	var current_vacation: Dictionary = {}
	for ev in Globaljson.vacation_data:
		if ev.get("year", 1440) == Global.year and ev.get("season_index", 0) == season_idx:
			current_vacation = ev
			break
	if current_vacation.is_empty():
		var target_idx = year_idx * 4 + season_idx
		if target_idx < Globaljson.vacation_data.size():
			current_vacation = Globaljson.vacation_data[target_idx]

	# 切换度假框 CG（使用居中画框，不更改全屏主背景）
	if current_vacation.has("cg") and ResourceLoader.exists(current_vacation["cg"]):
		vacation_cg.texture = load(current_vacation["cg"])
	vacation_ui.show()

	if already_triggered:
		# 同一季度内重复度假：不再触发事件选项（防刷属性），仅普通散心并消除100点疲劳
		print("[度假] 当前季度（%s）已触发过渡假剧情，本次为常规度假（疲劳-100，不重复获得选项加成）" % season_key)
		var repeat_diag = [
			{"character": "", "emotion": "", "text": "再次带着女儿来到郊外度假，享受悠闲宁静的时光。"},
			{"character": "daughter", "emotion": "happy", "text": "能再次出来放松，感觉精神好多了呢，谢谢爸爸！"}
		]
		var repeat_state = {"done": false}
		talk_layer.RegisterCallback(func(_dummy): repeat_state["done"] = true)
		talk_layer.TalkStart(repeat_diag, talk_layer.SettleType.NULL)
		while not repeat_state["done"]:
			await get_tree().process_frame
			
		arrtibute.AnnotationStart({"stress": -100.0})
		await arrtibute.settle_end
	else:
		# 首次度假：触发专属剧情事件、选项与属性/信赖度加成
		Global.triggered_vacation_events[season_key] = true

		# 3. 准备选项与剧情对话
		var intro_diag = current_vacation.get("intro", [
			{"character": "", "emotion": "", "text": "带着女儿踏上了美妙的度假之旅。"},
			{"character": "daughter", "emotion": "happy", "text": "能和爸爸一起出来玩，好开心啊！"}
		])
		var choices = current_vacation.get("choices", [])
		var choice_texts = []
		for c in choices:
			choice_texts.append(c.get("text", "休息"))

		# 4. 触发选项对话并等待玩家决策
		var choice_state = {"index": -1, "done": false}
		talk_layer.RegisterCallback(func(idx: int):
			choice_state["index"] = idx
			choice_state["done"] = true
		)
		talk_layer.TalkStart(intro_diag, talk_layer.SettleType.CHOICE, {}, choice_texts)
		while not choice_state["done"]:
			await get_tree().process_frame

		# 5. 选项属性变更计算（基础疲劳-100 + 选项属性变动）
		var chosen_choice = choices[choice_state["index"]] if choice_state["index"] >= 0 and choice_state["index"] < choices.size() else {}
		var total_changes: Dictionary = {}
		total_changes["stress"] = -100.0
		
		if chosen_choice.has("stats"):
			for k in chosen_choice["stats"].keys():
				var val = float(chosen_choice["stats"][k])
				if total_changes.has(k):
					total_changes[k] += val
				else:
					total_changes[k] = val

		# 6. 播放选项反馈对话
		var reaction_diag = chosen_choice.get("reaction", [])
		if not reaction_diag.is_empty():
			var reaction_state = {"done": false}
			talk_layer.RegisterCallback(func(_dummy): 
				reaction_state["done"] = true
			)
			talk_layer.TalkStart(reaction_diag, talk_layer.SettleType.NULL)
			while not reaction_state["done"]:
				await get_tree().process_frame

		# 7. 触发属性变更面板动画并模态等待玩家确认
		arrtibute.AnnotationStart(total_changes)
		await arrtibute.settle_end

	# 8. 隐藏度假界面，恢复时间与所持金，重置状态
	vacation_ui.hide()
	vacation_cg.texture = null
	date.show()
	money.show()
	talk_layer.SetStandingSpritesVisible(true)

	# 9. 时间流逝（天数跳动至阶段末尾）
	await _advance_vacation_time()

	Global.category_stage["vacation"][1] += 1
	is_vacation_running = false

func _advance_vacation_time() -> void:
	while Global.day < plan_end_day:
		await get_tree().create_timer(0.06).timeout
		Global.day += 1
		Global.sync_week_index()
		if date and date.has_method("UpdateStatus"):
			date.UpdateStatus()
	# 若不是最后一旬（例如上旬、中旬），推进1天到下一旬的首日（如10日->11日，20日->21日）
	if Global.schedule_plan_index < 2 and Global.day == plan_end_day:
		Global.day += 1
		Global.sync_week_index()
		if date and date.has_method("UpdateStatus"):
			date.UpdateStatus()

func CheckScheduleEvents(target_plan: String) -> void:
	var candidate_list: Array = []
	if target_plan == "rest":
		candidate_list = Globaljson.home_event_data.get("rest_events", [])
	else:
		var course_map: Dictionary = Globaljson.home_event_data.get("course_events", {})
		if course_map.has(target_plan):
			candidate_list = course_map[target_plan]
	if candidate_list.is_empty():
		return
	var available_events: Array = []
	for ev in candidate_list:
		var ev_id = ev.get("id", "")
		if ev_id != "" and not ev.get("repeatable", false) and Global.flags.get(ev_id, false):
			continue
		if CheckEventConditions(ev.get("conditions", {})):
			available_events.append(ev)
	if available_events.is_empty():
		return
	available_events.sort_custom(func(a, b): return a.get("priority", 0) > b.get("priority", 0))
	await PlayScheduleEvent(available_events[0])

func CheckEventConditions(cond: Dictionary) -> bool:
	for req_flag in cond.get("flags_required", []):
		if not Global.flags.get(req_flag, false):
			return false
	for ban_flag in cond.get("flags_banned", []):
		if Global.flags.get(ban_flag, false):
			return false
	var min_aff = cond.get("min_affection", {})
	for chara in min_aff.keys():
		if Global.affection.get(chara, 0) < min_aff[chara]:
			return false
	var max_aff = cond.get("max_affection", {})
	for chara in max_aff.keys():
		if Global.affection.get(chara, 0) > max_aff[chara]:
			return false
	var min_stats = cond.get("min_stats", {})
	for stat in min_stats.keys():
		var current_val = Daughterstatus.attributes.get(stat, Daughterstatus.body_stats.get(stat, null))
		if current_val == null or current_val < min_stats[stat]:
			return false
	var max_stats = cond.get("max_stats", {})
	for stat in max_stats.keys():
		var current_val = Daughterstatus.attributes.get(stat, Daughterstatus.body_stats.get(stat, null))
		if current_val != null and current_val > max_stats[stat]:
			return false
	if cond.has("min_year") and Global.year < cond["min_year"]:
		return false
	if cond.has("max_year") and Global.year > cond["max_year"]:
		return false
	if cond.has("min_month") and Global.month < cond["min_month"]:
		return false
	if cond.has("max_month") and Global.month > cond["max_month"]:
		return false
	if cond.get("is_birth_month", false) and Global.month != Daughterstatus.birth_month:
		return false
	return true

func PlayScheduleEvent(event: Dictionary) -> void:
	is_vacation_running = true
	schd.hide()
	talk_layer.keep_visible_on_end = false

	var ev_id = event.get("id", "")
	if ev_id != "" and not event.get("repeatable", false):
		Global.flags[ev_id] = true
	if event.has("set_flags"):
		for flag in event["set_flags"]:
			Global.flags[flag] = true
	if event.has("unlock_categories"):
		for cat in event["unlock_categories"]:
			if Global.category_stage.has(cat) and Global.category_stage[cat][0] == -1:
				Global.category_stage[cat][0] = 0
	if event.has("add_money"):
		Global.money += int(event["add_money"])
		if money and money.has_method("UpdateStatus"):
			money.UpdateStatus()
	var aff = event.get("add_affection", {})
	for chara in aff:
		Global.affection[chara] = Global.affection.get(chara, 0) + aff[chara]
	var stats = event.get("add_stats", {})
	for stat in stats:
		if Daughterstatus.attributes.has(stat):
			Daughterstatus.AddAttribute(stat, stats[stat])
		elif Daughterstatus.body_stats.has(stat):
			Daughterstatus.body_stats[stat] += stats[stat]

	var settle_type = talk_layer.SettleType.NULL
	var choice_list = []
	if event.has("choices"):
		settle_type = talk_layer.SettleType.CHOICE
		for c in event["choices"]:
			choice_list.append(c["text"])

	var step1_state = {"index": -1, "done": false}
	talk_layer.RegisterCallback(func(idx):
		step1_state["index"] = idx
		step1_state["done"] = true
	)
	talk_layer.TalkStart(event.get("dialogue_script", []), settle_type, {}, choice_list)
	while not step1_state["done"]:
		await get_tree().process_frame

	if event.has("choices") and step1_state["index"] >= 0 and step1_state["index"] < event["choices"].size():
		var choice_data = event["choices"][step1_state["index"]]
		var choice_aff = choice_data.get("add_affection", {})
		for chara in choice_aff:
			Global.affection[chara] = Global.affection.get(chara, 0) + choice_aff[chara]
		if choice_data.has("set_flags"):
			for flag in choice_data["set_flags"]:
				Global.flags[flag] = true
		if choice_data.has("unlock_categories"):
			for cat in choice_data["unlock_categories"]:
				if Global.category_stage.has(cat) and Global.category_stage[cat][0] == -1:
					Global.category_stage[cat][0] = 0
		if choice_data.has("add_money"):
			Global.money += int(choice_data["add_money"])
			if money and money.has_method("UpdateStatus"):
				money.UpdateStatus()

		var next_diag = choice_data.get("next_dialogue", [])
		if not next_diag.is_empty():
			var next_state = {"done": false}
			talk_layer.RegisterCallback(func(_dummy):
				next_state["done"] = true
			)
			talk_layer.TalkStart(next_diag, talk_layer.SettleType.NULL)
			while not next_state["done"]:
				await get_tree().process_frame

		var choice_stats = choice_data.get("add_stats", {})
		if not choice_stats.is_empty():
			var ui_stats = {}
			for stat in choice_stats:
				if arrtibute and arrtibute.attribute_nodes.has(stat):
					ui_stats[stat] = choice_stats[stat]
				elif Daughterstatus.attributes.has(stat):
					Daughterstatus.AddAttribute(stat, choice_stats[stat])
				elif Daughterstatus.body_stats.has(stat):
					Daughterstatus.body_stats[stat] += choice_stats[stat]
			if not ui_stats.is_empty():
				arrtibute.AnnotationStart(ui_stats)
				await arrtibute.settle_end

	is_vacation_running = false
