## 单位生产系统
##
## 负责处理游戏中单位的生产逻辑，包括资源消耗、建造时间管理、
## 单位生成和队列管理。挂载到游戏场景的对应节点上使用。
extends Node

# ==================== 资源与建造常量 ====================
## 步兵花费
const COST_INFANTRY: int = 50
## 火箭兵花费
const COST_ROCKET_SOLDIER: int = 100
## 轻型坦克花费
const COST_LIGHT_TANK: int = 200
## 重型坦克花费
const COST_HEAVY_TANK: int = 400
## 直升机花费
const COST_HELICOPTER: int = 300
## 默认单位花费
const COST_DEFAULT: int = 100

## 步兵建造时间（秒）
const BUILD_TIME_INFANTRY: float = 3.0
## 火箭兵建造时间（秒）
const BUILD_TIME_ROCKET_SOLDIER: float = 4.0
## 轻型坦克建造时间（秒）
const BUILD_TIME_LIGHT_TANK: float = 6.0
## 重型坦克建造时间（秒）
const BUILD_TIME_HEAVY_TANK: float = 8.0
## 直升机建造时间（秒）
const BUILD_TIME_HELICOPTER: float = 7.0
## 默认建造时间（秒）
const BUILD_TIME_DEFAULT: float = 5.0

## 生产完成的进度阈值
const PRODUCTION_COMPLETE_THRESHOLD: float = 1.0
## 单位生成位置偏移量（建筑旁边的相对位置）
const SPAWN_OFFSET: Vector2 = Vector2(100, 0)

# ==================== 单位场景路径 ====================
const SCENE_INFANTRY: String = "res://scenes/units/infantry.tscn"
const SCENE_ROCKET_SOLDIER: String = "res://scenes/units/rocket_soldier.tscn"
const SCENE_LIGHT_TANK: String = "res://scenes/units/light_tank.tscn"
const SCENE_HEAVY_TANK: String = "res://scenes/units/heavy_tank.tscn"
const SCENE_HELICOPTER: String = "res://scenes/units/helicopter.tscn"

# ==================== 错误消息 ====================
const ERR_INSUFFICIENT_CREDITS: String = "资源不足，无法生产单位！"
const ERR_INVALID_UNIT_TYPE: String = "无效的单位类型：%s"
const ERR_SCENE_LOAD_FAILED: String = "加载单位场景失败：%s"
const ERR_GAME_STATE_MISSING: String = "GameState 节点未找到"
const ERR_UNITS_NODE_MISSING: String = "Units 节点未找到"

# ==================== 信号定义 ====================
## 当单位开始生产时触发
## [param building] 生产该单位的建筑
## [param unit_type] 生产的单位类型
signal production_started(building: Node, unit_type: String)

## 当单位生产完成时触发
## [param unit] 生成的游戏单位节点
signal production_complete(unit)

## 生产进度更新时触发
## [param progress] 当前进度，范围 0.0 - 1.0
signal production_progress_updated(progress: float)

# ==================== 内部状态变量 ====================
## 生产队列（暂未使用，预留功能）
var production_queue: Array = []
## 是否正在生产中
var is_producing: bool = false
## 当前正在生产的单位信息
var current_production: Dictionary = {}
## 当前生产进度，范围 0.0 - 1.0
var production_progress: float = 0.0
## 正在生产的建筑引用
var producing_building: Node = null

# ==================== 依赖节点引用 ====================
var game_state: Node

func _ready() -> void:
	"""初始化时获取 GameState 节点引用。"""
	game_state = get_node("/root/GameState")
	if not is_instance_valid(game_state):
		push_error(ERR_GAME_STATE_MISSING)


## 开始生产指定类型的单位
##
## [param building] 执行生产指令的建筑
## [param unit_type] 要生产的单位类型（如 "Infantry"、"LightTank" 等）
## [return] 生产成功返回 true，资源不足或无效类型返回 false
func start_production(building: Node, unit_type: String) -> bool:
	# 参数验证
	if not is_instance_valid(building):
		push_error("无效的建筑引用")
		return false

	if not _is_valid_unit_type(unit_type):
		push_error(ERR_INVALID_UNIT_TYPE % unit_type)
		return false

	# 检查资源是否足够
	var cost: int = get_unit_cost(unit_type)
	if not game_state.spend_credits(cost):
		print(ERR_INSUFFICIENT_CREDITS)
		return false

	# 设置生产状态
	producing_building = building
	current_production = {
		"unit_type": unit_type,
		"cost": cost
	}
	production_progress = 0.0
	is_producing = true

	production_started.emit(building, unit_type)
	return true


## 每帧处理生产进度
##
## [param delta] 距离上一帧的时间（秒）
func _process(delta: float) -> void:
	if not is_producing:
		return

	# 获取当前单位的建造时间
	var unit_type: String = current_production.get("unit_type", "")
	var build_time: float = get_unit_build_time(unit_type)

	# 避免除以零
	if build_time <= 0.0:
		push_error("单位 %s 的建造时间无效: %f" % [unit_type, build_time])
		return

	production_progress += delta / build_time
	production_progress_updated.emit(production_progress)

	if production_progress >= PRODUCTION_COMPLETE_THRESHOLD:
		complete_production()


## 完成生产，生成单位实例
func complete_production() -> void:
	is_producing = false
	production_progress = PRODUCTION_COMPLETE_THRESHOLD

	# 生成单位
	var unit: Node = spawn_unit(current_production["unit_type"], producing_building)

	current_production.clear()
	producing_building = null

	if is_instance_valid(unit):
		production_complete.emit(unit)


## 生成指定类型的单位实例
##
## [param unit_type] 单位类型
## [param source_building] 来源建筑，用于确定生成位置
## [return] 生成成功返回单位节点，失败返回 null
func spawn_unit(unit_type: String, source_building: Node) -> Node:
	var scene_path: String = _get_unit_scene_path(unit_type)
	var unit_scene: PackedScene = load(scene_path)

	if unit_scene == null:
		push_error(ERR_SCENE_LOAD_FAILED % scene_path)
		return null

	var unit: Node = unit_scene.instantiate()
	unit.owner = "player"

	# 在建筑旁边生成单位
	var spawn_pos: Vector2 = source_building.position + SPAWN_OFFSET
	unit.position = spawn_pos

	# 添加到场景树和游戏状态
	var units_node: Node = get_node("/root/Game/Units")
	if not is_instance_valid(units_node):
		push_error(ERR_UNITS_NODE_MISSING)
		unit.queue_free()
		return null

	units_node.add_child(unit)
	game_state.player_units.append(unit)
	unit.add_to_group("units")

	return unit


## 获取指定单位的花费
##
## [param unit_type] 单位类型
## [return] 该单位的资源花费
func get_unit_cost(unit_type: String) -> int:
	match unit_type:
		"Infantry":       return COST_INFANTRY
		"RocketSoldier":  return COST_ROCKET_SOLDIER
		"LightTank":      return COST_LIGHT_TANK
		"HeavyTank":      return COST_HEAVY_TANK
		"Helicopter":     return COST_HELICOPTER
		_:                return COST_DEFAULT


## 获取指定单位的建造时间
##
## [param unit_type] 单位类型
## [return] 建造所需时间（秒）
func get_unit_build_time(unit_type: String) -> float:
	match unit_type:
		"Infantry":       return BUILD_TIME_INFANTRY
		"RocketSoldier":  return BUILD_TIME_ROCKET_SOLDIER
		"LightTank":      return BUILD_TIME_LIGHT_TANK
		"HeavyTank":      return BUILD_TIME_HEAVY_TANK
		"Helicopter":     return BUILD_TIME_HELICOPTER
		_:                return BUILD_TIME_DEFAULT


## 取消当前生产
func cancel_production() -> void:
	is_producing = false
	current_production.clear()
	producing_building = null
	production_progress = 0.0


## 检查单位类型是否有效
##
## [param unit_type] 单位类型字符串
## [return] 是否为有效的单位类型
func _is_valid_unit_type(unit_type: String) -> bool:
	return unit_type in ["Infantry", "RocketSoldier", "LightTank", "HeavyTank", "Helicopter"]


## 获取单位类型对应的场景路径
##
## [param unit_type] 单位类型
## [return] 场景资源的路径
func _get_unit_scene_path(unit_type: String) -> String:
	match unit_type:
		"Infantry":       return SCENE_INFANTRY
		"RocketSoldier":  return SCENE_ROCKET_SOLDIER
		"LightTank":      return SCENE_LIGHT_TANK
		"HeavyTank":      return SCENE_HEAVY_TANK
		"Helicopter":     return SCENE_HELICOPTER
		_:                return SCENE_INFANTRY
