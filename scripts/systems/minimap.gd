# 小地图系统
extends Control

var map_width: int = 32
var map_height: int = 32
var minimap_scale: float = 4.0

var terrain: Node
var player_color: Color = Color(0, 0.5, 0)
var ai_color: Color = Color(0.5, 0, 0)

func _ready():
	custom_minimum_size = Vector2(map_width * minimap_scale, map_height * minimap_scale)
	terrain = get_node("/root/Game/Terrain")

func _draw():
	# 绘制地形
	var terrain_grid = terrain.terrain_grid
	for pos in terrain_grid.keys():
		var t = terrain_grid[pos]
		match t:
			terrain.TerrainType.GRASS:
				draw_rect(Rect2(pos.x * minimap_scale, pos.y * minimap_scale, minimap_scale, minimap_scale), Color(0.2, 0.6, 0.2))
			terrain.TerrainType.WATER:
				draw_rect(Rect2(pos.x * minimap_scale, pos.y * minimap_scale, minimap_scale, minimap_scale), Color(0.2, 0.3, 0.8))
			terrain.TerrainType.ROCK:
				draw_rect(Rect2(pos.x * minimap_scale, pos.y * minimap_scale, minimap_scale, minimap_scale), Color(0.5, 0.5, 0.5))
	
	# 绘制玩家单位/建筑
	var gs = get_node("/root/GameState")
	for building in gs.player_buildings:
		var grid_pos = building.grid_position if "grid_position" in building else Vector2i(int(building.position.x/64), int(building.position.y/64))
		draw_rect(Rect2(grid_pos.x * minimap_scale, grid_pos.y * minimap_scale, minimap_scale*2, minimap_scale*2), player_color)
	
	for unit in gs.player_units:
		var grid_pos = Vector2i(int(unit.position.x/64), int(unit.position.y/64))
		draw_rect(Rect2(grid_pos.x * minimap_scale, grid_pos.y * minimap_scale, minimap_scale, minimap_scale), player_color)

func _process(delta):
	queue_redraw()  # 每帧刷新
