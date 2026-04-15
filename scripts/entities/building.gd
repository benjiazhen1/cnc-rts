## Building 基类 - 建筑单位
##
## 该类是所有建筑单位的基类，提供建造、生命值和销毁管理等核心功能。
## 支持建造进度跟踪，完工后进入可用状态。
## 建筑在建造期间脆弱，建成后具有耐久性和战略价值。
class_name Building
extends Node2D

# ============================================================================
# CONSTANTS - 常量定义
# ============================================================================
const DEFAULT_MAX_HEALTH: int = 500       # 默认最大生命值
const DEFAULT_BUILD_COST: int = 500        # 默认建造费用
const DEFAULT_CONSTRUCTION_TIME: float = 5.0 # 默认建造时间（秒）
const DEFAULT_SIGHT_RANGE: int = 200      # 默认视野范围
const DEFAULT_TILE_SIZE: int = 64         # 默认网格大小（像素）
const MIN_HEALTH: int = 0                 # 最小生命值
const REPAIR_COST_RATIO: float = 0.5      # 修复费用比例（缺失生命值的50%）
const CONSTRUCTION_COMPLETE: float = 1.0  # 建造完成进度

# 建造状态颜色定义
const UNDER_CONSTRUCTION_MODULATE: Color = Color(0.7, 0.7, 0.7)  # 建造中颜色（灰色）
const NORMAL_MODULATE: Color = Color(1, 1, 1)                    # 正常颜色
const DAMAGED_MODULATE: Color = Color(1, 0.8, 0.8)              # 受损颜色
const CRITICAL_MODULATE: Color = Color(1, 0.5, 0.5)             # 危急颜色

# ============================================================================
# EXPORT VARIABLES - 导出变量（可在编辑器中配置）
# ============================================================================
@export var building_name: String = "Building"
@export var max_health: int = DEFAULT_MAX_HEALTH
@export var build_cost: int = DEFAULT_BUILD_COST
@export var construction_time: float = DEFAULT_CONSTRUCTION_TIME
@export var sight_range: int = DEFAULT_SIGHT_RANGE

# ============================================================================
# PUBLIC VARIABLES - 公共变量
# ============================================================================
var health: int
var is_constructed: bool = false
var construction_progress: float = 0.0
var owner: String = "player"              # "player" or "ai"

# ============================================================================
# POSITION VARIABLES - 位置相关变量
# ============================================================================
var grid_position: Vector2i
var tile_size: int = DEFAULT_TILE_SIZE

# ============================================================================
# STATE MACHINE - 状态机
# ============================================================================
## 建筑状态枚举
## - UNDER_CONSTRUCTION: 建造中状态，建筑正在施工，生命值脆弱
## - OPERATIONAL: 运营状态，建筑已完工，可正常运作
## - DAMAGED: 受损状态，建筑受到攻击但未摧毁
## - DESTROYED: 销毁状态，建筑已被摧毁，等待移除
enum BuildingState {UNDER_CONSTRUCTION, OPERATIONAL, DAMAGED, DESTROYED}
var state: BuildingState = BuildingState.UNDER_CONSTRUCTION

# ============================================================================
# NODE REFERENCES - 节点引用
# ============================================================================
@onready var sprite: Sprite2D = $Sprite2D
@onready var health_bar: ProgressBar = $HealthBar

# ============================================================================
# SIGNALS - 信号定义
# ============================================================================
signal health_changed(new_health: int)
signal construction_complete()
signal destroyed()

# ============================================================================
# LIFECYCLE - 生命周期
# ============================================================================

## 初始化建筑
## 在节点进入场景树时调用，初始化生命值并开始建造流程
func _ready() -> void:
	# 初始化生命值
	health = max_health

	# 验证建造参数有效性
	if construction_time <= 0:
		push_warning("Building [%s]: Invalid construction_time: %f, using default" % [building_name, construction_time])
		construction_time = DEFAULT_CONSTRUCTION_TIME

	# 验证生命值参数有效性
	if max_health <= 0:
		push_warning("Building [%s]: Invalid max_health: %d, using default" % [building_name, max_health])
		max_health = DEFAULT_MAX_HEALTH
		health = max_health

	# 开始建造流程
	start_construction()

## 获取节点引用，带空值检查
## [param node_path] 节点路径
## [return] 节点引用，如果不存在则返回null
func _get_node_or_null(node_path: String) -> Node:
	if has_node(node_path):
		return get_node(node_path)
	push_warning("Building [%s]: Cannot find node at path: %s" % [building_name, node_path])
	return null

## 主循环处理
## 每帧调用，处理建造进度更新
## [param delta] 帧间隔时间（秒）
func _process(delta: float) -> void:
	# 已销毁状态跳过处理
	if state == BuildingState.DESTROYED:
		return

	# 建造状态处理
	match state:
		BuildingState.UNDER_CONSTRUCTION:
			_process_construction(delta)
		BuildingState.OPERATIONAL, BuildingState.DAMAGED:
			# 这些状态由外部事件驱动
			pass

# ============================================================================
# CONSTRUCTION STATE MACHINE - 建造状态机
# ============================================================================

## 处理建造流程
## 更新建造进度，进度完成时切换到运营状态
## [param delta] 帧间隔时间（秒）
func _process_construction(delta: float) -> void:
	# 验证建造参数
	if construction_time <= 0:
		push_warning("Building [%s]: Cannot construct with invalid time: %f" % [building_name, construction_time])
		return

	# 更新建造进度
	construction_progress += delta / construction_time

	# 限制进度范围 [0, 1]
	construction_progress = clamp(construction_progress, 0.0, CONSTRUCTION_COMPLETE)

	# 进度完成，切换到运营状态
	if construction_progress >= CONSTRUCTION_COMPLETE:
		complete_construction()

## 开始建造流程
## 重置建造状态，进入建造中状态
func start_construction() -> void:
	is_constructed = false
	construction_progress = 0.0
	state = BuildingState.UNDER_CONSTRUCTION

	# 建造中显示灰色
	_apply_construction_visual()

## 建造完成
## 切换到运营状态，发送完工信号
func complete_construction() -> void:
	is_constructed = true
	construction_progress = CONSTRUCTION_COMPLETE
	state = BuildingState.OPERATIONAL

	# 恢复正常颜色
	_apply_normal_visual()

	construction_complete.emit()

## 应用建造中视觉效果
func _apply_construction_visual() -> void:
	if sprite:
		sprite.modulate = UNDER_CONSTRUCTION_MODULATE

## 应用正常视觉效果
func _apply_normal_visual() -> void:
	if sprite:
		sprite.modulate = NORMAL_MODULATE

# ============================================================================
# HEALTH MANAGEMENT - 生命值管理
# ============================================================================

## 承受伤害
## 更新生命值，检查损坏和死亡状态
## [param amount] 伤害值
func take_damage(amount: int) -> void:
	# 已销毁状态忽略伤害
	if state == BuildingState.DESTROYED:
		return

	# 防止负数伤害
	if amount < 0:
		push_warning("Building [%s]: Negative damage received: %d" % [building_name, amount])
		amount = 0

	# 建造中的建筑受到双倍伤害
	if state == BuildingState.UNDER_CONSTRUCTION:
		amount *= 2

	# 应用伤害
	health -= amount
	health_changed.emit(health)

	# 更新视觉状态
	_update_health_visual()

	# 检查损坏状态
	if health < max_health and state == BuildingState.OPERATIONAL:
		state = BuildingState.DAMAGED

	# 检查死亡
	if health <= MIN_HEALTH:
		health = MIN_HEALTH
		destroy()

## 更新基于生命值的视觉效果
func _update_health_visual() -> void:
	if not sprite:
		return

	var health_ratio: float = float(health) / float(max_health)

	if health_ratio <= 0.25:
		sprite.modulate = CRITICAL_MODULATE
	elif health_ratio <= 0.5:
		sprite.modulate = DAMAGED_MODULATE
	else:
		sprite.modulate = NORMAL_MODULATE

## 修复建筑
## [param amount] 修复量
func repair(amount: int) -> void:
	# 已销毁状态无法修复
	if state == BuildingState.DESTROYED:
		push_warning("Building [%s]: Cannot repair a destroyed building" % building_name)
		return

	# 防止负数修复
	if amount < 0:
		push_warning("Building [%s]: Negative repair amount: %d" % [building_name, amount])
		return

	# 满血建筑无需修复
	if health >= max_health:
		return

	health = mini(health + amount, max_health)
	health_changed.emit(health)

	# 修复后恢复正常状态
	if state == BuildingState.DAMAGED and health >= max_health:
		state = BuildingState.OPERATIONAL

	_update_health_visual()

## 获取修复费用
## [return] 当前生命值恢复到满血所需的费用
func get_repair_cost() -> int:
	var missing_health: int = max_health - health
	if missing_health <= 0:
		return 0
	return int(float(missing_health) * REPAIR_COST_RATIO)

## 获取当前生命值
## [return] 当前生命值
func get_health() -> int:
	return health

## 获取最大生命值
## [return] 最大生命值
func get_max_health() -> int:
	return max_health

## 获取生命值百分比
## [return] 0.0 到 1.0 之间的生命值比例
func get_health_ratio() -> float:
	if max_health <= 0:
		return 0.0
	return float(health) / float(max_health)

## 检查建筑是否可用
## [return] 建筑是否处于可操作状态
func is_operational() -> bool:
	return state == BuildingState.OPERATIONAL or state == BuildingState.DAMAGED

## 检查建筑是否正在建造
## [return] 建筑是否处于建造中状态
func is_under_construction() -> bool:
	return state == BuildingState.UNDER_CONSTRUCTION

# ============================================================================
# DESTRUCTION - 销毁系统
# ============================================================================

## 销毁建筑
## 切换到销毁状态，发送销毁信号，移除建筑节点
func destroy() -> void:
	# 防止重复销毁
	if state == BuildingState.DESTROYED:
		return

	state = BuildingState.DESTROYED
	is_constructed = false
	destroyed.emit()

	# 延迟一帧销毁，确保信号被处理
	await get_tree().process_frame
	queue_free()

# ============================================================================
# UTILITY - 工具函数
# ============================================================================

## 获取建筑信息字符串
## [return] 包含建筑基本信息的字符串
func get_info() -> String:
	return "Building[%s]: HP=%d/%d, State=%s, Progress=%.1f%%" % [
		building_name,
		health,
		max_health,
		BuildingState.keys()[state],
		construction_progress * 100
	]
