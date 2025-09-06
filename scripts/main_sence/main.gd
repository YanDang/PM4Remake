extends Node

@onready var back_ground: TextureRect = $BackGround
@onready var daughter_live: Node2D = $DaughterLive
@onready var ui: CanvasLayer = $UI
@onready var talk_layer: CanvasLayer = $TalkLayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	back_ground.show()
	daughter_live.show()
	ui.show()
	talk_layer.TalkEnd()
