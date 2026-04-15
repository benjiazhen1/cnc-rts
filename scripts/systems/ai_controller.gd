## AI控制器 - 负责AI的建造、攻击和防御行为
##
## AI行为基于状态机模型，包含三种状态：
## - BUILDING: 积累资源和建筑阶段
## - ATTACKING: 拥有足够单位后发起进攻
## - DEFENDING: 当建筑数量不足时转为防守
##
## 状态切换规则：
## - 单位数量 >= 10 时进入ATTACKING状态
## - 建筑数量 < 3 时进入BUILDING状态
## - 其他情况保持当前状态
extends Node

# === 常量 ===

## 初始资源数量
const INITIAL_CREDITS: int = 2000

## 策略执行间隔（秒）
const STRATEGY_INTERVAL: float = 10.0

## 每回合获得的资源量
const CREDITS_PER_PHASE: int = 500

## 触发攻击状态的最小单位数量
const ATTACK_THRESHOLD_UNITS: int = 10

## 触发建造状态的最小建筑数量
const BUILD_THRESHOLD_BUILDINGS: int = 3

## 单位数组最大容量（防止内存溢出）
const MAX_UNITS: int = 100

## 建筑数组最大容量（防止内存溢出）
const MAX_BUILDINGS: int = 50

# === 状态枚举 ===

## AI状态机
enum AIState {
	BUILDING,   # 建造阶段：积累资源，建造建筑
	ATTACKING,  # 进攻阶段：拥有足够单位，主动攻击玩家
	DEFENDING   # 防御阶段：建筑不足，转为防守
}

# === 成员变量 ===

var ai_credits: int = INITIAL_CREDITS
var ai_buildings: Array = []
var ai_units: Array = []
var strategy_timer: float = 0.0
var current_state: AIState = AIState.BUILDING

# === 生命周期 ===

func _process(delta: float) -> void:
	"""
	每帧更新策略计时器，达到间隔后执行策略。

	Args:
		delta: 帧间隔时间（秒）
	"""
	strategy_timer += delta
	if strategy_timer >= STRATEGY_INTERVAL:
		strategy_timer = 0.0
		execute_strategy()


# === 核心策略 ===

func execute_strategy() -> void:
	"""
	执行AI策略的主入口。
	根据当前状态执行对应行为，然后根据条件判断是否切换状态。
	"""
	match current_state:
		AIState.BUILDING:
			ai_build_phase()
		AIState.ATTACKING:
			ai_attack_phase()
		AIState.DEFENDING:
			ai_defend_phase()
		_:
			push_error("AI状态机：未知状态 %d" % current_state)
			current_state = AIState.BUILDING  # 未知状态时恢复默认

	_transition_state()


func ai_build_phase() -> void:
	"""
	建造阶段：积累资源。
	每回合给予AI一定资源，直到满足建筑建造条件。
	"""
	ai_credits += CREDITS_PER_PHASE


func ai_attack_phase() -> void:
	"""
	进攻阶段：当AI拥有足够单位时，主动寻找并攻击玩家目标。
	如果没有可用单位，切换到防御状态。
	"""
	if ai_units.is_empty():
		push_warning("AI攻击阶段：没有可用单位，切换到防御状态")
		current_state = AIState.DEFENDING
		return

	# TODO: 实现攻击逻辑 - 随机选择玩家单位或建筑作为攻击目标
	# 攻击目标选择策略：
	# 1. 优先攻击血量低的单位
	# 2. 其次攻击关键建筑（如指挥中心）
	# 3. 避免攻击过度设防的目标


func ai_defend_phase() -> void:
	"""
	防御阶段：当建筑数量不足时，AI聚焦于建造更多建筑。
	"""
	if ai_buildings.size() >= BUILD_THRESHOLD_BUILDINGS:
		current_state = AIState.BUILDING


# === 状态切换 ===

func _transition_state() -> void:
	"""
	根据当前资源状况判断是否需要切换状态。
	状态切换优先级：进攻 > 建造 > 防御
	"""
	# 优先检查是否应该进攻（单位数量足够）
	if ai_units.size() >= ATTACK_THRESHOLD_UNITS:
		if current_state != AIState.ATTACKING:
			_debug_log("AI切换到进攻状态 (单位数: %d)" % ai_units.size())
		current_state = AIState.ATTACKING
		return

	# 检查是否应该建造（建筑数量不足）
	if ai_buildings.size() < BUILD_THRESHOLD_BUILDINGS:
		if current_state != AIState.BUILDING:
			_debug_log("AI切换到建造状态 (建筑数: %d)" % ai_buildings.size())
		current_state = AIState.BUILDING
		return


# === 单位/建筑管理 ===

func add_ai_building(building: Node) -> void:
	"""
	添加建筑到AI控制列表。

	Args:
		building: 要添加的建筑节点

	Errors:
		如果建筑列表已满，打印错误并拒绝添加
	"""
	if ai_buildings.size() >= MAX_BUILDINGS:
		push_error("AI建筑列表已满 (最大: %d)，无法添加更多建筑" % MAX_BUILDINGS)
		return

	if building == null:
		push_error("AI尝试添加空建筑节点")
		return

	if building in ai_buildings:
		push_warning("AI建筑列表中已存在该建筑，跳过添加")
		return

	ai_buildings.append(building)
	_debug_log("AI添加建筑 (总数: %d)" % ai_buildings.size())


func add_ai_unit(unit: Node) -> void:
	"""
	添加单位到AI控制列表。

	Args:
		unit: 要添加的单位节点

	Errors:
		如果单位列表已满，打印错误并拒绝添加
	"""
	if ai_units.size() >= MAX_UNITS:
		push_error("AI单位列表已满 (最大: %d)，无法添加更多单位" % MAX_UNITS)
		return

	if unit == null:
		push_error("AI尝试添加空单位节点")
		return

	if unit in ai_units:
		push_warning("AI单位列表中已存在该单位，跳过添加")
		return

	ai_units.append(unit)
	_debug_log("AI添加单位 (总数: %d)" % ai_units.size())


func remove_ai_building(building: Node) -> bool:
	"""
	从AI控制列表移除建筑。

	Args:
		building: 要移除的建筑节点

	Returns:
		是否成功移除
	"""
	var index: int = ai_buildings.find(building)
	if index == -1:
		push_warning("尝试移除不存在的AI建筑")
		return false

	ai_buildings.remove_at(index)
	_debug_log("AI移除建筑 (剩余: %d)" % ai_buildings.size())
	return true


func remove_ai_unit(unit: Node) -> bool:
	"""
	从AI控制列表移除单位。

	Args:
		unit: 要移除的单位节点

	Returns:
		是否成功移除
	"""
	var index: int = ai_units.find(unit)
	if index == -1:
		push_warning("尝试移除不存在的AI单位")
		return false

	ai_units.remove_at(index)
	_debug_log("AI移除单位 (剩余: %d)" % ai_units.size())
	return true


# === 工具函数 ===

func _debug_log(message: String) -> void:
	"""
	输出调试日志（仅在调试模式下生效）。

	Args:
		message: 日志消息
	"""
	if OS.is_debug_build():
		print("[AI] ", message)


func get_ai_status() -> Dictionary:
	"""
	获取AI当前状态信息，用于调试或UI显示。

	Returns:
		包含AI状态、资源、单位/建筑数量的字典
	"""
	return {
		"state": AIState.keys()[current_state],
		"credits": ai_credits,
		"unit_count": ai_units.size(),
		"building_count": ai_buildings.size()
	}
