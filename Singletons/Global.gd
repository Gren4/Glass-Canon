extends Node

export var min_load_amount = 50
var object_pool : Dictionary = {}
var previous_object_taken : Dictionary = {}

# При использовании время выполнения скриптов увеличилось с ~0.17 до 0.43 мс. 
# Думаю нет смысла использовать данный подход
#func _process(delta):
#	for type in object_pool:
#		for i in min_load_amount:
#			if "cur_transparency" in object_pool[type][i]:
#				if object_pool[type][i].cur_transparency > 0.0:
#					var color : Color = Color(1.0,1.0,1.0,object_pool[type][i].cur_transparency)
#					object_pool[type][i].process_material.set_color(color)
#					object_pool[type][i].cur_transparency -= object_pool[type][i].lifetime_delta*delta
#				else:
#					object_pool[type][i].emitting = false
#				#print("GOOD")
#			#print(object_pool[type][i])

func instantiate_node(packed_scene, pos = null, normal = null, parent = null):
	var clone = packed_scene.instance()
	clone.set_disable_scale(true)
	var root = get_tree().root.get_child(get_tree().root.get_child_count()-1)
	if parent == null:
		parent = root
		
	parent.add_child(clone)
	
	if pos != null:
		clone.global_transform.origin = pos
		if normal != null:
			if normal.is_equal_approx(Vector3.UP):
				clone.rotation_degrees.x = 90
			elif normal.is_equal_approx(Vector3.DOWN):
				clone.rotation_degrees.x = -90
			else:
				clone.look_at_from_position(pos, pos + normal, Vector3.UP)
	
	return clone
	
func spawn_node_from_pool(packed_scene, pos = null, normal = null, parent = null):
	var clone = take_node_from_pool(packed_scene)
	clone.set_disable_scale(true)
	var root = get_tree().root.get_child(get_tree().root.get_child_count()-1)
	if parent == null:
		parent = root
		
	parent.add_child(clone)
	
	if pos != null:
		clone.global_transform.origin = pos
		if normal != null:
			if normal.is_equal_approx(Vector3.UP):
				clone.rotation_degrees.x = 90
			elif normal.is_equal_approx(Vector3.DOWN):
				clone.rotation_degrees.x = -90
			else:
				clone.look_at_from_position(pos, pos + normal, Vector3.UP)
	
	return clone
	
func take_node_from_pool(packed_scene):
	var object
	var scene_path : String = packed_scene.get_path()
	if not scene_path in object_pool:
		load_node_in_pool(packed_scene)
	var index : int = previous_object_taken[scene_path]
	if index + 1 > min_load_amount - 1:
		index = 0
	else:
		index += 1
	object = object_pool[scene_path][index]
	var parent = object.get_parent()
	if is_instance_valid(parent):
		parent.remove_child(object)
	object.visible = true
	previous_object_taken[scene_path] = index
	return object

func load_node_in_pool(packed_scene):
	var root = get_tree().root.get_child(get_tree().root.get_child_count()-1)
	var scene_path : String = packed_scene.get_path()
	for _i in min_load_amount:
		var object = packed_scene.instance()
		object.visible = false
		if scene_path in object_pool:
			object_pool[scene_path].append(object)
		else:
			object_pool[scene_path] = [object]
		root.add_child(object)
	previous_object_taken[scene_path] = -1
