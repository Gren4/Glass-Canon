extends Node
########################
onready var Enemy_instance = preload("res://Players and Enemies/Enemies/Enemy/Enemy.tscn")
########################
onready var forces : Array = []

export(NodePath) var player_path
onready var player = get_node(player_path)
onready var nav = get_parent()

var timer = []
var pl_sides_it : int = 0
var it : int = 0
var col_enem

var pl_sides = {
	0 : Vector3(0,0,0),
	1 : Vector3(-10,0,0),
	2 : Vector3(5,0,-5),
	3 : Vector3(10,0,0),
	4 : Vector3(-5,0,5),
	5 : Vector3(5,0,5),
	6 : Vector3(0,0,10),
	7 : Vector3(0,0,-10)
}

func _ready():
	var t = 0
	forces = get_tree().get_nodes_in_group("Enemy")
	for i in forces:
		i.player = player
		i.attack_side = pl_sides_it
		if pl_sides_it + 1 > 8:
			pl_sides_it = 0
		else:
			pl_sides_it += 1
		timer.append(t)
		t += 0.05
		if t >= 0.5:
			t = 0

func _physics_process(delta):
	col_enem = forces.size()
	if col_enem > 0:
		if timer[it] >= 0.1:
			timer[it] = 0.0
			if is_instance_valid(forces[it]):
				move_to(forces[it])
			else:
				forces.remove(it)
				timer.remove(it)
				col_enem -= 1
		else:
			timer[it] += delta
			
		if it+1 >= col_enem:
			it = 0
		else:
			it += 1

func move_to(target):
	var path = []
	var dist_to_player = player.global_transform.origin - target.global_transform.origin
	if dist_to_player.length() >= 10 and col_enem > 2:
		var plV3 : Vector3 = player.global_transform.origin + pl_sides[target.attack_side]
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
