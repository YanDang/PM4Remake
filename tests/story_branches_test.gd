extends SceneTree

const HOME := "res://sences/main.tscn"
const CITY := "res://sences/city.tscn"
const SCHEDULE := "res://sences/schedule.tscn"
const BLACK_STREET := "blackstreet_ev026_friends_adventure"
const COURAGE := "square_courage_afterward"
const BALL := "home_ev034_royal_ball_debut"
const AFTER_BALL := "busystreet_christina_after_ball"
const FATHER_NEWS := "home_ev018_lise_father_news"
const LOGBOOK := "square_lise_fathers_logbook"

var game: Node
var daughter: Node
var saves: Node
var data: Node

func _initialize() -> void:
	call_deferred("Run")

func Run() -> void:
	create_timer(40, true, false, true).timeout.connect(func(): quit(1))
	Engine.time_scale = 10
	game = root.get_node("Global")
	daughter = root.get_node("Daughterstatus")
	saves = root.get_node("SaveManager")
	data = root.get_node("Globaljson")
	assert(await CheckWageAndWinter())
	for option in range(2):
		assert(await CheckCourage(option))
		assert(await CheckFriends(option))
	assert(await CheckMainDialogue())
	print("PASS: casino wage, winter vacation, story options and thresholds, outing actions and rebellious dialogue")
	quit()

func SetDate(year: int, month: int, day: int = 1) -> void:
	game.year = year
	game.month = month
	game.day = day
	game.sync_calendar()

func EnterScene(path: String) -> void:
	change_scene_to_file(path)
	await scene_changed
	while current_scene == null:
		await process_frame
	await process_frame

func AdvanceDialogue(scene: Node, option: int) -> void:
	var annotation := scene.get_node("Arrtibute")
	var talk := scene.get_node("TalkLayer")
	if annotation.visible:
		if annotation.annotation_visible:
			annotation.AnnotationEnd()
	elif talk.visible:
		if talk.choice_ui.visible:
			for button in talk.choice_ui.get_node("NinePatchRect/GridContainer").get_children():
				if button is Button and button.visible:
					if option == 0:
						button.pressed.emit()
						return
					option -= 1
		else:
			talk.TalkPolling()

func FinishDialogue(scene: Node, option: int = 0) -> void:
	while is_instance_valid(scene) and current_scene == scene and (scene.get_node("TalkLayer").visible or scene.get_node("Arrtibute").visible):
		AdvanceDialogue(scene, option)
		await process_frame

func RunLastPlan(plan: String) -> void:
	game.day = game.get_current_month_end_day()
	game.month_plan = ["rest", "rest", plan]
	game.schedule_plan_index = 2
	await EnterScene(SCHEDULE)
	var schedule := current_scene
	while is_instance_valid(schedule) and current_scene == schedule:
		AdvanceDialogue(schedule, 0)
		await process_frame
	while current_scene == null:
		await process_frame

func CheckWageAndWinter() -> bool:
	saves.StartNewGame()
	SetDate(1442, 12)
	await RunLastPlan("vacation")
	assert(game.completed_vacation_months.get("144212", false))
	assert(game.triggered_vacation_events.get("winter_1442", false))
	assert(game.year == 1443 and game.month == 1)
	await RunLastPlan("vacation")
	assert(game.completed_vacation_months.get("144301", false))
	assert(game.triggered_vacation_events.size() == 1)
	SetDate(1443, 12)
	await RunLastPlan("vacation")
	assert(game.triggered_vacation_events.get("winter_1443", false))
	var legacy := {"triggered_vacation_events": {"1443_3": true}, "completed_vacation_months": {"144312": true, "144301": true}}
	saves.MigrateWinterVacationRewards(legacy)
	assert(legacy["triggered_vacation_events"].get("winter_1442", false))
	assert(not legacy["triggered_vacation_events"].get("winter_1443", false))

	SetDate(1446, 10)
	game.category_stage["casino"] = [0, 15]
	daughter.attributes["smarts"] = 500
	game.flags["work_casino_intro"] = true
	assert(game.GetDailyWage("casino") == 70)
	await RunLastPlan("casino")
	assert(game.flags.get("work_casino_master", false) and game.GetDailyWage("casino") == 80)
	saves.StartNewGame()
	assert(game.GetDailyWage("casino") == 40)
	return true

func FindCityEvent(location: String, event_id: String) -> Dictionary:
	for event in data.event_data[location]:
		if event["id"] == event_id:
			return event
	return {}

func Visit(location: String, event_id: String, option: int = 0) -> bool:
	var city := current_scene
	for attempt in range(3):
		if not is_instance_valid(city) or current_scene != city or city.is_time_lapsing:
			return false
		var event: Dictionary = city.GetAvailableEventForLocation(location)
		for node in city.get_node("UI/SitePoints/" + location).get_children():
			if node is TextureButton:
				node.pressed.emit()
				break
		await FinishDialogue(city, option if event.get("id") == event_id else 0)
		if event.get("id") == event_id:
			return game.flags.get(event_id, false)
	return false

func CheckCourage(option: int) -> bool:
	saves.StartNewGame()
	SetDate(1444, 1)
	await RunLastPlan("martialArts")
	await RunLastPlan("martialArts")
	assert(game.flags.get("met_lise", false))
	daughter.attributes["martial"] = 119
	await EnterScene(CITY)
	var conditions: Dictionary = FindCityEvent("BlackStreet", BLACK_STREET)["conditions"]
	assert(not current_scene.CheckConditions(conditions))
	daughter.attributes["martial"] = 120
	assert(current_scene.CheckConditions(conditions))
	game.outing_actions_left = 3
	assert(await Visit("BlackStreet", BLACK_STREET))
	assert(game.outing_actions_left < 3)
	await EnterScene(CITY)
	assert(await Visit("Square", COURAGE, option))
	assert(game.flags.get("courage_shared_credit", false) == (option == 0))
	assert(game.flags.get("courage_safer_streets", false) == (option == 1))
	return true

func CheckFriends(option: int) -> bool:
	saves.StartNewGame()
	daughter.attributes["crime"] = 99 if option == 0 else 100
	SetDate(1446, 5)
	await EnterScene(HOME)
	await FinishDialogue(current_scene)
	assert(game.flags.get(FATHER_NEWS, false))
	SetDate(1446, 6)
	daughter.attributes["crime"] = 20
	await EnterScene(CITY)
	var logbook: Dictionary = FindCityEvent("Square", LOGBOOK)["conditions"]
	game.affection["lise"] = 24
	assert(not current_scene.CheckConditions(logbook))
	game.affection["lise"] = 25
	assert(await Visit("Square", LOGBOOK))

	SetDate(1447, 10)
	await EnterScene(HOME)
	await FinishDialogue(current_scene)
	assert(game.flags.get(BALL, false))
	SetDate(1448, 2)
	await EnterScene(CITY)
	var after_ball := FindCityEvent("BusyStreet", AFTER_BALL)
	game.affection["christina"] = 39
	assert(not current_scene.CheckConditions(after_ball["conditions"]))
	game.affection["christina"] = 40
	daughter.attributes["crime"] = 99 if option == 0 else 100
	assert(GlobalDialogueHasPreface(after_ball) == (option == 1))
	assert(await Visit("BusyStreet", AFTER_BALL, option))
	assert(game.flags.get("christina_after_ball_market", false) == (option == 0))
	assert(game.flags.get("christina_after_ball_reflection", false) == (option == 1))
	SetDate(1448, 3)
	await EnterScene(CITY)
	assert(not current_scene.CheckConditions(after_ball["conditions"]))
	return true

func GlobalDialogueHasPreface(event: Dictionary) -> bool:
	return game.GetStoryDialogue(event).size() > event["dialogue_script"].size()

func CheckMainDialogue() -> bool:
	for crime in [99, 100]:
		saves.StartNewGame()
		SetDate(1448, 1)
		daughter.attributes["crime"] = crime
		await EnterScene(HOME)
		var talk := current_scene.get_node("TalkLayer")
		assert(talk.visible and talk.talk_even[0]["text"].contains("猜我以后") == (crime == 100))
		await FinishDialogue(current_scene)
	return true
