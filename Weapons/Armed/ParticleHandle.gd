extends Particles
class_name ParticleHandle

func free_scene(delta):
	#Удаляем частицы, которые заспавинили в основной ноде
	if get_parent().name == "World":
		if not emitting:
			queue_free()
	else:
		set_process(false)
