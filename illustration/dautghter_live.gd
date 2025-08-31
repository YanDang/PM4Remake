extends Node2D

@onready var timer: Timer = $Timer
@onready var eyes: AnimatedSprite2D = $Eyes
@onready var body: Sprite2D = $Body

# 幼年形象
var region:Rect2 = Rect2(0,50,0,398)
var cloth_file_dict:Dictionary = {
	"常服":"res://assets/Patricia Halliwel/ch01c01.png",
	"夏季服":"res://assets/Patricia Halliwel/ch01c02.png",
	"冬季服":"res://assets/Patricia Halliwel/ch01c03.png",
	"洋装":"res://assets/Patricia Halliwel/ch01c04.png",
	"丝质洋装":"res://assets/Patricia Halliwel/ch01c05.png",
	"武术服":"res://assets/Patricia Halliwel/ch01c07.png",
	"修道服":"res://assets/Patricia Halliwel/ch01c12.png",
	"不良装扮":"res://assets/Patricia Halliwel/ch01c15.png",
	"睡衣":"res://assets/Patricia Halliwel/ch01c16.png",
}

var eye_index = 0
var all_animations = ["wink","wink_double"]

func _on_timer_timeout() -> void:
	eye_index ^= 1
	eyes.play(all_animations[eye_index])

func ChangeClothes(clothes_name:String):
	var atlas_tex = AtlasTexture.new()
	atlas_tex.atlas = load(cloth_file_dict[clothes_name])
	atlas_tex.region = region
	body.texture = atlas_tex

func _ready() -> void:
	ChangeClothes("常服")
