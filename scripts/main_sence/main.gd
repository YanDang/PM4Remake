extends Node

@onready var back_ground: TextureRect = $BackGround
@onready var daughter_live: Node2D = $DaughterLive
@onready var ui: CanvasLayer = $UI
@onready var talk_layer: CanvasLayer = $TalkLayer
@onready var item_info: CanvasLayer = $ItemInfo

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	back_ground.show()
	daughter_live.show()
	ui.show()
	item_info.hide()
	talk_layer.TalkEnd()
	#event_test()

## 测试一个对话->选项->对话->属性加成的功能
#func event_test() -> void:
	#talk_layer.TalkStart([{
				#"character": "daughter",
				#"emotion": "happy",
				#"text": "这里是PM4Remake",
				#"voice": ""
			#}],2,{},["是","否"])
	#
#func _on_talk_layer_choice_result(choice_index: Variant) -> void:
	#print(choice_index)
	#
	#if choice_index == 0:
		#talk_layer.TalkStart([{
				#"character": "daughter",
				#"emotion": "happy",
				#"text": "选择了‘是’",
				#"voice": ""
			#}],1,{"smarts":10})
	#else:
		#talk_layer.TalkStart([{
				#"character": "daughter",
				#"emotion": "happy",
				#"text": "选择了‘否’",
				#"voice": ""
			#}],1,{"fame":1})
