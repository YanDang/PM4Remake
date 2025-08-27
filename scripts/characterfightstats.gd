extends Node2D

signal stats_changed

## batter:连击，仅第一次攻击触发
## criticalhit:暴击,最大值100
## criticaldamage:暴伤
## dodge:闪避,最大值50
## fightback:反击，最大值100
## 伤害计算仿照明日方舟，物理伤害=max(1,atk-def)，魔法伤害=max(1,int(matk/mdef))
var charactername:String="name"
var hp:int=100
var maxhp:int=100
var atk:int=10
var def:int=5
var matk:int=10
var mdef:int=5
var batter:int=10
var criticalhit:int=10
var criticaldamage:float=1.5
var dodge:int=50
var fightback:int=10

func is_dead() -> bool:
	return hp <= 0
