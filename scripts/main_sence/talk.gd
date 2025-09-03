extends Node

@onready var talk_layer: CanvasLayer = $"../../TalkLayer"
@onready var talk_names:Array = ["greeting","softly","sternly","allowance"]
@onready var ui: CanvasLayer = $".."
@onready var talk: Node2D = $Talk

var conversation:Dictionary

func LoadJsonData():
	conversation = JSON.parse_string(FileAccess.open("res://datajson/talkjson/dailytalk/conversation_data.json", FileAccess.READ).get_as_text())
	
func _on_choice_pressed(_choice_text: String,choice_index:int):
	# 获取当前年龄阶段
	var age_stage = Daughterstatus.age_stage_names[Daughterstatus.age_stage]
	talk_layer.TalkStart(conversation[age_stage][talk_names[choice_index]])
	talk.hide()

func _on_talk_layer_talk_end() -> void:
	ui.CloseCanvas()
