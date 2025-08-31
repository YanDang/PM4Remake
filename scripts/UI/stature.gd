extends Node2D

@onready var height: Sprite2D = $height
@onready var weight: Sprite2D = $weight
@onready var b: Sprite2D = $B
@onready var w: Sprite2D = $W
@onready var h: Sprite2D = $H

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	UpdateStatus()

func UpdateProgressBar(target_sprite:Sprite2D,val:int):
	target_sprite.get_node("Num").text = str(val)
	target_sprite.get_node("TextureProgressBar").value = val

func UpdateStatus() -> void:
	UpdateProgressBar(height,Daughterstatus.height)
	UpdateProgressBar(weight,Daughterstatus.weight)
	UpdateProgressBar(b,int(Daughterstatus.bust))
	UpdateProgressBar(w,int(Daughterstatus.waist))
	UpdateProgressBar(h,int(Daughterstatus.hips))
