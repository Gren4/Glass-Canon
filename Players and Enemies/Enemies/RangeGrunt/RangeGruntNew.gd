extends Enemies

export(NodePath) var hitbox_path = null
export(NodePath) var shoot_path = null

export(NodePath) var ray_l_path = null
export(NodePath) var ray_r_path = null
export(NodePath) var ik_l_path = null
export(NodePath) var ik_r_path = null
export(NodePath) var point_l_path = null
export(NodePath) var point_r_path = null

export(PackedScene) var projectile = null

onready var hitbox = get_node(hitbox_path)
onready var shoot = get_node(shoot_path)

onready var ray_l = get_node(ray_l_path)
onready var ray_r = get_node(ray_r_path)
onready var ik_l = get_node(ik_l_path)
onready var ik_r = get_node(ik_r_path)
onready var point_l = get_node(point_l_path)
onready var point_r = get_node(point_r_path)

export var shoot_damage : int = 20

var SHOOT_CD_TIMER : float = 2.0

var _shoot_timer : float = 0.0
var _change_dir_timer : float = 2 * randf()
var _change_side_timer : float = 0.0

func _ready() -> void:
	accel = 5.0
	SPEED_AIR = 8.0
	SPEED_DOP_ATTACK = 20.0
	SPEED_DOP_EVADE = 14.0
	SPEED_NORMAL = 12.0
	SPEED_SIDE_STEP = 7.0
	IDLE_TIMER = 3.0
	RESET_TIMER = 3.0
	ALLERTED_AND_KNOWS_LOC_TIMER = 20.0
	ALLERTED_AND_DOESNT_KNOW_LOC_TIMER = 3.0
	IDLE_TURN_TIMER = 3.0
	LOOK_AT_ALLERT_TIMER = 0.5
	ATTACK_CD_TIMER = 1.5
	NOT_IN_AIR_TIMER = 0.5
	animation_tree.set("parameters/IdleAlert/current",0)
	animation_tree.set("parameters/Zero/current",1)
	animation_tree.set("parameters/JumpTransition/current",0)
	animation_tree.set("parameters/JumpBlend/blend_amount",0)
	set_process(true)
	set_physics_process(true)
	animation_tree.active = true
	var place_holder : Spatial = get_node("GlobalParticles")
	place_holder.set_disable_scale(true)
	#$Body.scale.y = (0.9 + 0.2*randf())
	pass
	
func ik_update() -> void:
	ray_l.force_raycast_update()
	ray_r.force_raycast_update()
	if not ray_l.is_colliding():
		#ik_l.interpolation = 0
		pass
	else:
		point_l.global_transform.origin = ray_l.get_collision_point()
		
	if not ray_r.is_colliding():
		#ik_r.interpolation = 0
		pass
	else:
		point_r.global_transform.origin = ray_r.get_collision_point()
	
func ik_setup() -> void:
	if ik_l.is_running() or ik_r.is_running():
		if dist_length > 15:
			ik_l.stop()
			ik_r.stop()
			return
		ik_update()
	else:
		if dist_length <= 15:
			ik_l.start()
			ik_r.start()
			ik_update()
	
func tact_init(delta : float) -> void:
	.tact_init(delta)
	ik_setup()	

func _process(delta : float) -> void:
	if global_transform.origin.y < -50:
		death()
	
func state_machine(delta : float) -> void:
	match _state:
		IDLE:
			if not is_on_floor:
				if timer_not_on_ground >= NOT_IN_AIR_TIMER:
					set_state(AIR)
				else:
					timer_not_on_ground += delta
				return
			idle(delta)
		RESET:
			if reset_self(delta):
				set_state(IDLE)
		ALLERTED_AND_KNOWS_LOC:
			if not is_on_floor:
				if timer_not_on_ground >= NOT_IN_AIR_TIMER:
					set_state(AIR)
				else:
					timer_not_on_ground += delta
				return
			analyze_and_prepare_attack(delta)
			#face_threat(5,delta,player.global_transform.origin,player.global_transform.origin)
		ATTACK_MELEE:
			attack()
			move_to_target(delta, 2.0, -dist, ATTACK_MELEE)
		SHOOT:
			velocityXY = velocityXY.linear_interpolate(Vector3.ZERO, delta)
			speed = SPEED_SIDE_STEP
			face_threat(5,delta,player.global_transform.origin,player.global_transform.origin)
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
				audio.step()
				set_state(JUMP_END)
				
		AIR:
			if is_on_floor:
				animation_tree.set("parameters/JumpTransition/current","JumpEnd")
				audio.step()
				set_state(JUMP_END)
				
		JUMP_END:
			if _timer >= 0.25:
				animation_tree.set("parameters/JumpBlend/blend_amount",0)
				_attack_timer = 0.0
				_shoot_timer = 0.0
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

func set_state(state : int) -> void:
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
			set_deferred("area_detection.monitoring", true)
			animation_tree.set("parameters/IdleAlert/current",2)
		ALLERTED_AND_KNOWS_LOC:
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
		ATTACK_MELEE:
			hitbox.monitoring = true
		SHOOT:
			direction = Vector3.ZERO
		DEATH:
			death()
	
func attack() -> void:
	if hit_confirm:
		var targets = hitbox.get_overlapping_bodies()
		if player in targets:
			audio.hit()
			player.update_health(-attack_damage, self.global_transform.origin)
			hit_confirm = false

func shoot() -> void:
	if player.speed <= player.WALLRUNNING_SPEED:
		Global.spawn_projectile_node_from_pool(projectile,self,shoot.global_transform.origin, (player.transform.origin + Vector3(player.vel_info.x,0,player.vel_info.z)*dist_length/(45*1.2)) + Vector3(0,1,0))
	else:
		Global.spawn_projectile_node_from_pool(projectile,self,shoot.global_transform.origin, (player.transform.origin) + Vector3(0,1,0))

func on_animation_finish(anim_name:String) -> void:
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
			hit_confirm = false
			hitbox.monitoring = false
		"Shoot":
			_shoot_timer = 0.0
			set_state(ALLERTED_AND_KNOWS_LOC)
	
func analyze_and_prepare_attack(delta : float) -> void:
	if not move_around_target(delta):
		evade_maneuver(delta, dist)
	
func move_around_target(delta : float) -> bool:
	if my_path.size() == 0:
		if _path_timer < 5.0:
			_path_timer += delta
		else:
			give_path = true
			
		if _change_dir_timer <= 0.0:
			_change_dir_timer = 2 * randf()
			if side == 0:
				side = 1
			else:
				side = -side
		else:
			_change_dir_timer -= delta
			
		speed = SPEED_SIDE_STEP
		if _change_side_timer >=  0.5:
			match side:
				1:
					right_ray.force_raycast_update()
					if (right_ray.is_colliding()):
						if (self.global_transform.origin.distance_to(right_ray.get_collision_point()) < 2.0):
							left_ray.force_raycast_update()
							if (left_ray.is_colliding()):
								if (self.global_transform.origin.distance_to(left_ray.get_collision_point()) < 2.0):
									side = 0
								else:
									side = -1
							else:
								side = -1
					else:
						right_down_ray.force_raycast_update()
						if not right_down_ray.is_colliding():
							left_down_ray.force_raycast_update()
							if not left_down_ray.is_colliding():
								side = 0
							else:
								side = -1
				-1:
					left_ray.force_raycast_update()
					if (left_ray.is_colliding()):
						if (self.global_transform.origin.distance_to(left_ray.get_collision_point()) < 2.0):
							right_ray.force_raycast_update()
							if (right_ray.is_colliding()):
								if (self.global_transform.origin.distance_to(right_ray.get_collision_point()) < 2.0):
									side = 0
								else:
									side = 1
							else:
								side = 1
					else:
						left_down_ray.force_raycast_update()
						if not left_down_ray.is_colliding():
							right_down_ray.force_raycast_update()
							if not right_down_ray.is_colliding():
								side = 0
							else:
								side = 1
		else:
			_change_side_timer += delta
		move_to_target(delta, 2.0, side * Vector3.UP.cross(dist).normalized(), ALLERTED_AND_KNOWS_LOC)	
		if attack_shoot(delta):
			return true
	else:
		move_along_path(delta)
	return false
		
func attack_shoot(delta : float) -> bool:
	if _attack_timer < ATTACK_CD_TIMER:
		_attack_timer += delta
	if _shoot_timer < SHOOT_CD_TIMER:
		_shoot_timer += delta
	if _attack_timer >= ATTACK_CD_TIMER or _shoot_timer >= SHOOT_CD_TIMER:
		var result = space_state.intersect_ray(self.global_transform.origin,player.global_transform.origin,[self],11)
		if result:
			if result.collider.is_in_group("Player"):
				if dist_length <= 4.5:
						set_state(ATTACK_MELEE)
						animation_tree.set("parameters/Attack/active",true)
						_attack_timer = 0.0
						_shoot_timer = 0.0
						dop_speed = SPEED_DOP_ATTACK
						return true
				else:
						set_state(SHOOT)
						animation_tree.set("parameters/Shoot/active",true)
						_attack_timer = 0.0
						_shoot_timer = 0.0
						SHOOT_CD_TIMER = 1.0+ randf()*0.5
						return true
			else:
				give_path = true
				_path_timer = 0.0
		else:
			give_path = true
			_path_timer = 0.0
			
	return false
		
func move_along_path(delta : float) -> bool:
	speed = SPEED_NORMAL
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
				jump_time_coeff = clamp(jump_time_coeff,0.5,0.8)
				offset = jdist.normalized()
				offset.y = 0
				while (link_to[0] in my_path):
					my_path.remove(0)
				audio.step()
				set_state(JUMP)
				return true
		if dir_to_path.length() < 1.4:
			my_path.remove(0)
		else:
			if not attack_shoot(delta):
				if is_on_wall():
					velocity.y = 1.0
					snap = Vector3.ZERO
			else:
				return true
			if dist_length < 3.5:
				left_ray.force_raycast_update()
				if not left_ray.is_colliding():
					move_to_target(delta, 2.0, Vector3.UP.cross(dir_to_path).normalized(), ALLERTED_AND_KNOWS_LOC,my_path[0])
			else:
				move_to_target(delta, 2.0, dir_to_path, ALLERTED_AND_KNOWS_LOC,my_path[0])
	else:
		if dist2D_length < 3.0:
			move_to_target(delta, 2.0, self.global_transform.basis.z, ALLERTED_AND_KNOWS_LOC)
		else:
			move_to_target(delta, 2.0, Vector3.ZERO, ALLERTED_AND_KNOWS_LOC)
	return false
		
func evade_setup(coef : int, dist_V : Vector3) -> void:
	direction = coef * side * Vector3.UP.cross(dist_V).normalized()
	side = coef * side
	dop_speed = SPEED_DOP_EVADE
	left_down_ray.transform.origin = Vector3(-4.5,-0.155,0)
	right_down_ray.transform.origin = Vector3(4.5,-0.155,0)
	set_state(EVADE)
	
	
func evading(delta : float) -> void:
	match side:
		-1:
			left_down_ray.force_raycast_update()
			if not left_down_ray.is_colliding():
				direction = -dist
				dop_speed = 0.0
				velocityXY = Vector3.ZERO
				side = 1
				left_down_ray.transform.origin = Vector3(-4.5,-0.155,0)
				right_down_ray.transform.origin = Vector3(4.5,-0.155,0)
				set_state(ALLERTED_AND_KNOWS_LOC)
		1:
			right_down_ray.force_raycast_update()
			if not right_down_ray.is_colliding():
				direction = -dist
				dop_speed = 0.0
				velocityXY = Vector3.ZERO
				side = -1
				left_down_ray.transform.origin = Vector3(-4.5,-0.155,0)
				right_down_ray.transform.origin = Vector3(4.5,-0.155,0)
				set_state(ALLERTED_AND_KNOWS_LOC)
				
	if _dop_timer >= 0.25:
		direction = -dist
		dop_speed = 0.0
		side = -side
		left_down_ray.transform.origin = Vector3(-4.5,-0.155,0)
		right_down_ray.transform.origin = Vector3(4.5,-0.155,0)
		set_state(ALLERTED_AND_KNOWS_LOC)
	else:
		_dop_timer += delta
			
	move_to_target(delta, 2.0, -dist, EVADE)
	
func get_nav_path(path : Dictionary) -> void:
	if _state != JUMP and _state != JUMP_END:
		give_path = false
		_path_timer = 0.0
		my_path = path["path"]
		link_from = path["from"]
		link_to = path["to"]


func play_audio(var name : String) -> void:
	match name:
		"Step":
			if is_moving:
				audio.step()
		"StepTurn":
			audio.step()
		"Whoosh":
			audio.whoosh()
			hit_confirm = true
		"Shoot":
			audio.shoot()

func _on_Area_body_entered(body) -> void:
	if _state == IDLE:
		set_state(LOOK_AT_ALLERT)
		set_deferred("area_detection.monitoring", false)
