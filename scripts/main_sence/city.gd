extends Node

@onready var site_points = $UI/SitePoints
var ui
var talk_layer

@onready var site = $UI/Site
@onready var site_bg = $UI/Site/SiteBackGround
@onready var site_name_label = $UI/Site/SiteName/NameLabel

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


func _ready() -> void:
	# 兼容单独测试和主场景运行
	ui = get_node_or_null("../UI")
	talk_layer = get_node_or_null("TalkLayer") # 先找子节点 (单独测试)
	if talk_layer == null:
		talk_layer = get_node_or_null("../TalkLayer") # 再找同级节点 (主场景)
		
	InitLocationButtons()

func InitLocationButtons():
	for loc_node in site_points.get_children():
		var sprite = loc_node.get_node("AnimatedSprite2D")
		var label = loc_node.get_node("Label")
		
		# 初始状态
		sprite.play("default")
		label.hide()
		
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
			sprite.play("click")
			TriggerEvent(loc_node.name)
		)

func TriggerEvent(location_name: String):
	print("Clicked location: ", location_name)
	
	# 切换背景和名称
	site_points.hide()
	site.show()
	if site_data.has(location_name):
		site_bg.texture = load("res://assets/sys/" + site_data[location_name]["bg"])
		site_name_label.text = site_data[location_name]["name"]
	
	# 如果没有事件数据或该地点没配置事件
	if not Globaljson.event_data.has(location_name):
		DefaultFallback(location_name)
		return
		
	var available_events = []
	for event in Globaljson.event_data[location_name]:
		if CheckConditions(event.get("conditions", {})):
			available_events.append(event)
			
	if available_events.is_empty():
		DefaultFallback(location_name)
		return
		
	# 按优先级排序，从大到小
	available_events.sort_custom(func(a, b): return a.get("priority", 0) > b.get("priority", 0))
	
	var chosen_event = available_events[0]
	PlayEvent(chosen_event)

func CheckConditions(cond: Dictionary) -> bool:
	# 检查必须有的Flag
	for req_flag in cond.get("flags_required", []):
		if not Global.flags.get(req_flag, false): return false
		
	# 检查不能有的Flag
	for ban_flag in cond.get("flags_banned", []):
		if Global.flags.get(ban_flag, false): return false
		
	# 检查好感度下限
	var min_aff = cond.get("min_affection", {})
	for chara in min_aff.keys():
		if Global.affection.get(chara, 0) < min_aff[chara]: return false
		
	# 检查属性下限
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
		
	# 检查时间
	if cond.has("min_year") and Global.year < cond["min_year"]: return false
	if cond.has("max_year") and Global.year > cond["max_year"]: return false
	if cond.has("min_month") and Global.month < cond["min_month"]: return false
	if cond.has("max_month") and Global.month > cond["max_month"]: return false
	
	return true

func PlayEvent(event: Dictionary):
	# 记录设置的新flag
	if event.has("set_flags"):
		for flag in event["set_flags"]:
			Global.flags[flag] = true
			
	if talk_layer:
		if ui:
			ui.now_canvas_type = ui.CanvasType.TALK
		talk_layer.RegisterCallback(func(_idx):
			site.hide()
			site_points.show()
			if ui:
				ui.now_canvas_type = ui.CanvasType.CITY # 假设后续有个 CITY 类型
			# 这里可以处理事件播放完的后续
		)
		talk_layer.TalkStart(event["dialogue_script"], 0)
	else:
		print("TalkLayer not found! Dialogue:\n", event["dialogue_script"])

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
			site.hide()
			site_points.show()
			if ui:
				ui.now_canvas_type = ui.CanvasType.CITY
		)
		talk_layer.TalkStart(fallback_script, 0)
	else:
		print("TalkLayer not found! No event dialogue played.")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_1:
			Daughterstatus.age_stage = Daughterstatus.AgeStageType.CHILD
			print("Debug: Switched Daughter to CHILD")
		elif event.keycode == KEY_2:
			Daughterstatus.age_stage = Daughterstatus.AgeStageType.TEEN
			print("Debug: Switched Daughter to TEEN")
		elif event.keycode == KEY_3:
			Daughterstatus.age_stage = Daughterstatus.AgeStageType.ADULT
			print("Debug: Switched Daughter to ADULT")
