extends SceneTree

var game: Node
var daughter: Node
var inventory: Node
var manager: Node
var transition: Node

func _initialize() -> void:
	call_deferred("Run")

func Run() -> void:
	create_timer(40.0).timeout.connect(func(): quit(1))
	game = root.get_node("Global")
	daughter = root.get_node("Daughterstatus")
	inventory = root.get_node("Inventory")
	manager = root.get_node("SaveManager")
	transition = root.get_node("SceneTransition")
	manager.save_directory = "user://harvest-test-%d" % OS.get_process_id()
	manager.StartNewGame()
	assert(await CheckAllowance())
	assert(await CheckShopBalanceWarning())
	assert(await CheckEquipmentAndTournament())
	DirAccess.remove_absolute(manager.SlotPath(0))
	DirAccess.remove_absolute(manager.SlotPath(1))
	DirAccess.remove_absolute(manager.save_directory)
	print("PASS: allowance, shop balance feedback, equipment, three annual contests, saved results, win, loss and withdrawal")
	quit()

func FindChoice(menu: Node, label: String) -> Button:
	for button in menu.get_node("NinePatchRect/GridContainer").get_children():
		if button is Button and button.visible and button.text == label:
			return button
	return null

func OpenRoom() -> void:
	manager.restoring_save = true
	change_scene_to_file("res://sences/main.tscn")
	await scene_changed
	await process_frame

func OpenMenu(button_name: String, canvas_type: int) -> void:
	var ui := current_scene.get_node("UI")
	ui.get_node("DailyAction/" + button_name).button_down.emit()
	while ui.now_canvas_type != canvas_type:
		await process_frame

func WaitForTransition() -> void:
	while transition.is_transitioning:
		await process_frame

func FinishDialogue(room: Node) -> void:
	var talk := room.get_node("TalkLayer")
	var annotation := room.get_node("Arrtibute")
	while talk.visible or annotation.visible:
		if annotation.visible:
			if annotation.annotation_visible:
				annotation.AnnotationEnd()
		else:
			talk.TalkPolling()
		await process_frame

func CheckAllowance() -> bool:
	await OpenRoom()
	var room := current_scene
	var ui := room.get_node("UI")
	var chat := room.get_node("TalkLayer")
	var before: Dictionary = daughter.attributes.duplicate()
	await OpenMenu("Talk", ui.CanvasType.DAILYTALK)
	for balance in [0, 49]:
		game.money = balance
		FindChoice(ui.talk, "给零用钱").pressed.emit()
		assert(chat.talk_text.text.contains("所持金不足"))
		assert(game.money == balance and not game.already_talk and daughter.attributes == before)
		await FinishDialogue(room)
		assert(ui.talk.visible and ui.now_canvas_type == ui.CanvasType.DAILYTALK)
	game.money = 50
	FindChoice(ui.talk, "给零用钱").pressed.emit()
	await FinishDialogue(room)
	assert(game.money == 0 and game.already_talk)
	assert(daughter.attributes["charm"] == before["charm"] + 5)
	return true

func CheckShopBalanceWarning() -> bool:
	manager.StartNewGame()
	await OpenRoom()
	var ui := current_scene.get_node("UI")
	var dialogue := current_scene.get_node("TalkLayer")
	await OpenMenu("Street", ui.CanvasType.STREET)
	FindChoice(ui.street, "道具店").pressed.emit()
	while not dialogue.choice_ui.visible:
		dialogue.TalkPolling()
		await process_frame
	FindChoice(dialogue.choice_ui, "购买物品").pressed.emit()
	while ui.now_canvas_type != ui.CanvasType.SHOP:
		await process_frame
	var shop := current_scene.get_node("StreetShop/ShopPanel")
	var item: Item = shop.GetItem(0)
	var button: Button = shop.grid_container.get_node("Button0")
	var count_before: int = inventory.GetItemCount(item.id)
	var money_before := item.prices - 1
	game.money = money_before
	button.pressed.emit()
	assert(shop.purchase_notice.is_visible_in_tree())
	assert(shop.purchase_notice.text.contains("余额不足"))
	assert(shop.purchase_notice.text.contains(str(item.prices) + " G"))
	assert(game.money == money_before and inventory.GetItemCount(item.id) == count_before)
	button.mouse_exited.emit()
	assert(shop.purchase_notice.visible and shop.interaction_enabled)
	shop.next.pressed.emit()
	assert(not shop.purchase_notice.visible)
	shop.previous.pressed.emit()
	button.pressed.emit()
	assert(shop.purchase_notice.visible)
	game.money = item.prices
	button.pressed.emit()
	assert(not shop.purchase_notice.visible and game.money == 0)
	assert(inventory.GetItemCount(item.id) == count_before + 1)
	return true

func OpenHarvest() -> Node:
	var ui := current_scene.get_node("UI")
	await OpenMenu("Street", ui.CanvasType.STREET)
	var choice := FindChoice(ui.street, "收获祭")
	assert(choice != null)
	choice.pressed.emit()
	await scene_changed
	await WaitForTransition()
	assert(current_scene.scene_file_path == game.HARVEST_SCENE)
	return current_scene

func ReturnToRoom(arena: Node) -> void:
	arena.back.pressed.emit()
	await scene_changed
	await WaitForTransition()
	assert(current_scene.scene_file_path == "res://sences/main.tscn")

func CheckEquipmentAndTournament() -> bool:
	manager.StartNewGame()
	await OpenRoom()
	var ui := current_scene.get_node("UI")
	assert(FindChoice(ui.street, "收获祭") == null)
	game.month = 9
	game.sync_calendar()
	daughter.attributes["stamina"] = 500
	daughter.attributes["martial"] = 300
	daughter.attributes["magic"] = 280
	inventory.AddItem("w02")
	inventory.AddItem("w06")
	inventory.AddItem("a02")
	await OpenRoom()
	ui = current_scene.get_node("UI")
	await OpenMenu("Item", ui.CanvasType.ITEM)
	var panel: Node = ui.item_panel
	for id in ["w02", "a02"]:
		while panel.GetItem(0) != null:
			var found := false
			for index in range(panel.max_item_nums):
				var item: Item = panel.GetItem(index)
				if item != null and item.id == id:
					var button: Button = panel.grid_container.get_node("Button" + str(index))
					button.pressed.emit()
					assert(button.text.contains("装备中"))
					found = true
					break
			if found:
				break
			assert(panel.next.visible)
			panel.next.pressed.emit()
	assert(daughter.equipped_gear == {"weapon": "w02", "armor": "a02"})
	var sellable: Array = current_scene.get_node("StreetShop/ShopPanel").filter_sellable_items(inventory.slots)
	assert(not sellable.any(func(slot): return slot["item"].id in ["w02", "a02"]))
	assert(manager.SaveSlot(0) == OK)
	var legacy: Dictionary = manager.ReadSlot(0)
	legacy["state"]["daughter"].erase("equipped_gear")
	var file := FileAccess.open(manager.SlotPath(1), FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	assert(manager.LoadSlot(1) == OK and daughter.equipped_gear == {"weapon": "", "armor": ""})
	assert(manager.LoadSlot(0) == OK and daughter.equipped_gear == {"weapon": "w02", "armor": "a02"})

	await OpenRoom()
	var arena := await OpenHarvest()
	assert(arena.player == {"hp": 106, "attack": 22, "magic": 18, "defense": 9, "magic_defense": 6})
	assert(arena.get_node("%PlayerGear").text.contains("铁制长剑"))
	var starting_money: int = game.money
	arena.start.pressed.emit()
	arena.get_node("%Guard").pressed.emit()
	assert(arena.guard_bonus == 6 and arena.rounds == 1)
	var rival_hp: int = arena.rival["hp"]
	arena.get_node("%Magic").pressed.emit()
	assert(arena.rival["hp"] == rival_hp - 21 and arena.guard_bonus == 0)
	while arena.competing:
		arena.get_node("%Physical").pressed.emit()
	assert(arena.RecordedResult() == "won")
	assert(game.money == starting_money + 150)
	arena.start.pressed.emit()
	assert(not arena.competing)
	arena.get_node("%GardenTab").pressed.emit()
	assert(arena.start.visible)
	arena.start.pressed.emit()
	assert(arena.entries.visible and arena.get_node("%StoryTab").disabled)
	arena.get_node("%Entry0").pressed.emit()
	assert(arena.RecordedResult() == "won" and arena.status.text.contains("得分"))
	assert(game.money == starting_money + 270)
	arena.get_node("%StoryTab").pressed.emit()
	assert(arena.start.visible)
	arena.start.pressed.emit()
	arena.get_node("%Entry0").pressed.emit()
	assert(arena.RecordedResult() == "lost")
	assert(game.money == starting_money + 270)
	await ReturnToRoom(arena)
	assert(game.month == 9 and game.day == 1)
	assert(manager.SaveSlot(0, true) == OK)
	assert(manager.LoadSlot(0) == OK)
	await OpenRoom()
	arena = await OpenHarvest()
	assert(not arena.start.visible and arena.RecordedResult() == "won")
	arena.get_node("%GardenTab").pressed.emit()
	assert(not arena.start.visible and arena.RecordedResult() == "won")
	arena.get_node("%StoryTab").pressed.emit()
	assert(not arena.start.visible and arena.RecordedResult() == "lost")
	await ReturnToRoom(arena)
	assert(game.money == starting_money + 270)

	game.year += 1
	await OpenRoom()
	arena = await OpenHarvest()
	assert(arena.start.visible)
	arena.start.pressed.emit()
	arena.back.pressed.emit()
	assert(arena.withdrawal.visible and arena.competing)
	arena.get_node("%KeepPlaying").pressed.emit()
	assert(not arena.withdrawal.visible and arena.actions.visible)
	arena.back.pressed.emit()
	arena.get_node("%ConfirmWithdrawal").pressed.emit()
	assert(arena.RecordedResult() == "withdrawn" and game.money == starting_money + 270)
	arena.get_node("%GardenTab").pressed.emit()
	assert(arena.start.visible)
	arena.start.pressed.emit()
	arena.back.pressed.emit()
	arena.get_node("%KeepPlaying").pressed.emit()
	assert(arena.entries.visible and not arena.withdrawal.visible)
	arena.back.pressed.emit()
	arena.get_node("%ConfirmWithdrawal").pressed.emit()
	assert(arena.RecordedResult() == "withdrawn" and game.money == starting_money + 270)
	await ReturnToRoom(arena)

	game.year = 1447
	daughter.attributes["stamina"] = 0
	daughter.attributes["magic"] = 0
	daughter.attributes["martial"] = 0
	assert(inventory.ToggleGear(root.get_node("Globaljson").items["w02"]))
	assert(inventory.ToggleGear(root.get_node("Globaljson").items["a02"]))
	await OpenRoom()
	arena = await OpenHarvest()
	arena.start.pressed.emit()
	while arena.competing:
		arena.get_node("%Physical").pressed.emit()
	assert(arena.RecordedResult() == "lost" and game.money == starting_money + 270)
	await ReturnToRoom(arena)
	return true
