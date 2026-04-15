# 建造菜单UI
extends Control

signal building_selected(building_type: String)
signal closed()

@onready var building_buttons: Array = []

func _ready():
	visible = false
	setup_buttons()

func setup_buttons():
	# 建筑按钮配置
	var buildings = [
		{"name": "Power Plant", "cost": 300, "desc": "提供电力"},
		{"name": "Barracks", "cost": 500, "desc": "生产步兵"},
		{"name": "Factory", "cost": 800, "desc": "生产坦克"},
		{"name": "Airfield", "cost": 1000, "desc": "生产直升机"}
	]
	
	var vbox = $PanelContainer/VBoxContainer
	
	for i in range(buildings.size()):
		var btn = Button.new()
		btn.text = "%s - %d矿" % [buildings[i]["name"], buildings[i]["cost"]]
		btn.custom_minimum_size = Vector2(200, 40)
		vbox.add_child(btn)
		btn.pressed.connect(_on_building_button.bind(buildings[i]["name"]))
		building_buttons.append(btn)

func _on_building_button(building_type: String):
	building_selected.emit(building_type)
	close_menu()

func open_menu():
	visible = true

func close_menu():
	visible = false
	closed.emit()

func _input(event):
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		close_menu()
