extends Node

@onready var health_stat: Sprite2D = $"../HealthStat"
@onready var ui: CanvasLayer = $".."
@onready var conversation:Dictionary
@onready var talk_layer: CanvasLayer = $"../../TalkLayer"
@onready var health: Node2D = $Health

func LoadJsonData():
	conversation = JSON.parse_string(FileAccess.open("res://datajson/talkjson/dailytalk/health_swith_data.json", FileAccess.READ).get_as_text())

func _on_choice_pressed(_choice_text: String,choice_index:int):
	var health_tactics:String = Global.health_tactics[choice_index]
	Global.health_index = choice_index
	talk_layer.TalkStart(conversation[health_tactics])
	health.hide()
	for key in Globaljson.health_growth[Daughterstatus.age_stage_names[Daughterstatus.age_stage]][health_tactics].keys():
		Global.set(key,Globaljson.health_growth[Daughterstatus.age_stage_names[Daughterstatus.age_stage]][health_tactics][key])

func _on_talk_layer_talk_end() -> void:
	health_stat.UpdateStatus()
	ui.CloseCanvas()
