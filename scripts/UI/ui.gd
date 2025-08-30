extends CanvasLayer

@onready var date: Sprite2D = $Date
@onready var base_info: Sprite2D = $BaseInfo
@onready var daily_action: GridContainer = $DailyAction
@onready var plan: Button = $Plan
@onready var health_stat: Sprite2D = $HealthStat

# 状态
var is_status_canvas = false
@onready var birthday: Sprite2D = $Birthday
@onready var stature: Node2D = $Stature
@onready var character_attribute: Node2D = $CharacterAttribute

# 对话
var is_talk_canvas = false
@onready var talk: Node2D = $Talk
var talk_node_list:Array

# 健康
var is_health_canvas = false
@onready var health: Node2D = $Health
var health_node_list:Array

# 道具
var is_item_canvas = false
@onready var item: Node2D = $Item

# 上街
var is_street_canvas = false
@onready var street: Node2D = $Street
@onready var money: Sprite2D = $Money

var street_node_list:Array

# 系统
var is_system_canvas = false
@onready var system: Node2D = $System
var system_node_list:Array
# 动画位移
var move_vector = Vector2(500,0)

func _ready() -> void:
	InitialUI()
	talk_node_list = talk.init(["打招呼","温柔地说话","严厉地说话","给零用钱"])
	health_node_list = health.init(["顺其自然","以活泼为目标培养","以娴静为目标培养","进行减肥"])
	street_node_list = street.init(["道具店","洋装店","餐厅","教会","医院"])
	system_node_list = system.init(["储存游戏","读取记录","设定选项","标题界面"])

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

#func _input(event: InputEvent) -> void:
	#if event is InputEventMouseButton:
		#if event.pressed:
			#if is_status_canvas:
				#if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT:
					#is_status_canvas = false
					#LeaveStatus()
			#if is_talk_canvas:
				#if event.button_index == MOUSE_BUTTON_RIGHT:
					#is_talk_canvas = false
					#LeaveTalk()
			#if is_health_canvas:
				#if event.button_index == MOUSE_BUTTON_RIGHT:
					#is_health_canvas = false
					#LeaveHealth()
			#if is_item_canvas:
				#if event.button_index == MOUSE_BUTTON_RIGHT:
					#is_item_canvas = false
					#LeaveItem()
			#if is_street_canvas:
				#if event.button_index == MOUSE_BUTTON_RIGHT:
					#is_street_canvas = false
					#LeaveStreet()
			#if is_system_canvas:
				#if event.button_index == MOUSE_BUTTON_RIGHT:
					#is_system_canvas = false
					#LeaveSystem()
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_RIGHT or event.is_action_pressed("cancel"):
				if is_status_canvas:
					is_status_canvas = false
					LeaveStatus()
				if is_talk_canvas:
					is_talk_canvas = false
					LeaveTalk()
				if is_health_canvas:
					is_health_canvas = false
					LeaveHealth()
				if is_item_canvas:
					is_item_canvas = false
					LeaveItem()
				if is_street_canvas:
					is_street_canvas = false
					LeaveStreet()
				if is_system_canvas:
					is_system_canvas = false
					LeaveSystem()
			if event.button_index == MOUSE_BUTTON_LEFT:
				if is_status_canvas:
					is_status_canvas = false
					LeaveStatus()
			
					

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
	tween.tween_callback(func():is_status_canvas=true)

func _on_talk_button_down() -> void:
	OnAnimation()
	var tween = get_tree().create_tween()  # 创建一个 Tween
	tween.tween_property(daily_action, "position", daily_action.position+move_vector, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(plan, "position", plan.position+move_vector, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func():
		daily_action.hide()
		plan.hide())
	tween.tween_callback(func():
		talk.show())
	tween.tween_callback(func():is_talk_canvas=true)

func _on_health_button_down() -> void:
	OnAnimation()
	var tween = get_tree().create_tween()  # 创建一个 Tween
	tween.tween_property(daily_action, "position", daily_action.position+move_vector, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(plan, "position", plan.position+move_vector, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func():
		daily_action.hide()
		plan.hide())
	tween.tween_callback(func():
		health.show())
	tween.tween_callback(func():is_health_canvas=true)

func _on_item_button_down() -> void:
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
		item.show())
	tween.tween_property(item, "position", item.position+2*move_vector, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func():is_item_canvas=true)

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
	tween.tween_callback(func():is_street_canvas=true)

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
	tween.tween_callback(func():is_system_canvas=true)

func _on_cancel_button_down() -> void:
	LeaveItem()
