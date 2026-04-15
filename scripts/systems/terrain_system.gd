# 地形系统
extends Node2D

enum TerrainType {GRASS, WATER, ROCK, ROAD}

const TILE_SIZE: int = 64

var terrain_grid: Dictionary = {}  # Vector2i -> TerrainType
var map_size: Vector2i = Vector2i(32, 32)

func _ready():
	generate_map()

func generate_map():
	# 生成随机地形
	for x in range(map_size.x):
		for y in range(map_size.y):
			var pos = Vector2i(x, y)
			# 边缘是岩石
			if x == 0 or y == 0 or x == map_size.x - 1 or y == map_size.y - 1:
				terrain_grid[pos] = TerrainType.ROCK
			else:
				terrain_grid[pos] = TerrainType.GRASS

func get_terrain(pos: Vector2i) -> TerrainType:
	return terrain_grid.get(pos, TerrainType.ROCK)

func can_build(pos: Vector2i) -> bool:
	var terrain = get_terrain(pos)
	return terrain == TerrainType.GRASS or terrain == TerrainType.ROAD

func get_tile_center(pos: Vector2i) -> Vector2:
	return Vector2(pos.x * TILE_SIZE + TILE_SIZE/2, pos.y * TILE_SIZE + TILE_SIZE/2)
