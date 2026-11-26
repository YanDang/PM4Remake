extends CanvasLayer

signal closed

enum Mode {SAVE, LOAD}

const SLOT_SCENE = preload("res://UI/save_slot.tscn")
const EMPTY_COLOR = Color(0.56, 0.56, 0.56)
const SAVED_COLOR = Color(1, 0.94, 0.84)
const HOVER_COLOR = Color(0.6, 1, 0.65)

@onready var slots_root: Control = $Screen/Canvas/Slots
@onready var details: Label = $Screen/Canvas/Details/Label
@onready var return_button: Button = $Screen/Canvas/Return
@onready var confirmation: Control = $Screen/Canvas/Confirmation
@onready var dialog_box: NinePatchRect = $Screen/Canvas/Confirmation/Box
@onready var prompt: Label = $Screen/Canvas/Confirmation/Box/Prompt
@onready var yes_button: Button = $Screen/Canvas/Confirmation/Box/Yes
@onready var no_button: Button = $Screen/Canvas/Confirmation/Box/No

var slot_buttons: Array[Button] = []
var slot_info: Array[Dictionary] = []
var hovered_slot: int = -1
var pending_slot: int = -1
var overwrite_confirmed: bool = false
var showing_error: bool = false
var mode: Mode = Mode.SAVE
var is_animating: bool = false
var animation_elements: Array = []

func _ready() -> void:
	for index in range(SaveManager.SLOT_COUNT):
		var button = SLOT_SCENE.instantiate() as Button
		button.name = "Slot%d" % (index + 1)
		button.position = Vector2(28 + (index / 5) * 298, 80 + (index % 5) * 50)
		button.get_node("DataLabel").text = "Data %d" % (index + 1)
		slots_root.add_child(button)
		button.mouse_entered.connect(HoverSlot.bind(index))
		button.focus_entered.connect(HoverSlot.bind(index))
		button.mouse_exited.connect(LeaveSlot.bind(index))
		button.pressed.connect(SelectSlot.bind(index))
		slot_buttons.append(button)
		animation_elements.append({"node": button, "position": button.position, "offset": Vector2(-640 if index < 5 else 640, 0)})
	for element in [$Screen/Canvas/Heading, $Screen/Canvas/Details, return_button]:
		animation_elements.append({"node": element, "position": element.position, "offset": Vector2(640 if element == return_button else -640, 0)})
	return_button.pressed.connect(Close)
	yes_button.pressed.connect(ConfirmSave)
	no_button.pressed.connect(CancelConfirmation)

func Open(open_mode: Mode = Mode.SAVE) -> void:
	mode = open_mode
	$Screen/Canvas/Heading/Label.text = "读 档" if mode == Mode.LOAD else "存 档"
	pending_slot = -1
	hovered_slot = -1
	confirmation.hide()
	RefreshSlots()
	details.text = ""
	show()
	await AnimatePanel(true)

func AnimatePanel(entering: bool) -> void:
	is_animating = true
	SetButtonsEnabled(false)
	var tween = create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for element in animation_elements:
		if entering:
			element["node"].position = element["position"] + element["offset"]
		var target = element["position"] if entering else element["position"] + element["offset"]
		tween.tween_property(element["node"], "position", target, 0.4)
	await tween.finished
	is_animating = false
	if entering:
		SetButtonsEnabled(true)

func ExitForLoad() -> void:
	confirmation.hide()
	await AnimatePanel(false)

func RefreshSlots() -> void:
	slot_info.clear()
	for index in range(SaveManager.SLOT_COUNT):
		var info = SaveManager.GetSlotInfo(index)
		slot_info.append(info)
		var date_label = slot_buttons[index].get_node("DateLabel") as Label
		if info["valid"]:
			var metadata = info["metadata"]
			date_label.text = "第%d年 %d月 %d日" % [metadata["game_year"], metadata["month"], metadata["day"]]
		elif info["exists"]:
			date_label.text = "记录损坏"
		else:
			date_label.text = ""
		SetSlotColor(index, false)

func SetSlotColor(index: int, hovered: bool) -> void:
	var label = slot_buttons[index].get_node("DataLabel") as Label
	var color = SAVED_COLOR if slot_info[index]["exists"] else EMPTY_COLOR
	label.add_theme_color_override("font_color", HOVER_COLOR if hovered else color)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.4, 0.13) if hovered else Color(0.3, 0.18, 0.12))
	slot_buttons[index].get_node("DateLabel").add_theme_color_override("font_color", HOVER_COLOR if hovered else SAVED_COLOR)

func HoverSlot(index: int) -> void:
	if not visible or confirmation.visible or is_animating:
		return
	if hovered_slot >= 0:
		SetSlotColor(hovered_slot, false)
	hovered_slot = index
	SetSlotColor(index, true)
	var info = slot_info[index]
	if info["valid"]:
		var metadata = info["metadata"]
		details.text = "父亲：%s　女儿：%s\n%d 岁　%s" % [metadata["father_name"], metadata["daughter_name"], metadata["age"], metadata["saved_at"]]
	elif info["exists"]:
		details.text = "此记录无法读取。" if mode == Mode.LOAD else "此记录无法读取，保存后将覆盖该记录。"
	else:
		details.text = ""

func LeaveSlot(index: int) -> void:
	if hovered_slot == index and not confirmation.visible:
		SetSlotColor(index, false)
		hovered_slot = -1
		details.text = ""

func SetButtonsEnabled(enabled: bool) -> void:
	for button in slot_buttons:
		button.disabled = not enabled
	return_button.disabled = not enabled

func SelectSlot(index: int) -> void:
	if not visible or confirmation.visible or is_animating or SceneTransition.is_transitioning:
		return
	pending_slot = index
	# Recheck the file, since it may have changed since the panel opened.
	var info = SaveManager.GetSlotInfo(index)
	if mode == Mode.LOAD and not info["valid"]:
		if info["exists"]:
			ShowError("此记录已损坏或版本不兼容，无法读取。")
		else:
			ShowError("这里没有游戏记录。")
		return
	overwrite_confirmed = info["exists"]
	showing_error = false
	ShowConfirmation()

func ShowConfirmation() -> void:
	SetButtonsEnabled(false)
	details.text = ""
	if hovered_slot >= 0:
		SetSlotColor(hovered_slot, false)
		hovered_slot = -1
	if mode == Mode.LOAD:
		prompt.text = "要读取游戏进度吗？"
	else:
		prompt.text = "这里已经有记录资料存在。\n要覆盖记录吗？" if overwrite_confirmed else "要储存游戏吗？"
	SetDialogHeight(152.0 if mode == Mode.SAVE and overwrite_confirmed else 128.0)
	yes_button.show()
	no_button.text = "否"
	confirmation.show()
	no_button.grab_focus()

func SetDialogHeight(height: float) -> void:
	dialog_box.size.y = height
	prompt.size.y = height - 100.0
	yes_button.position.y = height - 56.0
	no_button.position.y = height - 56.0

func ConfirmSave() -> void:
	if not confirmation.visible or showing_error or pending_slot < 0 or is_animating or SceneTransition.is_transitioning:
		return
	if mode == Mode.LOAD:
		var load_error = SaveManager.LoadSlot(pending_slot)
		if load_error != OK:
			ShowError("读取失败（%s）。\n原有游戏进度未改变。" % error_string(load_error))
			return
		var destination := Global.ENDING_SCENE if Global.passed_training_deadline() else "res://sences/main.tscn"
		SceneTransition.ChangeScene(destination, ExitForLoad)
		return
	var error = SaveManager.SaveSlot(pending_slot, overwrite_confirmed)
	if error == ERR_ALREADY_EXISTS:
		overwrite_confirmed = true
		ShowConfirmation()
		return
	if error != OK:
		ShowError("保存失败（%s）。\n请检查存档目录后重试。" % error_string(error))
		return
	var saved_slot = pending_slot
	CancelConfirmation()
	RefreshSlots()
	HoverSlot(saved_slot)

func ShowError(message: String) -> void:
	showing_error = true
	SetButtonsEnabled(false)
	prompt.text = message
	SetDialogHeight(152.0)
	yes_button.hide()
	no_button.text = "确定"
	confirmation.show()
	no_button.grab_focus()

func CancelConfirmation() -> void:
	confirmation.hide()
	showing_error = false
	pending_slot = -1
	SetButtonsEnabled(true)
	yes_button.release_focus()
	no_button.release_focus()

func Close() -> void:
	if is_animating or SceneTransition.is_transitioning:
		return
	if confirmation.visible:
		CancelConfirmation()
		return
	await AnimatePanel(false)
	hide()
	closed.emit()

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("cancel"):
		get_viewport().set_input_as_handled()
		Close()
