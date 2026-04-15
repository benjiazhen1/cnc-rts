# Game State Manager - 全局游戏状态
extends Node

enum GamePhase {MENU, LOADING, PLAYING, PAUSED, GAME_OVER}
var current_phase: GamePhase = GamePhase.MENU

# 玩家资源
var credits: int = 1000
var credits_per_minute: int = 100

# 单位/建筑计数
var player_buildings: Array = []
var player_units: Array = []
var ai_buildings: Array = []
var ai_units: Array = []

# 地图
var current_map: String = "map_01"
var map_size: Vector2i = Vector2i(64, 64)

# 游戏速度
var game_speed: float = 1.0
var is_paused: bool = false

func _ready():
	# 连接信号
	pass

func start_new_game():
	current_phase = GamePhase.PLAYING
	credits = 1000
	player_buildings.clear()
	player_units.clear()
	ai_buildings.clear()
	ai_units.clear()

func pause_game():
	is_paused = true
	current_phase = GamePhase.PAUSED

func resume_game():
	is_paused = false
	current_phase = GamePhase.PLAYING

func add_credits(amount: int):
	credits += amount

func spend_credits(amount: int) -> bool:
	if credits >= amount:
		credits -= amount
		return true
	return false

func get_credit_rate() -> int:
	return player_buildings.size() * 10  # 每个建筑+10/分
