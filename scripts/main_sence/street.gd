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

func _on_choice_pressed(_choice_text: String,choice_index:int):
	current_shop_index = choice_index
	current_shop_name = shop_names[current_shop_index]
	ui.now_canvas_type = ui.CanvasType.TALK
	name_label.text = _choice_text
	shop_back_ground.texture = load("res://assets/sys/" + shop_file_names[choice_index])
	street.hide()
	item_shop.show()
	talk_layer.RegisterCallback(ChoiceEvent)
	if choice_index == 0:
		talk_layer.TalkStart(conversation[current_shop_name]['first_time'],2,{},["购买物品","卖出物品","离开商店"])
	else:
		talk_layer.TalkStart(conversation[current_shop_name]['first_time'],0)
func LeaveShop():
	item_shop.hide()
	ui.now_canvas_type = ui.CanvasType.STREET
	ui.CloseCanvas()
func ChoiceEvent(_choice_index:int):
	match _choice_index:
		0:
			var tween = get_tree().create_tween()  # 创建一个 Tween
			tween.tween_callback(func():
				shop_panel.show()
				item_info.show()
				shop_panel.InitPanel(Globaljson.shop_items[current_shop_name]))
			tween.tween_property(shop_panel, "position", shop_panel.position+2*move_vector, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		2:
			LeaveShop()
	
