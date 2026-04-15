# 机场 - 生产空中单位
extends Building

func _init():
	building_name = "Airfield"
	max_health = 600
	build_cost = 1000
	construction_time = 20.0
	sight_range = 200

var producible_units: Array = ["Helicopter"]
