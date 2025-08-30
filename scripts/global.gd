extends Node

var week_list = ["周一","周二","周三","周四","周五","周六","周日"]
var health_tactics = ["顺其自然","活泼取向","娴静取向","进行减肥"]

# 当前年月日
var year:int = 1440
var month:int = 4
var day:int = 1
var week_index = 0

# 所持金
var money:int = clamp(2000,-5000,9999999)
# 健康策略
var health_index = 2

# 月度增长（monthly growth）
var height_monthly_growth:float = 0.39
var weight_monthly_growth:float = 0.26
var bust_monthly_growth:float = 0.3
var waist_monthly_growth:float = 0.15
var hip_monthly_growth:float = 0.33
var stamina_monthly_growth:float = 0

# 年度增长（annual growth）
var height_annual_growth:float = 4.68
var weight_annual_growth:float = 3.12
var bust_annual_growth:float = 3.6
var waist_annual_growth:float = 1.8
var hip_annual_growth:float = 3.96
var stamina_annual_growth:float = 0
