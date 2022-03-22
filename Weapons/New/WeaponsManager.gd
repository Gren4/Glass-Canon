extends Spatial

export(NodePath) var ray_path

export(NodePath) var camera_path

var all_weapons : Dictionary = {}

var weapons : Dictionary = {}

var hud 

var camera

var def_fov

var current_weapon
var current_weapon_slot : String = "Primary"

var changing_weapon : bool = false
var unequipped_weapon : bool = false

var weapon_index : int = 0

func _ready():
	
	hud = owner.get_node("HUD")
	get_node(ray_path).add_exception(owner)
	camera = get_node(camera_path)
	
	all_weapons = {
		"RiffleShotgun" : preload("res://Weapons/New/Armed/RiffleShotgun/RiffleShotgun.tscn")
	}
	def_fov = camera.fov
	weapons = {
		"Primary" : $Unarmed,
		"Secondary" : null
	}
	
	for w in weapons:
		if is_instance_valid(weapons[w]):
			weapon_setup(weapons[w])
			
	current_weapon = weapons["Primary"]		
	initial_weapon("Primary")
	
	set_process(false)
	
func weapon_setup(w):
	w.weapon_manager = self
	w.player = owner
	w.default_fov = def_fov
	w.ray = get_node(ray_path)
	w.visible = false
		
func initial_weapon(weapon_slot):
	current_weapon_slot = weapon_slot
	current_weapon = weapons[current_weapon_slot]
	update_weapon_index()
	weapons[current_weapon_slot].update_info()
		
func change_weapon(new_weapon_slot):
	if changing_weapon:
		return
	if new_weapon_slot == current_weapon_slot:
		return
	if not is_instance_valid(weapons[new_weapon_slot]):
		return
	current_weapon_slot = new_weapon_slot
	changing_weapon = true
	update_weapon_index()
	if is_instance_valid(current_weapon):
		unequipped_weapon = false
		current_weapon.unequip()
	set_process(true)

func _process(_delta):
		if unequipped_weapon == false:
			if current_weapon.is_unequip_finished() == false:
				return
			unequipped_weapon = true
			current_weapon = weapons[current_weapon_slot]
			current_weapon.equip()
		if current_weapon.is_equip_finished() == false:
			return
		changing_weapon = false
		set_process(false)


func update_hud(weapon_data):
	var weapon_slot = "1"
	match current_weapon_slot:
		"Primary":
			weapon_slot = "1"
		"Secondary":
			weapon_slot = "2"
	hud.update_weapon_ui(weapon_data, weapon_slot)

func update_weapon_index():
	match current_weapon_slot:
		"Primary":
			weapon_index = 0
		"Secondary":
			weapon_index = 1

func next_weapon():
	weapon_index += 1
	if weapon_index >= weapons.size():
		weapon_index = 0 
	change_weapon(weapons.keys()[weapon_index])
	
	
func previous_weapon():
	weapon_index -= 1
	if weapon_index < 0:
		weapon_index = weapons.size() - 1
	change_weapon(weapons.keys()[weapon_index])
	
func fire():
	if not changing_weapon:
		current_weapon.fire()
	
func reload():
	if not changing_weapon:
		current_weapon.reload()
	
func is_switching_active():
	return current_weapon.is_switching_active()
		
func add_weapon(weapon_data):
	if not weapon_data["Name"] in all_weapons:
		return
	match weapon_data["Name"]:
		"RiffleShotgun":
			if not is_instance_valid(weapons["Primary"]) or weapons["Primary"].weapon_name == "Unarmed":
				add_manage(weapon_data,"Primary")
				return
	
func add_manage(weapon_data, slot):
	var weapon = Global.instantiate_node(all_weapons[weapon_data["Name"]], Vector3.ZERO, null, self)
	weapon_setup(weapon)
#	weapon.ammo_in_mag = weapon_data["Ammo"]
#	weapon.extra_ammo = weapon_data["ExtraAmmo"]
#	weapon.mag_size = weapon_data["MagSize"]
	weapon.transform.origin = weapon.equip_pos
	weapons[slot] = weapon
	initial_weapon(slot)
	set_process(true)
	
func show_interaction_promt(weapon_name):
	var desc : String = ""
	match weapon_name:
		"RiffleShotgun":
			if not is_instance_valid(weapons["Primary"]) or weapons["Primary"].weapon_name == "Unarmed":
				desc = "Equip"
				hud.show_interaction_promt(desc)
				return true
			else:
				return false
	return false
	
func hide_interaction_promt():
	hud.hide_interaction_promt()

func process_weapon_pickup():
	var from : Vector3 = global_transform.origin
	var to : Vector3 = global_transform.origin - global_transform.basis.z.normalized() * 3.0
	var space_state : PhysicsDirectSpaceState = get_world().direct_space_state
	var collision = space_state.intersect_ray(from,to,[owner],4)
	
	if collision:
		var body = collision["collider"]
		if body.has_method("get_weapon_pickup_data"):
			var weapon_data : Dictionary = body.get_weapon_pickup_data()
			if (show_interaction_promt(weapon_data["Name"])):
				if Input.is_action_just_pressed("interact"):
					add_weapon(weapon_data)
					body.queue_free()
					hide_interaction_promt()
		else:
			hide_interaction_promt()
	else:
		hide_interaction_promt()
