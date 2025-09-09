extends Node2D

@onready var anim: AnimatedSprite2D = $Anim

#func _ready() -> void:
	#LoadSpriteFrames("art")
	#anim.play("fail")

func LoadSpriteFrames(plan:String):
	print("res://animation/schedule/%s.tres" % plan)
	anim.sprite_frames = load("res://animation/schedule/%s.tres" % plan)

func EventHappen(result:String):
	anim.play(result)
