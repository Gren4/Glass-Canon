extends KinematicBody

export var current_health : int = 1
export var shoot_damage : int = 20

export(NodePath) var animation_tree_path = null
export(NodePath) var target_look_path
export(NodePath) var front_ray_path = null
export(NodePath) var skeleton_path
#export(NodePath) var front_ray2_path = null
#export(NodePath) var front_ray3_path = null
#export(NodePath) var front_ray4_path = null
export(NodePath) var shoot_r_path = null
export(NodePath) var shoot_l_path = null
export(NodePath) var spikes_r_path = null
export(NodePath) var spikes_l_path = null
export(PackedScene) var ragdoll = null

export(PackedScene) var projectile = null

onready var animation_tree = get_node(animation_tree_path)
onready var  target_look = get_node(target_look_path)
onready var shoot_r = get_node(shoot_r_path)
onready var shoot_l = get_node(shoot_l_path)
onready var spikes_r = get_node(spikes_r_path)
onready var spikes_l = get_node(spikes_l_path)
onready var front_ray : RayCast = get_node(front_ray_path)
onready var  skeleton = get_node(skeleton_path)
#onready var front_ray2 : RayCast = get_node(front_ray2_path)
#onready var front_ray3 : RayCast = get_node(front_ray3_path)
#onready var front_ray4 : RayCast = get_node(front_ray4_path)
onready var prev_origin : Vector3 = Vector3.ZERO
onready var space_state : PhysicsDirectSpaceState = get_world().direct_space_state
var player
onready var _state : int

onready var turn_angle = self.rotation_degrees.y

enum {
		RESET,
		IDLE, 
		IDLE_TURN, 
		LOOK_AT_ALLERT,
		ALLERTED_AND_DOESNT_KNOW_LOC, 
		ALLERTED_AND_KNOWS_LOC,
		SHOOT,
		EVADE,
		DEATH
	}
	

var dop_velocity : Vector3 = Vector3.ZERO
var velocity : Vector3 = Vector3.ZERO
var dop_y_vel : float = 0.0
var direction : Vector3 = Vector3.ZERO
var dop_direction : Vector3 = Vector3.ZERO

var SPEED_DOP_EVADE : float
var SPEED_NORMAL : float
var SPEED_SIDE_STEP : float

var speed : float = 1.0
var jump_time_coeff : float = 0.7
var dop_speed : float = 0.0
var accel : float = 1.0
const gravity : float = 40.0


var dist : Vector3 = Vector3.ZERO
var dist2D : Vector2 = Vector2.ZERO
var dist_length : float = 0.0
var dist2D_length : float = 0.0
var allerted : bool = false


var SHOOT_CD_TIMER : float = 2.0
var IDLE_TIMER : float = 1.0
var RESET_TIMER : float = 1.0
var ALLERTED_AND_KNOWS_LOC_TIMER: float = 1.0
var ALLERTED_AND_DOESNT_KNOW_LOC_TIMER : float = 1.0
var IDLE_TURN_TIMER : float = 1.0
var LOOK_AT_ALLERT_TIMER : float = 1.0
var CHECK_IF_VISIBLE_TIMER : float = 1.5

var _timer : float = 0.0
var _dop_timer : float = 0.0
var _shoot_timer : float = 0.0
var _stop_timer : float = 0.0
var side : int = 1
var no_collision_between : bool = false

var is_moving : bool = false
var attack_side : int = 0
var height : float = 5
var ragdoll_create : bool = true
var col_shoots : int = 2

var death_dir : Vector3 = Vector3.ZERO

var give_path : bool = true
var my_path = []

var last_point : Vector3 = Vector3.ZERO

func _ready():
	_state = ALLERTED_AND_KNOWS_LOC
	accel = 2.5
	SPEED_DOP_EVADE = 14.0
	SPEED_NORMAL = 30.0
	IDLE_TIMER = 3.0
	RESET_TIMER = 3.0
	ALLERTED_AND_KNOWS_LOC_TIMER = 20.0
	ALLERTED_AND_DOESNT_KNOW_LOC_TIMER = 3.0
	IDLE_TURN_TIMER = 3.0
	LOOK_AT_ALLERT_TIMER = 0.5
	attack_side = randi()%8	
	#animation_tree.set("parameters/IdleAlert/current",0)
	#animation_tree.set("parameters/Zero/current",1)
	#animation_tree.set("parameters/JumpTransition/current",0)
	#animation_tree.set("parameters/JumpBlend/blend_amount",0)
	set_process(true)
	set_physics_process(true)
	animation_tree.active = true
	var place_holder : Spatial = get_node("GlobalParticles")
	place_holder.set_disable_scale(true)
	

func _physics_process(delta : float) -> void:
	ai(delta)
	
func ai(delta : float) -> void:
	tact_init(delta)
	state_machine(delta)
	finalize_velocity(delta)
	prev_origin = self.global_transform.origin

func on_animation_finish(anim_name:String) -> void:
	match anim_name:
		"Shoot":
			_shoot_timer = 0.0
			set_state(ALLERTED_AND_KNOWS_LOC)
				
func tact_init(delta : float) -> void:
	dist = self.global_transform.origin - player.global_transform.origin
	dist2D = Vector2(dist.x,dist.z)
	dist_length = dist.length()
	dist2D_length = dist2D.length()
	
	speed = SPEED_NORMAL
	#velocity.y = 0.0
	
func state_machine(delta : float) -> void:
	match _state:
		IDLE:
			idle(delta)
		RESET:
			if reset_self(delta):
				set_state(IDLE)
		ALLERTED_AND_KNOWS_LOC:
			analyze_and_prepare_attack(delta)
			#face_threat(15,delta,player.global_transform.origin,player.global_transform.origin)
		EVADE:
			#evading(delta)
			pass
		ALLERTED_AND_DOESNT_KNOW_LOC:
			look_for_player(delta)
		IDLE_TURN:
			pass
		LOOK_AT_ALLERT:
			look_at_allert(delta)
		DEATH:
			pass

func set_state(state : int) -> void:
	_timer = 0.0
	_dop_timer = 0.0
	_state = state
	match _state:
		IDLE:
			pass
			#set_deferred("area_detection.monitoring", true)
			#animation_tree.set("parameters/IdleAlert/current",0)
		RESET:
			#set_deferred("area_detection.monitoring", true)
			pass
		LOOK_AT_ALLERT:
			#animation_tree.set("parameters/IdleAlert/current",1)
			pass
		ALLERTED_AND_DOESNT_KNOW_LOC:
			pass
			#animation_tree.set("parameters/IdleAlert/current",2)
			#set_deferred("area_detection.monitoring", true)
		ALLERTED_AND_KNOWS_LOC:
			allerted = true
			#animation_tree.set("parameters/IdleAlert/current",2)
			#set_deferred("area_detection.monitoring", false)
		DEATH:
			death()
	
func _timer_update(delta : float, state_timer : float, switch_to_state = null) -> bool:
	if _timer >= state_timer:
		set_state(switch_to_state)
		return true
	else:
		_timer += delta
	return false
			
func idle(delta : float) -> void:
	if _dop_timer >= 0.1:
		_dop_timer = 0.0
		if is_player_in_sight():
			set_state(ALLERTED_AND_DOESNT_KNOW_LOC)
	else:
		_dop_timer += delta
		
func is_player_in_sight() -> bool:	
	if (self.global_transform.basis.z.angle_to(dist) < 1.39 and dist_length <= 250):
		return true
	else:
		return false
	
func look_at_allert(delta : float) -> void:
	face_threat(10,delta,player.global_transform.origin,player.global_transform.origin)
	_timer_update(delta, LOOK_AT_ALLERT_TIMER, ALLERTED_AND_DOESNT_KNOW_LOC)

func reset_self(delta : float) -> bool:
	var result : bool = true
	direction = Vector3.ZERO
	return result
	
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

func face_threat(d1 : int, delta : float, look : Vector3 = Vector3.ZERO, turn : Vector3 = Vector3.ZERO) -> void:
	Global.turn_face(self,turn,d1,delta)
	target_look.global_transform.origin = target_look.global_transform.origin.linear_interpolate(look,10*delta)
	pass
		
func analyze_and_prepare_attack(delta : float) -> void:
	if _shoot_timer < SHOOT_CD_TIMER:
		_shoot_timer += delta
		spikes_l.set_scale(spikes_l.get_scale().linear_interpolate(Vector3.ONE,delta))
		spikes_r.set_scale(spikes_r.get_scale().linear_interpolate(Vector3.ONE,delta))
	if _shoot_timer >= SHOOT_CD_TIMER and dist_length <= 30.0:
		if SHOOT_CD_TIMER == 3.0:
			col_shoots = 2
		var result = space_state.intersect_ray(self.global_transform.origin,player.global_transform.origin,[self],11)
		if result:
			if result.collider.is_in_group("Player"):
				set_state(SHOOT)
				animation_tree.set("parameters/Shoot/active",true)
				_shoot_timer = 0.0
				col_shoots -= 1
				if col_shoots > 0:
					SHOOT_CD_TIMER = 1.0
				else:
					SHOOT_CD_TIMER = 3.0
						
	var size_path : int = my_path.size()
	if size_path > 0:
		var dir_to_path = (my_path[0] - self.global_transform.origin)
		if dir_to_path.length() < 4.0:
			if size_path == 1:
				last_point = my_path[0]
			my_path.remove(0)
		else:
			fly_to_target(dir_to_path,delta,false)
	else:
		if _timer >= 0.5:
			if attack_side + side >= 8:
				attack_side = 0
			elif attack_side + side < 0:
				attack_side = 7
			else:
				attack_side += side
			var rnd : int = randi()%10
			height = 3 + rnd
			if rnd < 2:
				side = -side
			_timer = 0.0
		else:
			_timer += delta
		var dir_to_path = (last_point - self.global_transform.origin)
		if dir_to_path.length() < 1.4:
			fly_to_target(Vector3.ZERO,delta,true)
		else:
			fly_to_target(dir_to_path,delta,true)
		pass
		
func shoot(side : String) -> void:
	var point : Vector3 = player.global_transform.origin + Vector3(0,1,0)
	var follower : Vector3 =  + Vector3(player.vel_info.x,0,player.vel_info.z)*dist_length/(45*1.2)
	var pos : Vector3
	
	var sideV : Vector3 = 2*Vector3.UP.cross(dist).normalized()/sqrt(dist_length)
	var updownV : Vector3 = Vector3(0,-2,0)/sqrt(dist_length)
	match side:
		"left":
			pos = shoot_l.global_transform.origin
			spikes_l.set_scale(Vector3.ZERO)
			
		"right":
			pos = shoot_r.global_transform.origin
			spikes_r.set_scale(Vector3.ZERO)

	if player.speed <= player.WALLRUNNING_SPEED:
		var abs_p : Vector3 = point + follower
		Global.spawn_projectile_node_from_pool(projectile,self,pos, abs_p,50)
		Global.spawn_projectile_node_from_pool(projectile,self,pos, abs_p + updownV, 49)
		Global.spawn_projectile_node_from_pool(projectile,self,pos, abs_p - updownV, 48)
		Global.spawn_projectile_node_from_pool(projectile,self,pos, abs_p + sideV, 47)
		Global.spawn_projectile_node_from_pool(projectile,self,pos, abs_p - sideV, 46)
	else:
		Global.spawn_projectile_node_from_pool(projectile,self,pos, point,50)
		Global.spawn_projectile_node_from_pool(projectile,self,pos, point + updownV, 49)
		Global.spawn_projectile_node_from_pool(projectile,self,pos, point - updownV, 48)
		Global.spawn_projectile_node_from_pool(projectile,self,pos, point + sideV, 47)
		Global.spawn_projectile_node_from_pool(projectile,self,pos, point - sideV, 46)
	
func fly_to_target(dir : Vector3, delta : float, i_see_player : bool) -> void:
	direction = dir
	var n : Vector3 = (5*dir.normalized())
	front_ray.set_cast_to(n)
	front_ray.force_raycast_update()
	if front_ray.is_colliding():
		direction = Vector3.UP.cross(dir)
	face_threat(15,delta,player.global_transform.origin,player.global_transform.origin)
	
func finalize_velocity(delta : float) -> void:
	direction = direction.normalized()
	velocity = velocity.linear_interpolate(direction * (speed + dop_speed), accel * delta)
	var vel_inf = move_and_slide(velocity, Vector3.UP, false, 4, deg2rad(45))
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
		
#	if velocity.length() < 1.0:
#		animation_tree.set("parameters/Zero/current", 1)
#		animation_tree.set("parameters/AudioMovement/blend_position", Vector2.ZERO)
#		if do_turn:
#			if new_angle < 0:
#				if animation_tree.get("parameters/Turn/active") == false:
#					animation_tree.set("parameters/TurnSide/current", 0)
#					animation_tree.set("parameters/Turn/active", true)
#			else:
#				if animation_tree.get("parameters/Turn/active") == false:
#					animation_tree.set("parameters/TurnSide/current", 1)
#					animation_tree.set("parameters/Turn/active", true)
#	else:
#	animation_tree.set("parameters/Zero/current", 0)
	animation_tree.set("parameters/Movement/blend_position", Vector2(loc_v.x,loc_v.z))
#	animation_tree.set("parameters/AudioMovement/blend_position", Vector2(loc_v.x,loc_v.z))
		
func get_nav_path(path : Dictionary) -> void:
	my_path = path["path"]
	#give_path = false
	
func update_hp(damage : int, dir : Vector3) -> void:
	if _state < LOOK_AT_ALLERT:
		set_state(LOOK_AT_ALLERT)
	current_health -= damage
	
	if (current_health <= 0):
		death_dir = dir
		set_state(DEATH)
	
#	var get_sign = randf()-0.5
#	var new_sign = 1
#	if get_sign >= 0:
#		new_sign = 1
#	else:
#		new_sign = -1
#	target_look.transform.origin = Vector3(1.5*new_sign,0,-1)*target_look.transform.origin.z + target_look.transform.origin
	
	
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
