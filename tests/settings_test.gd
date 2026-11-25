extends SceneTree

# godot --headless --path . --script res://tests/settings_test.gd
# Remove --headless and add -- --capture for visual and window-mode checks.
var settings: Node
var test_path: String

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
		push_error("Settings regression test timed out")
		Cleanup()
		quit(1))
	settings = root.get_node("GameSettings")
	test_path = "user://test_settings_%d.cfg" % OS.get_process_id()
	settings.config_path = test_path
	settings.LoadSettings()
	root.get_node("Globaljson").home_event_data = {}

	# Settings survive a fresh disk read and ignore invalid inputs.
	assert(settings.SetValue("music_volume", 3) == OK)
	assert(settings.SetValue("sound_volume", 2) == OK)
	assert(settings.SetValue("voice_volume", 0) == OK)
	assert(settings.SetValue("text_speed", 2) == OK)
	settings.values = settings.DEFAULTS.duplicate()
	settings.LoadSettings()
	assert(settings.GetValue("music_volume") == 3)
	assert(settings.GetValue("sound_volume") == 2)
	assert(settings.GetValue("voice_volume") == 0)
	assert(settings.GetValue("text_speed") == 2)
	assert(settings.SetValue("music_volume", 4) == ERR_INVALID_PARAMETER)
	assert(settings.SetValue("fullscreen", "true") == ERR_INVALID_PARAMETER)
	for key in settings.DEFAULTS:
		assert(settings.SetValue(key, settings.DEFAULTS[key]) == OK)

	# The title Settings button opens the actual panel with a slide transition.
	change_scene_to_file("res://sences/title.tscn")
	await scene_changed
	current_scene.get_node("GridContainer/Setting").button_down.emit()
	await scene_changed
	await create_timer(0.55).timeout
	assert(current_scene.scene_file_path == "res://sences/settings.tscn")
	var panel = current_scene.get_node("SettingsPanel")
	assert(panel.visible and not panel.is_animating)
	assert(panel.option_buttons.size() == 5)
	for key in ["music_volume", "sound_volume", "voice_volume"]:
		assert(panel.option_buttons[key].size() == 4)
		assert(panel.option_buttons[key][1].button_pressed)
	await Capture("pm4-settings.png")

	# All three volume controls really alter their independent engine buses.
	for key in ["music_volume", "sound_volume", "voice_volume"]:
		var bus = AudioServer.get_bus_index(settings.AUDIO_BUSES[key])
		for level in range(4):
			panel.option_buttons[key][level].pressed.emit()
			assert(settings.GetValue(key) == level)
			assert(panel.option_buttons[key][level].button_pressed)
			assert(AudioServer.is_bus_mute(bus) == (level == 0))
			if level > 0:
				assert(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(bus)), settings.VOLUME_LEVELS[level]))
		panel.option_buttons[key][1].pressed.emit()
	settings.PlayMusic(settings.click_sound)
	settings.PlayVoice(settings.click_sound)
	assert(settings.music_player.bus == "Music" and settings.voice_player.bus == "Voice")
	assert(settings.music_player.playing and settings.voice_player.playing)
	assert(panel.return_button.button_down.is_connected(settings.PlayClick))
	panel.return_button.button_down.emit()
	assert(settings.sound_player.bus == "SFX" and settings.sound_player.playing)

	# Text speed and fullscreen/windowed are real options, not display-only labels.
	for level in range(3):
		panel.option_buttons["text_speed"][level].pressed.emit()
		assert(settings.GetValue("text_speed") == level)
	panel.option_buttons["fullscreen"][1].pressed.emit()
	assert(settings.GetValue("fullscreen"))
	if DisplayServer.get_name() != "headless":
		await create_timer(0.15).timeout
		assert(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
	panel.option_buttons["fullscreen"][0].pressed.emit()
	assert(not settings.GetValue("fullscreen"))
	if DisplayServer.get_name() != "headless":
		await create_timer(0.15).timeout
		assert(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED)
	await CancelInput()
	await scene_changed
	await create_timer(0.5).timeout
	assert(current_scene.scene_file_path == "res://sences/title.tscn")

	# The in-game entry animates the HUD out, and restores its positions on return.
	change_scene_to_file("res://sences/main.tscn")
	await scene_changed
	await process_frame
	var ui = current_scene.get_node("UI")
	var controller = ui.get_node("System")
	ui.get_node("DailyAction/System").button_down.emit()
	await create_timer(0.65).timeout
	var date_position = ui.date.position
	FindChoice(controller.menu, "设定选项").pressed.emit()
	assert(controller.records_transitioning)
	await create_timer(0.2).timeout
	assert(ui.date.position.x < date_position.x)
	assert(ui.daughter_live.modulate.a > 0.0 and ui.daughter_live.modulate.a < 1.0)
	await create_timer(0.75).timeout
	panel = controller.settings_panel
	assert(panel.visible and not ui.visible and not ui.daughter_live.visible)
	panel.option_buttons["text_speed"][0].pressed.emit()
	panel.return_button.pressed.emit()
	await create_timer(0.95).timeout
	assert(ui.visible and ui.daughter_live.visible and controller.menu.visible)
	assert(ui.date.position == date_position)
	assert(is_equal_approx(ui.daughter_live.modulate.a, 1.0))
	assert(ui.now_canvas_type == ui.CanvasType.SYSTEM)

	# Dialogue visibly reveals more characters at Fast than at Slow.
	var dialogue = current_scene.get_node("TalkLayer")
	var text = "这是一段用于验证讯息速度的长对话，文字应该按照设定逐字显示，而不是一次全部出现。"
	settings.SetValue("text_speed", 2)
	dialogue.TalkStart([{"character": "", "text": text}])
	await create_timer(0.25).timeout
	var slow_count = dialogue.talk_text.visible_characters
	assert(slow_count > 0 and dialogue.is_revealing_text)
	dialogue.TalkEnd()
	settings.SetValue("text_speed", 0)
	dialogue.TalkStart([{"character": "", "text": text}])
	await create_timer(0.25).timeout
	assert(dialogue.talk_text.visible_characters > slow_count)
	assert(dialogue.current_index == 1)
	var confirm = InputEventAction.new()
	confirm.action = "confirm"
	confirm.pressed = true
	root.push_input(confirm)
	await process_frame
	assert(not dialogue.is_revealing_text and dialogue.talk_text.visible_characters == -1)
	assert(dialogue.current_index == 1 and dialogue.visible)
	root.push_input(confirm.duplicate())
	await process_frame
	assert(not dialogue.visible)

	# Choices wait for the text to finish; completing the line never advances it.
	dialogue.TalkStart([{"character": "", "text": text}], dialogue.SettleType.CHOICE, {}, ["是", "否"])
	await process_frame
	assert(not dialogue.choice_ui.visible)
	root.push_input(confirm.duplicate())
	await process_frame
	assert(dialogue.choice_ui.visible and dialogue.current_index == 1)
	dialogue._on_choice_pressed("否", 1)
	print("PASS: both settings entries, slide transitions, audio levels/playback, text reveal, window modes and preference persistence")
	Cleanup()
	quit()

func Cleanup() -> void:
	if FileAccess.file_exists(test_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path))
