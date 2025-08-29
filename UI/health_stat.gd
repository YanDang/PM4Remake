extends Sprite2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	updatestats()


func updatestats() -> void:
	$B.text = str(int(Daughterstats.bust))
	$W.text = str(int(Daughterstats.waist))
	$H.text = str(int(Daughterstats.hips))
	$Heigh.text = str(int(Daughterstats.height))
	$Weight.text = str(int(Daughterstats.weight))
