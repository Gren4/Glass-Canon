extends Node
########################
onready var Enemy_Melee_instance = preload("res://Players and Enemies/Enemies/EnemyMelee/EnemyMelee.tscn")
onready var Enemy_Range_instance = preload("res://Players and Enemies/Enemies/EnemyRange/EnemyRange.tscn")
onready var MeleeGrunt = preload("res://Players and Enemies/Enemies/MeleeGrunt/MeleeGruntNew.tscn")
onready var RangeGrunt = preload("res://Players and Enemies/Enemies/RangeGrunt/RangeGruntNew.tscn")
########################
onready var forces : Array = []
onready var timer : Array = []
onready var spawn_points : Array = []

export(NodePath) var player_path
onready var player = get_node(player_path)
onready var nav = get_parent()
const max_enem : int = 5

var col_enem_to_spawn = 300

var phy_timer : int = 0
var link_timer : int = 0
var spawn_timer : float = 0.0
var pl_sides_it : int = 0
var it : int = 0
var spawn_it : int = 0
var col_enem

var pl_sides = {
	0 : Vector3(0,0,0),
	1 : Vector3(-3,0,0),
	2 : Vector3(1.75,0,-1.75),
	3 : Vector3(3,0,0),
	4 : Vector3(-1.75,0,1.75),
	5 : Vector3(1.75,0,1.75),
	6 : Vector3(0,0,3),
	7 : Vector3(0,0,-3)
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
	target.player = player
	target.attack_side = pl_sides_it
	if target.is_in_group("Melee"):
		if pl_sides_it + 1 >= 4:
			pl_sides_it = 0
		else:
			pl_sides_it += 1
		timer.append(randi()%21)
	elif target.is_in_group("Range"):
		if pl_sides_it + 1 >= 4:
			pl_sides_it = 0
		else:
			pl_sides_it += 1
		timer.append(randi()%41)

func set_target(target,point):
	var root = get_tree().root.get_child(get_tree().root.get_child_count()-1)
	root.get_node("Enemies").add_child(target)
	target.global_transform.origin = spawn_points[point].global_transform.origin
	forces.append(target)
	init_target(target)
	
func _physics_process(delta):
	col_enem = forces.size()
		
	if col_enem < max_enem and col_enem_to_spawn > 0:
		var col_spawn = spawn_points.size()
		if col_spawn > 0:
			if spawn_timer > 0.3:
				spawn_timer = 0.0
				var en_type = randi()%100
				var new_t
				if en_type <= 50:
					new_t = MeleeGrunt.instance()
				else:
					new_t = RangeGrunt.instance()			
				set_target(new_t,spawn_it)
				new_t.set_state(new_t.ALLERTED_AND_KNOWS_LOC)
				new_t.allerted = true
				col_enem_to_spawn = col_enem_to_spawn - 1
				if spawn_it+1 >= col_spawn:
					spawn_it = 0
				else:
					spawn_it += 1
				
			else:
				spawn_timer += delta
		pass
		
	#if phy_timer >= 0:
	if col_enem > 0:
		if is_instance_valid(forces[it]):
			if (timer[it] < 100):
				timer[it] += 1
			else:
				timer[it] = 0
			var dist_to_player = player.global_transform.origin - forces[it].global_transform.origin
			var dist_l = dist_to_player.length()
			if forces[it].is_in_group("Melee"):
				if timer[it]%4 == 0:
					move_to(forces[it],dist_l)
			elif forces[it].is_in_group("Range"):
				if (forces[it].give_path):
					if timer[it]%40 == 0:
						move_to(forces[it],dist_l)
		else:
			forces.remove(it)
			timer.remove(it)
			col_enem -= 1

		if it+1 >= col_enem:
			it = 0
		else:
			it += 1
	#phy_timer = 0
	if link_timer > 0:
		link_timer = link_timer - 1
	#else:
		#phy_timer += 1

func move_to(target,dist_l):
	var path = {}
	if target.is_in_group("Melee"):
			var plV3 : Vector3 = Vector3.ZERO
			if dist_l > 20:
				plV3 = player.get_point_for_npc(15.0, target.attack_side)
			elif dist_l > 10:
				plV3 = player.get_point_for_npc(8, target.attack_side)
			else:
				plV3 = player.get_point_for_npc(4.5, target.attack_side)
			var closest_t : Vector3 = nav.get_closest_point(target.global_transform.origin)
			var closest_p : Vector3 = nav.get_closest_point(plV3)
#			if (link_timer == 0 and dist_l > 6.0):
#				link_timer = 2
			path = nav.get_nav_link_path(closest_t, closest_p)
			if path.has("complete_path"):
				target.get_nav_path(path)
				if path["nav_link_to_first"].size() > 0:
					var j : int = 0
					for i in forces:
						if i == target:
							continue
						if is_instance_valid(i):
							if i.is_in_group("Melee") and i.my_path.size() == 0:
								var dt : Vector3 = target.global_transform.origin - i.global_transform.origin
								if (dt.length() <= 5.0):
									timer[j] = 0
									i.get_nav_path(path)
									pass
						j += 1
#			else:
#				var temp_path = nav.get_simple_path(closest_t, closest_p)
#				if (temp_path.size()>0):
#					path = {
#								"complete_path": temp_path,
#								"nav_link_to_first": [],
#								"nav_link_from_last": [],
#								"nav_link_path_inbetween": []
#							}
#					target.get_nav_path(path)
	elif target.is_in_group("Range"):
		var plV3 : Vector3 = player.get_point_for_npc(25.0, target.attack_side, "Range")
		var closest_t : Vector3 = nav.get_closest_point(target.global_transform.origin)
		var closest_p : Vector3 = nav.get_closest_point(plV3)
#		if (link_timer == 0):
#			link_timer = 2
		path = nav.get_nav_link_path(closest_t, closest_p)
		if path.has("complete_path"):
			target.get_nav_path(path)
#		else:
#			var temp_path = nav.get_simple_path(closest_t, closest_p)
#			if (temp_path.size()>0):
#				path = {
#							"complete_path": temp_path,
#							"nav_link_to_first": [],
#							"nav_link_from_last": [],
#							"nav_link_path_inbetween": []
#						}
#				target.get_nav_path(path)
		if target.attack_side + 1 >= 4:
			target.attack_side = 0
		else:
			target.attack_side += 1		
