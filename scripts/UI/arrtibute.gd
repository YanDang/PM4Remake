extends CanvasLayer

@onready var arrtibute_list: GridContainer = $ArrtibuteList

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

signal settle_end

func _ready() -> void:
	hide()
	AttributeHide()

func AttributeHide():
	# 初始所有节点隐藏
	for key in attribute_nodes.keys():
		attribute_nodes[key].hide()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("confirm") and annotation_visible:
		annotation_visible = false
		AnnotationEnd()
		# 吃事件,阻止事件向下传递
		get_viewport().set_input_as_handled()

# 初始直接生成所有按钮，用到的show
func AnnotationStart(arrtibute_dict:Dictionary):
	show()
	var tween = get_tree().create_tween()  # 创建一个 Tween
	tween.tween_property(arrtibute_list, "position", arrtibute_list.position-move_vector, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for key in arrtibute_dict.keys():
		var num:Label = attribute_nodes[key].get_node("Num")
		var progressbar:TextureProgressBar = attribute_nodes[key].get_node("TextureProgressBar")
		attribute_nodes[key].show()
		if arrtibute_dict[key] > 0:
			num.add_theme_color_override("font_color",colors["up"])
		elif arrtibute_dict[key] < 0:
			num.add_theme_color_override("font_color",colors["down"])
		else:
			num.add_theme_color_override("font_color",colors["normal"])
		# 全局数值更新
		Daughterstatus.attributes[key] += arrtibute_dict[key]
		num.text = str(int(Daughterstatus.attributes[key]))
		progressbar.value = Daughterstatus.attributes[key]
	tween.tween_callback(func():annotation_visible=true)
	
func AnnotationEnd():
	var tween = get_tree().create_tween()  # 创建一个 Tween
	tween.tween_property(arrtibute_list, "position", arrtibute_list.position+move_vector, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(AttributeHide)
	tween.tween_callback(hide)
	tween.tween_callback(func():emit_signal("settle_end"))
