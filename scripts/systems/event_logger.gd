## 事件日志系统
##
## 负责记录和展示游戏中的各类事件，包括单位创建、建筑放置、
## 战斗事件、资源变化等。支持事件历史存储和日志导出功能。
##
## **支持的事件类型：**
## - 单位相关：单位创建、單位销毁
## - 建筑相关：建筑建造、建筑销毁
## - 战斗相关：攻击、击杀、死亡
## - 资源相关：资源获取、资源消耗
## - 游戏相关：游戏暂停、游戏恢复、游戏结束
class_name EventLogger
extends Node

# ==================== 日志常量 ====================
## 最大保存事件数量
const MAX_EVENT_HISTORY: int = 100
## UI更新时间间隔（秒）
const UI_UPDATE_INTERVAL: float = 0.5
## 默认日志级别
const LOG_LEVEL_DEBUG: int = 0
const LOG_LEVEL_INFO: int = 1
const LOG_LEVEL_WARNING: int = 2
const LOG_LEVEL_ERROR: int = 3

# ==================== 事件类型常量 ====================
## 单位创建事件
const EVENT_UNIT_CREATED: String = "unit_created"
## 单位销毁事件
const EVENT_UNIT_DESTROYED: String = "unit_destroyed"
## 建筑建造开始事件
const EVENT_BUILDING_STARTED: String = "building_started"
## 建筑建造完成事件
const EVENT_BUILDING_COMPLETED: String = "building_completed"
## 建筑销毁事件
const EVENT_BUILDING_DESTROYED: String = "building_destroyed"
## 攻击事件
const EVENT_COMBAT_ATTACK: String = "combat_attack"
## 击杀事件
const EVENT_COMBAT_KILL: String = "combat_kill"
## 单位死亡事件
const EVENT_UNIT_DEATH: String = "unit_death"
## 资源获取事件
const EVENT_RESOURCE_GAINED: String = "resource_gained"
## 资源消耗事件
const EVENT_RESOURCE_SPENT: String = "resource_spent"
## 游戏暂停事件
const EVENT_GAME_PAUSED: String = "game_paused"
## 游戏恢复事件
const EVENT_GAME_RESUMED: String = "game_resumed"
## 游戏结束事件
const EVENT_GAME_OVER: String = "game_over"

# ==================== 节点路径 ====================
const UI_NODE_PATH: String = "/root/Game/UI"
const EVENT_PANEL_PATH: String = "/root/Game/UI/EventLogPanel"

# ==================== 信号定义 ====================
## 新事件被记录时触发
## [param event_type] 事件类型
## [param event_data] 事件数据字典
signal event_logged(event_type: String, event_data: Dictionary)

## 事件历史已满，需要清理旧事件时触发
## [param removed_count] 被移除的事件数量
signal event_history_full(removed_count: int)

# ==================== 内部状态变量 ====================
## 事件历史记录列表
var event_history: Array[Dictionary] = []
## 当前日志级别
var current_log_level: int = LOG_LEVEL_INFO
## UI更新计时器
var ui_update_timer: float = 0.0
## UI引用
var ui_node: CanvasLayer
## 事件面板引用
var event_panel: Panel
## 事件列表Label引用
var event_list_label: Label
## 导出文件路径
var export_file_path: String = "user://event_log.json"

# ==================== 生命周期 ====================

func _ready() -> void:
	"""初始化事件日志系统，获取UI节点引用。"""
	_initialize_ui_nodes()


func _process(delta: float) -> void:
	"""定期更新UI显示。"""
	ui_update_timer += delta
	if ui_update_timer >= UI_UPDATE_INTERVAL:
		_update_ui_display()
		ui_update_timer = 0.0


# ==================== 初始化方法 ====================

func _initialize_ui_nodes() -> void:
	"""获取UI相关节点的引用。"""
	ui_node = get_node_or_null(UI_NODE_PATH) as CanvasLayer
	if ui_node == null:
		push_warning("EventLogger: UI节点未找到 at %s" % UI_NODE_PATH)

	event_panel = get_node_or_null(EVENT_PANEL_PATH) as Panel
	if event_panel == null:
		push_warning("EventLogger: 事件面板未找到 at %s，UI显示将禁用" % EVENT_PANEL_PATH)

	if event_panel != null:
		event_list_label = event_panel.get_node_or_null("EventList") as Label
		if event_list_label == null:
			push_warning("EventLogger: 事件列表Label未找到，UI显示将禁用")


# ==================== 公共方法：事件记录 ====================

## 记录单位创建事件
##
## [param unit_name] 单位类型名称
## [param owner] 单位所属玩家（"player" 或 "ai"）
## [param position] 单位位置
func log_unit_created(unit_name: String, owner: String, position: Vector2) -> void:
	var event_data: Dictionary = {
		"unit_name": unit_name,
		"owner": owner,
		"position": {"x": position.x, "y": position.y},
		"description": "单位创建: %s (%s)" % [unit_name, owner]
	}
	_add_event(EVENT_UNIT_CREATED, event_data)


## 记录单位销毁事件
##
## [param unit_name] 单位类型名称
## [param owner] 单位所属玩家
## [param killer] 击杀者（可为null）
func log_unit_destroyed(unit_name: String, owner: String, killer: String = "") -> void:
	var event_data: Dictionary = {
		"unit_name": unit_name,
		"owner": owner,
		"killer": killer,
		"description": "单位销毁: %s (%s)" % [unit_name, owner]
	}
	_add_event(EVENT_UNIT_DESTROYED, event_data)


## 记录建筑建造开始事件
##
## [param building_name] 建筑类型名称
## [param owner] 建筑所属玩家
## [param position] 建筑位置
## [param build_time] 预计建造时间（秒）
func log_building_started(building_name: String, owner: String, position: Vector2, build_time: float) -> void:
	var event_data: Dictionary = {
		"building_name": building_name,
		"owner": owner,
		"position": {"x": position.x, "y": position.y},
		"build_time": build_time,
		"description": "开始建造: %s (%s)" % [building_name, owner]
	}
	_add_event(EVENT_BUILDING_STARTED, event_data)


## 记录建筑建造完成事件
##
## [param building_name] 建筑类型名称
## [param owner] 建筑所属玩家
## [param position] 建筑位置
func log_building_completed(building_name: String, owner: String, position: Vector2) -> void:
	var event_data: Dictionary = {
		"building_name": building_name,
		"owner": owner,
		"position": {"x": position.x, "y": position.y},
		"description": "建筑完成: %s (%s)" % [building_name, owner]
	}
	_add_event(EVENT_BUILDING_COMPLETED, event_data)


## 记录建筑销毁事件
##
## [param building_name] 建筑类型名称
## [param owner] 建筑所属玩家
## [param killer] 摧毁者（可为null）
func log_building_destroyed(building_name: String, owner: String, killer: String = "") -> void:
	var event_data: Dictionary = {
		"building_name": building_name,
		"owner": owner,
		"killer": killer,
		"description": "建筑销毁: %s (%s)" % [building_name, owner]
	}
	_add_event(EVENT_BUILDING_DESTROYED, event_data)


## 记录战斗攻击事件
##
## [param attacker_name] 攻击方单位名称
## [param attacker_owner] 攻击方所属
## [param target_name] 目标单位名称
## [param target_owner] 目标所属
## [param damage] 造成的伤害值
## [param position] 攻击发生位置
func log_combat_attack(attacker_name: String, attacker_owner: String, target_name: String, target_owner: String, damage: int, position: Vector2) -> void:
	var event_data: Dictionary = {
		"attacker": attacker_name,
		"attacker_owner": attacker_owner,
		"target": target_name,
		"target_owner": target_owner,
		"damage": damage,
		"position": {"x": position.x, "y": position.y},
		"description": "攻击: %s -> %s (%d伤害)" % [attacker_name, target_name, damage]
	}
	_add_event(EVENT_COMBAT_ATTACK, event_data)


## 记录击杀事件
##
## [param killer_name] 击杀者单位名称
## [param killer_owner] 击杀者所属
## [param victim_name] 被击杀单位名称
## [param victim_owner] 被击杀者所属
func log_combat_kill(killer_name: String, killer_owner: String, victim_name: String, victim_owner: String) -> void:
	var event_data: Dictionary = {
		"killer": killer_name,
		"killer_owner": killer_owner,
		"victim": victim_name,
		"victim_owner": victim_owner,
		"description": "击杀: %s (%s) 击杀 %s (%s)" % [killer_name, killer_owner, victim_name, victim_owner]
	}
	_add_event(EVENT_COMBAT_KILL, event_data)


## 记录单位死亡事件
##
## [param unit_name] 死亡单位名称
## [param owner] 死亡单位所属
## [param cause] 死亡原因
func log_unit_death(unit_name: String, owner: String, cause: String = "战斗") -> void:
	var event_data: Dictionary = {
		"unit_name": unit_name,
		"owner": owner,
		"cause": cause,
		"description": "单位死亡: %s (%s) - %s" % [unit_name, owner, cause]
	}
	_add_event(EVENT_UNIT_DEATH, event_data)


## 记录资源获取事件
##
## [param amount] 获取的资源数量
## [param source] 资源来源
## [param new_balance] 获取后的余额
func log_resource_gained(amount: int, source: String, new_balance: int) -> void:
	var event_data: Dictionary = {
		"amount": amount,
		"source": source,
		"balance": new_balance,
		"description": "资源 +%d (%s)" % [amount, source]
	}
	_add_event(EVENT_RESOURCE_GAINED, event_data)


## 记录资源消耗事件
##
## [param amount] 消耗的资源数量
## [param purpose] 消耗用途
## [param new_balance] 消耗后的余额
func log_resource_spent(amount: int, purpose: String, new_balance: int) -> void:
	var event_data: Dictionary = {
		"amount": amount,
		"purpose": purpose,
		"balance": new_balance,
		"description": "资源 -%d (%s)" % [amount, purpose]
	}
	_add_event(EVENT_RESOURCE_SPENT, event_data)


## 记录游戏暂停事件
##
## [param paused_by] 暂停操作者（"player" 或 "system"）
func log_game_paused(paused_by: String = "player") -> void:
	var event_data: Dictionary = {
		"paused_by": paused_by,
		"description": "游戏暂停"
	}
	_add_event(EVENT_GAME_PAUSED, event_data)


## 记录游戏恢复事件
##
## [param resumed_by] 恢复操作者
func log_game_resumed(resumed_by: String = "player") -> void:
	var event_data: Dictionary = {
		"resumed_by": resumed_by,
		"description": "游戏恢复"
	}
	_add_event(EVENT_GAME_RESUMED, event_data)


## 记录游戏结束事件
##
## [param winner] 获胜方（"player", "ai", 或 "draw"）
## [param reason] 游戏结束原因
func log_game_over(winner: String, reason: String = "") -> void:
	var event_data: Dictionary = {
		"winner": winner,
		"reason": reason,
		"description": "游戏结束: %s 获胜" % winner
	}
	_add_event(EVENT_GAME_OVER, event_data)


## 记录通用信息事件
##
## [param message] 日志消息
## [param level] 日志级别（默认INFO）
func log_message(message: String, level: int = LOG_LEVEL_INFO) -> void:
	if level < current_log_level:
		return

	var event_data: Dictionary = {
		"message": message,
		"level": level,
		"description": message
	}
	_add_event("generic_message", event_data)


# ==================== 公共方法：历史查询 ====================

## 获取事件历史记录
##
## [param count] 获取的事件数量，-1表示全部
## [param event_type] 可选的事件类型过滤
## [return] 事件列表
func get_event_history(count: int = -1, event_type: String = "") -> Array[Dictionary]:
	if event_type.is_empty():
		if count < 0 or count >= event_history.size():
			return event_history.duplicate(true)
		else:
			return event_history.slice(-count)
	else:
		var filtered: Array[Dictionary] = []
		for e in event_history:
			if e.get("type") == event_type:
				filtered.append(e)
		if count < 0 or count >= filtered.size():
			return filtered
		else:
			return filtered.slice(-count)


## 获取最近的事件
##
## [param count] 获取的事件数量
## [return] 最近的事件列表
func get_recent_events(count: int = 10) -> Array[Dictionary]:
	return get_event_history(count)


## 获取事件统计信息
##
## [return] 包含各类型事件数量的字典
func get_event_statistics() -> Dictionary:
	var stats: Dictionary = {}
	for event in event_history:
		var event_type: String = event.get("type", "unknown")
		stats[event_type] = stats.get(event_type, 0) + 1
	return stats


## 按事件类型过滤事件
##
## [param event_type] 事件类型
## [return] 该类型的所有事件
func get_events_by_type(event_type: String) -> Array[Dictionary]:
	return get_event_history(-1, event_type)


## 清除所有事件历史
func clear_history() -> void:
	event_history.clear()


# ==================== 公共方法：导出功能 ====================

## 导出事件日志到文件
##
## [param file_path] 导出文件路径，默认为 export_file_path
## [return] 导出是否成功
func export_to_file(file_path: String = "") -> bool:
	if file_path.is_empty():
		file_path = export_file_path

	var data: Dictionary = {
		"export_time": Time.get_datetime_string_from_system(),
		"event_count": event_history.size(),
		"events": event_history
	}

	var json_string: String = JSON.stringify(data, "\t")

	var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		push_error("EventLogger: 导出失败 - %s" % FileAccess.get_open_error())
		return false

	file.store_string(json_string)
	file.close()

	print("EventLogger: 已导出 %d 条事件到 %s" % [event_history.size(), file_path])
	return true


## 导出为可读文本格式
##
## [param file_path] 导出文件路径
## [return] 导出是否成功
func export_to_text_file(file_path: String = "") -> bool:
	if file_path.is_empty():
		file_path = export_file_path.replace(".json", ".txt")

	var text: String = "事件日志导出 - %s\n" % Time.get_datetime_string_from_system()
	text += "=" .repeat(50) + "\n\n"

	for event in event_history:
		var timestamp: float = event.get("timestamp", 0.0)
		var event_type: String = event.get("type", "unknown")
		var description: String = event.get("description", "")
		text += "[%.2f] %s: %s\n" % [timestamp, event_type, description]

	var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		push_error("EventLogger: 文本导出失败 - %s" % FileAccess.get_open_error())
		return false

	file.store_string(text)
	file.close()

	print("EventLogger: 已导出文本日志到 %s" % file_path)
	return true


## 获取导出数据（用于调试）
##
## [return] 包含所有事件数据的字典
func get_export_data() -> Dictionary:
	return {
		"export_time": Time.get_datetime_string_from_system(),
		"event_count": event_history.size(),
		"events": event_history,
		"statistics": get_event_statistics()
	}


# ==================== 公共方法：UI控制 ====================

## 设置UI面板可见性
##
## [param visible] 是否显示
func set_ui_visible(visible: bool) -> void:
	if event_panel != null:
		event_panel.visible = visible


## 获取UI面板当前可见性
##
## [return] UI面板是否可见
func is_ui_visible() -> bool:
	return event_panel != null and event_panel.visible


## 更新UI显示
func update_ui() -> void:
	_update_ui_display()


# ==================== 公共方法：日志级别控制 ====================

## 设置日志级别
##
## [param level] 日志级别
func set_log_level(level: int) -> void:
	current_log_level = level


## 获取当前日志级别
##
## [return] 当前日志级别
func get_log_level() -> int:
	return current_log_level


# ==================== 私有方法 ====================

func _add_event(event_type: String, event_data: Dictionary) -> void:
	"""添加事件到历史记录。"""
	var full_event: Dictionary = {
		"type": event_type,
		"timestamp": Time.get_ticks_msec() / 1000.0,
		"data": event_data
	}

	# 合并data到顶层（方便查看）
	for key in event_data:
		full_event[key] = event_data[key]

	event_history.append(full_event)

	# 检查是否超过最大数量
	if event_history.size() > MAX_EVENT_HISTORY:
		var removed_count: int = event_history.size() - MAX_EVENT_HISTORY
		for i in removed_count:
			event_history.pop_front()
		event_history_full.emit(removed_count)

	event_logged.emit(event_type, event_data)
	_update_ui_display()


func _update_ui_display() -> void:
	"""更新UI显示最近的事件。"""
	if event_list_label == null or event_panel == null:
		return

	if not event_panel.visible:
		return

	# 显示最近的事件（最多显示最近10条）
	var recent_events: Array[Dictionary] = get_recent_events(10)
	var display_text: String = ""

	for event in recent_events:
		var description: String = event.get("description", "")
		var timestamp: float = event.get("timestamp", 0.0)
		display_text += "[%.1f] %s\n" % [timestamp, description]

	if display_text.is_empty():
		display_text = "暂无事件记录"

	event_list_label.text = display_text


# ==================== 单例访问 ====================

## 获取事件日志单例实例
##
## 用于从其他脚本快速访问事件日志系统。
## [return] EventLogger单例实例
static func get_instance() -> EventLogger:
	var instance: EventLogger = Engine.get_main_loop().root.get_node_or_null("EventLogger")
	if instance == null:
		push_error("EventLogger: 单例实例未找到，请确保EventLogger已添加到场景")
	return instance
