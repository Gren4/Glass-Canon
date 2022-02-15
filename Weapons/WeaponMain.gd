extends Spatial
class_name WeaponMain

var weapon_manager = null
var player = null
var ray = null

var is_equipped : bool = false

export var weapon_name = "Weapon"
export(Texture) var weapon_image = null

func is_weapon_automatic():
	pass

func equip() -> void:
	pass
	
func unequip() -> void:
	pass
	
func is_equip_finished() -> bool:
	return true
		
func is_unequip_finished() -> bool:
	return true
			
func update_ammo(action = "Refresh"):
	var weapon_data = {
		"Name" : weapon_name,
		"Image" : weapon_image
	}
	
	weapon_manager.update_hud(weapon_data)
