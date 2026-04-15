## 地形系统
##
## 管理游戏地图的地形网格，支持草地、水体、岩石和道路四种地形类型。
## 提供地形查询、建筑可行性和坐标转换等功能。
extends Node2D

# 地形类型枚举
enum TerrainType {
	GRASS = 0,  # 草地 - 可建造
	WATER = 1,  # 水体 - 不可通行
	ROCK = 2,   # 岩石 - 边界/不可通行
	ROAD = 3    # 道路 - 可建造
}

# === 常量 ===

## 单个地形的像素尺寸
const TILE_SIZE: int = 64

## 默认地图尺寸（单位：格子数）
const DEFAULT_MAP_SIZE: Vector2i = Vector2i(32, 32)

## 地图像素尺寸（用于中心点计算）
const TILE_SIZE_FLOAT: float = 64.0

## 地形类型对应的移动消耗（用于后续寻路系统）
const MOVEMENT_COST: Dictionary = {
	TerrainType.GRASS: 1.0,
	TerrainType.WATER: float('inf'),
	TerrainType.ROCK: float('inf'),
	TerrainType.ROAD: 0.5
}

# === 变量 ===

## 地形网格数据，键为格子坐标，值为地形类型
var terrain_grid: Dictionary = {}

## 地图尺寸（单位：格子数）
var map_size: Vector2i = DEFAULT_MAP_SIZE

# === 生命周期 ===

func _ready() -> void:
	generate_map()


# === 核心功能 ===

## 生成随机地形
##
## 初始化地图网格，默认将边缘设为岩石边界，内部设为草地。
## 后续可扩展为更复杂的地形生成算法（如噪声函数）。
func generate_map() -> void:
	# 清空现有数据
	terrain_grid.clear()

	# 遍历所有格子
	for x in range(map_size.x):
		for y in range(map_size.y):
			var pos := Vector2i(x, y)

			# 边缘格子设为岩石边界
			if _is_boundary(pos):
				terrain_grid[pos] = TerrainType.ROCK
			else:
				terrain_grid[pos] = TerrainType.GRASS

	# 连接信号以便通知其他系统（如果有的话）
	# emit_signal("terrain_generated", map_size)


## 获取指定位置的地形类型
##
## @param pos: 格子坐标
## @return 地形类型，若位置无效则返回 ROCK
func get_terrain(pos: Vector2i) -> TerrainType:
	if not _is_valid_pos(pos):
		push_error("TerrainSystem: 无效的坐标 %s，超出地图范围 %s" % [pos, map_size])
		return TerrainType.ROCK

	return terrain_grid.get(pos, TerrainType.ROCK)


## 判断指定位置是否可建造
##
## @param pos: 格子坐标
## @return 是否可以建造建筑
func can_build(pos: Vector2i) -> bool:
	var terrain := get_terrain(pos)
	return terrain == TerrainType.GRASS or terrain == TerrainType.ROAD


## 获取指定格子的世界坐标中心点
##
## 将格子坐标转换为该格子中心的像素坐标。
## @param pos: 格子坐标
## @return 格子中心的二维世界坐标
func get_tile_center(pos: Vector2i) -> Vector2:
	var center_x := pos.x * TILE_SIZE + TILE_SIZE / 2
	var center_y := pos.y * TILE_SIZE + TILE_SIZE / 2
	return Vector2(center_x, center_y)


## 判断指定位置是否可通行（用于寻路）
##
## @param pos: 格子坐标
## @return 是否可以通行
func is_passable(pos: Vector2i) -> bool:
	var terrain := get_terrain(pos)
	var cost: float = MOVEMENT_COST.get(terrain, float('inf'))
	return cost < float('inf')


# === 辅助功能 ===

## 检查坐标是否为边界格子
##
## @param pos: 格子坐标
## @return 是否为边界
func _is_boundary(pos: Vector2i) -> bool:
	return pos.x == 0 or pos.y == 0 or pos.x == map_size.x - 1 or pos.y == map_size.y - 1


## 检查坐标是否在有效范围内
##
## @param pos: 格子坐标
## @return 是否有效
func _is_valid_pos(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.y >= 0 and pos.x < map_size.x and pos.y < map_size.y
