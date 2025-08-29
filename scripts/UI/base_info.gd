extends Sprite2D

func _ready() -> void:
	$FirstName.text = Daughterstatus.firstname
	$SecondName.text = Daughterstatus.secondname
	UpdateStatus()

func UpdateStatus() -> void:
	$Age.text = str(Daughterstatus.age)
	$Money.text = str(Global.money)
