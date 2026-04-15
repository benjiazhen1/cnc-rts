# 寻路系统 - A*算法实现
extends Node

var navigation_region: Node2D
var astar: AStar2D = AStar2D.new()

var map_size: Vector2i = Vector2i(32, 32)
var tile_size: int = 64

var terrain: Node
var walkable_tiles: Array = []  # 可行走的地形类型

func _ready():
	terrain = get_node("/root/Game/Terrain")
	walkable_tiles = [terrain.TerrainType.GRASS, terrain.TerrainType.ROAD]
	build_astar_graph()

func build_astar_graph():
	astar.clear()
	
	# 创建所有可行走点
	for x in range(map_size.x):
		for y in range(map_size.y):
			var pos = Vector2i(x, y)
			if terrain.can_build(pos) or terrain.get_terrain(pos) in walkable_tiles:
				var world_pos = terrain.get_tile_center(pos)
				astar.add_point(pos_to_id(pos), world_pos)
	
	# 连接相邻点
	for x in range(map_size.x):
		for y in range(map_size.y):
			var pos = Vector2i(x, y)
			if not astar.has_point(pos_to_id(pos)):
				continue
			
			# 4方向连接
			var neighbors = [
				Vector2i(x-1, y), Vector2i(x+1, y),
				Vector2i(x, y-1), Vector2i(x, y+1)
			]
			
			for n in neighbors:
				if n.x >= 0 and n.x < map_size.x and n.y >= 0 and n.y < map_size.y:
					if astar.has_point(pos_to_id(n)):
						astar.connect_points(pos_to_id(pos), pos_to_id(n), false)
			
			# 8方向连接（对角线）
			var diagonals = [
				Vector2i(x-1, y-1), Vector2i(x+1, y-1),
				Vector2i(x-1, y+1), Vector2i(x+1, y+1)
			]
			
			for d in diagonals:
				if d.x >= 0 and d.x < map_size.x and d.y >= 0 and d.y < map_size.y:
					if astar.has_point(pos_to_id(d)):
						# 对角线连接（需要两个相邻的4方向都可走才能连对角线）
						var can_diag = astar.has_point(pos_to_id(Vector2i(x-1, y))) and \
									   astar.has_point(pos_to_id(Vector2i(x, y-1))) or \
									   astar.has_point(pos_to_id(Vector2i(x+1, y))) and \
									   astar.has_point(pos_to_id(Vector2i(x, y-1))) or \
									   astar.has_point(pos_to_id(Vector2i(x-1, y))) and \
									   astar.has_point(pos_to_id(Vector2i(x, y+1))) or \
									   astar.has_point(pos_to_id(Vector2i(x+1, y))) and \
									   astar.has_point(pos_to_id(Vector2i(x, y+1))
						if can_diag:
							astar.connect_points(pos_to_id(pos), pos_to_id(d), false)

func find_path(start_pos: Vector2, end_pos: Vector2) -> PackedVector2Array:
	var start_id = pos_to_id(world_to_grid(start_pos))
	var end_id = pos_to_id(world_to_grid(end_pos))
	
	if not astar.has_point(start_id) or not astar.has_point(end_id):
		return PackedVector2Array([end_pos])  # 直接返回终点
	
	var path_ids = astar.get_point_path(start_id, end_id)
	var path = PackedVector2Array()
	
	for id in path_ids:
		path.append(astar.get_point_position(id))
	
	if path.size() == 0:
		return PackedVector2Array([end_pos])
	
	return path

func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(int(world_pos.x / tile_size), int(world_pos.y / tile_size))

func pos_to_id(pos: Vector2i) -> int:
	return pos.x * 100 + pos.y

func id_to_pos(id: int) -> Vector2i:
	return Vector2i(id / 100, id % 100)

func is_walkable(pos: Vector2i) -> bool:
	if pos.x < 0 or pos.x >= map_size.x or pos.y < 0 or pos.y >= map_size.y:
		return false
	return terrain.get_terrain(pos) in walkable_tiles
