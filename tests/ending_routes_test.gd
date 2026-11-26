extends SceneTree

# godot --headless --fixed-fps 60 --path . --script res://tests/ending_routes_test.gd -- cartography
const STRATEGIES := {
	"cartography": {"action": "magic", "choice": "跟测绘队去画地图", "friend": "father", "met": "home_ev003_first_christmas"},
	"workshop": {"action": "art", "choice": "找人一起开工坊", "visit": "ItemShop", "friend": "marie", "met": "met_marie", "monthly_talk": "打招呼"},
	"courier": {"action": "martialArts", "choice": "走山路给人送信", "visit": "Square", "friend": "lise", "met": "lise_test_done"},
	"community": {"action": "church", "choice": "和街坊办一桌饭", "visit": "BusyStreet", "friend": "christina", "met": "met_christina", "monthly_talk": "严厉地说话"},
	"explore": {"action": "rest", "choice": "先多试几样"}
}
const MAIN := "res://sences/main.tscn"
const TITLE := "res://sences/title.tscn"
const CITY := "res://sences/city.tscn"
const ENDING := "res://sences/ending.tscn"
const GALLERY := "res://sences/gallery.tscn"

var game: Node
var daughter: Node
var manager: Node
var transition: Node
var strategy: Dictionary
var completed_months := 0
var visited_route_location := false

func _initialize() -> void:
	call_deferred("Run")

func Run() -> void:
	create_timer(600, true, false, true).timeout.connect(func():
		push_error("Campaign test timed out during month %d" % completed_months)
		quit(1)
	)
	Engine.time_scale = 16
	seed(14400401)
	game = root.get_node("Global")
	daughter = root.get_node("Daughterstatus")
	manager = root.get_node("SaveManager")
	transition = root.get_node("SceneTransition")
	var route_id: String = OS.get_cmdline_user_args()[0]
	strategy = STRATEGIES[route_id]
	manager.ending_collection_path = "user://ending-routes-test-%d.cfg" % OS.get_process_id()

	assert(await PlayCampaign(route_id))
	assert(await CheckGallery(route_id))
	DirAccess.remove_absolute(manager.ending_collection_path)
	# Wait for the audio thread to release the last UI click during fast headless runs.
	var audio := root.get_node("GameSettings")
	audio.sound_player.stop()
	await process_frame
	OS.delay_msec(100)
	await process_frame
	print("PASS campaign ", route_id, " months=", completed_months)
	quit()

func PlayCampaign(route_id: String) -> bool:
	change_scene_to_file(TITLE)
	await scene_changed
	current_scene.get_node("GridContainer/Start").button_down.emit()
	await scene_changed
	await WaitForTransition()
	assert(game.year == 1440 and game.month == 4 and game.day == 1)
	var initial_height: float = daughter.body_stats["height"]

	for month_index in range(96):
		assert(current_scene.scene_file_path == MAIN and game.day == 1)
		while current_scene.get_node("TalkLayer").visible or current_scene.get_node("Arrtibute").visible:
			StepDialogue(current_scene)
			await process_frame
		if daughter.is_ill:
			await VisitHospital()
			assert(not daughter.is_ill)
		if strategy.has("monthly_talk"):
			await StartMonthlyConversation(strategy["monthly_talk"])
		var plans := ChoosePlans(month_index)
		await SubmitPlan(plans)
		if not await FinishMonth(month_index == 95):
			return false
		completed_months += 1
		if completed_months % 24 == 0:
			print("CHECKPOINT ", route_id, " months=", completed_months, " money=", game.money)

	await WaitForTransition()
	assert(game.year == 1448 and game.month == 3 and game.day == 31 and daughter.age == 17)
	assert(daughter.body_stats["height"] > initial_height)
	assert(game.flags.get("home_future_plan", false) and game.flags.get("future_" + route_id, false))
	var ending := current_scene
	print("RESULT expected=", route_id, " actual=", ending.route["id"], " attributes=", daughter.attributes, " affection=", game.affection)
	assert(ending.route["id"] == route_id)
	if strategy.has("met"):
		assert(game.flags.get(strategy["met"], false))
		assert(game.affection[strategy["friend"]] > 0)
	ending.advance.pressed.emit()
	assert(ending.showing_epilogue and ending.story.text == ending.route["epilogue"])
	ending.advance.pressed.emit()
	await scene_changed
	await WaitForTransition()
	assert(current_scene.scene_file_path == TITLE)
	return true

func ChoosePlans(month_index: int) -> Array:
	var action: String = strategy["action"]
	if strategy.has("visit") and month_index in [0, 12, 24, 36]:
		return ["outing", action, "rest"]
	if action == "rest":
		return ["rest", "rest", "rest"]
	if game.money < 360:
		return ["farm", "farm", "rest"]
	if action == "church":
		return ["church", "housework", "rest"]
	if action == "martialArts":
		return ["martialArts", "farm", "rest"]
	return [action, action, "rest"]

func WaitForTransition() -> void:
	while transition.is_transitioning:
		await process_frame

func PressChoice(menu: Node, text := "") -> void:
	for button in menu.get_node("NinePatchRect/GridContainer").get_children():
		if button is Button and button.visible and (text.is_empty() or button.text == text):
			button.pressed.emit()
			return
	assert(false, "Choice unavailable: " + text)

func VisitHospital() -> void:
	var room := current_scene
	var ui := room.get_node("UI")
	ui.get_node("DailyAction/Street").button_down.emit()
	while ui.now_canvas_type != ui.CanvasType.STREET:
		await process_frame
	PressChoice(ui.street, "医院")
	while room.get_node("TalkLayer").visible or ui.plan.disabled:
		StepDialogue(room)
		await process_frame

func StartMonthlyConversation(choice: String) -> void:
	var room := current_scene
	var ui := room.get_node("UI")
	ui.get_node("DailyAction/Talk").button_down.emit()
	while ui.now_canvas_type != ui.CanvasType.DAILYTALK:
		await process_frame
	PressChoice(ui.talk, choice)
	while room.get_node("TalkLayer").visible or ui.plan.disabled:
		StepDialogue(room)
		await process_frame

func SubmitPlan(plans: Array) -> void:
	var room := current_scene
	var ui := room.get_node("UI")
	ui.get_node("Plan").button_down.emit()
	while ui.now_canvas_type != ui.CanvasType.PLAN:
		await process_frame
	var planner := ui.get_node("PlanSchedule")
	var choose := planner.get_node("PlanChoose")
	var panel := planner.get_node("PlanPanel")
	for action in plans:
		for tab in range(choose.grids.size()):
			var button := choose.grids[tab].get_node_or_null(action) as TextureButton
			if button == null:
				continue
			choose.labels[tab].mouse_entered.emit()
			assert(button.is_visible_in_tree())
			button.pressed.emit()
			while panel.is_busy:
				await process_frame
			break
	var talk := room.get_node("TalkLayer")
	while is_instance_valid(room) and current_scene == room:
		if talk.choice_ui.visible:
			PressChoice(talk.choice_ui, "是")
		elif talk.visible:
			talk.TalkPolling()
		await process_frame

func StepDialogue(scene: Node) -> void:
	var annotation := scene.get_node_or_null("Arrtibute")
	if annotation and annotation.visible:
		if annotation.annotation_visible:
			annotation.AnnotationEnd()
		return
	var talk := scene.get_node_or_null("TalkLayer")
	if not talk or not talk.visible:
		return
	if talk.choice_ui.visible:
		var choice: String = strategy["choice"]
		PressChoice(talk.choice_ui, choice if talk.choice_list.has(choice) else "")
	else:
		talk.TalkPolling()

func FinishMonth(final_month: bool) -> bool:
	visited_route_location = false
	while current_scene == null or current_scene.scene_file_path not in [MAIN, ENDING]:
		var scene := current_scene
		if scene:
			if scene.scene_file_path == CITY and scene.get_node("UI/GoHome").visible:
				if not visited_route_location and strategy.has("visit"):
					var location := scene.get_node("UI/SitePoints/" + strategy["visit"])
					for node in location.get_children():
						if node is TextureButton:
							node.pressed.emit()
							visited_route_location = true
							break
				else:
					scene.get_node("UI/GoHome").pressed.emit()
			else:
				StepDialogue(scene)
		await process_frame
	var expected := ENDING if final_month else MAIN
	assert(current_scene.scene_file_path == expected)
	return current_scene.scene_file_path == expected

func CheckGallery(route_id: String) -> bool:
	var config := ConfigFile.new()
	assert(config.load(manager.ending_collection_path) == OK)
	assert(config.has_section_key("endings", route_id))
	current_scene.get_node("GridContainer/Gallery").button_down.emit()
	await scene_changed
	await WaitForTransition()
	var gallery := current_scene
	assert(gallery.scene_file_path == GALLERY)
	assert(gallery.collection_notice.text == "已收藏 1 / 5")
	var replayable := 0
	for button in gallery.routes_list.get_children():
		if not button.disabled:
			replayable += 1
			button.pressed.emit()
	assert(replayable == 1 and gallery.route["id"] == route_id)
	gallery.advance.pressed.emit()
	assert(gallery.showing_epilogue)
	gallery.advance.pressed.emit()
	assert(gallery.routes_list.visible and gallery.route.is_empty())
	gallery.advance.pressed.emit()
	await scene_changed
	await WaitForTransition()
	assert(current_scene.scene_file_path == TITLE)
	return true
