extends Spatial

export(NodePath) var animation_tree_path
export(NodePath) var right_hand_path
export(NodePath) var left_hand_path

onready var animation_tree = get_node(animation_tree_path)
onready var right_hand = get_node(right_hand_path)
onready var left_hand = get_node(left_hand_path)



func _ready():
	pass

func set_right_hand(target):
	right_hand.stop()
	right_hand.target_node = target
	right_hand.start()
	pass
	
func set_left_hand(target):
	left_hand.stop()
	left_hand.target_node = target 
	left_hand.start()
	pass
