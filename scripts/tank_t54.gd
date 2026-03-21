extends CharacterBody2D

signal tank_destroyed

@export var max_health: float = 10.0
var current_health: float
var speed: float = 20.0
var is_dead: bool = false
var shoot_timer: float = 0.0
var shoot_cooldown: float = 2.0

var bullet_scene = preload("res://scenes/objects/bullet.tscn")
var sfx_shoot: AudioStreamPlayer2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $ProgressBar
var raycast: RayCast2D

func _ready():
	current_health = max_health
	if get_node_or_null("ProgressBar"):
		health_bar.max_value = max_health
		health_bar.value = current_health
	
	add_to_group("allies")
	add_to_group("t54_tank")
	collision_layer = 16 # Allies
	collision_mask = 1 | 2 # Terrain (1) and Enemies (2)
	
	# Add RayCast2D for detecting enemies
	raycast = RayCast2D.new()
	raycast.target_position = Vector2(400, 0) # Look 400 pixels ahead
	raycast.collision_mask = 2 # Detect enemies
	add_child(raycast)
	
	# Add Shooting Sound
	sfx_shoot = AudioStreamPlayer2D.new()
	sfx_shoot.stream = load("res://assets/audio/tiengNo.mp3")
	sfx_shoot.volume_db = -10.0
	sfx_shoot.pitch_scale = 1.5
	add_child(sfx_shoot)

func _physics_process(delta):
	if is_dead: return
	
	if not is_on_floor():
		velocity.y += 900.0 * delta
		
	var player_in_range = false
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var p = players[0]
		if global_position.distance_to(p.global_position) < 600.0:
			player_in_range = true
			
		# Disable collision with player so they can walk through
		if not get_collision_exceptions().has(p):
			add_collision_exception_with(p)
		
	var enemy_in_front = false
	if raycast.is_colliding():
		var col = raycast.get_collider()
		if col and col.is_in_group("enemies"):
			enemy_in_front = true
			
	if enemy_in_front:
		velocity.x = 0
		anim.play("shoot_right")
		
		shoot_timer -= delta
		if shoot_timer <= 0:
			_shoot()
			shoot_timer = shoot_cooldown
	elif player_in_range:
		velocity.x = speed
		anim.play("run_right")
	else:
		velocity.x = 0
		anim.play("run_right")
		anim.stop() # Freeze animation to emulate Idle
		
	move_and_slide()

func _shoot():
	if not bullet_scene: return
	var bullet = bullet_scene.instantiate()
	var pos = global_position + Vector2(40, -10)
	bullet.setup(pos, Vector2.RIGHT, 400.0, 3.0, Color.YELLOW, true) # true -> is_player_bullet
	get_tree().current_scene.add_child(bullet)
	if sfx_shoot:
		sfx_shoot.play()

func take_damage(amount: float):
	if is_dead: return
	current_health -= amount
	if health_bar:
		health_bar.value = current_health
		
	# Flash red
	anim.modulate = Color.RED
	var tw = create_tween()
	tw.tween_property(anim, "modulate", Color.WHITE, 0.2)
	
	if current_health <= 0:
		die()

func die():
	is_dead = true
	velocity = Vector2.ZERO
	anim.play("destroy_right")
	collision_layer = 0
	collision_mask = 1
	tank_destroyed.emit()
	
	if sfx_shoot:
		sfx_shoot.pitch_scale = 0.5
		sfx_shoot.play()
