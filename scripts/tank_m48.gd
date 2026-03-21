extends CharacterBody2D

signal tank_destroyed

@export var max_health: float = 30.0
var current_health: float
var is_dead: bool = false
var shoot_timer: float = 0.0
var shoot_cooldown: float = 2.5
var shoot_range: float = 400.0

var bullet_scene = preload("res://scenes/objects/bullet.tscn")
var sfx_shoot: AudioStreamPlayer2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $ProgressBar

func _ready():
	current_health = max_health
	if get_node_or_null("ProgressBar"):
		health_bar.max_value = max_health
		health_bar.value = current_health
	
	add_to_group("enemies")
	add_to_group("m48_tank")
	collision_layer = 2 # Enemies
	collision_mask = 1 | 16 | 4 # Terrain, Allies, Player
	
	# Add Shooting Sound
	sfx_shoot = AudioStreamPlayer2D.new()
	sfx_shoot.stream = load("res://assets/audio/tiengNo.mp3")
	sfx_shoot.volume_db = -5.0
	sfx_shoot.pitch_scale = 1.2
	add_child(sfx_shoot)

func _physics_process(delta):
	if is_dead: return
	
	if not is_on_floor():
		velocity.y += 900.0 * delta
		
	# Find targets (player or allied tank)
	var targets = get_tree().get_nodes_in_group("player") + get_tree().get_nodes_in_group("allies")
	var closest_target = null
	var closest_dist = shoot_range
	
	for t in targets:
		if "is_dead" in t and t.is_dead: continue
		var dist = global_position.distance_to(t.global_position)
		# M-48 usually faces left, so it targets things on its left
		if dist < closest_dist and t.global_position.x < global_position.x:
			closest_dist = dist
			closest_target = t
			
	if closest_target:
		anim.play("shoot_left")
		velocity.x = 0
		shoot_timer -= delta
		if shoot_timer <= 0:
			_shoot()
			shoot_timer = shoot_cooldown
	else:
		anim.play("run_left")
		velocity.x = 0 # stays stationary if no target
		
	move_and_slide()

func _shoot():
	if not bullet_scene: return
	var bullet = bullet_scene.instantiate()
	var pos = global_position + Vector2(-40, -10)
	bullet.setup(pos, Vector2.LEFT, 450.0, 2.0, Color.ORANGE_RED, false) # false -> enemy bullet
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
	anim.play("destroy_left")
	collision_layer = 0
	collision_mask = 1
	tank_destroyed.emit()
	
	if sfx_shoot:
		sfx_shoot.pitch_scale = 0.5
		sfx_shoot.play()
