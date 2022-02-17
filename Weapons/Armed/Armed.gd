extends WeaponMain
class_name Armed

export(PackedScene) var weapon_pickup

var animation_player

var is_firing : bool = false
var is_reloading : bool = false

export var ammo_in_mag = 15
export var extra_ammo = 30
onready var mag_size = ammo_in_mag

export var damage = 10

export var is_automatic : bool = false
export var fire_rate = 1.0

export var equip_pos = Vector3.ZERO

export(PackedScene) var impact_effect
export(PackedScene) var hole_effect
export(NodePath) var muzzle_flash_path
onready var muzzle_flash = get_node(muzzle_flash_path)

export var equip_speed : float = 1.0
export var unequip_speed : float = 1.0
export var reload_speed : float = 1.0
	
func is_weapon_automatic() -> bool:
	return is_automatic
	
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
	
func fire_bullet():
	muzzle_flash.emitting = true
	update_ammo("consume")
	
	ray.force_raycast_update()
	
	if ray.is_colliding():
		var impact = Global.instantiate_node(impact_effect, ray.get_collision_point())
		impact.emitting = true
		var obj : Object = ray.get_collider()
		if (obj.is_in_group("World")):
			var inh_obj : Object = null
			if (obj.get_class() == "KinematicBody"):
				inh_obj = obj
			var hole = Global.instantiate_node(hole_effect, ray.get_collision_point(), -ray.get_collision_normal(), null , inh_obj)	
			hole.to_end = true
			hole.visible = true
			
func reload():
	if ammo_in_mag < mag_size and extra_ammo > 0:
		is_firing = false
		animation_player.play("Reload", -1.0, reload_speed)
		is_reloading = true

func equip() -> void:
	animation_player.play("Equip", -1.0, equip_speed)
	is_reloading = false
	
func unequip() -> void:
	animation_player.play("Unequip", -1.0, unequip_speed)
	
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
			
func update_ammo(action = "Refresh", additional_ammo = 0, update = true):
	match action:
		"consume":
			ammo_in_mag -= 1
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
