extends Players_and_Enemies

class_name Enemies

export(NodePath) var animation_tree_path = null
export(NodePath) var area_detection_path = null
export(NodePath) var front_ray_path = null
export(NodePath) var right_ray_path = null
export(NodePath) var left_ray_path = null
export(NodePath) var right_down_ray_path = null
export(NodePath) var left_down_ray_path = null
export(NodePath) var audio_path
export(NodePath) var skeleton_path
export(NodePath) var target_look_path

export(PackedScene) var ragdoll = null

export var current_health : int = 1
export var attack_damage : int = 1

onready var audio = get_node(audio_path)
onready var animation_tree = get_node(animation_tree_path)
onready var area_detection = get_node(area_detection_path)
onready var  front_ray = get_node(front_ray_path)
onready var  right_ray = get_node(right_ray_path)
onready var  left_ray = get_node(left_ray_path)
onready var  right_down_ray = get_node(right_down_ray_path)
onready var  left_down_ray = get_node(left_down_ray_path)
onready var  skeleton = get_node(skeleton_path)
onready var  target_look = get_node(target_look_path)

onready var prev_origin : Vector3 = Vector3.ZERO
onready var space_state : PhysicsDirectSpaceState = get_world().direct_space_state
onready var player
onready var _state : int

onready var turn_angle = self.rotation_degrees.y

enum {
		RESET,
		IDLE, 
		IDLE_TURN, 
		LOOK_AT_ALLERT,
		ALLERTED_AND_DOESNT_KNOW_LOC, 
		ALLERTED_AND_KNOWS_LOC,
		ATTACK_MELEE,
		SHOOT,
		EVADE,
		AIR,
		JUMP,
		JUMP_END,
		DEATH
	}
	
var SPEED_AIR : float
var SPEED_DOP_ATTACK : float
var SPEED_DOP_EVADE : float
var SPEED_NORMAL : float
var SPEED_SIDE_STEP : float

var speed : float = 1.0
var jump_time_coeff : float = 0.7
var dop_speed : float = 0.0
var accel : float = 1.0
const gravity : float = 40.0
var is_on_floor : bool = false
var dist : Vector3 = Vector3.ZERO
var dist2D : Vector2 = Vector2.ZERO
var dist_length : float = 0.0
var dist2D_length : float = 0.0
var allerted : bool = false

var IDLE_TIMER : float = 1.0
var RESET_TIMER : float = 1.0
var ALLERTED_AND_KNOWS_LOC_TIMER: float = 1.0
var ALLERTED_AND_DOESNT_KNOW_LOC_TIMER : float = 1.0
var IDLE_TURN_TIMER : float = 1.0
var LOOK_AT_ALLERT_TIMER : float = 1.0
var ATTACK_CD_TIMER : float = 1.0
var NOT_IN_AIR_TIMER : float = 1.0

var timer_not_on_ground : float = 0.0
var _timer : float = 0.0
var _dop_timer : float = 0.0
var _attack_timer : float = 0.0
var _evade_timer : int = 3 + randi() % 2
var _path_timer : float = 0.0
var give_path : bool = true
var _stop_timer : float = 0.0
var side : int = 1
var no_collision_between : bool = false
var my_path = []
var link_from : PoolVector3Array = []
var link_to : PoolVector3Array = []
var start_jump_pos : Vector3 = Vector3.ZERO
var jump_time : float = 0.0
var p1 : Vector3 = Vector3.ZERO
var offset : Vector3 = Vector3.ZERO
var is_moving : bool = false
var attack_side : int = 0
var ragdoll_create : bool = true
var hit_confirm : bool = false

var death_dir : Vector3 = Vector3.ZERO

func _physics_process(delta : float) -> void:
	ai(delta)
	
func ai(delta : float) -> void:
	tact_init(delta)
	state_machine(delta)
	if _state != JUMP:
		finalize_velocity(delta)
	prev_origin = self.global_transform.origin
	
func allert_everyone() -> void:
	if _state < ALLERTED_AND_KNOWS_LOC:
		set_state(ALLERTED_AND_KNOWS_LOC)
		allerted = true

func tact_init(delta : float) -> void:
	dist = self.global_transform.origin - player.global_transform.origin
	dist2D = Vector2(dist.x,dist.z)
	dist_length = dist.length()
	dist2D_length = dist2D.length()
	is_on_floor = is_on_floor()
	
	if is_on_floor:
		speed = SPEED_NORMAL
		timer_not_on_ground = 0.0
		velocity.y = -0.1
		snap = Vector3.DOWN
	else:
		velocity.y -= gravity * delta
		speed = SPEED_AIR
		
func state_machine(delta : float) -> void:
	pass
	
func set_state(state : int) -> void:
	_timer = 0.0
	_dop_timer = 0.0
	_state = state
	
func finalize_velocity(delta : float) -> void:
	direction = direction.normalized()
	velocityXY = velocityXY.linear_interpolate(direction * (speed + dop_speed), accel * delta)
	velocity.x = velocityXY.x
	velocity.z = velocityXY.z
	var vel_inf = move_and_slide_with_snap(velocity, snap, Vector3.UP, not_on_moving_platform, 4, deg2rad(45))
	var info = (self.global_transform.origin - prev_origin)/delta
	var loc_v : Vector3 = (info/SPEED_NORMAL).rotated(Vector3.UP,-self.rotation.y)
	if loc_v.length_squared() < 0.15:
		is_moving = false
	else:
		is_moving = true
		
	var new_angle = turn_angle - self.rotation_degrees.y
	var do_turn : bool = false
	if abs(new_angle) > 10.0:
		turn_angle = self.rotation_degrees.y
		do_turn = true
		
	if velocity.length() < 1.0:
		animation_tree.set("parameters/Zero/current", 1)
		animation_tree.set("parameters/AudioMovement/blend_position", Vector2.ZERO)
		if do_turn:
			if new_angle < 0:
				if animation_tree.get("parameters/Turn/active") == false:
					animation_tree.set("parameters/TurnSide/current", 0)
					animation_tree.set("parameters/Turn/active", true)
			else:
				if animation_tree.get("parameters/Turn/active") == false:
					animation_tree.set("parameters/TurnSide/current", 1)
					animation_tree.set("parameters/Turn/active", true)
	else:
		animation_tree.set("parameters/Zero/current", 0)
		animation_tree.set("parameters/Movement/blend_position", Vector2(loc_v.x,loc_v.z))
		animation_tree.set("parameters/AudioMovement/blend_position", Vector2(loc_v.x,loc_v.z))
	
func idle(delta : float) -> void:
	if _dop_timer >= 0.1:
		_dop_timer = 0.0
		if is_player_in_sight():
			set_state(ALLERTED_AND_DOESNT_KNOW_LOC)
	else:
		_dop_timer += delta

func reset_self(delta : float) -> bool:
	var result : bool = true
	direction = Vector3.ZERO
	return result
	
func _timer_update(delta : float, state_timer : float, switch_to_state = null) -> bool:
	if _timer >= state_timer:
		set_state(switch_to_state)
		return true
	else:
		_timer += delta
	return false
	
# Проверяем, видит ли противник игрока
func look_for_player(delta : float) -> void:
	if _dop_timer >= 0.1:
		_dop_timer = 0.0
		if is_player_in_sight():
			var result = space_state.intersect_ray(self.global_transform.origin,player.global_transform.origin + Vector3(0,1,0),[self],11)
			if result:
				if result.collider.is_in_group("Player"):
					set_state(ALLERTED_AND_KNOWS_LOC)
					get_tree().call_group("Enemy", "allert_everyone")
					return
	else:
		_dop_timer += delta
	_timer_update(delta,ALLERTED_AND_DOESNT_KNOW_LOC_TIMER,RESET)
	
func look_at_allert(delta : float) -> void:
	face_threat(10,delta,player.global_transform.origin,player.global_transform.origin)
	_timer_update(delta, LOOK_AT_ALLERT_TIMER, ALLERTED_AND_DOESNT_KNOW_LOC)
	
func death() -> void:
	var root = get_tree().root.get_child(get_tree().root.get_child_count()-1)
	var glob_part = get_node("GlobalParticles")
	for i in glob_part.get_children():
		glob_part.remove_child(i)
		root.add_child(i)
	if ragdoll_create:
		ragdoll_create = false
		var new_rag = ragdoll.instance()
		for i in skeleton.get_bone_count():
			new_rag.pose[i] = skeleton.get_bone_global_pose(i)
		new_rag.global_transform = self.global_transform
		new_rag.set_dir(death_dir)
		root.call_deferred("add_child",new_rag)
	call_deferred("queue_free")
	

func face_threat(d1 : int, delta : float, look : Vector3 = Vector3.ZERO, turn : Vector3 = Vector3.ZERO) -> void:
	Global.turn_face(self,turn,d1,delta)
	target_look.global_transform.origin = target_look.global_transform.origin.linear_interpolate(look,10*delta)
	pass

func update_hp(damage : int, dir : Vector3) -> void:
	if _state < LOOK_AT_ALLERT:
		set_state(LOOK_AT_ALLERT)
	
#	var get_sign = randf()-0.5
#	var new_sign = 1
#	if get_sign >= 0:
#		new_sign = 1
#	else:
#		new_sign = -1
#	target_look.transform.origin = Vector3(1.5*new_sign,0,-1)*target_look.transform.origin.z + target_look.transform.origin
	
	current_health -= damage
	if _state != JUMP and _state != JUMP_END:
		_evade_timer -= 1
	if (current_health <= 0):
		death_dir = dir
		set_state(DEATH)
		
func is_player_in_sight() -> bool:	
	if (self.global_transform.basis.z.angle_to(dist) < 1.39 and dist_length <= 250):
		return true
	else:
		return false
		
func move_to_target(delta : float, threshold_distance : float, dir : Vector3, state : int, turn_to = null) -> void:
	match state:
		ATTACK_MELEE:
			if dist_length > threshold_distance:
				direction = dir
			else:
				direction = Vector3.ZERO
			face_threat(15,delta,player.global_transform.origin,player.global_transform.origin)
		ALLERTED_AND_KNOWS_LOC:
			direction = dir
			if (turn_to != null and dist_length > 20.0):
				if (is_player_in_sight()):
					face_threat(5,delta,player.global_transform.origin,turn_to)
				else:
					face_threat(5,delta,turn_to,turn_to)
			else: 
				face_threat(5,delta,player.global_transform.origin,player.global_transform.origin)
	
	front_ray.force_raycast_update()
	if not front_ray.is_colliding():
		direction = Vector3.ZERO

func evade_setup(coef : int, dist_V : Vector3) -> void:
	pass
	
func evade_maneuver(delta : float, dist_V : Vector3) -> void:
	if _evade_timer <= 0:
		_evade_timer = 3 + randi() % 2
		if is_on_floor:
			match side:
				1: # right
					right_down_ray.force_raycast_update()
					right_ray.force_raycast_update()
					if not right_ray.is_colliding() and right_down_ray.is_colliding():
						evade_setup(1, dist_V)
						return
					left_down_ray.force_raycast_update()
					left_ray.force_raycast_update()
					if not left_ray.is_colliding() and left_down_ray.is_colliding():
						evade_setup(-1, dist_V)
						return
				-1: # left
					left_down_ray.force_raycast_update()
					left_ray.force_raycast_update()
					if not left_ray.is_colliding() and left_down_ray.is_colliding():
						evade_setup(1, dist_V)
						return
					right_down_ray.force_raycast_update()
					right_ray.force_raycast_update()
					if not right_ray.is_colliding() and right_down_ray.is_colliding():
						evade_setup(-1, dist_V)
						return

func evading(delta : float) -> void:
	pass
	
func get_nav_path(path : Dictionary) -> void:
	pass
	
func analyze_and_prepare_attack(delta : float) -> void:
	pass

func move_along_path(delta : float) -> bool:
	return false
	
func on_animation_finish(anim_name:String) -> void:
	pass
	
func attack() -> void:
	pass
