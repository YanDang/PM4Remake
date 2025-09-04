extends Node

@onready var talk_layer: CanvasLayer = $"../../TalkLayer"
@onready var arrtibute: CanvasLayer = $"../../Arrtibute"
@onready var base_info: Sprite2D = $"../BaseInfo"

@onready var talk_names:Array = ["greeting","softly","sternly","allowance"]
@onready var ui: CanvasLayer = $".."
@onready var talk: Node2D = $Talk

var conversation:Dictionary

func LoadJsonData():
	conversation = JSON.parse_string(FileAccess.open("res://datajson/talkjson/dailytalk/conversation_data.json", FileAccess.READ).get_as_text())
	
func _on_choice_pressed(_choice_text: String,choice_index:int):
	# 获取当前年龄阶段
	var age_stage = Daughterstatus.age_stage_names[Daughterstatus.age_stage]
	var arrtibute_dict:Dictionary = {}
	if Global.already_talk == false:
		match choice_index:
			0:
				arrtibute_dict = {"charm":5,"fame":2,"stress":-3}
			1:
				arrtibute_dict = {"morals":6,"sensitive":8,"pride":4,"stress":-5,"temper":-2}
			2:
				arrtibute_dict = {"pride":6,"highclass":4,"smarts":3,"temper":4,"stress":8}
			3:
				Global.money -= 50
				base_info.UpdateStatus()
				arrtibute_dict = {"charm":5,"crime":6,"morals":-4,"stress":-20}
		# 一年只有一次对话涨属性
		Global.already_talk = true
	talk_layer.TalkStart(conversation[age_stage][talk_names[choice_index]],arrtibute_dict)
	talk.hide()

func _on_talk_layer_talk_end() -> void:
	ui.CloseCanvas()
