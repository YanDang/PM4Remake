extends Node

# 显示优先级：衣服->武器->防具->其他
var slots: Array = []  # 每个元素是 {item: Item, count: int}

func _ready() -> void: 
	# 初始化示例
	var initial_items = [
		{"id": "c03", "count": 1},
		{"id": "c01", "count": 1},
		{"id": "c02", "count": 1},
		{"id": "c04", "count": 1},
		{"id": "c05", "count": 1},
		{"id": "c06", "count": 1},
		{"id": "c14", "count": 1},
		{"id": "c16", "count": 1},
		{"id": "c19", "count": 1},
		{"id": "f01", "count": 2},
		{"id": "co03", "count": 2},
	]
	slots = []
	for entry in initial_items:
		var item_obj = Globaljson.items.get(entry["id"])
		if item_obj:
			slots.append({"item": item_obj, "count": entry["count"]})

# 添加物品
func AddItem(item_id: String, add_num: int = 1) -> bool:
	var item: Item = Globaljson.items.get(item_id)
	if not item:
		push_warning("Item not found: %s" % item_id)
		return false
	# 查找是否已存在该物品
	for slot in slots:
		if slot["item"].id == item_id:
			slot["count"] += add_num
			return true
	# 不存在则新建一个格子
	slots.append({"item": item, "count": add_num})
	return true

# 删除物品
func RemoveItem(item_id: String, remove_num: int = 1) -> bool:
	print(item_id)
	for i in range(slots.size()):
		var slot = slots[i]
		if slot["item"].id == item_id:
			if slot["count"] > remove_num:
				slot["count"] -= remove_num
			else:
				slots.remove_at(i)
			return true
	push_warning("Item not in inventory: %s" % item_id)
	return false

# 检查是否拥有某物品且数量大于0
func HasItem(item_id: String) -> bool:
	for slot in slots:
		if slot.get("item") != null and slot["item"].id == item_id and slot.get("count", 0) > 0:
			return true
	return false

# 获取某物品拥有数量
func GetItemCount(item_id: String) -> int:
	for slot in slots:
		if slot.get("item") != null and slot["item"].id == item_id:
			return slot.get("count", 0)
	return 0

func _compare_items(a: Dictionary, b: Dictionary) -> int:
	if a["item"].types == b["item"].types:
		return a["item"].id < b["item"].id
	# ItemType 枚举值越小优先级越高
	return a["item"].types < b["item"].types

func SortSlots():
	slots.sort_custom(_compare_items)
