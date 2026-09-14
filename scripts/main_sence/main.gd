extends Node

@onready var back_ground: TextureRect = $BackGround
@onready var daughter_live: Node2D = $DaughterLive
@onready var ui: CanvasLayer = $UI
@onready var talk_layer: CanvasLayer = $TalkLayer
@onready var item_info: CanvasLayer = $ItemInfo

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	UpdateRoomBackground()
	back_ground.show()
	daughter_live.show()
	ui.show()
	item_info.hide()
	talk_layer.TalkEnd()
	#event_test()

# 更新主场景房间背景（根据当前季节与画作解锁等级）
func UpdateRoomBackground() -> void:
	var bg_path = Global.get_room_background_path()
	if ResourceLoader.exists(bg_path):
		back_ground.texture = load(bg_path)
	else:
		push_warning("Background resource not found: %s" % bg_path)

# 按键调试支持：F5切换季节，F6切换画作等级
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F5:
			# F5: 推进3个月切换季节 (春 4月 -> 夏 7月 -> 秋 10月 -> 冬 1月 -> 春 4月)
			Global.month = (Global.month + 2) % 12 + 1
			Global.sync_week_index()
			UpdateRoomBackground()
			var date_node = get_node_or_null("UI/Date")
			if date_node and date_node.has_method("UpdateStatus"):
				date_node.UpdateStatus()
			print("[调试] 季节切换 -> %s季 (%d月, 周%s), 背景图: %s" % [Global.get_current_season_name(), Global.month, Global.week_list[Global.week_index], Global.get_room_background_path()])
		elif event.keycode == KEY_F6:
			# F6: 循环切换画作等级 (0 -> 1 -> 2 -> 3 -> 0)
			Global.art_painting_level = (Global.art_painting_level + 1) % 4
			UpdateRoomBackground()
			var level_names = ["无画作", "中级-郁金香", "上级-几何苹果", "专业-丘陵独树"]
			print("[调试] 画作等级切换 -> %d (%s), 背景图: %s" % [Global.art_painting_level, level_names[Global.art_painting_level], Global.get_room_background_path()])

## 测试一个对话->选项->对话->属性加成的功能
#func event_test() -> void:
	#talk_layer.TalkStart([{
				#"character": "daughter",
				#"emotion": "happy",
				#"text": "这里是PM4Remake",
				#"voice": ""
			#}],2,{},["是","否"])
	#
#func _on_talk_layer_choice_result(choice_index: Variant) -> void:
	#print(choice_index)
	#
	#if choice_index == 0:
		#talk_layer.TalkStart([{
				#"character": "daughter",
				#"emotion": "happy",
				#"text": "选择了‘是’",
				#"voice": ""
			#}],1,{"smarts":10})
	#else:
		#talk_layer.TalkStart([{
				#"character": "daughter",
				#"emotion": "happy",
				#"text": "选择了‘否’",
				#"voice": ""
			#}],1,{"fame":1})
