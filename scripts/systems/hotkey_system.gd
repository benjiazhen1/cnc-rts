## 快捷键系统
## 处理游戏内快捷键输入,映射键盘事件到建筑/单位生产指令
extends Node

# 快捷键按键码常量
enum HotkeyKey {
	KEY_POWER_PLANT = KEY_Q,
	KEY_BARRACKS = KEY_W,
	KEY_FACTORY = KEY_E,
	KEY_AIRFIELD = KEY_R
}

enum ProductionKey {
	KEY_INFANTRY = KEY_1,
	KEY_LIGHT_TANK = KEY_2,
	KEY_HEAVY_TANK = KEY_3
}

# 建筑类型常量
enum BuildingType {
	POWER_PLANT = "Power Plant",
	BARRACKS = "Barracks",
	FACTORY = "Factory",
	AIRFIELD = "Airfield"
}

# 单位类型常量
enum UnitType {
	INFANTRY = "Infantry",
	LIGHT_TANK = "LightTank",
	HEAVY_TANK = "HeavyTank"
}

# 游戏状态节点路径
const GAME_STATE_PATH := "/root/GameState"

signal build_command(building_type: String)
signal production_command(unit_type: String)

## 处理输入事件
## 仅处理按键按下事件,忽略按键释放
func _input(event: InputEvent) -> void:
	if not _is_valid_key_event(event):
		return
	_handle_build_hotkeys(event)
	_handle_production_hotkeys(event)
	_handle_pause_hotkey(event)


## 检查事件是否为有效的按键按下
func _is_valid_key_event(event: InputEvent) -> bool:
	if event is InputEventKey:
		return event.pressed
	return false


## 处理建筑快捷键
## Q/W/E/R 分别对应 发电厂/兵营/工厂/机场
func _handle_build_hotkeys(event: InputEventKey) -> void:
	match event.keycode:
		HotkeyKey.KEY_POWER_PLANT:
			build_command.emit(BuildingType.POWER_PLANT)
		HotkeyKey.KEY_BARRACKS:
			build_command.emit(BuildingType.BARRACKS)
		HotkeyKey.KEY_FACTORY:
			build_command.emit(BuildingType.FACTORY)
		HotkeyKey.KEY_AIRFIELD:
			build_command.emit(BuildingType.AIRFIELD)


## 处理单位生产快捷键
## 1/2/3 分别对应 步兵/轻型坦克/重型坦克
func _handle_production_hotkeys(event: InputEventKey) -> void:
	match event.keycode:
		ProductionKey.KEY_INFANTRY:
			production_command.emit(UnitType.INFANTRY)
		ProductionKey.KEY_LIGHT_TANK:
			production_command.emit(UnitType.LIGHT_TANK)
		ProductionKey.KEY_HEAVY_TANK:
			production_command.emit(UnitType.HEAVY_TANK)


## 处理暂停快捷键
## 空格键切换游戏暂停/继续状态
func _handle_pause_hotkey(event: InputEventKey) -> void:
	if event.keycode != KEY_SPACE:
		return

	var game_state := _get_game_state_node()
	if game_state == null:
		return

	if game_state.is_paused:
		game_state.resume_game()
	else:
		game_state.pause_game()


## 获取游戏状态节点,带错误处理
func _get_game_state_node() -> Node:
	if not has_node(GAME_STATE_PATH):
		push_error("HotkeySystem: GameState node not found at path: " + GAME_STATE_PATH)
		return null

	var node := get_node(GAME_STATE_PATH)
	if not node.has_method("pause_game") or not node.has_method("resume_game"):
		push_error("HotkeySystem: GameState node missing pause_game/resume_game methods")
		return null

	return node
