extends CharacterFightStats

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	name = "Lise"
	matk = 0
	emit_signal("stats_changed")
