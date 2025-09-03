extends Sprite2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	UpdateStatus()


func UpdateStatus() -> void:
	$B.text = str(int(Daughterstatus.body_stats["bust"]))
	$W.text = str(int(Daughterstatus.body_stats["waist"]))
	$H.text = str(int(Daughterstatus.body_stats["hips"]))
	$Height.text = str(int(Daughterstatus.body_stats["height"]))
	$Weight.text = str(int(Daughterstatus.body_stats["weight"]))
	$Tactics.text = Global.health_tactics[Global.health_index]
