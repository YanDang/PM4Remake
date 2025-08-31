extends Resource

class_name Item

enum ItemType { CLOTHES, WEAPON, ARMOR, FOOD, CONSUMABLES, OTHER }

var id: String = ""
var name: String = ""
var description:String = ""
var icon: Texture2D
# 类型：服装，武器，防具，食物，消耗品，其他
var types: ItemType = ItemType.CLOTHES
# 价格
var prices:int = 0
# 堆叠
var stackable: bool = false
var max_stack: int = 99
# 可使用
var can_use:bool = false
# 重要物品不可丢弃
var important:bool = false
