extends CanvasLayer

@onready var talk_text: Label = $TalkEvent/TalkBox/TalkText
@onready var headshot: Sprite2D = $TalkEvent/People/Headshot
@onready var first_name: Label = $TalkEvent/People/FirstName
# 女主和女配有年龄差分
@onready var special_name: Array = ["daughter","lise","christina","marie"]

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

var talk_even = [["daughter","happy","感谢游玩！"],["daughter","calm","这是PM4重制版"],["daughter","surprised","项目免费开源"]]
var current_index = 0

func _ready() -> void:
	$ColorRect.MOUSE_FILTER_STOP

func talk_polling(talk_even:Array):
	if current_index < talk_even.size():
		var entry = talk_even[current_index]
		Happen(entry[0], entry[1], entry[2])
		current_index += 1
	else:
		hide()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("confirm"):
		talk_polling(talk_even)

# 谁，什么情绪，说啥了
func Happen(who:String,emotion:String,text:String) -> void:
	if who in special_name:
		icon_path = "res://assets/PM4_FC/" + Globaljson.icon_path[who][Daughterstatus.age_stage_names[Daughterstatus.age_stage]] + emotions[emotion] + ".png"
	else:
		icon_path = "res://assets/PM4_FC/" + Globaljson.icon_path[who] + emotions[emotion] + ".png"
	headshot.show()
	if who == "daughter":
		first_name.text = Daughterstatus.firstname
	else:
		first_name.text = who
	if not emotions.get(emotion):
		headshot.hide()
		push_warning("Load emotion ERROR")
		return
	print(icon_path)
	headshot.texture = load(icon_path)
	talk_text.text = text
