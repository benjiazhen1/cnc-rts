extends Node2D

# C&C RTS - Main Game Script
# 基于EA开源C&C Remastered Collection源码学习

func _ready():
	print("C&C RTS - 致敬经典!")
	
	# 显示开始界面
	$CanvasLayer/StartMenu.visible = true

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			print("游戏暂停")
