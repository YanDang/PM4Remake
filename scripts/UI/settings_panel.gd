extends CanvasLayer

signal closed

const ROW_SCENE = preload("res://UI/settings_row.tscn")
const ROWS = [
	{"key": "music_volume", "label": "音 乐", "options": ["OFF", "小", "中", "大"]},
	{"key": "sound_volume", "label": "音 效", "options": ["OFF", "小", "中", "大"]},
	{"key": "voice_volume", "label": "语 音", "options": ["OFF", "小", "中", "大"]},
	{"key": "text_speed", "label": "讯息显示", "options": ["快速", "普通", "缓慢"]},
	{"key": "fullscreen", "label": "画 面", "options": ["视窗", "全屏幕"]}
]

@onready var return_button: Button = $Screen/Canvas/Return
@onready var status: Label = $Screen/Canvas/Status

var option_buttons: Dictionary = {}
var animation_elements: Array = []
var is_animating: bool = false

func _ready() -> void:
	var empty_style = StyleBoxEmpty.new()
	for row_index in range(ROWS.size()):
		var definition = ROWS[row_index]
		var row = ROW_SCENE.instantiate()
		row.name = definition["key"]
		row.position = Vector2(100, 88 + row_index * 60)
		row.get_node("Label").text = definition["label"]
		$Screen/Canvas/Rows.add_child(row)
		animation_elements.append({"node": row, "position": row.position, "offset": Vector2(-640 if row_index % 2 == 0 else 640, 0)})
		var group = ButtonGroup.new()
		var buttons: Array[Button] = []
		for index in range(definition["options"].size()):
			var button = Button.new()
			button.name = "Option%d" % index
			button.text = definition["options"][index]
			button.toggle_mode = true
			button.button_group = group
			button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			button.position = Vector2(194 + index * 72, 4)
			button.size = Vector2(72, 44)
			if row_index < 3:
				button.position.x = 194 if index == 0 else 264 + (index - 1) * 48
				button.size.x = 70 if index == 0 else 48
			elif definition["key"] == "fullscreen":
				button.position.x = 204 + index * 100
				button.size.x = 108
			button.add_theme_font_size_override("font_size", 25 if definition["key"] == "text_speed" else 28)
			for style in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
				button.add_theme_stylebox_override(style, empty_style)
			row.add_child(button)
			button.pressed.connect(ChangeOption.bind(definition["key"], index))
			buttons.append(button)
		option_buttons[definition["key"]] = buttons
	for element in [$Screen/Canvas/Heading, return_button]:
		animation_elements.append({"node": element, "position": element.position, "offset": Vector2(640 if element == return_button else -640, 0)})
	return_button.pressed.connect(Close)
	GameSettings.changed.connect(OnSettingsChanged)
	RefreshOptions()

func Open() -> void:
	status.text = ""
	RefreshOptions()
	show()
	await AnimatePanel(true)

func RefreshOptions() -> void:
	for key in option_buttons:
		var selected = int(GameSettings.GetValue(key))
		for index in range(option_buttons[key].size()):
			var button = option_buttons[key][index]
			var color = Color(1, 0.94, 0.7) if selected == index else Color(0.56, 0.56, 0.56)
			button.set_pressed_no_signal(selected == index)
			button.add_theme_color_override("font_color", color)
			button.add_theme_color_override("font_focus_color", color)
			button.add_theme_color_override("font_pressed_color", color)
			button.add_theme_color_override("font_hover_pressed_color", Color(0.6, 1, 0.65))

func OnSettingsChanged(_key: String) -> void:
	RefreshOptions()

func ChangeOption(key: String, index: int) -> void:
	if is_animating or SceneTransition.is_transitioning:
		return
	var value: Variant = bool(index) if key == "fullscreen" else index
	var error = GameSettings.SetValue(key, value)
	status.text = "本次调整已生效，但设置未能保存。" if error != OK else ""

func SetButtonsEnabled(enabled: bool) -> void:
	for buttons in option_buttons.values():
		for button in buttons:
			button.disabled = not enabled
	return_button.disabled = not enabled

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

func Close() -> void:
	if is_animating or SceneTransition.is_transitioning:
		return
	await AnimatePanel(false)
	hide()
	closed.emit()

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("cancel"):
		get_viewport().set_input_as_handled()
		Close()
