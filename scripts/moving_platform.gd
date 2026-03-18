extends AnimatableBody2D

## Moving Platform - Chiếc thuyền/mảng gỗ di chuyển qua lại
## Player đứng trên sẽ được mang theo tự động (AnimatableBody2D behavior)

@export var point_a: Vector2 = Vector2.ZERO
@export var point_b: Vector2 = Vector2(300, 0)
@export var move_speed: float = 80.0

var _progress: float = 0.0   # 0.0 = point_a, 1.0 = point_b
var _direction: float = 1.0  # 1 = toward B, -1 = toward A
var _total_distance: float = 1.0
var _wave_timer: float = 0.0

func _ready():
	# Tạo CollisionShape2D cho bề mặt mảng gỗ
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(120, 16)
	col.shape = shape
	col.position = Vector2(0, 0)
	add_child(col)
	
	# Layer giống mặt đất (layer 3 = ground), để Player (mask layer 2,3) đứng được
	collision_layer = 6   # Layer 2 + 3
	collision_mask = 0    # Không cần detect gì
	
	global_position = point_a
	_total_distance = point_a.distance_to(point_b)
	if _total_distance < 1.0:
		_total_distance = 1.0
	
	z_index = 3

func _physics_process(delta):
	# Di chuyển ping-pong giữa A và B
	var step = (move_speed * delta) / _total_distance
	_progress += step * _direction
	
	if _progress >= 1.0:
		_progress = 1.0
		_direction = -1.0
	elif _progress <= 0.0:
		_progress = 0.0
		_direction = 1.0
	
	global_position = point_a.lerp(point_b, _progress)
	
	# Animation timer cho sóng nước
	_wave_timer += delta
	queue_redraw()

func _draw():
	# ── Mảng gỗ (Wooden Raft) ──
	var w = 120.0
	var h = 16.0
	
	# Bóng đổ dưới nước
	draw_rect(Rect2(-w * 0.5 + 3, 4, w, 8), Color(0.05, 0.15, 0.2, 0.3))
	
	# Thân mảng gỗ chính
	draw_rect(Rect2(-w * 0.5, -h * 0.5, w, h), Color(0.45, 0.28, 0.12))
	
	# Các thanh gỗ ngang (planks)
	for i in range(6):
		var px = -w * 0.5 + float(i) * 20.0 + 2
		draw_rect(Rect2(px, -h * 0.5, 18, h), Color(0.50, 0.32, 0.14))
		# Vân gỗ
		draw_line(
			Vector2(px + 3, -h * 0.5 + 3),
			Vector2(px + 3, h * 0.5 - 3),
			Color(0.38, 0.22, 0.10), 1.0
		)
		draw_line(
			Vector2(px + 9, -h * 0.5 + 5),
			Vector2(px + 9, h * 0.5 - 2),
			Color(0.38, 0.22, 0.10), 1.0
		)
	
	# Thanh ngang buộc (cross beams)
	draw_rect(Rect2(-w * 0.5 + 2, -3, w - 4, 3), Color(0.35, 0.20, 0.08))
	draw_rect(Rect2(-w * 0.5 + 2, 4, w - 4, 3), Color(0.35, 0.20, 0.08))
	
	# Dây thừng ở 2 đầu
	draw_circle(Vector2(-w * 0.5 + 5, 0), 3, Color(0.6, 0.5, 0.3))
	draw_circle(Vector2(w * 0.5 - 5, 0), 3, Color(0.6, 0.5, 0.3))
	
	# Sóng nước nhỏ 2 bên mảng gỗ
	var wave_offset = sin(_wave_timer * 3.0) * 2.0
	draw_line(
		Vector2(-w * 0.5 - 8, 6 + wave_offset),
		Vector2(-w * 0.5, 4 + wave_offset),
		Color(0.4, 0.7, 0.8, 0.5), 1.5
	)
	draw_line(
		Vector2(w * 0.5, 4 - wave_offset),
		Vector2(w * 0.5 + 8, 6 - wave_offset),
		Color(0.4, 0.7, 0.8, 0.5), 1.5
	)
