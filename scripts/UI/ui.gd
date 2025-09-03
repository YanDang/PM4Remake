extends CanvasLayer

@onready var date: Sprite2D = $Date
@onready var base_info: Sprite2D = $BaseInfo
@onready var daily_action: GridContainer = $DailyAction
@onready var plan: Button = $Plan
@onready var health_stat: Sprite2D = $HealthStat

enum CanvasType {MAIN,STATUS,TALK,HEALTH,ITEM,STREET,SYSTEM}
var now_canvas_type = CanvasType.MAIN

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
@onready var item: Node2D = $Item

# 上街
@onready var street: Node2D = $Street/Street
@onready var money: Sprite2D = $Money

# 系统
@onready var system: Node2D = $System/System
# 动画位移
var move_vector = Vector2(500,0)

func _ready() -> void:
	InitialUI()
	talk.init(["打招呼","温柔地说话","严厉地说话","给零用钱"])
	health.init(["顺其自然","以活泼为目标培养","以娴静为目标培养","进行减肥"])
	street.init(["道具店","洋装店","餐厅","教会","医院"])
	system.init(["储存游戏","读取记录","设定选项","标题界面"])

func InitialUI() -> void:
	date.show()
	base_info.show()
	health_stat.show()
	daily_action.show()
	plan.show()
	birthday.hide()
	stature.hide()
	character_attribute.hide()
	item.hide()
	health.hide()
	street.hide()
	system.hide()
	money.hide()

# 返回主界面
func CloseCanvas() -> void:
	match now_canvas_type:
		CanvasType.STATUS:
			LeaveStatus()
		CanvasType.TALK:
			LeaveTalk()
		CanvasType.HEALTH:
			LeaveHealth()
		CanvasType.ITEM:
			LeaveItem()
		CanvasType.STREET:
			LeaveStreet()
		CanvasType.SYSTEM:
			LeaveSystem()
	now_canvas_type = CanvasType.MAIN
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("cancel"):
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

func LeaveItem() -> void:
	var tween = get_tree().create_tween()  # 创建一个 Tween
	tween.tween_property(item, "position", item.position-2*move_vector, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func():
		item.hide())
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
	tween.tween_property(daily_action, "position", daily_action.position+move_vector, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(plan, "position", plan.position+move_vector, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(health_stat, "position", health_stat.position+move_vector, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func():
		daily_action.hide()
		plan.hide()
		health_stat.hide())
	tween.tween_callback(func():
		birthday.show()
		stature.show()
		character_attribute.show())
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
	tween.tween_callback(func():now_canvas_type=CanvasType.TALK)

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
	item.start_index = 0
	item.item_nums = len(Inventory.slots)
	item.UpdateChoice()
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
		item.show())
	tween.tween_property(item, "position", item.position+2*move_vector, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
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

func _on_cancel_button_down() -> void:
	CloseCanvas()
