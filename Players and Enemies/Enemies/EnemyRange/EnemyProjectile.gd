extends RigidBody

var attack_damage : int = 20
var timer : float = 8
export(float) var speed_coef = 3.0
var parent : Object = null

func _ready():
	set_as_toplevel(true)
	
func _physics_process(delta):
	
	if timer <= 0:
		queue_free()
	else:
		timer -= delta

func _on_Area_body_entered(body):
	if body != parent:
		if body.is_in_group("Player"):
			body.update_health(-attack_damage)
			queue_free()
		elif body.is_in_group("Enemy"): 
			body.update_hp(attack_damage)
			queue_free()
		else:
			queue_free()
