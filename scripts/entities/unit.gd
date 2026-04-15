# Unit 基类
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

var health: int
var current_health: int
var is_selected: bool = false
var owner: String = "player"

# 状态机
enum UnitState {IDLE, MOVING, ATTACKING, PATROL, HOLD}
var state: UnitState = UnitState.IDLE

# 移动目标
var target_position: Vector2
var target_unit: Unit

# 攻击冷却
var attack_cooldown: float = 0.0

# 动画
@onready var sprite: Sprite2D = $Sprite2D
@onready var health_bar: ProgressBar = $HealthBar

signal health_changed(new_health: int)
signal destroyed()

func _ready():
	current_health = max_health
	health = max_health

func _process(delta):
	# 攻击冷却
	if attack_cooldown > 0:
		attack_cooldown -= delta
	
	# 状态处理
	match state:
		UnitState.MOVING:
			process_movement(delta)
		UnitState.ATTACKING:
			process_attack()

func process_movement(delta):
	if target_position != Vector2.ZERO:
		var direction = (target_position - global_position).normalized()
		global_position += direction * move_speed * delta
		
		if global_position.distance_to(target_position) < 5:
			state = UnitState.IDLE
			target_position = Vector2.ZERO

func process_attack():
	if target_unit != null and attack_cooldown <= 0:
		if global_position.distance_to(target_unit.global_position) <= attack_range:
			target_unit.take_damage(attack_damage)
			attack_cooldown = attack_speed
		else:
			# 移动到目标
			target_position = target_unit.global_position
			state = UnitState.MOVING

func move_to(pos: Vector2):
	target_position = pos
	state = UnitState.MOVING

func attack_target(unit: Unit):
	target_unit = unit
	state = UnitState.ATTACKING

func stop():
	state = UnitState.IDLE
	target_position = Vector2.ZERO
	target_unit = null

func take_damage(amount: int):
	current_health -= amount
	health_changed.emit(current_health)
	if current_health <= 0:
		die()

func die():
	destroyed.emit()
	queue_free()

func select():
	is_selected = true
	sprite.modulate = Color(1.3, 1.3, 1.3)  # 高亮

func deselect():
	is_selected = false
	sprite.modulate = Color(1, 1, 1)
