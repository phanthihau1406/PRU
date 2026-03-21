extends Area2D

## Bullet - used by player and enemies

var direction: Vector2 = Vector2.RIGHT
var speed: float = 600.0
var damage: float = 1.0
var bullet_color: Color = Color.YELLOW
var is_player_bullet: bool = true
var lifetime: float = 3.0

func setup(pos: Vector2, dir: Vector2, spd: float, dmg: float, col: Color, from_player: bool):
	global_position = pos
	direction = dir.normalized()
	speed = spd
	damage = dmg
	bullet_color = col
	is_player_bullet = from_player
	rotation = direction.angle()

func _ready():
	var col_shape = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 4
	col_shape.shape = shape
	add_child(col_shape)
	
	if is_player_bullet:
		collision_layer = 4  # Layer 3
		collision_mask = 2   # Layer 2 (enemies)
	else:
		collision_layer = 8   # Layer 4
		collision_mask = 17   # Layer 1 (player) and Layer 5 (allies)
	
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(delta):
	position += direction * speed * delta
	if not is_player_bullet:
		_check_enemy_bullet_hit_player()
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
	queue_redraw()

func _draw():
	# Draw bullet based on weapon type
	var size = 3.0 if is_player_bullet else 2.5
	draw_circle(Vector2.ZERO, size, bullet_color)
	# Trail
	draw_line(Vector2.ZERO, -direction * 8, Color(bullet_color, 0.5), 2.0)

func _on_body_entered(body):
	if is_player_bullet and body.is_in_group("enemies"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
	elif not is_player_bullet and (body.is_in_group("player") or body.is_in_group("allies")):
		if body.has_method("take_damage"):
			body.take_damage(max(1, int(ceil(damage))))
		queue_free()

func _on_area_entered(area):
	if is_player_bullet and area.is_in_group("enemies"):
		if area.has_method("take_damage"):
			area.take_damage(damage)
		queue_free()

func _check_enemy_bullet_hit_player():
	for b in get_overlapping_bodies():
		if b and (b.is_in_group("player") or b.is_in_group("allies")) and b.has_method("take_damage"):
			b.take_damage(max(1, int(ceil(damage))))
			queue_free()
			return

	# Fallback for high-speed bullets that may tunnel across one frame.
	var players = get_tree().get_nodes_in_group("player")
	for p in players:
		if not is_instance_valid(p):
			continue
		if global_position.distance_to(p.global_position) <= 30.0:
			if p.has_method("take_damage"):
				p.take_damage(max(1, int(ceil(damage))))
			queue_free()
			return

	var allies = get_tree().get_nodes_in_group("allies")
	for a in allies:
		if not is_instance_valid(a):
			continue
		if global_position.distance_to(a.global_position) <= 30.0:
			if a.has_method("take_damage"):
				a.take_damage(max(1, int(ceil(damage))))
			queue_free()
			return
