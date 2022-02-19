extends RigidBody

export(String) var weapon_name : String = "Weapon"
export(int) var ammo_in_mag : int = 5
export(int) var extra_ammo : int = 10
onready var mag_size : int = ammo_in_mag

func _ready():
	connect("sleeping_state_changed", self, "on_sleeping")

func get_weapon_pickup_data():
	return {
		"Name" : weapon_name,
		"Ammo" : ammo_in_mag,
		"ExtraAmmo" : extra_ammo,
		"MagSize" : mag_size
	}

func on_sleeping():
	mode = MODE_STATIC


func _on_Area_body_entered(body):
	if body.get_name() == "Player":
		body.interactable_items_count += 1


func _on_Area_body_exited(body):
	if body.get_name() == "Player":
		body.interactable_items_count -= 1
