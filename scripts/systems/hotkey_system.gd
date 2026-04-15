# 快捷键系统
extends Node

signal build_command(building_type: String)
signal production_command(unit_type: String)

func _input(event):
	if not event is InputEventKey or not event.pressed:
		return
	
	match event.keycode:
		KEY_Q:
			build_command.emit("Power Plant")
		KEY_W:
			build_command.emit("Barracks")
		KEY_E:
			build_command.emit("Factory")
		KEY_R:
			build_command.emit("Airfield")
		KEY_1:
			production_command.emit("Infantry")
		KEY_2:
			production_command.emit("LightTank")
		KEY_3:
			production_command.emit("HeavyTank")
		KEY_SPACE:
			# 暂停/继续
			var gs = get_node("/root/GameState")
			if gs.is_paused:
				gs.resume_game()
			else:
				gs.pause_game()
