extends Navigation

class_name NavLinkAstar

export (bool) var generate_nav = true

export (NodePath) var NavLink_path = null
onready var NavLink = get_node(NavLink_path)

export (NodePath) var NavMesh_path = null
onready var NavMeshInstance = get_node(NavMesh_path)
onready var NavMesh = NavMeshInstance.navmesh

class NavLinkAstarData:
	var astar : AStar
	var Points4Astart : Dictionary = {}
	var Links : Dictionary = {}
	var LinksPath : Dictionary = {}

var NavD : NavLinkAstarData

class CenterPoly:
	var astar_id : int
	var island_id : int
	var pos : Vector3
	var verts : Array

class Island:
	var verts : Array
	var polys : Array
	
class Doubles:
	var d_size : int = 0
	var doubles : Array = []

func _ready():
	if generate_nav == true:
		NavD = NavLinkAstarData.new()
		_generate_astar_points()
	pass
	
#func _physics_process(delta):
#	if Input.is_action_just_pressed("ui_focus_next"):
#		var time1 = OS.get_system_time_msecs()
#		(get_path_links(($Start.global_transform.origin), ($End.global_transform.origin)))
#		print(OS.get_system_time_msecs() - time1)
#	pass
	
func get_path_links(from: Vector3, to: Vector3) -> Dictionary:
	from = get_closest_point(from)
	to = get_closest_point(to)
	var path : PoolVector3Array = []
	var type : int = 0
	var link_from : PoolVector3Array = []
	var link_to : PoolVector3Array = []
	var a_path : PoolVector3Array = _find_path(from, to)
	var size_a = a_path.size()
	var link_from_strings : PoolStringArray = []
	var link_to_strings : PoolStringArray = []
	
	for i in range(size_a):
		var pw : String = _world_point(a_path[i])
		if (NavD.Links.has(pw)):
			for j in range(i+1,size_a):
				if (_world_point(a_path[j]) == NavD.Links[pw]):
					link_from.append(a_path[i])
					link_to.append(a_path[j])
					link_from_strings.append(_world_point(a_path[i]))
					link_to_strings.append(_world_point(a_path[j]))
					break

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
					var key : String = _create_key(link_to_strings[i],link_from_strings[i+1])
					path.append_array(NavD.LinksPath[key])
					path.append(link_to[i+1])
				path.append_array(get_simple_path(link_to[lt_c-1],to))

	return {
		"type": type,
		"path": path,
		"from": link_from,
		"to": link_to
	}

func _find_path(from: Vector3, to: Vector3) -> PoolVector3Array:
	var start_id = NavD.astar.get_closest_point(from)
	var end_id = NavD.astar.get_closest_point(to)
	return NavD.astar.get_point_path(start_id, end_id)
	
func _form_precalculated_links_paths() -> void:
	for i in NavD.Links:
		var V_i : Vector3 = _point_world(i)
		for j in NavD.Links:
			if i == j or NavD.Links[i] == j or NavD.LinksPath.has(_create_key(i,j)):
				continue
			else:
				var V_j : Vector3 = _point_world(j)
				var path : PoolVector3Array = get_simple_path(get_closest_point(V_i), get_closest_point(V_j))
				if path.size() > 0:
					NavD.LinksPath[_create_key(i,j)] = path
	return
	
func _add_links_to_astar(var Points : Dictionary) -> void:
	var nav_link_group = NavLink.get_children()
	for p in nav_link_group:
		if p is NavLinkAstarPath:
			var one : Vector3 = get_closest_point(p.One.global_transform.origin)
			var two : Vector3 = get_closest_point(p.Two.global_transform.origin)
			if (not _world_point(one) in NavD.Links) and (not _world_point(two) in NavD.Links):
				NavD.Links[_world_point(one)] = _world_point(two)
				NavD.Links[_world_point(two)] = _world_point(one)
				var a_id1 = NavD.astar.get_available_point_id()
				NavD.astar.add_point(a_id1, one)
				var a_id2 = NavD.astar.get_available_point_id()
				NavD.astar.add_point(a_id2, two)
				if not NavD.astar.are_points_connected(a_id1, a_id2):
					NavD.astar.connect_points(a_id1, a_id2)
				
				# Search for nearest polygon to connect
				var d1 : float = 1e20
				var i1 : int
				var d2 : float = 1e20
				var i2 : int
				for d in NavD.Points4Astart:
					var new_d1 : float = (NavD.Points4Astart[d].pos - one).length()
					if (new_d1 < d1):
						d1 = new_d1
						i1 = d
					var new_d2 : float = (NavD.Points4Astart[d].pos - two).length()
					if (new_d2 < d2):
						d2 = new_d2
						i2 = d
				if not NavD.astar.are_points_connected(a_id1, NavD.Points4Astart[i1].astar_id):
					NavD.astar.connect_points(a_id1, NavD.Points4Astart[i1].astar_id)
				
				if not NavD.astar.are_points_connected(a_id2, NavD.Points4Astart[i2].astar_id):
					NavD.astar.connect_points(a_id2, NavD.Points4Astart[i2].astar_id)
					
	_form_precalculated_links_paths()
	return
	
	
func _generate_astar_points() -> void:
	var islands : Dictionary = {}
	var it : int = 0
	var doubles : Array = []
	var all_vert : PoolVector3Array = NavMesh.get_vertices()
	
	NavD.astar = AStar.new()
	
	for i in range(all_vert.size()):
		doubles.append(Doubles.new())
		for j in range(all_vert.size()):
			if i == j:
				continue
			else:
				if all_vert[i].is_equal_approx(all_vert[j]):
					doubles[i].d_size += 1
					doubles[i].doubles.append(j)
					
	for i in range(NavMesh.get_polygon_count()):
			var index_arr : Array = NavMesh.get_polygon(i)
			var col_v : int = index_arr.size()
			var no_parent = true
			for r in islands:
				var no_coll : bool = true
				
				for j in col_v:
					if index_arr[j] in islands[r].verts:
						no_coll = false
						
				if not no_coll:
					no_parent = false
					islands[r].polys.append(i)
					for j in col_v:
						if not index_arr[j] in islands[r].verts:
							islands[r].verts.append(index_arr[j])
						
							if doubles[index_arr[j]].d_size > 0:
								for k in range(doubles[index_arr[j]].d_size):
									if not doubles[index_arr[j]].doubles[k] in islands[r].verts:
										islands[r].verts.append(doubles[index_arr[j]].doubles[k])
			if no_parent:
				islands[it] = Island.new()
				islands[it].polys.append(i)
				
				for j in col_v:
					islands[it].verts.append(index_arr[j])
					if doubles[index_arr[j]].d_size > 0:
						for k in range(doubles[index_arr[j]].d_size):
							if not doubles[index_arr[j]].doubles[k] in islands[it].verts:
								islands[it].verts.append(doubles[index_arr[j]].doubles[k])
				it+=1
				
	var exclude = []
	for i in islands.size():
		if i in exclude:
			continue
		for j in islands.size():
			if i == j or j in exclude:
				continue
			else:
				var no_col = true
				for k in islands[i].verts:
					if k in islands[j].verts:
						no_col = false
				if not no_col:
					exclude.append(j)
					for k in islands[j].verts: 
						if not k in islands[i].verts:
							islands[i].verts.append(k)
					for k in islands[j].polys: 
						if not k in islands[i].polys:
							islands[i].polys.append(k)
					islands.erase(j)
	
	var island_id : int = 0
	var keys = islands.keys()
	for d in keys:
		for i in range(islands[d].polys.size()):
			var p_i : int = islands[d].polys[i]
			NavD.Points4Astart[p_i] = CenterPoly.new()
			NavD.Points4Astart[p_i].island_id = island_id
			var index_arr : Array = NavMesh.get_polygon(p_i)
			var col_v : int = index_arr.size()
			var center : Vector3 = Vector3.ZERO
			for j in col_v:
				NavD.Points4Astart[p_i].verts.append(index_arr[j])
				center += all_vert[index_arr[j]]
				if doubles[index_arr[j]].d_size > 0:
						for k in range(doubles[index_arr[j]].d_size):
							if not doubles[index_arr[j]].doubles[k] in NavD.Points4Astart[p_i].verts:
								NavD.Points4Astart[p_i].verts.append(doubles[index_arr[j]].doubles[k])
			center = center / col_v
			NavD.Points4Astart[p_i].pos = center
			var a_id = NavD.astar.get_available_point_id()
			NavD.astar.add_point(a_id, center)
			NavD.Points4Astart[p_i].astar_id = a_id
		island_id += 1
		
	var po = NavD.Points4Astart.keys()
	for i in range(island_id):
		for j1 in po:
			if NavD.Points4Astart[j1].island_id == i:
				for j2 in po:
					if j1 == j2:
						continue
					else:
						if not NavD.Points4Astart[j2].island_id == i:
							continue
						else:
							var is_neighboor : bool = false
							for v1 in range(NavD.Points4Astart[j1].verts.size()):
								for v2 in range(NavD.Points4Astart[j2].verts.size()):
									if NavD.Points4Astart[j1].verts[v1] == NavD.Points4Astart[j2].verts[v2]:
										is_neighboor = true
										break
								if is_neighboor == true:
									break
							if is_neighboor == true:
								if not NavD.astar.are_points_connected(NavD.Points4Astart[j1].astar_id, NavD.Points4Astart[j2].astar_id):
									NavD.astar.connect_points(NavD.Points4Astart[j1].astar_id, NavD.Points4Astart[j2].astar_id)
	
	_add_links_to_astar(NavD.Points4Astart)
	pass
	
func _world_point(world : Vector3) -> String:
	return "%0.2f,%0.2f,%0.2f" % [stepify(world.x,0.01),stepify(world.y,0.01),stepify(world.z,0.01)]

func _point_world(point : String) -> Vector3:
	var arr_v = point.rsplit(",")
	return Vector3(float(arr_v[0]),float(arr_v[1]),float(arr_v[2]))
	
func _create_key(from : String, to : String) -> String:
	return from + ";" + to
