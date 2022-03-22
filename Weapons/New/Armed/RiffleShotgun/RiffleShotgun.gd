extends WeaponMain

export(PackedScene) var weapon_pickup
export(PackedScene) var impact_effect
export(PackedScene) var hole_effect
export(PackedScene) var smoke_effect
export(PackedScene) var trace_effect

export(NodePath) var muzzle_flash_path
export(NodePath) var animation_tree_path
export(NodePath) var arms_path
export(NodePath) var right_hand_path
export(NodePath) var left_hand_path

export(int) var spread : int = 3
export(int) var damage : int = 10
export(int) var alt_damage : int = 5
export(int) var spread_alt : int = 10
export(int) var heat_per_bullet : float = 2.0
export(int) var heat_per_alt : float = 18.0
export(Vector3) var equip_pos : Vector3 = Vector3.ZERO

onready var animation_tree = get_node(animation_tree_path)
onready var muzzle_flash = get_node(muzzle_flash_path)
onready var arms = get_node(arms_path)
onready var right_hand = get_node(right_hand_path)
onready var left_hand = get_node(left_hand_path)
onready var heat : float = 0.0
onready var alt_spread_array : Array = [
	[0,0],[spread_alt,0],[-spread_alt,0],[0,spread_alt],[0,-spread_alt],
	[spread_alt*0.65,spread_alt*0.65],[-spread_alt*0.65,spread_alt*0.65],
	[spread_alt*0.65,-spread_alt*0.65],[-spread_alt*0.65,-spread_alt*0.65]
]

var is_firing : bool = false
var is_reloading : bool = false
var is_switching_active : bool = false
var is_alt_active : bool = false
var is_unequip_active : bool = false

func _ready():
	set_process(false)
	pass
	
func is_switching_active() -> bool:
	return is_switching_active
	
func fire():
	if not is_reloading:
		if heat < 100:
			if not is_alt_active:
				animation_tree.set("parameters/FireRifle/active", true)
			else:
				animation_tree.set("parameters/FireShotgun/active", true)
			if not is_firing:
				muzzle_flash.restart()
				is_firing = true
			return
		else:
			reload()
	
func fire_bullet():
	muzzle_flash.emitting = true
	heat += heat_per_bullet
	if heat > 100.0:
		heat = 100.0
	update_info()
	
	ray.cast_to.x = (rand_range(spread,-spread))
	ray.cast_to.y = (rand_range(spread,-spread))
	ray.force_raycast_update()
		
	if ray.is_colliding():
		var obj : Object = ray.get_collider()
		var ray_point : Vector3 = ray.get_collision_point()
		var ray_normal : Vector3 = ray.get_collision_normal()
		var impact = Global.spawn_node_from_pool(impact_effect, ray_point, -ray_normal, obj)
		var trace = Global.spawn_node_simple_mesh(trace_effect)
		trace.draw_start(muzzle_flash.global_transform.origin,ray_point)	
		impact.emitting = true
		if (obj.is_in_group("World")):
			var hole = Global.spawn_node_from_pool(hole_effect, ray_point, -ray_normal, obj)
			hole.visible = true
			hole.cur_transparency = 1.0
			#var smoke = Global.spawn_node_from_pool(smoke_effect, ray_point)
			#smoke.emitting = true
		elif (obj.is_in_group("Enemy")):
			if heat > 60.0:
				obj.update_hp(1.5 * damage)
			else:
				obj.update_hp(damage)
			weapon_manager.hud.hit_confirm.visible = true
	else:
		var trace = Global.spawn_node_simple_mesh(trace_effect)
		trace.draw_start(muzzle_flash.global_transform.origin,to_global(ray.cast_to))			

func fire_spray():
	muzzle_flash.emitting = true
	heat += heat_per_alt
	if heat > 100.0:
		heat = 100.0
	update_info()
	
	for i in 9:
		ray.cast_to.x = (alt_spread_array[i][0] + rand_range(1,-1))
		ray.cast_to.y = (alt_spread_array[i][1] + rand_range(1,-1))
		ray.force_raycast_update()
		
		if ray.is_colliding():
			var obj : Object = ray.get_collider()
			var ray_point : Vector3 = ray.get_collision_point()
			var ray_normal : Vector3 = ray.get_collision_normal()
			var trace = Global.spawn_node_simple_mesh(trace_effect)
			trace.draw_start(muzzle_flash.global_transform.origin,ray_point)
			var impact = Global.spawn_node_from_pool(impact_effect, ray_point, -ray_normal, obj)
			impact.emitting = true
			if (obj.is_in_group("World")):
				var hole = Global.spawn_node_from_pool(hole_effect, ray_point, -ray_normal, obj)
				hole.visible = true
				hole.cur_transparency = 1.0
				#var smoke = Global.spawn_node_from_pool(smoke_effect, ray_point)
				#smoke.emitting = true
			elif (obj.is_in_group("Enemy")):
				if heat > 60.0:
					obj.update_hp(1.25 * alt_damage)
				else:
					obj.update_hp(alt_damage)
				weapon_manager.hud.hit_confirm.visible = true
		else:
			var trace = Global.spawn_node_simple_mesh(trace_effect)
			trace.draw_start(muzzle_flash.global_transform.origin,to_global(ray.cast_to))		
			
func reload():
	if not is_reloading:
		is_firing = false
		is_reloading = true
		animation_tree.set("parameters/CoolOff/blend_amount",1)
		animation_tree.set("parameters/SetCool/current",0)

func _process(delta):
	if is_reloading:
		if heat <= 0.0:
			heat = 0.0
			update_info()
			animation_tree.set("parameters/SetCool/current",2)
		else:
			heat -= 20 * delta
			update_info()
	else:
		if heat <= 0.0:
			heat = 0.0
			update_info()
		else:
			heat -= 6 * delta
			update_info()
		

func equip() -> void:
	arms.set_right_hand(right_hand.get_path())
	arms.set_left_hand(left_hand.get_path())
	is_unequip_active = false
	animation_tree.set("parameters/Idle/current",0)
	animation_tree.set("parameters/Equip/active",true)
	if is_reloading:
		pass
	player.camera.fov = default_fov
	set_process(true)
	
func unequip() -> void:
	is_unequip_active = true
	animation_tree.set("parameters/Unequip/active",true)
	#muzzle_flash.one_shot = true
	is_firing = false
	set_process(false)
	
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
		"SwitchToRifle","SwitchToShotgun":
			is_switching_active = false
		"FireRifle","FireShotgun":
			is_firing = false
		"SwitchFromCoolOff":
			animation_tree.set("parameters/CoolOff/blend_amount",0)	
			is_reloading = false
			
func update_info(action = "Refresh", additional_ammo = 0, ammo_fired = 1, update = true):
#	match action:
#		"consume":
#			ammo_in_mag -= ammo_fired
#		"reload":
#			var ammo_needed = mag_size - ammo_in_mag
#			if extra_ammo > ammo_needed:
#				ammo_in_mag = mag_size
#				extra_ammo -= ammo_needed
#			else:
#				ammo_in_mag += extra_ammo	
#				extra_ammo = 0
#		"add":
#			extra_ammo += additional_ammo	
	
	if update:			
		var weapon_data = {
			"Name" : weapon_name,
			"Image" : weapon_image,
			"Ammo" : str(int(heat)),
#			"ExtraAmmo" : str(extra_ammo)
		}
		
		weapon_manager.update_hud(weapon_data)
	
func sway(mouse_input,delta):
	var rot : Vector3 = Vector3(0,
								clamp(mouse_input.x*5,-30,30),
								clamp(mouse_input.y*5,-30,30))
	rotation_degrees = rotation_degrees.linear_interpolate(rot, delta * 6)
		
func weapon_regime(value, delta) -> int:
	if is_equipped:
		if value:
			if not is_alt_active and not is_firing and not is_reloading:
				animation_tree.set("parameters/Idle/current",1)
				animation_tree.set("parameters/FireRifle/active", false)
				is_alt_active = true
				is_switching_active = true
				is_firing = false
				#muzzle_flash.one_shot = true
				return ALT
			else:
				return BASE
		else:
			if is_alt_active and not is_firing and not is_reloading:
				animation_tree.set("parameters/Idle/current",3)
				animation_tree.set("parameters/FireShotgun/active", false)
				is_alt_active = false
				is_switching_active = true
				is_firing = false
				#muzzle_flash.one_shot = true
				return BASE
			else:
				return ALT
	return BASE		
