# 单位生产系统
extends Node

var production_queue: Array = []
var is_producing: bool = false
var current_production: Dictionary = {}
var production_progress: float = 0.0

var producing_building: Node = null
var game_state: Node

signal production_started(building: Node, unit_type: String)
signal production_complete(unit)
signal production_progress_updated(progress: float)

func _ready():
	game_state = get_node("/root/GameState")

func start_production(building: Node, unit_type: String):
	var cost = get_unit_cost(unit_type)
	if not game_state.spend_credits(cost):
		print("资源不足，无法生产单位!")
		return false
	
	producing_building = building
	current_production = {
		"unit_type": unit_type,
		"cost": cost
	}
	production_progress = 0.0
	is_producing = true
	production_started.emit(building, unit_type)
	return true

func _process(delta):
	if not is_producing:
		return
	
	# 获取建造时间
	var build_time = get_unit_build_time(current_production["unit_type"])
	production_progress += delta / build_time
	production_progress_updated.emit(production_progress)
	
	if production_progress >= 1.0:
		complete_production()

func complete_production():
	is_producing = false
	production_progress = 1.0
	
	# 生成单位
	var unit = spawn_unit(current_production["unit_type"], producing_building)
	
	current_production.clear()
	producing_building = null
	
	production_complete.emit(unit)

func spawn_unit(unit_type: String, source_building: Node) -> Node:
	var unit_scene: PackedScene
	
	match unit_type:
		"Infantry":
			unit_scene = preload("res://scenes/units/infantry.tscn")
		"LightTank":
			unit_scene = preload("res://scenes/units/light_tank.tscn")
		"HeavyTank":
			unit_scene = preload("res://scenes/units/heavy_tank.tscn")
		"Helicopter":
			unit_scene = preload("res://scenes/units/helicopter.tscn")
		"RocketSoldier":
			unit_scene = preload("res://scenes/units/rocket_soldier.tscn")
	
	if unit_scene:
		var unit = unit_scene.instantiate()
		unit.owner = "player"
		# 在建筑旁边生成
		unit.position = source_building.position + Vector2(100, 0)
		get_node("/root/Game/Units").add_child(unit)
		game_state.player_units.append(unit)
		unit.add_to_group("units")
		return unit
	
	return null

func get_unit_cost(unit_type: String) -> int:
	match unit_type:
		"Infantry": return 50
		"RocketSoldier": return 100
		"LightTank": return 200
		"HeavyTank": return 400
		"Helicopter": return 300
		_: return 100

func get_unit_build_time(unit_type: String) -> float:
	match unit_type:
		"Infantry": return 3.0
		"RocketSoldier": return 4.0
		"LightTank": return 6.0
		"HeavyTank": return 8.0
		"Helicopter": return 7.0
		_: return 5.0

func cancel_production():
	is_producing = false
	current_production.clear()
	producing_building = null
	production_progress = 0.0
