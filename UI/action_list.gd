extends Sprite2D

@export var character: Node2D
@export var goalenemy: Node2D

signal atk_pressed(character:Node2D, goalenemy:Node2D)

func _ready():
	$ATK.pressed.connect(_on_atc_pressed)

func _on_atc_pressed():
	emit_signal("atk_pressed", character, goalenemy)
