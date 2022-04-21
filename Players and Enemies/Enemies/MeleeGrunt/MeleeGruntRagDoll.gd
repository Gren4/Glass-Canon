extends Spatial
export (NodePath) var skeleton_path = null
onready var Dis : float = 3.0
onready var skeleton = get_node(skeleton_path)

var pose : Dictionary = {}

func _ready():
	for i in pose.size():
		skeleton.set_bone_global_pose_override(i,pose[i],1)
	skeleton.physical_bones_start_simulation()
	$"Body/Skeleton/Physical Bone MidTorso".apply_central_impulse(to_global(Vector3(randf()*200-100,0,80 +randf()*50)))
#	pass
#
func _physics_process(delta):
	if Dis > 0.0:
		$Body/Skeleton/Cube.material_override.set_shader_param("Diss",Dis)
		Dis -= delta
	else:
		skeleton.physical_bones_stop_simulation()
		call_deferred("queue_free")

