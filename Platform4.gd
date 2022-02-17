extends KinematicBody


#func _physics_process(delta):
	#move_and_collide(Vector3.LEFT*delta)


func _on_Area_body_entered(body):
	if body.get_name() == "Player":
		body.not_on_moving_platform = false


func _on_Area_body_exited(body):
	if body.get_name() == "Player":
		body.not_on_moving_platform = true
