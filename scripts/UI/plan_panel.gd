extends Node2D
@onready var plan_icon_console: Node2D = $PlanIconConsole
@onready var day_icon_console: Node2D = $DayIconConsole
# 获取所有子节点
var plan_icons:Array
var day_icons:Array
var n = 42 #len(day_icons)

# 锁一下，防止崩溃
var is_busy := false

# 计算日期的icon位置
var region_start:Vector2 = Vector2(0,325)
# 特判一下28开头的素材
var s_region_start:Vector2 = Vector2(256,325)
# w28,h23
var icon_size:Vector2 = Vector2(28,23)
var icons_region_pos:Array

# 显示月份
var months = [
	"Jan 1", "Feb 2", "Mar 3", "Apr 4", "May 5", "Jun 6",
	"Jul 7", "Aug 8", "Sep 9", "Oct 10", "Nov 11", "Dec 12"
]

# 本月在哪天结束
var end_day:int = 30

# 第几个计划
var plan_index:int = 0

# 退出界面
signal plan_exit

# 计算日期对应的region
func CalIconRegionPos() -> void:
	var pos_offset = Vector2(0,0)
	for i in range(27):
		pos_offset.x = (i % 9) * icon_size.x
		pos_offset.y = int(i / 9) * icon_size.y
		icons_region_pos.append(region_start+pos_offset)
	for i in range(4):
		pos_offset.x = (i % 2) * icon_size.x
		pos_offset.y = int(i / 2) * icon_size.y
		icons_region_pos.append(s_region_start+pos_offset)

# 初始化
func DayIconInit() -> void:
	# 给所有的icon全都写个新的Atlas进去
	for i in range(n):
		var icon = day_icons[i]
		var new_atlas = AtlasTexture.new()
		new_atlas.atlas = icon.texture.atlas
		new_atlas.region.size = icon_size
		icon.texture = new_atlas
		plan_icons[i].hide()

# 计算本月天数
func DaysInMonth(year: int, month: int) -> int:
	var days_in_months = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

	# 闰年规则：能被4整除且不能被100整除，或者能被400整除
	var is_leap = (year % 4 == 0 and year % 100 != 0) or (year % 400 == 0)

	if month == 2 and is_leap:
		return 29
	else:
		return days_in_months[month - 1]

func StartPlan():
	# 更新label
	$Year.text = str(Global.year)
	$Month.text = months[Global.month-1]
	# 计算终止日
	end_day = DaysInMonth(Global.year,Global.month)
	# 全扫一遍
	for i in range(n):
		if Global.week_index <= i and i < Global.week_index + end_day:
			day_icons[i].show()
			# 先拿region出来
			var temp_atlas = day_icons[i].texture
			var temp_region = temp_atlas.region
			temp_region.position = icons_region_pos[i-Global.week_index]
			temp_atlas.region = temp_region
		else:
			day_icons[i].hide()

func _on_plan_choose_plan_click(plan_button: TextureButton) -> void:
	if is_busy:
		return
	is_busy = true
	if plan_index < 3:
		var start_index = plan_index*10+Global.week_index
		var end_index
		if plan_index == 2:
			end_index = end_day+Global.week_index
		else:
			end_index = start_index + 10
		# 全扫一遍
		for i in range(start_index,end_index):
			plan_icons[i].show()
			# 用button的texture覆盖
			plan_icons[i].texture = plan_button.texture_normal
			await get_tree().create_timer(0.01).timeout  # 每次间隔 0.2 秒
		plan_index += 1
	is_busy = false

func DelChoosePlan() -> void:
	if is_busy:
		return
	is_busy = true
	plan_index -= 1
	var start_index = plan_index*10+Global.week_index-1
	var end_index
	if plan_index == 2:
		end_index = end_day+Global.week_index-1
	else:
		end_index = start_index + 10
	for i in range(end_index,start_index,-1):
		plan_icons[i].hide()
		await get_tree().create_timer(0.01).timeout  # 每次间隔 0.2 秒
	is_busy = false
	
func _on_plan_choose_cancel_click() -> void:
	# 大于0则删除之前的
	if plan_index > 0:
		DelChoosePlan()
	# 否则退出该界面
	else:
		emit_signal("plan_exit")
		
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("cancel"):
		if plan_index > 0:
			DelChoosePlan()
		else:
			emit_signal("plan_exit")

func _ready() -> void:
	plan_icons = plan_icon_console.get_children()
	day_icons = day_icon_console.get_children()
	# 算一下icon的region
	CalIconRegionPos()
	# 初始化icon
	DayIconInit()
	StartPlan()
