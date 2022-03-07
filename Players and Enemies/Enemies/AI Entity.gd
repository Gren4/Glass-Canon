extends Node
########################
onready var Enemy_Melee_instance = preload("res://Players and Enemies/Enemies/EnemyMelee/EnemyMelee.tscn")
onready var Enemy_Range_instance = preload("res://Players and Enemies/Enemies/EnemyRange/EnemyRange.tscn")
########################
onready var forces : Array = []

export(NodePath) var player_path
onready var player = get_node(player_path)
onready var nav = get_parent()

var timer = []
var pl_sides_it : int = 0
var it : int = 0
var col_enem

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
	var t = 0
	forces = get_tree().get_nodes_in_group("Enemy")
	for i in forces:
		i.player = player
		i.attack_side = pl_sides_it
		if pl_sides_it + 1 >= 8:
			pl_sides_it = 0
		else:
			pl_sides_it += 1
		timer.append(t)
		t += 0.025
		if t >= 0.5:
			t = 0

func _physics_process(delta):
	col_enem = forces.size()
	if col_enem > 0:
		if is_instance_valid(forces[it]):
			if forces[it].is_in_group("Melee"):
				if timer[it] >= 0.1:
					timer[it] = 0.0
					move_to(forces[it])
				else:
					timer[it] += delta
			elif forces[it].is_in_group("Range"):
				if timer[it] >= 1.25:
					timer[it] = 0.0
					move_to(forces[it])
				else:
					timer[it] += delta
		else:
			forces.remove(it)
			timer.remove(it)
			col_enem -= 1
			
		if it+1 >= col_enem:
			it = 0
		else:
			it += 1

func move_to(target):
	var path = []
	var dist_to_player = player.global_transform.origin - target.global_transform.origin
	if target.is_in_group("Melee"):
		if dist_to_player.length() > 15 and col_enem > 1:
			var plV3 : Vector3 = player.global_transform.origin + pl_sides_melee[target.attack_side]
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
		else:
			var closest_p : Vector3 = nav.get_closest_point(player.global_transform.origin)
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
