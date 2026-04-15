# 主游戏脚本
extends Node2D

@onready var terrain: Node = $Terrain
@onready var selection_system: Node = $SelectionSystem
@onready var ai_controller: Node = $AIController
@onready var building_placer: Node = $BuildingPlacer
@onready var unit_production: Node = $UnitProduction

func _ready():
	# 连接信号
	building_placer.placement_complete.connect(_on_building_placed)
	unit_production.production_complete.connect(_on_unit_produced)
	
	# 连接快捷键
	var hotkey = preload("res://scripts/systems/hotkey_system.gd").new()
	add_child(hotkey)
	hotkey.build_command.connect(_on_build_command)
	hotkey.production_command.connect(_on_production_command)
	
	print("Command & War - 游戏已加载")

func _on_build_command(building_type: String):
	building_placer.start_placement(building_type)

func _on_production_command(unit_type: String):
	# 获取选中的建筑
	var selected_building = get_selected_building()
	if selected_building != null:
		unit_production.start_production(selected_building, unit_type)

func get_selected_building() -> Node:
	# 返回玩家选中的建筑
	var buildings = get_tree().get_nodes_in_group("player_buildings")
	for building in buildings:
		if building.is_selected:
			return building
	return null

func _on_building_placed(building_type: String, pos: Vector2i):
	print("建筑已放置: %s at %s" % [building_type, pos])

func _on_unit_produced(unit):
	print("单位已生产: %s" % unit.unit_name)
