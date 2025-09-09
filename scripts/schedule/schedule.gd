extends Node

@onready var ui: CanvasLayer = $UI
@onready var date: Sprite2D = $UI/Date
@onready var money: Sprite2D = $UI/Money
@onready var schd: Node2D = $UI/Schd
@onready var talk_layer: CanvasLayer = $TalkLayer
@onready var arrtibute: CanvasLayer = $Arrtibute

var plan_index:int

func _ready() -> void:
	plan_index = 0
	# 初始隐藏
	talk_layer.hide()
	arrtibute.hide()
	Global.month_plan = [&"theory", &"theory", &"theory"]
	Global.month_end_day = 30
	TimeLapse()

func TimeLapse():
	# 加载需要用到的属性
	var arrtibute_change:Dictionary
	# 当前行动
	var plan_name:String = Global.month_plan[plan_index]
	# 当前行动的level
	var plan_level:String = "level%d" % (Global.category_stage[plan_name][0])
	# 周日休息
	if Global.week_index == 6:
		arrtibute_change["stress"] = -2
		schd.EventHappen("rest")
		talk_layer.TalkStart([{"character": "",
						"emotion": "",
						"text": "周日休息",
						"voice": ""}],1,arrtibute_change)
	else:
		# 成功了吗
		var rand_event = randi_range(0,1)
		if rand_event == 0:
			for key in Daughterstatus.attributes.keys():
				if Globaljson.category_data[plan_name][plan_level][key] != 0:
					arrtibute_change[key] = Globaljson.category_data[plan_name][plan_level][key]
			schd.LoadSpriteFrames(plan_name)
			schd.EventHappen("success")
			talk_layer.TalkStart([{"character": "",
						"emotion": "",
						"text": "按部就班地执行了。",
						"voice": ""}],1,arrtibute_change)
			Global.money += Globaljson.category_data[plan_name][plan_level]["money"]
		else:
			for key in Daughterstatus.attributes.keys():
				if Globaljson.category_data[plan_name][plan_level][key] != 0:
					if key != "stress":
						arrtibute_change[key] = Globaljson.category_data[plan_name][plan_level][key] / 2
					else:
						arrtibute_change[key] = Globaljson.category_data[plan_name][plan_level][key]
			schd.LoadSpriteFrames(plan_name)
			schd.EventHappen("fail")
			talk_layer.TalkStart([{"character": "",
						"emotion": "",
						"text": "好像搞砸了……",
						"voice": ""}],1,arrtibute_change)
			Global.money += Globaljson.category_data[plan_name][plan_level]["money"] / 2
	# 度过了一天
	Global.day += 1
	Global.week_index = (Global.week_index + 1) % 7
	date.UpdateStatus()
	money.UpdateStatus()

func _on_talk_layer_talk_end() -> void:
	if Global.day < Global.month_end_day:
		TimeLapse()
