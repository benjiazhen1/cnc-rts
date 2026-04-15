## 小地图系统
##
## 在屏幕角落渲染游戏世界的缩小视图，显示地形、玩家单位和AI单位。
## 每帧更新以反映游戏状态变化。
extends Control

# === 常量 ===

## 小地图默认宽度（格子数）
const DEFAULT_MAP_WIDTH: int = 32
## 小地图默认高度（格子数）
const DEFAULT_MAP_HEIGHT: int = 32
## 小地图缩放比例（像素/格子）
const MINIMAP_SCALE: float = 4.0
## 游戏格子大小（像素），用于将世界坐标转换为格子坐标
const GRID_SIZE: int = 64

# 地形颜色
const COLOR_GRASS: Color = Color(0.2, 0.6, 0.2)
const COLOR_WATER: Color = Color(0.2, 0.3, 0.8)
const COLOR_ROCK: Color = Color(0.5, 0.5, 0.5)

# 单位/建筑在小地图上的显示大小（倍数）
const UNIT_SIZE_MULTIPLIER: float = 1.0
const BUILDING_SIZE_MULTIPLIER: float = 2.0

# === 节点路径 ===
const TERRAIN_NODE_PATH: String = "/root/Game/Terrain"
const GAME_STATE_NODE_PATH: String = "/root/GameState"

# === 变量 ===
var map_width: int = DEFAULT_MAP_WIDTH
var map_height: int = DEFAULT_MAP_HEIGHT
var minimap_scale: float = MINIMAP_SCALE

var terrain: Node
var player_color: Color = Color(0, 0.5, 0)
var ai_color: Color = Color(0.5, 0, 0)

func _ready() -> void:
	"""
	初始化小地图控件。
	设置最小尺寸并获取地形节点引用。
	"""
	custom_minimum_size = Vector2(map_width * minimap_scale, map_height * minimap_scale)

	# 获取地形节点
	terrain = get_node_or_null(TERRAIN_NODE_PATH)
	if terrain == null:
		push_error("Minimap: 无法获取地形节点，路径: " + TERRAIN_NODE_PATH)


func _draw() -> void:
	"""
	绘制小地图内容。
	包括地形网格、玩家单位/建筑、AI单位/建筑。
	"""
	# 安全检查：确保必要节点存在
	if terrain == null:
		push_error("Minimap: terrain节点为空，跳过地形绘制")
		return

	var terrain_grid = terrain.get("terrain_grid")
	if terrain_grid == null:
		push_error("Minimap: terrain.terrain_grid不存在，跳过地形绘制")
		return

	# 绘制地形
	_draw_terrain(terrain_grid)

	# 获取游戏状态并绘制单位/建筑
	var gs = get_node_or_null(GAME_STATE_NODE_PATH)
	if gs == null:
		push_error("Minimap: 无法获取GameState节点，跳过单位绘制")
		return

	_draw_buildings(gs)
	_draw_units(gs)


func _draw_terrain(terrain_grid: Dictionary) -> void:
	"""
	绘制地形网格到小地图。

	参数:
		terrain_grid: 地形网格字典，键为Vector2i位置，值为地形类型枚举
	"""
	for pos in terrain_grid.keys():
		var t = terrain_grid[pos]
		var rect := Rect2(
			pos.x * minimap_scale,
			pos.y * minimap_scale,
			minimap_scale,
			minimap_scale
		)

		match t:
			terrain.TerrainType.GRASS:
				draw_rect(rect, COLOR_GRASS)
			terrain.TerrainType.WATER:
				draw_rect(rect, COLOR_WATER)
			terrain.TerrainType.ROCK:
				draw_rect(rect, COLOR_ROCK)
			_:
				# 未知地形类型，使用默认颜色
				draw_rect(rect, COLOR_GRASS)


func _draw_buildings(gs: Node) -> void:
	"""
	绘制所有玩家的建筑到小地图。

	参数:
		gs: GameState节点，包含player_buildings和ai_buildings列表
	"""
	# 绘制玩家建筑（绿色，尺寸稍大）
	for building in gs.get("player_buildings", []):
		var grid_pos = _get_building_grid_position(building)
		var rect := Rect2(
			grid_pos.x * minimap_scale,
			grid_pos.y * minimap_scale,
			minimap_scale * BUILDING_SIZE_MULTIPLIER,
			minimap_scale * BUILDING_SIZE_MULTIPLIER
		)
		draw_rect(rect, player_color)

	# 绘制AI建筑（红色，尺寸稍大）
	for building in gs.get("ai_buildings", []):
		var grid_pos = _get_building_grid_position(building)
		var rect := Rect2(
			grid_pos.x * minimap_scale,
			grid_pos.y * minimap_scale,
			minimap_scale * BUILDING_SIZE_MULTIPLIER,
			minimap_scale * BUILDING_SIZE_MULTIPLIER
		)
		draw_rect(rect, ai_color)


func _draw_units(gs: Node) -> void:
	"""
	绘制所有玩家的单位到小地图。

	参数:
		gs: GameState节点，包含player_units和ai_units列表
	"""
	# 绘制玩家单位（绿色）
	for unit in gs.get("player_units", []):
		var grid_pos := Vector2i(
			int(unit.position.x / GRID_SIZE),
			int(unit.position.y / GRID_SIZE)
		)
		var rect := Rect2(
			grid_pos.x * minimap_scale,
			grid_pos.y * minimap_scale,
			minimap_scale * UNIT_SIZE_MULTIPLIER,
			minimap_scale * UNIT_SIZE_MULTIPLIER
		)
		draw_rect(rect, player_color)

	# 绘制AI单位（红色）
	for unit in gs.get("ai_units", []):
		var grid_pos := Vector2i(
			int(unit.position.x / GRID_SIZE),
			int(unit.position.y / GRID_SIZE)
		)
		var rect := Rect2(
			grid_pos.x * minimap_scale,
			grid_pos.y * minimap_scale,
			minimap_scale * UNIT_SIZE_MULTIPLIER,
			minimap_scale * UNIT_SIZE_MULTIPLIER
		)
		draw_rect(rect, ai_color)


func _get_building_grid_position(building: Object) -> Vector2i:
	"""
	获取建筑的格子坐标。

	参数:
		building: 建筑节点对象

	返回:
		Vector2i: 建筑在网格中的位置
	"""
	# 优先使用grid_position属性，否则从世界坐标计算
	if "grid_position" in building and building.grid_position is Vector2i:
		return building.grid_position
	else:
		return Vector2i(
			int(building.position.x / GRID_SIZE),
			int(building.position.y / GRID_SIZE)
		)


func _process(delta: float) -> void:
	"""
	每帧处理。
	请求重绘以反映游戏状态变化。

	参数:
		delta: 距离上一帧的时间（秒）
	"""
	queue_redraw()
