extends Sprite2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	UpdateStatus()


func UpdateStatus() -> void:
	$B.text = str(int(Daughterstatus.bust))
	$W.text = str(int(Daughterstatus.waist))
	$H.text = str(int(Daughterstatus.hips))
	$High.text = str(int(Daughterstatus.high))
	$Weight.text = str(int(Daughterstatus.weight))
	$Tactics.text = Global.health_tactics[Global.health_index]
