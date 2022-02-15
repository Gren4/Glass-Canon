extends Node


func instantiate_node(packed_scene, pos = null, normal = null, parent = null):
	var clone = packed_scene.instance()
	var root = get_tree().root
	if parent == null:
		parent = root.get_child(root.get_child_count()-1)
		
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
