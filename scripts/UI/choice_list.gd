extends Node2D

var choice_list:Array

# 基本位移量
var base_heigh:int = 24
var base_choice:int = 1

func init(p_choice_list) -> void:
	if p_choice_list.size() > 0:
		choice_list = p_choice_list
	LoadChoices()

func LoadChoices() -> void:
	# 删除旧的按钮（保留模板 Choice0）
	for child in $NinePatchRect/GridContainer.get_children():
		if child.name.begins_with("Choice") and child != $NinePatchRect/GridContainer/Choice0:
			child.queue_free()

	var choice_nums: int = choice_list.size()
	$NinePatchRect.size.y = choice_nums * base_heigh
	$NinePatchRect/GridContainer.size.y = $NinePatchRect.size.y
	$Buttom.position.y = $NinePatchRect.size.y + base_heigh

	for i in range(choice_nums):
		var new_choice
		if i == 0:
			new_choice = $NinePatchRect/GridContainer/Choice0
		else:
			new_choice = $NinePatchRect/GridContainer/Choice0.duplicate()
			$NinePatchRect/GridContainer.add_child(new_choice)

		new_choice.name = "Choice" + str(i)
		new_choice.text = choice_list[i]
		if not new_choice.pressed.is_connected(Callable(get_parent(), "_on_choice_pressed").bind(choice_list[i], i)):
			new_choice.pressed.connect(Callable(get_parent(), "_on_choice_pressed").bind(choice_list[i], i))
