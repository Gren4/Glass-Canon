extends Navigation
var res : Resource

class_name NavLinkAstar

var cube_mesh = CubeMesh.new()
var red_material = SpatialMaterial.new()
var green_material = SpatialMaterial.new()

export (bool) var generate_nav = true

export (NodePath) var NavLink_path = null
onready var NavLink = get_node(NavLink_path)

export (NodePath) var NavMesh_path = null
onready var NavMeshInstance = get_node(NavMesh_path)
onready var NavMesh = NavMeshInstance.navmesh

var astar : AStar
var links_paths : Dictionary
var doubles : Dictionary = {}
var main_vert : PoolVector3Array = []
var main_id : Array = []
var main_col : int
var links_col : int
var link_one : PoolVector3Array = []
var link_two : PoolVector3Array = []
var id_one : Array = []
var id_two : Array = []

func _ready():
	red_material.albedo_color = Color.red
	green_material.albedo_color = Color.green
	cube_mesh.size = Vector3(0.25, 0.25, 0.25)
	if generate_nav == true:
		_generate_astar_points()
	
func _create_nav_cube(position: Vector3, material):
	var cube = MeshInstance.new()
	cube.mesh = cube_mesh
	cube.material_override = material
	add_child(cube)
	cube.global_transform.origin = position
	
func get_path_links(from: Vector3, to: Vector3) -> Dictionary:
	from = get_closest_point(from)
	to = get_closest_point(to)
	var path : PoolVector3Array = []
	var type : int = 0
	var link_from : PoolVector3Array = []
	var link_to : PoolVector3Array = []
	var link_from_id : Array = []
	var link_to_id : Array = []
	
	var a_path : PoolVector3Array = _find_path(from, to)
	var size_a = a_path.size()

	for i in range(size_a-1):
		for j in range(links_col):
			if (a_path[i] == link_one[j] and a_path[i+1] == link_two[j]):
				link_from.append(link_one[j])
				link_from_id.append(id_one[j])
				link_to.append(link_two[j])
				link_to_id.append(id_two[j])
			elif (a_path[i] == link_two[j] and a_path[i+1] == link_one[j]):
				link_from.append(link_two[j])
				link_from_id.append(id_two[j])
				link_to.append(link_one[j])
				link_to_id.append(id_one[j])		

	var lt_c : int = link_to.size()
	var lf_c : int = link_from.size()
	if lt_c == 0 and lf_c == 0:
		type = 0
		path = get_simple_path(from,to)
	else:
		if lt_c == 0:
			type = 0
			path = get_simple_path(from,to)
		else:
			type = 1
			if lt_c == 1:
				path = get_simple_path(from,link_from[0])
				path.append(link_to[0])
				path.append_array(get_simple_path(link_to[0],to))
			else:
				path = get_simple_path(from,link_from[0])
				path.append(link_to[0])
				for i in range(lt_c - 1):
					var key : String = _create_key(link_to_id[i],link_from_id[i+1])
					path.append_array(links_paths[key])
					path.append(link_to[i+1])
				path.append_array(get_simple_path(link_to[lt_c-1],to))

	return {
		"type": type,
		"path": path,
		"from": link_from,
		"to": link_to
	}	
	
func _find_path(from: Vector3, to: Vector3) -> PoolVector3Array:
	var from_d : float = 1e20
	var from_id : int
	var to_d : float = 1e20
	var to_id : int
	
	for i in main_col:
		var vt : Vector3 = main_vert[i] - from
		vt.y *= 4
		var dt : float = vt.length()
		if dt < from_d:
			from_d = dt
			from_id = main_id[i]
		vt = main_vert[i] - to
		vt.y *= 4
		dt = vt.length()
		if dt < to_d:
			to_d = dt
			to_id = main_id[i]
#	#var start_id = astar.get_closest_point(from)
#	#var end_id = astar.get_closest_point(to)
	return astar.get_point_path(from_id, to_id)
	
func _check_doubles(d : Dictionary, i : int) -> int:
	if d.has(i):
		return d[i]
	else:
		return i
	
func _generate_astar_points() -> void:
	var dop_id : Array = []
	var dop_vert : PoolVector3Array = []
	main_vert = NavMesh.get_vertices()
	astar = AStar.new()
	
	var vert_count : int = main_vert.size()
	var poly_count : int = NavMesh.get_polygon_count()
	
	var exclude : Array = []
	for i in range(vert_count):
		if i in exclude:
			continue
		for j in range(vert_count):
			if i == j:
				continue
			else:
				if main_vert[i] == main_vert[j]:
					exclude.append(j)
					doubles[j] = i
	
	for i in range(vert_count):
		var a_id : int = astar.get_available_point_id()
		main_id.append(a_id)
		astar.add_point(a_id, main_vert[i])
		#_create_nav_cube(main_vert[i],green_material)
					
	for i in range(poly_count):
		var index_arr : Array = NavMesh.get_polygon(i)
		var col_v : int = index_arr.size()
		var center : Vector3 = Vector3.ZERO
		for j in col_v:
			center += main_vert[index_arr[j]]
			for c in col_v:
				if c == j:
					continue
				else:
					var i1 : int = _check_doubles(doubles,main_id[index_arr[j]])
					var i2 : int = _check_doubles(doubles,main_id[index_arr[c]])
					if not astar.are_points_connected(i1,i2):
						astar.connect_points(i1,i2)
		center = center / col_v
		var a_id : int = astar.get_available_point_id()
		astar.add_point(a_id,center)
		#_create_nav_cube(center,green_material)
		dop_id.append(a_id)
		dop_vert.append(center)
		for j in col_v:
			var i1 : int = _check_doubles(doubles,main_id[index_arr[j]])
			if not astar.are_points_connected(i1,dop_id[i]):
				astar.connect_points(i1,dop_id[i])
	
	main_vert.append_array(dop_vert)
	main_id.append_array(dop_id)
	main_col = main_vert.size()
	var nav_link_group = NavLink.get_children()
	for p in nav_link_group:
		if p is NavLinkAstarPath:
			var one : Vector3 = get_closest_point(p.One.global_transform.origin)
			var two : Vector3 = get_closest_point(p.Two.global_transform.origin)
			link_one.append(one)
			link_two.append(two)
			var a_id1 = astar.get_available_point_id()
			astar.add_point(a_id1, one)
			#_create_nav_cube(one,green_material)
			id_one.append(a_id1)
			var a_id2 = astar.get_available_point_id()
			astar.add_point(a_id2, two)
			#_create_nav_cube(two,green_material)
			id_two.append(a_id2)
			if not astar.are_points_connected(a_id1, a_id2):
				astar.connect_points(a_id1, a_id2)
			# Search for nearest polygon to connect
			var d1 : float = 1e20
			var i1 : int
			var d2 : float = 1e20
			var i2 : int
			for d in range(main_vert.size()):
				var new_d1 : float = (main_vert[d] - one).length()
				if (new_d1 < d1):
					d1 = new_d1
					i1 = _check_doubles(doubles,main_id[d])
				var new_d2 : float = (main_vert[d] - two).length()
				if (new_d2 < d2):
					d2 = new_d2
					i2 = _check_doubles(doubles,main_id[d])
			if not astar.are_points_connected(a_id1, i1):
				astar.connect_points(a_id1, i1)
			if not astar.are_points_connected(a_id2, i2):
				astar.connect_points(a_id2, i2)
				
	links_col = link_one.size()
	for i in range(links_col):
		for j in range(links_col):
			if i == j:
				continue
			else:
				var key1 : String = _create_key(id_one[i],id_one[j])
				var path1 : PoolVector3Array = get_simple_path(link_one[i], link_one[j])
				if path1.size() > 0:
					links_paths[key1] = path1
				var key2 : String = _create_key(id_one[i],id_two[j])
				var path2 : PoolVector3Array = get_simple_path(link_one[i], link_two[j])
				if path2.size() > 0:
					links_paths[key2] = path2
				var key3 : String = _create_key(id_two[i],id_one[j])
				var path3 : PoolVector3Array = get_simple_path(link_two[i], link_one[j])
				if path3.size() > 0:
					links_paths[key3] = path3
				var key4 : String = _create_key(id_two[i],id_two[j])
				var path4 : PoolVector3Array = get_simple_path(link_two[i], link_two[j])
				if path4.size() > 0:
					links_paths[key4] = path4
	pass
	
func _world_point(world : Vector3) -> String:
	return "%0.2f,%0.2f,%0.2f" % [stepify(world.x,0.01),stepify(world.y,0.01),stepify(world.z,0.01)]

func _point_world(point : String) -> Vector3:
	var arr_v = point.rsplit(",")
	return Vector3(float(arr_v[0]),float(arr_v[1]),float(arr_v[2]))
	
func _create_key(id1 : int, id2 : int) -> String:
	return "%d;%d"%[id1,id2]
