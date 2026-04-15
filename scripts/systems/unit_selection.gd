# 单位选择系统 - 增强版
extends Node

var selected_units: Array[Unit] = []
var selection_box: Rect2
var is_selecting: bool = false
var selection_start: Vector2

var is_attack_move_mode: bool = false

signal units_selected(unit_list: Array)

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				start_selection(event.position)
			else:
				end_selection(event.position)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				if is_attack_move_mode:
					issue_attack_move_command(event.position)
				else:
					issue_move_command(event.position)

func start_selection(pos: Vector2):
	is_selecting = true
	selection_start = pos
	# 清除之前的选择（如果点击空白处）
	if not event_is_on_ui(pos):
		clear_selection()

func end_selection(pos: Vector2):
	is_selecting = false
	
	if selection_start.distance_to(pos) < 5:
		# 单击选择
		var clicked_unit = get_unit_at_position(pos)
		if clicked_unit != null and clicked_unit.owner == "player":
			if Input.is_key_pressed(KEY_CTRL):
				# Ctrl+点击 = 追加选择
				if not clicked_unit in selected_units:
					selected_units.append(clicked_unit)
					clicked_unit.select()
			else:
				clear_selection()
				selected_units.append(clicked_unit)
				clicked_unit.select()
	else:
		# 框选
		if not Input.is_key_pressed(KEY_CTRL):
			clear_selection()
		box_select_units(selection_start, pos)
	
	units_selected.emit(selected_units)

func box_select_units(start: Vector2, end: Vector2):
	var rect = Rect2(start, end - start)
	if rect.size.x < 0:
		rect.position.x += rect.size.x
		rect.size.x = -rect.size.x
	if rect.size.y < 0:
		rect.position.y += rect.size.y
		rect.size.y = -rect.size.y
	
	var units = get_tree().get_nodes_in_group("units")
	for unit in units:
		if unit.owner == "player" and rect.has_point(unit.global_position):
			if not unit in selected_units:
				selected_units.append(unit)
				unit.select()

func get_unit_at_position(pos: Vector2) -> Unit:
	var units = get_tree().get_nodes_in_group("units")
	for unit in units:
		if unit.global_position.distance_to(pos) < 25:
			return unit
	return null

func issue_move_command(pos: Vector2):
	for unit in selected_units:
		unit.stop()
		unit.move_to(pos)

func issue_attack_move_command(pos: Vector2):
	# 攻击移动：移动过程中遇到敌人会自动攻击
	for unit in selected_units:
		unit.target_position = pos
		unit.state = unit.UnitState.MOVING

func clear_selection():
	for unit in selected_units:
		unit.deselect()
	selected_units.clear()

func select_all_of_type(unit_type: String):
	var units = get_tree().get_nodes_in_group("units")
	for unit in units:
		if unit.owner == "player" and unit.unit_name == unit_type:
			selected_units.append(unit)
			unit.select()

func toggle_attack_move_mode():
	is_attack_move_mode = not is_attack_move_mode
	print("Attack-Move模式: ", "开启" if is_attack_move_mode else "关闭")

func event_is_on_ui(pos: Vector2) -> bool:
	# 简单检测点击是否在UI上
	var ui = get_node_or_null("/root/Game/CanvasLayer/UI")
	if ui:
		var rect = ui.get_global_rect()
		return rect.has_point(pos)
	return false
