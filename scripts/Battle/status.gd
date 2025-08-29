extends Sprite2D

@export var character: Node2D

var max_hp_scale = 120

func UpdateStatus() -> void:
	$Name.text = character.name
	$HP.text = str(character.hp)
	$ATK.text = str(character.atk)
	$DEF.text = str(character.def)
	$MATK.text = str(character.matk)
	$MDEF.text = str(character.mdef)
	$HPScale.size.x = clamp(character.hp * max_hp_scale / character.maxhp, 0, max_hp_scale)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	character.stats_changed.connect(UpdateStatus)
	UpdateStatus()
