extends KinematicBody

export(NodePath) var head_path
export(NodePath) var camera_path
export(NodePath) var weapon_manager_path

export(NodePath) var ray_climb_path
export(NodePath) var ray_top_path
export(NodePath) var ray_top_point_path
export(NodePath) var ray_empty_path

export(NodePath) var timer_can_jump_path
export(NodePath) var timer_can_wall_run_path
export(NodePath) var timer_slide_path
export(NodePath) var timer_can_slide_path

export(NodePath) var animation_player_path

onready var head = get_node(head_path)
onready var camera = get_node(camera_path)
onready var weapon_manager = get_node(weapon_manager_path)

onready var rayClimb = get_node(ray_climb_path)
onready var rayTop = get_node(ray_top_path)
onready var rayTopPoint = get_node(ray_top_point_path)
onready var rayEmpty = get_node(ray_empty_path)

onready var timerCanJump = get_node(timer_can_jump_path)
onready var timerCanWallRun = get_node(timer_can_wall_run_path)
onready var timerSlide = get_node(timer_slide_path)
onready var timerCanSlide = get_node(timer_can_slide_path)

onready var animation_player = get_node(animation_player_path)

onready var defTransform = transform

const ACCEL : float = 10.0
const ACCEL_AIR  : float= 5.0
enum { LEFT, RIGHT, CENTER = -1}
const SPEED_N : float = 20.0
const SPEED_W : float = 25.0
const SPEED_S : float = 100.0

var speed : float = SPEED_N
var accel : float = ACCEL
var gravity : float = 40.0
var jump_power : float = 20.0
var mouseSensivity : float = 0.3

var isceil_tek : bool = true
var isfloor_tek : bool = true
var iswall_tek : bool = true

var dop_velocity : Vector3 = Vector3.ZERO
var velocityXY : Vector3 = Vector3.ZERO
var velocity : Vector3 = Vector3.ZERO
var direction : Vector3 = Vector3.ZERO
var snap : Vector3 = Vector3.ZERO
var wall_normal : KinematicCollision = null

var not_on_moving_platform : bool = true

var canJump : bool = true

var isSliding : bool = false
var canSlide : bool = true

var canWallRun : bool = true

var wall_id : int
var wallrun_dir : Vector3 = Vector3.ZERO
var dot_old : float
var sideW : int = -1
var isWallRunning : bool = false
var wallrun_current_angle : float

####################################################################
var isClimbing : bool = false
var climbPoint : Vector3 = Vector3.ZERO
var rotateTo : Vector3 = Vector3.ZERO
####################################################################

var wall_jump_horizontal_power : float = 5.0
var wall_jump_vertical_power : float = 0.7
var wall_jump_factor : float = 0.4
var coun_wall_jump : int = 3

var interactable_items_count : int = 0

func init() -> void:
		velocityXY = Vector3.ZERO
		velocity = Vector3.ZERO
		direction = Vector3.ZERO
		wallrun_dir = Vector3.ZERO
		snap = Vector3.ZERO

func initSlide() -> void:
	isSliding = true
	velocity.y = 0
	timerSlide.start()
	
func finSlide() -> void:
	canSlide = false
	isSliding = false
	timerCanSlide.start()

func primary_setup(delta) -> void:
	isfloor_tek = is_on_floor()
	iswall_tek = is_on_wall()
	isceil_tek = is_on_ceiling()
	
	
	if (isceil_tek):
		velocity.y -= 9.8
	if (not isfloor_tek):
		if not isClimbing:
			if isSliding:
				velocity.y = 0
			else:
				if isWallRunning:
					velocity.y -= gravity / 30 * delta
				elif iswall_tek and velocity.y <= 0:
					velocity.y -= gravity / 4 * delta
				else:
					velocity.y -= gravity * delta
			if not isWallRunning and iswall_tek:
				rayClimb.enabled = true
			else:
				rayClimb.enabled = false
			
		accel = ACCEL_AIR
		if timerCanJump.is_stopped() and canJump:
			timerCanJump.start()
	else:
		coun_wall_jump = 3
		timerCanWallRun.stop()
		if isSliding:
			velocity.y = 0
		else:
			velocity.y = -0.1
		rayClimb.enabled = false
		canJump = true
		isWallRunning = false
		canWallRun = true
		accel = ACCEL

func floor_jump() -> void:
	if Input.is_action_just_pressed("jump") and canJump:
		canJump = false
		if isSliding:
			timerSlide.stop()
			finSlide()
			velocity.y = 1.25 * jump_power
		else:
			velocity.y = jump_power
		snap = Vector3.ZERO
	else:
		snap = Vector3.DOWN

func movement_inputs() -> void:
	direction = Vector3.ZERO
	if Input.is_action_pressed("move_forward"):
		direction -= self.get_global_transform().basis.z
	elif Input.is_action_pressed("move_backwards"):
		direction += self.get_global_transform().basis.z
				
	if Input.is_action_pressed("move_right"):
		direction += self.get_global_transform().basis.x
	elif Input.is_action_pressed("move_left"):
		direction -= self.get_global_transform().basis.x

func get_side(point) -> int:
	point = to_local(point)
	
	if point.x > 0:
		return LEFT
	elif point.x < 0:
		return RIGHT
	else:
		return CENTER

func wall_run() -> void:
	if canWallRun and Input.is_action_pressed("shift") and Input.is_action_pressed("move_forward") and (velocity.y < (jump_power / 2)) and iswall_tek and not isfloor_tek:
		for n in get_slide_count() :
			wall_normal = get_slide_collision(n)
			var isWall : bool = wall_normal.collider.is_in_group("Wall")
			if (isWall):
				if (not isWallRunning or wall_id != wall_normal.collider_id):
					var wallrun_dir_old : Vector3 = wallrun_dir
					# Нормаль к плоскости стены
					var normal : Vector3 = wall_normal.normal
					
					if normal.angle_to(Vector3.UP) > 1.58:
						return
					# Рассчитываем направление вдоль стены
					wallrun_dir = Vector3.UP.cross(normal)
					# Считываем вектор3 направления камеры
					var player_view_dir : Vector3 = -head.global_transform.basis.z
					# Рассчитываем угол между вектором3 направлением движения и вектором3 направлением камеры
					var dot : float = wallrun_dir.dot(player_view_dir)
					if (isWallRunning):
						# Если при беге по стене перешли на другую стену, сохраняем старый угол для сохранения направления движения
						if (dot_old != dot):
							dot = dot_old
					dot_old = dot
					# В зависимости от угла мы должны поменять сторону направления движения вдоль стены
					if dot < 0:
						wallrun_dir = -wallrun_dir
					# Проверяем под каким углом смотрим на стену. 
					# При небольшом угле бежать по стене не будем.
					if not isWallRunning: 
						# Двумерный вектор2 направления камеры игрока
						var view_dir_2d : Vector2 = Vector2(player_view_dir.x, player_view_dir.z)
						# Двумерный вектор2 стены
						var wallrun_axis_2d : Vector2 = Vector2(wallrun_dir.x, wallrun_dir.z)
						# Угол между вектором2 стены и вектором2 предыдущей стены
						var angle : float = wallrun_axis_2d.angle_to(view_dir_2d)
						angle = rad2deg(angle)
						if dot < 0:
							angle = -angle
						if angle < -75:
							isWallRunning = false
							return
					else:
						# Двумерный вектор2 стены
						var wallrun_axis_2d : Vector2 = Vector2(wallrun_dir.x, wallrun_dir.z)
						# Двумерный вектор2 предыдущей стены
						var wallrun_old_axis_2d : Vector2 = Vector2(wallrun_dir_old.x, wallrun_dir_old.z)
						# Угол между вектором2 стены и вектором2 предыдущей стены
						var angle : float = wallrun_axis_2d.angle_to(wallrun_old_axis_2d)
						angle = rad2deg(angle)
						if dot < 0:
							angle = -angle
						if angle < -75:
							isWallRunning = false
							canWallRun = false
							timerCanWallRun.start()
							return
					# Добавляем к направлению движения небольшую силу в сторону стены, 
					# чтобы не отрываться от неё
					wallrun_dir += -normal * 0.05
					velocity.y = 0
					isWallRunning = true
				# Сохраняем номер последней стены, по которой бежали
				wall_id = wall_normal.collider_id;
				# Расчитываем сторону, противоположную от стены
				sideW = get_side(wall_normal.position)
				# Переопределяем глобальный вектор направления.
				# Ввод пользователя клавишами влево\вправо\назад будет проигнорирован.
				direction = wallrun_dir
				break
	else:
		isWallRunning = false

	if Input.is_action_just_released("shift") and not isWallRunning:
		canWallRun = false
		timerCanWallRun.start()
		
func wall_jump() -> void:
	if isWallRunning:
		if Input.is_action_just_pressed("jump"):
			snap = Vector3.ZERO
			isWallRunning = false
			timerCanWallRun.start()
			velocityXY = Vector3.ZERO
			velocity.y = jump_power * wall_jump_vertical_power
			var normal : Vector3 = wall_normal.normal
			dop_velocity = normal * wall_jump_horizontal_power * wall_jump_factor
			coun_wall_jump = 3
	elif iswall_tek and not isfloor_tek and coun_wall_jump > 0:
		if Input.is_action_just_pressed("jump"):
			snap = Vector3.ZERO
			isWallRunning = false
			velocityXY = Vector3.ZERO
			velocity.y = jump_power * wall_jump_vertical_power
			for n in get_slide_count() :
				wall_normal = get_slide_collision(n)
				var isWall : bool = wall_normal.collider.is_in_group("Wall")
				if (isWall):
					wall_normal = get_slide_collision(0)
					var normal : Vector3 = wall_normal.normal
					dop_velocity = normal * wall_jump_horizontal_power * wall_jump_factor
					coun_wall_jump -= 1
					break
	

func wall_run_and_jump() -> void:
	wall_run()
	wall_jump()
		
func edge_climb(delta) -> void:
	if not isClimbing:
		if iswall_tek and not isWallRunning and rayClimb.enabled and Input.is_action_pressed("move_forward"):
			for n in get_slide_count() :
				if rayClimb.is_colliding():
					if (rayClimb.get_collider() == get_slide_collision(n).collider):
						var ClimbPoint : Vector3 = to_local(rayClimb.get_collision_point())
						var normal : Vector3 = -get_slide_collision(n).normal
						var normal_2d : Vector2 = Vector2(normal.x, normal.z)
						# Считываем вектор3 направления камеры
						var player_view_dir : Vector3 = -head.global_transform.basis.z
						# Двумерный вектор2 направления камеры игрока
						var view_dir_2d : Vector2 = Vector2(player_view_dir.x, player_view_dir.z)
						# Угол между вектором2 стены и вектором2 направлением камеры игрока
						var angleClimb : float = rad2deg(normal_2d.angle_to(view_dir_2d))
						rayEmpty.translation.y = ClimbPoint.y + 0.1
						rayEmpty.rotation_degrees.y = angleClimb
						rayTopPoint.translation.y = ClimbPoint.y
						rayEmpty.force_raycast_update()
						if not rayEmpty.is_colliding():
							rayTop.force_raycast_update()
							if rayTop.is_colliding():
								var TopPoint : Vector3 = to_local(rayTop.get_collision_point())
								if TopPoint.y - ClimbPoint.y < 1.3:
									return
							rayTopPoint.force_raycast_update()
							if rayTopPoint.is_colliding():
								var ClimbTopPoint : Vector3 = to_local(rayTopPoint.get_collision_point())
								if ClimbTopPoint.y - ClimbPoint.y < 1.3:
									return
							rotateTo = Vector3(0,self.rotation_degrees.y + angleClimb,0)
							climbPoint = (rayClimb.get_collision_point())
							isClimbing = true
							isWallRunning = false
							timerSlide.stop()
							finSlide()
							direction = normal * 0.5
							velocity = Vector3(0,jump_power,0)
						break
							
	if isClimbing:
		snap = Vector3.ZERO
		self.rotation_degrees = self.rotation_degrees.linear_interpolate(rotateTo, delta * 10)
		if transform.origin.y > climbPoint.y + 1.25:
			velocity = Vector3(0,-gravity/4,0)
			direction = Vector3.ZERO
			velocity = Vector3.ZERO
			isClimbing = false
		
func sliding() -> void:
	if canSlide and not isWallRunning:
		if Input.is_action_just_pressed("shift"):
			if not isSliding:
				if direction == Vector3.ZERO or isWallRunning:
					direction -= self.get_global_transform().basis.z
				initSlide()

func finalize_velocity(delta) -> void:
	if isSliding:
		speed = SPEED_S
	elif isWallRunning:
		speed = SPEED_W
	else:
		speed = SPEED_N
		
	direction = direction.normalized()
	velocityXY = velocityXY.linear_interpolate(direction * speed, accel * delta) + dop_velocity
	dop_velocity = dop_velocity.linear_interpolate(Vector3.ZERO, accel * delta)
	velocity.x = velocityXY.x
	velocity.z = velocityXY.z
	
	var vel_info = move_and_slide_with_snap(velocity, snap, Vector3.UP, not_on_moving_platform, 4, deg2rad(45))
	
	if vel_info.length() < 3.0 or not isfloor_tek or isSliding or isClimbing:
		animation_player.play("RESET", 0.1, 1.0)
	else:
		animation_player.play("HeadBop", 0.1, 1.5)
		
	
func camera_transform(delta) -> void:
	if isWallRunning:
		if sideW == LEFT:
			wallrun_current_angle += delta * 70
			wallrun_current_angle = clamp(wallrun_current_angle, -15, 15)
		elif sideW == RIGHT:
			wallrun_current_angle -= delta * 70
			wallrun_current_angle = clamp(wallrun_current_angle, -15, 15)
	else:
		if wallrun_current_angle > 0:
			wallrun_current_angle -= delta * 40
			wallrun_current_angle = max(0, wallrun_current_angle)
		elif wallrun_current_angle < 0:
			wallrun_current_angle += delta * 40
			wallrun_current_angle = min(wallrun_current_angle, 0)
	
	camera.rotation_degrees = Vector3(0, 0, 1) * wallrun_current_angle

func process_weapons(delta) -> void:
	if Input.is_action_just_pressed("empty"):
		weapon_manager.change_weapon("Empty")
	if Input.is_action_just_pressed("primary"):
		weapon_manager.change_weapon("Primary")
	if Input.is_action_just_pressed("secondary"):
		weapon_manager.change_weapon("Secondary")

	if weapon_manager.is_weapon_automatic():
		if Input.is_action_pressed("fire"):
			weapon_manager.fire()
		if Input.is_action_just_released("fire"):
			weapon_manager.fire_stop()
	else:
		if Input.is_action_just_pressed("fire"):
			weapon_manager.fire()
		
	if Input.is_action_just_pressed("reload"):
		weapon_manager.reload()
	
	if Input.is_action_just_pressed("drop"):
		weapon_manager.drop_weapon()
	if interactable_items_count > 0:
		weapon_manager.process_weapon_pickup()
	if weapon_manager.current_weapon.name != "Unarmed":
		weapon_manager.current_weapon.sway(delta)
		
	if Input.is_action_pressed("ads"):
		weapon_manager.current_weapon.aim_down_sights(true, delta)
	else:
		weapon_manager.current_weapon.aim_down_sights(false, delta)
		
	
func _ready():
	set_disable_scale(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	set_process(true)
	set_physics_process(true)
	set_process_input(true)
	

func _input(event):
	if event is InputEventMouseMotion:
		head.rotate_x(deg2rad(-event.relative.y * mouseSensivity))
		head.rotation.x = clamp(head.rotation.x, -1.54, 1.54)
		if not isClimbing:
			self.rotate_y(deg2rad(-event.relative.x * mouseSensivity))
		
	if event is InputEventMouseButton:
		if event.pressed:
			match event.button_index:
				BUTTON_WHEEL_UP:
					weapon_manager.next_weapon()
				BUTTON_WHEEL_DOWN:
					weapon_manager.previous_weapon()

func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().quit()
	if transform.origin.y < -50:
		set_physics_process(false)
		init()
		transform = defTransform
		set_physics_process(true)
	
func _physics_process(delta):
	primary_setup(delta)
	floor_jump()
	edge_climb(delta)
	if not isClimbing and not isSliding:
		movement_inputs()
		wall_run_and_jump()
	sliding()
	camera_transform(delta)
	finalize_velocity(delta)
	process_weapons(delta)

################################## Таймеры ##################################

func _on_CanJump_timeout():
	if canJump:
		canJump = false

func _on_CanWallRun_timeout():
	canWallRun = true

func _on_Slide_timeout():
		finSlide()

func _on_canSlide_timeout():
	canSlide = true
