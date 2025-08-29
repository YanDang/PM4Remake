extends TextureRect

var image_paths = [
	"res://assets/sys/tmenu1.png",
	"res://assets/sys/tmenu1a.png",
	"res://assets/sys/tmenu1b.png"
	]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var image_rand = randi() % 3
	self.texture = load(image_paths[image_rand])


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
