extends CharacterBody2D

## Boss Final - Màn 4 (Dinh Độc Lập)
## Chỉ huy địch - di chuyển nhanh, bắn đạn chùm, lao tới (dash)

signal boss_defeated

@export var max_health: float = 400.0
@export var speed: float = 250.0

var health: float = 400.0
var target: Node2D
var attack_timer: float = 0.0
var flash_timer: float = 0.0

var bullet_scene = preload("res://scenes/objects/bullet.tscn")
var state: int = 0
var facing_right: bool = false
var dash_target: Vector2
var is_dashing: bool = false
var leg_angle: float = 0.0

func _ready():
	health = max_health
	add_to_group("enemies")
	add_to_group("bosses")
	z_index = 5

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += 900.0 * delta # Gravity
		
	if not target:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			target = players[0]
			
	if not target: return
	
	if is_dashing:
		velocity.x = 800 * (1 if facing_right else -1)
		if (facing_right and global_position.x > dash_target.x) or (not facing_right and global_position.x < dash_target.x):
			is_dashing = false
			velocity.x = 0
	else:
		attack_timer -= delta
		if attack_timer <= 0:
			state = randi() % 3
			match state:
				0:
					_shoot_burst()
					attack_timer = 2.0
				1:
					_shoot_spread()
					attack_timer = 2.0
				2:
					_start_dash()
					attack_timer = 3.0
					
		# Normal movement towards player
		if global_position.distance_to(target.global_position) > 200:
			var dir = sign(target.global_position.x - global_position.x)
			velocity.x = dir * speed
			facing_right = dir > 0
		else:
			velocity.x = 0
			facing_right = target.global_position.x > global_position.x
			
	if flash_timer > 0:
		flash_timer -= delta
		
	# Animation
	if abs(velocity.x) > 10:
		leg_angle += delta * 15 * (1 if is_dashing else 0.5)
	
	move_and_slide()
	queue_redraw()

func _shoot_burst():
	if not bullet_scene or not target: return
	for i in range(3):
		var bullet = bullet_scene.instantiate()
		var dir = (target.global_position - global_position).normalized()
		bullet.setup(global_position + Vector2(0, -20), dir, 500, 2, Color.MAGENTA, false)
		get_tree().current_scene.add_child(bullet)
		await get_tree().create_timer(0.2).timeout

func _shoot_spread():
	if not bullet_scene or not target: return
	var base_dir = (target.global_position - global_position).normalized()
	for i in range(5):
		var bullet = bullet_scene.instantiate()
		var dir = base_dir.rotated(deg_to_rad(-30 + i * 15))
		bullet.setup(global_position + Vector2(0, -20), dir, 400, 1, Color.RED, false)
		get_tree().current_scene.add_child(bullet)

func _start_dash():
	is_dashing = true
	dash_target = target.global_position

func take_damage(amount: float):
	health -= amount
	flash_timer = 0.1
	if health <= 0:
		die()

func die():
	GameManager.add_score(20000)
	boss_defeated.emit()
	queue_free()

func _draw():
	var col = Color(0.2, 0.1, 0.1) if flash_timer <= 0 else Color.WHITE
	var skin_color = Color(0.85, 0.7, 0.55)
	var dir = 1 if facing_right else -1
	
	# Dash effect trail
	if is_dashing:
		draw_rect(Rect2(-10 - 30 * dir, -30, 20, 30), Color(col, 0.3))
		draw_rect(Rect2(-10 - 60 * dir, -30, 20, 30), Color(col, 0.1))
	
	# Legs
	var lr = sin(leg_angle) * (40 if is_dashing else 20)
	draw_line(Vector2(-3 * dir, -5), Vector2(-3 * dir + sin(deg_to_rad(lr)) * 10, 15), col, 4)
	draw_line(Vector2(3 * dir, -5), Vector2(3 * dir - sin(deg_to_rad(lr)) * 10, 15), col, 4)
	
	# Body
	draw_rect(Rect2(-8, -25, 16, 20), col)
	
	# Head
	draw_circle(Vector2(0, -32), 7, skin_color)
	
	# Officer Hat
	draw_rect(Rect2(-10, -42, 20, 8), Color(0.15, 0.15, 0.2))
	draw_rect(Rect2(-12 * dir, -35, 15, 3), Color(0.1, 0.1, 0.15)) # brim
	draw_circle(Vector2(0, -38), 2, Color.YELLOW) # badge
	
	# Gun
	draw_line(Vector2(5 * dir, -15), Vector2(20 * dir, -15), Color(0.3, 0.3, 0.3), 4)
	
	# Health bar
	draw_rect(Rect2(-30, -55, 60, 6), Color.RED)
	draw_rect(Rect2(-30, -55, 60 * (health/max_health), 6), Color.GREEN)
