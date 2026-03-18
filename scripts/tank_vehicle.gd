extends CharacterBody2D

## Tank Vehicle - Player có thể leo lên lái bật chế độ tàn phá
## Bắn đạn pháo cực mạnh, không thể nhảy nhưng cán qua chướng ngại vật

var bullet_scene = preload("res://scenes/objects/bullet.tscn")

@export var max_health: float = 50.0
@export var speed: float = 150.0

var health: float = 50.0
var driver: Node2D = null
var shoot_timer: float = 0.0
var flash_timer: float = 0.0
var gravity: float = 900.0
var facing_right: bool = true
var aim_direction: Vector2 = Vector2.RIGHT

func _ready():
	add_to_group("tank")

func _physics_process(delta):
	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta
		
	if driver:
		_process_driver_input(delta)
	else:
		velocity.x = lerp(velocity.x, 0.0, 5 * delta)
		# Check for player entering
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			var p = players[0]
			if global_position.distance_to(p.global_position) < 60 and Input.is_action_just_pressed("interact"):
				mount(p)
	
	if flash_timer > 0:
		flash_timer -= delta
		
	move_and_slide()
	queue_redraw()

func _process_driver_input(delta):
	if Input.is_action_just_pressed("interact"):
		dismount()
		return
		
	var input_dir = Input.get_axis("move_left", "move_right")
	velocity.x = input_dir * speed
	
	if input_dir > 0:
		facing_right = true
	elif input_dir < 0:
		facing_right = false

	# Aim direction (8 directions)
	var aim = Vector2.ZERO
	if Input.is_action_pressed("move_right"):
		aim.x = 1
	elif Input.is_action_pressed("move_left"):
		aim.x = -1
	else:
		aim.x = 1 if facing_right else -1
	if Input.is_action_pressed("move_up"):
		aim.y = -1
	elif Input.is_action_pressed("move_down"):
		aim.y = 1
	if aim != Vector2.ZERO:
		aim_direction = aim.normalized()
	
	shoot_timer -= delta
	if Input.is_action_pressed("shoot") and shoot_timer <= 0:
		_shoot()
		shoot_timer = 1.0

func _shoot():
	if not bullet_scene: return
	
	var bullet = bullet_scene.instantiate()
	var dir = aim_direction
	bullet.setup(global_position + dir * 60 + Vector2(0, -20), dir, 800, 10, Color(1, 0.5, 0), true)
	bullet.scale = Vector2(3, 3) # Big cannon ball
	get_tree().current_scene.add_child(bullet)

func mount(p: Node2D):
	driver = p
	p.in_tank = true
	p.visible = false
	p.global_position = global_position # Keep player inside tank

func dismount():
	if driver:
		driver.in_tank = false
		driver.visible = true
		driver.global_position = global_position + Vector2(0, -50)
		driver = null

func take_damage(amount: float):
	health -= amount
	flash_timer = 0.1
	if health <= 0:
		explode()

func explode():
	if driver: dismount()
	# TODO visual explosion here
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	tween.tween_callback(queue_free)

func _draw():
	var col = Color(0.2, 0.3, 0.1) if flash_timer <= 0 else Color.WHITE
	var wheel_col = Color(0.1, 0.1, 0.1)
	
	var dir = 1 if facing_right else -1
	
	# Hatch / Turret
	draw_rect(Rect2(-20, -35, 40, 20), col)
	draw_circle(Vector2(0, -35), 10, col)
	
	# Main body
	draw_rect(Rect2(-45, -15, 90, 25), col)
	
	# Beveled front/back
	draw_triangle(Vector2(45 * dir, -15), Vector2(55 * dir, 10), Vector2(45 * dir, 10), col)
	draw_triangle(Vector2(-45 * dir, -15), Vector2(-55 * dir, 10), Vector2(-45 * dir, 10), col)
	
	# Gun barrel
	var barrel_base = Vector2(10 * dir, -25)
	var barrel_end = barrel_base + aim_direction * 60
	draw_line(barrel_base, barrel_end, Color(0.15, 0.2, 0.1), 8)
	
	# Tracks
	draw_rect(Rect2(-50, 10, 100, 15), Color(0.2, 0.2, 0.2))
	# Wheels inside track
	for i in range(5):
		draw_circle(Vector2(-40 + i * 20, 17.5), 6, wheel_col)
	
	# "Interact" prompt if empty
	if not driver and global_position.distance_to(get_tree().get_nodes_in_group("player")[0].global_position if get_tree().get_nodes_in_group("player").size() > 0 else Vector2(-1000, -1000)) < 60:
		draw_string(ThemeDB.fallback_font, Vector2(-40, -60), "[Enter] Lên xe", HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color.YELLOW)
	
	# Health bar if driver
	if driver:
		draw_rect(Rect2(-40, -50, 80, 5), Color.RED)
		draw_rect(Rect2(-40, -50, 80 * (health/max_health), 5), Color.GREEN)

func draw_triangle(p1: Vector2, p2: Vector2, p3: Vector2, color: Color):
	var points = PackedVector2Array([p1, p2, p3])
	draw_colored_polygon(points, color)
