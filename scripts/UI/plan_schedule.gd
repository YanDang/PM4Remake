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
	plan_panel.DelAllPlan()
	if choice_index == 0:
		print("跳转到执行场景")
		print(plan_panel.plan_list)
		Global.month_plan = plan_panel.plan_list
		Global.month_end_day = plan_panel.end_day
		get_tree().change_scene_to_file("res://sences/schedule.tscn")
		
