extends Particles

onready var lifetime_delta: float = 1.0 / lifetime
var cur_transparency: float = 1.0

func _process(delta):
	if cur_transparency > 0.0:
		var color : Color = Color(1.0,1.0,1.0,cur_transparency)
		self.process_material.set_color(color)
		cur_transparency -= lifetime_delta*delta
