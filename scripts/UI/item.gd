extends Node2D


@onready var ui: CanvasLayer = $".."
@onready var dautghter_live: Node2D = $"../../DautghterLive"


# 基本位移量
var base_heigh:int = 38
var base_choice:int = 1
# 道具数量显示上限
# 由于素材只给了5个，所以先写死5个，后续可以用多选框的思路进行扩展
static var max_item_nums:int = 5
var start_index:int = 0
var item_nums:int = 1

@onready var grid_container: GridContainer = $GridContainer

# 初始选框的位置
var choice_highlight_start:Vector2 = Vector2(19.5,-83)
@onready var choice_high_light: Sprite2D = $ChoiceHighLight

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	item_nums = len(Inventory.slots)
	choice_high_light.hide()
	$Cancel.pressed.connect(func() -> void:
			ui._on_cancel_button_down()
	)
	# 加载选项
	LoadChoices()
	# 获取所有子节点（按钮）并连接信号
	UpdateChoice()
	#var buttons = grid_container.get_children()
		

# 鼠标悬停在按钮上时调用
# 悬停时移动选框
func on_button_hovered(_button: Button,i:int):
	#print("鼠标悬浮在按钮上: ", button.name)
	choice_high_light.position.y = choice_highlight_start.y + i * base_heigh
	choice_high_light.show()

# 鼠标离开按钮时调用
# 离开时隐藏选框
func on_button_unhovered(_button: Button,_i:int):
	#print("鼠标离开按钮: ", button.name)
	choice_high_light.hide()

func on_button_pressed(_button:Button,item:Item):
	print(item.name)
	if item.types == Item.ItemType.CLOTHES:
		ui.CloseCanvas()
		dautghter_live.ChangeClothes(item.name)

## 加载按钮,一次全加载出来算了……没用到的直接hide
func LoadChoices() -> void:
	$GridContainer.size.y = max_item_nums * base_heigh
	for i in range(1,max_item_nums):
		var new_choice = $GridContainer/Button0.duplicate()
		new_choice.name = "Button" + str(i)
		$GridContainer.add_child(new_choice)

## 更新选项并且更新函数事件
func UpdateChoice() -> void:
	var choice_nums:int = min(item_nums-start_index,max_item_nums)
	var temp_node:Button
	for i in range(choice_nums):
		# 获取所有的选项
		temp_node = $GridContainer.get_node("Button"+str(i))
		temp_node.show()
		temp_node.text = Inventory.slots[i]["item"].name
		temp_node.get_node("Label").text = str(Inventory.slots[i]["item"].prices) + " G"
		temp_node.pressed.connect(func():on_button_pressed(temp_node,Inventory.slots[i]["item"]))
		# 连接鼠标进入信号，同时传递按钮和索引
		temp_node.mouse_entered.connect(func(): on_button_hovered(temp_node, i))
		# 连接鼠标离开信号（可选）
		temp_node.mouse_exited.connect(func(): on_button_unhovered(temp_node, i))
	for i in range(choice_nums,max_item_nums):
		temp_node = $GridContainer.get_node("Button"+str(i))
		temp_node.hide()

func _on_next_pressed() -> void:
	start_index += 5
	UpdateChoice()

func _on_previous_pressed() -> void:
	start_index -= 5
	UpdateChoice()
