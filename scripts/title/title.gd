extends Node

@onready var scene_manager = get_tree()
@export var main_scene_path: String = "res://sences/main.tscn"

func _on_start_button_down() -> void:
	scene_manager.change_scene_to_file(main_scene_path)

func _on_exit_button_down() -> void:
	scene_manager.quit()
