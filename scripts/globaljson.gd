extends Node

var health_growth:Dictionary
var items:Dictionary
var clothes_path:Dictionary
var icon_path:Dictionary

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	health_growth = JSON.parse_string(FileAccess.open("res://datajson/growth_data.json", FileAccess.READ).get_as_text())
	LoadItemsFromJson("res://datajson/item_data.json")
	clothes_path = JSON.parse_string(FileAccess.open("res://datajson/clothes_path_data.json", FileAccess.READ).get_as_text())
	icon_path = JSON.parse_string(FileAccess.open("res://datajson/headshot_icon_data.json", FileAccess.READ).get_as_text())

func LoadItemsFromJson(path:String):
	var file = FileAccess.open(path,FileAccess.READ)
	if not file:
		push_error("Failed to open item data: %s" % path)
		return
	var data = JSON.parse_string(file.get_as_text())
	for item_dict in data:
		var item := Item.new()
		ApplyJsonToItem(item, item_dict)
		items[item.id] = item

func ApplyJsonToItem(item:Item,dict:Dictionary):
	var props = []
	for p in item.get_property_list():
		props.append(p.name)
	for key in dict.keys():
		if key in props:
			var value = dict[key]
			if key == "types":
				if typeof(value) == TYPE_STRING and Item.ItemType.has(value):
					item.types = Item.ItemType[value]
				elif typeof(value) == TYPE_INT:
					item.types = value
			else:
				item.set(key, value)
