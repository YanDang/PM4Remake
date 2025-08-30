extends Sprite2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	UpdateStatus()

func UpdateStatus() -> void:
	$Label.text = str(Global.money)
