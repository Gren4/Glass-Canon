extends ImmediateGeometry

var pos_start : Vector3 = Vector3(0, 0, 0)
var tek : Vector3 = Vector3(0, 0, 0)
var pos_end : Vector3 = Vector3(0, 0, 10)
export(int) var speed = 10


func _ready():
	draw_start(pos_start,pos_end)
	pass
	
func _physics_process(delta):
	if (tek.distance_to(pos_end) > 0.5):
		tek = tek.linear_interpolate(pos_end,speed*delta)
		draw(tek,pos_end)
	else:
		draw(pos_end,pos_end)
		set_physics_process(false)
	pass
func draw_start(start,end):
	tek = start
	pos_start = start
	pos_end = end
	draw(start,end)
	set_physics_process(true)
func draw(start,end):
	clear()
	begin(Mesh.PRIMITIVE_LINE_STRIP)
	add_vertex(start)
	add_vertex(end)
	end()
