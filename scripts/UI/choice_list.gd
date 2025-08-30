extends Node2D

var choice_list:Array = ["打招呼","温柔地说话","严厉地说话","给零用钱"]

# 基本位移量
var base_heigh:int = 24
var base_choice:int = 1

func init(p_choice_list) -> Array:
	if p_choice_list.size() > 0:
		choice_list = p_choice_list
	return LoadChoices()

func LoadChoices() -> Array:
	var choice_nums:int = len(choice_list)
	var choice_node_list:Array = []
	$NinePatchRect.size.y = choice_nums * base_heigh
	$NinePatchRect/GridContainer.size.y = $NinePatchRect.size.y
	$Buttom.position.y = $NinePatchRect.size.y + base_heigh
	for i in range(base_choice,choice_nums):
		var new_choice = $NinePatchRect/GridContainer/Choice0.duplicate()
		new_choice.name = "Choice" + str(i)
		$NinePatchRect/GridContainer.add_child(new_choice)
	for i in range(choice_nums):
		# 获取所有的选项
		var temp_node = $NinePatchRect/GridContainer.get_node("Choice"+str(i))
		temp_node.text = choice_list[i]
		choice_node_list.append(temp_node)
	return choice_node_list
