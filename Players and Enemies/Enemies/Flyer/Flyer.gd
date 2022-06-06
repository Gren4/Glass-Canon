extends KinematicBody

export var current_health : int = 1
export var shoot_damage : int = 20

export(NodePath) var down_ray_path = null
export(PackedScene) var ragdoll = null

onready var down_ray : RayCast = get_node(down_ray_path)
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
var velocityXY : Vector3 = Vector3.ZERO
var direction : Vector3 = Vector3.ZERO

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
var ragdoll_create : bool = false
var hit_confirm : bool = false

var death_dir : Vector3 = Vector3.ZERO

var give_path : bool = false
var my_path = []

var pl_sides_range = {
	0 : Vector3(0,0,-15),
	1 : Vector3(-7.5,0,-7.5),
	2 : Vector3(-15,0,0),
	3 : Vector3(-7.5,0,7.5),
	4 : Vector3(0,0,15),
	5 : Vector3(7.5,0,7.5),
	6 : Vector3(15,0,0),
	7 : Vector3(7.5,0,-7.5),
}

func _ready():
	_state = ALLERTED_AND_KNOWS_LOC
	accel = 2.5
	SPEED_DOP_EVADE = 14.0
	SPEED_NORMAL = 10.0
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
	#animation_tree.active = true
	var place_holder : Spatial = get_node("GlobalParticles")
	place_holder.set_disable_scale(true)
	

func _physics_process(delta : float) -> void:
	ai(delta)
	
func ai(delta : float) -> void:
	tact_init(delta)
	state_machine(delta)
	finalize_velocity(delta)
	prev_origin = self.global_transform.origin
	
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
	Global.look_face($Body,turn,d1,delta)
	#$MeshInstance.look_at(player.global_transform.origin,Vector3.UP)
	#target_look.global_transform.origin = target_look.global_transform.origin.linear_interpolate(look,10*delta)
	pass
		
func analyze_and_prepare_attack(delta : float) -> void:
#	if _shoot_timer < SHOOT_CD_TIMER:
#		_shoot_timer += delta
#	if _shoot_timer >= SHOOT_CD_TIMER:
#		var result = space_state.intersect_ray(self.global_transform.origin,player.global_transform.origin,[self],11)
#		if result:
#			if result.collider.is_in_group("Player"):
#				set_state(SHOOT)
#				animation_tree.set("parameters/Shoot/active",true)
#				_attack_timer = 0.0
#				_shoot_timer = 0.0
#				SHOOT_CD_TIMER = 1.0 + randf()*0.5
#	if not move_along_path(delta):
#		evade_maneuver(delta, dist)
	
	if my_path.size() > 0:
			var dir_to_path = (my_path[0] - (self.global_transform.origin - Vector3(0,2.0,0)) )
			if dir_to_path.length() < 1.4:
				my_path.remove(0)
			else:
				fly_to_target(dir_to_path,delta,false)
	else:
		fly_to_target(Vector3.ZERO,delta,true)
		pass
	
	
func fly_to_target(dir : Vector3, delta : float, i_see_player : bool) -> void:
#	if _timer >= CHECK_IF_VISIBLE_TIMER:
#		_timer = 0.0
#		var result = space_state.intersect_ray(down_ray.global_transform.origin,player.global_transform.origin,[self],11)
#		if result:
#			if result.collider.is_in_group("Player"):
#				my_path.resize(0)
#			else:
#	else:
#		_timer += delta
	down_ray.force_raycast_update()
	var dp : Vector3
	if down_ray.is_colliding():
		 dp =  down_ray.global_transform.origin - down_ray.get_collision_point()
	else:
		dp = Vector3(0,5.0,0)
	if my_path.size() < 1:
		if _timer >= 2.0:
			attack_side = randi()%8	
			give_path = true
			_timer = 0.0
		else:
			_timer += delta
	
	if i_see_player:
		if dist_length < 15.0:
			direction = self.global_transform.basis.z
		else:
			direction = dir
		if (dp.y > 2.0):
			dop_y_vel = lerp(dop_y_vel, 2.5 * (5.0 - dist.y), 0.1)
		else:
			dop_y_vel = lerp(dop_y_vel, (dp.y), 0.1)
	else:		
		direction = dir
		if dist_length < 7.0:
			var cross : Vector3 = Vector3.UP.cross(dist)
			direction = direction + cross
			attack_side = randi()%8	
			give_path = true
		if (dp.y > 2.0):
			dop_y_vel = lerp(dop_y_vel, 2.5 * ( dir.y), 0.1)
		else:
			dop_y_vel = lerp(dop_y_vel, (dp.y), 0.1)
	
#	else:
#		dop_y_vel= lerp(dop_y_vel, -10.0, 0.01)
#   direction += rand_range(-10,10)*self.global_transform.basis.x
	face_threat(15,delta,player.global_transform.origin,player.global_transform.origin)
	
func finalize_velocity(delta : float) -> void:
	direction = direction.normalized()
	velocityXY = velocityXY.linear_interpolate(direction * (speed + dop_speed), accel * delta)
	velocity.x = velocityXY.x
	velocity.z = velocityXY.z
	velocity.y = dop_y_vel
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
		
func get_nav_path(path : PoolVector3Array) -> void:
	my_path = path
	give_path = false
	
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
	
	if (current_health <= 0):
		death_dir = dir
		set_state(DEATH)
	
func death() -> void:
	var root = get_tree().root.get_child(get_tree().root.get_child_count()-1)
	var glob_part = get_node("GlobalParticles")
	for i in glob_part.get_children():
		glob_part.remove_child(i)
		root.add_child(i)
#	if ragdoll_create:
#		ragdoll_create = false
#		var new_rag = ragdoll.instance()
#		for i in skeleton.get_bone_count():
#			new_rag.pose[i] = skeleton.get_bone_global_pose(i)
#		new_rag.global_transform = self.global_transform
#		new_rag.set_dir(death_dir)
#		root.call_deferred("add_child",new_rag)
	call_deferred("queue_free")
