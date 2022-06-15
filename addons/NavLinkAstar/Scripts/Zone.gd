extends Node

class_name ZonePath

var StartPoint : Vector3
var x_max : float = -1e20
var x_min : float = 1e20
var y_max : float = -1e20
var y_min : float = 1e20
var z_max : float = -1e20
var z_min : float = 1e20

func _ready():
	var ArrayPoints : Array = [	$_1.global_transform.origin, 
								$_2.global_transform.origin, 
								$_3.global_transform.origin, 
								$_4.global_transform.origin, 
								$_5.global_transform.origin, 
								$_6.global_transform.origin, 
								$_7.global_transform.origin, 
								$_8.global_transform.origin]
	StartPoint = $Start.global_transform.origin
	
	for p in ArrayPoints:
		if p.x > x_max:
			x_max = p.x
		elif p.x < x_min:
			x_min = p.x
		if p.y > y_max:
			y_max = p.y
		elif p.y < y_min:
			y_min = p.y
		if p.z > z_max:
			z_max = p.z
		elif p.z < z_min:
			z_min = p.z
	
	
