extends Node2D

@onready var talk_layer: CanvasLayer = $"../../TalkLayer"
@onready var plan_panel: Node2D = $PlanPanel
@onready var money: Sprite2D = $"../Money"

var pay_money = true

func _on_plan_panel_plan_ready(_plan_list: Array) -> void:
	talk_layer.RegisterCallback(ChoiceEvent)
	talk_layer.TalkStart([{
			"character": "jeep",
			"emotion": "happy",
			"text": "这样安排可以吗。",
		}],2,{},["是","否"])
	
func ChoiceEvent(choice_index:int):
	plan_panel.DelAllPlan()
	if choice_index == 0:
		if pay_money:
			Global.month_plan = plan_panel.plan_list
			Global.month_end_day = plan_panel.end_day
			talk_layer.TalkStart([{
				"character": "",
				"emotion": "",
				"text": "支付了生活费%s" % Global.growth_rates["money"],
			}])
			Global.money -= Global.growth_rates["money"]
			money.UpdateStatus()
			talk_layer.event_callable = Callable()
			pay_money = false
		await talk_layer.talk_end
		print("对话结束")
		get_tree().change_scene_to_file("res://sences/schedule.tscn")
