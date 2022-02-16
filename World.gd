extends Node

var init_compile_wait : int = 0
signal canStart

func _ready():
	connect("canStart", get_node("Player/HUD"), "hide_loading_screen")
	get_tree().paused = true

func all_loaded():
	init_compile_wait += 1
	# Две камеры, ждем два сигнала
	if init_compile_wait == 2:
		get_tree().paused = false
		emit_signal("canStart")
		disconnect("canStart", get_node("Player/HUD"), "hide_loading_screen")
