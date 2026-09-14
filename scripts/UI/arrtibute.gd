extends CanvasLayer

@onready var arrtibute_list: GridContainer = $ArrtibuteList
@onready var talk_layer: CanvasLayer = $"../TalkLayer"

@onready var attribute_nodes:Dictionary = {
	"stamina": $ArrtibuteList/stamina,
	"smarts": $ArrtibuteList/smarts,
	"charm": $ArrtibuteList/charm,
	"pride": $ArrtibuteList/pride,
	"morals": $ArrtibuteList/morals,
	"highclass": $ArrtibuteList/highclass,
	"sensitive": $ArrtibuteList/sensitive,
	"temper": $ArrtibuteList/temper,
	"fame": $ArrtibuteList/fame,
	"martial": $ArrtibuteList/martial,
	"magic": $ArrtibuteList/magic,
	"crime": $ArrtibuteList/crime,
	"stress": $ArrtibuteList/stress
}

@onready var colors:Dictionary = {
	"up":Color("#a0d4ff"),
	"down":Color("#ffb3a0"),
	"normal":Color("#a0ffda")
}

# scale=2所以减一半
var move_vector = Vector2(250,0)
var keys:Array
var annotation_visible: bool = false
var is_closing: bool = false
var base_position: Vector2
var current_tween: Tween = null

signal settle_end

func _ready() -> void:
	layer = 3
	base_position = arrtibute_list.position
	hide()
	AttributeHide()

func AttributeHide():
	# 初始所有节点隐藏
	for key in attribute_nodes.keys():
		attribute_nodes[key].hide()

func _input(event: InputEvent) -> void:
	if not visible:
		return
		
	# 当属性动画显示或正在收回时，拦截所有鼠标按键输入，绝对禁止点击穿透到底层界面的任何按钮（如返回、购买等）
	if event is InputEventMouseButton:
		if event.is_action_pressed("confirm") and annotation_visible and not is_closing:
			annotation_visible = false
			AnnotationEnd()
		get_viewport().set_input_as_handled()
		return
		
	# 键盘确认键响应（Enter / Space 等）
	if event.is_action_pressed("confirm"):
		if annotation_visible and not is_closing:
			annotation_visible = false
			AnnotationEnd()
		get_viewport().set_input_as_handled()

func _update_character_attribute_ui() -> void:
	if get_tree() and get_tree().current_scene:
		var char_attr = get_tree().current_scene.get_node_or_null("UI/CharacterAttribute")
		if char_attr and char_attr.has_method("UpdateStatus"):
			char_attr.UpdateStatus()

# 初始直接生成所有按钮，用到的show
func AnnotationStart(arrtibute_dict:Dictionary):
	if arrtibute_dict == null or arrtibute_dict.is_empty():
		call_deferred("emit_signal", "settle_end")
		return

	if current_tween and current_tween.is_valid():
		current_tween.kill()

	is_closing = false
	annotation_visible = false
	AttributeHide()
	show()

	var target_pos = base_position - move_vector
	current_tween = get_tree().create_tween()
	current_tween.set_parallel(true)
	current_tween.tween_property(arrtibute_list, "position", target_pos, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	for key in arrtibute_dict.keys():
		var delta = float(arrtibute_dict[key])
		var old_val = Daughterstatus.attributes.get(key, 0.0)
		Daughterstatus.AddAttribute(key, delta)
		var new_val = Daughterstatus.attributes.get(key, 0.0)

		if attribute_nodes.has(key):
			var node: Control = attribute_nodes[key]
			var num: Label = node.get_node("Num")
			var progressbar: TextureProgressBar = node.get_node("TextureProgressBar")
			node.show()

			if delta > 0:
				num.add_theme_color_override("font_color", colors["up"])
			elif delta < 0:
				num.add_theme_color_override("font_color", colors["down"])
			else:
				num.add_theme_color_override("font_color", colors["normal"])

			num.text = str(int(old_val))
			progressbar.value = old_val
			current_tween.tween_method(
				func(v: float):
					num.text = str(int(v))
					progressbar.value = v,
				old_val,
				new_val,
				0.3
			).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	current_tween.chain().tween_callback(func():
		annotation_visible = true
		_update_character_attribute_ui()
	)
	
func AnnotationEnd():
	annotation_visible = false
	is_closing = true
	if current_tween and current_tween.is_valid():
		current_tween.kill()

	current_tween = get_tree().create_tween()
	current_tween.tween_property(arrtibute_list, "position", base_position, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	current_tween.tween_callback(AttributeHide)
	current_tween.tween_callback(hide)
	current_tween.tween_callback(func():
		is_closing = false
		_update_character_attribute_ui()
		settle_end.emit()
	)

func _on_talk_layer_attribute_settle(attribute_dict: Variant) -> void:
	AnnotationStart(attribute_dict)
