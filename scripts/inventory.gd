extends Node

# 显示优先级：衣服->武器->防具->其他
var slots: Array = []  # 每个元素是 {item: Item, count: int}

func GearSlot(item: Item) -> String:
	if item.types == Item.ItemType.WEAPON:
		return "weapon"
	if item.types == Item.ItemType.ARMOR:
		return "armor"
	return ""

func ApplyMonthlyItemEffects() -> void:
	var changes := {}
	var applied := {}
	for slot in slots:
		var item: Item = slot["item"]
		if item.monthly_effects.is_empty() or applied.has(item.id):
			continue
		applied[item.id] = true
		for stat in item.monthly_effects:
			changes[stat] = changes.get(stat, 0) + item.monthly_effects[stat]
	Daughterstatus.ApplyAttributeDict(changes)

func IsEquippedGear(item: Item) -> bool:
	var slot := GearSlot(item)
	return not slot.is_empty() and Daughterstatus.equipped_gear[slot] == item.id

func ToggleGear(item: Item) -> bool:
	var slot := GearSlot(item)
	if slot.is_empty() or not HasItem(item.id):
		return false
	Daughterstatus.equipped_gear[slot] = "" if IsEquippedGear(item) else item.id
	return true

func _ready() -> void: 
	ResetSlots()

func ResetSlots() -> void:
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
		AddItem(entry["id"], entry["count"])

func RestoreSlots(entries: Array) -> void:
	slots = []
	for entry in entries:
		var item: Item = Globaljson.items[entry["id"]]
		AppendStacks(item, int(entry["count"]), item.GetStackLimit())

func AppendStacks(item: Item, count: int, limit: int) -> void:
	while count > 0:
		var stack_count := mini(count, limit)
		slots.append({"item": item, "count": stack_count})
		count -= stack_count

# 添加物品
func AddItem(item_id: String, add_num: int = 1) -> bool:
	if add_num <= 0:
		return false
	var item: Item = Globaljson.items.get(item_id)
	if not item:
		push_warning("Item not found: %s" % item_id)
		return false
	var limit := item.GetStackLimit()
	if limit > 1:
		for slot in slots:
			if slot["item"].id != item_id or slot["count"] >= limit:
				continue
			var added := mini(add_num, limit - int(slot["count"]))
			slot["count"] += added
			add_num -= added
			if add_num == 0:
				return true
	AppendStacks(item, add_num, limit)
	return true

# 删除物品
func RemoveItem(item_id: String, remove_num: int = 1) -> bool:
	if remove_num <= 0 or GetItemCount(item_id) < remove_num:
		return false
	for index in range(slots.size() - 1, -1, -1):
		var slot: Dictionary = slots[index]
		if slot["item"].id != item_id:
			continue
		var removed := mini(remove_num, int(slot["count"]))
		RemoveFromSlot(index, removed)
		remove_num -= removed
		if remove_num == 0:
			return true
	return false

func RemoveFromSlot(index: int, count: int = 1) -> bool:
	if index < 0 or index >= slots.size() or count <= 0:
		return false
	var slot: Dictionary = slots[index]
	if slot["count"] < count:
		return false
	slot["count"] -= count
	if slot["count"] == 0:
		var item: Item = slot["item"]
		slots.remove_at(index)
		if IsEquippedGear(item) and not HasItem(item.id):
			Daughterstatus.equipped_gear[GearSlot(item)] = ""
	return true

func HasItem(item_id: String) -> bool:
	return GetItemCount(item_id) > 0

# 获取某物品拥有数量
func GetItemCount(item_id: String) -> int:
	var count := 0
	for slot in slots:
		if slot.get("item") != null and slot["item"].id == item_id:
			count += slot.get("count", 0)
	return count

func _compare_items(a: Dictionary, b: Dictionary) -> int:
	if a["item"].types == b["item"].types:
		return a["item"].id < b["item"].id
	# ItemType 枚举值越小优先级越高
	return a["item"].types < b["item"].types

func SortSlots():
	slots.sort_custom(_compare_items)
