extends SceneTree

# Run with: godot --headless --path . --script res://tests/system_menu_test.gd
# Remove --headless and add -- --capture to save screenshots in the temp folder.
func _initialize() -> void:
	call_deferred("Run")

func FindChoice(list: Node, text: String) -> Button:
	for button in list.get_node("NinePatchRect/GridContainer").get_children():
		if button is Button and button.visible and button.text == text:
			return button
	return null

func Run() -> void:
	create_timer(15.0).timeout.connect(func():
		push_error("System menu regression test timed out")
		quit(1))
	# Keep monthly story events from interrupting the menu under test.
	root.get_node("Globaljson").home_event_data = {}
	change_scene_to_file("res://sences/main.tscn")
	await scene_changed
	await process_frame
	var main = current_scene
	var ui = main.get_node("UI")
	var menu = main.get_node("UI/System/System")
	var dialogue = main.get_node("TalkLayer")
	var transition = root.get_node("SceneTransition")

	ui.get_node("DailyAction/System").button_down.emit()
	await create_timer(0.65).timeout
	assert(menu.visible)
	FindChoice(menu, "标题界面").pressed.emit()
	dialogue.FinishTextReveal()
	await process_frame
	assert(dialogue.visible and not menu.visible)
	assert(dialogue.talk_text.text == "要返回到游戏的标题画面。\n这样可以吗？")
	assert(dialogue.choice_ui.visible)
	assert(dialogue.choice_ui.name == "NarrowChoiceUI")
	assert(dialogue.choice_ui.get_node("NinePatchRect").size.x == 170.0)
	assert(FindChoice(dialogue.choice_ui, "是").text == "是")
	assert(FindChoice(dialogue.choice_ui, "否").text == "否")
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("TEMP").path_join("pm4-title-confirmation.png"))

	# No restores the system menu without leaving the game.
	FindChoice(dialogue.choice_ui, "否").pressed.emit()
	assert(current_scene == main and menu.visible and not dialogue.visible)
	assert(ui.now_canvas_type == ui.CanvasType.SYSTEM)

	# Esc/right-click uses the same safe cancellation path.
	FindChoice(menu, "标题界面").pressed.emit()
	dialogue.FinishTextReveal()
	await process_frame
	var cancel = InputEventAction.new()
	cancel.action = "cancel"
	cancel.pressed = true
	root.push_input(cancel)
	await process_frame
	assert(menu.visible and not dialogue.visible)
	assert(ui.now_canvas_type == ui.CanvasType.SYSTEM)

	# Yes slides the components out and fades the daughter before changing scenes.
	FindChoice(menu, "标题界面").pressed.emit()
	dialogue.FinishTextReveal()
	await process_frame
	var date_x = ui.date.position.x
	var info_x = ui.base_info.position.x
	var text_x = dialogue.get_node("TalkEvent").position.x
	var choice_x = dialogue.choice_ui.position.x
	FindChoice(dialogue.choice_ui, "是").pressed.emit()
	assert(transition.is_transitioning)
	await create_timer(0.25).timeout
	assert(current_scene == main)
	assert(dialogue.visible and dialogue.choice_ui.visible)
	assert(ui.date.position.x < date_x)
	assert(ui.base_info.position.x > info_x)
	assert(dialogue.get_node("TalkEvent").position.x < text_x)
	assert(dialogue.choice_ui.position.x > choice_x)
	assert(ui.daughter_live.modulate.a > 0.0 and ui.daughter_live.modulate.a < 1.0)
	assert(is_zero_approx(transition.curtain.color.a))
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("TEMP").path_join("pm4-title-slide-out.png"))
	await create_timer(0.4).timeout
	assert(is_zero_approx(ui.daughter_live.modulate.a))
	assert(transition.curtain.color.a > 0.0 and transition.curtain.color.a < 1.0)
	await scene_changed
	assert(current_scene.scene_file_path == "res://sences/title.tscn")
	assert(is_equal_approx(transition.curtain.color.a, 1.0))
	await create_timer(0.5).timeout
	assert(not transition.is_transitioning and not transition.visible)
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("TEMP").path_join("pm4-returned-title.png"))
	print("PASS: narrow confirmation, No, cancel, component slide-out, daughter fade and title transition")

	# The title exit button must fade out before terminating the process.
	current_scene.get_node("GridContainer/Exit").button_down.emit()
	assert(transition.is_transitioning)
	await create_timer(0.2).timeout
	assert(transition.curtain.color.a > 0.0 and transition.curtain.color.a < 1.0)
	print("PASS: exit button starts a fade before quitting")
