class_name SaveSystem
extends Node

## 存档系统
## 负责游戏状态的保存、加载和自动保存管理

# 常量
const SAVE_DIR := "user://saves/"
const SLOT_COUNT := 3
const AUTO_SAVE_SLOT := 0
const SAVE_FILE_NAME := "save_slot_{slot}.json"
const METADATA_FILE_NAME := "metadata_{slot}.json"
const AUTO_SAVE_INTERVAL := 300.0  # 自动保存间隔（秒）

# 信号
signal save_completed(slot: int, success: bool)
signal load_completed(slot: int, success: bool)
signal auto_save_triggered()
signal auto_save_disabled()

# 私有变量
var _auto_save_timer: Timer
var _current_slot: int = -1
var _auto_save_enabled: bool = true
var _save_in_progress: bool = false

# 元数据结构
class SaveMetadata:
	var slot: int
	var timestamp: int
	var play_time: float
	var scene_name: String
	var description: String

	func to_dict() -> Dictionary:
		return {
			"slot": slot,
			"timestamp": timestamp,
			"play_time": play_time,
			"scene_name": scene_name,
			"description": description
		}

	func from_dict(data: Dictionary) -> void:
		slot = data.get("slot", 0)
		timestamp = data.get("timestamp", 0)
		play_time = data.get("play_time", 0.0)
		scene_name = data.get("scene_name", "")
		description = data.get("description", "")


func _ready() -> void:
	_setup_auto_save()


func _setup_auto_save() -> void:
	_auto_save_timer = Timer.new()
	_auto_save_timer.wait_time = AUTO_SAVE_INTERVAL
	_auto_save_timer.timeout.connect(_on_auto_save_timeout)
	add_child(_auto_save_timer)
	_auto_save_timer.start()


func _on_auto_save_timeout() -> void:
	if _auto_save_enabled and not _save_in_progress:
		auto_save_triggered.emit()
		save_game(AUTO_SAVE_SLOT, "自动存档")


func _get_save_dir() -> String:
	return SAVE_DIR


func _get_save_path(slot: int) -> String:
	return _get_save_dir() + SAVE_FILE_NAME.format({"slot": slot})


func _get_metadata_path(slot: int) -> String:
	return _get_save_dir() + METADATA_FILE_NAME.format({"slot": slot})


func _ensure_save_dir() -> void:
	if not DirAccess.dir_exists_absolute(_get_save_dir()):
		DirAccess.make_dir_recursive_absolute(_get_save_dir())


func _get_game_state() -> Dictionary:
	## 获取当前游戏状态 - 可根据游戏需求扩展
	var state := {
		"version": "1.0.0",
		"timestamp": Time.get_unix_time_from_system(),
		"game_data": {}
	}

	# 存档玩家数据
	if has_node("/root/GameManager"):
		var game_manager = get_node("/root/GameManager")
		if game_manager.has_method("get_save_data"):
			state["game_data"]["game_manager"] = game_manager.get_save_data()

	# 存档单位管理器
	if has_node("/root/UnitManager"):
		var unit_manager = get_node("/root/UnitManager")
		if unit_manager.has_method("get_save_data"):
			state["game_data"]["unit_manager"] = unit_manager.get_save_data()

	# 存档建筑管理器
	if has_node("/root/BuildingManager"):
		var building_manager = get_node("/root/BuildingManager")
		if building_manager.has_method("get_save_data"):
			state["game_data"]["building_manager"] = building_manager.get_save_data()

	# 存档地图数据
	if has_node("/root/MapManager"):
		var map_manager = get_node("/root/MapManager")
		if map_manager.has_method("get_save_data"):
			state["game_data"]["map_manager"] = map_manager.get_save_data()

	# 存档当前场景
	state["scene"] = get_tree().current_scene.scene_file_path if get_tree().current_scene else ""

	return state


func _restore_game_state(state: Dictionary) -> bool:
	## 恢复游戏状态
	if not state.has("version") or not state.has("game_data"):
		push_error("存档数据格式无效")
		return false

	# 恢复玩家数据
	if has_node("/root/GameManager"):
		var game_manager = get_node("/root/GameManager")
		if game_manager.has_method("load_save_data") and state["game_data"].has("game_manager"):
			game_manager.load_save_data(state["game_data"]["game_manager"])

	# 恢复单位管理器
	if has_node("/root/UnitManager"):
		var unit_manager = get_node("/root/UnitManager")
		if unit_manager.has_method("load_save_data") and state["game_data"].has("unit_manager"):
			unit_manager.load_save_data(state["game_data"]["unit_manager"])

	# 恢复建筑管理器
	if has_node("/root/BuildingManager"):
		var building_manager = get_node("/root/BuildingManager")
		if building_manager.has_method("load_save_data") and state["game_data"].has("building_manager"):
			building_manager.load_save_data(state["game_data"]["building_manager"])

	# 恢复地图数据
	if has_node("/root/MapManager"):
		var map_manager = get_node("/root/MapManager")
		if map_manager.has_method("load_save_data") and state["game_data"].has("map_manager"):
			map_manager.load_save_data(state["game_data"]["map_manager"])

	# 加载场景
	if state.has("scene") and state["scene"]:
		await get_tree().change_scene_to_file(state["scene"])

	return true


## 保存游戏到指定槽位
func save_game(slot: int, description: String = "") -> bool:
	if _save_in_progress:
		push_warning("存档操作正在进行中")
		return false

	if slot < 0 or slot >= SLOT_COUNT:
		push_error("无效的存档槽位: %d" % slot)
		return false

	_save_in_progress = true
	_ensure_save_dir()

	var save_path := _get_save_path(slot)
	var metadata_path := _get_metadata_path(slot)
	var game_state := _get_game_state()

	# 保存游戏数据
	var save_file := FileAccess.open(save_path, FileAccess.WRITE)
	if save_file == null:
		push_error("无法创建存档文件: %s" % save_path)
		_save_in_progress = false
		save_completed.emit(slot, false)
		return false

	var json_string := JSON.stringify(game_state, "\t")
	save_file.store_string(json_string)
	save_file.close()

	# 保存元数据
	var metadata := SaveMetadata.new()
	metadata.slot = slot
	metadata.timestamp = Time.get_unix_time_from_system()
	metadata.play_time = _get_play_time()
	metadata.scene_name = get_tree().current_scene.name if get_tree().current_scene else ""
	metadata.description = description

	var metadata_file := FileAccess.open(metadata_path, FileAccess.WRITE)
	if metadata_file == null:
		push_error("无法创建元数据文件: %s" % metadata_path)
		_save_in_progress = false
		save_completed.emit(slot, false)
		return false

	var metadata_json := JSON.stringify(metadata.to_dict(), "\t")
	metadata_file.store_string(metadata_json)
	metadata_file.close()

	_current_slot = slot
	_save_in_progress = false
	save_completed.emit(slot, true)
	return true


## 从指定槽位加载游戏
func load_game(slot: int) -> bool:
	if _save_in_progress:
		push_warning("存档操作正在进行中")
		return false

	if slot < 0 or slot >= SLOT_COUNT:
		push_error("无效的存档槽位: %d" % slot)
		return false

	_save_in_progress = true
	var save_path := _get_save_path(slot)

	# 检查存档文件是否存在
	if not FileAccess.file_exists(save_path):
		push_error("存档文件不存在: %s" % save_path)
		_save_in_progress = false
		load_completed.emit(slot, false)
		return false

	# 加载游戏数据
	var save_file := FileAccess.open(save_path, FileAccess.READ)
	if save_file == null:
		push_error("无法打开存档文件: %s" % save_path)
		_save_in_progress = false
		load_completed.emit(slot, false)
		return false

	var json_string := save_file.get_as_text()
	save_file.close()

	var json := JSON.new()
	var parse_result := json.parse(json_string)
	if parse_result != OK:
		push_error("存档文件JSON解析失败: %s" % save_path)
		_save_in_progress = false
		load_completed.emit(slot, false)
		return false

	var game_state: Dictionary = json.get_data()
	if typeof(game_state) != TYPE_DICTIONARY:
		push_error("存档数据格式错误")
		_save_in_progress = false
		load_completed.emit(slot, false)
		return false

	# 恢复游戏状态
	var success := await _restore_game_state(game_state)

	_current_slot = slot
	_save_in_progress = false
	load_completed.emit(slot, success)
	return success


## 获取指定槽位的元数据
func get_slot_metadata(slot: int) -> SaveMetadata:
	if slot < 0 or slot >= SLOT_COUNT:
		return null

	var metadata_path := _get_metadata_path(slot)

	if not FileAccess.file_exists(metadata_path):
		return null

	var metadata_file := FileAccess.open(metadata_path, FileAccess.READ)
	if metadata_file == null:
		return null

	var json_string := metadata_file.get_as_text()
	metadata_file.close()

	var json := JSON.new()
	var parse_result := json.parse(json_string)
	if parse_result != OK:
		return null

	var data: Dictionary = json.get_data()
	if typeof(data) != TYPE_DICTIONARY:
		return null

	var metadata := SaveMetadata.new()
	metadata.from_dict(data)
	return metadata


## 获取所有槽位的元数据
func get_all_slots_metadata() -> Array[SaveMetadata]:
	var result: Array[SaveMetadata] = []
	for i in SLOT_COUNT:
		var metadata := get_slot_metadata(i)
		result.append(metadata)
	return result


## 检查指定槽位是否有存档
func has_save(slot: int) -> bool:
	if slot < 0 or slot >= SLOT_COUNT:
		return false
	return FileAccess.file_exists(_get_save_path(slot))


## 删除指定槽位的存档
func delete_save(slot: int) -> bool:
	if slot < 0 or slot >= SLOT_COUNT:
		return false

	var save_path := _get_save_path(slot)
	var metadata_path := _get_metadata_path(slot)

	var success := true

	if FileAccess.file_exists(save_path):
		var dir := DirAccess.open(_get_save_dir())
		if dir == null:
			success = false
		else:
			success = dir.remove(save_path) == OK

	if FileAccess.file_exists(metadata_path):
		var dir := DirAccess.open(_get_save_dir())
		if dir == null:
			success = false
		else:
			success = dir.remove(metadata_path) == OK

	return success


## 启用/禁用自动保存
func set_auto_save(enabled: bool) -> void:
	_auto_save_enabled = enabled
	if enabled:
		_auto_save_timer.start()
	else:
		_auto_save_timer.stop()
		auto_save_disabled.emit()


## 获取自动保存是否启用
func is_auto_save_enabled() -> bool:
	return _auto_save_enabled


## 获取当前已加载的存档槽位
func get_current_slot() -> int:
	return _current_slot


## 获取游戏总时长（需要与游戏管理器配合）
func _get_play_time() -> float:
	if has_node("/root/GameManager"):
		var game_manager = get_node("/root/GameManager")
		if game_manager.has_method("get_play_time"):
			return game_manager.get_play_time()
	return 0.0


## 执行快速保存（自动存档）
func quick_save() -> bool:
	return save_game(AUTO_SAVE_SLOT, "快速存档")


## 执行快速加载（从自动存档槽位加载）
func quick_load() -> bool:
	return load_game(AUTO_SAVE_SLOT)
