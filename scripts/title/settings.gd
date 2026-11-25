extends Node

func _ready() -> void:
	$BackGround.texture = load(Global.get_room_background_path())
	$SettingsPanel.closed.connect(ReturnToTitle)
	$SettingsPanel.Open()

func ReturnToTitle() -> void:
	SceneTransition.ChangeScene("res://sences/title.tscn")
