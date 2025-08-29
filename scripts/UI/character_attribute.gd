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
	UpdateProgressBar(stamina,Daughterstatus.stamina)
	UpdateProgressBar(smarts,Daughterstatus.smarts)
	UpdateProgressBar(charm,Daughterstatus.charm)
	UpdateProgressBar(pride,Daughterstatus.pride)
	UpdateProgressBar(morals,Daughterstatus.morals)
	UpdateProgressBar(highclass,Daughterstatus.highclass)
	UpdateProgressBar(sensitive,Daughterstatus.sensitive)
	UpdateProgressBar(temper,Daughterstatus.temper)
	UpdateProgressBar(fame,Daughterstatus.fame)
	UpdateProgressBar(martial,Daughterstatus.martial)
	UpdateProgressBar(magic,Daughterstatus.magic)
	UpdateProgressBar(crime,Daughterstatus.crime)
	UpdateProgressBar(stress,Daughterstatus.stress)
