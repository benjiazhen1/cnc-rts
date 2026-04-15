# 指挥中心 - 主基地
extends Building

func _init():
	building_name = "Command Center"
	max_health = 1000
	build_cost = 0  # 免费，起始建筑
	construction_time = 0
	sight_range = 300
