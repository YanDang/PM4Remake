extends Node2D


@onready var ui: CanvasLayer = $".."
@onready var daughter_live: Node2D = $"../../DaughterLive"

@onready var previous: Button = $Previous
@onready var next: Button = $Next

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

# 发射退出信号
signal cancel_click

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	item_nums = len(Inventory.slots)
	choice_high_light.hide()
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
		daughter_live.ChangeClothes(item.name)

func on_choice_pressed(i:int):
	var slots_index = i + start_index
	if slots_index < len(Inventory.slots):
		var item:Item = Inventory.slots[slots_index]["item"]
		on_button_pressed($GridContainer.get_node("Button" + str(i)), item)

## 加载按钮,一次全加载出来算了……没用到的直接hide
func LoadChoices() -> void:
	$GridContainer.size.y = max_item_nums * base_heigh
	for i in range(max_item_nums):
		var new_choice:Button
		if i == 0:
			new_choice = $GridContainer/Button0
		else:
			new_choice = $GridContainer/Button0.duplicate()
			new_choice.name = "Button" + str(i)
			$GridContainer.add_child(new_choice)
		new_choice.pressed.connect(func():on_choice_pressed(i))
		# 连接鼠标进入信号，同时传递按钮和索引
		new_choice.mouse_entered.connect(func(): on_button_hovered(new_choice, i))
		# 连接鼠标离开信号（可选）
		new_choice.mouse_exited.connect(func(): on_button_unhovered(new_choice, i))

## 更新选项并且更新函数事件
func UpdateChoice() -> void:
	var choice_nums:int = min(item_nums-start_index,max_item_nums)
	var temp_node:Button
	var slots_index:int
	for i in range(choice_nums):
		slots_index = i + start_index
		# 获取所有的选项
		temp_node = $GridContainer.get_node("Button"+str(i))
		temp_node.show()
		temp_node.text = Inventory.slots[slots_index]["item"].name
		temp_node.get_node("Label").text = str(Inventory.slots[slots_index]["item"].prices) + " G"
	for i in range(choice_nums,max_item_nums):
		temp_node = $GridContainer.get_node("Button"+str(i))
		temp_node.hide()
	if start_index <= 0:
		previous.hide()
	else:
		previous.show()
	if start_index+max_item_nums > item_nums:
		next.hide()
	else:
		next.show()

func _on_next_pressed() -> void:
	start_index += 5
	UpdateChoice()

func _on_previous_pressed() -> void:
	start_index -= 5
	UpdateChoice()
	
func _on_cancel_pressed() -> void:
	emit_signal("cancel_click")
