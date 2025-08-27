extends "res://scripts/characterfightstats.gd"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	name = "Lise"
	matk = 0
	emit_signal("stats_changed")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
