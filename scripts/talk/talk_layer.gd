extends CanvasLayer

@onready var talk_text: Label = $TalkEvent/TalkBox/TalkText
@onready var headshot: Sprite2D = $TalkEvent/People/Headshot
@onready var first_name: Label = $TalkEvent/People/FirstName
@onready var arrtibute: CanvasLayer = $"../Arrtibute"

# 女主和女配有年龄差分
@onready var special_name: Array = ["daughter","lise","christina","marie"]

signal talk_end
signal attribute_settle(attribute_dict)

# 平静，开心，生气，失望，惊讶，怀疑，喜出望外，伤心，不满，不耐烦，生病
@onready var emotions:Dictionary = {
	"calm": "01",
	"happy": "02",
	"angry": "03",
	"disappointed": "04",
	"surprised": "05",
	"doubtful": "06",
	"overjoyed": "07",
	"sad": "08",
	"dissatisfied": "09",
	"impatient": "10",
	"sick": "11"
}

var icon_path:String

var current_index:int = 0
var talk_even:Array
# 需要属性变更
var is_settle:bool = false
var allow_emit:bool = true
var attribute_dict:Dictionary

func TalkStart(talk_array:Array,data_dict:Dictionary={}):
	current_index = 0
	if data_dict.is_empty():
		is_settle = false
	else:
		is_settle = true
		attribute_dict = data_dict
		allow_emit = true
		
	show()
	talk_even = talk_array
	set_process_input(true)
	TalkPolling()  # 立刻显示第一句

func TalkEnd():
	set_process_input(false)  # 完全停止输入处理
	hide()
	emit_signal("talk_end")

func TalkPolling():
	if current_index < talk_even.size():
		var entry = talk_even[current_index]
		Happen(entry["character"], entry["emotion"], entry["text"])
		current_index += 1
	else:
		if is_settle:
			if allow_emit:
				# 发射结束信号,等待信号回传
				emit_signal("attribute_settle",attribute_dict)
				allow_emit = false
		else:
			# 不需要计算属性
			TalkEnd()
		

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("confirm"):
		TalkPolling()
	elif event.is_action_pressed("next_view"):
		if current_index < len(talk_even):
			TalkPolling()
	elif event.is_action_pressed("back_view"):
		if current_index > 1:
			current_index -= 2 
			TalkPolling()
	# 吃事件,阻止事件向下传递
	get_viewport().set_input_as_handled()
# 谁，什么情绪，说啥了
func Happen(who:String,emotion:String,text:String) -> void:
	if who in special_name:
		icon_path = "res://assets/PM4_FC/" + Globaljson.icon_path[who][Daughterstatus.age_stage_names[Daughterstatus.age_stage]] + emotions[emotion] + ".png"
	elif who == "":
		# 旁白
		headshot.hide()
		first_name.text = ""
		talk_text.text = text
		return 
	else:
		icon_path = "res://assets/PM4_FC/" + Globaljson.icon_path[who] + emotions[emotion] + ".png"
	headshot.show()
	if who == "daughter":
		first_name.text = Daughterstatus.firstname
	else:
		first_name.text = Globaljson.human_translation[who]
	if not emotions.get(emotion):
		headshot.hide()
		push_warning("Load emotion ERROR")
		return
	headshot.texture = load(icon_path)
	talk_text.text = text

func _on_arrtibute_settle_end() -> void:
	TalkEnd()
