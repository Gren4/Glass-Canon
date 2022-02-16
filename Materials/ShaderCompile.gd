#https://github.com/webnetweaver/Godot_shadercompile/blob/main/shaderCompile.gd
# НЕ ИСПОЛЬЗУЕТСЯ
extends Node

export(int) var verticalDisplacement = 2
export(int) var existFrames = 2
var instances: Array
var meshInst: MeshInstance
var meshInstSurfaceCount: int
var mesh: Mesh
var meshSurfaceCount: int
var processCount = 0
var meshParticles: Particles

func _ready():
	set_process(false)
	#print(get_tree().current_scene)
	#get_tree().current_scene.connect("ready", self, "compileShaders")
	#if existFrames <= 0:
	#	set_process(false)
	
func _process(_delta):
	processCount += 1
	if processCount > existFrames:
		var quadMeshes = get_tree().get_nodes_in_group("compiledShaders")
		for quadMeshInst in quadMeshes:
			quadMeshInst.visible = false
		set_process(false)

func compileShaders():
	instances = get_tree().get_nodes_in_group("materials")
	if instances.size() > 0:
		for instance in instances:
			if instance is MeshInstance:
				meshInst = instance as MeshInstance
				setupShaderCompile(meshInst.material_override)
				meshInstSurfaceCount = meshInst.get_surface_material_count()
				if meshInstSurfaceCount > 0:
					for index in range(0, meshInstSurfaceCount):
						setupShaderCompile(meshInst.get_surface_material(index))
				mesh = meshInst.mesh
				
				meshSurfaceCount = mesh.get_surface_count()
				if meshSurfaceCount > 0:
					for index in range(0, meshSurfaceCount):
						setupShaderCompile(mesh.surface_get_material(index))
			elif instance is Particles:
				meshParticles = instance as Particles
				setupShaderCompile(meshParticles.process_material)
				var num_passes = meshParticles.draw_passes
				setupShaderCompile(meshParticles.draw_pass_1.material)
				if num_passes > 1:
					setupShaderCompile(meshParticles.draw_pass_2.material)
					if num_passes > 2:
						setupShaderCompile(meshParticles.draw_pass_3.material)
						if num_passes > 3:
							setupShaderCompile(meshParticles.draw_pass_4.material)

func setupShaderCompile(material: Material):
	if material:
		while material:
			compileShader(material)
			material = material.get_next_pass()
		
func compileShader(material):
	var quadMesh: QuadMesh
	quadMesh = QuadMesh.new()
	quadMesh.material = material
	var mi: MeshInstance
	mi = MeshInstance.new()
	mi.mesh = quadMesh
	for n in 20:
		mi.set_layer_mask_bit(n,true)
	mi.cast_shadow = false
	mi.add_to_group("compiledShaders")
	get_parent().add_child(mi)
	mi.global_transform.origin.z = -1*verticalDisplacement


