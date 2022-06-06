extends Spatial
class_name NavLinkAstarPath

export (NodePath) var One_path = null
var One : Position3D
export (NodePath) var Two_path = null
var Two : Position3D

func _enter_tree():
	One = get_node(One_path)
	Two = get_node(Two_path)
