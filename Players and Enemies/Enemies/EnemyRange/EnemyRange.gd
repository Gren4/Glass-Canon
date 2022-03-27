extends Players_and_Enemies

#export(NodePath) var player_path = null
export(NodePath) var mesh_inst1_path = null
export(NodePath) var mesh_inst2_path = null
export(NodePath) var hitbox_path = null
export(NodePath) var animation_player_path = null
export(NodePath) var area_detection_path = null

export(NodePath) var right_ray_path = null
export(NodePath) var left_ray_path = null
export(NodePath) var right_down_ray_path = null
export(NodePath) var left_down_ray_path = null

export(PackedScene) var projectile = null

onready var player# = get_node(player_path)
onready var mesh_inst1 = get_node(mesh_inst1_path)
onready var mesh_inst2 = get_node(mesh_inst2_path)
onready var hitbox = get_node(hitbox_path)
onready var animation_player = get_node(animation_player_path)
onready var area_detection = get_node(area_detection_path)

onready var  right_ray = get_node(right_ray_path)
onready var  left_ray = get_node(left_ray_path)
onready var  right_down_ray = get_node(right_down_ray_path)
onready var  left_down_ray = get_node(left_down_ray_path)

onready var space_state : PhysicsDirectSpaceState = get_world().direct_space_state

var isAlive : bool = true

const ACCEL : float = 10.0
#const ACCEL_AIR  : float= 5.0
#const ACCEL_DASH : float = 10.0
enum { LEFT, RIGHT, CENTER = -1}
const SPEED_NORMAL : float = 15.0
const SPEED_AIR : float = 8.0
const SPEED_SIDE_STEP : float = 5.0
const SPEED_DOP_ATTACK : float = 20.0
const SPEED_DOP_EVADE : float = 70.0

const jump_power : float = 20.0

var dop_speed : float = 0.0

export var current_health : int = 100
export var attack_damage : int = 5
export var shoot_damage : int = 20

var speed : float = SPEED_NORMAL
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
		SHOOT,
		EVADE,
		JUMP,
		DEATH
	}
	
var dist : Vector3 = Vector3.ZERO
var dist_length : float = 0.0

onready var _state : int = IDLE

const IDLE_TIMER : float = 3.0
const RESET_TIMER : float = 3.0
const ALLERTED_AND_KNOWS_LOC_TIMER: float = 20.0
const ALLERTED_AND_DOESNT_KNOW_LOC_TIMER : float = 3.0
const IDLE_TURN_TIMER : float = 3.0
const LOOK_AT_ALLERT_TIMER : float = 0.5
const ATTACK_CD_TIMER : float = 0.5
const SHOOT_CD_TIMER : float = 1.0

var _timer : float = 0.0
var _dop_timer : float = 0.0
var _attack_timer : float = 0.0
var _shoot_timer : float = 0.0
var _change_dir_timer : float = 2 * randf()
var _evade_timer : int = 1 + randi() % 5
var side : int = 1

var no_collision_between : bool = false

var my_path = []
var link_from : PoolVector3Array = []
var link_to : PoolVector3Array = []
#var need_to_jump : bool = false
var start_jump_pos : Vector3 = Vector3.ZERO
var jump_time : float = 0.0
var p1 : Vector3 = Vector3.ZERO
var offset : Vector3 = Vector3.ZERO

var attack_side : int = 0

func _ready():
	animation_player.connect("animation_finished", self, "on_animation_finish")

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
	
func state_machine(delta):
	match _state:
		IDLE:
			idle(delta)
		RESET:
			if reset_self(delta):
				set_state(IDLE)
		ALLERTED_AND_KNOWS_LOC:
			analyze_and_prepare_attack(delta)
		ATTACK_MELEE:
			move_to_target(delta,-dist,ATTACK_MELEE)
		SHOOT:
			speed = SPEED_SIDE_STEP
			face_threat(20,30,delta,player.global_transform.origin)
		EVADE:
			evading(delta)
		JUMP:
			face_threat(20,30,delta,link_to[0] + offset)
			if jump_time < 1.0:
				jump_time += delta
				self.global_transform.origin = Global.quadratic_bezier(start_jump_pos,p1,link_to[0],jump_time)
			else:
				link_to.remove(0)
				link_from.remove(0)
				jump_time = 0.0
				#need_to_jump = false
				set_state(ALLERTED_AND_KNOWS_LOC)
		ALLERTED_AND_DOESNT_KNOW_LOC:
			look_for_player(delta)
		IDLE_TURN:
			pass
		LOOK_AT_ALLERT:
			look_at_allert(delta)
		DEATH:
			death()

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
		RESET:
			set_deferred("area_detection.monitoring", true)
			set_color_orange()
		IDLE:
			set_color_orange()
		IDLE_TURN:
			set_color_orange()
		LOOK_AT_ALLERT:
			set_color_orange()
		ALLERTED_AND_DOESNT_KNOW_LOC:
			set_deferred("area_detection.monitoring", true)
			set_color_orange()
		ALLERTED_AND_KNOWS_LOC:
			set_color_orange()
			pass
		ATTACK_MELEE, SHOOT:
			set_color_violate()
		EVADE:
			pass
			
func tact_init(delta):
	dist = self.global_transform.origin - player.global_transform.origin
	dist_length = dist.length()
	
	is_on_floor = is_on_floor()
	if is_on_floor:
		speed = SPEED_NORMAL
	else:
		speed = SPEED_AIR
	
	if is_on_floor:
		velocity.y = -0.1
		snap = Vector3.DOWN
	else:
		velocity.y -= gravity * delta
	
func finalize_velocity(delta):
	direction = direction.normalized()
	velocityXY = velocityXY.linear_interpolate(direction * (speed + dop_speed), (accel) * delta)
	velocity.x = velocityXY.x
	velocity.z = velocityXY.z
	move_and_slide_with_snap(velocity, snap, Vector3.UP, not_on_moving_platform, 4, deg2rad(45))
	
	
func attack():
	var targets = hitbox.get_overlapping_bodies()
	if player in targets:
		player.update_health(-attack_damage)

func shoot():
	Global.spawn_projectile_node_from_pool(projectile,self,hitbox.global_transform.origin, (player.transform.origin + player.vel_info*dist_length/(65*1.2)) + Vector3(0,1,0))
	pass

func on_animation_finish(anim_name):
	match anim_name:
		"Attack":
			_attack_timer = 0.0
			set_state(ALLERTED_AND_KNOWS_LOC)
			direction = Vector3.ZERO
			velocityXY = Vector3.ZERO
			dop_speed = 0.0
		"Shoot":
			_shoot_timer = 0.0
			set_state(ALLERTED_AND_KNOWS_LOC)
			
	
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
	if mesh_inst2.rotation.x != 0:
		result = false
		if mesh_inst2.rotation.x > 0:
			mesh_inst2.rotation.x -= 4 * delta
		else:
			mesh_inst2.rotation.x += 4 * delta
		mesh_inst2.rotation.x = max(0,mesh_inst2.rotation.x)
	if mesh_inst2.rotation.z != 0:
		result = false
		if mesh_inst2.rotation.z > 0:
			mesh_inst2.rotation.z -= 4 * delta
		else:
			mesh_inst2.rotation.z += 4 * delta
		mesh_inst2.rotation.z = max(0,mesh_inst2.rotation.z)
	return result
	
# Проверяем, видит ли противник игрока
func look_for_player(delta):
	if _dop_timer >= 0.1:
		_dop_timer = 0.0
		if is_player_in_sight():
			var result = space_state.intersect_ray(mesh_inst2.global_transform.origin,player.global_transform.origin + Vector3(0,1,0),[self],11)
			if result:
				if result.collider.is_in_group("Player"):
					set_state(ALLERTED_AND_KNOWS_LOC)
					set_deferred("area_detection.monitoring", false)
					get_tree().call_group("Enemy", "allert_everyone")
					return
	else:
		_dop_timer += delta
	_timer_update(delta,ALLERTED_AND_DOESNT_KNOW_LOC_TIMER,RESET)
	
func analyze_and_prepare_attack(delta):
	var result = space_state.intersect_ray(mesh_inst2.global_transform.origin,player.global_transform.origin,[self],11)
	if result:
		if result.collider.is_in_group("Player"):			
			if dist_length <= 5.0:
				if _attack_timer < ATTACK_CD_TIMER:
					_attack_timer += delta
				if _attack_timer >= ATTACK_CD_TIMER:
						if dist_length <= 5.0:
							if result:
								if result.collider.is_in_group("Player"):
									if (abs(Global.observation_angle(self,player)) <= 0.175):
										#var height_dif : float = -dist.y
										#if abs(height_dif) <= 0.5:
											dop_speed = SPEED_DOP_ATTACK
											set_state(ATTACK_MELEE)
											animation_player.play("Attack",-1.0,3)
							_attack_timer = 0.0
			else:
				if _shoot_timer < SHOOT_CD_TIMER:
					_shoot_timer += delta
				if _shoot_timer >= SHOOT_CD_TIMER:
							set_state(SHOOT)
							animation_player.play("Shoot", -1.0, 0.5)
							_shoot_timer = 0.0
			if _change_dir_timer <= 0.0:
				_change_dir_timer = 2 * randf()
				side = -side
			else:
				_change_dir_timer -= delta
			move_around_target(delta)
		else:
			move_around_target(delta)
	else:
		move_along_path(delta)
	evade_maneuver(delta, dist)
	
func move_around_target(delta):
	if my_path.size() == 0:
		speed = SPEED_SIDE_STEP
		match side:
			1:
				right_down_ray.force_raycast_update()
				if not right_down_ray.is_colliding():
					side = -1
					velocityXY = Vector3.ZERO
			-1:
				left_down_ray.force_raycast_update()
				if not left_down_ray.is_colliding():
					side = 1
					velocityXY = Vector3.ZERO
		move_to_target(delta, side * Vector3.UP.cross(dist).normalized(), ALLERTED_AND_KNOWS_LOC)
	else:
		move_along_path(delta)
	
	
func move_along_path(delta):
	if my_path.size() > 0:
		var dir_to_path = (my_path[0] - self.global_transform.origin)
		if link_from.size() > 0 and link_to.size() > 0:
			var dtp_l = (my_path[0] - link_from[0])
			if dtp_l.length() < 1.4:
				direction = Vector3.ZERO
				velocity = Vector3.ZERO
				velocityXY = Vector3.ZERO
				start_jump_pos = self.global_transform.origin
				p1 = (link_to[0] + start_jump_pos) / 2  + Vector3(0,1*max(start_jump_pos.y,link_to[0].y),0)
				offset = (link_to[0] - start_jump_pos).normalized()
				offset.y = 0
				set_state(JUMP)
				pass
		if dir_to_path.length() < 1.4:
			my_path.remove(0)
		else:
			move_to_target(delta, dir_to_path, ALLERTED_AND_KNOWS_LOC)
	else:
		move_to_target(delta, Vector3.ZERO, ALLERTED_AND_KNOWS_LOC)
	

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
	
func move_to_target(delta, dir, state):
	match state:
		ATTACK_MELEE:
			direction = dir
			face_threat(15,20,delta,player.global_transform.origin)
		ALLERTED_AND_KNOWS_LOC:#, EVADE:
			if dist_length < 2.5:
				direction = direction.linear_interpolate(-dir, delta)
			elif dist_length >= 2.5 and dist_length <= 3.5:
				direction = Vector3.ZERO
			else:
				direction = dir
			face_threat(20,30,delta,player.global_transform.origin)

func look_at_allert(delta):
	face_threat(5,10,delta,player.global_transform.origin)
	_timer_update(delta, LOOK_AT_ALLERT_TIMER, ALLERTED_AND_DOESNT_KNOW_LOC)

func face_threat(d1,d2,delta,offset_ = Vector3.ZERO):
	Global.look_face(mesh_inst2, offset_, d1, delta)
	Global.turn_face(self, offset_, d2, delta)

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
	my_path = path["complete_path"]
	if _state != JUMP:
		link_from.resize(0)
		link_to.resize(0)
	if not path["nav_link_to_first"].empty():
		if path["nav_link_path_inbetween"].empty():
			if _state != JUMP:
				var to = path["nav_link_from_last"][0]
				var from = path["nav_link_to_first"][path["nav_link_to_first"].size()-1]
				if to in my_path and from in my_path:
					link_from.append(from)
					link_to.append(to)
		else:
			if _state != JUMP:
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
	
func set_color_red():
	mesh_inst1.get_surface_material(0).set_albedo(Color(1,0,0))

func set_color_green():
	mesh_inst1.get_surface_material(0).set_albedo(Color(0,1,0))
	
func set_color_orange():
	mesh_inst1.get_surface_material(0).set_albedo(Color(1,0.43,0))
	
func set_color_blue():
	mesh_inst1.get_surface_material(0).set_albedo(Color(0,0,1))
	
func set_color_violate():
	mesh_inst1.get_surface_material(0).set_albedo(Color(0.5,0,0.5))


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
	call_deferred("queue_free")
	

