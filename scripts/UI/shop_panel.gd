extends Node2D

@onready var previous: Button = $Previous
@onready var next: Button = $Next
@onready var cancel: Button = $Cancel
@onready var money: Sprite2D = $"../../UI/Money"
@onready var shop_stat: Label = $ShopStat
@onready var daughter_live: Node2D = $"../../DaughterLive"

# 基本位移量
var base_heigh:int = 38
var base_choice:int = 1
# 道具数量显示上限
# 由于素材只给了5个，所以先写死5个，后续可以用多选框的思路进行扩展
static var max_item_nums:int = 5
var start_index:int = 0
var item_nums:int = 1

enum ShopMode { BUY, SELL }
var current_mode: ShopMode = ShopMode.BUY

# 物品类型名字
var type_name = ["clothes", "weapon", "armor", "food", "consumables", "other"]

@onready var grid_container: GridContainer = $GridContainer

# 初始选框的位置
var choice_highlight_start:Vector2 = Vector2(19.5,-83)
@onready var choice_high_light: Sprite2D = $ChoiceHighLight

# 将商店的库存写入
var shop_slots:Array

# 发射选择信号
signal item_hovered(item_description:String)
signal cancel_pressed

# Called when the node enters the scene tree for the first time
func InitPanel(this_shop_slots:Array, mode: int = ShopMode.BUY):
	current_mode = mode
	if current_mode == ShopMode.BUY:
		shop_slots = this_shop_slots
		shop_stat.text = "买 入"
	elif current_mode == ShopMode.SELL:
		Inventory.SortSlots()
		shop_slots = filter_sellable_items(this_shop_slots)
		shop_stat.text = "卖 出"
		
	item_nums = len(shop_slots)
	start_index = 0
	choice_high_light.hide()
	# 获取所有子节点（按钮）并更新
	UpdateChoice()
	
func filter_sellable_items(all_slots: Array) -> Array:
	var sellable_slots = []
	var current_clothes = ""
	if daughter_live:
		current_clothes = daughter_live.current_clothes
		
	for slot in all_slots:
		if slot["item"]:
			if slot["item"].important:
				continue
			if slot["item"].types == Item.ItemType.CLOTHES and slot["item"].name == current_clothes:
				continue
			sellable_slots.append(slot)
	return sellable_slots
	
func _ready():
	cancel.pressed.connect(func(): emit_signal("cancel_pressed"))
	# 初始化时只加载一次选项按钮
	LoadChoices()

func GetItem(i:int) -> Item:
	var slots_index = i + start_index
	var item:Item
	if slots_index < len(shop_slots):
		item = shop_slots[slots_index]["item"]
	return item

# 鼠标悬停在按钮上时调用
# 悬停时移动选框
func on_button_hovered(_button: Button,i:int):
	#print("鼠标悬浮在按钮上: ", button.name)
	choice_high_light.position.y = choice_highlight_start.y + i * base_heigh
	choice_high_light.show()
	var item:Item = GetItem(i)
	if item:
		print("hover_emit")
		emit_signal("item_hovered",item.description)

# 鼠标离开按钮时调用
# 离开时隐藏选框
func on_button_unhovered(_button: Button,_i:int):
	#print("鼠标离开按钮: ", button.name)
	choice_high_light.hide()
	emit_signal("item_hovered","")

func on_choice_pressed(i:int):
	var item:Item = GetItem(i)
	if item:
		if current_mode == ShopMode.BUY:
			if Global.money >= item.prices:
				Global.money -= item.prices
				Inventory.AddItem(item.id)
				print("购买成功: ", item.name)
				
				# 更新金钱UI
				if money:
					money.UpdateStatus()
			else:
				print("金钱不足，无法购买: ", item.name)
		elif current_mode == ShopMode.SELL:
			var sell_price = int(item.prices / 2)
			Global.money += sell_price
			Inventory.RemoveItem(item.id, 1)
			print("卖出成功: ", item.name)
			
			if money:
				money.UpdateStatus()
			RefreshPanel()

func RefreshPanel() -> void:
	if current_mode == ShopMode.SELL:
		Inventory.SortSlots()
		shop_slots = filter_sellable_items(Inventory.slots)
	
	item_nums = len(shop_slots)
	
	if start_index >= item_nums and start_index > 0:
		start_index -= max_item_nums
		if start_index < 0:
			start_index = 0
			
	UpdateChoice()

## 加载按钮,一次全加载出来算了……没用到的直接hide
func LoadChoices() -> void:
	grid_container.size.y = max_item_nums * base_heigh
	for i in range(max_item_nums):
		var new_choice:Button
		if i == 0:
			new_choice =  $GridContainer/Button0
		else:
			new_choice =  $GridContainer/Button0.duplicate()
			new_choice.name = "Button" + str(i)
			grid_container.add_child(new_choice)
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
		temp_node = grid_container.get_node("Button"+str(i))
		temp_node.show()
		
		var display_price = shop_slots[slots_index]["item"].prices
		var count_str = ""
		if current_mode == ShopMode.SELL:
			display_price = int(display_price / 2)
			count_str = " x" + str(shop_slots[slots_index]["count"])
			
		temp_node.text = shop_slots[slots_index]["item"].name + count_str
		temp_node.icon = load("res://animation/item/%s.tres" % type_name[shop_slots[slots_index]["item"].types])
		temp_node.get_node("Label").text = str(display_price) + " G"
	for i in range(choice_nums,max_item_nums):
		temp_node = grid_container.get_node("Button"+str(i))
		temp_node.hide()
	if start_index <= 0:
		previous.hide()
	else:
		previous.show()
	if start_index+max_item_nums >= item_nums:
		next.hide()
	else:
		next.show()

func _on_next_pressed() -> void:
	start_index += 5
	UpdateChoice()

func _on_previous_pressed() -> void:
	start_index -= 5
	UpdateChoice()
