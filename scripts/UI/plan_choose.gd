extends Node2D

@onready var labels:Array = [$HeadConsole/Course,$HeadConsole/Work,$HeadConsole/Rest]
@onready var grids:Array = [$GrideConsole/CourseGridContainer, $GrideConsole/WorkGridContainer, $GrideConsole/RestGridContainer]
@onready var head_back_ground: TextureRect = $HeadConsole/HeadBackGround
@onready var choose_high_light: AnimatedSprite2D = $GrideConsole/ChooseHighLight

# 详细信息
@onready var plan_info: Node2D = $PlanInfo
@onready var category_name: Label = $PlanInfo/CategoryName
@onready var num: Label = $PlanInfo/Num

@onready var colors:Dictionary = {
	"up":Color("#a0d4ff"),
	"down":Color("#ffb3a0"),
	"normal":Color("#a0ffda")
}

signal plan_click(plan_button:TextureButton)
signal cancel_click

var choose_high_light_start_pos:Vector2

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

var course_levels = ["初级","中级","高级","专家"]

func _ready():
	plan_info.hide()
	# 枚举所有按钮，增加选框移动事件
	for grid_container in grids:
		for button in grid_container.get_children():
			if button is TextureButton:
				button.mouse_entered.connect(func(): on_button_hovered(button))
				button.mouse_exited.connect(func(): on_button_unhovered(button))
				button.pressed.connect(func():on_button_click(button))
	choose_high_light.hide()
	choose_high_light_start_pos = choose_high_light.position
	update_state(0)  # 默认激活第一个
	rest_state(0)
	UpdateCategoryStatus()

# 更新按钮状态
func UpdateCategoryStatus() -> void:
	for grid_container in grids:
		for button in grid_container.get_children():
			if Global.category_stage[button.name][0] == -1:
				button.hide()
			else:
				button.show()
	
func on_button_click(button:TextureButton):
	choose_high_light.play("click")
	emit_signal("plan_click",button)

# 鼠标悬停事件
func on_button_hovered(button:TextureButton):
	choose_high_light.show()
	plan_info.show()
	choose_high_light.position = choose_high_light_start_pos + button.position
	category_name.text = Globaljson.category_translation[button.name]
	var category_dict:Dictionary
	if activate_index == 0:
		var category_stage = Global.category_stage[button.name][0]
		category_dict = Globaljson.category_data[button.name]["level"+str(category_stage)]
		category_name.text += "  " + course_levels[category_stage]
	else:
		category_dict = Globaljson.category_data[button.name]["level0"]
	if category_dict["money"] > 0:
		num.add_theme_color_override("font_color",colors["up"])
	elif category_dict["money"] < 0:
		num.add_theme_color_override("font_color",colors["down"])
	else:
		num.add_theme_color_override("font_color",colors["normal"])
	num.text = str(int(category_dict["money"]))

func on_button_unhovered(_button:TextureButton):
	choose_high_light.hide()
	plan_info.hide()

func update_state(index:int) -> void:
	activate_index = index
	for i in range(labels.size()):
		var lbl = labels[i]
		if i == index:
			lbl.add_theme_color_override("font_color", color_list[2])
			lbl.add_theme_font_size_override("font_size", font_size[1])
			lbl.set_deferred("size", label_size[1])
			grids[i].show()
		else:
			lbl.add_theme_color_override("font_color", color_list[0])
			lbl.add_theme_font_size_override("font_size", font_size[0])
			lbl.set_deferred("size", label_size[0])
			grids[i].hide()
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

func _on_cancel_pressed() -> void:
	emit_signal("cancel_click")
