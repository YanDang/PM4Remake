extends Node

@onready var action_list: Sprite2D = $"../ActionList"
@onready var daughter: Node2D = $"../Characters/Daughter"

enum DamageType { PHYSICAL, MAGIC }

var character_offset = Vector2(50,0)
var goalenemy_offset = Vector2(-50,0)
signal action_finished(character: Node2D, goalenemy: Node2D)
var player_can_batter = true
var enemy_can_batter = true
var player_turn = true

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
	# 攻击方图层设置为1
	character.z_index = 1
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
	tween.tween_callback(func():
		character.z_index = 0
		emit_signal("action_finished", character, goalenemy)
	)


func _on_action_list_atk_pressed(character: Node2D, goalenemy: Node2D) -> void:
	player_can_batter = true
	enemy_can_batter = true
	player_turn = true
	atk_action(character, goalenemy, character_offset)

func _on_action_finished(character: Node2D, goalenemy: Node2D) -> void:
	if player_turn:
		if player_can_batter:
			var batter_rand = randi() % 100
			if batter_rand < character.batter:
				player_can_batter = false
				atk_action(character, goalenemy, character_offset)
				return
		# 玩家连击结束，轮到敌人
		player_turn = false
		enemy_can_batter = true
		atk_action(goalenemy, character, goalenemy_offset)
		check_result(character,goalenemy)
	else:
		if enemy_can_batter:
			var batter_rand = randi() % 100
			if batter_rand < goalenemy.batter:
				enemy_can_batter = false
				atk_action(character,goalenemy,goalenemy_offset)
				return
		# 敌人连击结束，回到玩家回合
		player_turn = true
		check_result(character,goalenemy)
		action_list.show()

func check_result(character: Node2D, goalenemy: Node2D) -> void:
	var character_sprite = character.get_node("AnimatedSprite2D")
	var goalenemy_sprite = goalenemy.get_node("AnimatedSprite2D")
	if character.is_dead():
		character_sprite.play("loss")
		goalenemy_sprite.play("win")
	elif goalenemy.is_dead():
		character_sprite.play("win")
		goalenemy_sprite.play("loss")
