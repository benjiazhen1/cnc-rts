## Unit 基类 - 集成寻路和战斗
##
## 该类是所有游戏单位的基类，提供移动、攻击、状态管理等核心功能。
## 支持状态机驱动的行为模式，包括待机、移动、攻击、巡逻、坚守和死亡状态。
## 集成寻路系统和战斗系统，提供完整的RTS单位行为。
class_name Unit
extends Node2D

# ============================================================================
# CONSTANTS - 常量定义
# ============================================================================
const DEFAULT_ARMOR: float = 1.0       # 默认护甲值
const PATHfinding_NODE: String = "/root/Game/Pathfinding"
const COMBAT_SYSTEM_NODE: String = "/root/Game/CombatSystem"
const DEFAULT_SIGHT_RANGE: int = 150   # 默认视野范围
const DEFAULT_MAX_HEALTH: int = 100    # 默认最大生命值
const DEFAULT_MOVE_SPEED: float = 100.0 # 默认移动速度
const DEFAULT_ATTACK_DAMAGE: int = 10  # 默认攻击力
const DEFAULT_ATTACK_RANGE: float = 50.0 # 默认攻击范围
const DEFAULT_ATTACK_SPEED: float = 1.0 # 默认攻击速度（次/秒）
const DEFAULT_ATTACK_COOLDOWN: float = 0.0 # 初始攻击冷却
const WAYPOINT_THRESHOLD: float = 5.0  # 路径点到达阈值
const ANIMATION_FLASH_DURATION: float = 0.1 # 动画闪烁持续时间

# 状态机颜色定义
const SELECTED_MODULATE: Color = Color(1.3, 1.3, 1.3)  # 选中状态颜色
const ATTACK_FLASH_MODULATE: Color = Color(1.5, 0.5, 0.5) # 攻击闪烁颜色
const DAMAGE_FLASH_MODULATE: Color = Color(1, 0.3, 0.3)  # 受伤闪烁颜色
const NORMAL_MODULATE: Color = Color(1, 1, 1)  # 正常颜色

# ============================================================================
# EXPORT VARIABLES - 导出变量（可在编辑器中配置）
# ============================================================================
@export var unit_name: String = "Unit"
@export var max_health: int = DEFAULT_MAX_HEALTH
@export var move_speed: float = DEFAULT_MOVE_SPEED
@export var attack_damage: int = DEFAULT_ATTACK_DAMAGE
@export var attack_range: float = DEFAULT_ATTACK_RANGE
@export var attack_speed: float = DEFAULT_ATTACK_SPEED
@export var unit_cost: int = 100
@export var sight_range: int = DEFAULT_SIGHT_RANGE
@export var armor: float = DEFAULT_ARMOR

# ============================================================================
# PUBLIC VARIABLES - 公共变量
# ============================================================================
var health: int
var current_health: int
var is_selected: bool = false
var owner: String = "player"

# ============================================================================
# STATE MACHINE - 状态机
# ============================================================================
## 单位状态枚举
## - IDLE: 待机状态，单位静止等待指令
## - MOVING: 移动状态，单位正在沿路径移动
## - ATTACKING: 攻击状态，单位正在追击或攻击目标
## - PATROL: 巡逻状态，单位在多点之间移动巡逻
## - HOLD: 坚守状态，单位停留在原地不追击敌人
## - DEAD: 死亡状态，单位已阵亡，等待移除
enum UnitState {IDLE, MOVING, ATTACKING, PATROL, HOLD, DEAD}
var state: UnitState = UnitState.IDLE

# ============================================================================
# MOVEMENT VARIABLES - 移动相关变量
# ============================================================================
var target_position: Vector2 = Vector2.ZERO
var target_unit: Node = null
var current_path: PackedVector2Array = []
var pathfinding: Node = null
var waypoint_index: int = 0

# ============================================================================
# COMBAT VARIABLES - 战斗相关变量
# ============================================================================
var attack_cooldown: float = DEFAULT_ATTACK_COOLDOWN
var combat_system: Node = null

# ============================================================================
# NODE REFERENCES - 节点引用
# ============================================================================
@onready var sprite: Sprite2D = $Sprite2D
@onready var health_bar: ProgressBar = $HealthBar

# ============================================================================
# SIGNALS - 信号定义
# ============================================================================
signal health_changed(new_health: int)
signal destroyed()
signal attack_issued(target: Node)

# ============================================================================
# LIFECYCLE - 生命周期
# ============================================================================

## 初始化单位
## 在节点进入场景树时调用，初始化生命值和获取系统引用
func _ready() -> void:
	# 初始化生命值
	health = max_health
	current_health = max_health

	# 获取寻路系统引用（带错误处理）
	pathfinding = _get_node_or_null(PATHfinding_NODE)

	# 获取战斗系统引用（带错误处理）
	combat_system = _get_node_or_null(COMBAT_SYSTEM_NODE)

## 获取节点引用，带空值检查
## [param node_path] 节点路径
## [return] 节点引用，如果不存在则返回null
func _get_node_or_null(node_path: String) -> Node:
	if has_node(node_path):
		return get_node(node_path)
	push_warning("Unit [%s]: Cannot find node at path: %s" % [unit_name, node_path])
	return null

## 主循环处理
## 每帧调用，处理攻击冷却和状态机更新
## [param delta] 帧间隔时间（秒）
func _process(delta: float) -> void:
	# 死亡状态跳过处理
	if state == UnitState.DEAD:
		return

	# 更新攻击冷却计时器
	if attack_cooldown > 0:
		attack_cooldown -= delta

	# 状态机处理
	match state:
		UnitState.MOVING:
			_process_movement(delta)
		UnitState.ATTACKING:
			_process_combat()
		UnitState.IDLE, UnitState.PATROL, UnitState.HOLD:
			# 这些状态由外部指令驱动，无需每帧处理
			pass

# ============================================================================
# MOVEMENT - 移动系统
# ============================================================================

## 处理单位移动
## 沿预计算路径移动，或直接向目标位置移动
## [param delta] 帧间隔时间（秒）
func _process_movement(delta: float) -> void:
	# 验证移动速度有效性
	if move_speed <= 0:
		push_warning("Unit [%s]: Invalid move_speed: %f" % [unit_name, move_speed])
		state = UnitState.IDLE
		return

	# 沿路径移动
	if current_path.size() > 0 and waypoint_index < current_path.size():
		_process_path_movement(delta)
	else:
		# 直接向目标位置移动
		_process_direct_movement(delta)

## 沿路径移动处理
## [param delta] 帧间隔时间（秒）
func _process_path_movement(delta: float) -> void:
	var waypoint: Vector2 = current_path[waypoint_index]
	var direction: Vector2 = (waypoint - global_position).normalized()
	global_position += direction * move_speed * delta

	# 检查是否到达当前路径点
	if global_position.distance_to(waypoint) < WAYPOINT_THRESHOLD:
		waypoint_index += 1

	# 检查是否到达终点
	if waypoint_index >= current_path.size():
		_complete_movement()

## 直接移动处理
## [param delta] 帧间隔时间（秒）
func _process_direct_movement(delta: float) -> void:
	if target_position == Vector2.ZERO:
		state = UnitState.IDLE
		return

	var direction: Vector2 = (target_position - global_position).normalized()
	global_position += direction * move_speed * delta

	if global_position.distance_to(target_position) < WAYPOINT_THRESHOLD:
		_complete_movement()

## 完成移动操作
## 清理路径数据并切换到待机状态
func _complete_movement() -> void:
	state = UnitState.IDLE
	current_path.clear()
	waypoint_index = 0
	target_position = Vector2.ZERO

# ============================================================================
# COMBAT - 战斗系统
# ============================================================================

## 处理战斗逻辑
## 检查目标有效性，控制攻击节奏，需要时追击目标
func _process_combat() -> void:
	# 验证目标有效性
	if not _is_valid_target(target_unit):
		_target_invalid()
		return

	var distance: float = global_position.distance_to(target_unit.global_position)

	# 在攻击范围内
	if distance <= attack_range:
		_process_attack_phase()
	else:
		_process_chase_phase()

## 检查目标是否有效
## [param target] 目标单位
## [return] 目标是否有效
func _is_valid_target(target: Node) -> bool:
	if target == null:
		return false
	if not is_instance_valid(target):
		return false
	if target.state == UnitState.DEAD:
		return false
	return true

## 目标无效时的处理
## 尝试查找新目标，否则切换到待机状态
func _target_invalid() -> void:
	target_unit = find_nearest_enemy()
	if target_unit == null:
		state = UnitState.IDLE

## 处理攻击阶段
func _process_attack_phase() -> void:
	if attack_cooldown <= 0:
		perform_attack()

## 处理追击阶段
## 向目标移动并切换到移动状态
func _process_chase_phase() -> void:
	if pathfinding:
		current_path = pathfinding.find_path(global_position, target_unit.global_position)
		waypoint_index = 0
		# 移除起始点避免原地徘徊
		if current_path.size() > 0:
			current_path.remove_at(0)
	else:
		target_position = target_unit.global_position
	state = UnitState.MOVING

## 执行攻击
## 对目标造成伤害，触发攻击动画和冷却
func perform_attack() -> void:
	if not _is_valid_target(target_unit):
		return

	var final_damage: int = attack_damage

	# 通过战斗系统计算伤害（带防御减伤）
	if combat_system:
		var calculated_damage: float = combat_system.calculate_damage(self, target_unit, attack_damage)
		final_damage = int(calculated_damage * target_unit.armor)
	else:
		# 简化的本地伤害计算
		final_damage = int(attack_damage / target_unit.armor) if target_unit.armor > 0 else attack_damage

	target_unit.take_damage(final_damage)
	attack_cooldown = attack_speed
	attack_issued.emit(target_unit)

	# 播放攻击动画
	_play_attack_animation()

## 播放攻击动画
## 红色闪烁效果提示攻击发生
func _play_attack_animation() -> void:
	if sprite:
		sprite.modulate = ATTACK_FLASH_MODULATE
		await get_tree().create_timer(ANIMATION_FLASH_DURATION).timeout
		if sprite:
			sprite.modulate = NORMAL_MODULATE

## 查找最近的敌人
## [return] 最近的敌对单位，如果没有则返回null
func find_nearest_enemy() -> Node:
	if combat_system:
		return combat_system.find_nearest_enemy(self)
	push_warning("Unit [%s]: CombatSystem not available for enemy search" % unit_name)
	return null

# ============================================================================
# COMMANDS - 指令系统
# ============================================================================

## 向指定位置移动
## 使用寻路系统计算最优路径
## [param pos] 目标位置（世界坐标）
func move_to(pos: Vector2) -> void:
	if state == UnitState.DEAD:
		return

	target_position = pos
	state = UnitState.MOVING

	# 使用寻路系统计算路径
	if pathfinding:
		current_path = pathfinding.find_path(global_position, pos)
		waypoint_index = 0
		if current_path.size() > 0:
			current_path.remove_at(0)  # 移除起始点

## 攻击指定目标
## [param unit] 目标单位
func attack_target(unit: Node) -> void:
	if state == UnitState.DEAD:
		return
	if not _is_valid_target(unit):
		push_warning("Unit [%s]: Cannot attack invalid target" % unit_name)
		return

	target_unit = unit
	state = UnitState.ATTACKING

## 停止单位当前行动
## 切换到待机状态，清除所有目标
func stop() -> void:
	state = UnitState.IDLE
	target_position = Vector2.ZERO
	target_unit = null
	current_path.clear()
	waypoint_index = 0

## 坚守位置
## 与stop()类似，但强调不追击敌人
func hold_position() -> void:
	stop()
	state = UnitState.HOLD

## 巡逻到指定位置
## [param pos] 巡逻目标位置
func patrol(pos: Vector2) -> void:
	if state == UnitState.DEAD:
		return

	target_position = pos
	state = UnitState.PATROL

## 承受伤害
## 应用护甲减伤，更新生命值，检查死亡
## [param amount] 原始伤害值
func take_damage(amount: int) -> void:
	if state == UnitState.DEAD:
		return

	# 防止负数伤害
	if amount < 0:
		push_warning("Unit [%s]: Negative damage received: %d" % [unit_name, amount])
		amount = 0

	# 护甲减伤计算
	var actual_damage: int = amount
	if armor > 0:
		actual_damage = int(amount / armor)

	current_health -= actual_damage
	health_changed.emit(current_health)

	# 播放受伤动画
	_play_damage_animation()

	# 检查死亡
	if current_health <= 0:
		current_health = 0
		die()

## 播放受伤动画
func _play_damage_animation() -> void:
	if sprite:
		sprite.modulate = DAMAGE_FLASH_MODULATE
		await get_tree().create_timer(ANIMATION_FLASH_DURATION).timeout
		if sprite:
			sprite.modulate = NORMAL_MODULATE

## 单位死亡
## 切换到死亡状态，发送销毁信号，移除单位
func die() -> void:
	state = UnitState.DEAD
	destroyed.emit()
	queue_free()

## 选中单位
## 高亮显示单位表示被选中
func select() -> void:
	is_selected = true
	if sprite:
		sprite.modulate = SELECTED_MODULATE

## 取消选中
## 恢复正常显示
func deselect() -> void:
	is_selected = false
	if sprite:
		sprite.modulate = NORMAL_MODULATE
