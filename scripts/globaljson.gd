extends Node

var health_growth:Dictionary
var items:Dictionary
var clothes_path:Dictionary
var icon_path:Dictionary
var human_translation:Dictionary
var category_translation:Dictionary
var category_data:Dictionary
#var arrtibute_translation:Dictionary

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	health_growth = JSON.parse_string(FileAccess.open("res://datajson/growth_data.json", FileAccess.READ).get_as_text())
	LoadItemsFromJson("res://datajson/item_data.json")
	clothes_path = JSON.parse_string(FileAccess.open("res://datajson/clothes_path_data.json", FileAccess.READ).get_as_text())
	icon_path = JSON.parse_string(FileAccess.open("res://datajson/headshot_icon_data.json", FileAccess.READ).get_as_text())
	human_translation = JSON.parse_string(FileAccess.open("res://datajson/translation/human_translation.json", FileAccess.READ).get_as_text())
	category_translation = JSON.parse_string(FileAccess.open("res://datajson/translation/category_translation.json", FileAccess.READ).get_as_text())
	LoadCategoryFromTxt("res://datajson/category_data.txt")
	#arrtibute_translation = JSON.parse_string(FileAccess.open("res://datajson/translation/arrtibute_translation.json", FileAccess.READ).get_as_text())

func LoadCategoryFromTxt(path:String):
	var row_list:Array = FileAccess.open(path,FileAccess.READ).get_as_text().split('\n')
	# csv存储格式，逗号分隔符,Linux格式换行
	var key_words:Array = row_list[0].split(',')
	for row_text in row_list.slice(1):
		var row_array:Array = row_text.split(',')
		var temp_dict:Dictionary
		# 'level' + str
		var temp_key:String = key_words[1] + row_array[1]
		for i in range(2,row_array.size()):
			temp_dict[key_words[i]] = float(row_array[i])
		if not category_data.has(row_array[0]):
			category_data[row_array[0]] = {temp_key:temp_dict}
		else:
			category_data[row_array[0]].merge({temp_key:temp_dict})

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
