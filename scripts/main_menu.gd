extends Control

signal start_game_pressed

func _ready():
	$CenterContainer/VBoxContainer/StartGameButton.grab_focus()

func _on_start_game_button_pressed():
	start_game_pressed.emit()
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_quit_button_pressed():
	get_tree().quit()