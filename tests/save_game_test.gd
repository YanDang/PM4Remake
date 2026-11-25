extends SceneTree

# godot --headless --path . --script res://tests/save_game_test.gd
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
	create_timer(20.0).timeout.connect(func():
		push_error("Save game regression test timed out")
		Cleanup()
		quit(1))
	manager = root.get_node("SaveManager")
	# Never touch the player's actual save directory.
	test_directory = "user://test_saves_%d" % OS.get_process_id()
	manager.save_directory = test_directory
	root.get_node("Globaljson").home_event_data = {}
	var global = root.get_node("Global")
	var daughter = root.get_node("Daughterstatus")
	global.money = 3456
	global.already_talk = true
	global.flags["save_test_event"] = true
	global.affection["lise"] = 17
	global.category_stage["theory"] = [2, 8]
	daughter.attributes["stress"] = 37
	daughter.body_stats["height"] = 140.39
	assert(manager.SaveSlot(0) == OK)
	var original_record = FileAccess.get_file_as_string(manager.SlotPath(0))
	assert(manager.SaveSlot(0) == ERR_ALREADY_EXISTS)
	assert(manager.SaveSlot(-1) == ERR_INVALID_PARAMETER)
	assert(manager.SaveSlot(10) == ERR_INVALID_PARAMETER)

	change_scene_to_file("res://sences/main.tscn")
	await scene_changed
	await process_frame
	var main = current_scene
	var ui = main.get_node("UI")
	var controller = main.get_node("UI/System")
	ui.get_node("DailyAction/System").button_down.emit()
	await create_timer(0.65).timeout
	FindChoice(controller.menu, "储存游戏").pressed.emit()
	var panel = controller.save_panel
	assert(controller.records_transitioning)
	var date_x = ui.records_positions[ui.date].x
	await create_timer(0.2).timeout
	assert(ui.date.position.x < date_x)
	assert(ui.daughter_live.modulate.a > 0.0 and ui.daughter_live.modulate.a < 1.0)
	await create_timer(0.4).timeout
	assert(panel.visible and panel.is_animating)
	assert(panel.slot_buttons[0].position.x < 28.0)
	assert(panel.slot_buttons[5].position.x > 326.0)
	await Capture("pm4-records-slide-in.png")
	await create_timer(0.35).timeout
	assert(panel.visible and not ui.visible and not ui.daughter_live.visible)
	assert(ui.now_canvas_type == ui.CanvasType.SAVE)
	assert(panel.slot_buttons.size() == 10)
	assert(panel.slot_buttons[0].position == Vector2(28, 80))
	assert(panel.slot_buttons[5].position == Vector2(326, 80))
	assert(panel.slot_buttons[9].position == Vector2(326, 280))
	assert(panel.slot_buttons[0].get_node("DateLabel").text == "第1年 4月 1日")
	panel.slot_buttons[3].mouse_entered.emit()
	assert(panel.details.text.is_empty())
	assert(panel.slot_buttons[3].get_node("DataLabel").get_theme_color("font_color") == panel.HOVER_COLOR)
	await Capture("pm4-save-empty-hover.png")
	panel.slot_buttons[0].mouse_entered.emit()
	assert(panel.details.text.contains(global.father_name))
	assert(panel.details.text.contains(daughter.firstname))
	assert(panel.details.text.contains("10 岁"))
	assert(panel.details.text.contains(manager.GetSlotInfo(0)["metadata"]["saved_at"]))
	await Capture("pm4-save-details.png")

	# Empty slots require confirmation. No and Esc never create a save.
	panel.slot_buttons[3].pressed.emit()
	assert(panel.confirmation.visible and panel.prompt.text == "要储存游戏吗？")
	assert(panel.return_button.disabled and panel.slot_buttons[0].disabled)
	await Capture("pm4-save-confirm.png")
	panel.no_button.pressed.emit()
	assert(not FileAccess.file_exists(manager.SlotPath(3)))
	panel.slot_buttons[3].pressed.emit()
	await CancelInput()
	assert(panel.visible and not panel.confirmation.visible)
	assert(not FileAccess.file_exists(manager.SlotPath(3)))

	# Existing records require a distinct overwrite confirmation.
	panel.slot_buttons[0].pressed.emit()
	assert(panel.prompt.text.contains("要覆盖记录吗"))
	await Capture("pm4-save-overwrite.png")
	panel.no_button.pressed.emit()
	assert(FileAccess.get_file_as_string(manager.SlotPath(0)) == original_record)

	# Save the full game state, including event flags and inventory item IDs.
	panel.slot_buttons[3].pressed.emit()
	panel.yes_button.pressed.emit()
	assert(not panel.confirmation.visible)
	assert(manager.GetSlotInfo(3)["valid"])
	var saved = manager.ReadSlot(3)
	assert(saved["state"]["global"]["money"] == 3456)
	assert(saved["state"]["global"]["already_talk"])
	assert(saved["state"]["global"]["flags"]["save_test_event"])
	assert(saved["state"]["global"]["affection"]["lise"] == 17)
	assert(saved["state"]["global"]["category_stage"]["theory"] == [2.0, 8.0])
	assert(saved["state"]["daughter"]["attributes"]["stress"] == 37)
	assert(is_equal_approx(saved["state"]["daughter"]["body_stats"]["height"], 140.39))
	assert(saved["state"]["inventory"][0]["id"] == root.get_node("Inventory").slots[0]["item"].id)
	assert(saved["state"]["inventory"][0]["count"] == root.get_node("Inventory").slots[0]["count"])
	assert(saved["metadata"]["father_name"] == global.father_name)
	assert(saved["metadata"]["daughter_name"] == daughter.firstname)

	# Overwriting updates the same slot and does not affect the other records.
	global.money = 7890
	panel.slot_buttons[0].pressed.emit()
	panel.yes_button.pressed.emit()
	assert(manager.ReadSlot(0)["state"]["global"]["money"] == 7890)
	assert(manager.ReadSlot(3)["state"]["global"]["money"] == 3456)
	assert(not FileAccess.file_exists(manager.SlotPath(0) + ".tmp"))

	# A fresh manager reads the data from disk, without an in-memory cache.
	var fresh_manager = load("res://scripts/save_manager.gd").new()
	fresh_manager.save_directory = test_directory
	assert(fresh_manager.ReadSlot(0)["state"]["global"]["money"] == 7890)
	fresh_manager.free()

	# A write error stays in the menu and never reports success.
	manager.save_directory = manager.SlotPath(0)
	panel.slot_buttons[7].pressed.emit()
	panel.yes_button.pressed.emit()
	assert(panel.showing_error and panel.confirmation.visible)
	assert(panel.prompt.text.contains("保存失败"))
	panel.no_button.pressed.emit()
	manager.save_directory = test_directory
	assert(manager.ReadSlot(0)["state"]["global"]["money"] == 7890)

	# Invalid records stay occupied and also require explicit overwrite approval.
	var invalid_file = FileAccess.open(manager.SlotPath(8), FileAccess.WRITE)
	invalid_file.store_string("{\"format_version\":1,\"metadata\":{},\"state\":{}}")
	invalid_file.close()
	panel.RefreshSlots()
	assert(panel.slot_info[8]["exists"] and not panel.slot_info[8]["valid"])
	assert(panel.slot_buttons[8].get_node("DateLabel").text == "记录损坏")
	panel.slot_buttons[8].pressed.emit()
	assert(panel.prompt.text.contains("要覆盖记录吗"))
	panel.no_button.pressed.emit()

	# Returning restores the system menu; reopening refreshes the saved dates.
	panel.return_button.pressed.emit()
	assert(panel.is_animating)
	await create_timer(0.95).timeout
	assert(not panel.visible and ui.visible and ui.daughter_live.visible)
	assert(controller.menu.visible and ui.now_canvas_type == ui.CanvasType.SYSTEM)
	FindChoice(controller.menu, "储存游戏").pressed.emit()
	await create_timer(0.95).timeout
	assert(controller.save_panel == panel and panel.visible)
	assert(not panel.slot_buttons[3].get_node("DateLabel").text.is_empty())
	await CancelInput()
	await create_timer(0.95).timeout
	assert(not panel.visible and ui.now_canvas_type == ui.CanvasType.SYSTEM)
	print("PASS: ten slots, hover details, confirmation/cancel, save, overwrite, disk persistence, write failure and return")
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
