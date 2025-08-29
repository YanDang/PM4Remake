extends "res://scripts/characterfightstats.gd"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	name = "Daughter"
	emit_signal("stats_changed")
