# 战斗反馈UI
extends CanvasLayer

var damage_labels: Array = []

func show_damage(damage: int, world_pos: Vector2):
	var label = Label.new()
	label.text = "-%d" % damage
	label.global_position = world_pos
	label.modulate = Color(1, 0.3, 0.3)  # 红色
	label.add_theme_font_size_override("font_size", 16)
	add_child(label)
	
	# 向上飘动动画
	var tween = create_tween()
	tween.tween_property(label, "position:y", label.position.y - 50, 0.8)
	tween.tween_callback(label.queue_free)
	
	damage_labels.append(label)

func show_attack_indicator(from_pos: Vector2, to_pos: Vector2):
	# 简单用Line2D显示攻击线
	var line = Line2D.new()
	line.points = [from_pos, to_pos]
	line.default_color = Color(1, 0.5, 0, 0.8)
	line.width = 2
	add_child(line)
	
	await get_tree().create_timer(0.1).timeout
	if line:
		line.queue_free()

func show_unit_health_change(unit: Unit, old_health: int, new_health: int):
	var damage = old_health - new_health
	if damage > 0:
		show_damage(damage, unit.global_position)
