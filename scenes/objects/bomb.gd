extends Area2D

## Bomb - dropped from airplane, falls straight down with gravity

var velocity: Vector2 = Vector2.ZERO
var damage: float = 2.0
var gravity: float = 480.0
var lifetime: float = 6.0
var exploded: bool = false
var damaged_body_ids: Dictionary = {}
@export var terrain_collision_mask: int = 1

func _ready():
	var col_shape = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 7
	col_shape.shape = shape
	add_child(col_shape)
	
	# Layer 4 (enemy bullet), mask = player (1) + allies (5)
	collision_layer = 8
	collision_mask = 17
	monitoring = true
	monitorable = false
	
	velocity = Vector2(0, 80)  # initial downward push
	
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	var prev_pos = global_position
	velocity.y += gravity * delta
	global_position += velocity * delta
	# rotate bomb to face velocity direction
	rotation = velocity.angle()

	if _check_ground_hit(prev_pos, global_position):
		return
	
	# Failsafe cleanup if projectile somehow leaves playable area.
	if global_position.y > 4000.0:
		queue_free()
		return
	
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
		return
	
	# Check if hit enemies (player/allies)
	_check_hit()
	
	queue_redraw()

func _check_hit():
	for body in get_overlapping_bodies():
		if body and (body.is_in_group("player") or body.is_in_group("allies")):
			_damage_body_once(body)
			if body.is_in_group("player"):
				_explode()
				return

func _on_body_entered(body):
	if body.is_in_group("player") or body.is_in_group("allies"):
		_damage_body_once(body)
		if body.is_in_group("player"):
			_explode()

func _damage_body_once(body: Node):
	var id = body.get_instance_id()
	if damaged_body_ids.has(id):
		return
	damaged_body_ids[id] = true
	if body.has_method("take_damage"):
		body.take_damage(max(1, int(ceil(damage))))

func _check_ground_hit(from_pos: Vector2, to_pos: Vector2) -> bool:
	var scene = get_tree().current_scene
	if scene and scene.has_method("_ground_y"):
		var gy = scene._ground_y(to_pos.x)
		if to_pos.y >= gy:
			global_position = Vector2(to_pos.x, gy)
			_explode()
			return true

	var space_state = get_world_2d().direct_space_state
	if not space_state:
		return false

	var query = PhysicsRayQueryParameters2D.create(from_pos, to_pos + Vector2(0, 6.0), terrain_collision_mask)
	query.exclude = [get_rid()]
	var hit = space_state.intersect_ray(query)
	if hit:
		global_position = hit.position
		_explode()
		return true
	return false

func _explode():
	if exploded:
		return
	exploded = true
	queue_free()

func _draw():
	# Draw bomb body - hình elip màu xanh lá nhà binh
	draw_ellipse_arc_filled(Vector2.ZERO, Vector2(5, 9), 0.0, TAU, Color(0.15, 0.18, 0.12))
	# Fins
	var fin_color = Color(0.20, 0.22, 0.16)
	draw_line(Vector2(-4, 6), Vector2(-8, 12), fin_color, 2.0)
	draw_line(Vector2(4, 6), Vector2(8, 12), fin_color, 2.0)
	draw_line(Vector2(0, 6), Vector2(0, 14), fin_color, 2.0)
	# Nose
	draw_circle(Vector2(0, -10), 3.5, Color(0.40, 0.42, 0.35))

func draw_ellipse_arc_filled(center: Vector2, radius: Vector2, start_angle: float, end_angle: float, color: Color):
	var pts = PackedVector2Array()
	var steps = 16
	for i in range(steps + 1):
		var a = start_angle + (end_angle - start_angle) * float(i) / float(steps)
		pts.append(center + Vector2(cos(a) * radius.x, sin(a) * radius.y))
	draw_colored_polygon(pts, color)
