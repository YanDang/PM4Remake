extends Resource

class_name FightStats

## batter:连击，仅第一次攻击触发
## criticalhit:暴击,最大值100
## criticaldamage:暴伤
## dodge:闪避,最大值50
## 伤害计算仿照明日方舟，物理伤害=max(1,atk-def)，魔法伤害=max(1,int(matk/mdef))
@export var hp:int = 100
@export var atk:int = 10
@export var def:int = 5
@export var matk:int = 10
@export var mdef:int = 5
@export var batter:int = 50
@export var criticalhit:int = 50
@export var criticaldamage:int = 150
@export var dodge:int = 50
