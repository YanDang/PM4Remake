extends SceneTree

# godot --headless --path . --script res://tests/load_game_test.gd
# Run without --headless and add -- --capture for screenshots.
var manager: Node
var test_directory: String

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

func CancelInput() -> void:
	var event = InputEventAction.new()
	event.action = "cancel"
	event.pressed = true
	root.push_input(event)
	await process_frame

func Run() -> void:
	create_timer(25.0).timeout.connect(func():
		push_error("Load game regression test timed out")
		Cleanup()
		quit(1))
	manager = root.get_node("SaveManager")
	test_directory = "user://test_loads_%d" % OS.get_process_id()
	manager.save_directory = test_directory
	var global = root.get_node("Global")
	var daughter = root.get_node("Daughterstatus")
	var inventory = root.get_node("Inventory")
	var data = root.get_node("Globaljson")
	# A monthly event must not run again when loading an already saved month.
	data.home_event_data = {"monthly_events": [{
		"id": "load_test_home_event", "conditions": {}, "repeatable": true,
		"add_money": 999, "dialogue_script": [{"character": "", "text": "Unexpected event"}]
	}]}
	global.year = 1443
	global.month = 7
	global.day = 11
	global.sync_week_index()
	global.money = 12345
	global.father_name = "海威尔"
	global.already_talk = true
	global.flags = {"load_test_done": true}
	global.affection["lise"] = 42
	global.visited_shops = {"item_shop": true}
	global.category_stage["theory"] = [2, 5]
	global.triggered_vacation_events = {"1443_1": true}
	global.health_index = 1
	global.growth_rates = data.health_growth["teen"]["活泼取向"].duplicate(true)
	daughter.age = 13
	daughter.age_stage = 1
	daughter.attributes["stress"] = 37.25
	daughter.body_stats["height"] = 156.39
	inventory.slots = [{"item": data.items["c01"], "count": 1}, {"item": data.items["f01"], "count": 5}]
	assert(manager.SaveSlot(0) == OK)
	var original_record = FileAccess.get_file_as_string(manager.SlotPath(0))

	# Browsing and cancelling from the title never initializes or changes a game.
	global.money = 777
	global.month = 4
	global.day = 1
	global.already_talk = false
	daughter.age = 10
	daughter.age_stage = 0
	inventory.slots = []
	change_scene_to_file("res://sences/title.tscn")
	await scene_changed
	current_scene.get_node("GridContainer/Load").button_down.emit()
	await scene_changed
	await create_timer(0.55).timeout
	assert(current_scene.scene_file_path == "res://sences/records.tscn")
	var panel = current_scene.get_node("SavePanel")
	assert(panel.mode == panel.Mode.LOAD and not panel.is_animating)
	assert(panel.get_node("Screen/Canvas/Heading/Label").text == "读 档")
	assert(global.money == 777 and daughter.age == 10 and inventory.slots.is_empty())
	panel.slot_buttons[0].mouse_entered.emit()
	assert(panel.details.text.contains("13 岁"))
	await Capture("pm4-load-slots.png")
	panel.slot_buttons[3].pressed.emit()
	assert(panel.showing_error and panel.prompt.text == "这里没有游戏记录。")
	panel.no_button.pressed.emit()
	panel.slot_buttons[0].pressed.emit()
	assert(panel.prompt.text == "要读取游戏进度吗？")
	assert(panel.no_button.has_focus())
	assert(panel.no_button.get_theme_color("font_focus_color") == panel.no_button.get_theme_color("font_color"))
	await Capture("pm4-load-confirm.png")
	panel.no_button.pressed.emit()
	assert(global.money == 777 and not panel.confirmation.visible)
	panel.slot_buttons[0].pressed.emit()
	await CancelInput()
	assert(panel.visible and not panel.confirmation.visible and global.money == 777)
	panel.return_button.pressed.emit()
	await scene_changed
	assert(current_scene.scene_file_path == "res://sences/title.tscn")
	await create_timer(0.5).timeout
	assert(global.money == 777)

	# Continue from the title restores full state, UI, wardrobe and room season.
	current_scene.get_node("GridContainer/Load").button_down.emit()
	await scene_changed
	await create_timer(0.55).timeout
	panel = current_scene.get_node("SavePanel")
	panel.slot_buttons[0].pressed.emit()
	panel.yes_button.pressed.emit()
	await scene_changed
	await create_timer(0.5).timeout
	assert(current_scene.scene_file_path == "res://sences/main.tscn")
	assert(global.year == 1443 and global.month == 7 and global.day == 11)
	assert(global.money == 12345 and global.already_talk)
	assert(global.flags["load_test_done"] and not global.flags.has("load_test_home_event"))
	assert(global.affection["lise"] == 42 and global.visited_shops["item_shop"])
	assert(global.category_stage["theory"] == [2, 5])
	assert(global.category_stage["theory"][0] is int)
	assert(global.triggered_vacation_events["1443_1"])
	assert(global.health_index == 1 and global.growth_rates["monthly"]["height"] == data.health_growth["teen"]["活泼取向"]["monthly"]["height"])
	assert(daughter.age == 13 and daughter.age_stage == 1)
	assert(is_equal_approx(daughter.attributes["stress"], 37.25))
	assert(is_equal_approx(daughter.body_stats["height"], 156.39))
	assert(inventory.GetItemCount("f01") == 5 and inventory.GetItemCount("c01") == 1)
	assert(inventory.slots[0]["count"] is int)
	assert(current_scene.get_node("UI/Date/Month").text == "7")
	assert(current_scene.get_node("UI/BaseInfo/Age").text == "13")
	assert(current_scene.get_node("UI/BaseInfo/Money").text == "12345")
	assert(current_scene.get_node("DaughterLive").now_stage_node.name == "Teen")
	assert(current_scene.get_node("BackGround").texture.resource_path == global.get_room_background_path())
	assert(not current_scene.get_node("TalkLayer").visible and not manager.restoring_save)
	var restored_state = JSON.parse_string(JSON.stringify(manager.CaptureGame()["state"]))
	assert(restored_state == JSON.parse_string(original_record)["state"])
	await Capture("pm4-loaded-game.png")

	# The in-game system entry uses the same panel and safely returns on cancel.
	var ui = current_scene.get_node("UI")
	var controller = ui.get_node("System")
	ui.get_node("DailyAction/System").button_down.emit()
	await create_timer(0.65).timeout
	FindChoice(controller.menu, "读取记录").pressed.emit()
	await create_timer(0.95).timeout
	panel = controller.save_panel
	assert(panel.visible and panel.mode == panel.Mode.LOAD)
	panel.return_button.pressed.emit()
	await create_timer(0.95).timeout
	assert(ui.visible and ui.daughter_live.visible and controller.menu.visible)
	assert(ui.now_canvas_type == ui.CanvasType.SYSTEM)
	assert(is_equal_approx(ui.daughter_live.modulate.a, 1.0))
	global.money = 888
	global.already_talk = false
	FindChoice(controller.menu, "读取记录").pressed.emit()
	await create_timer(0.95).timeout
	panel.slot_buttons[0].pressed.emit()
	panel.yes_button.pressed.emit()
	await scene_changed
	await create_timer(0.5).timeout
	assert(global.money == 12345 and global.already_talk)
	assert(FileAccess.get_file_as_string(manager.SlotPath(0)) == original_record)
	assert(current_scene.get_node("UI").now_canvas_type == 0)
	assert(not current_scene.get_node("TalkLayer").visible)

	# Corrupt and incompatible files cannot partially overwrite live state.
	var bad_data = JSON.parse_string(original_record)
	bad_data["state"]["global"]["money"] = 99999
	bad_data["state"]["inventory"][0]["id"] = "unknown_item"
	var file = FileAccess.open(manager.SlotPath(1), FileAccess.WRITE)
	file.store_string(JSON.stringify(bad_data))
	file.close()
	assert(not manager.GetSlotInfo(1)["valid"])
	assert(manager.LoadSlot(1) == ERR_FILE_CORRUPT)
	assert(global.money == 12345 and inventory.GetItemCount("f01") == 5)
	assert(manager.LoadSlot(9) == ERR_FILE_NOT_FOUND)
	assert(manager.LoadSlot(-1) == ERR_INVALID_PARAMETER)
	print("PASS: title Continue, in-game Load, cancel/return, complete state/UI restoration, no event replay and corrupt-file rejection")
	Cleanup()
	quit()

func Cleanup() -> void:
	for index in range(10):
		var path = ProjectSettings.globalize_path(test_directory.path_join("slot_%02d.json" % (index + 1)))
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
		if FileAccess.file_exists(path + ".tmp"):
			DirAccess.remove_absolute(path + ".tmp")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_directory))
