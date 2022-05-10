tool
extends Spatial

export (NodePath) var who = null
export (NodePath) var to = null

onready var who_ = get_node(who)
onready var to_ = get_node(to)

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	set_physics_process(true)
	pass # Replace with function body.

func _physics_process(delta):
	who_.global_transform.origin = to_.global_transform.origin
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
