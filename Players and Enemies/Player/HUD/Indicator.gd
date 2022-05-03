extends TextureRect

func _ready() -> void:
	pass
	
func _process(delta : float) -> void:
	modulate.a -= 5*delta
	
	if modulate.a <= 0.0:
		queue_free()
