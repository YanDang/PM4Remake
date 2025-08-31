extends Node2D


@onready var ui: CanvasLayer = $".."
@onready var dautghter_live: Node2D = $"../../DautghterLive"


# 基本位移量
var base_heigh:int = 38
var base_choice:int = 1
# 道具数量显示上限
# 由于素材只给了5个，所以先写死5个，后续可以用多选框的思路进行扩展
static var max_item_nums = 5

@onready var grid_container: GridContainer = $GridContainer

# 初始选框的位置
var choice_highlight_start:Vector2 = Vector2(19.5,-83)
@onready var choice_high_light: Sprite2D = $ChoiceHighLight

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	choice_high_light.hide()
	$Cancel.pressed.connect(func() -> void:
			get_parent()._on_cancel_button_down()
	)
	# 加载选项
	LoadChoices()
	# 获取所有子节点（按钮）并连接信号
	var buttons = grid_container.get_children()
	for i in range(buttons.size()):
		# 连接鼠标进入信号，同时传递按钮和索引
		buttons[i].mouse_entered.connect(func(): on_button_hovered(buttons[i], i))
		# 连接鼠标离开信号（可选）
		buttons[i].mouse_exited.connect(func(): on_button_unhovered(buttons[i], i))
		# 点击触发事件
		buttons[i].pressed.connect(func():on_button_pressed(buttons[i],Inventory.slots[i]["item"]))

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
		var tween = get_tree().create_tween()  # 创建一个 Tween
		ui.CloseCanvas()
		dautghter_live.ChangeClothes(item.name)

## 加载按钮
func LoadChoices() -> void:
	var choice_nums:int = min(len(Inventory.slots),max_item_nums)
	$GridContainer.size.y = choice_nums * base_heigh
	for i in range(base_choice,choice_nums):
		var new_choice = $GridContainer/Button0.duplicate()
		new_choice.name = "Button" + str(i)
		$GridContainer.add_child(new_choice)
	for i in range(choice_nums):
		# 获取所有的选项
		var temp_node = $GridContainer.get_node("Button"+str(i))
		temp_node.text = Inventory.slots[i]["item"].name
		temp_node.get_node("Label").text = str(Inventory.slots[i]["item"].prices) + " G"
		#temp_node.pressed.connect(func() -> void:
			#get_parent()._on_choice_pressed(temp_node.text,i)
		#)
