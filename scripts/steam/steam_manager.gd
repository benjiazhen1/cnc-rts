# Steam SDK集成管理器
extends Node

# Steam状态
var is_steam_initialized: bool = false
var is_online: bool = false
var steam_id: int = 0
var persona_name: String = ""

# 成就进度
var achievements: Dictionary = {
	"FIRST_BUILDING": false,
	"FIRST_UNIT": false,
	"FIRST_BATTLE": false,
	"FIRST_WIN": false,
	"FIRST_LOSS": false,
	"DESTROY_10_UNITS": false,
	"BUILD_ARMY": false,
	"TECH_UP": false
}

signal steam_initialized(success: bool)
signal achievement_unlocked(achievement_id: String)

func _ready():
	# 注意: GodotSteam需要编译进引擎
	# 以下代码在非Steam环境下会静默失败
	initialize_steam()

func initialize_steam():
	# 模拟检查（实际需要GodotSteam模块）
	# 在Steam运行时自动启用
	is_steam_initialized = false
	print("Steam管理器已加载 (需要GodotSteam模块)")

func unlock_achievement(achievement_id: String):
	if not is_steam_initialized:
		return
	
	if achievement_id in achievements and not achievements[achievement_id]:
		achievements[achievement_id] = true
		achievement_unlocked.emit(achievement_id)
		print("成就解锁: ", achievement_id)

func on_building_built():
	unlock_achievement("FIRST_BUILDING")

func on_unit_produced():
	unlock_achievement("FIRST_UNIT")
	var gs = get_node_or_null("/root/GameState")
	if gs and gs.player_units.size() >= 20:
		unlock_achievement("BUILD_ARMY")

func on_battle_started():
	unlock_achievement("FIRST_BATTLE")

func on_game_won():
	unlock_achievement("FIRST_WIN")

func on_game_lost():
	unlock_achievement("FIRST_LOSS")

func submit_score(leaderboard_name: String, score: int):
	if not is_steam_initialized:
		return
	print("提交分数到排行榜: ", leaderboard_name, " = ", score)
