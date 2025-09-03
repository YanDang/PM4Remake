extends Node2D

@onready var stamina: Sprite2D = $stamina
@onready var smarts: Sprite2D = $smarts
@onready var charm: Sprite2D = $charm
@onready var pride: Sprite2D = $pride
@onready var morals: Sprite2D = $morals
@onready var highclass: Sprite2D = $highclass
@onready var sensitive: Sprite2D = $sensitive
@onready var temper: Sprite2D = $temper
@onready var fame: Sprite2D = $fame
@onready var martial: Sprite2D = $martial
@onready var magic: Sprite2D = $magic
@onready var crime: Sprite2D = $crime
@onready var stress: Sprite2D = $stress

func _ready() -> void:
	UpdateStatus()

func UpdateProgressBar(target_sprite:Sprite2D,val:int):
	target_sprite.get_node("Num").text = str(val)
	target_sprite.get_node("TextureProgressBar").value = val

func UpdateStatus() -> void:
	for key in Daughterstatus.attributes.keys():
		var node = get_node(key) # 假设 UI 节点名字和 key 一致
		UpdateProgressBar(node, Daughterstatus.attributes[key])
