extends Area

export(int) var ammo = 10
export(String) var weapon_name = "Weapon"

func _on_AmmoPickup_body_entered(body):
	if body.name == "Player":
		var result = body.weapon_manager.add_ammo(weapon_name, ammo)
		if result: 
			queue_free()		
