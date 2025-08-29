extends CanvasLayer

@onready var daily_action: GridContainer = $DailyAction
@onready var plan: Button = $Plan
@onready var health_stat: Sprite2D = $HealthStat

@onready var birthday: Sprite2D = $Birthday
@onready var stature: Node2D = $Stature
@onready var character_attribute: Node2D = $CharacterAttribute

var move_vector = Vector2(500,0)

func _on_status_button_down() -> void:
	var tween = get_tree().create_tween()  # 创建一个 Tween
	tween.tween_property(daily_action, "position", daily_action.position+move_vector, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(plan, "position", plan.position+move_vector, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(health_stat, "position", health_stat.position+move_vector, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func():
		daily_action.hide()
		plan.hide()
		health_stat.hide())
	tween.tween_callback(func():
		birthday.show()
		stature.show()
		character_attribute.show())
	tween.tween_property(birthday, "position", birthday.position+move_vector, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(stature, "position", stature.position+move_vector, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(character_attribute, "position", character_attribute.position-move_vector, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
