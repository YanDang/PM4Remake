extends Node2D

@onready var labels:Array = [$HeadConsole/Course,$HeadConsole/Work,$HeadConsole/Rest]
@onready var head_back_ground: TextureRect = $HeadConsole/HeadBackGround
@onready var choose_high_light: AnimatedSprite2D = $ChooseHighLight

var head_atlas:AtlasTexture

var activate_index = 0
# 未选中，选中
var font_size = [14,20]
var label_size = [Vector2(50,20),Vector2(80,23)]
# 未选中，选中，激活
var color_list = ["faafaf","ffe8a9","93eaae"]
var activate_list:Array=[
	[Vector2(-140,-128),Vector2(-57,-126),Vector2(11,-126),Rect2(0,256,224,50)],
	[Vector2(-125,-126),Vector2(-72,-128),Vector2(11,-126),Rect2(0,306,224,50)],
	[Vector2(-125,-126),Vector2(-57,-126),Vector2(-4,-128),Rect2(0,356,224,50)]
]

func _ready():
	update_state(0)  # 默认激活第一个
	rest_state(0)

func update_state(index:int) -> void:
	for i in range(labels.size()):
		var lbl = labels[i]
		if i == index:
			lbl.add_theme_color_override("font_color", color_list[2])
			lbl.add_theme_font_size_override("font_size", font_size[1])
			lbl.size = label_size[1]
		else:
			lbl.add_theme_color_override("font_color", color_list[0])
			lbl.add_theme_font_size_override("font_size", font_size[0])
			lbl.size = label_size[0]
		lbl.position = activate_list[index][i]
	# 更新背景
	head_back_ground.texture.region = activate_list[index][3]

func rest_state(index:int) -> void:
	labels[index].add_theme_color_override("font_color", color_list[1])

func _on_course_mouse_entered() -> void:
	update_state(0)
func _on_work_mouse_entered() -> void:
	update_state(1)
func _on_rest_mouse_entered() -> void:
	update_state(2)
func _on_course_mouse_exited() -> void:
	rest_state(0)
func _on_work_mouse_exited() -> void:
	rest_state(1)
func _on_rest_mouse_exited() -> void:
	rest_state(2)

# 鼠标悬停在按钮上时调用
# 悬停时移动选框
#func on_button_hovered(_button: Button,i:int):
	##print("鼠标悬浮在按钮上: ", button.name)
	#choice_high_light.position.y = choice_highlight_start.y + i * base_heigh
	#choice_high_light.show()
#
## 鼠标离开按钮时调用
## 离开时隐藏选框
#func on_button_unhovered(_button: Button,_i:int):
	##print("鼠标离开按钮: ", button.name)
	#choice_high_light.hide()
#
### 加载按钮,一次全加载出来算了……没用到的直接hide
#func LoadChoices() -> void:
	#for i in range(max_item_nums):
		#var new_choice:Button
		#if i == 0:
			#new_choice = $GridContainer/Button0
		#else:
			#new_choice = $GridContainer/Button0.duplicate()
			#new_choice.name = "Button" + str(i)
			#$GridContainer.add_child(new_choice)
		#new_choice.pressed.connect(func():on_choice_pressed(i))
		## 连接鼠标进入信号，同时传递按钮和索引
		#new_choice.mouse_entered.connect(func(): on_button_hovered(new_choice, i))
		## 连接鼠标离开信号（可选）
		#new_choice.mouse_exited.connect(func(): on_button_unhovered(new_choice, i))
