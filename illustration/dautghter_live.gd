extends Node2D

@onready var timer: Timer = $Timer
@onready var age_stage_nodes = [$Child,$Teen,$Adult]

# 根据年龄阶段读取不同的节点
var now_stage_node:Node2D
var eyes: AnimatedSprite2D
var body: Sprite2D

var region:Array = [Rect2(0,50,268,398),Rect2(0,76,280,444),Rect2(0,54,372,472)]
# 幼年形象
var cloth_file_dict:Dictionary

var eye_index = 0
var all_animations = ["wink","wink_double"]

func _on_timer_timeout() -> void:
	eye_index ^= 1
	eyes.play(all_animations[eye_index])

func ChangeClothes(clothes_name:String):
	# 加载了不应该存在的衣服（没有美术资源了）
	if not cloth_file_dict.get(clothes_name):
		push_warning("Load Resource ERROR")
		return
	var atlas_tex = AtlasTexture.new()
	print(Daughterstatus.age_stage_names[Daughterstatus.age_stage])
	print(cloth_file_dict[clothes_name])
	atlas_tex.atlas = load(cloth_file_dict[clothes_name])
	atlas_tex.region = region[Daughterstatus.age_stage]
	body.texture = atlas_tex
	# 结婚礼服不支持眨眼动画
	if clothes_name == "结婚礼服":
		timer.stop()
	else:
		timer.start()

func _ready() -> void:
	Daughterstatus.age_stage = Daughterstatus.AgeStageType.CHILD
	cloth_file_dict = Globaljson.clothes_path[Daughterstatus.age_stage_names[Daughterstatus.age_stage]]
	print(Daughterstatus.age_stage)
	Inventory.AddItem("c14")
	Inventory.AddItem("c19")
	Inventory.AddItem("c06")
	now_stage_node = age_stage_nodes[Daughterstatus.age_stage]
	now_stage_node.show()
	eyes = now_stage_node.get_node("Eyes") as AnimatedSprite2D
	body = now_stage_node.get_node("Body") as Sprite2D
	ChangeClothes("常服")
