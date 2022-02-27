extends Armed

var spread : float = 10.0
export(float) var alt_fire_rate : float = 1.0
export(int) var  alt_damage : int = 5
var is_alt_active : bool = false

func _ready():
	animation_player = $AnimationPlayer
	animation_player.connect("animation_finished", self, "on_animation_finish")

func on_animation_finish(anim_name):
	match anim_name:
		"Unequip":
			is_equipped = false
		"Equip":
			is_equipped = true
		"Reload":
			is_reloading = false
			update_ammo("reload")
		"AltEquip","AltUnequip":
			is_switching_active = false
			


func weapon_regime(value, delta) -> int:
	is_ads = value
	
	if is_ads:
		if not is_alt_active and not is_reloading:
			animation_player.play("AltEquip",-1.0, 2.0)
			is_alt_active = true
			is_switching_active = true
			is_firing = false
			muzzle_flash.one_shot = true
		return ALT
	else:
		if is_alt_active and not is_reloading:
			animation_player.play("AltUnequip",-1.0, 2.0)
			is_alt_active = false
			is_switching_active = true
			is_firing = false
			muzzle_flash.one_shot = false
			ray.cast_to.x = 0
			ray.cast_to.y = 0
		return BASE
			
	
func fire():
	if not is_reloading:
		if ammo_in_mag > 0:
			if not is_firing:
				if is_automatic:
					is_firing = true
					if is_alt_active:
						animation_player.get_animation("AltFire").loop = true
					else:
						animation_player.get_animation("Fire").loop = true
				else:
					is_firing = false
					if animation_player.is_playing():
						animation_player.stop(true)
				if is_alt_active:
					animation_player.play("AltFire", -1.0, alt_fire_rate)
				else:
					animation_player.play("Fire", -1.0, fire_rate)
			return
		else:
			if is_firing:
				if is_automatic:
					fire_stop()
			reload()
			
func fire_stop():
	is_firing = false
	if is_automatic:
		if is_alt_active:
			animation_player.get_animation("AltFire").loop = false
		else:
			animation_player.get_animation("Fire").loop = false
		muzzle_flash.one_shot = true

func fire_spray():
	muzzle_flash.emitting = true
	var bullets : int = min(10,ammo_in_mag)
	update_ammo("consume",0, bullets)
	
	for i in bullets:
		ray.cast_to.x = rand_range(spread,-spread)
		ray.cast_to.y = rand_range(spread,-spread)
		ray.force_raycast_update()
		
		if ray.is_colliding():
			var obj : Object = ray.get_collider()
			var ray_point : Vector3 = ray.get_collision_point()
			var ray_normal : Vector3 = ray.get_collision_normal()
			var impact = Global.spawn_node_from_pool(impact_effect, ray_point, -ray_normal, obj)
			impact.emitting = true
			if (obj.is_in_group("World")):
				var hole = Global.spawn_node_from_pool(hole_effect, ray_point, -ray_normal, obj)
				hole.visible = true
				hole.cur_transparency = 1.0
				var smoke = Global.spawn_node_from_pool(smoke_effect, ray_point)
				smoke.emitting = true
			elif (obj.is_in_group("Enemy")):
				obj.update_hp(alt_damage)
				weapon_manager.hud.hit_confirm.visible = true
		
func sway(delta):
	global_transform.origin = sway_pivot.global_transform.origin
	
	var pivot_quat : Quat = sway_pivot.global_transform.basis.get_rotation_quat()
	var new_quat : Quat = Quat()
	
	var self_quat : Quat = global_transform.basis.get_rotation_quat()
	var cth : float = self_quat.angle_to(pivot_quat)
	new_quat = self_quat.slerp(pivot_quat, 20 * (1 + cth) * delta)
	
	global_transform.basis = Basis(new_quat)
