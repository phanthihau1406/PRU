extends CharacterBody2D

## Boss Fortress - Căn cứ phòng thủ (Boss Màn 2)
## Đứng yên trên mặt đất, liên tục bắn tên lửa/đạn pháo

signal boss_defeated

@export var max_health: float = 200.0
@export var damage: int = 2

var health: float = 200.0
var target: Node2D
var attack_timer: float = 0.0
var flash_timer: float = 0.0

var bullet_scene = preload("res://scenes/objects/bullet.tscn")
var state: int = 0
var angle_sweep: float = 0.0

func _ready():
	health = max_health
	add_to_group("enemies")
	add_to_group("bosses")
	z_index = -5

func _physics_process(delta):
	if not target:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			target = players[0]
			
	attack_timer -= delta
	if attack_timer <= 0:
		# Alternate attacks
		state = 1 - state
		if state == 0:
			_fire_spread(delta)
			attack_timer = 2.0
		else:
			_fire_homing()
			attack_timer = 2.5
			
	if flash_timer > 0:
		flash_timer -= delta
		
	queue_redraw()

func _fire_spread(_delta):
	if not bullet_scene: return
	
	# Bắn đạn tỏa ra 5 hướng
	for i in range(5):
		var bullet = bullet_scene.instantiate()
		var dir = Vector2(-1, 0).rotated(deg_to_rad(-45 + i*22.5))
		bullet.setup(global_position + Vector2(-50, -40), dir, 300, 2, Color.ORANGE, false)
		get_tree().current_scene.add_child(bullet)

func _fire_homing():
	if not bullet_scene or not target: return
	# Bắn đạn tốc độ chậm nhưng ngắm thẳng player (tạm làm đạn thẳng nhanh)
	var bullet = bullet_scene.instantiate()
	var dir = (target.global_position - (global_position + Vector2(-30, -80))).normalized()
	bullet.setup(global_position + Vector2(-30, -80), dir, 500, 3, Color.RED, false)
	# Làm đạn bự hơn
	bullet.scale = Vector2(2, 2) 
	get_tree().current_scene.add_child(bullet)

func take_damage(amount: float):
	health -= amount
	flash_timer = 0.1
	if health <= 0:
		die()

func die():
	GameManager.add_score(8000)
	boss_defeated.emit()
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.5)
	tween.tween_callback(queue_free)

func _draw():
	var col = Color(0.4, 0.4, 0.45) if flash_timer <= 0 else Color.WHITE
	var dark_col = Color(0.2, 0.2, 0.25)
	
	# Platform
	draw_rect(Rect2(-80, -20, 160, 70), dark_col)
	# Bunker block
	draw_rect(Rect2(-60, -60, 120, 40), col)
	# Turret cap
	draw_arc(Vector2(0, -60), 40, deg_to_rad(180), deg_to_rad(360), 16, col, 80)
	# Gun barrel 1 (Spread)
	draw_rect(Rect2(-80, -45, 30, 10), Color(0.1, 0.1, 0.1))
	# Gun barrel 2 (Big cannon)
	var dir = Vector2(-1, 0)
	if target:
		dir = (target.global_position - (global_position + Vector2(0, -80))).normalized()
	
	draw_line(Vector2(0, -80), Vector2(0, -80) + dir * 60, dark_col, 15)
	
	# Health bar on top
	draw_rect(Rect2(-60, -120, 120, 8), Color.RED)
	draw_rect(Rect2(-60, -120, 120 * (health/max_health), 8), Color.GREEN)
