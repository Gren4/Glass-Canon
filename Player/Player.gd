extends KinematicBody

const ACCEL : float = 10.0
const ACCEL_AIR  : float= 5.0
const LEFT : int = 0
const RIGHT : int = 1
const CENTER : int = -1
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

var velocityXY : Vector3 = Vector3.ZERO
var velocity : Vector3 = Vector3.ZERO
var direction : Vector3 = Vector3.ZERO
var snap : Vector3 = Vector3.ZERO

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

var isWallJumping : bool = false
var wall_jump_dir : Vector3 = Vector3.ZERO
var wall_jump_horizontal_power : float = 5.0
var wall_jump_vertical_power : float = 0.7
var wall_jump_factor : float = 0.4

onready var head = $Head
onready var camera = $Head/Camera
onready var weapon_manager = $Head/Weapons
onready var rayClimb = $ClimbRays/RayClimb
onready var rayTop = $ClimbRays/RayTop
onready var rayEmpty = $ClimbRays/RayEmpty

onready var timerWallJump = $Timers/WallJump
onready var timerCanJump = $Timers/CanJump
onready var timerCanWallRun = $Timers/CanWallRun
onready var timerSlide = $Timers/Slide
onready var timerCanSlide = $Timers/CanSlide

onready var animation_player = $AnimationPlayer

onready var defTransform = transform

func init() -> void:
		velocityXY = Vector3.ZERO
		velocity = Vector3.ZERO
		direction = Vector3.ZERO
		wallrun_dir = Vector3.ZERO
		snap = Vector3.ZERO

func initSlide() -> void:
	isSliding = true
	velocity.y = 0
#	$MeshInstance.mesh.mid_height = 0.4
#	$CollisionShape.shape.height = 0.4
#	head.translation.y = 0.4
	timerSlide.start()
	
func finSlide() -> void:
	canSlide = false
	isSliding = false
	velocity.y = 0
#	$MeshInstance.mesh.mid_height = 1.25
#	$CollisionShape.shape.height = 1.25
#	head.translation.y = 0.818
	timerCanSlide.start()

func primary_setup(delta) -> void:
	isfloor_tek = is_on_floor()
	iswall_tek = is_on_wall()
	isceil_tek = is_on_ceiling()
	
	if (isceil_tek):
		velocity.y = -gravity/4
	
	if (not isfloor_tek):
		if not isClimbing:
			if isSliding:
				velocity.y = 0
			else:
				velocity.y -= gravity*delta
			if not isWallRunning and iswall_tek:
				rayClimb.enabled = true
				rayTop.enabled = true
				#rayEmpty.enabled = true
			else:
				rayClimb.enabled = false
				rayTop.enabled = false
				#rayEmpty.enabled = false
			
		accel = ACCEL_AIR
		if timerCanJump.is_stopped() and canJump:
			timerCanJump.start()
	else:
		timerCanWallRun.stop()
		timerWallJump.stop()
		if isSliding:
			velocity.y = 0
		else:
			velocity.y = -0.1
		rayClimb.enabled = false
		rayTop.enabled = false
		#rayEmpty.enabled = false
		canJump = true
		isWallRunning = false
		isWallJumping = false
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
	var wall_normal : KinematicCollision
	if canWallRun and Input.is_action_pressed("shift") and Input.is_action_pressed("move_forward") and (velocity.y < (jump_power / 2)) and iswall_tek and not isfloor_tek:
		for n in get_slide_count() :
			wall_normal = get_slide_collision(n)
			var isWall : bool = wall_normal.collider.is_in_group("Wall")
			if (isWall):
				if (not isWallRunning or wall_id != wall_normal.collider_id):
					var wallrun_dir_old : Vector3 = wallrun_dir
					# Нормаль к плоскости стены
					var normal : Vector3 = wall_normal.normal
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
					if (isWallRunning):
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
					isWallRunning = true
					# Сбрасываем признак
					isWallJumping = false
				# Сохраняем номер последней стены, по которой бежали
				wall_id = wall_normal.collider_id;
				# Выставляем небольшую силу, тянущую вниз
				velocity.y = -0.01
				# Расчитываем сторону, противоположную от стены
				sideW = get_side(wall_normal.position)
				# Переопределяем глобальный вектор направления.
				# Ввод пользователя клавишами влево\вправо\назад будет проигнорирован.
				direction = wallrun_dir
			else:
				isWallRunning = false
			break
	else:
		isWallRunning = false

	if Input.is_action_just_released("shift") and not isWallRunning and not isWallJumping:
		canWallRun = false
		timerCanWallRun.start()
		
	if isWallRunning:
		if Input.is_action_just_pressed("jump"):
			snap = Vector3.ZERO
			isWallRunning = false
			timerCanWallRun.start()
			velocityXY = Vector3.ZERO
			isWallJumping = true
			timerWallJump.start()
			velocity.y = jump_power * wall_jump_vertical_power
			var normal : Vector3 = wall_normal.normal
			wall_jump_dir = normal * wall_jump_horizontal_power
			wall_jump_dir *= wall_jump_factor
	elif iswall_tek and not isfloor_tek:
		if Input.is_action_just_pressed("jump"):
			snap = Vector3.ZERO
			isWallRunning = false
			velocityXY = Vector3.ZERO
			isWallJumping = true
			timerWallJump.start()
			velocity.y = jump_power * wall_jump_vertical_power
			wall_normal = get_slide_collision(0)
			var normal : Vector3 = wall_normal.normal
			wall_jump_dir = normal * wall_jump_horizontal_power
			wall_jump_dir *= wall_jump_factor
						
	if isWallJumping:
		direction += wall_jump_dir
		
func edge_climb(delta) -> void:
	if not isClimbing:
		if rayTop.enabled:
			if rayTop.is_colliding() and  1.5 * transform.origin.y >= rayTop.get_collision_point().y:
				pass
			else:
				if rayEmpty.enabled:
					if not rayEmpty.is_colliding():
						if iswall_tek and not isWallRunning and rayClimb.enabled and Input.is_action_pressed("move_forward"):
							if rayClimb.is_colliding():
								for n in get_slide_count() :
									if (rayClimb.get_collider() == get_slide_collision(n).collider):
										var normal : Vector3 = -get_slide_collision(n).normal
										var normal_2d : Vector2 = Vector2(normal.x, normal.z)
										# Считываем вектор3 направления камеры
										var player_view_dir : Vector3 = -head.global_transform.basis.z
										# Двумерный вектор2 направления камеры игрока
										var view_dir_2d : Vector2 = Vector2(player_view_dir.x, player_view_dir.z)
										# Угол между вектором2 стены и вектором2 направлением камеры игрока
										var angleClimb : float = rad2deg(normal_2d.angle_to(view_dir_2d))
										rotateTo = Vector3(0,self.rotation_degrees.y + angleClimb,0)
										climbPoint = (rayClimb.get_collision_point())
										isClimbing = true
										isWallRunning = false
										isWallJumping = false
										direction = normal * 0.5
										velocity = Vector3(0,jump_power,0)
	if isClimbing:
		snap = Vector3.ZERO
		head.rotation = head.rotation.linear_interpolate(Vector3.ZERO, delta * 10)
		self.rotation_degrees = self.rotation_degrees.linear_interpolate(rotateTo, delta * 10)
		if transform.origin.y > climbPoint.y + 1.25:
			velocity = Vector3(0,-gravity/4,0)
		if isfloor_tek:
			direction = Vector3.ZERO
			velocity = Vector3.ZERO
			isClimbing = false
		
func sliding() -> void:
	if canSlide:
		if Input.is_action_just_pressed("slide"):
			if not isSliding:
				if direction == Vector3.ZERO:
					direction -= self.get_global_transform().basis.z
				initSlide()
#	if isSliding:
#		if rayTop.enabled:
#			if not isceil_tek:
#				if rayTop.is_colliding():
#					if 1.7 * transform.origin.y >= rayTop.get_collision_point().y:
#						timerSlide.paused = true
#				else:
#					timerSlide.paused = false
#			else:
#				timerSlide.stop()
#				finSlide()
		
func finalize_velocity(delta) -> void:
	if isSliding:
		speed = SPEED_S
	elif isWallRunning:
		speed = SPEED_W
	else:
		speed = SPEED_N
		
	direction = direction.normalized()
	velocityXY = velocityXY.linear_interpolate(direction * speed, accel * delta)
	
	velocity.x = velocityXY.x
	velocity.z = velocityXY.z
	
	var vel_info = move_and_slide_with_snap(velocity, snap, Vector3.UP, true, 4, deg2rad(45))
	
	if vel_info.length() > 3.0 and canJump and not isClimbing and not isWallJumping and not isWallRunning and not isSliding:
		animation_player.play("HeadBop", 0.1, 1.5)
	else:
		animation_player.play("RESET", 0.1, 1.0)
		
	
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

func process_weapons():
	if Input.is_action_just_pressed("empty"):
		weapon_manager.change_weapon("Empty")
	if Input.is_action_just_pressed("primary"):
		weapon_manager.change_weapon("Primary")
	if Input.is_action_just_pressed("secondary"):
		weapon_manager.change_weapon("Secondary")

	if weapon_manager.is_automatic():
		if Input.is_action_pressed("fire"):
			weapon_manager.fire()
		if Input.is_action_just_released("fire"):
			weapon_manager.fire_stop()
	else:
		if Input.is_action_just_pressed("fire"):
			weapon_manager.fire()
		
	if Input.is_action_just_pressed("reload"):
		weapon_manager.reload()
		
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	set_process(true)
	set_physics_process(true)

func _input(event):
	if event is InputEventMouseMotion and not isClimbing:
		head.rotate_x(deg2rad(-event.relative.y * mouseSensivity))
		head.rotation.x = clamp(head.rotation.x, -1.54, 1.54)
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
	
	if not isClimbing and not isSliding:
		movement_inputs()
		wall_run()
	
	sliding()
	
	edge_climb(delta)
	
	camera_transform(delta)
	
	finalize_velocity(delta)
	
	process_weapons()

################################## Таймеры ##################################
func _on_WallJump_timeout():
	wall_jump_dir = Vector3.ZERO
	isWallJumping = false


func _on_CanJump_timeout():
	if canJump:
		canJump = false


func _on_CanWallRun_timeout():
	canWallRun = true


func _on_Slide_timeout():
		finSlide()


func _on_canSlide_timeout():
	canSlide = true
