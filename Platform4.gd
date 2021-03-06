extends KinematicBody

var old_coord : Vector3 = Vector3.ZERO
var velocity : Vector3 = Vector3.ZERO

func _ready():
	set_physics_process(false)

func _physics_process(delta):
	velocity = (translation - old_coord) / delta
	old_coord = translation

func _on_Area_body_entered(body):
	if body.is_in_group("Player") or body.is_in_group("Enemy"):
		body.not_on_moving_platform = false
		set_physics_process(true)


func _on_Area_body_exited(body):
	if body.is_in_group("Player") or body.is_in_group("Enemy"):
		body.not_on_moving_platform = true
		body.dop_velocity = velocity / 8
		set_physics_process(false)
