extends WeaponMain

var ads_speed : int = 10
var is_ads : bool = false
var is_reloading : bool = false

func fire():
	pass
	
func reload():
	pass

func sway(mouse_input,delta):
	pass

func weapon_regime(value, delta) -> int:
	is_ads = value
	
	if  is_ads == false and player.camera.fov == default_fov:
		return BASE
	
	if is_ads:
		player.camera.fov = lerp(player.camera.fov, default_fov / 2, ads_speed * delta)
		return ADS
	else:
		player.camera.fov = lerp(player.camera.fov, default_fov, ads_speed * delta)
		return BASE
	
