extends CanvasLayer

const FADE_DURATION: float = 0.4

var is_transitioning: bool = false
var curtain: ColorRect

func _ready() -> void:
	layer = 100
	curtain = ColorRect.new()
	curtain.color = Color(0, 0, 0, 0)
	curtain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	curtain.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(curtain)
	hide()

func FadeTo(alpha: float) -> void:
	var tween = create_tween()
	tween.tween_property(curtain, "color:a", alpha, FADE_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

func ChangeScene(scene_path: String, exit_animation: Callable = Callable()) -> void:
	if is_transitioning:
		return
	is_transitioning = true
	show()
	if exit_animation.is_valid():
		await exit_animation.call()
	await FadeTo(1.0)
	var error = get_tree().change_scene_to_file(scene_path)
	if error == OK:
		await get_tree().scene_changed
	else:
		push_error("Failed to change scene to %s: %s" % [scene_path, error_string(error)])
	await FadeTo(0.0)
	hide()
	is_transitioning = false

func QuitGame() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	show()
	await FadeTo(1.0)
	get_tree().quit()
