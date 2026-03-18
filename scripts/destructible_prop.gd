extends Area2D
class_name DestructibleProp

## Destructible prop (barrel, sandbag, cannon, jeep)

signal prop_destroyed

enum PropType { BARREL, SANDBAG, CANNON, JEEP }

@export var prop_type: PropType = PropType.BARREL
@export var max_health: float = 3.0

var health: float = 3.0
var flash_timer: float = 0.0

func _ready():
	add_to_group("enemies")
	collision_layer = 2
	collision_mask = 1
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(28, 20)
	col.shape = shape
	add_child(col)

func _process(delta):
	if flash_timer > 0.0:
		flash_timer -= delta
	queue_redraw()

func take_damage(amount: float):
	health -= amount
	flash_timer = 0.12
	if health <= 0.0:
		prop_destroyed.emit()
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.25)
		tween.tween_callback(queue_free)

func _draw():
	var col = Color(0.5, 0.35, 0.22) if flash_timer <= 0.0 else Color.WHITE
	match prop_type:
		PropType.BARREL:
			draw_rect(Rect2(-10, -12, 20, 24), Color(0.35, 0.18, 0.08))
			draw_rect(Rect2(-10, -12, 20, 4), Color(0.25, 0.12, 0.06))
			draw_rect(Rect2(-10, 8, 20, 4), Color(0.25, 0.12, 0.06))
		PropType.SANDBAG:
			draw_rect(Rect2(-14, -6, 28, 12), Color(0.32, 0.26, 0.18))
			draw_rect(Rect2(-12, -12, 24, 8), Color(0.36, 0.30, 0.22))
		PropType.CANNON:
			draw_rect(Rect2(-12, -6, 24, 12), col)
			draw_rect(Rect2(10, -3, 24, 6), Color(0.15, 0.15, 0.15))
			draw_circle(Vector2(-10, 10), 5, Color(0.12, 0.12, 0.12))
			draw_circle(Vector2(10, 10), 5, Color(0.12, 0.12, 0.12))
		PropType.JEEP:
			draw_rect(Rect2(-18, -10, 36, 14), col)
			draw_rect(Rect2(-10, -18, 20, 10), Color(0.18, 0.18, 0.20))
			draw_circle(Vector2(-12, 8), 5, Color(0.1, 0.1, 0.1))
			draw_circle(Vector2(12, 8), 5, Color(0.1, 0.1, 0.1))
