extends Area2D
class_name PowerUp

## Power-up item

enum PowerType { WEAPON_UP, HEALTH, SHIELD, SPEED, INFINITE_AMMO }

@export var power_type: PowerType = PowerType.WEAPON_UP
var bob_timer: float = 0.0
var origin_y: float = 0.0

var colors = {
	PowerType.WEAPON_UP: Color(1, 0.3, 0.1),
	PowerType.HEALTH: Color(0.1, 1, 0.3),
	PowerType.SHIELD: Color(0.3, 0.5, 1),
	PowerType.SPEED: Color(1, 1, 0.2),
	PowerType.INFINITE_AMMO: Color(1, 0.1, 1),
}

var labels = {
	PowerType.WEAPON_UP: "W",
	PowerType.HEALTH: "+",
	PowerType.SHIELD: "S",
	PowerType.SPEED: ">>",
	PowerType.INFINITE_AMMO: "∞",
}

func _ready():
	origin_y = position.y
	set_deferred("collision_layer", 16)
	set_deferred("collision_mask", 1)
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 12
	col.shape = shape
	add_child(col)
	body_entered.connect(_on_body_entered)

func _process(delta):
	bob_timer += delta * 3
	position.y = origin_y + sin(bob_timer) * 5
	queue_redraw()

func _draw():
	var col = colors.get(power_type, Color.WHITE)
	# Box
	draw_rect(Rect2(-10, -10, 20, 20), Color(0.15, 0.15, 0.15))
	draw_rect(Rect2(-9, -9, 18, 18), col * 0.7)
	draw_rect(Rect2(-8, -8, 16, 16), col)
	# Label
	draw_string(ThemeDB.fallback_font, Vector2(-6, 5), labels.get(power_type, "?"), HORIZONTAL_ALIGNMENT_CENTER, 16, 12, Color.WHITE)
	# Glow
	draw_circle(Vector2.ZERO, 14, Color(col, 0.2))

func _on_body_entered(body):
	if body.is_in_group("player"):
		match power_type:
			PowerType.WEAPON_UP:
				if body.has_method("refill_current_magazine"):
					body.refill_current_magazine()
				else:
					GameManager.upgrade_weapon()
			PowerType.HEALTH:
				if body.has_method("heal"):
					body.heal(3)
			PowerType.SHIELD:
				if body.has_method("activate_shield"):
					body.activate_shield(5.0)
			PowerType.SPEED:
				if body.has_method("activate_speed_boost"):
					body.activate_speed_boost(5.0)
			PowerType.INFINITE_AMMO:
				if body.has_method("activate_infinite_ammo"):
					body.activate_infinite_ammo(5.0)
		queue_free()
