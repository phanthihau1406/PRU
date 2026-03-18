extends CharacterBody2D

## Helicopter Boss - Level 1
## Pattern: Bay vòng, thả bom và bắn súng máy

signal boss_defeated

@export var max_health: float = 100.0
@export var speed: float = 150.0

var health: float = 100.0
var target: Node2D
var start_pos: Vector2

var attack_timer: float = 0.0
var state: int = 0  # 0: move, 1: bomb, 2: machine_gun
var flash_timer: float = 0.0

var bullet_scene = preload("res://scenes/objects/bullet.tscn")
var bomb_scene = preload("res://scenes/objects/bullet.tscn") # Use bullet as simple bomb for now

func _ready():
	health = max_health
	start_pos = global_position
	add_to_group("enemies")
	add_to_group("bosses")
	z_index = 6

func _physics_process(delta):
	if not target:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			target = players[0]
	
	if not target: return
	
	# Hover movement pattern
	var hover_y = start_pos.y + sin(Time.get_ticks_msec() / 500.0) * 50
	
	# If player is far, chase. If close, hover above or move away slightly
	var dist_x = target.global_position.x - global_position.x
	
	if abs(dist_x) > 300:
		velocity.x = sign(dist_x) * speed
	else:
		velocity.x = sign(dist_x) * speed * 0.5
	
	velocity.y = (hover_y - global_position.y) * 2.0
	
	# Attack patterns
	attack_timer -= delta
	if attack_timer <= 0:
		state = randi() % 3
		match state:
			0:
				attack_timer = 2.0 # Just move
			1:
				_drop_bomb()
				attack_timer = 1.0
			2:
				_fire_machine_gun()
				attack_timer = 2.5
	
	if flash_timer > 0:
		flash_timer -= delta
		
	move_and_slide()
	queue_redraw()

func _drop_bomb():
	if bomb_scene:
		var bomb = bomb_scene.instantiate()
		bomb.setup(global_position + Vector2(0, 30), Vector2.DOWN, 200, 2, Color.RED, false)
		get_tree().current_scene.add_child(bomb)

func _fire_machine_gun():
	if not bullet_scene or not target: return
	
	for i in range(5):
		var bullet = bullet_scene.instantiate()
		var dir = (target.global_position - global_position).normalized().rotated(randf_range(-0.1, 0.1))
		bullet.setup(global_position + Vector2(0, 20), dir, 400, 1, Color(1, 0.8, 0), false)
		get_tree().current_scene.add_child(bullet)
		await get_tree().create_timer(0.1).timeout

func take_damage(amount: float):
	health -= amount
	flash_timer = 0.1
	if health <= 0:
		die()

func die():
	GameManager.add_score(5000)
	boss_defeated.emit()
	
	# Explosions effect
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	tween.tween_callback(queue_free)

func _draw():
	var col = Color(0.2, 0.25, 0.3) if flash_timer <= 0 else Color.WHITE
	
	# Main body
	draw_circle(Vector2(0, 0), 30, col)
	draw_rect(Rect2(-40, -15, 80, 30), col)
	
	# Tail
	var target_x = target.global_position.x if target else 0
	var dir = -1 if target_x > global_position.x else 1
	draw_rect(Rect2(30 * dir, -5, 50 * dir, 10), col)
	draw_rect(Rect2(70 * dir, -15, 10 * dir, 30), col) # Tail rotor support
	
	# Cockpit
	draw_arc(Vector2(-15 * dir, -5), 15, deg_to_rad(180), deg_to_rad(270) if dir > 0 else deg_to_rad(90), 10, Color(0.5, 0.8, 1, 0.5), 15)
	
	# Top rotor
	var t = Time.get_ticks_msec() / 50.0
	draw_rect(Rect2(-5, -35, 10, 5), Color(0.1, 0.1, 0.1))
	draw_line(Vector2(-60 * sin(t), -35), Vector2(60 * sin(t), -35), Color(0.1, 0.1, 0.1, 0.5), 4)

	# Health bar
	draw_rect(Rect2(-40, -50, 80, 5), Color.RED)
	draw_rect(Rect2(-40, -50, 80 * (health/max_health), 5), Color.GREEN)
