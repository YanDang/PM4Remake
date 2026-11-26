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
var current_clothes: String = ""

func _on_timer_timeout() -> void:
	eye_index ^= 1
	eyes.play(all_animations[eye_index])

func ChangeClothes(clothes_name:String):
	# 加载了不应该存在的衣服（没有美术资源了）
	if not cloth_file_dict.get(clothes_name):
		if clothes_name != "常服" and cloth_file_dict.get("常服"):
			ChangeClothes("常服")
			return
		push_warning("Load Resource ERROR")
		return
	current_clothes = clothes_name
	Daughterstatus.current_clothes_name = clothes_name
	for item in Globaljson.items.values():
		if item.name == clothes_name:
			Daughterstatus.current_clothes_id = item.id.trim_prefix("c")
			break
	UpdatePortrait()

func UpdatePortrait() -> void:
	var sick_path := Daughterstatus.StandingPortraitPath("11") if Daughterstatus.is_ill else ""
	now_stage_node.modulate = Color.WHITE
	if not sick_path.is_empty() and ResourceLoader.exists(sick_path):
		body.texture = load(sick_path)
		# Align the feet with the normal portrait's standing position.
		body.offset.y = (region[Daughterstatus.age_stage].size.y - body.texture.get_height()) / 2.0
		eyes.hide()
		timer.stop()
		return
	body.offset.y = 0.0
	eyes.show()
	var atlas_tex = AtlasTexture.new()
	atlas_tex.atlas = load(cloth_file_dict[current_clothes])
	atlas_tex.region = region[Daughterstatus.age_stage]
	body.texture = atlas_tex
	if Daughterstatus.is_ill:
		now_stage_node.modulate = Color(0.83, 0.88, 0.93)
		eyes.stop()
		timer.stop()
		return
	# 结婚礼服不支持眨眼动画
	if current_clothes == "结婚礼服":
		timer.stop()
	else:
		timer.start()

func _ready() -> void:
	cloth_file_dict = Globaljson.clothes_path.get(Daughterstatus.age_stage_names[Daughterstatus.age_stage], {})
	print(Daughterstatus.age_stage)
	for i in range(age_stage_nodes.size()):
		if i == Daughterstatus.age_stage:
			age_stage_nodes[i].show()
		else:
			age_stage_nodes[i].hide()
	now_stage_node = age_stage_nodes[Daughterstatus.age_stage]
	eyes = now_stage_node.get_node("Eyes") as AnimatedSprite2D
	body = now_stage_node.get_node("Body") as Sprite2D
	var target_clothes = Daughterstatus.current_clothes_name if Daughterstatus.current_clothes_name != "" else "常服"
	ChangeClothes(target_clothes)
	Daughterstatus.health_changed.connect(UpdatePortrait)
