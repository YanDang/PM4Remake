extends Node

@onready var name_label: Label = $"../../StreetShop/ItemShop/ShopName/NameLabel"
@onready var shop_back_ground: TextureRect = $"../../StreetShop/ItemShop/ShopBackGround"
@onready var item_shop: Node2D = $"../../StreetShop/ItemShop"
@onready var shop_panel: Node2D = $"../../StreetShop/ShopPanel"
@onready var street: Node2D = $Street
@onready var talk_layer: CanvasLayer = $"../../TalkLayer"
@onready var ui: CanvasLayer = $".."
@onready var item_info: CanvasLayer = $"../../ItemInfo"

# 道具店，洋装店，餐厅，教会，医院
@onready var shop_file_names:Array = ["bg08.png","bg10.png","bg09.png","bg12.png","bg13.png"]
@onready var shop_names:Array = ["item_shop","cloth_shop","food_shop","church","hospital"]

var conversation:Dictionary

var shop_name:String
var move_vector = Vector2(500,0)

var current_shop_index:int = -1
var current_shop_name:String

func LoadJsonData():
	conversation = JSON.parse_string(FileAccess.open("res://datajson/talkjson/shop/streetshop_data.json", FileAccess.READ).get_as_text())

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	LoadJsonData()
	shop_panel.cancel_pressed.connect(_on_shop_panel_cancel)

func _on_shop_panel_cancel():
	var tween = get_tree().create_tween()
	item_info.hide()
	tween.tween_property(shop_panel, "position", shop_panel.position-2*move_vector, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func():
		shop_panel.hide())
	
	if current_shop_index == 0:
		# 道具店重新显示商店对话选项
		talk_layer.RegisterCallback(ChoiceEvent)
		var next_talk = "normal"
		if conversation[current_shop_name].has("after_choice"):
			next_talk = "after_choice"
		talk_layer.TalkStart(conversation[current_shop_name][next_talk],2,{},["购买物品","卖出物品","离开商店"])
	else:
		# 服装店和餐厅直接离开商店
		LeaveShopWithDialogue()

func _on_choice_pressed(_choice_text: String,choice_index:int):
	current_shop_index = choice_index
	current_shop_name = shop_names[current_shop_index]
	ui.now_canvas_type = ui.CanvasType.TALK
	name_label.text = _choice_text
	shop_back_ground.texture = load("res://assets/sys/" + shop_file_names[choice_index])
	street.hide()
	item_shop.show()
	talk_layer.RegisterCallback(ChoiceEvent)
	
	var greeting_key = get_greeting_key()
	
	if choice_index == 0:
		talk_layer.TalkStart(conversation[current_shop_name][greeting_key],2,{},["购买物品","卖出物品","离开商店"])
	else:
		talk_layer.TalkStart(conversation[current_shop_name][greeting_key],0)
func LeaveShopWithDialogue():
	if conversation[current_shop_name].has("leave"):
		talk_layer.RegisterCallback(func(_idx): LeaveShop())
		talk_layer.TalkStart(conversation[current_shop_name]["leave"], 0)
	else:
		LeaveShop()

func LeaveShop():
	item_shop.hide()
	ui.now_canvas_type = ui.CanvasType.STREET
	ui.CloseCanvas()
	
func get_greeting_key() -> String:
	if not Global.visited_shops.has(current_shop_name):
		Global.visited_shops[current_shop_name] = true
		return "first_time"
	return "normal"
func ChoiceEvent(_choice_index:int):
	# 4是医院，它们没有购买面板，结束对话直接离开
	if current_shop_index >= 4:
		LeaveShopWithDialogue()
		return
		
	match _choice_index:
		0:
			var tween = get_tree().create_tween()  # 创建一个 Tween
			tween.tween_callback(func():
				shop_panel.show()
				item_info.show()
				shop_panel.InitPanel(Globaljson.shop_items[current_shop_name], 0)) # BUY mode
			tween.tween_property(shop_panel, "position", shop_panel.position+2*move_vector, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		1:
			var tween = get_tree().create_tween()  # 创建一个 Tween
			tween.tween_callback(func():
				shop_panel.show()
				item_info.show()
				shop_panel.InitPanel(Inventory.slots, 1)) # SELL mode
			tween.tween_property(shop_panel, "position", shop_panel.position+2*move_vector, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		2:
			LeaveShopWithDialogue()
	
