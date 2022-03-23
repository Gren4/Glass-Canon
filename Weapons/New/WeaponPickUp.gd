extends RigidBody

export(String) var weapon_name : String = "Weapon"

func _ready():
	connect("sleeping_state_changed", self, "on_sleeping")

func get_weapon_pickup_data():
	return weapon_name

func on_sleeping():
	mode = MODE_STATIC


func _on_Area_body_entered(body):
	if body.get_name() == "Player":
		body.interactable_items_count += 1


func _on_Area_body_exited(body):
	if body.get_name() == "Player":
		body.interactable_items_count -= 1
