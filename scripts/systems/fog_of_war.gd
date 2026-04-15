## 战争迷雾系统
# 管理地图探索状态和单位视野可见性
# - visible_tiles: 当前帧可见的瓦片（实时计算）
# - explored_tiles: 曾被探索过的瓦片（永久记录）
# - sight_ranges: 各单位视野范围缓存
extends Node2D

# ============ 常量 ============
# 默认视野范围（像素），当单位未定义sight_range时使用
const DEFAULT_SIGHT_RANGE: float = 150.0
# 默认地图尺寸（瓦片数）
const DEFAULT_MAP_SIZE: Vector2i = Vector2i(32, 32)
# 默认瓦片尺寸（像素）
const DEFAULT_TILE_SIZE: int = 64
# 地形节点路径
const TERRAIN_NODE_PATH: String = "/root/Game/Terrain"

# ============ 状态变量 ============
# 已探索瓦片集合: Vector2i -> bool (true表示已探索)
var explored_tiles: Dictionary = {}
# 当前可见瓦片集合: Vector2i -> bool (true表示当前可见)
var visible_tiles: Dictionary = {}
# 单位视野范围缓存: 单位ID -> 视野范围(像素)
var sight_ranges: Dictionary = {}

# 地图配置
var map_size: Vector2i = DEFAULT_MAP_SIZE
var tile_size: int = DEFAULT_TILE_SIZE

# 地形节点引用
var terrain: Node = null

## 初始化
func _ready() -> void:
	_initialize_terrain()

## 每帧更新可见性
func _process(_delta: float) -> void:
	update_visibility()

## 初始化地形节点引用，带错误处理
func _initialize_terrain() -> void:
	if not has_node(TERRAIN_NODE_PATH):
		push_error("FogOfWar: 找不到地形节点: " + TERRAIN_NODE_PATH)
		return
	terrain = get_node(TERRAIN_NODE_PATH)

## 更新所有单位的可见瓦片
# 遍历所有单位，计算其视野范围内的瓦片
func update_visibility() -> void:
	visible_tiles.clear()

	var units = get_tree().get_nodes_in_group("units")
	if units.is_empty():
		return

	for unit in units:
		_update_unit_visibility(unit)

## 更新单个单位的可见瓦片
# @param unit: 单位节点，需具有sight_range属性
func _update_unit_visibility(unit: Node) -> void:
	# 获取单位位置（转换为瓦片坐标）
	var unit_pos = _get_unit_tile_position(unit)
	if unit_pos == Vector2i(-1, -1):
		return

	# 获取视野范围（像素）
	var sight_range: float = _get_unit_sight_range(unit)
	var sight_tiles: int = int(sight_range / tile_size)

	# 方形区域遍历，计算圆形视野
	for dx in range(-sight_tiles, sight_tiles + 1):
		for dy in range(-sight_tiles, sight_tiles + 1):
			var check_pos: Vector2i = unit_pos + Vector2i(dx, dy)

			# 边界检查
			if not _is_within_bounds(check_pos):
				continue

			# 距离检查（圆形视野）
			var dist: float = sqrt(dx * dx + dy * dy) * tile_size
			if dist <= sight_range:
				visible_tiles[check_pos] = true
				explored_tiles[check_pos] = true

## 获取单位所在瓦片坐标
# @param unit: 单位节点
# @return 瓦片坐标，失败返回Vector2i(-1, -1)
func _get_unit_tile_position(unit: Node) -> Vector2i:
	if not is_instance_valid(unit):
		push_warning("FogOfWar: 单位节点无效")
		return Vector2i(-1, -1)

	if not "global_position" in unit:
		push_warning("FogOfWar: 单位缺少global_position属性")
		return Vector2i(-1, -1)

	return Vector2i(
		int(unit.global_position.x / tile_size),
		int(unit.global_position.y / tile_size)
	)

## 获取单位视野范围
# @param unit: 单位节点
# @return 视野范围（像素），默认150
func _get_unit_sight_range(unit: Node) -> float:
	if "sight_range" in unit:
		return float(unit.sight_range)
	return DEFAULT_SIGHT_RANGE

## 检查坐标是否在地图范围内
# @param pos: 瓦片坐标
# @return 是否在范围内
func _is_within_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < map_size.x and pos.y >= 0 and pos.y < map_size.y

## 检查指定瓦片是否当前可见
# @param pos: 瓦片坐标
# @return 是否可见
func is_visible(pos: Vector2i) -> bool:
	return visible_tiles.has(pos)

## 检查指定瓦片是否曾被探索
# @param pos: 瓦片坐标
# @return 是否已探索
func is_explored(pos: Vector2i) -> bool:
	return explored_tiles.has(pos)

## 重置迷雾状态（可选：游戏重新开始时调用）
func reset() -> void:
	explored_tiles.clear()
	visible_tiles.clear()
	sight_ranges.clear()
