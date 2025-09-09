extends Sprite2D

@onready var colors:Dictionary = {
	"weekday":Color("#a0ffda"),
	"saturday":Color("#5692f6"),
	"sunday":Color("#fda3ba")
}

func _ready() -> void:
	UpdateStatus()

func UpdateStatus() -> void:
	$Week.text = str(Global.week_list[Global.week_index])
	if Global.week_index == 0:
		$Week.add_theme_color_override("font_color", colors["sunday"])
	elif Global.week_index == 6:
		$Week.add_theme_color_override("font_color", colors["saturday"])
	else:
		$Week.add_theme_color_override("font_color", colors["weekday"])
	$Year.text = str(Global.year)
	$Month.text = str(Global.month)
	$Day.text = str(Global.day)
