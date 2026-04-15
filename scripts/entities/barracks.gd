# 兵营 - 生产步兵单位
extends Building

func _init():
	building_name = "Barracks"
	max_health = 600
	build_cost = 500
	construction_time = 10.0
	sight_range = 150

# 可生产的单位
var producible_units: Array = ["Infantry", "RocketSoldier"]

func can_produce(unit_name: String) -> bool:
	return unit_name in producible_units
