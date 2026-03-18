extends Area2D

## Health Pickup - dropped by enemies on death
## Heals player for 2 HP on contact

var lifetime: float = 10.0
var bob_timer: float = 0.0
var origin_y: float = 0.0

func _ready():
	origin_y = global_position.y
	collision_layer = 16
	collision_mask = 1
	body_entered.connect(_on_body_entered)

func _process(delta):
	bob_timer += delta * 3.0
	global_position.y = origin_y + sin(bob_timer) * 4.0
	
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
	
	queue_redraw()

func _draw():
	# Green cross icon
	var c = Color(0.2, 0.9, 0.3)
	draw_rect(Rect2(-3, -8, 6, 16), c)
	draw_rect(Rect2(-8, -3, 16, 6), c)
	# White highlight
	draw_rect(Rect2(-2, -6, 4, 12), Color(0.5, 1.0, 0.6))
	draw_rect(Rect2(-6, -2, 12, 4), Color(0.5, 1.0, 0.6))
	# Glow
	draw_circle(Vector2.ZERO, 12, Color(0.2, 0.9, 0.3, 0.15))

func _on_body_entered(body):
	if body.is_in_group("player") and body.has_method("heal"):
		body.heal(2)
		queue_free()
