extends Particles

export(PackedScene) var my_instance

func _process(delta):
	#Удаляем частицы, которые заспавинили в основной ноде
	if get_parent().name == "World":
		if not emitting:
			queue_free()
	else:
		set_process(false)
