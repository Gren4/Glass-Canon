extends Players_and_Enemies

export(NodePath) var player_path = null
export(NodePath) var mesh_inst1_path = null
export(NodePath) var mesh_inst2_path = null
export(NodePath) var hitbox_path = null
export(NodePath) var animation_player_path = null
export(NodePath) var area_detection_path = null

export(NodePath) var right_ray_path = null
export(NodePath) var left_ray_path = null
export(NodePath) var right_down_ray_path = null
export(NodePath) var left_down_ray_path = null

onready var player = get_node(player_path)
onready var mesh_inst1 = get_node(mesh_inst1_path)
onready var mesh_inst2 = get_node(mesh_inst2_path)
onready var hitbox = get_node(hitbox_path)
onready var animation_player = get_node(animation_player_path)
onready var area_detection = get_node(area_detection_path)

onready var  right_ray = get_node(right_ray_path)
onready var  left_ray = get_node(left_ray_path)
onready var  right_down_ray = get_node(right_down_ray_path)
onready var  left_down_ray = get_node(left_down_ray_path)

var target
onready var space_state : PhysicsDirectSpaceState = get_world().direct_space_state

var isAlive : bool = true

const ACCEL : float = 5.0
const ACCEL_AIR  : float= 3.0
const ACCEL_DASH : float = 10.0
enum { LEFT, RIGHT, CENTER = -1}
const SPEED_NORMAL : float = 25.0
const SPEED_AIR : float = 18.0
const SPEED_DOP_ATTACK : float = 20.0
const SPEED_DOP_EVADE : float = 70.0

const jump_power : float = 20.0

var dop_speed : float = 0.0

export var current_health : int = 520
export var attack_damage : int = 5

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
		ATTACK,
		EVADE,
		DEATH
	}
	
var dist : Vector3 = Vector3.ZERO
var dist_length : float = 0.0

onready var _state : int = IDLE
var timer_finished : bool = true

const IDLE_TIMER : float = 3.0
const RESET_TIMER : float = 3.0
const ALLERTED_AND_KNOWS_LOC_TIMER: float = 20.0
const ALLERTED_AND_DOESNT_KNOW_LOC_TIMER : float = 3.0
const IDLE_TURN_TIMER : float = 3.0
const LOOK_AT_ALLERT_TIMER : float = 0.5
const ATTACK_CD_TIMER : float = 0.5

var _timer : float = 0.0
var _dop_timer : float = 0.0
var _attack_timer : float = 0.0
var _evade_timer : float = 0.0
var EVADE_TIMER_CD : float = 2.5
var side : int = 1

var no_collision_between : bool = false

var point_of_interest : Vector3 = Vector3.ZERO

func _ready():
	animation_player.connect("animation_finished", self, "on_animation_finish")

func _process(delta):
	if global_transform.origin.y < -50:
		death()

func _physics_process(delta):
	tact_init(delta)
	state_machine(delta)
	finalize_velocity(delta)

func state_machine(delta):
	match _state:
		IDLE:
			idle(delta)
		RESET:
			if reset_self(delta):
				set_state(IDLE)
		ALLERTED_AND_KNOWS_LOC:
			analyze_and_prepare_attack(delta)
		ATTACK:
			move_to_target(delta,ATTACK)
		EVADE:
			evading(delta)
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
			set_color_green()
		IDLE:
			set_color_green()
		IDLE_TURN:
			set_color_green()
		LOOK_AT_ALLERT:
			set_color_blue()
		ALLERTED_AND_DOESNT_KNOW_LOC:
			set_deferred("area_detection.monitoring", true)
			set_color_orange()
		ALLERTED_AND_KNOWS_LOC:
			right_ray.enabled = true
			left_ray.enabled = true
			right_down_ray.enabled = false
			left_down_ray.enabled = false
			set_color_red()
		ATTACK:
			set_color_violate()
		EVADE:
			right_ray.enabled = false
			left_ray.enabled = false
			
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

func on_animation_finish(anim_name):
	match anim_name:
		"Attack":
			_attack_timer = 0.0
			set_state(ALLERTED_AND_KNOWS_LOC)
			direction = Vector3.ZERO
			velocityXY = Vector3.ZERO
			dop_speed = 0.0
	
func idle(delta):
	if _dop_timer >= 0.1:
		_dop_timer = 0.0
		if is_player_in_sight():
			set_state(ALLERTED_AND_DOESNT_KNOW_LOC)
			target = player
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
		if target == player:
			if is_player_in_sight():
				var result = space_state.intersect_ray(mesh_inst2.global_transform.origin,target.global_transform.origin + Vector3(0,0.7,0),[self],5)
				if result:
					if result.collider.is_in_group("Player"):
						set_state(ALLERTED_AND_KNOWS_LOC)
						set_deferred("area_detection.monitoring", false)
						return
	else:
		_dop_timer += delta
	_timer_update(delta,ALLERTED_AND_DOESNT_KNOW_LOC_TIMER,RESET)
	
func analyze_and_prepare_attack(delta):
	if _dop_timer >= 0.5:
		_dop_timer = 0.0
		var result = space_state.intersect_ray(mesh_inst2.global_transform.origin,target.global_transform.origin,[self],5)
		if result:
			if result.collider.is_in_group("Player"):
				no_collision_between = true
			else:
				no_collision_between = false
	else:
		_dop_timer += delta
		
	if _attack_timer >= ATTACK_CD_TIMER:
		if no_collision_between:
			if dist_length <= 4.5:
				var height_dif : float = -dist.y
				if (abs(Global.observation_angle(self,player)) <= 0.175):
					if height_dif > 0.5:
						if is_on_floor:
							velocity.y = jump_power
							snap = Vector3.ZERO
							dop_speed = SPEED_DOP_ATTACK
							set_state(ATTACK)
							animation_player.play("Attack",-1.0,3)
							return
					elif abs(height_dif) <= 0.5:
						dop_speed = SPEED_DOP_ATTACK
						set_state(ATTACK)
						animation_player.play("Attack",-1.0,3)
						return
	else:
		_attack_timer += delta

	move_to_target(delta, ALLERTED_AND_KNOWS_LOC)
	evade_maneuver(delta, dist)		
	
func evade_maneuver(delta, dist_V):
	if _evade_timer >= EVADE_TIMER_CD:
		_evade_timer = 0.0
		if is_on_floor:
			match side:
				1: # right
					if not right_ray.is_colliding():
						right_down_ray.enabled = true
						evade_setup(1, dist_V)
						return
					elif not left_ray.is_colliding():
						left_down_ray.enabled = true
						evade_setup(-1, dist_V)
						return
				-1: # left
					if not left_ray.is_colliding():
						left_down_ray.enabled = true
						evade_setup(1, dist_V)
						return
					elif not right_ray.is_colliding():
						right_down_ray.enabled = true
						evade_setup(-1, dist_V)
						return
	else:
		_evade_timer += delta	
		
func evade_setup(coef,dist_V):
	direction = coef * side * Vector3.UP.cross(dist_V).normalized()
	side = coef * side
	dop_speed = SPEED_DOP_EVADE
	EVADE_TIMER_CD = 1 + randf()
	set_state(EVADE)
	
	
func evading(delta):
	match side:
		-1:
			if not left_down_ray.is_colliding():
				direction = -dist
				dop_speed = 0.0
				side = 1
				set_state(ALLERTED_AND_KNOWS_LOC)
		1:
			if not right_down_ray.is_colliding():
				direction = -dist
				dop_speed = 0.0
				side = -1
				set_state(ALLERTED_AND_KNOWS_LOC)
				
	if _dop_timer >= 0.1:
		direction = -dist
		dop_speed = 0.0
		side = -side
		set_state(ALLERTED_AND_KNOWS_LOC)
	else:
		_dop_timer += delta
			
	move_to_target(delta,EVADE)
	
func move_to_target(delta, state):
	match state:
		ATTACK:
			direction = -dist
			Global.look_face(mesh_inst2,target.global_transform.origin, 15, delta)
			Global.turn_face(self,target.global_transform.origin, 20, delta)
		ALLERTED_AND_KNOWS_LOC:#, EVADE:
			if dist_length < 3.5:
				direction = direction.linear_interpolate(dist, delta)
			else:
				direction = -dist
			Global.look_face(mesh_inst2,target.global_transform.origin, 20, delta)
			Global.turn_face(self,target.global_transform.origin, 30, delta)

func look_at_allert(delta):
	Global.look_face(mesh_inst2, point_of_interest, 5 ,delta)
	Global.turn_face(self,target.global_transform.origin, 10, delta)
	_timer_update(delta, LOOK_AT_ALLERT_TIMER, ALLERTED_AND_DOESNT_KNOW_LOC)

func update_hp(damage):
	point_of_interest = player.global_transform.origin
	if _state < LOOK_AT_ALLERT:
		target = player
		set_state(LOOK_AT_ALLERT)
		
	current_health -= damage
	if (current_health <= 0):
		set_state(DEATH)
		
func is_player_in_sight() -> bool:	
	if (self.global_transform.basis.z.angle_to(dist) < 1.05 and dist_length <= 250):
		return true
	else:
		return false
	
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
		target = player
		point_of_interest = player.global_transform.origin
		set_state(LOOK_AT_ALLERT)
		set_deferred("area_detection.monitoring", false)

func death():
	var root = get_tree().root.get_child(get_tree().root.get_child_count()-1)
	var glob_part = get_node("GlobalParticles")
	for i in glob_part.get_children():
		glob_part.remove_child(i)
		root.add_child(i)
	call_deferred("queue_free")
	

