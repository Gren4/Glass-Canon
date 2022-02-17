extends MeshInstance

var dist : Vector3 = Vector3.ZERO
var obj : Object = null
var lifetime: float = 1.0
var lifetime_delta: float = 1.0 / 1
var to_end : bool = false

func _ready():
	set_physics_process(false)

func _physics_process(delta):
		self.set_translation(obj.get_translation() - dist)

func _process(delta):
	free_scene(delta)

func free_scene(delta):
	#Удаляем частицы, которые заспавинили в основной ноде
	if to_end:
		if lifetime <= 0:
			queue_free()
		var _albedo = get_surface_material(0) as SpatialMaterial
		var color : Color = Color(1.0,1.0,1.0,lifetime)
		_albedo.set_albedo(color)
		lifetime -= lifetime_delta*delta
	else:
		set_process(false)
