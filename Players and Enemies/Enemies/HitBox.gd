extends Area

export (NodePath) var parent_path = null
export var damage_koeff : float = 1.0

onready var parent = get_node(parent_path)

#func _ready():
#	var parent = get_parent()
#	print()
#	pass

func place_node(node) -> void:
	var place_holder : Spatial = parent.get_node("GlobalParticles")
	place_holder.add_child(node)

func hitbox_processing(damage : int, dir : Vector3) -> void:
	parent.update_hp(damage_koeff * damage, dir)
	pass
