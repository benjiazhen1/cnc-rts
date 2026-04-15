# Unit 基类 - 集成寻路和战斗
extends Node2D
class_name Unit

## 单位属性
@export var unit_name: String = "Unit"
@export var max_health: int = 100
@export var move_speed: float = 100.0
@export var attack_damage: int = 10
@export var attack_range: float = 50.0
@export var attack_speed: float = 1.0
@export var unit_cost: int = 100
@export var sight_range: int = 150
@export var armor: float = 1.0  # 护甲减伤系数

var health: int
var current_health: int
var is_selected: bool = false
var owner: String = "player"

# 状态机
enum UnitState {IDLE, MOVING, ATTACKING, PATROL, HOLD, DEAD}
var state: UnitState = UnitState.IDLE

# 移动
var target_position: Vector2
var target_unit: Node
var current_path: PackedVector2Array = []
var pathfinding: Node
var waypoint_index: int = 0

# 攻击
var attack_cooldown: float = 0.0
var combat_system: Node

# 动画
@onready var sprite: Sprite2D = $Sprite2D
@onready var health_bar: ProgressBar = $HealthBar

signal health_changed(new_health: int)
signal destroyed()
signal attack_issued(target: Node)

func _ready():
	current_health = max_health
	health = max_health
	pathfinding = get_node("/root/Game/Pathfinding") if has_node("/root/Game/Pathfinding") else null
	combat_system = get_node("/root/Game/CombatSystem") if has_node("/root/Game/CombatSystem") else null

func _process(delta):
	if state == UnitState.DEAD:
		return
	
	# 攻击冷却
	if attack_cooldown > 0:
		attack_cooldown -= delta
	
	# 状态处理
	match state:
		UnitState.MOVING:
			process_movement(delta)
		UnitState.ATTACKING:
			process_combat()

func process_movement(delta):
	if current_path.size() > 0 and waypoint_index < current_path.size():
		var waypoint = current_path[waypoint_index]
		var direction = (waypoint - global_position).normalized()
		global_position += direction * move_speed * delta
		
		# 到达当前路径点
		if global_position.distance_to(waypoint) < 5:
			waypoint_index += 1
		
		# 到达终点
		if waypoint_index >= current_path.size():
			state = UnitState.IDLE
			current_path.clear()
	else:
		# 没有路径，直接移动到目标
		if target_position != Vector2.ZERO:
			var direction = (target_position - global_position).normalized()
			global_position += direction * move_speed * delta
			
			if global_position.distance_to(target_position) < 5:
				state = UnitState.IDLE
				target_position = Vector2.ZERO

func process_combat():
	if target_unit == null or target_unit.state == UnitState.DEAD:
		# 目标死亡，查找新目标
		target_unit = find_nearest_enemy()
		if target_unit == null:
			state = UnitState.IDLE
			return
	
	var distance = global_position.distance_to(target_unit.global_position)
	
	# 在攻击范围内
	if distance <= attack_range:
		# 攻击
		if attack_cooldown <= 0:
			perform_attack()
	else:
		# 移动到目标
		if pathfinding:
			current_path = pathfinding.find_path(global_position, target_unit.global_position)
			waypoint_index = 0
		else:
			target_position = target_unit.global_position
		state = UnitState.MOVING

func perform_attack():
	if combat_system:
		var damage = combat_system.calculate_damage(self, target_unit, attack_damage)
		target_unit.take_damage(int(damage * target_unit.armor))
	else:
		target_unit.take_damage(attack_damage)
	
	attack_cooldown = attack_speed
	attack_issued.emit(target_unit)
	
	# 播放攻击动画
	if sprite:
		sprite.modulate = Color(1.5, 0.5, 0.5)  # 红色闪烁
		await get_tree().create_timer(0.1).timeout
		sprite.modulate = Color(1, 1, 1)

func find_nearest_enemy() -> Node:
	if combat_system:
		return combat_system.find_nearest_enemy(self)
	return null

func move_to(pos: Vector2):
	target_position = pos
	state = UnitState.MOVING
	
	# 使用寻路
	if pathfinding:
		current_path = pathfinding.find_path(global_position, pos)
		waypoint_index = 0
		if current_path.size() > 0:
			current_path.remove_at(0)  # 移除起始点

func attack_target(unit: Node):
	target_unit = unit
	state = UnitState.ATTACKING

func stop():
	state = UnitState.IDLE
	target_position = Vector2.ZERO
	target_unit = null
	current_path.clear()

func hold_position():
	stop()

func patrol(pos: Vector2):
	target_position = pos
	state = UnitState.PATROL

func take_damage(amount: int):
	# 护甲减伤
	var actual_damage = int(amount / armor)
	current_health -= actual_damage
	health_changed.emit(current_health)
	
	# 受伤动画
	if sprite:
		sprite.modulate = Color(1, 0.3, 0.3)
		await get_tree().create_timer(0.1).timeout
		sprite.modulate = Color(1, 1, 1)
	
	if current_health <= 0:
		die()

func die():
	state = UnitState.DEAD
	destroyed.emit()
	queue_free()

func select():
	is_selected = true
	if sprite:
		sprite.modulate = Color(1.3, 1.3, 1.3)

func deselect():
	is_selected = false
	if sprite:
		sprite.modulate = Color(1, 1, 1)
