extends CharacterBody2D

## Boss Building - Tòa nhà cửa ngõ Sài Gòn (Màn 3)
## Bắn rát từ các tầng, gọi thêm lính

signal boss_defeated

@export var max_health: float = 300.0

var health: float = 300.0
var target: Node2D
var attack_timer: float = 0.0
var spawn_timer: float = 3.0
var flash_timer: float = 0.0

var bullet_scene = preload("res://scenes/objects/bullet.tscn")
var enemy_scene = preload("res://scenes/Enemy/Enemy.tscn")

func _ready():
	health = max_health
	add_to_group("enemies")
	add_to_group("bosses")
	z_index = -5

func _physics_process(delta):
	if not target:
		find_target()
			
	attack_timer -= delta
	if attack_timer <= 0:
		_shoot_from_windows()
		attack_timer = 1.5
		
	spawn_timer -= delta
	if spawn_timer <= 0:
		_spawn_guard()
		spawn_timer = 5.0
			
	if flash_timer > 0:
		flash_timer -= delta
		
	queue_redraw()

func find_target():
	var tanks = get_tree().get_nodes_in_group("tank")
	if tanks.size() > 0 and tanks[0].driver != null:
		target = tanks[0]
	else:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			target = players[0]

func _shoot_from_windows():
	if not bullet_scene or not target: return
	
	# Bắn từ 3 tầng
	var heights = [-50, -150, -250]
	for h in heights:
		var bullet = bullet_scene.instantiate()
		var spawn_pos = global_position + Vector2(-60, h)
		var dir = (target.global_position - spawn_pos).normalized()
		bullet.setup(spawn_pos, dir, 400, 2, Color.YELLOW, false)
		get_tree().current_scene.add_child(bullet)

func _spawn_guard():
	if not enemy_scene: return
	var enemy = enemy_scene.instantiate()
	enemy.global_position = global_position + Vector2(-100, 0)
	if "topdown_mode" in enemy:
		enemy.topdown_mode = true
	get_tree().current_scene.add_child(enemy)

func take_damage(amount: float):
	health -= amount
	flash_timer = 0.1
	if health <= 0:
		die()

func die():
	GameManager.add_score(10000)
	boss_defeated.emit()
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 2.0)
	tween.tween_callback(queue_free)

func _draw():
	var col = Color(0.6, 0.6, 0.5) if flash_timer <= 0 else Color.WHITE
	var window_col = Color(0.1, 0.1, 0.2)
	if attack_timer < 0.2: window_col = Color(0.9, 0.8, 0.2) # Flash when shooting
	
	# Main structure
	draw_rect(Rect2(-80, -300, 160, 300), col)
	
	# Windows
	for y in range(3):
		for x in range(3):
			draw_rect(Rect2(-60 + x * 45, -280 + y * 90, 30, 40), window_col)
			
	# Entrance
	draw_rect(Rect2(-30, -50, 60, 50), Color(0.2, 0.1, 0.1))
	
	# Details
	draw_rect(Rect2(-90, -310, 180, 20), col.darkened(0.2)) # Roof edge
	
	# Health bar
	draw_rect(Rect2(-80, -330, 160, 10), Color.RED)
	draw_rect(Rect2(-80, -330, 160 * (health/max_health), 10), Color.GREEN)
