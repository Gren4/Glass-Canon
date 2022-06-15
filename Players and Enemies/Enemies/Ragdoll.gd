extends Spatial
export (NodePath) var skeleton_path = null
export (NodePath) var impulse_path = null
export (Dictionary) var mesh_path = null
onready var Dis : float = 2.0
onready var Alb : float = 1.0
onready var skeleton = get_node(skeleton_path)
onready var impulse = get_node(impulse_path)
var mesh : Dictionary

var pose : Dictionary = {}
var set_dir : Vector3

func _ready() -> void:
	for m in mesh_path:
		mesh[m] = get_node(mesh_path[m])
	for i in pose.size():
		skeleton.set_bone_global_pose_override(i,pose[i],1)
	skeleton.physical_bones_start_simulation()
	impulse.apply_central_impulse(set_dir)

func _physics_process(delta : float) -> void:
	for m in mesh:
		if m == 0:
			mesh[m].material_override.set_shader_param("Diss",Dis)
		elif m == 1:
			mesh[m].material_override.set_shader_param("Alb",Alb)
			
	if Alb > 0.0:
		Alb -= delta/1.5
	else:
		Alb = 0.0
		
	if Dis > 0.0:
		Dis -= delta/1.5
	else:
		skeleton.physical_bones_stop_simulation()
		call_deferred("queue_free")

func set_dir(dir : Vector3) -> void:
	set_dir = dir

