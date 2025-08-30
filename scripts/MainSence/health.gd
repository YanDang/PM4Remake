extends Node

@onready var health_stat: Sprite2D = $"../HealthStat"
@onready var ui: CanvasLayer = $".."

func _on_choice_pressed(choice_text: String,choice_index:int):
	Global.health_index = choice_index
	health_stat.UpdateStatus()
	ui.LeaveHealth()
