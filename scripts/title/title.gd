extends Node

@export var main_scene_path: String = "res://sences/main.tscn"

func _on_start_button_down() -> void:
	if SceneTransition.is_transitioning:
		return
	SaveManager.StartNewGame()
	SceneTransition.ChangeScene(main_scene_path)

func _on_exit_button_down() -> void:
	SceneTransition.QuitGame()

func _on_load_button_down() -> void:
	SceneTransition.ChangeScene("res://sences/records.tscn", AnimateMenuExit)

func _on_setting_button_down() -> void:
	SceneTransition.ChangeScene("res://sences/settings.tscn", AnimateMenuExit)

func _on_gallery_button_down() -> void:
	SceneTransition.ChangeScene("res://sences/gallery.tscn", AnimateMenuExit)

func AnimateMenuExit() -> void:
	var menu = $GridContainer
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(menu, "position:x", menu.position.x + get_viewport().get_visible_rect().size.x, 0.4)
	await tween.finished
