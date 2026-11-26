extends SceneTree

var game: Node
var daughter: Node
var data: Node
var manager: Node
var transition: Node

func _initialize() -> void:
	call_deferred("Run")

func Run() -> void:
	create_timer(35.0).timeout.connect(func():
		push_error("Story flow regression test timed out")
		quit(1)
	)
	game = root.get_node("Global")
	daughter = root.get_node("Daughterstatus")
	data = root.get_node("Globaljson")
	manager = root.get_node("SaveManager")
	manager.ending_collection_path = "user://story-flow-collection-%d.cfg" % OS.get_process_id()
	transition = root.get_node("SceneTransition")

	assert(CheckAge())
	assert(CheckHomeConditions())
	assert(await CheckRoomDialogue())
	assert(await CheckOutingEvents())
	assert(await CheckVacationRecord())
	assert(CheckLegacySave())
	assert(await CheckGrowthAndTreatment())
	assert(await CheckBudgetConfirmation())
	assert(await CheckCoursePromotions())
	assert(CheckEndingDecisions())
	assert(await CheckEnding("rest"))
	assert(await CheckEnding("outing"))
	DirAccess.remove_absolute(manager.ending_collection_path)
	print("PASS: story, both endings, growth, illness portraits, treatment, budget confirmation and course promotions")
	quit()

func SetDate(year: int, month: int, day: int) -> void:
	game.year = year
	game.month = month
	game.day = day
	game.sync_calendar()

func FindEvent(events: Array, id: String) -> Dictionary:
	for event in events:
		if event.get("id") == id:
			return event
	return {}

func CheckAge() -> bool:
	SetDate(1443, 3, 31)
	assert(daughter.age == 12 and daughter.age_stage == daughter.AgeStageType.CHILD)
	game.advance_day()
	assert(game.day == 1 and game.month == 4)
	assert(daughter.age == 13 and daughter.age_stage == daughter.AgeStageType.TEEN)
	SetDate(1446, 3, 31)
	assert(daughter.age == 15 and daughter.age_stage == daughter.AgeStageType.TEEN)
	game.advance_day()
	assert(daughter.age == 16 and daughter.age_stage == daughter.AgeStageType.ADULT)
	assert(daughter.age_on(1441, 2, 27, 1428, 2, 29) == 12)
	assert(daughter.age_on(1441, 2, 28, 1428, 2, 29) == 13)
	return true

func CheckHomeConditions() -> bool:
	var springs = FindEvent(data.home_event_data["rest_events"], "rest_ev300_hotspring_friends")["conditions"]
	game.completed_vacation_months = {"144201": true}
	game.affection["lise"] = 16
	SetDate(1442, 7, 1)
	assert(not game.MeetsHomeEventConditions(springs))
	SetDate(1442, 12, 1)
	game.affection["lise"] = 15
	assert(not game.MeetsHomeEventConditions(springs))
	game.affection["marie"] = 1
	game.completed_vacation_months = {"144101": true, "144212": true}
	assert(not game.MeetsHomeEventConditions(springs))
	game.completed_vacation_months["144112"] = true
	assert(game.MeetsHomeEventConditions(springs))
	SetDate(1443, 2, 28)
	assert(game.MeetsHomeEventConditions(springs))
	game.advance_day()
	assert(not game.MeetsHomeEventConditions(springs))

	var massage = FindEvent(data.home_event_data["monthly_events"], "home_ev040_massage_father")["conditions"]
	SetDate(1446, 8, 1)
	game.affection["father"] = 150
	daughter.attributes["morals"] = 349.5
	assert(not game.MeetsHomeEventConditions(massage))
	SetDate(1448, 3, 1)
	game.affection["father"] = 149
	assert(not game.MeetsHomeEventConditions(massage))
	game.affection["father"] = 150
	daughter.attributes["morals"] = 350
	assert(not game.MeetsHomeEventConditions(massage))
	daughter.attributes["morals"] = 349.5
	assert(game.MeetsHomeEventConditions(massage))
	game.advance_day()
	assert(not game.MeetsHomeEventConditions(massage))
	return true

func PressChoice(list: Node, label: String) -> void:
	for button in list.get_node("NinePatchRect/GridContainer").get_children():
		if button is Button and button.visible and button.text == label:
			button.pressed.emit()
			return
	assert(false, "Choice missing: " + label)

func ClickAt(position: Vector2) -> void:
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.position = position
	mouse.pressed = true
	root.push_input(mouse, true)
	mouse.pressed = false
	root.push_input(mouse, true)

func CloseDialogue(dialogue: CanvasLayer) -> void:
	for step in range(dialogue.talk_even.size() * 2 + 1):
		if not dialogue.visible:
			return
		dialogue.TalkPolling()

func CheckRoomDialogue() -> bool:
	for year in [1440, 1443, 1446]:
		SetDate(year, 4, 1)
		game.already_talk = true
		manager.restoring_save = true
		change_scene_to_file("res://sences/main.tscn")
		await scene_changed
		await process_frame
		var main := current_scene
		var dialogue := main.get_node("TalkLayer")
		ClickAt(Vector2(15, 15))
		assert(not dialogue.visible)
		var portrait: Sprite2D = main.daughter_live.body
		var center := portrait.get_global_transform_with_canvas() * portrait.get_rect().get_center()
		var stage: String = daughter.age_stage_names[daughter.age_stage]
		for line in data.daughter_click_data[stage]:
			ClickAt(center)
			assert(dialogue.visible and dialogue.talk_text.text == dialogue.ProcessDialogueText(line["text"]))
			await process_frame
			CloseDialogue(dialogue)
			assert(not dialogue.visible and game.already_talk)
			await process_frame
		daughter.is_ill = true
		assert(portrait.texture.resource_path.get_file().begins_with("ch11"))
		assert(main.daughter_live.timer.is_stopped() and not main.daughter_live.eyes.visible)
		ClickAt(center)
		assert(dialogue.visible and dialogue.headshot.texture.resource_path.get_file().ends_with("11.png"))
		await process_frame
		CloseDialogue(dialogue)
		daughter.is_ill = false
		assert(portrait.texture is AtlasTexture and not main.daughter_live.timer.is_stopped())
		await process_frame

	var dialogue := current_scene.get_node("TalkLayer")
	var controller := current_scene.get_node("UI/System")
	current_scene.get_node("UI/DailyAction/System").button_down.emit()
	await create_timer(0.6).timeout
	for index in range(controller.GUIDE_TOPICS.size()):
		PressChoice(controller.menu, "新手指引")
		dialogue.FinishTextReveal()
		await process_frame
		assert(dialogue.choice_ui.visible)
		PressChoice(dialogue.choice_ui, controller.GUIDE_LABELS[index])
		assert(dialogue.talk_even == data.beginner_guide_data[controller.GUIDE_TOPICS[index]])
		await process_frame
		CloseDialogue(dialogue)
		assert(controller.menu.visible)
	return true

func CheckOutingEvents() -> bool:
	manager.StartNewGame()
	SetDate(1447, 8, 1)
	change_scene_to_file("res://sences/city.tscn")
	await scene_changed
	var city := current_scene
	var dialogue := city.get_node("TalkLayer")
	var restaurant = FindEvent(data.event_data["FoodShop"], "christina_talk_ev172_14")
	assert(city.CheckConditions(restaurant["conditions"]))
	SetDate(1447, 9, 30)
	assert(city.CheckConditions(restaurant["conditions"]))
	SetDate(1447, 10, 1)
	assert(not city.CheckConditions(restaurant["conditions"]))

	var checked := 0
	for location in data.event_data:
		for event in data.event_data[location]:
			if not event.has("stat_changes"):
				continue
			for stat in event["stat_changes"]:
				daughter.attributes[stat] = 100
			city.PlayEvent(event)
			for stat in event["stat_changes"]:
				assert(is_equal_approx(daughter.attributes[stat], 100.0 + event["stat_changes"][stat]))
			dialogue.event_callable = Callable()
			dialogue.TalkEnd()
			checked += 1
	assert(checked == 12)
	assert(city.GetCharacterHeadshotIcon("ashan") != null)
	dialogue.Happen("ashan", "calm", "头像测试")
	assert(dialogue.headshot.visible and dialogue.headshot.texture.resource_path.ends_with("/ashan.png"))
	return true

func CheckVacationRecord() -> bool:
	manager.StartNewGame()
	SetDate(1442, 2, 28)
	game.triggered_vacation_events["winter_1441"] = true
	var old_count: int = game.category_stage["vacation"][1]
	await FinishLastPlan("vacation")
	assert(game.year == 1442 and game.month == 3 and game.day == 1)
	assert(game.completed_vacation_months.get("144202", false))
	assert(game.category_stage["vacation"][1] == old_count + 1)
	assert(manager.CaptureGame()["state"]["global"]["completed_vacation_months"]["144202"])
	return true

func CheckLegacySave() -> bool:
	manager.StartNewGame()
	SetDate(1446, 7, 1)
	var original_directory: String = manager.save_directory
	manager.save_directory = "user://story-flow-test-%d" % OS.get_process_id()
	assert(DirAccess.make_dir_recursive_absolute(manager.save_directory) == OK)
	var record: Dictionary = manager.CaptureGame()
	record["state"]["global"].erase("completed_vacation_months")
	record["state"]["global"]["triggered_vacation_events"] = {"1442_3": true}
	record["state"]["global"]["category_stage"]["art"] = [0, 12]
	record["state"]["daughter"]["age"] = 10
	record["state"]["daughter"]["age_stage"] = 0
	record["metadata"]["age"] = 10
	var path: String = manager.SlotPath(0)
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert(file != null)
	file.store_string(JSON.stringify(record))
	file.close()
	assert(manager.GetSlotInfo(0)["metadata"]["age"] == 16)
	assert(manager.LoadSlot(0) == OK)
	assert(daughter.age == 16 and daughter.age_stage == daughter.AgeStageType.ADULT)
	assert(game.completed_vacation_months.is_empty() and game.triggered_vacation_events["1442_3"])
	assert(game.category_stage["art"] == [2, 12] and game.art_painting_level == 2)
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(manager.save_directory)
	manager.save_directory = original_directory
	return true

func CheckGrowthAndTreatment() -> bool:
	manager.StartNewGame()
	SetDate(1443, 3, 31)
	game.health_index = 1
	game.UpdateGrowthRates()
	daughter.attributes["stress"] = 100
	var starting_height: float = daughter.body_stats["height"]
	var starting_hips: float = daughter.body_stats["hips"]
	var starting_stamina: float = daughter.attributes["stamina"]
	game.finish_training_month()
	game.finish_training_month()
	await scene_changed
	await process_frame
	assert(game.month == 4 and game.day == 1 and daughter.age == 13 and daughter.is_ill)
	assert(is_equal_approx(daughter.body_stats["height"], starting_height + 0.5))
	assert(is_equal_approx(daughter.body_stats["hips"], starting_hips + 0.4))
	assert(is_equal_approx(daughter.attributes["stamina"], starting_stamina + 2.5))
	assert(game.growth_rates == data.health_growth["teen"][game.health_tactics[1]])
	var room := current_scene
	var dialogue := room.get_node("TalkLayer")
	while dialogue.visible:
		CloseDialogue(dialogue)
		await process_frame
	var ui := room.get_node("UI")
	assert(ui.health_stat.get_node("Tactics").text.contains("生病"))
	ui.get_node("DailyAction/Street").button_down.emit()
	while ui.now_canvas_type != ui.CanvasType.STREET:
		await process_frame
	PressChoice(ui.street, "医院")
	await process_frame
	assert(daughter.is_ill and dialogue.visible)
	CloseDialogue(dialogue)
	assert(not daughter.is_ill and daughter.attributes["stress"] < daughter.attributes["stamina"])
	assert(not ui.health_stat.get_node("Tactics").text.contains("生病"))

	daughter.is_ill = true
	daughter.attributes["stress"] = 120
	change_scene_to_file("res://sences/city.tscn")
	await scene_changed
	var city := current_scene
	dialogue = city.get_node("TalkLayer")
	for button in city.get_node("UI/SitePoints/Hospital").get_children():
		if button is TextureButton:
			button.pressed.emit()
			break
	assert(dialogue.visible)
	await process_frame
	CloseDialogue(dialogue)
	assert(not daughter.is_ill and daughter.attributes["stress"] < daughter.attributes["stamina"])
	assert(game.outing_actions_left == 2)
	return true

func CheckEndingDecisions() -> bool:
	var ending: Node = load("res://scripts/ending.gd").new()
	assert(ending.SelectEnding({"charm": 119.5, "sensitive": 999}, {"marie": 100}, {"future_workshop": true})["id"] == "explore")
	assert(ending.SelectEnding({"charm": 120, "sensitive": 999})["id"] == "workshop")
	var stats := {"smarts": 260, "magic": 260}
	assert(ending.SelectEnding(stats)["id"] == "explore")
	assert(ending.SelectEnding(stats, {"father": 19})["id"] == "explore")
	assert(ending.SelectEnding(stats, {"father": 20})["id"] == "cartography")
	stats.merge({"charm": 600, "sensitive": 600})
	assert(ending.SelectEnding(stats, {"father": 20})["id"] == "workshop")
	assert(ending.SelectEnding(stats, {"father": 20}, {"future_cartography": true})["id"] == "cartography")
	assert(ending.SelectEnding(stats, {"father": 19}, {"future_cartography": true})["id"] == "workshop")
	ending.free()
	return true

func CheckBudgetConfirmation() -> bool:
	manager.StartNewGame()
	SetDate(1440, 5, 1)
	game.money = 15
	manager.restoring_save = true
	change_scene_to_file("res://sences/main.tscn")
	await scene_changed
	var room := current_scene
	var ui := room.get_node("UI")
	var dialogue := room.get_node("TalkLayer")
	var choose := room.get_node("UI/PlanSchedule/PlanChoose")
	var panel := room.get_node("UI/PlanSchedule/PlanPanel")
	ui.plan.button_down.emit()
	while ui.now_canvas_type != ui.CanvasType.PLAN:
		await process_frame

	for answer in ["否", "是"]:
		for action in ["art", "rest", "rest"]:
			var tab := 0 if action == "art" else 2
			choose.labels[tab].mouse_entered.emit()
			choose.grids[tab].get_node(action).pressed.emit()
			while panel.is_busy:
				await process_frame
		assert(dialogue.talk_even[0]["text"].contains("资金不足"))
		assert(dialogue.talk_even[1]["text"].contains("欠款"))
		while not dialogue.choice_ui.visible:
			dialogue.TalkPolling()
			await process_frame
		PressChoice(dialogue.choice_ui, answer)
		assert(panel.plan_list.is_empty())
		if answer == "否":
			assert(game.money == 15 and game.month_plan.is_empty())

	assert(game.month_plan == ["art", "rest", "rest"] and game.money == -15, "Plan: %s, funds: %d" % [str(game.month_plan), game.money])
	assert(dialogue.talk_text.text.contains("当前欠款 15"))
	CloseDialogue(dialogue)
	await scene_changed
	assert(current_scene.plan_name == "rest" and game.category_stage["art"][1] == 0)
	assert(current_scene.talk_layer.talk_text.text.contains("钱不够"))
	assert(game.money == -15)
	return true

func CheckCoursePromotions() -> bool:
	var rank := 0
	for count in [4, 12, 24]:
		manager.StartNewGame()
		SetDate(1440, 5, 31)
		game.category_stage["art"] = [rank, count - 1]
		await FinishLastPlan("art")
		rank += 1
		assert(game.category_stage["art"] == [rank, count] and game.art_painting_level == rank)
		assert(current_scene.get_node("BackGround").texture.resource_path == game.get_room_background_path())
	return true

func FinishLastPlan(plan: String) -> void:
	game.month_plan = ["rest", "rest", plan]
	game.schedule_plan_index = 2
	change_scene_to_file("res://sences/schedule.tscn")
	await scene_changed
	if plan == "outing":
		await scene_changed
		assert(current_scene.scene_file_path == "res://sences/city.tscn")
		current_scene.get_node("UI/GoHome").pressed.emit()
		await scene_changed
		return
	var schedule := current_scene
	var dialogue := schedule.get_node("TalkLayer")
	var annotation := schedule.get_node("Arrtibute")
	while current_scene == schedule:
		if annotation.annotation_visible:
			annotation.AnnotationEnd()
		elif dialogue.visible and not annotation.visible:
			dialogue.TalkPolling()
		await create_timer(0.05).timeout
	if current_scene == null:
		await scene_changed

func CheckEnding(plan: String) -> bool:
	manager.StartNewGame()
	SetDate(1448, 3, 30)
	game.already_talk = true
	game.money = 817
	daughter.firstname = "小满"
	if plan == "rest":
		daughter.attributes["smarts"] = 400
		daughter.attributes["magic"] = 200
	await FinishLastPlan(plan)
	assert(current_scene.scene_file_path == game.ENDING_SCENE)
	assert(game.year == 1448 and game.month == 3 and game.day == 31 and daughter.age == 17)
	assert(not game.already_talk and not game.is_outing_mode)
	var ending := current_scene
	assert(ending.heading.text == ("给河流画一张地图" if plan == "rest" else "自己的第一天"))
	assert(ending.story.text.begins_with("小满"))
	while transition.is_transitioning:
		await process_frame
	ending.advance.pressed.emit()
	assert(ending.showing_epilogue and ending.story.text == ending.route["epilogue"])
	ending.advance.pressed.emit()
	await scene_changed
	assert(current_scene.scene_file_path == "res://sences/title.tscn")
	while transition.is_transitioning:
		await process_frame
	current_scene.get_node("GridContainer/Start").button_down.emit()
	await scene_changed
	assert(current_scene.scene_file_path == "res://sences/main.tscn")
	assert(game.year == 1440 and game.month == 4 and game.day == 1)
	assert(game.money == 2000 and daughter.age == 10 and daughter.firstname != "小满")
	while transition.is_transitioning:
		await process_frame
	return true
