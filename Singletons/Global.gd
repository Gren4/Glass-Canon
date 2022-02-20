extends Node

const MAX_INSTANCES_AT_A_TIME : int = 5
export(int) var min_load_amount : int = 50 # Должен быть кратен 10
var object_pool : Dictionary = {}
var previous_object_taken : Dictionary = {}

func instantiate_node(packed_scene, pos = null, normal = null, parent = null):
	var root = get_tree().root.get_child(get_tree().root.get_child_count()-1)
	var clone = packed_scene.instance()
	return place_node(root, clone, pos, normal, parent)
	
func spawn_node_from_pool(packed_scene, pos = null, normal = null, parent = null):
	var root = get_tree().root.get_child(get_tree().root.get_child_count()-1)
	var clone = take_node_from_pool(root, packed_scene)
	return place_node(root, clone, pos, normal, parent)
	
func place_node(root, clone, pos = null, normal = null, parent = null):
	clone.set_disable_scale(true)
	if parent == null:
		parent = root
		parent.add_child(clone)
	else:
		if parent.is_in_group("Enemy"):
			var place_holder : Spatial = parent.get_node("GlobalParticles")
			place_holder.set_disable_scale(true)
			place_holder.add_child(clone)
		else:
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
	
func take_node_from_pool(root, packed_scene):
	var object
	var scene_path : String = packed_scene.get_path()
	var index : int
	if previous_object_taken.has(scene_path):
		index = previous_object_taken[scene_path] 
	else:
		 index = -1
	if index + 1 > min_load_amount - 1:
		index = 0
	else:
		index += 1
	check_nodes(root, packed_scene, scene_path, index)
	object = object_pool[scene_path][index]
	var parent = object.get_parent()
	if is_instance_valid(parent):
		parent.remove_child(object)
	object.visible = true
	previous_object_taken[scene_path] = index
	return object

func check_nodes(root, packed_scene, scene_path, index):
	if not scene_path in object_pool:
		load_node_in_pool(root, packed_scene, scene_path)
		previous_object_taken[scene_path] = 0
	else:
		var size : int = object_pool[scene_path].size()
		if size < min_load_amount and index >= size:
			for i in range(size, size + (min_load_amount / MAX_INSTANCES_AT_A_TIME)):
				if object_pool[scene_path].size() == min_load_amount:
					return
				else:
					load_node_in_pool(root, packed_scene, scene_path)

func load_node_in_pool(root, packed_scene, scene_path):
	var object = packed_scene.instance()
	object.visible = false
	if scene_path in object_pool:
		object_pool[scene_path].append(object)
	else:
		object_pool[scene_path] = [object]
	root.add_child(object)
	
	
###############################

func look_face(_self, target, rotationSpeed, delta):
	var global_pos = _self.global_transform.origin
	var wtransform = _self.global_transform.looking_at(target,Vector3.UP)
	var wrotation = Quat(_self.global_transform.basis).slerp(Quat(wtransform.basis), rotationSpeed * delta)
	_self.global_transform = Transform(Basis(wrotation), _self.global_transform.origin)

func turn_face(_self, target, rotationSpeed, delta):
	var global_pos = _self.global_transform.origin
	var wtransform = _self.global_transform.looking_at(Vector3(target.x,global_pos.y,target.z),Vector3.UP)
	var wrotation = Quat(_self.global_transform.basis).slerp(Quat(wtransform.basis), rotationSpeed * delta)
	_self.global_transform = Transform(Basis(wrotation), _self.global_transform.origin)
