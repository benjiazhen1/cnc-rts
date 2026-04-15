# Building 基类
extends Node2D
class_name Building

## 建筑属性
@export var building_name: String = "Building"
@export var max_health: int = 500
@export var build_cost: int = 500
@export var construction_time: float = 5.0
@export var sight_range: int = 200

var health: int
var is_constructed: bool = false
var construction_progress: float = 0.0
var owner: String = "player"  # "player" or "ai"

# 位置
var grid_position: Vector2i
var tile_size: int = 64

signal health_changed(new_health: int)
signal construction_complete()
signal destroyed()

func _ready():
	health = max_health
	# 开始建造
	start_construction()

func start_construction():
	is_constructed = false
	construction_progress = 0.0

func _process(delta):
	if not is_constructed:
		construction_progress += delta / construction_time
		if construction_progress >= 1.0:
			complete_construction()

func complete_construction():
	is_constructed = true
	construction_progress = 1.0
	construction_complete.emit()

func take_damage(amount: int):
	health -= amount
	health_changed.emit(health)
	if health <= 0:
		destroy()

func destroy():
	destroyed.emit()
	queue_free()

func get_repair_cost() -> int:
	var missing = max_health - health
	return missing / 2  # 修复费用是缺失生命值的一半
