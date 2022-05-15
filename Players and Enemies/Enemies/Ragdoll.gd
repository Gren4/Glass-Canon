extends Spatial
export (NodePath) var skeleton_path = null
export (NodePath) var impulse_path = null
export (NodePath) var mesh_path = null
onready var Dis : float = 3.0
onready var skeleton = get_node(skeleton_path)
onready var impulse = get_node(impulse_path)
onready var mesh = get_node(mesh_path)

var pose : Dictionary = {}
var set_dir : Vector3

func _ready() -> void:
	for i in pose.size():
		skeleton.set_bone_global_pose_override(i,pose[i],1)
	skeleton.physical_bones_start_simulation()
	impulse.apply_central_impulse(set_dir)

func _physics_process(delta : float) -> void:
	if Dis > 0.0:
		mesh.material_override.set_shader_param("Diss",Dis)
		Dis -= delta/1.5
	else:
		skeleton.physical_bones_stop_simulation()
		call_deferred("queue_free")

func set_dir(dir : Vector3) -> void:
	set_dir = dir

