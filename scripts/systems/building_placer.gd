# 建筑放置系统
extends Node

enum PlaceMode {NONE, PLACING, CONFIRMING}
var current_mode: PlaceMode = PlaceMode.NONE

var ghost_building: Node2D = null
var current_building_type: String = ""
var can_place: bool = false
var grid_position: Vector2i

var terrain: Node
var game_state: Node

signal placement_complete(building_type: String, pos: Vector2i)
signal placement_cancelled()

func _ready():
	terrain = get_node("/root/Game/Terrain")
	game_state = get_node("/root/GameState")

func _input(event):
	match current_mode:
		PlaceMode.PLACING:
			if event is InputEventMouseMotion:
				update_ghost_position(event.position)
			elif event is InputEventMouseButton:
				if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
					confirm_placement()
				elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
					cancel_placement()

func start_placement(building_type: String):
	current_mode = PlaceMode.PLACING
	current_building_type = building_type
	create_ghost_building(building_type)

func create_ghost_building(building_type: String):
	ghost_building = Node2D.new()
	ghost_building.name = "GhostBuilding"
	
	# 创建幽灵建筑外观
	var rect = ColorRect.new()
	rect.name = "GhostRect"
	rect.size = Vector2(64, 64)
	rect.color = Color(0, 1, 0, 0.5)  # 绿色半透明
	ghost_building.add_child(rect)
	
	get_node("/root/Game/Buildings").add_child(ghost_building)

func update_ghost_position(pos: Vector2):
	if ghost_building == null:
		return
	
	# 网格对齐
	grid_position = Vector2i(int(pos.x / 64), int(pos.y / 64))
	ghost_building.position = Vector2(grid_position.x * 64, grid_position.y * 64)
	
	# 检查是否可以放置
	can_place = terrain.can_build(grid_position)
	var rect = ghost_building.get_node("GhostRect")
	if can_place:
		rect.color = Color(0, 1, 0, 0.5)  # 绿色
	else:
		rect.color = Color(1, 0, 0, 0.5)  # 红色

func confirm_placement():
	if not can_place:
		return
	
	# 检查资源
	var cost = get_building_cost(current_building_type)
	if not game_state.spend_credits(cost):
		print("资源不足!")
		return
	
	# 创建真实建筑
	spawn_building(current_building_type, grid_position)
	placement_complete.emit(current_building_type, grid_position)
	end_placement()

func spawn_building(building_type: String, pos: Vector2i):
	var building_scene: PackedScene
	
	match building_type:
		"Command Center":
			building_scene = preload("res://scenes/buildings/command_center.tscn")
		"Power Plant":
			building_scene = preload("res://scenes/buildings/power_plant.tscn")
		"Barracks":
			building_scene = preload("res://scenes/buildings/barracks.tscn")
		"Factory":
			building_scene = preload("res://scenes/buildings/factory.tscn")
		"Airfield":
			building_scene = preload("res://scenes/buildings/airfield.tscn")
	
	if building_scene:
		var building = building_scene.instantiate()
		building.grid_position = pos
		building.position = Vector2(pos.x * 64, pos.y * 64)
		building.owner = "player"
		get_node("/root/Game/Buildings").add_child(building)
		game_state.player_buildings.append(building)

func cancel_placement():
	end_placement()
	placement_cancelled.emit()

func end_placement():
	current_mode = PlaceMode.NONE
	if ghost_building:
		ghost_building.queue_free()
		ghost_building = null

func get_building_cost(building_type: String) -> int:
	match building_type:
		"Power Plant": return 300
		"Barracks": return 500
		"Factory": return 800
		"Airfield": return 1000
		_: return 500
