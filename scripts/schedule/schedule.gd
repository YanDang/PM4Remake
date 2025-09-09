extends Node

@onready var ui: CanvasLayer = $UI
@onready var date: Sprite2D = $UI/Date
@onready var money: Sprite2D = $UI/Money
@onready var schd: Node2D = $UI/Schd
@onready var talk_layer: CanvasLayer = $TalkLayer
@onready var arrtibute: CanvasLayer = $Arrtibute

signal plan_end

enum SchdType {LESSON,WORK,REST}

# 现在到了第几个行动
var plan_index:int
# 行动名称
var plan_name:String
# 当前行动的level
var plan_level:String 
# 学习，工作还是休息
var plan_type:SchdType

var plan_end_day:int

func _ready() -> void:
	plan_index = 0
	# 初始隐藏
	talk_layer.hide()
	arrtibute.hide()
	Global.month_plan = [&"farm", &"theory", &"art"]
	Global.month_end_day = 30
	PlanStart()
	await self.plan_end
	PlanStart()
	await self.plan_end
	PlanStart()
	await self.plan_end
	Global.day = 1
	Global.month += 1
	get_tree().change_scene_to_file("res://sences/main.tscn")
	
func PlanStart():
	plan_name = Global.month_plan[plan_index]
	plan_level = "level%d" % (Global.category_stage[plan_name][0])
	plan_type = SchdType[Globaljson.category_data[plan_name][plan_level]["type"]]
	schd.LoadSpriteFrames(plan_name)
	if plan_index == 2:
		plan_end_day = Global.month_end_day
	else:
		plan_end_day = (plan_index+1) * 10
	TimeLapse()

func TimeLapse():
	match plan_type:
		SchdType.LESSON:
			# 周日休息
			if Global.week_index == 0:
				SundayRest()
			else:
				# 成功了吗
				var rand_event = randi_range(0,1)
				if rand_event == 0:
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
				# 成功了吗
				var rand_event = randi_range(0,1)
				if rand_event == 0:
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
	return arrtibute_change

func SundayRest() -> void:
	schd.EventHappen("rest")
	talk_layer.TalkStart([{"character": "",
					"emotion": "",
					"text": "周日休息",
					"voice": ""}],1,{"stress":-2})

func _on_talk_layer_talk_end() -> void:
	if Global.day <= plan_end_day:
		Global.day += 1
		date.UpdateStatus()
		TimeLapse()
		# 度过了一天
		Global.week_index = (Global.week_index + 1) % 7
		money.UpdateStatus()
		if Global.day > plan_end_day:
			plan_index += 1
			# 工作|上课次数+1
			Global.category_stage[plan_name][1] += 1
			emit_signal("plan_end")
