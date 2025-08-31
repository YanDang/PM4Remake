extends Node

@onready var health_stat: Sprite2D = $"../HealthStat"
@onready var ui: CanvasLayer = $".."

func _on_choice_pressed(_choice_text: String,choice_index:int):
	Global.health_index = choice_index
	health_stat.UpdateStatus()
	var health_tactics:String = Global.health_tactics[choice_index]
	for key in Globaljson.health_growth[Daughterstatus.age_stage][health_tactics].keys():
		Global.set(key,Globaljson.health_growth[Daughterstatus.age_stage][health_tactics][key])
	ui.CloseCanvas()
