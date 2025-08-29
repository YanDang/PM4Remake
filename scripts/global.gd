extends Node

var week_list = ["周一","周二","周三","周四","周五","周六","周日"]

# 当前年月日
var year:int = 1440
var month:int = 4
var day:int = 1
var week_index = 0

# 所持金
var money:int = clamp(2000,-5000,9999999)
