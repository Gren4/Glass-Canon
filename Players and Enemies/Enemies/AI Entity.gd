extends Node
########################
#onready var MeleeGrunt = preload("res://Players and Enemies/Enemies/MeleeGrunt/MeleeGruntNew.tscn")
onready var MeleeGrunt = preload("res://Players and Enemies/Enemies/MeleeGrunt/MeleeGruntNew.tscn")
onready var RangeGrunt = preload("res://Players and Enemies/Enemies/RangeGrunt/RangeGruntNew.tscn")
########################
var forces : Array = []
var timer : Array = []
var taken_points : PoolVector3Array = []
var spawn_points : Array = []

export(NodePath) var player_path
onready var player = get_node(player_path)
onready var nav = get_parent()
const max_enem : int = 0

var col_enem_to_spawn = 300

var spawn_timer : float = 0.0
var pl_sides_it : int = 0
var it : int = 0
var spawn_it : int = 0
var col_enem

func _ready():
	forces = get_tree().get_nodes_in_group("Enemy")
	spawn_points = get_tree().get_nodes_in_group("SpawnPoint")
	for i in forces:
		init_target(i)

	pass

func init_target(target):
	target.player = player
	target.attack_side = pl_sides_it
	if pl_sides_it + 1 >= 8:
		pl_sides_it = 0
	else:
		pl_sides_it += 1
	if target.is_in_group("Melee"):
		timer.append(randi()%6)
	elif target.is_in_group("Range"):
		timer.append(randi()%51)
	elif target.is_in_group("Flying"):
		timer.append(randi()%51)
	
	taken_points.append(target.global_transform.origin)

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
				if en_type < 100:
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
		
	if col_enem > 0:
		for e in range(it,col_enem):
			if e >= col_enem:
				break
			if is_instance_valid(forces[e]):
				if (timer[e] < 100):
					timer[e] += 1
				else:
					timer[e] = 0
				var dist_to_player = player.global_transform.origin - forces[e].global_transform.origin
				var dist_l = dist_to_player.length()
				if forces[e].is_in_group("Melee"):
					if (forces[e].give_path):
						if dist_l > 10:
							if timer[e]%10 == 0:
								taken_points[e] = move_to(forces[e],dist_l,e)
								it = e
								break
						else:
							if timer[e]%5 == 0:
								taken_points[e] = move_to(forces[e],dist_l,e)
								it = e
								break
				elif forces[e].is_in_group("Range"):
					if (forces[e].give_path):
						if timer[e]%50 == 0:
							taken_points[e] = move_to(forces[e],dist_l,e)
							it = e
							break
				elif forces[e].is_in_group("Flying"):
					if (forces[e].give_path):
						if timer[e]%50 == 0:
							taken_points[e] = move_to(forces[e],dist_l,e)
							it = e
							break
			else:
				forces.remove(e)
				timer.remove(e)
				taken_points.remove(e)
				col_enem -= 1

		if it+1 >= col_enem:
			it = 0
		else:
			it += 1

func move_to(target, dist_l : float, i : int) -> Vector3:
	var path = {}
	if target.is_in_group("Melee"):
		var plV3 : Vector3 = Vector3.ZERO
		if dist_l > 20:
			plV3 = _get_point(15.0, target.attack_side, i)
		elif dist_l > 10:
			plV3 = _get_point(8.0, target.attack_side, i)
		else:
			plV3 = _get_point(4.5, target.attack_side, i)
		path = nav.get_path_links(target.global_transform.origin, plV3)
		target.get_nav_path(path)
		return plV3

	elif target.is_in_group("Range"):
		var plV3 : Vector3 = _get_point(25.0, target.attack_side, i)
		path = nav.get_path_links(target.global_transform.origin, plV3)
		target.get_nav_path(path)
		target.attack_side = randi()%8	
		return plV3
		
	elif target.is_in_group("Flying"):
		var plV3 : Vector3 = _get_point(15.0, target.attack_side, i, false)
		path = nav.get_path_links(target.global_transform.origin, plV3)
		target.get_nav_path(path)
		return plV3
		
	return Vector3.ZERO

func _get_point(dist : float, side : int, i : int, check_down : bool = true) -> Vector3:
	var point : Vector3 = player.get_point_for_npc(dist, side, check_down)
#	for j in range(taken_points.size()):
#		if j == i: 
#			continue
#		else:
#			if (point - taken_points[j]).length_squared() <= 1.94:
#				point = point + Vector3(2.0,0,2.0)
	return point
	
	
	
