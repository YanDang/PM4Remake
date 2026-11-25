extends SceneTree

# godot --headless --path . --script res://tests/clothing_test.gd
# Remove --headless and add -- --capture for screenshots.
var test_directory: String
var manager: Node

func _initialize() -> void:
	call_deferred("Run")

func FindChoice(list: Node, text: String) -> Button:
	for button in list.get_node("NinePatchRect/GridContainer").get_children():
		if button is Button and button.visible and button.text == text:
			return button
	return null

func Capture(filename: String) -> void:
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("TEMP").path_join(filename))

func DrainDialogue(dialogue: Node) -> void:
	for attempt in range(20):
		if not dialogue.visible or dialogue.settle != dialogue.SettleType.NULL:
			return
		if dialogue.is_revealing_text:
			dialogue.FinishTextReveal()
		else:
			dialogue.TalkPolling()
		await process_frame

func ShowPurchaseChoice(dialogue: Node) -> void:
	await DrainDialogue(dialogue)
	assert(dialogue.settle == dialogue.SettleType.CHOICE)
	dialogue.FinishTextReveal()
	await process_frame

func ChooseInventoryItem(panel: Node, id: String) -> void:
	var slots = root.get_node("Inventory").slots
	for index in range(slots.size()):
		if slots[index]["item"].id == id:
			panel.start_index = (index / 5) * 5
			panel.UpdateChoice()
			panel.grid_container.get_node("Button%d" % (index % 5)).pressed.emit()
			return
	assert(false, "Missing inventory item: " + id)

func FinishEquip(dialogue: Node, attributes: Node) -> void:
	dialogue.FinishTextReveal()
	await create_timer(0.35).timeout
	if attributes.visible:
		attributes.AnnotationEnd()
		await create_timer(0.3).timeout
	else:
		await DrainDialogue(dialogue)

func Run() -> void:
	create_timer(35.0).timeout.connect(func():
		push_error("Clothing regression test timed out")
		Cleanup()
		quit(1))
	manager = root.get_node("SaveManager")
	test_directory = "user://test_clothing_%d" % OS.get_process_id()
	manager.save_directory = test_directory
	var global = root.get_node("Global")
	var daughter = root.get_node("Daughterstatus")
	var inventory = root.get_node("Inventory")
	var data = root.get_node("Globaljson")
	var clothing = root.get_node("Clothing")
	data.home_event_data = {}
	global.money = 2000
	inventory.slots = []
	for id in ["c01", "c05", "c06", "c07"]:
		inventory.AddItem(id)
	var base_attributes = daughter.attributes.duplicate(true)
	change_scene_to_file("res://sences/main.tscn")
	await scene_changed
	await process_frame
	var main = current_scene
	var ui = main.get_node("UI")
	var street = ui.get_node("Street")
	var shop = main.get_node("StreetShop/ShopPanel")
	var dialogue = main.get_node("TalkLayer")
	var attributes = main.get_node("Arrtibute")
	var preview = main.get_node("StreetShop/ClothingPreview")

	ui.get_node("DailyAction/Street").button_down.emit()
	await create_timer(1.3).timeout
	FindChoice(street.street, "洋装店").pressed.emit()
	await DrainDialogue(dialogue)
	await create_timer(0.4).timeout
	assert(shop.visible and shop.interaction_enabled and ui.now_canvas_type == ui.CanvasType.SHOP)
	shop.grid_container.get_node("Button1").mouse_entered.emit()
	assert(ui.item_info.info_text.text == "〔冬服〕\n对抗寒冷的冬服\n就算寒流来袭也不要紧")
	await Capture("pm4-clothes-description.png")

	# Clicking Winter previews only Winter: duplicated rows must not buy row zero.
	shop.grid_container.get_node("Button1").pressed.emit()
	assert(street.pending_clothing.id == "c03" and preview.visible)
	assert(not shop.interaction_enabled and not ui.item_info.visible)
	assert(global.money == 2000 and inventory.GetItemCount("c02") == 0 and inventory.GetItemCount("c03") == 0)
	assert(daughter.attributes == base_attributes and daughter.current_clothes_id == "01")
	assert(dialogue.talk_text.text.contains("这是冬天的服装"))
	assert(preview.get_node("Body").texture.atlas.resource_path.ends_with("ch01c03.png"))
	dialogue.FinishTextReveal()
	await Capture("pm4-clothes-preview.png")
	await ShowPurchaseChoice(dialogue)
	assert(FindChoice(dialogue.choice_ui, "购买") != null)
	assert(FindChoice(dialogue.choice_ui, "不买") != null)
	await Capture("pm4-clothes-purchase-choice.png")
	FindChoice(dialogue.choice_ui, "不买").pressed.emit()
	assert(dialogue.talk_text.text == "请慢慢挑选。" and not preview.visible)
	assert(global.money == 2000 and inventory.GetItemCount("c03") == 0)
	await DrainDialogue(dialogue)
	assert(shop.interaction_enabled and street.pending_clothing == null)

	# Confirmed purchases deduct money once, add only that item, and grant no stats.
	shop.grid_container.get_node("Button2").pressed.emit()
	await ShowPurchaseChoice(dialogue)
	FindChoice(dialogue.choice_ui, "购买").pressed.emit()
	assert(dialogue.talk_text.text == "感谢购买。" and preview.visible)
	assert(global.money == 1500 and inventory.GetItemCount("c04") == 1)
	assert(inventory.GetItemCount("c02") == 0 and daughter.attributes == base_attributes)
	assert(not attributes.visible)
	await DrainDialogue(dialogue)

	shop.grid_container.get_node("Button3").pressed.emit()
	await ShowPurchaseChoice(dialogue)
	FindChoice(dialogue.choice_ui, "购买").pressed.emit()
	assert(dialogue.talk_text.text.contains("预算"))
	assert(global.money == 1500 and inventory.GetItemCount("c05") == 1)
	await DrainDialogue(dialogue)

	# Escape during preview cancels the transaction rather than leaving the shop.
	shop.grid_container.get_node("Button1").pressed.emit()
	var cancel_event = InputEventAction.new()
	cancel_event.action = "cancel"
	cancel_event.pressed = true
	root.push_input(cancel_event)
	await process_frame
	assert(dialogue.talk_text.text == "请慢慢挑选。")
	assert(global.money == 1500 and inventory.GetItemCount("c03") == 0)
	await DrainDialogue(dialogue)

	# Selling unworn clothing removes no attribute bonus.
	shop.InitPanel(inventory.slots, shop.ShopMode.SELL)
	for index in range(shop.shop_slots.size()):
		if shop.shop_slots[index]["item"].id == "c05":
			shop.on_choice_pressed(index)
			break
	assert(inventory.GetItemCount("c05") == 0 and daughter.attributes == base_attributes)
	inventory.AddItem("c05")
	shop.cancel.pressed.emit()
	await create_timer(0.4).timeout
	await DrainDialogue(dialogue)
	await create_timer(1.0).timeout
	assert(not street.item_shop.visible and ui.now_canvas_type == ui.CanvasType.MAIN)

	# Inventory equip shows the changed outfit, narrator text and a single stat delta.
	var panel = ui.item_panel
	inventory.AddItem("c03")
	ui.get_node("DailyAction/Item").button_down.emit()
	await create_timer(0.95).timeout
	ChooseInventoryItem(panel, "c03")
	await create_timer(0.95).timeout
	assert(dialogue.talk_text.text == "换成冬季服了。" and not attributes.visible)
	assert(daughter.attributes == base_attributes)
	await DrainDialogue(dialogue)
	assert(not panel.is_using_item and ui.now_canvas_type == ui.CanvasType.MAIN)
	ui.get_node("DailyAction/Item").button_down.emit()
	await create_timer(0.95).timeout
	ChooseInventoryItem(panel, "c04")
	await create_timer(0.95).timeout
	assert(daughter.attributes["highclass"] == float(base_attributes["highclass"]) + 15.0)
	assert(daughter.clothing_bonus["highclass"] == 15.0)
	assert(dialogue.talk_text.text == "换成洋装了。")
	assert(ui.daughter_live.current_clothes == "洋装")
	assert(ui.daughter_live.body.texture.atlas.resource_path.ends_with("ch01c04.png"))
	dialogue.FinishTextReveal()
	await create_timer(0.35).timeout
	assert(attributes.visible and daughter.attributes["highclass"] == float(base_attributes["highclass"]) + 15.0)
	await Capture("pm4-clothes-equipped.png")
	attributes.AnnotationEnd()
	await create_timer(0.3).timeout
	assert(not panel.is_using_item and ui.now_canvas_type == ui.CanvasType.MAIN)

	# Same outfit and wrong-age outfits show dialogue without changing anything.
	ui.get_node("DailyAction/Item").button_down.emit()
	await create_timer(0.95).timeout
	ChooseInventoryItem(panel, "c04")
	assert(dialogue.talk_text.text == "是现在穿着的衣服喔。")
	await DrainDialogue(dialogue)
	assert(ui.now_canvas_type == ui.CanvasType.ITEM)
	ChooseInventoryItem(panel, "c06")
	assert(dialogue.talk_text.text.contains("尺寸"))
	assert(daughter.current_clothes_id == "04")
	await DrainDialogue(dialogue)
	ChooseInventoryItem(panel, "c05")
	await create_timer(0.95).timeout
	await FinishEquip(dialogue, attributes)
	assert(daughter.attributes["highclass"] == float(base_attributes["highclass"]) + 40.0)
	assert(daughter.clothing_bonus["highclass"] == 40.0)

	# The saved contribution survives load; taking the outfit off removes it once.
	assert(manager.SaveSlot(0) == OK)
	clothing.Equip("c01")
	assert(daughter.attributes["highclass"] == base_attributes["highclass"])
	assert(manager.LoadSlot(0) == OK)
	assert(daughter.clothing_bonus["highclass"] == 40.0)
	change_scene_to_file("res://sences/main.tscn")
	await scene_changed
	await process_frame
	assert(current_scene.get_node("DaughterLive").current_clothes == "丝质洋装")
	assert(daughter.attributes["highclass"] == float(base_attributes["highclass"]) + 40.0)
	clothing.Equip("c04")
	assert(daughter.attributes["highclass"] == float(base_attributes["highclass"]) + 15.0)
	clothing.Equip("c01")
	assert(daughter.attributes["highclass"] == base_attributes["highclass"])
	clothing.Equip("c04")
	daughter.AddAttribute("highclass", 5.0)
	clothing.Equip("c05")
	assert(daughter.attributes["highclass"] == float(base_attributes["highclass"]) + 45.0)
	clothing.Equip("c01")
	assert(daughter.attributes["highclass"] == float(base_attributes["highclass"]) + 5.0)

	# Bounds and negative bonuses remain reversible without repeated-equip exploits.
	daughter.attributes["highclass"] = 990.0
	clothing.Equip("c05")
	assert(daughter.attributes["highclass"] == 999.0 and daughter.clothing_bonus["highclass"] == 9.0)
	clothing.Equip("c04")
	assert(daughter.attributes["highclass"] == 999.0)
	clothing.Equip("c01")
	assert(daughter.attributes["highclass"] == 990.0)
	daughter.attributes["charm"] = 2.0
	clothing.Equip("c07")
	assert(daughter.attributes["charm"] == 0.0)
	assert(clothing.Equip("c07")["error"] == ERR_ALREADY_IN_USE)
	clothing.Equip("c01")
	assert(daughter.attributes["charm"] == 2.0)
	assert(daughter.attributes["martial"] == base_attributes["martial"])

	# Pre-equipment version-1 records remain readable without silently changing stats.
	var legacy = manager.ReadSlot(0)
	legacy["state"]["daughter"].erase("clothing_bonus")
	var file = FileAccess.open(manager.SlotPath(1), FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	assert(manager.GetSlotInfo(1)["valid"])
	assert(manager.ReadSlot(1)["state"]["daughter"]["clothing_bonus"].is_empty())
	print("PASS: clothing hints/preview/dialogue, decline, confirmed purchase, insufficient funds, sale, equip bonuses, age checks, caps and save/load")
	Cleanup()
	quit()

func Cleanup() -> void:
	for index in range(2):
		var path = ProjectSettings.globalize_path(test_directory.path_join("slot_%02d.json" % (index + 1)))
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_directory))
