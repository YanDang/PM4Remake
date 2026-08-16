extends CanvasLayer

@onready var talk_text: Label = $TalkEvent/TalkBox/TalkText
@onready var headshot: Sprite2D = $TalkEvent/People/Headshot
@onready var first_name: Label = $TalkEvent/People/FirstName
@onready var arrtibute: CanvasLayer = $"../Arrtibute"
@onready var choice_ui: Node2D = $"ChoiceUI"
@onready var standing_sprites: Node2D = $StandingSprites
var active_sprites: Dictionary = {}

# 女主和女配有年龄差分
@onready var special_name: Array = ["daughter","lise","christina","marie"]

# 对话结束后结算
enum SettleType {NULL,ATTRIBUTE,CHOICE}

signal talk_start
signal talk_end
signal attribute_settle(attribute_dict)
# 发出选择结果
#signal choice_result(choice_index)

# 平静，开心，生气，失望，惊讶，怀疑，喜出望外，伤心，不满，不耐烦，生病
@onready var emotions:Dictionary = {
	"calm": "01",
	"happy": "02",
	"angry": "03",
	"disappointed": "04",
	"surprised": "05",
	"doubtful": "06",
	"overjoyed": "07",
	"sad": "08",
	"dissatisfied": "09",
	"impatient": "10",
	"sick": "11"
}

var icon_path:String

var current_index:int = 0

func _ready() -> void:
	set_process_input(false)
	hide()

var talk_even:Array

var settle:SettleType

# 需要结算
var is_settle:bool = false
var allow_emit:bool = true
var attribute_dict:Dictionary
var choice_list:Array

# 函数触发
var event_callable:Callable = Callable()
var child_choice_index:int = 0 # 默认值为0，即便没有触发选项也能正常结算

func RegisterCallback(cb: Callable) -> void:
	event_callable = cb

func TalkStart(talk_array:Array,now_settle:SettleType=SettleType.NULL,data_dict:Dictionary={},data_list:Array=[]):
	emit_signal("talk_start")
	current_index = 0
	child_choice_index = 0
	settle = now_settle
	match settle:
		SettleType.NULL:
			is_settle = false
		SettleType.ATTRIBUTE:
			is_settle = true
			attribute_dict = data_dict
			allow_emit = true
		SettleType.CHOICE:
			is_settle = true
			choice_list = data_list
			allow_emit = true
	show()
	talk_even = talk_array
	call_deferred("set_process_input", true)
	TalkPolling()  # 显示第一句话

func TalkEnd():
	set_process_input(false)  # 完全停止输入处理
	hide()
	
	# 结束对话时清理所有立绘
	for sprite in active_sprites.values():
		if is_instance_valid(sprite):
			sprite.queue_free()
	active_sprites.clear()
	
	if event_callable.is_null():
		emit_signal("talk_end")
	else:
		var cb = event_callable
		# 先销毁再调用，以支持在回调中注册新的回调
		event_callable = Callable()
		cb.call(child_choice_index)

func TalkPolling():
	if current_index < talk_even.size():
		var entry = talk_even[current_index]
		Happen(entry.get("character", ""), entry.get("emotion", "01"), entry.get("text", ""), entry.get("name_index", 0), entry.get("action", ""))
		current_index += 1
		if entry.get("action", "") == "leave" and entry.get("text", "") == "":
			TalkPolling()
	else:
		if not is_settle:
			# 不需要计算属性
			TalkEnd()
	if current_index == talk_even.size():
		if is_settle:
			if allow_emit:
				# 发射结束信号,等待信号回传
				match settle:
					SettleType.ATTRIBUTE:
						emit_signal("attribute_settle",attribute_dict)
					SettleType.CHOICE:
						choice_ui.init(choice_list)
						if choice_list.size() > 2:
							choice_ui.position.y -= choice_list.size() * choice_ui.base_heigh
						await get_tree().process_frame # 等到下一帧
						choice_ui.show()
				allow_emit = false
		
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("confirm"):
		TalkPolling()
	elif event.is_action_pressed("next_view"):
		if current_index < len(talk_even):
			TalkPolling()
	elif event.is_action_pressed("back_view"):
		if current_index > 1:
			current_index -= 2 
			TalkPolling()
	# 吃事件,阻止事件向下传递
	if settle != SettleType.CHOICE and get_viewport():
		get_viewport().set_input_as_handled()
		
		
# 谁，什么情绪，说啥了
func Happen(who:String, emotion:String, text:String, name_index:int=0, action:String="") -> void:
	if action == "leave":
		if active_sprites.has(who):
			var sprite = active_sprites[who]
			active_sprites.erase(who)
			UpdateSpritePositions(true)
			var tween = create_tween()
			tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
			tween.tween_callback(sprite.queue_free)
		return
	if who == "":
		# 旁白
		headshot.hide()
		first_name.text = ""
		talk_text.text = text
		return 
	# 普通npc的icon和其他的不一样
	elif who in Globaljson.special_name:
		# 年龄差分
		if who in special_name:
			icon_path = "res://assets/PM4_FC/" + Globaljson.icon_path[who][Daughterstatus.age_stage_names[Daughterstatus.age_stage]] + emotions[emotion] + ".png"
		else:
			icon_path = "res://assets/PM4_FC/" + Globaljson.icon_path[who] + emotions[emotion] + ".png"
		print(icon_path)
		headshot.show()
		if who == "daughter":
			first_name.text = Daughterstatus.firstname
		else:
			first_name.text = Globaljson.human_translation[who][name_index]
		if not emotions.get(emotion):
			headshot.hide()
			push_warning("Load emotion ERROR")
			return
	else:
		first_name.text = Globaljson.human_translation[who][name_index]
		icon_path = "res://assets/PM4_FC/" + Globaljson.icon_path[who] + ".png"
	headshot.texture = load(icon_path)
	talk_text.text = text

	# === 大立绘(Standing Sprite) 逻辑 ===
	if get_tree().current_scene.name != "Main" and Globaljson.stand_sprite_data.has(who):
		var template: String = Globaljson.stand_sprite_data[who]
		var emo_code = emotions.get(emotion, "01")
		var age_code = ""
		
		if who in special_name:
			var age_stage_map = {"child": "c", "teen": "l", "adult": "h"}
			var stage_name = Daughterstatus.age_stage_names[Daughterstatus.age_stage]
			age_code = age_stage_map.get(stage_name, "c")
			
		var cloth_code = Daughterstatus.current_clothes_id
		var sprite_path = "res://assets/" + template.replace("{emotion}", emo_code).replace("{age}", age_code).replace("{cloth}", cloth_code)
		
		if not active_sprites.has(who):
			var new_sprite = Sprite2D.new()
			new_sprite.scale = Vector2(1.8, 1.8)
			new_sprite.modulate.a = 0.0
			standing_sprites.add_child(new_sprite)
			active_sprites[who] = new_sprite
			
			UpdateSpritePositions(false, new_sprite)
			
			var tween = create_tween()
			tween.tween_property(new_sprite, "modulate:a", 1.0, 0.3)
			
			UpdateSpritePositions(true)
			
		var slot = active_sprites[who]
		var tex = load(sprite_path)
		if tex:
			if who == "daughter" and emo_code == "01":
				var body_tex = AtlasTexture.new()
				body_tex.atlas = tex
				var region_body = Rect2(0, 48, 268, 400)
				var eye_pos = Vector2(2.5, -104.5)
				var eye_region = Rect2(2, 2, 77, 43)
				
				if age_code == "l":
					region_body = Rect2(0, 40, 280, 480)
					eye_pos = Vector2(1, -103)
					eye_region = Rect2(2, 2, 76, 36)
				elif age_code == "h":
					region_body = Rect2(0, 46, 372, 480)
					eye_pos = Vector2(-7, -140)
					eye_region = Rect2(2, 2, 75, 42)
					
				body_tex.region = region_body
				slot.texture = body_tex
				
				var eye_sprite = slot.get_node_or_null("EyeAnimSprite")
				if not eye_sprite:
					var old_eye = slot.get_node_or_null("EyeSprite")
					if old_eye: old_eye.queue_free()
					
					eye_sprite = AnimatedSprite2D.new()
					eye_sprite.name = "EyeAnimSprite"
					slot.add_child(eye_sprite)
				
				var tex0 = AtlasTexture.new()
				tex0.atlas = tex
				var tex1 = AtlasTexture.new()
				tex1.atlas = tex
				var tex2 = AtlasTexture.new()
				tex2.atlas = tex
				
				if age_code == "c":
					tex0.region = Rect2(2, 2, 77, 43)
					tex1.region = Rect2(83, 2, 77, 43)
					tex2.region = Rect2(164, 2, 77, 43)
				elif age_code == "l":
					tex0.region = Rect2(2, 2, 76, 36)
					tex1.region = Rect2(82, 2, 76, 36)
					tex2.region = Rect2(162, 2, 76, 36)
				elif age_code == "h":
					tex0.region = Rect2(2, 2, 75, 42)
					tex1.region = Rect2(81, 2, 75, 42)
					tex2.region = Rect2(160, 2, 75, 42)
				
				var frames = SpriteFrames.new()
				if not frames.has_animation("default"):
					frames.add_animation("default")
				frames.add_frame("default", tex0)
				
				if emo_code == "01":
					frames.add_animation("wink")
					frames.set_animation_loop("wink", false)
					frames.set_animation_speed("wink", 10.0)
					for t in [tex0, tex1, tex2, tex1, tex0]:
						frames.add_frame("wink", t)
						
					frames.add_animation("wink_double")
					frames.set_animation_loop("wink_double", false)
					frames.set_animation_speed("wink_double", 10.0)
					for t in [tex0, tex1, tex2, tex1, tex0, tex1, tex2, tex1, tex0]:
						frames.add_frame("wink_double", t)
				
				eye_sprite.sprite_frames = frames
				eye_sprite.play("default")
				eye_sprite.position = eye_pos
				
				if emo_code == "01":
					var eye_timer = eye_sprite.get_node_or_null("EyeTimer")
					if not eye_timer:
						eye_timer = Timer.new()
						eye_timer.name = "EyeTimer"
						eye_timer.wait_time = randf_range(3.0, 5.0)
						eye_timer.autostart = true
						eye_timer.timeout.connect(func():
							if eye_sprite and is_instance_valid(eye_sprite):
								var anims = ["wink", "wink_double"]
								eye_sprite.play(anims[randi() % 2])
								eye_timer.wait_time = randf_range(3.0, 5.0)
						)
						eye_sprite.add_child(eye_timer)
			else:
				slot.texture = tex
				var eye_sprite = slot.get_node_or_null("EyeAnimSprite")
				if eye_sprite:
					eye_sprite.queue_free()
				var old_eye = slot.get_node_or_null("EyeSprite")
				if old_eye:
					old_eye.queue_free()
		else:
			push_warning("Failed to load stand sprite: ", sprite_path)

func UpdateSpritePositions(animated: bool, newly_added_sprite: Sprite2D = null) -> void:
	var keys = active_sprites.keys()
	var count = keys.size()
	if count == 0: return
	
	var target_x = {}
	if count == 1:
		target_x[keys[0]] = 0.0
	elif count == 2:
		target_x[keys[0]] = -220.0
		target_x[keys[1]] = 220.0
	else:
		target_x[keys[0]] = -250.0
		target_x[keys[1]] = 0.0
		target_x[keys[2]] = 250.0
		for i in range(3, count):
			target_x[keys[i]] = 250.0 + (i - 2) * 50.0
			
	for who in keys:
		var sprite = active_sprites[who]
		var tx = target_x[who]
		var target_pos = Vector2(tx, -220)
		
		if sprite == newly_added_sprite:
			sprite.position = target_pos
		elif animated and sprite.position.x != tx:
			var tween = create_tween()
			tween.tween_property(sprite, "position:x", tx, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		else:
			sprite.position = target_pos

func _on_arrtibute_settle_end() -> void:
	TalkEnd()

# 选项触发后的事件
func _on_choice_pressed(_choice_text: String,choice_index:int):
	print("收到选择信号")
	child_choice_index = choice_index
	print(choice_index)
	TalkEnd()
	choice_ui.hide()
