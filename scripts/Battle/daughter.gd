extends CharacterFightStats

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	name = Daughterstatus.firstname + "·" + Daughterstatus.secondname
	emit_signal("stats_changed")
