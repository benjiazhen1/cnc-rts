# 游戏UI
extends CanvasLayer

@onready var credits_label: Label = $CreditsPanel/CreditsLabel
@onready var build_menu: Panel = $BuildMenu
@onready var unit_info: Panel = $UnitInfo

var game_state_path = "/root/.openclaw/workspace/cnc-rts/scripts/game_state.gd"

func _ready():
	build_menu.visible = false
	unit_info.visible = false
	update_credits_display()

func _process(delta):
	update_credits_display()

func update_credits_display():
	var gs = get_node("/root/GameState")
	credits_label.text = "Credits: %d" % gs.credits

func show_build_menu(building_type: String):
	build_menu.visible = true
	# 根据建筑类型显示可生产单位

func hide_build_menu():
	build_menu.visible = false

func show_unit_info(unit: Unit):
	unit_info.visible = true
	$UnitInfo/UnitName.text = unit.unit_name
	$UnitInfo/HealthBar.value = (unit.current_health / unit.max_health) * 100

func hide_unit_info():
	unit_info.visible = false
