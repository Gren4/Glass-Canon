extends Spatial
class_name WeaponMain

var weapon_manager = null
var player = null
var ray = null
var default_fov : int = 90
enum { 
	BASE, 
	ALT,
	ADS
	}

var is_equipped : bool = false

export(String) var weapon_name : String = "Weapon"
export(Texture) var weapon_image = null
	
func fire():
	pass
	
func fire_stop():
	pass
	
func is_switching_active():
	pass

func equip() -> void:
	pass
	
func unequip() -> void:
	pass
	
func is_equip_finished() -> bool:
	return true
		
func is_unequip_finished() -> bool:
	return true
	
func climb():
	pass
	
func sway(mouse_input,delta):
	pass

func update_info():
	var weapon_data = {
		"Name" : weapon_name,
		"Image" : weapon_image
	}
	
	weapon_manager.update_hud(weapon_data)
