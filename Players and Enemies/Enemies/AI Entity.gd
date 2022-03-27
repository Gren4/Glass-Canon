extends Node
########################
onready var Enemy_Melee_instance = preload("res://Players and Enemies/Enemies/EnemyMelee/EnemyMelee.tscn")
onready var Enemy_Range_instance = preload("res://Players and Enemies/Enemies/EnemyRange/EnemyRange.tscn")
onready var MeleeGrunt = preload("res://Players and Enemies/Enemies/MeleeGrunt/New/MeleeGrunt.tscn")
########################
onready var forces : Array = []
onready var timer : Array = []
onready var spawn_points : Array = []

export(NodePath) var player_path
onready var player = get_node(player_path)
onready var nav = get_parent()

const max_enem : int = 3

var phy_timer : int = 0
var spawn_timer : float = 0.0
var pl_sides_it : int = 0
var it : int = 0
var spawn_it : int = 0
var col_enem

#var pl_sides = {
#	0 : Vector3(0,0,0),
#	1 : Vector3(-3,0,0),
#	2 : Vector3(1.75,0,-1.75),
#	3 : Vector3(3,0,0),
#	4 : Vector3(-1.75,0,1.75),
#	5 : Vector3(1.75,0,1.75),
#	6 : Vector3(0,0,3),
#	7 : Vector3(0,0,-3)
#}

var pl_sides = {
	0 : Vector3(0,0,0),
	1 : Vector3(-1,0,0),
	2 : Vector3(0.6,0,-0.6),
	3 : Vector3(1,0,0),
	4 : Vector3(-0.6,0,0.6),
	5 : Vector3(0.6,0,0.6),
	6 : Vector3(0,0,1),
	7 : Vector3(0,0,-1)
}

var pl_sides_melee = {
	0 : Vector3(0,0,0),
	1 : Vector3(-12,0,0),
	2 : Vector3(5.5,0,-5.5),
	3 : Vector3(12,0,0),
	4 : Vector3(-5.5,0,5.5),
	5 : Vector3(5.5,0,5.5),
	6 : Vector3(0,0,12),
	7 : Vector3(0,0,-12)
}

var pl_sides_range = {
	0 : Vector3(0,0,-45),
	1 : Vector3(-15,0,-15),
	2 : Vector3(-45,0,0),
	3 : Vector3(-15,0,15),
	4 : Vector3(0,0,45),
	5 : Vector3(15,0,15),
	6 : Vector3(45,0,0),
	7 : Vector3(15,0,-15),
}

func _ready():
	forces = get_tree().get_nodes_in_group("Enemy")
	spawn_points = get_tree().get_nodes_in_group("SpawnPoint")
	for i in forces:
		init_target(i)

func init_target(target):
	target.add_to_entity()
	target.player = player
	target.attack_side = pl_sides_it
	if pl_sides_it + 1 >= 8:
		pl_sides_it = 0
	else:
		pl_sides_it += 1
	timer.append(0)

func set_target(target,point):
	var root = get_tree().root.get_child(get_tree().root.get_child_count()-1)
	root.get_node("Enemies").add_child(target)
	target.global_transform.origin = spawn_points[point].global_transform.origin
	forces.append(target)
	init_target(target)
	
func _physics_process(delta):
	col_enem = forces.size()
	
	if col_enem < max_enem:
		var col_spawn = spawn_points.size()
		if col_spawn > 0:
			if spawn_timer > 0.5:
				var new_t = MeleeGrunt.instance()
				set_target(new_t,spawn_it)
				new_t.set_state(new_t.ALLERTED_AND_KNOWS_LOC)
				if spawn_it+1 >= col_spawn:
					spawn_it = 0
				else:
					spawn_it += 1
				
			else:
				spawn_timer += delta
		pass
	var cur_it = 0
	if col_enem > 0:
		if is_instance_valid(forces[it]):
			var dist_to_player = player.global_transform.origin - forces[it].global_transform.origin
			var dist_l = dist_to_player.length()
			if forces[it].is_in_group("Melee"):
				var td = 0.0
				if dist_l <= 50:
					td = 0.1
				else:
					td = 0.5
				if timer[it] >= td:
					if phy_timer >= 4:
						move_to(forces[it],dist_l)
						timer[it] = 0.0
						phy_timer = 0
				else:
					timer[it] += delta
			elif forces[it].is_in_group("Range"):
				if timer[it] >= 1.25:
					if phy_timer >= 4:
						move_to(forces[it],dist_l)
						timer[it] = 0.0
						phy_timer = 0
				else:
					timer[it] += delta
		else:
			forces.remove(it)
			col_enem -= 1
		
		if (phy_timer < 4):
			phy_timer += 1
		
		if it+1 >= col_enem:
			it = 0
		else:
			it += 1
		cur_it += 1
		if cur_it > 0:
			return

func move_to(target,dist_l):
	var path = []
	if target.is_in_group("Melee"):
#		if dist_to_player.length() > 15:
#			var plV3 : Vector3 = player.global_transform.origin + pl_sides_melee[target.attack_side]
#			var closest_p : Vector3 = nav.get_closest_point(plV3)
#			var closest_pp : Vector3 = nav.get_closest_point(player.global_transform.origin)
#			var temp_path_sides = nav.get_nav_link_path(closest_p, closest_pp)
#			var temp_path = nav.get_nav_link_path(target.global_transform.origin, closest_pp)
#
#			if (temp_path_sides.size() != 0 ):
#				if (temp_path.size() != 0):
#					if (temp_path_sides.complete_path.size() <= temp_path.complete_path.size()):
#						path = nav.get_nav_link_path(target.global_transform.origin, closest_p)
#						if path.has("complete_path"):
#							target.get_nav_path(path)
#				else:
#					path = nav.get_nav_link_path(target.global_transform.origin, closest_p)
#					if path.has("complete_path"):
#						target.get_nav_path(path)
#			else:
#				path = temp_path
#				if path.has("complete_path"):
#					target.get_nav_path(path)
#			var dist_to_pl = (plV3 - closest_p).length()
#			if dist_to_pl < 1.0:
#				path = nav.get_nav_link_path(target.global_transform.origin, plV3)
#				if path.has("complete_path"):
#					target.get_nav_path(path)
#			else:
#				path = nav.get_nav_link_path(target.global_transform.origin, closest_p)
#				if path.has("complete_path"):
#					target.get_nav_path(path)
#		else:
			var plV3 : Vector3 = Vector3.ZERO
			if dist_l > 15:
				plV3 = player.global_transform.origin
			else:
				plV3 = player.global_transform.origin + pl_sides[target.attack_side] 
			var closest_p : Vector3 = nav.get_closest_point(plV3)
			var dist_to_pl = (player.global_transform.origin - closest_p).length()
			if dist_to_pl < 1.0:
				path = nav.get_nav_link_path(target.global_transform.origin, player.global_transform.origin)
				if path.has("complete_path"):
					target.get_nav_path(path)
			else:
				path = nav.get_nav_link_path(target.global_transform.origin, closest_p)
				if path.has("complete_path"):
					target.get_nav_path(path)
	elif target.is_in_group("Range"):
		var plV3 : Vector3 = player.global_transform.origin + pl_sides_range[target.attack_side]
		var closest_p : Vector3 = nav.get_closest_point(plV3)
		var dist_to_pl = (plV3 - closest_p).length()
		if dist_to_pl < 1.0:
			path = nav.get_nav_link_path(target.global_transform.origin, plV3)
			if path.has("complete_path"):
				target.get_nav_path(path)
		else:
			path = nav.get_nav_link_path(target.global_transform.origin, closest_p)
			if path.has("complete_path"):
				target.get_nav_path(path)
		if target.attack_side + 1 >= 8:
			target.attack_side = 0
		else:
			target.attack_side += 1		
	
#		else:
#			var closest_p : Vector3 = nav.get_closest_point(player.global_transform.origin)
#			var dist_to_pl = (player.global_transform.origin - closest_p).length()
#			if dist_to_pl < 1.0:
#				path = nav.get_nav_link_path(target.global_transform.origin, player.global_transform.origin)
#				if path.has("complete_path"):
#					target.get_nav_path(path)
#			else:
#				path = nav.get_nav_link_path(target.global_transform.origin, closest_p)
#				if path.has("complete_path"):
#					target.get_nav_path(path)
