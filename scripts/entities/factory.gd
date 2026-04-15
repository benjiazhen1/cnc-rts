# 工厂 - 生产车辆单位
extends Building

func _init():
	building_name = "Factory"
	max_health = 800
	build_cost = 800
	construction_time = 15.0
	sight_range = 150

var producible_units: Array = ["LightTank", "HeavyTank"]
