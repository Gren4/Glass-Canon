extends TextureRect
#var player
#var degree : float
func _ready():
	pass
	
func _process(delta):
	#rect_rotation = degree - player.rotation_degrees.y
	modulate.a -= 5*delta
	
	if modulate.a <= 0.0:
		queue_free()
