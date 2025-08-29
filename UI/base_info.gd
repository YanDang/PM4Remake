extends Sprite2D

func _ready() -> void:
	$FirstName.text = Daughterstats.firstname
	$SecondName.text = Daughterstats.secondname
	updatestats()

func updatestats() -> void:
	$Age.text = str(Daughterstats.age)
	$Money.text = str(Global.money)
