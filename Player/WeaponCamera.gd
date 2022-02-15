extends Camera

export(NodePath) var main_cam_path
onready var main_cam = get_node(main_cam_path)

func _process(_delta):
	global_transform = main_cam.global_transform
	fov = main_cam.fov
