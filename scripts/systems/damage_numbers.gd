# 伤害数字系统
extends CanvasLayer

var active_labels: Array = []

func _process(delta):
	var to_remove = []
	
	for data in active_labels:
		var label = data["label"]
		var age = data["age"]
		var lifetime = data["lifetime"]
		
		age += delta
		data["age"] = age
		
		# 向上飘动
		label.position.y -= 50 * delta
		label.modulate.a = 1.0 - (age / lifetime)
		
		if age >= lifetime:
			label.queue_free()
			to_remove.append(data)
	
	for data in to_remove:
		active_labels.erase(data)

func show_damage(damage: int, world_pos: Vector2):
	var camera = get_tree().get_first_node_in_group("camera")
	if camera:
		var screen_pos = camera.unproject_position(world_pos)
	else:
		screen_pos = world_pos
	
	var label = Label.new()
	label.text = "-%d" % damage
	label.position = screen_pos
	label.modulate = Color(1, 0.2, 0.2, 1)
	add_child(label)
	
	active_labels.append({
		"label": label,
		"age": 0.0,
		"lifetime": 0.8
	})
