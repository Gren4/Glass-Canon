extends Spatial
class_name NavLinkAstarPath

var One : Position3D
var Two : Position3D

func _enter_tree():
	One = $One
	Two = $Two
