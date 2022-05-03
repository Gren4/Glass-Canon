tool
extends Spatial

export(NodePath) var skeleton_path setget _set_skeleton_path
export(String) var bone_name = ""
export(int, "_process", "_physics_process", "none") var update_mode = 0 setget _set_update
export(int, "X-up", "Y-up", "Z-up") var look_at_axis = 1
export(float, 0.0, 1.0, 0.001) var interpolation = 1.0
export(bool) var use_our_rotation_x = false
export(bool) var use_our_rotation_y = false
export(bool) var use_our_rotation_z = false
export(bool) var use_negative_our_rot = false
export(Vector3) var additional_rotation = Vector3()
export(bool) var position_using_additional_bone = false
export(String) var additional_bone_name = ""
export(float) var additional_bone_length = 1
export(bool) var debug_messages = false

var skeleton_to_use: Skeleton = null
var first_call: bool = true
var _editor_indicator: Spatial = null

var target : Vector3 = Vector3.ZERO

var old_transform : Transform

func _ready() -> void:
	set_process(false)
	set_physics_process(false)
	set_notify_transform(false)

	if update_mode == 0:
		set_process(true)
	elif update_mode == 1:
		set_physics_process(true)
	elif update_mode == 2:
		set_notify_transform(true)
	else:
		if debug_messages:
			print(name, " - IK_LookAt: Unknown update mode. NOT updating skeleton")

	#if Engine.editor_hint:
		#_setup_for_editor()


func _process(delta : float) -> void:
	update_skeleton(delta)


func _physics_process(delta : float) -> void:
	update_skeleton(delta)

func update_skeleton(delta : float) -> void:
	# NOTE: Because get_node doesn't work in _ready, we need to skip
	# a call before doing anything.
	if first_call:
		first_call = false
		if skeleton_to_use == null:
			_set_skeleton_path(skeleton_path)


	# If we do not have a skeleton and/or we're not supposed to update, then return.
	if skeleton_to_use == null:
		return
	if update_mode >= 3:
		return

	# Get the bone index.
	var bone: int = skeleton_to_use.find_bone(bone_name)

	# If no bone is found (-1), then return and optionally printan error.
	if bone == -1:
		if debug_messages:
			print(name, " - IK_LookAt: No bone in skeleton found with name [", bone_name, "]!")
		return

	#var rest = skeleton_to_use.get_bone_custom_pose(bone)
	var inverse_rest = skeleton_to_use.get_bone_rest(bone).affine_inverse()
	var global_pose = skeleton_to_use.get_bone_global_pose(bone)
	
	if (old_transform != global_pose):
		#var global_pose_original = global_pose
		#var custom = skeleton_to_use.get_bone_custom_pose(bone)#.affine_inverse()
		var parent = skeleton_to_use.get_bone_parent(bone)
		var inverse_parent_global = skeleton_to_use.get_bone_global_pose(parent).affine_inverse()
		var inverse_pose = skeleton_to_use.get_bone_pose(bone).affine_inverse()
		
		var target_pos = skeleton_to_use.global_transform.xform_inv(global_transform.origin)
		target = lerp(target,target_pos,0.05)
		#var target_pos = global_transform.origin
		#target_pos.y *= -1
		global_pose = global_pose.looking_at(target, Vector3.UP)
	#	var wtransform = custom.looking_at(target_pos,Vector3.UP)
	#	var wrotation = Quat(custom.basis).slerp(Quat(wtransform.basis), 15 * delta)
	#	custom = Transform(Basis(wrotation), custom.origin)
	#	var m11 = global_pose.basis.x[0]*global_pose_original.basis.x[0] + global_pose.basis.x[1]*global_pose_original.basis.y[0] + global_pose.basis.x[2]*global_pose_original.basis.z[0]
	#	var m12 = global_pose.basis.x[0]*global_pose_original.basis.x[1] + global_pose.basis.x[1]*global_pose_original.basis.y[1] + global_pose.basis.x[2]*global_pose_original.basis.z[1]
	#	var m13 = global_pose.basis.x[0]*global_pose_original.basis.x[2] + global_pose.basis.x[1]*global_pose_original.basis.y[2] + global_pose.basis.x[2]*global_pose_original.basis.z[2]
	#
	#	var m21 = global_pose.basis.y[0]*global_pose_original.basis.x[0] + global_pose.basis.y[1]*global_pose_original.basis.y[0] + global_pose.basis.y[2]*global_pose_original.basis.z[0]
	#	var m22 = global_pose.basis.y[0]*global_pose_original.basis.x[1] + global_pose.basis.y[1]*global_pose_original.basis.y[1] + global_pose.basis.y[2]*global_pose_original.basis.z[1]
	#	var m23 = global_pose.basis.y[0]*global_pose_original.basis.x[2] + global_pose.basis.y[1]*global_pose_original.basis.y[2] + global_pose.basis.y[2]*global_pose_original.basis.z[2]
	#
	#	var m31 = global_pose.basis.z[0]*global_pose_original.basis.x[0] + global_pose.basis.z[1]*global_pose_original.basis.y[0] + global_pose.basis.z[2]*global_pose_original.basis.z[0]
	#	var m32 = global_pose.basis.z[0]*global_pose_original.basis.x[1] + global_pose.basis.z[1]*global_pose_original.basis.y[1] + global_pose.basis.z[2]*global_pose_original.basis.z[1]
	#	var m33 = global_pose.basis.z[0]*global_pose_original.basis.x[2] + global_pose.basis.z[1]*global_pose_original.basis.y[2] + global_pose.basis.z[2]*global_pose_original.basis.z[2]
	#
	#	global_pose.basis = Basis(Vector3(m11,m12,m13),Vector3(m21,m22,m23),Vector3(m31,m32,m33))

		#
		#var rest_euler = global_pose.basis.get_euler()
		#global_pose.basis = Basis(rest_euler)	
		if additional_rotation != Vector3.ZERO:
			global_pose.basis = global_pose.basis.rotated(global_pose.basis.x, deg2rad(additional_rotation.x))
			global_pose.basis = global_pose.basis.rotated(global_pose.basis.y, deg2rad(additional_rotation.y))
			global_pose.basis = global_pose.basis.rotated(global_pose.basis.z, deg2rad(additional_rotation.z))
		var x = inverse_rest * inverse_parent_global * global_pose * inverse_pose
		
		skeleton_to_use.set_bone_custom_pose(bone, x)
		
		old_transform = x


func _set_update(new_value : int) -> void:
	update_mode = new_value

	# Set all of our processes to false.
	set_process(false)
	set_physics_process(false)
	set_notify_transform(false)

	# Based on the value of passed to update, enable the correct process.
	if update_mode == 0:
		set_process(true)
		if debug_messages:
			print(name, " - IK_LookAt: updating skeleton using _process...")
	elif update_mode == 1:
		set_physics_process(true)
		if debug_messages:
			print(name, " - IK_LookAt: updating skeleton using _physics_process...")
	elif update_mode == 2:
		set_notify_transform(true)
		if debug_messages:
			print(name, " - IK_LookAt: updating skeleton using _notification...")
	else:
		if debug_messages:
			print(name, " - IK_LookAt: NOT updating skeleton due to unknown update method...")


func _set_skeleton_path(new_value) -> void:
	# Because get_node doesn't work in the first call, we just want to assign instead.
	# This is to get around a issue with NodePaths exposed to the editor.
	if first_call:
		skeleton_path = new_value
		return

	# Assign skeleton_path to whatever value is passed.
	skeleton_path = new_value

	if skeleton_path == null:
		if debug_messages:
			print(name, " - IK_LookAt: No Nodepath selected for skeleton_path!")
		return

	# Get the node at that location, if there is one.
	var temp = get_node(skeleton_path)
	if temp != null:
		if temp is Skeleton:
			skeleton_to_use = temp
			if debug_messages:
				print(name, " - IK_LookAt: attached to (new) skeleton")
		else:
			skeleton_to_use = null
			if debug_messages:
				print(name, " - IK_LookAt: skeleton_path does not point to a skeleton!")
	else:
		if debug_messages:
			print(name, " - IK_LookAt: No Nodepath selected for skeleton_path!")
