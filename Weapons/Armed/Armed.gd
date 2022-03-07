extends WeaponMain
class_name Armed

export(PackedScene) var weapon_pickup

var animation_player

var is_firing : bool = false
var is_reloading : bool = false
var is_switching_active : bool = false

export(bool) var slow_fire_rate = true
export(int) var spread : int = 3
export(int) var ammo_in_mag : int = 15
export(int) var extra_ammo : int = 30
onready var mag_size : int = ammo_in_mag

export(int) var damage : int = 10

export(bool) var is_automatic : bool = false
export(float) var fire_rate : float = 1.0

export(Vector3) var equip_pos : Vector3 = Vector3.ZERO

export(PackedScene) var impact_effect
export(PackedScene) var hole_effect
export(PackedScene) var smoke_effect
export(NodePath) var muzzle_flash_path
onready var muzzle_flash = get_node(muzzle_flash_path)

export(float) var equip_speed : float = 1.0
export(float) var unequip_speed : float = 1.0
export(float) var reload_speed : float = 1.0

var sway_pivot = null

export(Vector3) var ads_pos : Vector3 = Vector3.ZERO
var ads_speed : int = 10
var is_ads : bool = false
var is_unequip_active : bool = false

func _ready():
	set_as_toplevel(true)
	call_deferred("create_sway_pivot")

func is_weapon_automatic() -> bool:
	return is_automatic
	
func is_switching_active() -> bool:
	return is_switching_active
	
func fire():
	if not is_reloading:
		if ammo_in_mag > 0:
			if not is_firing:
				if is_automatic:
					is_firing = true
					animation_player.get_animation("Fire").loop = true
				else:
					is_firing = false
					if animation_player.is_playing():
						animation_player.stop(true)
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
		animation_player.get_animation("Fire").loop = false
		muzzle_flash.one_shot = true
	
func fire_bullet():
	if is_automatic and not slow_fire_rate:
		muzzle_flash.one_shot = false
	else:
		muzzle_flash.one_shot = true
	muzzle_flash.emitting = true
	update_ammo("consume")
	
	ray.cast_to.x = (rand_range(spread,-spread))
	ray.cast_to.y = (rand_range(spread,-spread))
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
			obj.update_hp(damage)
			weapon_manager.hud.hit_confirm.visible = true
			
			
func reload():
	if not is_reloading and not is_switching_active:
		if ammo_in_mag < mag_size and extra_ammo > 0:
			is_firing = false
			animation_player.stop()
			animation_player.play("Reload", -1.0, reload_speed)
			is_reloading = true
			if is_automatic:
				muzzle_flash.one_shot = true

func equip() -> void:
	is_unequip_active = false
	animation_player.play("Equip", -1.0, equip_speed)
	is_reloading = false
	sway_pivot.transform.origin = equip_pos
	player.camera.fov = default_fov
	
func unequip() -> void:
	is_unequip_active = true
	animation_player.stop()
	animation_player.play("Unequip", -1.0, unequip_speed)
	muzzle_flash.one_shot = true
	is_firing = false
	
func is_equip_finished() -> bool:
	if is_equipped:
		return true
	else:
		return false
		
func is_unequip_finished() -> bool:
	if is_equipped:
		return false
	else:
		return true
		
func show_weapon():
	visible = true
	
func hide_weapon():
	visible = false
		
func on_animation_finish(anim_name):
	match anim_name:
		"Unequip":
			is_equipped = false
		"Equip":
			is_equipped = true
		"Reload":
			is_reloading = false
			update_ammo("reload")
			
func update_ammo(action = "Refresh", additional_ammo = 0, ammo_fired = 1, update = true):
	match action:
		"consume":
			ammo_in_mag -= ammo_fired
		"reload":
			var ammo_needed = mag_size - ammo_in_mag
			if extra_ammo > ammo_needed:
				ammo_in_mag = mag_size
				extra_ammo -= ammo_needed
			else:
				ammo_in_mag += extra_ammo	
				extra_ammo = 0
		"add":
			extra_ammo += additional_ammo	
	
	if update:			
		var weapon_data = {
			"Name" : weapon_name,
			"Image" : weapon_image,
			"Ammo" : str(ammo_in_mag),
			"ExtraAmmo" : str(extra_ammo)
		}
		
		weapon_manager.update_hud(weapon_data)

func drop_weapon():
	var pickup = Global.instantiate_node(weapon_pickup, global_transform.origin - player.global_transform.basis.z.normalized())
	pickup.ammo_in_mag = ammo_in_mag
	pickup.extra_ammo = extra_ammo
	pickup.mag_size = mag_size
	queue_free()

func create_sway_pivot():
	sway_pivot = Spatial.new()
	get_parent().add_child(sway_pivot)
	sway_pivot.transform.origin = equip_pos
	sway_pivot.name = weapon_name + "_Sway"
	
func sway(delta):
	global_transform.origin = sway_pivot.global_transform.origin
	
	var pivot_quat : Quat = sway_pivot.global_transform.basis.get_rotation_quat()
	var new_quat : Quat = Quat()
	if is_ads:
		new_quat = pivot_quat
	else:
		var self_quat : Quat = global_transform.basis.get_rotation_quat()
		var cth : float = self_quat.angle_to(pivot_quat)
		new_quat = self_quat.slerp(pivot_quat, 20 * (1 + cth) * delta)
	
	global_transform.basis = Basis(new_quat)

func weapon_regime(value, delta) -> int:
	if is_equipped:
		is_ads = value
		
		if  is_ads == false and player.camera.fov == default_fov:
			return BASE
		
		if is_ads:
			sway_pivot.transform.origin = sway_pivot.transform.origin.linear_interpolate(ads_pos,ads_speed * delta)
			player.camera.fov = lerp(player.camera.fov, default_fov / 2, ads_speed * delta)
			return ADS
		else:
			sway_pivot.transform.origin = sway_pivot.transform.origin.linear_interpolate(equip_pos,ads_speed * delta)
			player.camera.fov = lerp(player.camera.fov, default_fov, ads_speed * delta)
			return BASE
	return BASE	
		
func _exit_tree():
	sway_pivot.queue_free()
