# 战争迷雾系统
extends Node2D

var explored_tiles: Dictionary = {}  # Vector2i -> bool
var visible_tiles: Dictionary = {}    # Vector2i -> bool
var sight_ranges: Dictionary = {}    # 单位ID -> sight_range

var map_size: Vector2i = Vector2i(32, 32)
var tile_size: int = 64

var terrain: Node

func _ready():
	terrain = get_node("/root/Game/Terrain")

func _process(delta):
	update_visibility()

func update_visibility():
	visible_tiles.clear()
	
	# 遍历所有单位
	var units = get_tree().get_nodes_in_group("units")
	for unit in units:
		var unit_pos = Vector2i(int(unit.global_position.x / tile_size), int(unit.global_position.y / tile_size))
		var sight = unit.sight_range if "sight_range" in unit else 150
		
		# 简化的视野计算（方形区域）
		var sight_tiles = int(sight / tile_size)
		for dx in range(-sight_tiles, sight_tiles + 1):
			for dy in range(-sight_tiles, sight_tiles + 1):
				var check_pos = unit_pos + Vector2i(dx, dy)
				if check_pos.x >= 0 and check_pos.x < map_size.x and check_pos.y >= 0 and check_pos.y < map_size.y:
					var dist = sqrt(dx*dx + dy*dy) * tile_size
					if dist <= sight:
						visible_tiles[check_pos] = true
						explored_tiles[check_pos] = true  # 探索过的区域标记

func is_visible(pos: Vector2i) -> bool:
	return visible_tiles.has(pos)

func is_explored(pos: Vector2i) -> bool:
	return explored_tiles.has(pos)
