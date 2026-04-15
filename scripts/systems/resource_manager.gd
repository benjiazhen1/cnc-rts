## 资源管理系统
##
## 负责处理游戏中的货币资源逻辑，包括信用点(Credits)的生成、消耗、
## 验证和UI显示。挂载到游戏场景的对应节点上使用。
extends Node

# ==================== 资源常量 ====================
## 初始信用点数量
const INITIAL_CREDITS: int = 1000
## 基础每分钟收入
const BASE_CREDITS_PER_MINUTE: int = 100
## 建筑每分钟产出加成
const CREDITS_PER_BUILDING_PER_MINUTE: int = 10
## 升级收入加成（预留）
const CREDITS_BONUS_PER_UPGRADE: int = 5
## 更新间隔（秒）
const UPDATE_INTERVAL: float = 1.0

# ==================== 建筑资源产出 ====================
## 指挥中心每分钟产出
const YIELD_COMMAND_CENTER: int = 50
## 发电厂每分钟产出
const YIELD_POWER_PLANT: int = 20
## 兵营每分钟产出
const YIELD_BARRACKS: int = 10
## 工厂每分钟产出
const YIELD_FACTORY: int = 30
## 飞机场每分钟产出
const YIELD_AIRFIELD: int = 25
## 默认建筑每分钟产出
const YIELD_DEFAULT: int = 10

# ==================== 单位维持成本 ====================
## 步兵每分钟维持费用
const UPKEEP_INFANTRY: int = 2
## 火箭兵每分钟维持费用
const UPKEEP_ROCKET_SOLDIER: int = 4
## 轻型坦克每分钟维持费用
const UPKEEP_LIGHT_TANK: int = 8
## 重型坦克每分钟维持费用
const UPKEEP_HEAVY_TANK: int = 12
## 直升机每分钟维持费用
const UPKEEP_HELICOPTER: int = 10
## 默认单位维持费用
const UPKEEP_DEFAULT: int = 5

# ==================== 错误消息 ====================
const ERR_INSUFFICIENT_CREDITS: String = "资源不足：需要 %d，当前 %d"
const ERR_INVALID_AMOUNT: String = "无效的资源数量：%d"
const ERR_GAME_STATE_MISSING: String = "GameState 节点未找到"
const ERR_UI_NODE_MISSING: String = "UI 节点未找到"

# ==================== 信号定义 ====================
## 资源变化时触发
## [param old_value] 变化前的资源数量
## [param new_value] 变化后的资源数量
signal credits_changed(old_value: int, new_value: int)

## 收入增加时触发（如建造建筑）
## [param amount] 增加的收入量
signal income_changed(amount: int)

## 资源不足，无法执行操作时触发
## [param required] 所需资源
## [param available] 可用资源
signal insufficient_credits(required: int, available: int)

# ==================== 内部状态变量 ====================
## 当前信用点数量
var credits: int = INITIAL_CREDITS
## 每分钟总收入
var total_income_per_minute: int = BASE_CREDITS_PER_MINUTE
## 每分钟总支出（维持费用）
var total_upkeep_per_minute: int = 0
## 更新计时器
var update_timer: float = 0.0
## 累计获得的资源（用于统计）
var total_credits_earned: int = 0
## 累计消耗的资源（用于统计）
var total_credits_spent: int = 0

# ==================== 依赖节点引用 ====================
var game_state: Node
var ui_node: Node

# ==================== 生命周期 ====================

func _ready() -> void:
	"""初始化获取 GameState 和 UI 节点引用。"""
	_initialize_nodes()


func _process(delta: float) -> void:
	"""每帧处理资源更新计时。"""
	update_timer += delta

	if update_timer >= UPDATE_INTERVAL:
		_process_resource_generation()
		update_timer = 0.0


func _initialize_nodes() -> void:
	"""获取必要的游戏系统节点引用。"""
	game_state = get_node_or_null("/root/GameState")
	if game_state == null:
		push_error(ERR_GAME_STATE_MISSING)

	ui_node = get_node_or_null("/root/Game/UI")
	if ui_node == null:
		push_warning(ERR_UI_NODE_MISSING + "，资源UI将不更新")


# ==================== 公共方法：资源操作 ====================

## 增加信用点
##
## [param amount] 要增加的数量
## [return] 增加是否成功
func add_credits(amount: int) -> bool:
	if amount <= 0:
		push_warning(ERR_INVALID_AMOUNT % amount)
		return false

	var old_credits: int = credits
	credits += amount
	total_credits_earned += amount

	credits_changed.emit(old_credits, credits)
	_update_ui()
	_sync_to_game_state()
	return true


## 消费信用点（带验证）
##
## [param amount] 要消费的数量
## [return] 消费是否成功，资源不足时返回 false
func spend_credits(amount: int) -> bool:
	if amount <= 0:
		push_warning(ERR_INVALID_AMOUNT % amount)
		return false

	if credits < amount:
		insufficient_credits.emit(amount, credits)
		push_warning(ERR_INSUFFICIENT_CREDITS % [amount, credits])
		return false

	var old_credits: int = credits
	credits -= amount
	total_credits_spent += amount

	credits_changed.emit(old_credits, credits)
	_update_ui()
	_sync_to_game_state()
	return true


## 检查是否有足够的信用点
##
## [param amount] 要检查的数量
## [return] 资源是否足够
func has_credits(amount: int) -> bool:
	return credits >= amount


## 获取当前信用点余额
##
## [return] 当前信用点数量
func get_credits() -> int:
	return credits


## 获取当前每分钟净收入
##
## [return] 每分钟净收入（收入 - 维持费用）
func get_net_income_per_minute() -> int:
	return total_income_per_minute - total_upkeep_per_minute


# ==================== 公共方法：收入管理 ====================

## 添加建筑收入来源
##
## [param building_type] 建筑类型
func add_building_yield(building_type: String) -> void:
	var yield_amount: int = get_building_yield(building_type)
	total_income_per_minute += yield_amount
	income_changed.emit(yield_amount)
	_sync_to_game_state()


## 移除建筑收入来源
##
## [param building_type] 建筑类型
func remove_building_yield(building_type: String) -> void:
	var yield_amount: int = get_building_yield(building_type)
	total_income_per_minute -= yield_amount
	income_changed.emit(-yield_amount)
	_sync_to_game_state()


## 添加单位维持费用
##
## [param unit_type] 单位类型
func add_unit_upkeep(unit_type: String) -> void:
	var upkeep_amount: int = get_unit_upkeep(unit_type)
	total_upkeep_per_minute += upkeep_amount
	_sync_to_game_state()


## 移除单位维持费用
##
## [param unit_type] 单位类型
func remove_unit_upkeep(unit_type: String) -> void:
	var upkeep_amount: int = get_unit_upkeep(unit_type)
	total_upkeep_per_minute -= upkeep_amount
	_sync_to_game_state()


## 重置所有资源状态
func reset_resources() -> void:
	var old_credits: int = credits
	credits = INITIAL_CREDITS
	total_income_per_minute = BASE_CREDITS_PER_MINUTE
	total_upkeep_per_minute = 0
	total_credits_earned = 0
	total_credits_spent = 0
	update_timer = 0.0

	credits_changed.emit(old_credits, credits)
	_update_ui()
	_sync_to_game_state()


# ==================== 公共方法：查询函数 ====================

## 获取建筑每分钟产出
##
## [param building_type] 建筑类型
## [return] 该建筑类型的每分钟产出
func get_building_yield(building_type: String) -> int:
	match building_type:
		"Command Center":  return YIELD_COMMAND_CENTER
		"Power Plant":     return YIELD_POWER_PLANT
		"Barracks":        return YIELD_BARRACKS
		"Factory":         return YIELD_FACTORY
		"Airfield":        return YIELD_AIRFIELD
		_:                return YIELD_DEFAULT


## 获取单位每分钟维持费用
##
## [param unit_type] 单位类型
## [return] 该单位类型的每分钟维持费用
func get_unit_upkeep(unit_type: String) -> int:
	match unit_type:
		"Infantry":        return UPKEEP_INFANTRY
		"RocketSoldier":   return UPKEEP_ROCKET_SOLDIER
		"LightTank":       return UPKEEP_LIGHT_TANK
		"HeavyTank":       return UPKEEP_HEAVY_TANK
		"Helicopter":      return UPKEEP_HELICOPTER
		_:                return UPKEEP_DEFAULT


## 获取所有资源状态摘要
##
## [return] 包含所有资源信息的字典
func get_resource_summary() -> Dictionary:
	return {
		"credits": credits,
		"income_per_minute": total_income_per_minute,
		"upkeep_per_minute": total_upkeep_per_minute,
		"net_income": get_net_income_per_minute(),
		"total_earned": total_credits_earned,
		"total_spent": total_credits_spent
	}


# ==================== 私有方法 ====================

func _process_resource_generation() -> void:
	"""处理资源生成（每 UPDATE_INTERVAL 秒调用一次）。"""
	if game_state != null and game_state.is_paused:
		return

	# 计算每秒钟的资源增加（基于每分钟收入和维持费用）
	var net_per_second: float = float(total_income_per_minute - total_upkeep_per_minute) / 60.0

	if net_per_second > 0:
		var old_credits: int = credits
		credits += int(net_per_second)
		total_credits_earned += int(net_per_second)
		credits_changed.emit(old_credits, credits)
		_update_ui()
		_sync_to_game_state()
	elif net_per_second < 0:
		# 资源不足警告（当净支出为负时）
		var deficit_per_second: float = abs(net_per_second)
		var old_credits: int = credits
		credits -= int(deficit_per_second)
		total_credits_spent += int(deficit_per_second)

		if credits <= 0:
			credits = 0
			# 触发资源耗尽警告（可用于游戏结束判定）
			push_warning("资源耗尽！净支出: %d/分钟" % total_upkeep_per_minute)

		credits_changed.emit(old_credits, credits)
		_update_ui()
		_sync_to_game_state()


func _update_ui() -> void:
	"""更新UI显示。"""
	if ui_node == null:
		return

	var ui = ui_node as CanvasLayer
	if ui.has_method("update_credits_display"):
		ui.update_credits_display()


func _sync_to_game_state() -> void:
	"""同步资源状态到 GameState。"""
	if game_state == null:
		return

	game_state.credits = credits
	game_state.credits_per_minute = get_net_income_per_minute()
