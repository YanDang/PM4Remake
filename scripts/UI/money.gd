extends Sprite2D

var temp_money:int

@onready var label: Label = $Label

@onready var colors:Dictionary = {
	"up":Color("#a0ffda"),
	"down":Color("#ffb3a0"),
	"normal":Color("#fef2a4")
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	temp_money = Global.money
	$Label.text = str(Global.money)

func UpdateStatus() -> void:
	if temp_money != Global.money:
		var tween = create_tween()
		if temp_money < Global.money:
			tween.tween_property(label, "theme_override_colors/font_color",colors['up'],0.3)
		elif temp_money > Global.money:
			tween.tween_property(label, "theme_override_colors/font_color",colors['down'],0.3)
		tween.tween_property(label, "theme_override_colors/font_color",colors['normal'],0.3)
	$Label.text = str(Global.money)
