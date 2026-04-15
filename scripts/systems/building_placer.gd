## 建筑放置系统
## 处理建筑物的网格对齐放置、幽灵预览和放置确认
class_name BuildingPlacer
extends Node

# 放置模式枚举
enum PlaceMode {
	NONE = 0,       # 无放置操作
	PLACING = 1,   # 正在放置模式
	CONFIRMING = 2 # 确认中模式
}

# ============ 常量 ============
# 网格设置
const GRID_CELL_SIZE: int = 64  # 网格单元格大小（像素）

# 幽灵建筑外观
const GHOST_TRANSPARENCY: float = 0.5  # 幽灵建筑透明度
const GHOST_VALID_COLOR: Color = Color(0.0, 1.0, 0.0, GHOST_TRANSPARENCY)  # 可放置时绿色
const GHOST_INVALID_COLOR: Color = Color(1.0, 0.0, 0.0, GHOST_TRANSPARENCY)  # 不可放置时红色

# 建筑成本
const COST_POWER_PLANT: int = 300
const COST_BARRACKS: int = 500
const COST_FACTORY: int = 800
const COST_AIRFIELD: int = 1000
const COST_DEFAULT: int = 500  # 默认成本（用于未知建筑类型）

# 场景路径
const SCENE_COMMAND_CENTER: String = "res://scenes/buildings/command_center.tscn"
const SCENE_POWER_PLANT: String = "res://scenes/buildings/power_plant.tscn"
const SCENE_BARRACKS: String = "res://scenes/buildings/barracks.tscn"
const SCENE_FACTORY: String = "res://scenes/buildings/factory.tscn"
const SCENE_AIRFIELD: String = "res://scenes/buildings/airfield.tscn"

# 节点路径
const PATH_TERRAIN: String = "/root/Game/Terrain"
const PATH_GAME_STATE: String = "/root/GameState"
const PATH_BUILDINGS: String = "/root/Game/Buildings"

# ============ 状态变量 ============
var current_mode: PlaceMode = PlaceMode.NONE
var ghost_building: Node2D = null
var current_building_type: String = ""
var can_place: bool = false
var grid_position: Vector2i

# ============ 依赖节点 ============
var terrain: Node
var game_state: Node

# ============ 信号定义 ============
## 放置完成信号
signal placement_complete(building_type: String, pos: Vector2i)
## 放置取消信号
signal placement_cancelled()

# ============ 生命周期 ============

func _ready() -> void:
	"""
	初始化获取游戏节点引用
	"""
	_initialize_nodes()

func _initialize_nodes() -> void:
	"""
	获取必要的游戏系统节点引用
	"""
	# 确保依赖节点存在
	if not NodePath(PATH_TERRAIN).get_name_count() > 0:
		push_error("BuildingPlacer: Terrain节点未找到 at " + PATH_TERRAIN)
		return

	if not NodePath(PATH_GAME_STATE).get_name_count() > 0:
		push_error("BuildingPlacer: GameState节点未找到 at " + PATH_GAME_STATE)
		return

	terrain = get_node(PATH_TERRAIN)
	game_state = get_node(PATH_GAME_STATE)

func _input(event: InputEvent) -> void:
	"""
	处理鼠标输入事件进行建筑放置
	"""
	match current_mode:
		PlaceMode.PLACING:
			_handle_placing_input(event)
		PlaceMode.NONE:
			pass  # 无操作时忽略输入
		PlaceMode.CONFIRMING:
			pass  # 确认中时忽略输入

# ============ 公共方法 ============

## 开始建筑放置流程
## [param building_type] 建筑类型名称
func start_placement(building_type: String) -> void:
	if building_type.is_empty():
		push_error("BuildingPlacer: 不能放置空建筑类型")
		return

	current_mode = PlaceMode.PLACING
	current_building_type = building_type
	create_ghost_building(building_type)

## 取消当前放置操作
func cancel_placement() -> void:
	end_placement()
	placement_cancelled.emit()

# ============ 私有方法 ============

func _handle_placing_input(event: InputEvent) -> void:
	"""
	处理放置模式下的输入事件
	"""
	if event is InputEventMouseMotion:
		update_ghost_position(event.position)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			confirm_placement()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			cancel_placement()

func create_ghost_building(building_type: String) -> void:
	"""
	创建幽灵建筑用于放置预览
	"""
	# 清理已存在的幽灵建筑
	if ghost_building != null:
		ghost_building.queue_free()
		ghost_building = null

	ghost_building = Node2D.new()
	ghost_building.name = "GhostBuilding"

	# 创建幽灵建筑外观
	var rect = ColorRect.new()
	rect.name = "GhostRect"
	rect.size = Vector2(GRID_CELL_SIZE, GRID_CELL_SIZE)
	rect.color = GHOST_VALID_COLOR  # 默认绿色（可放置）
	ghost_building.add_child(rect)

	# 添加到建筑容器节点
	var buildings_container = get_node_or_null(PATH_BUILDINGS)
	if buildings_container == null:
		push_error("BuildingPlacer: Buildings容器节点未找到 at " + PATH_BUILDINGS)
		return

	buildings_container.add_child(ghost_building)

func update_ghost_position(pos: Vector2) -> void:
	"""
	更新幽灵建筑位置并检查是否可放置

	[param pos] 鼠标世界坐标
	"""
	if ghost_building == null:
		push_warning("BuildingPlacer: ghost_building为null，跳过位置更新")
		return

	# 网格对齐计算
	grid_position = Vector2i(
		int(pos.x / GRID_CELL_SIZE),
		int(pos.y / GRID_CELL_SIZE)
	)
	ghost_building.position = Vector2(
		grid_position.x * GRID_CELL_SIZE,
		grid_position.y * GRID_CELL_SIZE
	)

	# 检查是否可以放置
	can_place = terrain.can_build(grid_position)

	# 更新幽灵颜色反馈
	var rect = ghost_building.get_node_or_null("GhostRect")
	if rect != null:
		rect.color = GHOST_VALID_COLOR if can_place else GHOST_INVALID_COLOR
	else:
		push_warning("BuildingPlacer: GhostRect节点未找到")

func confirm_placement() -> void:
	"""
	确认放置建筑
	"""
	if not can_place:
		push_warning("BuildingPlacer: 当前位置不可放置建筑")
		return

	# 检查资源是否足够
	var cost: int = get_building_cost(current_building_type)
	if not game_state.spend_credits(cost):
		push_warning("BuildingPlacer: 资源不足，无法放置 " + current_building_type)
		return

	# 创建真实建筑
	var building = spawn_building(current_building_type, grid_position)
	if building == null:
		push_error("BuildingPlacer: 建筑创建失败 " + current_building_type)
		return

	# 通知并清理
	placement_complete.emit(current_building_type, grid_position)
	end_placement()

func spawn_building(building_type: String, pos: Vector2i) -> Node:
	"""
	实例化并放置真实建筑

	[param building_type] 建筑类型
	[param pos] 网格位置
	[return] 创建的建筑节点，失败返回null
	"""
	var scene_path: String = _get_building_scene_path(building_type)
	if scene_path.is_empty():
		push_error("BuildingPlacer: 未知建筑类型: " + building_type)
		return null

	var building_scene: PackedScene = load(scene_path)
	if building_scene == null:
		push_error("BuildingPlacer: 无法加载场景: " + scene_path)
		return null

	var building: Node = building_scene.instantiate()
	if building == null:
		push_error("BuildingPlacer: 场景实例化失败: " + scene_path)
		return null

	# 配置建筑属性
	building.grid_position = pos
	building.position = Vector2(pos.x * GRID_CELL_SIZE, pos.y * GRID_CELL_SIZE)
	building.set("owner", "player") if "owner" in building else null

	# 添加到场景树
	var buildings_container = get_node_or_null(PATH_BUILDINGS)
	if buildings_container == null:
		push_error("BuildingPlacer: Buildings容器节点未找到")
		building.queue_free()
		return null

	buildings_container.add_child(building)

	# 注册到游戏状态
	if game_state.player_buildings != null:
		game_state.player_buildings.append(building)
	else:
		push_warning("BuildingPlacer: player_buildings列表未初始化")

	return building

func end_placement() -> void:
	"""
	结束放置流程，清理状态
	"""
	current_mode = PlaceMode.NONE
	current_building_type = ""
	can_place = false

	if ghost_building != null:
		ghost_building.queue_free()
		ghost_building = null

func _get_building_scene_path(building_type: String) -> String:
	"""
	根据建筑类型获取场景路径

	[param building_type] 建筑类型名称
	[return] 场景资源路径，未知类型返回空字符串
	"""
	match building_type:
		"Command Center":
			return SCENE_COMMAND_CENTER
		"Power Plant":
			return SCENE_POWER_PLANT
		"Barracks":
			return SCENE_BARRACKS
		"Factory":
			return SCENE_FACTORY
		"Airfield":
			return SCENE_AIRFIELD
		_:
			return ""

func get_building_cost(building_type: String) -> int:
	"""
	获取建筑成本

	[param building_type] 建筑类型名称
	[return] 建筑成本（货币单位）
	"""
	match building_type:
		"Power Plant":
			return COST_POWER_PLANT
		"Barracks":
			return COST_BARRACKS
		"Factory":
			return COST_FACTORY
		"Airfield":
			return COST_AIRFIELD
		"Command Center":
			return COST_DEFAULT  # Command Center使用默认成本
		_:
			push_warning("BuildingPlacer: 未知建筑类型成本: " + building_type + "，使用默认成本")
			return COST_DEFAULT
