extends Control

enum Action {PHYSICAL, MAGIC, GUARD}
enum Contest {ARENA, GARDEN, STORY}

const WIN_REWARD := 150
const MAX_ROUNDS := 12
const RESULTS := {"won": "获胜", "lost": "落败", "withdrawn": "退赛"}
const DISPLAY_REWARD := 120
const DISPLAY_CONTESTS := {
	Contest.GARDEN: {
		"id": "garden",
		"title": "园艺评比",
		"prompt": "为露天展台布置一盆植物。",
		"entries": [
			{"label": "耐候布置\n体力 · 智力", "stats": ["stamina", "smarts"]},
			{"label": "花色搭配\n感受 · 魅力", "stats": ["sensitive", "charm"]},
			{"label": "细心养护\n体贴 · 体力", "stats": ["temper", "stamina"]}
		]
	},
	Contest.STORY: {
		"id": "story",
		"title": "故事演说",
		"prompt": "登台讲一个短故事。",
		"entries": [
			{"label": "即兴讲述\n魅力 · 感受", "stats": ["charm", "sensitive"]},
			{"label": "悬念布局\n智力 · 自尊", "stats": ["smarts", "pride"]},
			{"label": "细腻叙事\n感受 · 体贴", "stats": ["sensitive", "temper"]}
		]
	}
}

@onready var status: Label = %Status
@onready var player_name: Label = %PlayerName
@onready var player_health: ProgressBar = %PlayerHealth
@onready var player_stats: Label = %PlayerStats
@onready var rival_health: ProgressBar = %RivalHealth
@onready var forecast: Label = %Forecast
@onready var start: Button = %Register
@onready var actions: HBoxContainer = %Actions
@onready var back: Button = %Back
@onready var withdrawal: HBoxContainer = %Withdrawal
@onready var contest_buttons: Array[Button] = [%ArenaTab, %GardenTab, %StoryTab]
@onready var entries: HBoxContainer = %Entries

var player: Dictionary
var rival: Dictionary
var rounds := 0
var guard_bonus := 0
var competing := false
var result_key: String
var contest := Contest.ARENA
var difficulty: int

func _ready() -> void:
	difficulty = maxi(0, Global.year - SaveManager.START_YEAR)
	player_name.text = Daughterstatus.firstname
	SelectContest(Contest.ARENA)

func SelectContest(selected: Contest) -> void:
	if competing:
		return
	contest = selected
	if contest == Contest.ARENA:
		result_key = "harvest_%d" % Global.year
		%Title.text = "收获祭擂台"
		PrepareArena()
	else:
		var details: Dictionary = DISPLAY_CONTESTS[contest]
		result_key = "harvest_%s_%d" % [details["id"], Global.year]
		%Title.text = details["title"]
		forecast.text = details["prompt"]
		for index in range(entries.get_child_count()):
			entries.get_child(index).text = details["entries"][index]["label"]
	%Contestants.visible = contest == Contest.ARENA
	UpdateContestButtons()
	var previous_result := RecordedResult()
	start.visible = Global.IsHarvestMonth() and previous_result.is_empty()
	if start.visible:
		var reward := WIN_REWARD if contest == Contest.ARENA else DISPLAY_REWARD
		var rules := "比赛有 %d 回合。" % MAX_ROUNDS if contest == Contest.ARENA else "按养成属性评分，本届最高分为 %d。" % DisplayTarget()
		status.text = "本项每年可报名一次。获胜可得 %d G 和名声。%s" % [reward, rules]
		start.grab_focus()
	elif not previous_result.is_empty():
		status.text = "本届结果 · %s" % RESULTS[previous_result]
		back.grab_focus()
	else:
		status.text = "每年九月开放报名。"
		back.grab_focus()

func PrepareArena() -> void:
	var weapon: Item = Globaljson.items.get(Daughterstatus.equipped_gear["weapon"])
	var armor: Item = Globaljson.items.get(Daughterstatus.equipped_gear["armor"])
	%PlayerGear.text = "武器 %s　防具 %s" % [weapon.name if weapon else "无", armor.name if armor else "无"]
	player = BuildPlayerStats(weapon, armor)
	rounds = 0
	guard_bonus = 0
	rival = {
		"hp": 49 + difficulty * 9,
		"attack": 12 + difficulty * 2,
		"magic": 12 + difficulty * 2,
		"defense": 3 + difficulty,
		"magic_defense": 3 + difficulty
	}
	player_health.max_value = player["hp"]
	rival_health.max_value = rival["hp"]
	UpdateBoard()

func BuildPlayerStats(weapon: Item, armor: Item) -> Dictionary:
	var attributes: Dictionary = Daughterstatus.attributes
	var stamina := float(attributes["stamina"])
	var martial := float(attributes["martial"])
	var magic := float(attributes["magic"])
	var weapon_bonus := weapon.combat_bonus if weapon != null else {}
	var armor_bonus := armor.combat_bonus if armor != null else {}
	return {
		"hp": 46 + roundi(stamina * 0.12),
		"attack": 8 + roundi(martial / 30.0) + int(weapon_bonus.get("attack", 0)),
		"magic": 8 + roundi(magic / 28.0) + int(weapon_bonus.get("magic", 0)),
		"defense": 2 + roundi(stamina / 100.0) + int(armor_bonus.get("defense", 0)) + int(weapon_bonus.get("defense", 0)),
		"magic_defense": 2 + roundi(magic / 130.0) + int(armor_bonus.get("magic_defense", 0)) + int(weapon_bonus.get("magic_defense", 0))
	}

func RecordedResult() -> String:
	for result in RESULTS:
		if Global.flags.get(result_key + "_" + result, false):
			return result
	return ""

func Register() -> void:
	if SceneTransition.is_transitioning or competing or not Global.IsHarvestMonth() or not RecordedResult().is_empty():
		return
	competing = true
	UpdateContestButtons()
	start.hide()
	back.text = "退赛"
	if contest == Contest.ARENA:
		status.text = "比赛开始。选择本回合的行动。"
		UpdateBoard()
	else:
		status.text = "选择参赛方式。前一项属性权重较高，两项属性共同决定得分。"
	ShowActions()

func UpdateContestButtons() -> void:
	for index in range(contest_buttons.size()):
		contest_buttons[index].disabled = competing or index == contest

func ShowActions() -> void:
	if contest == Contest.ARENA:
		actions.show()
		%Physical.grab_focus()
	else:
		entries.show()
		%Entry0.grab_focus()

func DisplayTarget() -> int:
	return 90 + difficulty * 35

func SubmitEntry(index: int) -> void:
	if not competing or contest == Contest.ARENA or withdrawal.visible or SceneTransition.is_transitioning:
		return
	var stats: Array = DISPLAY_CONTESTS[contest]["entries"][index]["stats"]
	var attributes: Dictionary = Daughterstatus.attributes
	var score := roundi((2.0 * attributes[stats[0]] + attributes[stats[1]]) / 3.0)
	var target := DisplayTarget()
	Finish("won" if score > target else "lost")
	status.text = "得分 %d，对手最高分 %d。%s" % [score, target, status.text]

func UpdateBoard() -> void:
	player_health.value = player["hp"]
	rival_health.value = rival["hp"]
	player_stats.text = "武技 %d　术法 %d　物防 %d　术防 %d" % [
		player["attack"], player["magic"], player["defense"], player["magic_defense"]
	]
	var rival_action := "术法" if rounds % 2 == 1 else "武技"
	var ready_text := " · 已蓄势" if guard_bonus > 0 else ""
	forecast.text = "第 %d / %d 回合　对手准备使用%s%s" % [rounds + 1, MAX_ROUNDS, rival_action, ready_text] if competing else ""

func PlayTurn(action: Action) -> void:
	if not competing or contest != Contest.ARENA or withdrawal.visible or SceneTransition.is_transitioning:
		return
	var guarding := action == Action.GUARD
	var hit := 0
	if guarding:
		guard_bonus = 6
	else:
		var using_magic := action == Action.MAGIC
		var power: int = player["magic"] if using_magic else player["attack"]
		var defense: int = rival["magic_defense"] if using_magic else rival["defense"]
		hit = maxi(1, power + guard_bonus - defense)
		guard_bonus = 0
		rival["hp"] = maxi(0, rival["hp"] - hit)
		if rival["hp"] == 0:
			Finish("won")
			return
	var rival_uses_magic := rounds % 2 == 1
	var incoming := int(rival["magic"] - player["magic_defense"]) if rival_uses_magic else int(rival["attack"] - player["defense"])
	if guarding:
		incoming = ceili(incoming / 2.0)
	incoming = maxi(1, incoming)
	player["hp"] = maxi(0, player["hp"] - incoming)
	rounds += 1
	if player["hp"] == 0 or rounds >= MAX_ROUNDS:
		Finish("lost")
		return
	status.text = "防守后受到 %d 点伤害，下次进攻增加 6 点威力。" % incoming if guarding else "对手受到 %d 点伤害，你受到 %d 点伤害。" % [hit, incoming]
	UpdateBoard()

func Finish(result: String) -> void:
	if not competing or not RecordedResult().is_empty():
		return
	competing = false
	Global.flags[result_key + "_" + result] = true
	UpdateContestButtons()
	actions.hide()
	entries.hide()
	withdrawal.hide()
	back.text = "返回房间"
	back.show()
	back.grab_focus()
	match result:
		"won":
			var reward := WIN_REWARD if contest == Contest.ARENA else DISPLAY_REWARD
			var fame := 6 if contest == Contest.ARENA else 4
			Global.money += reward
			Daughterstatus.AddAttribute("fame", fame)
			status.text = "比赛获胜，获得 %d G 和 %d 点名声。" % [reward, fame]
		"lost":
			Daughterstatus.AddAttribute("fame", 1)
			status.text = "比赛结束，获得 1 点名声。"
		"withdrawn":
			status.text = "已退出比赛，本项参赛机会用完。"
	if result != "withdrawn":
		Daughterstatus.AddAttribute("stress", 5)
	if contest == Contest.ARENA:
		UpdateBoard()

func GoBack() -> void:
	if SceneTransition.is_transitioning:
		return
	if competing:
		actions.hide()
		entries.hide()
		back.hide()
		withdrawal.show()
		%KeepPlaying.grab_focus()
	else:
		SaveManager.restoring_save = true
		SceneTransition.ChangeScene("res://sences/main.tscn")

func KeepPlaying() -> void:
	withdrawal.hide()
	back.show()
	ShowActions()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cancel") and not SceneTransition.is_transitioning:
		get_viewport().set_input_as_handled()
		if withdrawal.visible:
			KeepPlaying()
		else:
			GoBack()
