# 单位选择系统
extends Node

var selected_units: Array[Unit] = []
var selection_box: Rect2
var is_selecting: bool = false
var selection_start: Vector2

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
				issue_move_command(event.position)

func start_selection(pos: Vector2):
	is_selecting = true
	selection_start = pos
	selected_units.clear()

func end_selection(pos: Vector2):
	is_selecting = false
	
	if selection_start.distance_to(pos) < 5:
		# 单击选择
		var clicked_unit = get_unit_at_position(pos)
		if clicked_unit != null:
			selected_units.append(clicked_unit)
			clicked_unit.select()
	else:
		# 框选
		selection_box = Rect2(selection_start, pos - selection_start)
		box_select_units()
	
	units_selected.emit(selected_units)

func box_select_units():
	var units = get_tree().get_nodes_in_group("units")
	for unit in units:
		if unit.owner == "player" and selection_box.has_point(unit.global_position):
			selected_units.append(unit)
			unit.select()

func get_unit_at_position(pos: Vector2) -> Unit:
	var units = get_tree().get_nodes_in_group("units")
	for unit in units:
		if unit.global_position.distance_to(pos) < 20:
			return unit
	return null

func issue_move_command(pos: Vector2):
	for unit in selected_units:
		if unit.state == Unit.UnitState.ATTACKING:
			unit.stop()
		unit.move_to(pos)

func clear_selection():
	for unit in selected_units:
		unit.deselect()
	selected_units.clear()
