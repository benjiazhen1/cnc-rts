# 生产面板UI
extends Control

signal unit_produced(unit_type: String)

var current_building: Node = null
var available_units: Array = []

func _ready():
	visible = false

func show_production_menu(building: Node):
	current_building = building
	visible = true
	
	# 根据建筑类型显示可生产单位
	var vbox = $PanelContainer/VBoxContainer
	# 清除旧按钮
	for child in vbox.get_children():
		child.queue_free()
	
	var units = get_producible_units(building.building_name)
	for unit in units:
		var btn = Button.new()
		btn.text = "%s - %d矿" % [unit["name"], unit["cost"]]
		btn.custom_minimum_size = Vector2(180, 36)
		vbox.add_child(btn)
		btn.pressed.connect(_on_unit_button.bind(unit["name"]))

func get_producible_units(building_name: String) -> Array:
	match building_name:
		"Barracks":
			return [{"name": "Infantry", "cost": 50}, {"name": "RocketSoldier", "cost": 100}]
		"Factory":
			return [{"name": "LightTank", "cost": 200}, {"name": "HeavyTank", "cost": 400}]
		"Airfield":
			return [{"name": "Helicopter", "cost": 300}]
		_:
			return []

func _on_unit_button(unit_type: String):
	unit_produced.emit(unit_type)
	visible = false

func close_panel():
	visible = false
	current_building = null
