extends Node2D

## Enemy Airplane - Patrols, detects player, chases and SHOOTS at player
## Uses AnimatedSprite2D: fly
## Stops chasing if player hides under TileMap tiles (roof/cover)

signal enemy_died(enemy)

@export var speed: float = 160.0
@export var health: float = 10.0
@export var damage: int = 2
@export var patrol_min_x: float = 100.0
@export var patrol_max_x: float = 1500.0
@export var patrol_y: float = -80.0
@export var detection_range: float = 500.0
@export var chase_speed: float = 200.0
@export var shoot_cooldown: float = 1.5

enum State { PATROL, CHASE, DEAD }
var state: State = State.PATROL
var direction: float = 1.0
var shoot_timer: float = 0.0
var death_timer: float = 0.0
var lost_sight_timer: float = 0.0  # Grace period before returning to patrol

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
var bullet_scene = preload("res://scenes/objects/bullet.tscn")

func _ready():
	add_to_group("enemies")
	z_index = 8
	
	if patrol_y == -80.0:
		patrol_y = global_position.y
	
	if anim_sprite:
		anim_sprite.play("fly")

func _physics_process(delta):
	if state == State.DEAD:
		death_timer -= delta
		# Fall down with smoke effect
		global_position.y += 200 * delta
		rotation += delta * 2.0
		if death_timer <= 0:
			queue_free()
		return
	
	var player = _find_player()
	var can_see_player = false
	var dist_to_player = INF
	
	if player and not player.is_dead:
		dist_to_player = global_position.distance_to(player.global_position)
		if dist_to_player < detection_range:
			can_see_player = _check_line_of_sight(player)
	
	match state:
		State.PATROL:
			_patrol(delta)
			if can_see_player:
				state = State.CHASE
				lost_sight_timer = 0.0
		State.CHASE:
			if can_see_player and player:
				lost_sight_timer = 0.0
				_chase(player, delta)
				_try_shoot(player, delta)
			else:
				# Grace period: keep chasing last known direction for 2 seconds
				lost_sight_timer += delta
				if lost_sight_timer > 2.0:
					state = State.PATROL
				else:
					# Continue flying in last direction
					global_position.x += direction * speed * delta
	
	# Update sprite direction
	if anim_sprite:
		anim_sprite.flip_h = direction < 0

func _patrol(delta):
	global_position.x += direction * speed * delta
	
	# Slight sine wave altitude
	global_position.y = patrol_y + sin(Time.get_ticks_msec() / 1000.0) * 8.0
	
	if global_position.x > patrol_max_x:
		direction = -1.0
	elif global_position.x < patrol_min_x:
		direction = 1.0

func _chase(player: Node2D, delta):
	# Fly above player, maintain altitude
	var target_y = player.global_position.y - 100
	
	if player.global_position.x > global_position.x:
		direction = 1.0
	else:
		direction = -1.0
	
	global_position.x += direction * chase_speed * delta
	global_position.y = move_toward(global_position.y, target_y, 80 * delta)
	
	# Loosened bounds during chase
	global_position.x = clampf(global_position.x, patrol_min_x - 300, patrol_max_x + 300)

func _try_shoot(player: Node2D, delta):
	shoot_timer -= delta
	if shoot_timer <= 0:
		_fire_at_player(player)
		shoot_timer = shoot_cooldown

func _fire_at_player(player: Node2D):
	if not bullet_scene:
		return
	
	# Shoot bullet aimed at player
	var bullet = bullet_scene.instantiate()
	var dir = (player.global_position - global_position).normalized()
	bullet.setup(
		global_position + Vector2(0, 15),
		dir,
		350.0,
		damage,
		Color(1.0, 0.45, 0.1),
		false  # Not player bullet
	)
	get_tree().current_scene.add_child(bullet)
	
	# Also drop a bomb straight down occasionally
	if randf() < 0.3:
		var bomb = bullet_scene.instantiate()
		var bomb_dir = Vector2(direction * 0.1, 1.0).normalized()
		bomb.setup(
			global_position + Vector2(0, 15),
			bomb_dir,
			180.0,
			damage,
			Color(1.0, 0.3, 0.0),
			false
		)
		get_tree().current_scene.add_child(bomb)

func _check_line_of_sight(player: Node2D) -> bool:
	# Cast a ray from airplane DOWN to the player
	# If a TileMap tile blocks the ray, player is hiding under cover
	var space_state = get_world_2d().direct_space_state
	if not space_state:
		return true
	
	# Ray from airplane to player - checks if tilemap is between them
	var query = PhysicsRayQueryParameters2D.create(
		global_position,
		player.global_position,
		1  # Only check terrain layer (layer 1 = TileMap)
	)
	# Exclude the player body from the ray
	if player is CollisionObject2D:
		query.exclude = [player.get_rid()]
	
	var result = space_state.intersect_ray(query)
	
	# If ray hit tilemap before reaching player, player is hidden under tiles
	if result:
		return false
	
	# Also check if there are tiles directly above the player (roof check)
	var above_query = PhysicsRayQueryParameters2D.create(
		player.global_position + Vector2(0, -5),
		player.global_position + Vector2(0, -50),
		1  # terrain layer
	)
	if player is CollisionObject2D:
		above_query.exclude = [player.get_rid()]
	
	var above_result = space_state.intersect_ray(above_query)
	if above_result:
		# There are tiles above the player = player is under cover
		return false
	
	return true

func _find_player() -> Node2D:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	return null

func take_damage(amount: float):
	health -= amount
	if anim_sprite:
		anim_sprite.modulate = Color(1.5, 1.2, 1.0)
		var tw = create_tween()
		tw.tween_property(anim_sprite, "modulate", Color.WHITE, 0.15)
	if health <= 0:
		die()

func die():
	state = State.DEAD
	GameManager.add_score(500)
	enemy_died.emit(self)
	death_timer = 1.5
	remove_from_group("enemies")
