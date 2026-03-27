extends Area2D

var speed: float = 200.0
var damage: int = 2
var is_exploded: bool = false
var has_damaged_player: bool = false
@export var bottom_explode_y: float = 700.0

@onready var sprite = $AnimatedSprite2D
@onready var sfx_no = $SfxNo

func _ready():
	monitoring = true
	body_entered.connect(_on_body_entered)
	if sprite:
		sprite.stop()
		sprite.frame = 0

func _process(delta):
	if is_exploded:
		return
	position.y += speed * delta

	# Level 1 request: only explode when the bomb reaches ground/bottom area.
	if global_position.y >= bottom_explode_y:
		_explode()
		return
	
	if position.y > 2000.0:
		queue_free()

func _on_body_entered(body):
	if is_exploded:
		return
		
	if body.is_in_group("player") and not has_damaged_player:
		has_damaged_player = true
		if body.has_method("take_damage"):
			body.take_damage(damage)

	# Do not explode on collision in mid-air; keep falling to bottom_explode_y.

func _explode():
	is_exploded = true
	# Dừng rơi để phát animation nổ tại chỗ
	speed = 0.0
	
	if sprite:
		sprite.play("shoot")
	
	if sfx_no:
		sfx_no.play()
	
	_shake_camera()
	
	# Chờ đến khi animation nổ chạy xong
	if sprite:
		await sprite.animation_finished
	elif sfx_no:
		await sfx_no.finished
	else:
		await get_tree().create_timer(1.0).timeout
		
	queue_free()

func _shake_camera():
	var cam = get_viewport().get_camera_2d()
	if not cam:
		return
	var tw = create_tween()
	var shake_amount = 12.0
	for i in range(8):
		tw.tween_property(cam, "offset", Vector2(randf_range(-shake_amount, shake_amount), randf_range(-shake_amount, shake_amount)), 0.05)
		shake_amount *= 0.8
	tw.tween_property(cam, "offset", Vector2.ZERO, 0.05)

func _draw():
	if is_exploded and sfx_no.playing:
		# Draw a simple explosion flash
		draw_circle(Vector2.ZERO, randf_range(20.0, 40.0), Color(1, 0.5, 0.1, 0.7))
		draw_circle(Vector2.ZERO, randf_range(10.0, 20.0), Color(1, 0.9, 0.2, 0.9))
