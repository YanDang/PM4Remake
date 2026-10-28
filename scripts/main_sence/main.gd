extends Node

@onready var back_ground: TextureRect = $BackGround
@onready var daughter_live: Node2D = $DaughterLive
@onready var ui: CanvasLayer = $UI
@onready var talk_layer: CanvasLayer = $TalkLayer
@onready var item_info: CanvasLayer = $ItemInfo
@onready var arrtibute: CanvasLayer = $Arrtibute

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	UpdateRoomBackground()
	back_ground.show()
	daughter_live.show()
	ui.show()
	item_info.hide()
	talk_layer.TalkEnd()
	call_deferred("CheckMonthlyHomeEvents")

# 更新主场景房间背景（根据当前季节与画作解锁等级）
func UpdateRoomBackground() -> void:
	var bg_path = Global.get_room_background_path()
	if ResourceLoader.exists(bg_path):
		back_ground.texture = load(bg_path)
	else:
		push_warning("Background resource not found: %s" % bg_path)

# 按键调试支持：F5切换季节，F6切换画作等级
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F5:
			# F5: 推进3个月切换季节 (春 4月 -> 夏 7月 -> 秋 10月 -> 冬 1月 -> 春 4月)
			Global.month = (Global.month + 2) % 12 + 1
			Global.sync_week_index()
			UpdateRoomBackground()
			var date_node = get_node_or_null("UI/Date")
			if date_node and date_node.has_method("UpdateStatus"):
				date_node.UpdateStatus()
			print("[调试] 季节切换 -> %s季 (%d月, 周%s), 背景图: %s" % [Global.get_current_season_name(), Global.month, Global.week_list[Global.week_index], Global.get_room_background_path()])
		elif event.keycode == KEY_F6:
			# F6: 循环切换画作等级 (0 -> 1 -> 2 -> 3 -> 0)
			Global.art_painting_level = (Global.art_painting_level + 1) % 4
			UpdateRoomBackground()
			var level_names = ["无画作", "中级-郁金香", "上级-几何苹果", "专业-丘陵独树"]
			print("[调试] 画作等级切换 -> %d (%s), 背景图: %s" % [Global.art_painting_level, level_names[Global.art_painting_level], Global.get_room_background_path()])

# 检查并触发月初自宅/父亲/节日剧情事件
func CheckMonthlyHomeEvents() -> void:
	if not Globaljson.home_event_data.has("monthly_events"):
		return
	var event_list: Array = Globaljson.home_event_data["monthly_events"]
	var available_events: Array = []
	for ev in event_list:
		var ev_id = ev.get("id", "")
		if ev_id != "" and not ev.get("repeatable", false) and Global.flags.get(ev_id, false):
			continue
		if CheckEventConditions(ev.get("conditions", {})):
			available_events.append(ev)
	if available_events.is_empty():
		return
	available_events.sort_custom(func(a, b): return a.get("priority", 0) > b.get("priority", 0))
	PlayHomeEvent(available_events[0])

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

func _refresh_plan_choose_if_needed() -> void:
	var plan_choose = get_node_or_null("UI/PlanSchedule/PlanChoose")
	if plan_choose and plan_choose.has_method("UpdateCategoryStatus"):
		plan_choose.UpdateCategoryStatus()
	var base_info = get_node_or_null("UI/BaseInfo")
	if base_info and base_info.has_method("UpdateStatus"):
		base_info.UpdateStatus()

func PlayHomeEvent(event: Dictionary) -> void:
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
		_refresh_plan_choose_if_needed()
	if event.has("add_money"):
		Global.money += int(event["add_money"])
		_refresh_plan_choose_if_needed()
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

	talk_layer.RegisterCallback(func(idx):
		if event.has("choices") and idx >= 0 and idx < event["choices"].size():
			var choice_data = event["choices"][idx]
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
				_refresh_plan_choose_if_needed()
			if choice_data.has("add_money"):
				Global.money += int(choice_data["add_money"])
				_refresh_plan_choose_if_needed()

			var has_ui_stats = false
			var choice_stats = choice_data.get("add_stats", {})
			if not choice_stats.is_empty():
				var ui_stats = {}
				for stat in choice_stats:
					if arrtibute and arrtibute.attribute_nodes.has(stat):
						ui_stats[stat] = choice_stats[stat]
						has_ui_stats = true
					elif Daughterstatus.attributes.has(stat):
						Daughterstatus.AddAttribute(stat, choice_stats[stat])
					elif Daughterstatus.body_stats.has(stat):
						Daughterstatus.body_stats[stat] += choice_stats[stat]
				if has_ui_stats:
					arrtibute.AnnotationStart(ui_stats)
					await arrtibute.settle_end

			var next_diag = choice_data.get("next_dialogue", [])
			if not next_diag.is_empty():
				talk_layer.RegisterCallback(func(_dummy):
					CheckMonthlyHomeEvents()
				)
				talk_layer.TalkStart(next_diag, talk_layer.SettleType.NULL)
				return
		CheckMonthlyHomeEvents()
	)
	talk_layer.TalkStart(event.get("dialogue_script", []), settle_type, {}, choice_list)

## 测试一个对话->选项->对话->属性加成的功能
#func event_test() -> void:
	#talk_layer.TalkStart([{
				#"character": "daughter",
				#"emotion": "happy",
				#"text": "这里是PM4Remake",
				#"voice": ""
			#}],2,{},["是","否"])
	#
#func _on_talk_layer_choice_result(choice_index: Variant) -> void:
	#print(choice_index)
	#
	#if choice_index == 0:
		#talk_layer.TalkStart([{
				#"character": "daughter",
				#"emotion": "happy",
				#"text": "选择了‘是’",
				#"voice": ""
			#}],1,{"smarts":10})
	#else:
		#talk_layer.TalkStart([{
				#"character": "daughter",
				#"emotion": "happy",
				#"text": "选择了‘否’",
				#"voice": ""
			#}],1,{"fame":1})
