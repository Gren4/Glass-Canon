extends Players_and_Enemies

onready var player

export(NodePath) var hitboxl_path = null
export(NodePath) var hitboxr_path = null
export(NodePath) var animation_tree_path = null
export(NodePath) var area_detection_path = null

export(NodePath) var front_ray_path = null
export(NodePath) var right_ray_path = null
export(NodePath) var left_ray_path = null
export(NodePath) var right_down_ray_path = null
export(NodePath) var left_down_ray_path = null
export(PackedScene) var ragdoll = null

onready var hitboxl = get_node(hitboxl_path)
onready var hitboxr = get_node(hitboxr_path)
onready var animation_tree = get_node(animation_tree_path)
onready var area_detection = get_node(area_detection_path)

onready var  front_ray = get_node(front_ray_path)
onready var  right_ray = get_node(right_ray_path)
onready var  left_ray = get_node(left_ray_path)
onready var  right_down_ray = get_node(right_down_ray_path)
onready var  left_down_ray = get_node(left_down_ray_path)

onready var space_state : PhysicsDirectSpaceState = get_world().direct_space_state

var isAlive : bool = true

const ACCEL : float = 15.0
const SPEED_AIR : float = 18.0
const SPEED_DOP_ATTACK : float = 20.0
const SPEED_DOP_EVADE : float = 70.0

const SPEED_NORMAL : float = 19.0
var speed : float = SPEED_NORMAL

var jump_time_coeff : float = 0.7

var dop_speed : float = 0.0

export var current_health : int = 250
export var attack_damage : int = 5

var accel : float = ACCEL

var gravity : float = 40.0

var is_on_floor : bool = false

enum {
		RESET,
		IDLE, 
		IDLE_TURN, 
		LOOK_AT_ALLERT,
		ALLERTED_AND_DOESNT_KNOW_LOC, 
		ALLERTED_AND_KNOWS_LOC,
		ATTACK_MELEE,
		EVADE,
		AIR,
		JUMP,
		JUMP_END,
		DEATH
	}
	
var dist : Vector3 = Vector3.ZERO
var dist2D : Vector2 = Vector2.ZERO
var dist_length : float = 0.0
var dist2D_length : float = 0.0

onready var _state : int = IDLE
var allerted : bool = false

const IDLE_TIMER : float = 3.0
const RESET_TIMER : float = 3.0
const ALLERTED_AND_KNOWS_LOC_TIMER: float = 20.0
const ALLERTED_AND_DOESNT_KNOW_LOC_TIMER : float = 3.0
const IDLE_TURN_TIMER : float = 3.0
const LOOK_AT_ALLERT_TIMER : float = 0.5
const ATTACK_CD_TIMER : float = 1.5
const DIR_CD_TIMER : float = 5.0

export(NodePath) var StartTimer_path = null
onready var StartTimer : Timer = get_node(StartTimer_path)

var _timer : float = 0.0
var _dop_timer : float = 0.0
var _attack_timer : float = 0.0
var _evade_timer : int = 1 + randi() % 5
var _dir_timer : float = 0.0
var side : int = 1

var no_collision_between : bool = false

var my_path = []
var link_from : PoolVector3Array = []
var link_to : PoolVector3Array = []
var start_jump_pos : Vector3 = Vector3.ZERO
var jump_time : float = 0.0
var p1 : Vector3 = Vector3.ZERO
var offset : Vector3 = Vector3.ZERO

var attack_side : int = 0
var ragdoll_create : bool = true

func _ready():
	set_process(true)
	set_physics_process(true)
	call_deferred("init_timer_set")
	#$Body.scale.y = (0.9 + 0.2*randf())
	pass
	
func init_timer_set():
	StartTimer.wait_time = 1.0 + randf()/2.0
	StartTimer.start()
	

func _process(delta):
	if global_transform.origin.y < -50:
		death()

func _physics_process(delta):
	ai(delta)
	
func ai(delta):
	tact_init(delta)
	state_machine(delta)
	if _state != JUMP:
		finalize_velocity(delta)

func allert_everyone():
	if _state < ALLERTED_AND_KNOWS_LOC:
		set_state(ALLERTED_AND_KNOWS_LOC)
		allerted = true
	
func state_machine(delta):
	match _state:
		IDLE:
			if not is_on_floor:
				set_state(AIR)
				return
			idle(delta)
		RESET:
			if reset_self(delta):
				set_state(IDLE)
		ALLERTED_AND_KNOWS_LOC:
			if not is_on_floor:
				set_state(AIR)
				return
			analyze_and_prepare_attack(delta)
			if _dir_timer >= DIR_CD_TIMER:
				if attack_side + 1 >= 4:
					attack_side = 0
				else:
					attack_side += 1
			else:
				_dir_timer += delta
		ATTACK_MELEE:
			move_to_target(delta,-dist,ATTACK_MELEE)
		EVADE:
			evading(delta)
		JUMP:
			face_threat(20,delta,link_to[0] + offset,link_to[0] + offset)
			if jump_time < 1.0:
				jump_time += delta / jump_time_coeff
				self.global_transform.origin = Global.quadratic_bezier(start_jump_pos,p1,link_to[0],jump_time)
				if jump_time >= 0.95:
					animation_tree.set("parameters/JumpTransition/current","JumpEnd")
			else: 
				link_to.remove(0)
				link_from.remove(0)
				jump_time = 0.0
				set_state(JUMP_END)
				
		AIR:
			if is_on_floor:
				animation_tree.set("parameters/JumpTransition/current","JumpEnd")
				set_state(JUMP_END)
				
		JUMP_END:
			if _timer >= 0.25:
				animation_tree.set("parameters/JumpBlend/blend_amount",0)
				if allerted:
					set_state(ALLERTED_AND_KNOWS_LOC)
				else:
					set_state(IDLE)
			else:
				animation_tree.set("parameters/JumpBlend/blend_amount",1 - (1/0.25)*_timer)
				_timer += delta
		ALLERTED_AND_DOESNT_KNOW_LOC:
			look_for_player(delta)
		IDLE_TURN:
			pass
		LOOK_AT_ALLERT:
			look_at_allert(delta)
		DEATH:
			pass

func _timer_update(delta, state_timer, switch_to_state = null) -> bool:
	if _timer >= state_timer:
		set_state(switch_to_state)
		return true
	else:
		_timer += delta
	return false

func set_state(state):
	_timer = 0.0
	_dop_timer = 0.0
	_state = state
	match _state:
		IDLE:
			set_deferred("area_detection.monitoring", true)
			animation_tree.set("parameters/IdleAlert/current",0)
		RESET:
			set_deferred("area_detection.monitoring", true)
		LOOK_AT_ALLERT:
			animation_tree.set("parameters/IdleAlert/current",1)
		ALLERTED_AND_DOESNT_KNOW_LOC:
			animation_tree.set("parameters/IdleAlert/current",2)
			set_deferred("area_detection.monitoring", true)
		ALLERTED_AND_KNOWS_LOC:
			allerted = true
			animation_tree.set("parameters/IdleAlert/current",2)
			set_deferred("area_detection.monitoring", false)
		JUMP,AIR:
			animation_tree.set("parameters/JumpBlend/blend_amount",1)
			animation_tree.set("parameters/JumpTransition/current","JumpStart")
			direction = Vector3.ZERO
			velocityXY = Vector3.ZERO
		JUMP_END:
			direction = Vector3.ZERO
			velocityXY = Vector3.ZERO
		DEATH:
			death()
			

func tact_init(delta):
	dist = self.global_transform.origin - player.global_transform.origin
	dist2D = Vector2(dist.x,dist.z)
	dist_length = dist.length()
	dist2D_length = dist2D.length()
	is_on_floor = is_on_floor()
	
	if is_on_floor:
		speed = SPEED_NORMAL - (2.0*SPEED_NORMAL/(dist_length*dist_length))
	else:
		speed = SPEED_AIR
	
	if is_on_floor:
		velocity.y = -0.1
		snap = Vector3.DOWN
	else:
		velocity.y -= gravity * delta
	
func finalize_velocity(delta):
	direction = direction.normalized()
	velocityXY = velocityXY.linear_interpolate(direction * (speed + dop_speed), accel * delta)
	velocity.x = velocityXY.x
	velocity.z = velocityXY.z
	var vel_inf = move_and_slide_with_snap(velocity, snap, Vector3.UP, not_on_moving_platform, 4, deg2rad(45))
	var loc_v : Vector3 = (velocity/SPEED_NORMAL).rotated(Vector3.UP,-self.rotation.y)
	animation_tree.set("parameters/Movement/blend_position", Vector2(loc_v.x,loc_v.z))
	
func attack(side:String):
	var targets
	match side:
		"left":
			targets = hitboxl.get_overlapping_bodies()
		"right":
			targets = hitboxr.get_overlapping_bodies()
	if player in targets:
		player.update_health(-attack_damage)
	pass

func on_animation_finish(anim_name:String):
	match anim_name:
		"AttackLeft", "AttackRight":
			_attack_timer = 0.0
			my_path.resize(0)
			link_from.resize(0)
			link_to.resize(0)
			set_state(ALLERTED_AND_KNOWS_LOC)
			direction = Vector3.ZERO
			velocityXY = Vector3.ZERO
			dop_speed = 0.0
	
func idle(delta):
	if _dop_timer >= 0.1:
		_dop_timer = 0.0
		if is_player_in_sight():
			set_state(ALLERTED_AND_DOESNT_KNOW_LOC)
	else:
		_dop_timer += delta

func reset_self(delta) -> bool:
	var result : bool = true
	direction = Vector3.ZERO
	return result
	
# Проверяем, видит ли противник игрока
func look_for_player(delta):
	if _dop_timer >= 0.1:
		_dop_timer = 0.0
		if is_player_in_sight():
			#var result = space_state.intersect_ray(head.global_transform.origin,player.global_transform.origin + Vector3(0,1,0),[self],11)
			var result = space_state.intersect_ray(self.global_transform.origin,player.global_transform.origin + Vector3(0,1,0),[self],11)
			if result:
				if result.collider.is_in_group("Player"):
					set_state(ALLERTED_AND_KNOWS_LOC)
					get_tree().call_group("Enemy", "allert_everyone")
					return
	else:
		_dop_timer += delta
	_timer_update(delta,ALLERTED_AND_DOESNT_KNOW_LOC_TIMER,RESET)
	
func analyze_and_prepare_attack(delta):
	if _attack_timer < ATTACK_CD_TIMER:
		_attack_timer += delta
	if _attack_timer >= ATTACK_CD_TIMER:
			if dist_length <= 5.0:
				var result = space_state.intersect_ray(self.global_transform.origin,player.global_transform.origin,[self],11)
				if result:
					if result.collider.is_in_group("Player"):
						dop_speed = SPEED_DOP_ATTACK
						set_state(ATTACK_MELEE)
						animation_tree.set("parameters/Attack/active",true)
				_attack_timer = 0.0
	if not move_along_path(delta):
		evade_maneuver(delta, dist)

func move_along_path(delta) -> bool:
	if my_path.size() > 0:
		var dir_to_path = (my_path[0] - self.global_transform.origin)
		if link_from.size() > 0 and link_to.size() > 0:
			var dtp_l = (my_path[0] - link_from[0])
			if dtp_l.length() < 1.5 and dir_to_path.length() < 1.4:
				direction = Vector3.ZERO
				velocityXY = Vector3.ZERO
				start_jump_pos = self.global_transform.origin
				p1 = (link_to[0] + start_jump_pos) / 2  + Vector3(0,1*max(start_jump_pos.y,link_to[0].y),0)
				var jdist = (link_to[0] - start_jump_pos)
				jump_time_coeff = jdist.length() / speed
				jump_time_coeff = clamp(jump_time_coeff,0.4,0.7)
				offset = jdist.normalized()
				offset.y = 0
				while (link_to[0] in my_path):
					my_path.remove(0)
				set_state(JUMP)
				return true
		if dir_to_path.length() < 1.4:
			my_path.remove(0)
		else:
			move_to_target(delta, dir_to_path, ALLERTED_AND_KNOWS_LOC,my_path[0])
	else:		
		move_to_target(delta, -dist, ALLERTED_AND_KNOWS_LOC)
	return false
	
func evade_maneuver(delta, dist_V):
	if _evade_timer <= 0:
		_evade_timer = 1 + randi() % 5
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
		
func evade_setup(coef,dist_V):
	direction = coef * side * Vector3.UP.cross(dist_V).normalized()
	side = coef * side
	dop_speed = SPEED_DOP_EVADE
	set_state(EVADE)
	
	
func evading(delta):
	match side:
		-1:
			left_down_ray.force_raycast_update()
			if not left_down_ray.is_colliding():
				direction = -dist
				dop_speed = 0.0
				velocityXY = Vector3.ZERO
				side = 1
				set_state(ALLERTED_AND_KNOWS_LOC)
		1:
			right_down_ray.force_raycast_update()
			if not right_down_ray.is_colliding():
				direction = -dist
				dop_speed = 0.0
				velocityXY = Vector3.ZERO
				side = -1
				set_state(ALLERTED_AND_KNOWS_LOC)
				
	if _dop_timer >= 0.05:
		direction = -dist
		dop_speed = 0.0
		side = -side
		set_state(ALLERTED_AND_KNOWS_LOC)
	else:
		_dop_timer += delta
			
	move_to_target(delta, -dist, EVADE)
	
func move_to_target(delta, dir, state, turn_to = null):
	match state:
		ATTACK_MELEE:
			if dist_length > 3.5:
				direction = dir
			elif dist_length < 3.5 and dist_length > 2.0:
				direction = Vector3.ZERO
			else:
				direction = direction.linear_interpolate(dist.normalized(), delta)
			face_threat(15,delta,player.global_transform.origin,player.global_transform.origin)
		ALLERTED_AND_KNOWS_LOC:
			if dist_length > 3.5:
				direction = dir
			else:
				direction = direction.linear_interpolate(dist.normalized(), delta)
			if (turn_to != null and dist_length > 10.0):
				if (is_player_in_sight()):
					face_threat(10,delta,player.global_transform.origin,turn_to)
				else:
					face_threat(10,delta,turn_to,turn_to)
			else: 
				face_threat(10,delta,player.global_transform.origin,player.global_transform.origin)
	
	front_ray.force_raycast_update()
	if not front_ray.is_colliding():
		direction = Vector3.ZERO

func look_at_allert(delta):
	face_threat(10,delta,player.global_transform.origin,player.global_transform.origin)
	_timer_update(delta, LOOK_AT_ALLERT_TIMER, ALLERTED_AND_DOESNT_KNOW_LOC)

func update_hp(damage):
	if _state < LOOK_AT_ALLERT:
		set_state(LOOK_AT_ALLERT)
		
	current_health -= damage
	_evade_timer -= 1
	if (current_health <= 0):
		set_state(DEATH)
		
func is_player_in_sight() -> bool:	
	if (self.global_transform.basis.z.angle_to(dist) < 1.05 and dist_length <= 250):
		return true
	else:
		return false

func get_nav_path(path):
	if _state != JUMP and _state != JUMP_END:
		my_path = path["complete_path"]
		link_from.resize(0)
		link_to.resize(0)
		if not path["nav_link_to_first"].empty():
			if path["nav_link_path_inbetween"].empty():
				var to = path["nav_link_from_last"][0]
				var from = path["nav_link_to_first"][path["nav_link_to_first"].size()-1]
				if to in my_path and from in my_path:
					link_from.append(from)
					link_to.append(to)
			else:
				var from = path["nav_link_to_first"][path["nav_link_to_first"].size()-1]
				if from in my_path:
					link_from.append(from)
				for pp in path["nav_link_path_inbetween"].size():
					for p in path["nav_link_path_inbetween"][pp].size():
						if path["nav_link_path_inbetween"][pp][p][0] in my_path:
							link_to.append(path["nav_link_path_inbetween"][pp][p][0])
						if path["nav_link_path_inbetween"][pp][p][path["nav_link_path_inbetween"][pp][p].size()-1] in my_path:
							link_from.append(path["nav_link_path_inbetween"][pp][p][path["nav_link_path_inbetween"][pp][p].size()-1])
				var to = path["nav_link_from_last"][0]
				if to in my_path:
					link_to.append(to)


func _on_Area_body_entered(body):
	if _state == IDLE:
		set_state(LOOK_AT_ALLERT)
		set_deferred("area_detection.monitoring", false)

func death():
	var root = get_tree().root.get_child(get_tree().root.get_child_count()-1)
	var glob_part = get_node("GlobalParticles")
	for i in glob_part.get_children():
		glob_part.remove_child(i)
		root.add_child(i)
	if ragdoll_create:
		ragdoll_create = false
		var new_rag = ragdoll.instance()
		for i in $Body/Skeleton.get_bone_count():
			new_rag.pose[i] = $Body/Skeleton.get_bone_global_pose(i)
		new_rag.global_transform = self.global_transform
		root.call_deferred("add_child",new_rag)
	call_deferred("queue_free")
	

func face_threat(d1,delta,look = Vector3.ZERO, turn = Vector3.ZERO):
	Global.turn_face(self,turn,d1,delta)
	$Target.global_transform.origin = look
	pass



func _on_Start_timeout():
	animation_tree.active = true
