extends Control

const MIN_ROUTE_SCORE := 300.0
const MIN_ROUTE_STAT := 120.0
const ROUTES := [
	{
		"id": "cartography",
		"affection": "father",
		"stats": ["smarts", "magic"],
		"title": "给河流画一张地图",
		"ending": "%s报名加入了河道测绘队。出发前，她把镇上旧地图的空白处描了一遍。她说，等走完这一趟，就知道哪些路该画上去了。",
		"epilogue": "入秋后，家里收到了一卷用布包好的新地图。她标出了每一处能过河的浅滩，也在地图边角写下了下一次回家的日期。"
	},
	{
		"id": "workshop",
		"affection": "marie",
		"stats": ["charm", "sensitive"],
		"title": "一间亮着灯的工坊",
		"ending": "%s跟街坊合租了一间空屋，准备做修补和装帧的生意。开门那天，第一位客人拿来的，是一本孙女画坏了封面的故事书。",
		"epilogue": "第二年春天，工坊摆上了两张矮桌。每逢休息日，来学装订的孩子都会在新本子的第一页写下自己的名字。"
	},
	{
		"id": "courier",
		"affection": "lise",
		"stats": ["stamina", "martial"],
		"title": "山口的信差",
		"ending": "%s接下了山口的送信差事。第一趟出门时，她把水壶、绷带和当天要送的信逐样点了一遍，天刚亮就出了门。",
		"epilogue": "冬天封路前，她带着新来的信差认过一遍沿途可以借住的人家。那年山里的最后一封信，赶在落雪前送到了。"
	},
	{
		"id": "community",
		"affection": "christina",
		"stats": ["morals", "temper"],
		"title": "街坊的长桌",
		"ending": "%s和邻居借来几张桌子，办起每周一次的街坊饭。她请大家把剩下的食材带来，也给来得晚的人留了位置。",
		"epilogue": "后来，街坊自己排起了轮值。她有事晚到的那天，对面的人给她盛了一碗热汤，说锅里一直留着她那一份。"
	}
]
const DEFAULT_ROUTE := {
	"id": "explore",
	"title": "自己的第一天",
	"ending": "%s把旧日程表收进抽屉，在新本子上只写了明天要做的一件事。她想先去听听街坊们怎么谋生，再试两样感兴趣的活儿。",
	"epilogue": "几个月后，她回家吃饭，袖口还有没拍干净的木屑。她讲起新学会修的那扇门，也约好了下次回来把家里松动的门把手修好。"
}

@onready var section: Label = %Section
@onready var heading: Label = %Heading
@onready var story: Label = %Story
@onready var advance: Button = %Advance
@onready var routes_list: VBoxContainer = %Routes
@onready var collection_notice: Label = %CollectionNotice

@export var gallery_mode := false

var route: Dictionary
var showing_epilogue := false

func _ready() -> void:
	if gallery_mode:
		ShowCollection()
		return
	SaveManager.restoring_save = false
	var selected := SelectEnding(Daughterstatus.attributes, Global.affection, Global.flags)
	ShowEnding(selected, Daughterstatus.firstname)
	if SaveManager.RecordEnding(selected["id"], Daughterstatus.firstname) != OK:
		collection_notice.text = "无法保存结局收藏。"
		collection_notice.show()

func SelectEnding(attributes: Dictionary, affection: Dictionary = {}, flags: Dictionary = {}) -> Dictionary:
	var selected := DEFAULT_ROUTE
	var best_score := MIN_ROUTE_SCORE
	for candidate in ROUTES:
		var stats: Array = candidate["stats"]
		var first_stat := float(attributes.get(stats[0], 0))
		var second_stat := float(attributes.get(stats[1], 0))
		if minf(first_stat, second_stat) < MIN_ROUTE_STAT:
			continue
		var score := (first_stat + second_stat) / 2.0
		score += clampf(affection.get(candidate["affection"], 0), 0.0, 40.0) * 2.0
		if score < MIN_ROUTE_SCORE:
			continue
		if flags.get("future_" + candidate["id"], false):
			return candidate
		if score > best_score or (score == best_score and selected == DEFAULT_ROUTE):
			best_score = score
			selected = candidate
	return selected

func ShowCollection() -> void:
	route = {}
	section.text = "画廊"
	heading.text = "结局收藏"
	story.hide()
	routes_list.show()
	for button in routes_list.get_children():
		routes_list.remove_child(button)
		button.queue_free()
	var collection := SaveManager.ReadEndingCollection()
	var entries := ROUTES + [DEFAULT_ROUTE]
	var unlocked := 0
	for entry in entries:
		var saved_name: Variant = null
		if collection.has_section_key("endings", entry["id"]):
			saved_name = collection.get_value("endings", entry["id"])
		var button := Button.new()
		button.custom_minimum_size.y = 48
		button.disabled = not saved_name is String
		button.text = "未解锁" if button.disabled else entry["title"]
		if not button.disabled:
			unlocked += 1
			button.pressed.connect(ShowEnding.bind(entry, saved_name))
		routes_list.add_child(button)
	collection_notice.text = "已收藏 %d / %d" % [unlocked, entries.size()]
	collection_notice.show()
	advance.text = "返回标题"
	advance.grab_focus()

func ShowEnding(entry: Dictionary, daughter_name: String) -> void:
	route = entry
	showing_epilogue = false
	section.text = "养成结局"
	heading.text = route["title"]
	story.text = route["ending"] % daughter_name
	story.show()
	collection_notice.hide()
	routes_list.hide()
	advance.text = "阅读后日谈"
	advance.grab_focus()

func _on_advance_pressed() -> void:
	if SceneTransition.is_transitioning:
		return
	if route.is_empty():
		SceneTransition.ChangeScene("res://sences/title.tscn")
		return
	if showing_epilogue:
		if gallery_mode:
			ShowCollection()
		else:
			SceneTransition.ChangeScene("res://sences/title.tscn")
		return
	showing_epilogue = true
	section.text = "后日谈"
	story.text = route["epilogue"]
	advance.text = "返回画廊" if gallery_mode else "返回标题"
