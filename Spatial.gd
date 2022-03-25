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
	
func draw_start(start,end):
	tek = start
	pos_start = start
	pos_end = end
	draw(start,end)
	set_physics_process(true)
	
func draw(start,end):

	var AB = end - start;
	var ort1 = AB.cross(Vector3.UP).normalized()*0.025;
	var ort2 = AB.cross(ort1).normalized()*0.025;
	
	var start1p = start+ort1
	var start2p = start+ort2
	var start1m = start-ort1
	var start2m = start-ort2
	
	var end1p = end+ort1
	var end2p = end+ort2
	var end1m = end-ort1
	var end2m = end-ort2
	
	clear()
	begin(Mesh.PRIMITIVE_TRIANGLES)
	#1
	add_vertex(start1p)
	add_vertex(start2p)
	add_vertex(end1p)

	add_vertex(end1p)
	add_vertex(end2p)
	add_vertex(start2p)
	#2
	add_vertex(start1m)
	add_vertex(start2p)
	add_vertex(end1m)

	add_vertex(end1m)
	add_vertex(end2p)
	add_vertex(start2p)
	#3
	add_vertex(start1p)
	add_vertex(start2m)
	add_vertex(end1p)

	add_vertex(end1p)
	add_vertex(end2m)
	add_vertex(start2m)
	#4
	add_vertex(start1m)
	add_vertex(start2m)
	add_vertex(end1m)

	add_vertex(end1m)
	add_vertex(end2m)
	add_vertex(start2m)
	
	end()
