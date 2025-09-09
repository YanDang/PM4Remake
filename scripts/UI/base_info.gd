extends Sprite2D

var temp_money:int

@onready var money: Label = $Money

@onready var colors:Dictionary = {
	"up":Color("#a0ffda"),
	"down":Color("#ffb3a0"),
	"normal":Color("#fef2a4")
}


func _ready() -> void:
	$FirstName.text = Daughterstatus.firstname
	$SecondName.text = Daughterstatus.secondname
	temp_money = Global.money
	UpdateStatus()

func UpdateStatus() -> void:
	$Age.text = str(Daughterstatus.age)
	$Money.text = str(Global.money)
	if temp_money != Global.money:
		var tween = create_tween()
		if temp_money < Global.money:
			tween.tween_property(money, "theme_override_colors/font_color",colors['up'],0.3)
		if temp_money > Global.money:
			tween.tween_property(money, "theme_override_colors/font_color",colors['down'],0.3)
		tween.tween_property(money, "theme_override_colors/font_color",colors['normal'],0.2)
		temp_money = Global.money
