extends Node2D

@onready var timer: Timer = $Timer
@onready var eyes: AnimatedSprite2D = $Eyes

var eye_index = 0
var all_animations = ["wink","wink_double"]

func _on_timer_timeout() -> void:
	eye_index ^= 1
	eyes.play(all_animations[eye_index])
