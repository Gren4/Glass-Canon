extends Spatial

export(NodePath) var player_path = null
onready var player = get_node(player_path)
onready var skeleton = 

func _ready():
	pass

func _physics_process(delta):
	face_threat(15,20,delta,player.global_transform.origin)

func face_threat(d1,d2,delta,offset_ = Vector3.ZERO):
	#torso.look_at(offset_, Vector3.UP)
	#Global.look_face($Armature/Skeleton/TorsoBone, offset_, d1, delta)
	#Global.turn_face(torso, offset_, d2, delta)
	pass
