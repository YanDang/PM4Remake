extends SceneTree

var game: Node
var daughter: Node
var items: Node
var inventory: Node
var saves: Node
var audio: Node

func _initialize() -> void:
	call_deferred("Run")

func Run() -> void:
	create_timer(35, true, false, true).timeout.connect(func(): quit(1))
	Engine.time_scale = 8.0
	game = root.get_node("Global")
	daughter = root.get_node("Daughterstatus")
	items = root.get_node("Globaljson")
	inventory = root.get_node("Inventory")
	saves = root.get_node("SaveManager")
	audio = root.get_node("GameSettings")
	saves.StartNewGame()
	assert(await CheckAudioAndShortcuts())
	assert(await CheckStock())
	assert(CheckInventoryStacks())
	assert(await CheckConsumeFromStack())
	assert(await CheckSchedule())
	print("PASS: audio, shortcuts, shop stock, unique purchases, inventory stacks, monthly effects, recovery and wage")
	quit()

func EnterScene(path: String) -> void:
	change_scene_to_file(path)
	await scene_changed
	await process_frame

func PressKey(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	root.push_input(event, true)

func CheckAudioAndShortcuts() -> bool:
	await EnterScene("res://sences/title.tscn")
	assert(audio.music_player.stream.resource_path.ends_with("/title.wav"))
	saves.restoring_save = true
	await EnterScene("res://sences/main.tscn")
	assert(audio.music_player.stream.resource_path.ends_with("/room.wav"))
	assert(audio.music_player.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD)
	PressKey(KEY_F5)
	PressKey(KEY_F6)
	assert(game.month == 4 and game.art_painting_level == 0)
	await EnterScene("res://sences/city.tscn")
	assert(audio.music_player.stream.resource_path.ends_with("/outing.wav"))
	for code in [KEY_1, KEY_2, KEY_3, KEY_4]:
		PressKey(code)
	assert(game.year == 1440 and daughter.age_stage == daughter.AgeStageType.CHILD)
	audio.PlayVoiceId("res://audio/music/title.wav")
	assert(audio.voice_player.stream.resource_path.ends_with("/title.wav"))
	audio.StopVoice()
	return true

func PressChoice(menu: Node, label: String) -> void:
	for button in menu.get_node("NinePatchRect/GridContainer").get_children():
		if button is Button and button.is_visible_in_tree() and button.text == label:
			button.pressed.emit()
			return
	assert(false, "Choice missing: " + label)

func CheckStock() -> bool:
	var available := {}
	for slot in inventory.slots:
		available[slot["item"].id] = true
	for catalogue in items.shop_items.values():
		for slot in catalogue:
			available[slot["item"].id] = true
	assert(available.size() == items.items.size())
	for id in ["w08", "w09", "w10"]:
		assert(items.items[id].combat_bonus["attack"] > 0)
	assert(items.items["w08"].combat_bonus["magic_defense"] == 1)

	saves.restoring_save = true
	await EnterScene("res://sences/main.tscn")
	var room := current_scene
	var ui := room.get_node("UI")
	var street := ui.get_node("Street")
	var shop := room.get_node("StreetShop/ShopPanel")
	var talk := room.get_node("TalkLayer")
	assert(not street.ItemShopChoices().has("珍品柜台"))
	game.month = 5
	shop.InitPanel(items.shop_items["item_shop"])
	assert(not shop.shop_slots.any(func(slot): return slot["item"].id in ["o13", "o14"]))
	game.month = daughter.birth_month
	shop.InitPanel(items.shop_items["item_shop"])
	assert(shop.shop_slots.any(func(slot): return slot["item"].id == "o13"))
	assert(shop.shop_slots.any(func(slot): return slot["item"].id == "o14"))

	ui.get_node("DailyAction/Street").button_down.emit()
	while ui.now_canvas_type != ui.CanvasType.STREET:
		await process_frame
	PressChoice(ui.street, "道具店")
	await RevealChoices(talk)
	PressChoice(talk.choice_ui, "购买物品")
	while not shop.interaction_enabled or not shop.visible:
		await process_frame
	while shop.next.visible:
		shop.next.pressed.emit()
	var license_found := false
	for index in range(shop.max_item_nums):
		var item: Item = shop.GetItem(index)
		if item and item.id == "o15":
			shop.grid_container.get_node("Button%d" % index).pressed.emit()
			license_found = inventory.HasItem("o15")
			break
	assert(license_found)
	shop.cancel.pressed.emit()
	while not talk.visible:
		await process_frame
	await RevealChoices(talk)
	PressChoice(talk.choice_ui, "珍品柜台")
	while not shop.interaction_enabled or not shop.visible:
		await process_frame
	assert(shop.GetItem(0).id == "w08")
	game.money = 20000
	var bought := {}
	while true:
		for index in range(shop.max_item_nums):
			var item: Item = shop.GetItem(index)
			if item == null or item.id not in ["o16", "o17", "o23"]:
				continue
			var button: Button = shop.grid_container.get_node("Button%d" % index)
			var old_money: int = game.money
			button.pressed.emit()
			assert(game.money == old_money - item.prices and inventory.GetItemCount(item.id) == 1)
			var attributes: Dictionary = daughter.attributes.duplicate()
			button.pressed.emit()
			assert(game.money == old_money - item.prices and inventory.GetItemCount(item.id) == 1)
			assert(daughter.attributes == attributes and shop.purchase_notice.is_visible_in_tree())
			assert(shop.purchase_notice.text.contains(item.name))
			bought[item.id] = true
		if not shop.next.visible:
			break
		shop.next.pressed.emit()
	assert(bought.size() == 3)
	var annotation := room.get_node("Arrtibute")
	if annotation.visible:
		annotation.AnnotationEnd()
		await annotation.settle_end
	return true

func CheckInventoryStacks() -> bool:
	inventory.RestoreSlots([{"id": "f01", "count": 2}, {"id": "w02", "count": 2}])
	var food: Item = items.items["f01"]
	var old_limit := food.max_stack
	food.max_stack = 3
	assert(inventory.AddItem("f01", 5))
	assert(inventory.GetItemCount("f01") == 7)
	assert(inventory.slots[0]["count"] == 3 and inventory.slots[3]["count"] == 3)
	assert(inventory.slots[4]["count"] == 1)
	assert(inventory.slots[1]["count"] == 1 and inventory.slots[2]["count"] == 1)
	assert(not inventory.RemoveItem("f01", 8) and inventory.GetItemCount("f01") == 7)
	var shop := current_scene.get_node("StreetShop/ShopPanel")
	shop.InitPanel(inventory.slots, shop.ShopMode.SELL)
	var money_before: int = game.money
	shop.grid_container.get_node("Button3").pressed.emit()
	assert(game.money == money_before + int(food.prices / 2))
	assert(inventory.slots[2]["count"] == 3 and inventory.slots[3]["count"] == 2)
	assert(inventory.ToggleGear(items.items["w02"]))
	assert(inventory.RemoveItem("w02") and inventory.IsEquippedGear(items.items["w02"]))
	assert(inventory.RemoveItem("w02") and not inventory.IsEquippedGear(items.items["w02"]))
	inventory.RestoreSlots([{"id": "f01", "count": 8}, {"id": "o16", "count": 2}])
	assert(inventory.GetItemCount("f01") == 8 and inventory.GetItemCount("o16") == 2)
	assert(inventory.slots[0]["count"] == 3 and inventory.slots[1]["count"] == 3 and inventory.slots[2]["count"] == 2)
	food.max_stack = old_limit
	return true

func CheckConsumeFromStack() -> bool:
	var food: Item = items.items["f01"]
	var old_limit := food.max_stack
	food.max_stack = 3
	inventory.RestoreSlots([{"id": "f01", "count": 5}])
	food.max_stack = old_limit
	saves.restoring_save = true
	await EnterScene("res://sences/main.tscn")
	var room := current_scene
	var ui := room.get_node("UI")
	var panel := ui.get_node("Item/ItemPanel")
	var annotation := room.get_node("Arrtibute")
	daughter.attributes["stress"] = 100
	ui.get_node("DailyAction/Item").button_down.emit()
	while ui.now_canvas_type != ui.CanvasType.ITEM:
		await process_frame
	panel.grid_container.get_node("Button1").pressed.emit()
	while not annotation.annotation_visible:
		await process_frame
	annotation.AnnotationEnd()
	await annotation.settle_end
	assert(inventory.slots[0]["count"] == 3 and inventory.slots[1]["count"] == 1)
	assert(daughter.attributes["stress"] == 50)
	return true

func RevealChoices(dialogue: Node) -> void:
	while not dialogue.choice_ui.visible:
		dialogue.TalkPolling()
		await process_frame

func CheckSchedule() -> bool:
	saves.StartNewGame()
	game.category_stage["casino"] = [0, 4]
	assert(game.GetDailyWage("casino") == 40)
	game.category_stage["casino"][1] = 5
	assert(game.GetDailyWage("casino") == 50)
	game.category_stage["casino"][1] = 100
	assert(game.GetDailyWage("casino") == 70)
	daughter.attributes["stress"] = 60
	daughter.attributes["crime"] = 10
	daughter.attributes["demonization"] = 20
	daughter.is_ill = true
	inventory.AddItem("o16", 2)
	inventory.AddItem("o17")
	inventory.AddItem("o23")
	saves.restoring_save = true
	await EnterScene("res://sences/main.tscn")
	var planner := current_scene.get_node("UI/PlanSchedule/PlanChoose")
	assert(planner.grids[2].get_node("recover").visible)

	game.month_plan = ["recover", "casino", "rest"]
	await EnterScene("res://sences/schedule.tscn")
	var schedule := current_scene
	var saw_recovery := false
	var saw_casino := false
	while is_instance_valid(schedule) and current_scene == schedule:
		if schedule.plan_name == "recover" and schedule.schd.visible:
			saw_recovery = true
			assert(schedule.schd.anim.sprite_frames.resource_path.ends_with("/recover.tres"))
		if schedule.plan_name == "casino" and schedule.schd.visible:
			saw_casino = true
			assert(schedule.schd.anim.sprite_frames.resource_path.ends_with("/casino.tres"))
			assert(not daughter.is_ill)
		var annotation := schedule.get_node("Arrtibute")
		var talk := schedule.get_node("TalkLayer")
		if annotation.visible and annotation.annotation_visible:
			annotation.AnnotationEnd()
		elif not annotation.visible and talk.visible:
			talk.TalkPolling()
		await process_frame
	while current_scene == null:
		await process_frame
	assert(saw_recovery and saw_casino and game.month == 5)
	assert(game.money > 2000 and (game.money - 2000) % 35 == 0)
	var casino_workdays := 0
	for date_day in range(11, 21):
		if game.get_weekday(1440, 4, date_day) != 0:
			casino_workdays += 1
	assert(daughter.attributes["demonization"] == 20 + casino_workdays)
	assert(daughter.attributes["crime"] == 11)
	assert(not current_scene.get_node("UI/PlanSchedule/PlanChoose").grids[2].get_node("recover").visible)

	daughter.attributes["stress"] = 24
	var previous_crime: float = daughter.attributes["crime"]
	inventory.ApplyMonthlyItemEffects()
	assert(daughter.attributes["stress"] == 14 and daughter.attributes["crime"] == previous_crime + 1)
	return true
