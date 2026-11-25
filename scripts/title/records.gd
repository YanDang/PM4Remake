extends Node

func _ready() -> void:
	$BackGround.texture = load(Global.get_room_background_path())
	$SavePanel.closed.connect(ReturnToTitle)
	$SavePanel.Open(1)

func ReturnToTitle() -> void:
	SceneTransition.ChangeScene("res://sences/title.tscn")
