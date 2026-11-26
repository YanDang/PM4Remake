extends Node

var data: Dictionary

func _ready() -> void:
	data = JSON.parse_string(FileAccess.get_file_as_string("res://datajson/clothing_data.json"))

func GetDescription(item: Item) -> String:
	return data["items"].get(item.id, {}).get("description", "〔%s〕\n%s" % [item.name, item.description])

func GetShopDialogue(item: Item) -> Array:
	return data["items"].get(item.id, {}).get("shop_dialogue", [{"character": "teresa", "emotion": "calm", "text": item.description}])

func CanWear(item: Item) -> bool:
	if item == null or item.types != Item.ItemType.CLOTHES:
		return false
	var paths = Globaljson.clothes_path.get(Daughterstatus.age_stage_names[Daughterstatus.age_stage], {})
	return paths.has(item.name) and ResourceLoader.exists(paths[item.name])

func Equip(item_id: String) -> Dictionary:
	var item: Item = Globaljson.items.get(item_id)
	if not Inventory.HasItem(item_id) or not CanWear(item):
		return {"error": ERR_UNAVAILABLE, "changes": {}}
	if item_id == "c" + Daughterstatus.current_clothes_id:
		return {"error": ERR_ALREADY_IN_USE, "changes": {}}
	return ApplyOutfit(item)

func EnsureAgeCompatibleOutfit() -> void:
	var current: Item = Globaljson.items.get("c" + Daughterstatus.current_clothes_id)
	if not CanWear(current):
		ApplyOutfit(Globaljson.items["c01"])

func ApplyOutfit(item: Item) -> Dictionary:
	var changes: Dictionary = {}
	var next_bonus: Dictionary = {}
	var keys = Daughterstatus.clothing_bonus.keys()
	for key in item.arrtibute_dict:
		if key not in keys:
			keys.append(key)
	for key in keys:
		if not Daughterstatus.attributes.has(key):
			continue
		var old_value = float(Daughterstatus.attributes[key])
		var base_value = clampf(old_value - float(Daughterstatus.clothing_bonus.get(key, 0.0)), 0.0, 999.0)
		var new_value = clampf(base_value + float(item.arrtibute_dict.get(key, 0.0)), 0.0, 999.0)
		Daughterstatus.attributes[key] = new_value
		if not is_equal_approx(new_value, old_value):
			changes[key] = new_value - old_value
		if not is_equal_approx(new_value, base_value):
			next_bonus[key] = new_value - base_value
	Daughterstatus.clothing_bonus = next_bonus
	Daughterstatus.current_clothes_id = item.id.trim_prefix("c")
	Daughterstatus.current_clothes_name = item.name
	return {"error": OK, "changes": changes}
