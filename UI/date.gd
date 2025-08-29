extends Sprite2D

func _ready() -> void:
	updatestats()

func updatestats() -> void:
	$Week.text = str(Global.week_list[Global.week_index])
	$Year.text = str(Global.year)
	$Month.text = str(Global.month)
	$Day.text = str(Global.day)
