extends Node

@onready var name_label: Label = $"../../StreetShop/ItemShop/ShopName/NameLabel"
@onready var shop_back_ground: TextureRect = $"../../StreetShop/ItemShop/ShopBackGround"
@onready var item_shop: Node2D = $"../../StreetShop/ItemShop"
@onready var street: Node2D = $Street
@onready var talk_layer: CanvasLayer = $"../../TalkLayer"
@onready var ui: CanvasLayer = $".."

# 道具店，洋装店，餐厅，教会，医院
@onready var shop_file_names:Array = ["bg08.png","bg10.png","bg09.png","bg12.png","bg13.png"]

var conversation:Dictionary

var shop_name:String

func LoadJsonData():
	conversation = JSON.parse_string(FileAccess.open("res://datajson/talkjson/shop/streetshop_data.json", FileAccess.READ).get_as_text())

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	LoadJsonData()

func _on_choice_pressed(_choice_text: String,choice_index:int):
	ui.now_canvas_type = ui.CanvasType.TALK
	name_label.text = _choice_text
	shop_back_ground.texture = load("res://assets/sys/" + shop_file_names[choice_index])
	street.hide()
	item_shop.show()
	talk_layer.RegisterCallback(ChoiceEvent)
	match choice_index:
		0:
			talk_layer.TalkStart(conversation['item_shop']['first_time'],2,{},["购买物品","卖出物品","离开商店"])
		1:
			talk_layer.TalkStart(conversation['cloth_shop']['first_time'],0)
		2:
			talk_layer.TalkStart(conversation['food_shop']['first_time'],0)
		3:
			talk_layer.TalkStart(conversation['church']['first_time'],0)
		4:
			talk_layer.TalkStart(conversation['hospital']['first_time'],0)
func ChoiceEvent(_choice_index:int):
	item_shop.hide()
	ui.now_canvas_type = ui.CanvasType.STREET
	ui.CloseCanvas()
