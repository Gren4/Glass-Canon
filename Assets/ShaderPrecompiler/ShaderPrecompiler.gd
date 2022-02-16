extends Spatial

export var numFrames: int = 10  # The number of frames to display all materials

signal allShadersCompiled  # This signal is emitted when the node frees itself (i.e., all materials are compiled)

var _counter: int = 0
var mat0 : Array
var mat1 : Array
var mat2 : Array
var mat3 : Array
var mat4 : Array
var mat5 : Array
var mat6 : Array
var mat7 : Array
var mat8 : Array
var mat9 : Array
var mat10 : Array
var mat11 : Array
var mat12 : Array
var mat13 : Array
var mat14 : Array
var mat15 : Array
var mat16 : Array
var mat17 : Array
var mat18 : Array
var mat19 : Array
var _foundMaterials: Dictionary = {
	0: mat0,
	1: mat1,
	2: mat2,
	3: mat3,
	4: mat4,
	5: mat5,
	6: mat6,
	7: mat7,
	8: mat8,
	9: mat9,
	10: mat10,
	11: mat11,
	12: mat12,
	13: mat13,
	14: mat14,
	15: mat15,
	16: mat16,
	17: mat17,
	18: mat18,
	19: mat19
}
var part0 : Array
var part1 : Array
var part2 : Array
var part3 : Array
var part4 : Array
var part5 : Array
var part6 : Array
var part7 : Array
var part8 : Array
var part9 : Array
var part10 : Array
var part11 : Array
var part12 : Array
var part13 : Array
var part14 : Array
var part15 : Array
var part16 : Array
var part17 : Array
var part18 : Array
var part19 : Array
var _foundParticles: Dictionary = {
	0: part0,
	1: part1,
	2: part2,
	3: part3,
	4: part4,
	5: part5,
	6: part6,
	7: part7,
	8: part8,
	9: part9,
	10: part10,
	11: part11,
	12: part12,
	13: part13,
	14: part14,
	15: part15,
	16: part16,
	17: part17,
	18: part18,
	19: part19
}
var _allMeshesDisplayed: bool = false
var _visible_layer : int = 0

func _ready():
	connect("allShadersCompiled", owner.owner, "all_loaded")
	for i in range(0,20):
		if get_parent().get_cull_mask_bit(i):
			_visible_layer = i
			_recursive_get_materials(get_tree().root)


func _process(_delta: float) -> void:
	_rotate_children()
	
	_counter += 1
	if _counter == numFrames:
		queue_free()
		emit_signal("allShadersCompiled")


func _recursive_get_materials(node: Node) -> void:
	for child in node.get_children():
		if child is MeshInstance:
			if child.get_layer_mask_bit(_visible_layer):	
				var mesh: MeshInstance = child as MeshInstance
				#################################
				_setup_material(mesh.material_override)
				#################################
				for i in range(mesh.get_surface_material_count()):
					var mat: Material = mesh.get_surface_material(i)
					if not is_instance_valid(mat):
						mat = mesh.mesh.surface_get_material(i)
					_setup_material(mat)
				#################################
				var m_inst = mesh.mesh
				for i in range(m_inst.get_surface_count()):
					_setup_material(m_inst.surface_get_material(i))
		if child is Particles:
			if child.get_layer_mask_bit(_visible_layer):	
				var part: Particles = child as Particles
				_setup_particle(part)
					
		_recursive_get_materials(child)

func _setup_material(mat : Material):
	if is_instance_valid(mat):
		while mat:
			if not mat in _foundMaterials.get(_visible_layer):
				_add_material(mat)
				_foundMaterials.get(_visible_layer).append(mat)
			mat = mat.get_next_pass()


func _add_material(material: Material) -> void:
	var quad: QuadMesh = QuadMesh.new()
	var newMesh: MeshInstance = MeshInstance.new()
	newMesh.mesh = quad
	newMesh.set_surface_material(0, material)
	newMesh.set_layer_mask_bit(_visible_layer, true)
	
	add_child(newMesh)
	newMesh.set_owner(self)
	
	newMesh.global_transform.origin.x += randf() - 0.5
	newMesh.global_transform.origin.x += randf()/2 - 0.25
	newMesh.global_transform.origin.z += randf() - 0.5

func _setup_particle(part : Particles):
	if is_instance_valid(part):
		if not part in _foundParticles.get(_visible_layer):
			_add_particle(part)
			_foundParticles.get(_visible_layer).append(part)

func _add_particle(particle: Particles) -> void:
	var proc_mat : Particles = Particles.new()
	proc_mat.set_process_material(particle.process_material)
	proc_mat.set_layer_mask_bit(_visible_layer, true)
	proc_mat.emitting = true
	proc_mat.one_shot = false
	proc_mat.process_material.set_gravity(Vector3.ZERO)
	var num_passes = particle.draw_passes
	proc_mat.set_draw_passes(num_passes)
	for i in num_passes:
		#_set_draw_passes(proc_mat,particle,i)
		proc_mat.set_draw_pass_mesh(i,particle.get_draw_pass_mesh(i))
	add_child(proc_mat)
	proc_mat.set_owner(self)
	
	proc_mat.global_transform.origin.x += randf() - 0.5
	proc_mat.global_transform.origin.x += randf()/2 - 0.25
	proc_mat.global_transform.origin.z += randf() - 0.5

#func _set_draw_passes(to_particle : Particles, particle: Particles, i : int) -> void:
#	var quad: QuadMesh = QuadMesh.new()
#	quad.surface_set_material(0,particle.get_draw_pass_mesh(i).surface_get_material(0))
#	for i2 in range(particle.get_draw_pass_mesh(i).get_surface_count()):
#		pass#_setup_material(particle.get_draw_pass_mesh(i).surface_get_material(i2))
#	to_particle.set_draw_pass_mesh(i,quad)
#	to_particle.set_draw_pass_mesh(i,particle.get_draw_pass_mesh(i))


func _rotate_children() -> void:
	for child in get_children():
		if child is MeshInstance:
			var mesh: MeshInstance = child as MeshInstance
			mesh.rotate_x(randf() * 0.2)
			mesh.rotate_y(randf() * -0.3)
			mesh.rotate_z(randf() * 0.1)
		elif child is Particles:
			var part: Particles = child as Particles
			part.rotate_x(randf() * 0.2)
			part.rotate_y(randf() * -0.3)
			part.rotate_z(randf() * 0.1)
