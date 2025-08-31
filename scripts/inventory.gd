extends Node

# 显示优先级：衣服->武器->防具->其他
var slots: Array = []  # 每个元素是 {item: Item, count: int}

func _ready() -> void: 
	# 初始化示例
	slots = [
		{"item": Globaljson.items["c03"], "count": 1},
		{"item": Globaljson.items["c01"], "count": 1},
		{"item": Globaljson.items["c02"], "count": 1},
		{"item": Globaljson.items["c04"], "count": 1},
		{"item": Globaljson.items["c05"], "count": 1},
	]
	SortSlots()

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
			SortSlots()
			return true
	
	# 不存在则新建一个格子
	slots.append({"item": item, "count": add_num})
	SortSlots()
	return true

# 删除物品
func RemoveItem(item_id: String, remove_num: int = 1) -> bool:
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

func _compare_items(a: Dictionary, b: Dictionary) -> int:
	if a["item"].types == b["item"].types:
		return a["item"].id < b["item"].id
	# ItemType 枚举值越小优先级越高
	return a["item"].types < b["item"].types

func SortSlots():
	slots.sort_custom(_compare_items)
