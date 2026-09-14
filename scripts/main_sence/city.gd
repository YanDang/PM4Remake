extends Node

@onready var site_points = $UI/SitePoints
var ui
var talk_layer

@onready var site = $UI/Site
@onready var site_bg = $UI/Site/SiteBackGround
@onready var site_name_label = $UI/Site/SiteName/NameLabel
@onready var date = $UI.get_node_or_null("Date")
@onready var action_badge: Label = $UI.get_node_or_null("ActionBadge")
@onready var go_home: Button = $UI.get_node_or_null("GoHome")

var is_time_lapsing: bool = false

var site_data = {
	"City": {"bg": "bg01.png", "name": "城"},
	"BusyStreet": {"bg": "bg07.png", "name": "繁华街"},
	"ClothShop": {"bg": "bg10.png", "name": "洋装店"},
	"FoodShop": {"bg": "bg09.png", "name": "餐厅"},
	"ItemShop": {"bg": "bg08.png", "name": "道具店"},
	"Square": {"bg": "bg04.png", "name": "广场"},
	"Market": {"bg": "bg05.png", "name": "市场"},
	"Church": {"bg": "bg12.png", "name": "教会"},
	"Street": {"bg": "bg06.png", "name": "街道"},
	"Hospital": {"bg": "bg13.png", "name": "医院"},
	"BlackStreet": {"bg": "bg14.png", "name": "黑街"}
}

var circle_avatar_shader = preload("res://animation/city/circle_avatar.gdshader")

func _ready() -> void:
	# 兼容单独测试和主场景运行
	ui = get_node_or_null("../UI")
	talk_layer = get_node_or_null("TalkLayer") # 先找子节点 (单独测试)
	if talk_layer == null:
		talk_layer = get_node_or_null("../TalkLayer") # 再找同级节点 (主场景)
		
	Global.sync_week_index()
	if date:
		date.UpdateStatus()
		
	if not Global.is_outing_mode:
		Global.outing_actions_left = 3
		
	if go_home:
		go_home.pressed.connect(_on_go_home_pressed)

	UpdateActionBadge()
	InitLocationButtons()
	UpdateLocationHints()

func UpdateActionBadge() -> void:
	if action_badge:
		action_badge.text = "外出行动: %d / 3" % clampi(Global.outing_actions_left, 0, 3)

func InitLocationButtons():
	for loc_node in site_points.get_children():
		var sprite = loc_node.get_node("AnimatedSprite2D")
		var label = loc_node.get_node("Label")
		
		# 初始状态
		sprite.play("default")
		label.hide()
		
		# 创建圆形头像事件提示节点
		var hint_rect = TextureRect.new()
		hint_rect.name = "EventHint"
		hint_rect.custom_minimum_size = Vector2(46, 46)
		hint_rect.size = Vector2(46, 46)
		hint_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		hint_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		var mat = ShaderMaterial.new()
		mat.shader = circle_avatar_shader
		hint_rect.material = mat
		
		hint_rect.position = sprite.position + Vector2(18, -38)
		hint_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hint_rect.hide()
		loc_node.add_child(hint_rect)
		
		# 创建一个全覆盖的透明按钮
		var btn = TextureButton.new()
		loc_node.add_child(btn)
		
		# 设置按钮位置和大小，覆盖在 Sprite 上
		# Sprite 是居中显示的，所以要根据 texture 的大小计算
		var tex_size = sprite.sprite_frames.get_frame_texture("default", 0).get_size() * sprite.scale
		btn.size = tex_size
		btn.position = sprite.position - tex_size / 2
		
		# 绑定信号
		btn.mouse_entered.connect(func():
			sprite.play("hover")
			label.show()
		)
		btn.mouse_exited.connect(func():
			sprite.play("default")
			label.hide()
		)
		btn.pressed.connect(func():
			if is_time_lapsing:
				return
			sprite.play("click")
			TriggerEvent(loc_node.name)
		)

func GetAvailableEventForLocation(location_name: String) -> Dictionary:
	var event_list = []
	if Globaljson.event_data.has(location_name):
		event_list = Globaljson.event_data[location_name]
	elif location_name == "City" and Globaljson.event_data.has("Castle"):
		event_list = Globaljson.event_data["Castle"]
	elif location_name == "Castle" and Globaljson.event_data.has("City"):
		event_list = Globaljson.event_data["City"]
		
	var available_events = []
	for event in event_list:
		if CheckConditions(event.get("conditions", {})):
			available_events.append(event)
			
	if available_events.is_empty():
		return {}
		
	# 按优先级排序，从大到小
	available_events.sort_custom(func(a, b): return a.get("priority", 0) > b.get("priority", 0))
	return available_events[0]

func GetEventCharacter(event: Dictionary) -> String:
	var chara = event.get("character", "")
	if chara != "" and chara != "daughter":
		return chara
	if event.has("dialogue_script"):
		for d in event["dialogue_script"]:
			var c = d.get("character", "")
			if c != "" and c != "daughter":
				return c
	if event.has("add_affection") and not event["add_affection"].is_empty():
		return event["add_affection"].keys()[0]
	return chara

func GetCharacterHeadshotIcon(chara: String) -> Texture2D:
	if chara == "" or not Globaljson.icon_path.has(chara):
		return null
	var entry = Globaljson.icon_path[chara]
	var base_name = ""
	if entry is Dictionary:
		var stage_name = Daughterstatus.age_stage_names[Daughterstatus.age_stage]
		base_name = entry.get(stage_name, "")
	else:
		base_name = str(entry)
	if base_name == "":
		return null
		
	var p1 = "res://assets/PM4_FC/" + base_name + "01.png"
	var p2 = "res://assets/PM4_FC/" + base_name + ".png"
	if ResourceLoader.exists(p1):
		return load(p1)
	elif ResourceLoader.exists(p2):
		return load(p2)
	return null

func UpdateLocationHints():
	for loc_node in site_points.get_children():
		var hint_rect = loc_node.get_node_or_null("EventHint")
		if not hint_rect:
			continue
			
		var ev = GetAvailableEventForLocation(loc_node.name)
		if ev.is_empty():
			hint_rect.hide()
		else:
			var chara = GetEventCharacter(ev)
			var icon_tex = GetCharacterHeadshotIcon(chara)
			if icon_tex:
				hint_rect.texture = icon_tex
				hint_rect.show()
				
				# 呼吸轻微浮动动画
				if not hint_rect.has_meta("has_anim"):
					hint_rect.set_meta("has_anim", true)
					var base_y = hint_rect.position.y
					var tween = create_tween().set_loops()
					tween.tween_property(hint_rect, "position:y", base_y - 4, 0.8).set_trans(Tween.TRANS_SINE)
					tween.tween_property(hint_rect, "position:y", base_y, 0.8).set_trans(Tween.TRANS_SINE)
			else:
				hint_rect.hide()

func TriggerEvent(location_name: String):
	print("Clicked location: ", location_name)
	
	# 切换背景和名称
	site_points.hide()
	site.show()
	if go_home:
		go_home.hide()
	if site_data.has(location_name):
		site_bg.texture = load("res://assets/sys/" + site_data[location_name]["bg"])
		site_name_label.text = site_data[location_name]["name"]
	
	var chosen_event = GetAvailableEventForLocation(location_name)
	if chosen_event.is_empty():
		DefaultFallback(location_name)
		return
		
	PlayEvent(chosen_event)

func CheckConditions(cond: Dictionary) -> bool:
	# 检查必须有的Flag
	for req_flag in cond.get("flags_required", []):
		if not Global.flags.get(req_flag, false): return false
		
	# 检查不能有的Flag
	for ban_flag in cond.get("flags_banned", []):
		if Global.flags.get(ban_flag, false): return false
		
	# 检查好感度下限与上限
	var min_aff = cond.get("min_affection", {})
	for chara in min_aff.keys():
		if Global.affection.get(chara, 0) < min_aff[chara]: return false
	var max_aff = cond.get("max_affection", {})
	for chara in max_aff.keys():
		if Global.affection.get(chara, 0) > max_aff[chara]: return false
		
	# 检查属性下限与上限
	var min_stats = cond.get("min_stats", {})
	for stat in min_stats.keys():
		var current_val = 0
		if Daughterstatus.attributes.has(stat):
			current_val = Daughterstatus.attributes[stat]
		elif Daughterstatus.body_stats.has(stat):
			current_val = Daughterstatus.body_stats[stat]
		else:
			current_val = Daughterstatus.get(stat)
			
		if current_val == null:
			current_val = Global.get(stat)
			
		if current_val == null or current_val < min_stats[stat]: 
			return false
			
	var max_stats = cond.get("max_stats", {})
	for stat in max_stats.keys():
		var current_val = 0
		if Daughterstatus.attributes.has(stat):
			current_val = Daughterstatus.attributes[stat]
		elif Daughterstatus.body_stats.has(stat):
			current_val = Daughterstatus.body_stats[stat]
		else:
			current_val = Daughterstatus.get(stat)
			
		if current_val == null:
			current_val = Global.get(stat)
			
		if current_val != null and current_val > max_stats[stat]:
			return false
		
	# 检查时间
	if cond.has("min_year") and Global.year < cond["min_year"]: return false
	if cond.has("max_year") and Global.year > cond["max_year"]: return false
	if cond.has("min_month") and Global.month < cond["min_month"]: return false
	if cond.has("max_month") and Global.month > cond["max_month"]: return false
	
	# 检查年龄
	if cond.has("min_age") and Daughterstatus.age < cond["min_age"]: return false
	if cond.has("max_age") and Daughterstatus.age > cond["max_age"]: return false
	
	return true

func PlayEvent(event: Dictionary):
	# 设置基础flag
	if event.has("set_flags"):
		for flag in event["set_flags"]:
			Global.flags[flag] = true
			
	# 根级别的被动好感度和属性增加（无UI动画，静默增加）
	var aff = event.get("add_affection", event.get("affection_changes", {}))
	for chara in aff:
		if not Global.affection.has(chara):
			Global.affection[chara] = 0
		Global.affection[chara] += aff[chara]
		
	var stats = event.get("add_stats", event.get("stats_changes", {}))
	for stat in stats:
		if Daughterstatus.attributes.has(stat):
			Daughterstatus.AddAttribute(stat, stats[stat])
		elif Daughterstatus.body_stats.has(stat):
			Daughterstatus.body_stats[stat] += stats[stat]
			
	if talk_layer:
		if ui:
			ui.now_canvas_type = ui.CanvasType.TALK
			
		var settle_type = 0
		var choice_list = []
		if event.has("choices"):
			settle_type = 2
			for c in event["choices"]:
				choice_list.append(c["text"])
				
		talk_layer.RegisterCallback(func(idx):
			if event.has("choices") and idx >= 0 and idx < event["choices"].size():
				var choice_data = event["choices"][idx]
				
				# 结算好感度
				var choice_aff = choice_data.get("add_affection", choice_data.get("affection_changes", {}))
				for chara in choice_aff:
					if not Global.affection.has(chara):
						Global.affection[chara] = 0
					Global.affection[chara] += choice_aff[chara]
						
				# 结算属性
				var has_ui_stats = false
				var choice_stats = choice_data.get("add_stats", choice_data.get("stat_changes", choice_data.get("stats_changes", {})))
				if not choice_stats.is_empty():
					var ui_stats = {}
					for stat in choice_stats:
						if talk_layer.arrtibute and talk_layer.arrtibute.attribute_nodes.has(stat):
							ui_stats[stat] = choice_stats[stat]
							has_ui_stats = true
						else:
							if Daughterstatus.attributes.has(stat):
								Daughterstatus.AddAttribute(stat, choice_stats[stat])
							elif Daughterstatus.body_stats.has(stat):
								Daughterstatus.body_stats[stat] += choice_stats[stat]
					
					if has_ui_stats:
						talk_layer.arrtibute.AnnotationStart(ui_stats)
						
				# 记录选项触发的特定 flag
				if choice_data.has("set_flags"):
					for flag in choice_data["set_flags"]:
						Global.flags[flag] = true
						
				if has_ui_stats:
					await talk_layer.arrtibute.settle_end
						
				# 如果有后续对话，继续播放
				var next_diag = choice_data.get("next_dialogue", choice_data.get("dialogue_script", []))
				if next_diag.size() > 0:
					talk_layer.RegisterCallback(func(_dummy):
						ReturnToCityMap()
					)
					talk_layer.TalkStart(next_diag, 0)
					return
					
			# 关闭界面并返回城镇
			ReturnToCityMap()
		)
		talk_layer.TalkStart(event["dialogue_script"], settle_type, {}, choice_list)
	else:
		print("TalkLayer not found! Dialogue:\n", event["dialogue_script"])

func ReturnToCityMap():
	site.hide()
	site_points.show()
	if go_home and not is_time_lapsing:
		go_home.show()
	if ui:
		ui.now_canvas_type = ui.CanvasType.MAIN
	UpdateLocationHints()
	ConsumeAction()

func _on_go_home_pressed() -> void:
	if is_time_lapsing:
		return
	if talk_layer and talk_layer.visible:
		return
	print("[外出] 玩家点击回家按钮，提前结束本次外出")
	StartTimeLapseAndExit()

func ConsumeAction() -> void:
	if is_time_lapsing:
		return
	Global.outing_actions_left -= 1
	UpdateActionBadge()
	if Global.outing_actions_left <= 0:
		StartTimeLapseAndExit()

func StartTimeLapseAndExit() -> void:
	is_time_lapsing = true
	if go_home:
		go_home.hide()
	if action_badge:
		action_badge.text = "外出结束，时间流逝中..."
		
	# 前两个行动（阶段0、阶段1）固定前进到 10 日和 20 日；
	# 最后一次行动（阶段2）根据当前月份总天数（28/29/30/31日）确定终止日！
	var plan_end_day: int
	if Global.schedule_plan_index >= 2:
		plan_end_day = Global.get_current_month_end_day()
	else:
		plan_end_day = (Global.schedule_plan_index + 1) * 10
		
	# 时间流逝跳动动画（逐日推进并刷新表盘）
	while Global.day < plan_end_day:
		await get_tree().create_timer(0.08).timeout
		Global.day += 1
		Global.week_index = (Global.week_index + 1) % 7
		if date:
			date.UpdateStatus()
			
	# 若不是最后一旬，推进1天到下一旬的首日（如10日->11日，20日->21日）
	if Global.schedule_plan_index < 2 and Global.day == plan_end_day:
		Global.day += 1
		Global.week_index = (Global.week_index + 1) % 7
		if date:
			date.UpdateStatus()
			
	await get_tree().create_timer(0.3).timeout
	
	# 外出排程结束，推进到下一个排程
	Global.outing_actions_left = 3
	Global.is_outing_mode = false
	Global.schedule_plan_index += 1
	
	if Global.schedule_plan_index >= 3:
		# 本月所有计划执行完毕，跨月并返回主场景
		Global.day = 1
		Global.month += 1
		if Global.month > 12:
			Global.month = 1
			Global.year += 1
		Global.schedule_plan_index = 0
		Global.month_end_day = Global.get_current_month_end_day()
		Global.sync_week_index()
		get_tree().change_scene_to_file("res://sences/main.tscn")
	else:
		# 返回排程场景继续后续计划
		get_tree().change_scene_to_file("res://sences/schedule.tscn")

func DefaultFallback(location_name: String):
	print("No event at ", location_name)
	# 通用无事件闲聊
	var fallback_script = [
		{
			"character": "daughter",
			"emotion": "calm",
			"text": "在这个地方逛了一会儿，并没有发生特别的事……"
		}
	]
	if talk_layer:
		if ui:
			ui.now_canvas_type = ui.CanvasType.TALK
		talk_layer.RegisterCallback(func(_idx):
			ReturnToCityMap()
		)
		talk_layer.TalkStart(fallback_script, 0)
	else:
		print("TalkLayer not found! No event dialogue played.")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_1:
			Daughterstatus.age_stage = Daughterstatus.AgeStageType.CHILD
			print("Debug: Switched Daughter to CHILD")
			UpdateLocationHints()
		elif event.keycode == KEY_2:
			Daughterstatus.age_stage = Daughterstatus.AgeStageType.TEEN
			print("Debug: Switched Daughter to TEEN")
			UpdateLocationHints()
		elif event.keycode == KEY_3:
			Daughterstatus.age_stage = Daughterstatus.AgeStageType.ADULT
			print("Debug: Switched Daughter to ADULT")
			UpdateLocationHints()
		elif event.keycode == KEY_4:
			Global.year = 1445
			print("Debug: Switched Year to 1445")
			UpdateLocationHints()
			
