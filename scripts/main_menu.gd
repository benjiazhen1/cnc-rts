# 主菜单
extends Control

signal start_new_game()
signal load_game()
signal quit_game()

func _ready():
	$VBoxContainer/NewGameButton.grab_focus()

func _on_new_game_button_pressed():
	start_new_game.emit()
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_load_game_button_pressed():
	load_game.emit()

func _on_quit_button_pressed():
	quit_game.emit()
	get_tree().quit()
