extends MeshInstance

onready var lifetime: float = 5.0
onready var lifetime_delta: float = 1.0 / lifetime
var cur_transparency: float = 1.0

func _process(delta):
	if cur_transparency > 0.0:
		var color : Color = Color(1.0,1.0,1.0,cur_transparency)
		self.get_surface_material(0).set_albedo(color)
		cur_transparency -= lifetime_delta*delta
	else:
		visible = false
