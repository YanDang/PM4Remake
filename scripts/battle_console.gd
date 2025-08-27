extends Node

@onready var action_list: Sprite2D = $"../ActionList"
@onready var daughter: Node2D = $"../Characters/Daughter"

enum DamageType { PHYSICAL, MAGIC }

var character_offset = Vector2(50,0)
var goalenemy_offset = Vector2(-50,0)
signal action_finished(character: Node2D, goalenemy: Node2D)

func _ready() -> void:
	connect("action_finished", Callable(self, "_on_action_finished"))

func _deal_damage(character: Node2D, goalenemy: Node2D, damage_type:int,offset:Vector2) -> void:
	var goalenemy_sprite = goalenemy.get_node("AnimatedSprite2D")
	var hit_target = damage_settlement(character, goalenemy, damage_type)
	# 命中则播放受击动画
	if hit_target:
		goalenemy_sprite.play("hit")
	else:
		var start_pos = goalenemy.position
		var miss_tween = goalenemy.get_tree().create_tween()
		miss_tween.tween_property(goalenemy, "position", start_pos - offset, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		miss_tween.tween_property(goalenemy, "position", start_pos, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	goalenemy.emit_signal("stats_changed")

func damage_settlement(character: Node2D, goalenemy:Node2D,damage_type:int) -> bool:
	var dodge_rand = randi() % 100 + 1
	# 攻击命中
	if dodge_rand > goalenemy.dodge:
		var criticalhit_rand = randi() % 100
		match damage_type:
			DamageType.PHYSICAL:
				# 暴击
				if criticalhit_rand < character.criticalhit:
					goalenemy.hp -= max(1,character.atk*character.criticaldamage-goalenemy.def)
				else:
					goalenemy.hp -= max(1,character.atk-goalenemy.def)
			DamageType.MAGIC:
				# 暴击
				if criticalhit_rand < character.criticalhit:
					goalenemy.hp -= max(1,character.mtk*character.criticaldamage/goalenemy.mdef)
				else:
					goalenemy.hp -= max(1,character.mtk/goalenemy.mdef)
		goalenemy.hp = max(0,goalenemy.hp)
		return true
	return false

func atk_action(character: Node2D, goalenemy:Node2D, offset:Vector2):
	action_list.hide()
	var character_sprite = character.get_node("AnimatedSprite2D")
	var goalenemy_sprite = goalenemy.get_node("AnimatedSprite2D")
	var start_pos = character.position  # 记录初始位置
	var end_pos = goalenemy.position + offset
	var tween = character.get_tree().create_tween()  # 创建一个 Tween
	# 1. 移动到 endpoint
	tween.tween_property(character, "position", end_pos, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# 2. 播放 attack 动画（在到达之后）
	tween.tween_callback(Callable(character_sprite, "play").bind("attack"))
	tween.tween_callback(Callable(self, "_deal_damage").bind(character, goalenemy, DamageType.PHYSICAL,offset))
	# 3. 等待攻击动画时间，然后回到原位
	tween.tween_interval(0.7)
	tween.tween_property(character, "position", start_pos, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# 4. 回到原位后设置 idle
	tween.tween_callback(Callable(character_sprite, "play").bind("idle"))
	tween.tween_callback(Callable(goalenemy_sprite, "play").bind("idle"))
	tween.tween_callback(Callable(action_list, "show"))
	tween.tween_callback(func():emit_signal("action_finished", character, goalenemy))


func _on_action_list_atk_pressed(character: Node2D, goalenemy: Node2D) -> void:
	# 第一个攻击完成后，调用第二个攻击
	atk_action(character, goalenemy, character_offset)

func _on_action_finished(character: Node2D, goalenemy: Node2D) -> void:
	if character == daughter:
		# 玩家行动结束，敌人行动一次
		atk_action(goalenemy, character, goalenemy_offset)
	else:
		# 敌人行动结束，回到菜单
		action_list.show()
