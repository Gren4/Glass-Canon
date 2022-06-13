extends Navigation

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
var astar_points : PoolVector3Array = []
var col_points : int = 0
var polygon : Dictionary = {}

var links_paths : Dictionary
var links_col : int = 0
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
	var start_id : int = 0
	var end_id : int = 0
	var start_d : float = 1e20
	var end_d : float = 1e20
	var one_stop : bool = false
	var two_stop : bool = false
	for d in range(polygon.size()):
		var vstart = Geometry.ray_intersects_triangle(from + Vector3(0,0.5,0), Vector3.DOWN,polygon[d]["verts"][0],polygon[d]["verts"][1],polygon[d]["verts"][2])
		if vstart != null and not one_stop:
			var d_temp : float = (vstart - from).length_squared()
			if (d_temp < start_d):
				start_id = polygon[d]["id"]
				start_d = d_temp
		for i in polygon[d]["verts"]:
			var d_temp : float = (i - from).length_squared()
			if (d_temp < start_d):
				start_id = polygon[d]["id"]
				start_d = d_temp
			
		var vend = Geometry.ray_intersects_triangle(to + Vector3(0,0.5,0), Vector3.DOWN,polygon[d]["verts"][0],polygon[d]["verts"][1],polygon[d]["verts"][2])
		if vend != null and not two_stop:
			var d_temp : float = (vend - to).length_squared()
			if (d_temp < end_d):
				end_id = polygon[d]["id"]
				end_d = d_temp
		for i in polygon[d]["verts"]:
			var d_temp : float = (i - to).length_squared()
			if (d_temp < end_d):
				end_id = polygon[d]["id"]
				end_d = d_temp

	return astar.get_point_path(start_id, end_id)
	
func _check_doubles(d : Dictionary, i : int) -> int:
	if d.has(i):
		return d[i]
	else:
		return i
	
func _generate_astar_points() -> void:
	var doubles : Dictionary = {} 
	var main_vert : PoolVector3Array = []
	var points_of_verts : Dictionary = {}
	
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
					
	for i in range(poly_count):
		var index_arr : Array = NavMesh.get_polygon(i)
		var a_id = astar.get_available_point_id()
		var center : Vector3 = Vector3.ZERO
		var col_v : int = index_arr.size()
		var verts : PoolVector3Array
		for a in range(col_v):
			var chck : int = _check_doubles(doubles, index_arr[a])
			verts.append(main_vert[chck])
			center += main_vert[chck]
			if points_of_verts.has(chck):
				points_of_verts[chck].append(a_id)
			else:
				points_of_verts[chck] = [a_id]
		polygon[i] = {"verts" : verts, "id" : a_id }
		center = center / col_v
		astar.add_point(a_id,center)
		astar_points.append(center)
		col_points += 1
		#_create_nav_cube(center,green_material)
		
		for a in range(col_v):
			var chck : int = _check_doubles(doubles, index_arr[a])
			if points_of_verts[chck].size() > 0:
				for j in range(points_of_verts[chck].size()):
					if not astar.are_points_connected(a_id, points_of_verts[chck][j]) and a_id != points_of_verts[chck][j]:
						astar.connect_points(a_id, points_of_verts[chck][j])
						
	var nav_link_group = NavLink.get_children()
	for p in nav_link_group:
		if p is NavLinkAstarPath:
			var one : Vector3 = p.One.global_transform.origin
			var two : Vector3 = p.Two.global_transform.origin
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
			
			var one_d : float = 1e20
			var one_id : int = 0
			var two_d : float = 1e20
			var two_id : int = 0
			for d in range(polygon.size()):
				var vone = Geometry.ray_intersects_triangle(one, Vector3.DOWN,polygon[d]["verts"][0],polygon[d]["verts"][1],polygon[d]["verts"][2])
				if vone != null:
					var d_temp : float = (vone - one).length_squared()
					if (d_temp < one_d):
						one_id = polygon[d]["id"]
						one_d = d_temp
				for i in polygon[d]["verts"]:
					var d_temp : float = (i - one).length_squared()
					if (d_temp < one_d):
						one_id = polygon[d]["id"]
						one_d = d_temp
				var vtwo = Geometry.ray_intersects_triangle(two, Vector3.DOWN,polygon[d]["verts"][0],polygon[d]["verts"][1],polygon[d]["verts"][2])
				if vtwo != null:
					var d_temp : float = (vtwo - two).length_squared()
					if (d_temp < two_d):
						two_id = polygon[d]["id"]
						two_d = d_temp
				for i in polygon[d]["verts"]:
					var d_temp : float = (i - two).length_squared()
					if (d_temp < two_d):
						two_id = polygon[d]["id"]
						two_d = d_temp
			if not astar.are_points_connected(a_id1,one_id):
				astar.connect_points(a_id1,one_id)
			if not astar.are_points_connected(a_id2,two_id):
				astar.connect_points(a_id2,two_id)

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
