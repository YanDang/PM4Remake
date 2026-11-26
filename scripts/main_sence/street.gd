extends Node

@onready var name_label: Label = $"../../StreetShop/ItemShop/ShopName/NameLabel"
@onready var shop_back_ground: TextureRect = $"../../StreetShop/ItemShop/ShopBackGround"
@onready var item_shop: Node2D = $"../../StreetShop/ItemShop"
@onready var shop_panel: Node2D = $"../../StreetShop/ShopPanel"
@onready var street: Node2D = $Street
@onready var talk_layer: CanvasLayer = $"../../TalkLayer"
@onready var ui: CanvasLayer = $".."
@onready var item_info: CanvasLayer = $"../../ItemInfo"
@onready var clothing_preview: Control = $"../../StreetShop/ClothingPreview"

# 道具店，洋装店，餐厅，教会，医院
@onready var shop_file_names:Array = ["bg08.png","bg10.png","bg09.png","bg12.png","bg13.png"]
@onready var shop_names:Array = ["item_shop","cloth_shop","food_shop","church","hospital"]

var conversation:Dictionary

var shop_name:String
var move_vector = Vector2(500,0)

var current_shop_index:int = -1
var current_shop_name:String
var pending_clothing: Item
var clothing_stage: String = ""
var shop_transitioning: bool = false

func LoadJsonData():
	conversation = JSON.parse_string(FileAccess.open("res://datajson/talkjson/shop/streetshop_data.json", FileAccess.READ).get_as_text())

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	LoadJsonData()
	shop_panel.cancel_pressed.connect(_on_shop_panel_cancel)
	shop_panel.clothing_selected.connect(PreviewClothing)

func _on_shop_panel_cancel():
	if pending_clothing != null or shop_transitioning:
		return
	shop_transitioning = true
	shop_panel.SetInteraction(false)
	var tween = get_tree().create_tween()
	item_info.hide()
	clothing_preview.hide()
	tween.tween_property(shop_panel, "position", shop_panel.position-2*move_vector, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func():
		shop_panel.hide())
	await tween.finished
	shop_transitioning = false
	
	if current_shop_index == 0:
		# 道具店重新显示商店对话选项
		talk_layer.RegisterCallback(ChoiceEvent)
		var next_talk = "normal"
		if conversation[current_shop_name].has("after_choice"):
			next_talk = "after_choice"
		talk_layer.TalkStart(conversation[current_shop_name][next_talk],2,{},ItemShopChoices())
	else:
		# 服装店和餐厅直接离开商店
		LeaveShopWithDialogue()

func _on_choice_pressed(_choice_text: String,choice_index:int):
	if SceneTransition.is_transitioning:
		return
	if choice_index == shop_names.size():
		if Global.IsHarvestMonth():
			ui.now_canvas_type = ui.CanvasType.TALK
			SceneTransition.ChangeScene(Global.HARVEST_SCENE)
		return
	current_shop_index = choice_index
	current_shop_name = shop_names[current_shop_index]
	ui.now_canvas_type = ui.CanvasType.TALK
	name_label.text = _choice_text
	shop_back_ground.texture = load("res://assets/sys/" + shop_file_names[choice_index])
	street.hide()
	ui.daughter_live.hide()
	item_shop.show()
	talk_layer.RegisterCallback(ChoiceEvent)
	
	var greeting_key = get_greeting_key()
	
	if current_shop_name == "hospital" and Daughterstatus.is_ill:
		talk_layer.RegisterCallback(FinishHospitalVisit)
		talk_layer.TalkStart(Daughterstatus.HOSPITAL_TREATMENT)
	elif choice_index == 0:
		talk_layer.TalkStart(conversation[current_shop_name][greeting_key],2,{},ItemShopChoices())
	else:
		talk_layer.TalkStart(conversation[current_shop_name][greeting_key],0)

func FinishHospitalVisit(choice_index: int) -> void:
	Daughterstatus.FinishHospitalTreatment(choice_index)
	ui.health_stat.UpdateStatus()
	LeaveShopWithDialogue()
func LeaveShopWithDialogue():
	if conversation[current_shop_name].has("leave"):
		talk_layer.RegisterCallback(func(_idx): LeaveShop())
		talk_layer.TalkStart(conversation[current_shop_name]["leave"], 0)
	else:
		LeaveShop()

func LeaveShop():
	item_shop.hide()
	clothing_preview.hide()
	ui.daughter_live.show()
	ui.now_canvas_type = ui.CanvasType.STREET
	ui.CloseCanvas()
	
func get_greeting_key() -> String:
	if not Global.visited_shops.has(current_shop_name):
		Global.visited_shops[current_shop_name] = true
		return "first_time"
	return "normal"
func ItemShopChoices() -> Array:
	var choices := ["购买物品", "卖出物品", "离开商店"]
	if Inventory.HasItem("o15"):
		choices.append("珍品柜台")
	return choices

func ChoiceEvent(_choice_index:int):
	# 4是医院，它们没有购买面板，结束对话直接离开
	if current_shop_index >= 4:
		LeaveShopWithDialogue()
		return
	if _choice_index == 3 and (current_shop_name != "item_shop" or not Inventory.HasItem("o15")):
		return
		
	match _choice_index:
		0, 3:
			var stock := "rare_shop" if _choice_index == 3 else current_shop_name
			shop_transitioning = true
			var tween = get_tree().create_tween()  # 创建一个 Tween
			tween.tween_callback(func():
				shop_panel.show()
				item_info.show()
				shop_panel.InitPanel(Globaljson.shop_items[stock], 0)
				shop_panel.SetInteraction(false)) # BUY mode
			tween.tween_property(shop_panel, "position", shop_panel.position+2*move_vector, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			await tween.finished
			shop_panel.SetInteraction(true)
			ui.now_canvas_type = ui.CanvasType.SHOP
			shop_transitioning = false
		1:
			shop_transitioning = true
			var tween = get_tree().create_tween()  # 创建一个 Tween
			tween.tween_callback(func():
				shop_panel.show()
				item_info.show()
				shop_panel.InitPanel(Inventory.slots, 1)
				shop_panel.SetInteraction(false)) # SELL mode
			tween.tween_property(shop_panel, "position", shop_panel.position+2*move_vector, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			await tween.finished
			shop_panel.SetInteraction(true)
			ui.now_canvas_type = ui.CanvasType.SHOP
			shop_transitioning = false
		2:
			LeaveShopWithDialogue()

func PreviewClothing(item: Item) -> void:
	if pending_clothing != null or shop_transitioning:
		return
	pending_clothing = item
	clothing_stage = "preview"
	shop_panel.SetInteraction(false)
	item_info.hide()
	clothing_preview.ShowItem(item)
	talk_layer.RegisterCallback(ShowClothingPurchaseChoice)
	talk_layer.TalkStart(Clothing.GetShopDialogue(item))

func ShowClothingPurchaseChoice(_index: int) -> void:
	clothing_stage = "choice"
	talk_layer.RegisterCallback(ChooseClothing)
	talk_layer.TalkStart(Clothing.data["purchase_prompt"], talk_layer.SettleType.CHOICE, {}, ["购买", "不买"], true)

func ChooseClothing(index: int) -> void:
	if pending_clothing == null or clothing_stage == "feedback":
		return
	clothing_stage = "feedback"
	var response = "decline"
	if index == 0:
		if Global.money < pending_clothing.prices:
			response = "no_money"
		elif Inventory.AddItem(pending_clothing.id):
			Global.money -= pending_clothing.prices
			ui.money.UpdateStatus()
			ui.base_info.UpdateStatus()
			response = "purchase_success"
	if response == "decline":
		clothing_preview.hide()
	talk_layer.RegisterCallback(ResumeClothingBrowsing)
	talk_layer.TalkStart(Clothing.data[response])

func ResumeClothingBrowsing(_index: int = 0) -> void:
	var item = pending_clothing
	pending_clothing = null
	clothing_stage = ""
	clothing_preview.hide()
	shop_panel.SetInteraction(true)
	item_info.show()
	if item != null:
		item_info._on_item_panel_item_hovered_item(Clothing.GetDescription(item))
	ui.now_canvas_type = ui.CanvasType.SHOP

func _input(event: InputEvent) -> void:
	if pending_clothing != null and event.is_action_pressed("cancel"):
		get_viewport().set_input_as_handled()
		if clothing_stage == "feedback":
			talk_layer.TalkEnd()
		else:
			ChooseClothing(1)
	
