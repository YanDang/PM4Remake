extends CanvasLayer

@onready var date: Sprite2D = $Date
@onready var base_info: Sprite2D = $BaseInfo
@onready var daily_action: GridContainer = $DailyAction
@onready var plan: Button = $Plan
@onready var health_stat: Sprite2D = $HealthStat

enum CanvasType {MAIN,STATUS,TALK,HEALTH,ITEM,STREET,SYSTEM,PLAN,DAILYTALK,SAVE,SETTINGS,SHOP}
var now_canvas_type:CanvasType = CanvasType.MAIN
var temp_canvas_type:CanvasType

# 状态
@onready var birthday: Sprite2D = $Birthday
@onready var stature: Node2D = $Stature
@onready var character_attribute: Node2D = $CharacterAttribute

# 对话
@onready var talk: Node2D = $Talk/Talk
@onready var talk_console:Node = $Talk

# 健康
@onready var health: Node2D = $Health/Health
@onready var health_console: Node = $Health

# 道具
@onready var item_console: Node = $Item
@onready var item_panel: Node = $Item/ItemPanel
@onready var item_info: CanvasLayer = $"../ItemInfo"

# 上街
@onready var street: Node2D = $Street/Street
@onready var money: Sprite2D = $Money

# 系统
@onready var system: Node2D = $System/System

# 行程安排
@onready var plan_schedule: Node2D = $PlanSchedule
@onready var plan_choose: Node2D = $PlanSchedule/PlanChoose
@onready var plan_panel: Node2D = $PlanSchedule/PlanPanel
@onready var daughter_live: Node2D = $"../DaughterLive"

# 动画位移
var move_vector = Vector2(500,0)
var records_positions: Dictionary = {}

func _ready() -> void:
	InitialUI()
	talk.init(["打招呼","温柔地说话","严厉地说话","给零用钱"])
	health.init(["顺其自然","以活泼为目标培养","以娴静为目标培养","进行减肥"])
	var street_choices := ["道具店", "洋装店", "餐厅", "教会", "医院"]
	if Global.IsHarvestMonth():
		street_choices.append("收获祭")
	street.init(street_choices)
	system.init(["储存游戏","读取记录","设定选项","标题界面","新手指引"])

func InitialUI() -> void:
	daughter_live.show()
	date.show()
	base_info.show()
	health_stat.show()
	daily_action.show()
	plan.show()
	birthday.hide()
	stature.hide()
	character_attribute.hide()
	item_panel.hide()
	health.hide()
	street.hide()
	system.hide()
	money.hide()
	plan_schedule.hide()

# 返回主界面
func CloseCanvas() -> void:
	print(now_canvas_type)
	match now_canvas_type:
		CanvasType.STATUS:
			LeaveStatus()
		CanvasType.HEALTH:
			LeaveHealth()
		CanvasType.ITEM:
			LeaveItem()
		CanvasType.STREET:
			LeaveStreet()
		CanvasType.SYSTEM:
			LeaveSystem()
		CanvasType.PLAN:
			LeavePlan()
		CanvasType.DAILYTALK:
			LeaveTalk()
	now_canvas_type = CanvasType.MAIN
	
func _input(event: InputEvent) -> void:
	if SceneTransition.is_transitioning or now_canvas_type in [CanvasType.SAVE, CanvasType.SETTINGS]:
		return
	if now_canvas_type == CanvasType.SHOP:
		if event.is_action_pressed("cancel"):
			$Street._on_shop_panel_cancel()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("cancel") and now_canvas_type != CanvasType.PLAN and now_canvas_type != CanvasType.TALK:
		if now_canvas_type == CanvasType.ITEM and item_panel.is_using_item:
			return
		CloseCanvas()
	if event.is_action_pressed("confirm"):
		if now_canvas_type == CanvasType.STATUS:
			CloseCanvas()

func LeaveStatus() -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(birthday, "position", birthday.position-move_vector, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(stature, "position", stature.position-move_vector, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(character_attribute, "position", character_attribute.position+move_vector, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func():
		birthday.hide()
		stature.hide()
		character_attribute.hide())
	tween.tween_callback(func():
		daily_action.show()
		plan.show()
		health_stat.show())
	tween.tween_property(daily_action, "position", daily_action.position-move_vector, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(plan, "position", plan.position-move_vector, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(health_stat, "position", health_stat.position-move_vector, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(LeaveAnimation)

func LeaveTalk() -> void:
	var tween = get_tree().create_tween()  # 创建一个 Tween
	tween.tween_callback(func():
		talk.hide())
	tween.tween_callback(func():
		daily_action.show()
		plan.show())
	tween.tween_property(daily_action, "position", daily_action.position-move_vector, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(plan, "position", plan.position-move_vector, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(LeaveAnimation)

func LeaveHealth() -> void:
	var tween = get_tree().create_tween()  # 创建一个 Tween
	tween.tween_callback(func():
		health.hide())
	tween.tween_callback(func():
		daily_action.show()
		plan.show())
	tween.tween_property(daily_action, "position", daily_action.position-move_vector, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(plan, "position", plan.position-move_vector, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(LeaveAnimation)

func LeaveItem(restore_main_ui: bool = true) -> void:
	var tween = get_tree().create_tween()  # 创建一个 Tween
	item_info.hide()
	tween.tween_property(item_panel, "position", item_panel.position-2*move_vector, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func():
		item_panel.hide())
	tween.tween_callback(func():
		if restore_main_ui:
			daily_action.show()
			plan.show()
			health_stat.show()
			base_info.show()
			date.show())
	tween.tween_property(daily_action, "position", daily_action.position-move_vector, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(plan, "position", plan.position-move_vector, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(health_stat, "position", health_stat.position-move_vector, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(base_info, "position", base_info.position-move_vector, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(date, "position", date.position+move_vector, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(LeaveAnimation)
	await tween.finished

func LeaveStreet() -> void:
	var tween = get_tree().create_tween()  # 创建一个 Tween
	tween.tween_callback(func():
		street.hide())
	tween.tween_property(money, "position", money.position+move_vector, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func():
		daily_action.show()
		plan.show()
		health_stat.show()
		base_info.show()
		date.show())
	tween.tween_property(daily_action, "position", daily_action.position-move_vector, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(plan, "position", plan.position-move_vector, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(health_stat, "position", health_stat.position-move_vector, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(base_info, "position", base_info.position-move_vector, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(date, "position", date.position+move_vector, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(LeaveAnimation)

func LeaveSystem() -> void:
	var tween = get_tree().create_tween()  # 创建一个 Tween
	tween.tween_callback(func():
		system.hide())
	tween.tween_callback(func():
		daily_action.show()
		plan.show())
	tween.tween_property(daily_action, "position", daily_action.position-move_vector, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(plan, "position", plan.position-move_vector, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(LeaveAnimation)

func AnimateTitleExit() -> void:
	OnAnimation()
	var talk_layer = get_node("../TalkLayer")
	var slide_distance = get_viewport().get_visible_rect().size.x
	var tween = create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# 日期和对话框向左退出，属性面板和选项向右退出。
	for component in [date, talk_layer.get_node("TalkEvent")]:
		tween.tween_property(component, "position:x", component.position.x - slide_distance, 0.55)
	for component in [base_info, health_stat, daily_action, plan, system, talk_layer.choice_ui]:
		if component.is_visible_in_tree():
			tween.tween_property(component, "position:x", component.position.x + slide_distance, 0.55)
	tween.tween_property(daughter_live, "modulate:a", 0.0, 0.55)
	await tween.finished

func AnimateRecordsInterface(entering: bool) -> void:
	var components = [date, base_info, health_stat, system]
	var slide_distance = get_viewport().get_visible_rect().size.x
	if entering:
		show()
		daughter_live.show()
		system.show()
	else:
		for component in components:
			records_positions[component] = component.position
	var tween = create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for component in components:
		var offset = Vector2(-slide_distance if component == date else slide_distance, 0)
		var target = records_positions[component] if entering else records_positions[component] + offset
		tween.tween_property(component, "position", target, 0.45)
	tween.tween_property(daughter_live, "modulate:a", 1.0 if entering else 0.0, 0.45)
	await tween.finished
	if not entering:
		hide()
		daughter_live.hide()

func LeavePlan() -> void:
	var tween = get_tree().create_tween()  # 创建一个 Tween
	tween.tween_property(money, "position", money.position+move_vector, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(plan_choose, "position", plan_choose.position+2*move_vector, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(plan_panel, "position", plan_panel.position-2*move_vector, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func():
		daily_action.show()
		plan.show()
		health_stat.show()
		base_info.show()
		date.show()
		daughter_live.show())
	tween.tween_callback(func():
		money.hide()
		plan_schedule.hide())
	tween.tween_property(daily_action, "position", daily_action.position-move_vector, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(plan, "position", plan.position-move_vector, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(health_stat, "position", health_stat.position-move_vector, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(base_info, "position", base_info.position-move_vector, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(date, "position", date.position+move_vector, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(daughter_live,"modulate:a", 1.0, 0.5)
	tween.tween_callback(LeaveAnimation)
	

func OnAnimation() -> void:
	$DailyAction/Status.disabled = true
	$DailyAction/Talk.disabled = true
	$DailyAction/Health.disabled = true
	$DailyAction/Item.disabled = true
	$DailyAction/Street.disabled = true
	$DailyAction/System.disabled = true
	$Plan.disabled = true

func LeaveAnimation() -> void:
	$DailyAction/Status.disabled = false
	$DailyAction/Talk.disabled = false
	$DailyAction/Health.disabled = false
	$DailyAction/Item.disabled = false
	$DailyAction/Street.disabled = false
	$DailyAction/System.disabled = false
	$Plan.disabled = false

func _on_status_button_down() -> void:
	OnAnimation()
	var tween = get_tree().create_tween()  # 创建一个 Tween
	tween.tween_property(daily_action, "position", daily_action.position+move_vector, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(plan, "position", plan.position+move_vector, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(health_stat, "position", health_stat.position+move_vector, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func():
		daily_action.hide()
		plan.hide()
		health_stat.hide())
	tween.tween_callback(func():
		birthday.show()
		stature.show()
		character_attribute.show())
	# 显示的时候做一次更新
	stature.UpdateStatus()
	character_attribute.UpdateStatus()
	
	tween.tween_property(birthday, "position", birthday.position+move_vector, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(stature, "position", stature.position+move_vector, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(character_attribute, "position", character_attribute.position-move_vector, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func():now_canvas_type=CanvasType.STATUS)

func _on_talk_button_down() -> void:
	talk_console.LoadJsonData()
	OnAnimation()
	var tween = get_tree().create_tween()  # 创建一个 Tween
	tween.tween_property(daily_action, "position", daily_action.position+move_vector, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(plan, "position", plan.position+move_vector, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func():
		daily_action.hide()
		plan.hide())
	tween.tween_callback(func():
		talk.show())
	tween.tween_callback(func():now_canvas_type=CanvasType.DAILYTALK)

func _on_health_button_down() -> void:
	health_console.LoadJsonData()
	OnAnimation()
	var tween = get_tree().create_tween()  # 创建一个 Tween
	tween.tween_property(daily_action, "position", daily_action.position+move_vector, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(plan, "position", plan.position+move_vector, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func():
		daily_action.hide()
		plan.hide())
	tween.tween_callback(func():
		health.show())
	tween.tween_callback(func():now_canvas_type=CanvasType.HEALTH)

func _on_item_button_down() -> void:
	OnAnimation()
	# 在显示时对仓库进行一次排序
	Inventory.SortSlots()
	# 每次进入重置index
	item_panel.start_index = 0
	item_panel.item_nums = len(Inventory.slots)
	item_panel.UpdateChoice()
	var tween = get_tree().create_tween()  # 创建一个 Tween
	tween.tween_property(daily_action, "position", daily_action.position+move_vector, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(plan, "position", plan.position+move_vector, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(health_stat, "position", health_stat.position+move_vector, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(base_info, "position", base_info.position+move_vector, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(date, "position", date.position-move_vector, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func():
		daily_action.hide()
		plan.hide()
		health_stat.hide()
		base_info.hide()
		date.hide())
	tween.tween_callback(func():
		item_panel.show()
		item_info.show())
	tween.tween_property(item_panel, "position", item_panel.position+2*move_vector, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func():now_canvas_type=CanvasType.ITEM)

func _on_street_button_down() -> void:
	OnAnimation()
	var tween = get_tree().create_tween()  # 创建一个 Tween
	tween.tween_property(daily_action, "position", daily_action.position+move_vector, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(plan, "position", plan.position+move_vector, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(health_stat, "position", health_stat.position+move_vector, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(base_info, "position", base_info.position+move_vector, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(date, "position", date.position-move_vector, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func():
		daily_action.hide()
		plan.hide()
		health_stat.hide()
		base_info.hide()
		date.hide())
	tween.tween_callback(func():
		street.show()
		money.show())
	tween.tween_property(money, "position", money.position-move_vector, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func():now_canvas_type=CanvasType.STREET)

func _on_system_button_down() -> void:
	OnAnimation()
	var tween = get_tree().create_tween()  # 创建一个 Tween
	tween.tween_property(daily_action, "position", daily_action.position+move_vector, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(plan, "position", plan.position+move_vector, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func():
		daily_action.hide()
		plan.hide())
	tween.tween_callback(func():
		system.show())
	tween.tween_callback(func():now_canvas_type=CanvasType.SYSTEM)

func _on_plan_button_down() -> void:
	plan_choose.UpdateCategoryStatus()
	OnAnimation()
	var tween = get_tree().create_tween()  # 创建一个 Tween
	tween.tween_property(daily_action, "position", daily_action.position+move_vector, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(plan, "position", plan.position+move_vector, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(health_stat, "position", health_stat.position+move_vector, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(base_info, "position", base_info.position+move_vector, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(date, "position", date.position-move_vector, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func():
		daily_action.hide()
		plan.hide()
		health_stat.hide()
		base_info.hide()
		date.hide())
	tween.tween_callback(func():
		money.show()
		plan_schedule.show())
	tween.tween_property(money, "position", money.position-move_vector, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(plan_choose, "position", plan_choose.position-2*move_vector, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(plan_panel, "position", plan_panel.position+2*move_vector, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(daughter_live,"modulate:a", 0.0, 0.3)
	tween.tween_callback(func():
		now_canvas_type=CanvasType.PLAN
		daughter_live.hide())
	
func _on_cancel_pressed() -> void:
	if now_canvas_type in [CanvasType.TALK, CanvasType.SAVE, CanvasType.SETTINGS] or SceneTransition.is_transitioning:
		return
	if now_canvas_type == CanvasType.SHOP:
		$Street._on_shop_panel_cancel()
		return
	if now_canvas_type == CanvasType.ITEM and item_panel.is_using_item:
		return
	CloseCanvas()

func _on_plan_panel_plan_exit() -> void:
	now_canvas_type = CanvasType.PLAN
	CloseCanvas()

func _on_talk_layer_talk_start() -> void:
	temp_canvas_type = now_canvas_type
	now_canvas_type = CanvasType.TALK
	
func _on_talk_layer_talk_end() -> void:
	print(now_canvas_type)
	print("收到信号")
	now_canvas_type = temp_canvas_type
	print(now_canvas_type)
