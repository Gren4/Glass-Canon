extends Spatial

export(int) var numFrames: int = 10  # The number of frames to display all materials
export(int) var layers_to_process: int = 2

signal allShadersCompiled  # This signal is emitted when the node frees itself (i.e., all materials are compiled)

var _counter: int = -1
var _foundMaterials: Dictionary = {}
var _foundParticles: Dictionary = {}
var _allMeshesDisplayed: bool = false
var _visible_layer : int = 0
var curr_layer = null
var iter : int = 0 


func _ready():
	connect("allShadersCompiled", owner.owner, "all_loaded")


func _process(_delta: float) -> void:
	if iter != layers_to_process - 1:
		if is_instance_valid(curr_layer):
			if curr_layer.is_queued_for_deletion():
				return
		
		if _counter == numFrames:
			_counter = -1
			iter += 1
			curr_layer.queue_free()
			return
		if _counter == -1:
			_visible_layer = iter
			curr_layer = Spatial.new()
			self.add_child(curr_layer)
			if not _foundMaterials.has(_visible_layer):
				_foundMaterials[_visible_layer] = []
			if not _foundParticles.has(_visible_layer):
				_foundParticles[_visible_layer] = []
			_recursive_get_materials(get_tree().root)
			_counter = 0
		else:
			_counter += 1
			
		_rotate_children()
	
	if iter == layers_to_process - 1:
		queue_free()
		emit_signal("allShadersCompiled")


func _recursive_get_materials(node: Node) -> void:
	for child in node.get_children():
		if child is MeshInstance:	
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
	newMesh.set_layer_mask_bit(0, _visible_layer == 0)
	newMesh.set_layer_mask_bit(_visible_layer, true)
	
	curr_layer.add_child(newMesh)
	newMesh.set_owner(curr_layer)
	
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
	var particle_pass = particle.process_material
	if is_instance_valid(particle_pass):
		proc_mat.set_process_material(particle_pass)
		var proc_mat_pass = proc_mat.process_material
		particle_pass = particle_pass.get_next_pass()
		while particle_pass:
			proc_mat_pass = particle_pass
			proc_mat_pass.set_gravity(Vector3.ZERO)
			particle_pass = particle_pass.get_next_pass()
			proc_mat_pass = proc_mat_pass.get_next_pass()
	proc_mat.set_layer_mask_bit(0, _visible_layer == 0)
	proc_mat.set_layer_mask_bit(_visible_layer, true)
	proc_mat.emitting = true
	proc_mat.one_shot = false
	var num_passes = particle.draw_passes
	proc_mat.set_draw_passes(num_passes)
	for i in num_passes:
		proc_mat.set_draw_pass_mesh(i,particle.get_draw_pass_mesh(i))
	proc_mat.set_material_override(particle.get_material_override())
	curr_layer.add_child(proc_mat)
	proc_mat.set_owner(curr_layer)
	
	proc_mat.global_transform.origin.x += randf() - 0.5
	proc_mat.global_transform.origin.x += randf() / 2 - 0.25
	proc_mat.global_transform.origin.z += randf() - 0.5


func _rotate_children() -> void:
	for child in curr_layer.get_children():
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
