extends Node2D

@onready var talk_layer: CanvasLayer = $"../../TalkLayer"
@onready var plan_panel: Node2D = $PlanPanel
@onready var money: Sprite2D = $"../Money"

func _on_plan_panel_plan_ready(plans: Array) -> void:
	var living_cost: int = Global.growth_rates["money"]
	var planned_expenses := living_cost
	for index in range(plans.size()):
		planned_expenses += Global.GetPlanExpense(plans[index], index * 10 + 1, Global.GetPlanEndDay(index))
	var lines := [{"character": "jeep", "emotion": "happy", "text": "这样安排可以吗？"}]
	if Global.money < planned_expenses:
		lines = [{"character": "jeep", "text": "资金不足。现有 %d，按当前等级估算支出 %d（含生活费 %d）。" % [Global.money, planned_expenses, living_cost]}]
		if Global.money < living_cost:
			lines.append({"character": "jeep", "text": "继续安排会把不足的生活费记为欠款。"})
		lines.append({"character": "jeep", "text": "打工收入到账后才可使用。付不起的课程和度假会改为休息。仍要继续吗？"})
	talk_layer.RegisterCallback(ChoiceEvent)
	talk_layer.TalkStart(lines, talk_layer.SettleType.CHOICE, {}, ["是", "否"])
	
func ChoiceEvent(choice_index: int) -> void:
	var plans: Array = plan_panel.plan_list.duplicate()
	plan_panel.DelAllPlan()
	if choice_index != 0:
		return
	Global.month_plan = plans
	Global.month_end_day = plan_panel.end_day
	Global.schedule_plan_index = 0
	Global.is_outing_mode = false
	var living_cost: int = Global.growth_rates["money"]
	Global.money -= living_cost
	money.UpdateStatus()
	var message := "本月生活费 %d。" % living_cost
	if Global.money < 0:
		message += " 当前欠款 %d。" % -Global.money
	talk_layer.RegisterCallback(StartSchedule)
	talk_layer.TalkStart([{"character": "", "text": message}])

func StartSchedule(_index: int) -> void:
	get_tree().change_scene_to_file("res://sences/schedule.tscn")
