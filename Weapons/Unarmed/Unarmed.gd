extends WeaponMain

var ads_speed : int = 10
var is_ads : bool = false
var is_reloading : bool = false

func fire():
	pass
	
func fire_stop():
	pass
	
func reload():
	pass

func aim_down_sights(value, delta):
	is_ads = value
	
	if  is_ads == false and player.camera.fov == default_fov:
		return
	
	if is_ads:
		player.camera.fov = lerp(player.camera.fov, default_fov / 2, ads_speed * delta)
	else:
		player.camera.fov = lerp(player.camera.fov, default_fov, ads_speed * delta)
