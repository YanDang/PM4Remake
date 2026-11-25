extends Node

const SAVE_PANEL_SCENE = preload("res://UI/save_panel.tscn")
const SETTINGS_PANEL_SCENE = preload("res://UI/settings_panel.tscn")

@onready var menu: Node2D = $System
@onready var ui: CanvasLayer = $".."
@onready var talk_layer: CanvasLayer = $"../../TalkLayer"

var confirming_title: bool = false
var save_panel: CanvasLayer
var records_transitioning: bool = false
var settings_panel: CanvasLayer

func _on_choice_pressed(_choice_text: String, choice_index: int) -> void:
	if confirming_title or records_transitioning or SceneTransition.is_transitioning or (is_instance_valid(save_panel) and save_panel.visible) or (is_instance_valid(settings_panel) and settings_panel.visible):
		return
	if choice_index == 0:
		OpenSavePanel()
		return
	if choice_index == 1:
		OpenSavePanel(1)
		return
	if choice_index == 2:
		OpenSettingsPanel()
		return
	if choice_index != 3:
		return
	confirming_title = true
	menu.hide()
	talk_layer.keep_visible_on_end = true
	talk_layer.RegisterCallback(ConfirmReturnToTitle)
	talk_layer.TalkStart([{
		"character": "",
		"text": "要返回到游戏的标题画面。\n这样可以吗？"
	}], talk_layer.SettleType.CHOICE, {}, ["是", "否"], true)

func OpenSavePanel(open_mode: int = 0) -> void:
	if not is_instance_valid(save_panel):
		save_panel = SAVE_PANEL_SCENE.instantiate()
		get_tree().current_scene.add_child(save_panel)
		save_panel.closed.connect(CloseSystemPanel)
	records_transitioning = true
	ui.now_canvas_type = ui.CanvasType.SAVE
	await ui.AnimateRecordsInterface(false)
	await save_panel.Open(open_mode)
	records_transitioning = false

func OpenSettingsPanel() -> void:
	if not is_instance_valid(settings_panel):
		settings_panel = SETTINGS_PANEL_SCENE.instantiate()
		get_tree().current_scene.add_child(settings_panel)
		settings_panel.closed.connect(CloseSystemPanel)
	records_transitioning = true
	ui.now_canvas_type = ui.CanvasType.SETTINGS
	await ui.AnimateRecordsInterface(false)
	await settings_panel.Open()
	records_transitioning = false

func CloseSystemPanel() -> void:
	records_transitioning = true
	await ui.AnimateRecordsInterface(true)
	ui.now_canvas_type = ui.CanvasType.SYSTEM
	records_transitioning = false

func ConfirmReturnToTitle(choice_index: int) -> void:
	confirming_title = false
	talk_layer.keep_visible_on_end = false
	if choice_index == 0:
		ui.now_canvas_type = ui.CanvasType.TALK
		# 保留确认框，随其他界面组件一起滑出。
		talk_layer.choice_ui.show()
		SceneTransition.ChangeScene("res://sences/title.tscn", ui.AnimateTitleExit)
	else:
		talk_layer.hide()
		menu.show()
		ui.now_canvas_type = ui.CanvasType.SYSTEM

func _input(event: InputEvent) -> void:
	if confirming_title and event.is_action_pressed("cancel"):
		get_viewport().set_input_as_handled()
		talk_layer._on_choice_pressed("否", 1)
