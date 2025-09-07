extends Node2D

@onready var talk_layer: CanvasLayer = $"../../TalkLayer"
@onready var plan_panel: Node2D = $PlanPanel

func _on_plan_panel_plan_ready(_plan_list: Array) -> void:
	talk_layer.RegisterCallback(ChoiceEvent)
	talk_layer.TalkStart([{
			"character": "jeep",
			"emotion": "happy",
			"text": "这样安排可以吗。",
		}],2,{},["是","否"])
	
func ChoiceEvent(choice_index:int):
	if choice_index == 0:
		print("跳转到执行场景")
	plan_panel.DelAllPlan()
