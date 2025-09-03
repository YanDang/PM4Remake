extends Node

@onready var back_ground: TextureRect = $BackGround
@onready var dautghter_live: Node2D = $DautghterLive
@onready var ui: CanvasLayer = $UI
@onready var talk_layer: CanvasLayer = $TalkLayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	back_ground.show()
	dautghter_live.show()
	ui.show()
	talk_layer.TalkEnd()
