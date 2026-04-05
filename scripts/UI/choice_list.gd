extends Node2D

var choice_list:Array

# 基本位移量
var base_heigh:int = 24
var base_choice:int = 1
var original_position: Vector2

func _ready() -> void:
	original_position = self.position
	$NinePatchRect/GridContainer.columns = 1

func init(p_choice_list) -> void:
	self.position = original_position
	if p_choice_list.size() > 0:
		choice_list = p_choice_list
	LoadChoices()

func LoadChoices() -> void:
	# 删除旧的按钮（保留模板 Choice0）
	for child in $NinePatchRect/GridContainer.get_children():
		if child.name.begins_with("Choice") and child != $NinePatchRect/GridContainer/Choice0:
			$NinePatchRect/GridContainer.remove_child(child)
			child.queue_free()

	var choice_nums: int = choice_list.size()
	$NinePatchRect.size.y = choice_nums * base_heigh
	$NinePatchRect/GridContainer.size.y = $NinePatchRect.size.y
	$Buttom.position.y = $NinePatchRect.size.y + base_heigh

	for i in range(choice_nums):
		var new_choice
		new_choice = $NinePatchRect/GridContainer/Choice0.duplicate()
		$NinePatchRect/GridContainer.add_child(new_choice)
		new_choice.name = "Choice" + str(i)
		new_choice.text = choice_list[i]
		new_choice.visible = true
		new_choice.pressed.connect(Callable(get_parent(), "_on_choice_pressed").bind(choice_list[i], i))
