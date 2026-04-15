extends Control

signal play_again_pressed
signal return_to_menu_pressed

enum Outcome {VICTORY, DEFEAT}

var game_outcome: Outcome = Outcome.VICTORY
var stats_units_built: int = 0
var stats_buildings_constructed: int = 0
var stats_time_elapsed: float = 0.0

func _ready():
	_update_outcome_display()
	_update_stats_display()
	$CenterContainer/VBoxContainer/PlayAgainButton.grab_focus()

func setup(outcome: Outcome, units_built: int, buildings_constructed: int, time_elapsed: float):
	game_outcome = outcome
	stats_units_built = units_built
	stats_buildings_constructed = buildings_constructed
	stats_time_elapsed = time_elapsed
	_update_outcome_display()
	_update_stats_display()

func _update_outcome_display():
	var outcome_label = $CenterContainer/VBoxContainer/OutcomeLabel
	if game_outcome == Outcome.VICTORY:
		outcome_label.text = "Victory!"
		outcome_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2, 1))
	else:
		outcome_label.text = "Defeat!"
		outcome_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2, 1))

func _update_stats_display():
	var time_minutes = int(stats_time_elapsed) / 60
	var time_seconds = int(stats_time_elapsed) % 60
	$CenterContainer/VBoxContainer/StatsContainer/UnitsLabel.text = "Units Built: %d" % stats_units_built
	$CenterContainer/VBoxContainer/StatsContainer/BuildingsLabel.text = "Buildings Constructed: %d" % stats_buildings_constructed
	$CenterContainer/VBoxContainer/StatsContainer/TimeLabel.text = "Time: %d:%02d" % [time_minutes, time_seconds]

func _on_play_again_button_pressed():
	play_again_pressed.emit()
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_return_to_menu_button_pressed():
	return_to_menu_pressed.emit()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")