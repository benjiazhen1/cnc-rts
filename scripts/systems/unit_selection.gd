## 单位选择系统
##
## 处理RTS游戏中的单位选择逻辑，包括：
## - 单击选择单位
## - 框选多个单位
## - Ctrl+点击追加/取消选择
## - 移动命令和攻击移动命令
## - Ctrl+A 全选当前类型单位
class_name UnitSelection
extends Node

# ==================== 常量 ====================

## 框选阈值：鼠标移动超过此距离视为框选，否则为单击
const SELECTION_CLICK_THRESHOLD: float = 5.0

## 单位点击检测半径
const UNIT_CLICK_RADIUS: float = 25.0

## 玩家所属标识
const PLAYER_OWNER: String = "player"

## 单位节点组名称
const UNITS_GROUP: String = "units"

## 移动状态标识
const STATE_MOVING: String = "moving"

## UI节点路径
const UI_NODE_PATH: String = "/root/Game/CanvasLayer/UI"

# ==================== 信号 ====================

## 单位选择变更信号
## [param unit_list]: 当前选中的单位列表
signal units_selected(unit_list: Array)

# ==================== 状态变量 ====================

## 当前选中的单位列表
var selected_units: Array[Unit] = []

## 选择框矩形区域
var selection_box: Rect2

## 是否正在框选
var is_selecting: bool = false

## 选择框起始位置
var selection_start: Vector2

## 是否处于攻击移动模式
var is_attack_move_mode: bool = false

# ==================== 输入处理 ====================

func _input(event: InputEvent) -> void:
	"""处理鼠标输入事件"""
	if not _is_valid_event(event):
		return

	var mouse_event := event as InputEventMouseButton
	if mouse_event == null:
		return

	_handle_mouse_button(mouse_event)


## 检查事件是否有效
func _is_valid_event(event: InputEvent) -> bool:
	"""验证输入事件是否为有效的事件对象"""
	if event == null:
		push_error("UnitSelection: 收到无效的输入事件")
		return false
	return true


## 处理鼠标按钮事件
func _handle_mouse_button(event: InputEventMouseButton) -> void:
	"""根据鼠标按钮类型分发处理"""
	match event.button_index:
		MOUSE_BUTTON_LEFT:
			_handle_left_click(event)
		MOUSE_BUTTON_RIGHT:
			_handle_right_click(event)


## 处理左键点击
func _handle_left_click(event: InputEventMouseButton) -> void:
	"""左键按下开始选择，松开结束选择"""
	if event.pressed:
		start_selection(event.position)
	else:
		end_selection(event.position)


## 处理右键点击
func _handle_right_click(event: InputEventMouseButton) -> void:
	"""右键按下时根据当前模式发送移动或攻击移动命令"""
	if not event.pressed:
		return

	if is_attack_move_mode:
		issue_attack_move_command(event.position)
	else:
		issue_move_command(event.position)

# ==================== 选择逻辑 ====================

## 开始选择流程
func start_selection(pos: Vector2) -> void:
	"""记录选择起始点，清除现有选择（点击空白区域时）"""
	is_selecting = true
	selection_start = pos

	# 点击空白处时清除之前的选择
	if not event_is_on_ui(pos):
		clear_selection()


## 结束选择流程
func end_selection(pos: Vector2) -> void:
	"""根据选择方式（单击/框选）处理单位选择"""
	is_selecting = false

	# 判断是单击还是框选
	if selection_start.distance_to(pos) < SELECTION_CLICK_THRESHOLD:
		_handle_click_selection(pos)
	else:
		_handle_box_selection(pos)

	units_selected.emit(selected_units)


## 处理单击选择
func _handle_click_selection(pos: Vector2) -> void:
	"""处理单击选择逻辑：选中单个单位，支持Ctrl追加"""
	var clicked_unit := get_unit_at_position(pos)

	# 检查单位是否存在且属于玩家
	if clicked_unit == null:
		push_warning("UnitSelection: 点击位置无有效单位")
		return

	if clicked_unit.owner != PLAYER_OWNER:
		return

	# Ctrl+点击：追加选择
	if Input.is_key_pressed(KEY_CTRL):
		if not _add_unit_to_selection(clicked_unit):
			push_warning("UnitSelection: 单位已在选中列表中")
	else:
		# 普通点击：清除旧选择并选中新单位
		clear_selection()
		_add_unit_to_selection(clicked_unit)


## 处理框选
func _handle_box_selection(pos: Vector2) -> void:
	"""处理框选逻辑：Ctrl+框选追加，否则替换"""
	if not Input.is_key_pressed(KEY_CTRL):
		clear_selection()

	box_select_units(selection_start, pos)


## 将单位添加到选中列表
func _add_unit_to_selection(unit: Unit) -> bool:
	"""将单位添加到选中列表，成功返回true"""
	if unit == null:
		push_error("UnitSelection: 尝试添加空单位到选择列表")
		return false

	if not unit in selected_units:
		selected_units.append(unit)
		unit.select()
		return true
	return false


## 框选单位
func box_select_units(start: Vector2, end: Vector2) -> void:
	"""根据起始点和终点确定的选择框选取其中的所有玩家单位"""
	var rect := _create_normalized_rect(start, end)

	var units := get_tree().get_nodes_in_group(UNITS_GROUP)
	for unit in units:
		# 只选择属于玩家的单位
		if unit.owner != PLAYER_OWNER:
			continue

		# 检查单位中心点是否在选择框内
		if rect.has_point(unit.global_position):
			_add_unit_to_selection(unit)


## 创建标准化矩形（处理负尺寸）
func _create_normalized_rect(start: Vector2, end: Vector2) -> Rect2:
	"""创建矩形并确保宽高为正数"""
	var rect := Rect2(start, end - start)

	if rect.size.x < 0:
		rect.position.x += rect.size.x
		rect.size.x = -rect.size.x

	if rect.size.y < 0:
		rect.position.y += rect.size.y
		rect.size.y = -rect.size.y

	return rect


## 获取指定位置的单位
func get_unit_at_position(pos: Vector2) -> Unit:
	"""返回指定位置半径范围内的第一个玩家单位，无则返回null"""
	var units := get_tree().get_nodes_in_group(UNITS_GROUP)

	for unit in units:
		# 距离检测：单位是否在点击范围内
		if unit.global_position.distance_to(pos) < UNIT_CLICK_RADIUS:
			return unit

	return null

# ==================== 命令执行 ====================

## 向选中单位发送移动命令
func issue_move_command(pos: Vector2) -> void:
	"""命令所有选中单位停止当前动作并移动到目标位置"""
	for unit in selected_units:
		if unit == null:
			push_warning("UnitSelection: 选中列表包含空单位引用")
			continue

		unit.stop()
		unit.move_to(pos)


## 向选中单位发送攻击移动命令
func issue_attack_move_command(pos: Vector2) -> void:
	"""命令所有选中单位移动，途中遇到敌人会自动攻击"""
	for unit in selected_units:
		if unit == null:
			push_warning("UnitSelection: 选中列表包含空单位引用")
			continue

		unit.target_position = pos
		unit.state = unit.UnitState.MOVING

# ==================== 选择管理 ====================

## 清除所有当前选择
func clear_selection() -> void:
	"""取消所有选中单位的选中状态并清空列表"""
	for unit in selected_units:
		if unit != null and is_instance_valid(unit):
			unit.deselect()
		else:
			push_warning("UnitSelection: 跳过无效单位的取消选择")

	selected_units.clear()


## 选择所有指定类型的玩家单位
func select_all_of_type(unit_type: String) -> void:
	"""选中所有指定类型的玩家单位（不清除现有选择，追加模式）"""
	if unit_type == "":
		push_error("UnitSelection: unit_type不能为空字符串")
		return

	var units := get_tree().get_nodes_in_group(UNITS_GROUP)
	for unit in units:
		if unit.owner == PLAYER_OWNER and unit.unit_name == unit_type:
			_add_unit_to_selection(unit)


## 切换攻击移动模式
func toggle_attack_move_mode() -> void:
	"""切换攻击移动模式的开关状态"""
	is_attack_move_mode = not is_attack_move_mode
	print("Attack-Move模式: ", "开启" if is_attack_move_mode else "关闭")


## 检查点击位置是否在UI上
func event_is_on_ui(pos: Vector2) -> bool:
	"""检测点击坐标是否落在UI区域范围内"""
	var ui := get_node_or_null(UI_NODE_PATH)

	if ui == null:
		# UI节点不存在，假定点击不在UI上（允许选择）
		return false

	if not is_instance_valid(ui):
		push_warning("UnitSelection: UI节点已失效")
		return false

	var ui_rect := ui.get_global_rect()
	return ui_rect.has_point(pos)
