# Steam统计/进度系统
extends Node

var game_stats: Dictionary = {
	"games_played": 0,
	"games_won": 0,
	"games_lost": 0,
	"total_units_produced": 0,
	"total_buildings_built": 0,
	"total_damage_dealt": 0,
	"total_units_destroyed": 0,
	"highest_score": 0,
	"total_playtime": 0
}

func _ready():
	load_stats()

func save_stats():
	var steam_mgr = get_node("/root/Game/SteamManager")
	if steam_mgr and steam_mgr.is_steam_initialized:
		for stat in game_stats:
			var value = game_stats[stat]
			if value is int:
				Steam.setStatInt(stat, value)
			elif value is float:
				Steam.setStatFloat(stat, value)
		Steam.storeStats()
	
	# 同时保存到本地
	var file = FileAccess.open("user://game_stats.dat", FileAccess.WRITE)
	if file:
		file.store_var(game_stats)
		file.close()

func load_stats():
	# 尝试从Steam云加载
	var steam_mgr = get_node("/root/Game/SteamManager")
	if steam_mgr and steam_mgr.is_steam_initialized:
		for stat in game_stats:
			if Steam.getStatType(stat) == "INTEGER":
				game_stats[stat] = Steam.getStatInt(stat)
			elif Steam.getStatType(stat) == "FLOAT":
				game_stats[stat] = Steam.getStatFloat(stat)
	
	# 本地备份
	var file = FileAccess.open("user://game_stats.dat", FileAccess.READ)
	if file:
		var local_stats = file.get_var()
		if local_stats:
			game_stats = local_stats
		file.close()

func increment_stat(stat_name: String, amount: int = 1):
	if stat_name in game_stats:
		game_stats[stat_name] += amount
		save_stats()

func set_highest_score(score: int):
	if score > game_stats["highest_score"]:
		game_stats["highest_score"] = score
		save_stats()
