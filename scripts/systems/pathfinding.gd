#寻路系统 - A*算法实现
# A* (A-Star) pathfinding system using Godot's AStar2D for grid-based navigation.
# Supports 4-directional and 8-directional (diagonal) movement with terrain-aware pathfinding.
extends Node

# Map configuration constants
const MAP_SIZE: Vector2i = Vector2i(32, 32)  # Number of tiles in the grid (width x height)
const TILE_SIZE: int = 64  # Size of each tile in world units (pixels)
const GRID_ID_MULTIPLIER: int = 100  # Multiplier for encoding 2D grid positions into 1D point IDs
                                       # NOTE: GRID_ID_MULTIPLIER must be >= MAP_SIZE.x for unique ID encoding

# Cardinal directions (4-directional movement: up, down, left, right)
const CARDINAL_DIRECTIONS: Array[Vector2i] = [
	Vector2i(-1, 0),  # Left
	Vector2i(1, 0),   # Right
	Vector2i(0, -1),  # Up
	Vector2i(0, 1)    # Down
]

# Diagonal directions (8-directional movement adds diagonals)
const DIAGONAL_DIRECTIONS: Array[Vector2i] = [
	Vector2i(-1, -1),  # Top-left
	Vector2i(1, -1),   # Top-right
	Vector2i(-1, 1),   # Bottom-left
	Vector2i(1, 1)    # Bottom-right
]

# A* algorithm internal state constants
const DEFAULT_COST: float = 1.0  # Base movement cost for adjacent tiles
const DIAGONAL_COST: float = 1.414  # Cost for diagonal movement (sqrt(2), approximates Euclidean distance)

var navigation_region: Node2D
var astar: AStar2D = AStar2D.new()

var map_size: Vector2i = MAP_SIZE
var tile_size: int = TILE_SIZE

var terrain: Node
var walkable_tiles: Array = []  # Terrain types that units can walk on

## A* Pathfinding System
#
# This system implements the A* algorithm for grid-based pathfinding in an RTS game.
# It builds a navigation graph from the terrain map and finds optimal paths between points.
#
# A* Algorithm Overview:
# - Uses a best-first search strategy with heuristic guidance
# - Maintains two sets: OPEN (nodes to evaluate) and CLOSED (nodes already evaluated)
# - For each node, calculates: f(n) = g(n) + h(n)
#   - g(n): Actual cost from start to current node
#   - h(n): Estimated cost from current node to goal (heuristic)
# - Uses AStar2D which efficiently manages the graph structure and pathfinding
#
# Diagonal Movement Rules:
# - Diagonal connections are only created when BOTH adjacent cardinal neighbors are walkable
# - This prevents diagonal movement through "wall corners" and ensures natural movement

func _ready() -> void:
	terrain = get_node("/root/Game/Terrain")
	walkable_tiles = [terrain.TerrainType.GRASS, terrain.TerrainType.ROAD]
	build_astar_graph()

## Builds the AStar2D navigation graph from the terrain map
#
# Iterates through all tiles in the map grid. For each tile that is walkable
# (based on terrain type and buildability), adds a point to the AStar graph.
# Then connects adjacent walkable points with edges:
#   - 4-directional (cardinal) edges for up/down/left/right
#   - 8-directional (diagonal) edges only if both adjacent cardinal paths exist
#
# This two-pass approach ensures the graph only contains reachable walkable terrain.
func build_astar_graph() -> void:
	astar.clear()

	# PASS 1: Create all walkable points in the grid
	for x in range(map_size.x):
		for y in range(map_size.y):
			var pos := Vector2i(x, y)
			if terrain.can_build(pos) or terrain.get_terrain(pos) in walkable_tiles:
				var world_pos := terrain.get_tile_center(pos)
				astar.add_point(pos_to_id(pos), world_pos)

	# PASS 2: Connect adjacent points with edges
	for x in range(map_size.x):
		for y in range(map_size.y):
			var pos := Vector2i(x, y)
			var current_id := pos_to_id(pos)

			# Skip if current position has no point in the graph
			if not astar.has_point(current_id):
				continue

			_connect_cardinal_neighbors(pos, current_id)
			_connect_diagonal_neighbors(pos, current_id)

## Connects a point to its 4 cardinal neighbors (up, down, left, right)
#
# @param pos: Grid position of the current point
# @param current_id: AStar point ID of the current point
func _connect_cardinal_neighbors(pos: Vector2i, current_id: int) -> void:
	for direction in CARDINAL_DIRECTIONS:
		var neighbor_pos := pos + direction

		# Bounds check: ensure neighbor is within map boundaries
		if not _is_within_bounds(neighbor_pos):
			continue

		var neighbor_id := pos_to_id(neighbor_pos)

		# Only connect if neighbor point exists in graph
		if astar.has_point(neighbor_id):
			astar.connect_points(current_id, neighbor_id, false)

## Connects a point to its diagonal neighbors (4 corners)
#
# Diagonal movement is only allowed when BOTH adjacent cardinal neighbors are walkable.
# This prevents units from "cutting corners" through walls.
#
# Example: Moving diagonally from (x,y) to (x+1,y+1) requires both:
#   - Point at (x+1, y) is walkable (right neighbor)
#   - Point at (x, y+1) is walkable (bottom neighbor)
#
# @param pos: Grid position of the current point
# @param current_id: AStar point ID of the current point
func _connect_diagonal_neighbors(pos: Vector2i, current_id: int) -> void:
	for direction in DIAGONAL_DIRECTIONS:
		var diagonal_pos := pos + direction

		# Bounds check: ensure diagonal position is within map boundaries
		if not _is_within_bounds(diagonal_pos):
			continue

		var diagonal_id := pos_to_id(diagonal_pos)

		# Only process if diagonal point exists in graph
		if not astar.has_point(diagonal_id):
			continue

		# Check if all required cardinal paths exist for valid diagonal movement
		if _can_move_diagonally(pos, direction):
			astar.connect_points(current_id, diagonal_id, false)

## Checks if diagonal movement is valid given the current position and diagonal direction
#
# A diagonal move requires both of its adjacent cardinal neighbors to be walkable.
# This ensures units don't clip through corners of buildings/walls.
#
# @param pos: Current grid position
# @param diag_dir: Diagonal direction to move
# @return: true if diagonal movement is valid
func _can_move_diagonally(pos: Vector2i, diag_dir: Vector2i) -> bool:
	# Determine the two cardinal directions that form this diagonal
	var card1: Vector2i
	var card2: Vector2i

	if diag_dir.x < 0:
		card1 = Vector2i(-1, 0)  # Left
		card2 = Vector2i(0, diag_dir.y)  # Up or Down
	else:
		card1 = Vector2i(1, 0)   # Right
		card2 = Vector2i(0, diag_dir.y)  # Up or Down

	var neighbor1_pos := pos + card1
	var neighbor2_pos := pos + card2

	# Both adjacent cardinal neighbors must exist for valid diagonal movement
	var neighbor1_exists := astar.has_point(pos_to_id(neighbor1_pos))
	var neighbor2_exists := astar.has_point(pos_to_id(neighbor2_pos))

	return neighbor1_exists and neighbor2_exists

## Checks if a grid position is within the map boundaries
#
# @param pos: Grid position to check
# @return: true if position is within [0, map_size) bounds
func _is_within_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < map_size.x and pos.y >= 0 and pos.y < map_size.y

## Finds an optimal path between two world positions using A* algorithm
#
# @param start_pos: Starting position in world coordinates
# @param end_pos: Target position in world coordinates
# @return: Array of Vector2 points forming the path, or empty array if no path exists
#
# Error Handling:
# - Returns empty PackedVector2Array if start or end is not on a walkable tile
# - Returns empty PackedVector2Array if no valid path exists between points
func find_path(start_pos: Vector2, end_pos: Vector2) -> PackedVector2Array:
	# Convert world positions to grid positions
	var start_grid := world_to_grid(start_pos)
	var end_grid := world_to_grid(end_pos)

	# Get AStar point IDs for both positions
	var start_id := pos_to_id(start_grid)
	var end_id := pos_to_id(end_grid)

	# Validate that both endpoints exist in the navigation graph
	if not astar.has_point(start_id):
		push_warning("Pathfinding: Start position is not on a walkable tile: %s" % [start_grid])
		return PackedVector2Array()

	if not astar.has_point(end_id):
		push_warning("Pathfinding: End position is not on a walkable tile: %s" % [end_grid])
		return PackedVector2Array()

	# Use AStar2D's built-in A* implementation
	var path_ids := astar.get_point_path(start_id, end_id)

	# Convert point IDs back to world positions
	var path := PackedVector2Array()
	for point_id in path_ids:
		path.append(astar.get_point_position(point_id))

	# Validate path result
	if path.size() == 0:
		push_warning("Pathfinding: No valid path found from %s to %s" % [start_grid, end_grid])
		return PackedVector2Array()

	return path

## Converts a world position to a grid position
#
# @param world_pos: Position in world coordinates (pixels)
# @return: Corresponding grid tile coordinates
func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(int(world_pos.x / tile_size), int(world_pos.y / tile_size))

## Converts a grid position to a unique AStar point ID
#
# Uses a simple encoding: id = x * GRID_ID_MULTIPLIER + y
# GRID_ID_MULTIPLIER must be >= map_size.x to ensure unique IDs
#
# @param pos: Grid position to encode
# @return: Unique integer ID for the AStar point
func pos_to_id(pos: Vector2i) -> int:
	return pos.x * GRID_ID_MULTIPLIER + pos.y

## Converts an AStar point ID back to a grid position
#
# @param id: AStar point ID to decode
# @return: Corresponding grid position
func id_to_pos(id: int) -> Vector2i:
	return Vector2i(id / GRID_ID_MULTIPLIER, id % GRID_ID_MULTIPLIER)

## Checks if a grid position is walkable (passable for pathfinding)
#
# @param pos: Grid position to check
# @return: true if the position is within bounds and has walkable terrain
func is_walkable(pos: Vector2i) -> bool:
	# First check if position is within map boundaries
	if not _is_within_bounds(pos):
		return false

	# Then check if terrain type is walkable
	return terrain.get_terrain(pos) in walkable_tiles
