extends "res://scripts/base_level.gd"

## Level 2: Vượt Sông Tiến Quân (River Crossing)
## Bối cảnh: Bình minh. Cầu bị phá hủy. Player phải nhảy lên mảng gỗ
## vượt sông, tránh bắn tỉa từ trụ cầu, và đánh chiếm bờ bên kia.

var moving_platform_scene = preload("res://scenes/objects/moving_platform.tscn")
var sniper_enemy_scene = preload("res://scenes/objects/sniper_enemy.tscn")

const LEVEL_W: float = 6000.0
const GROUND_Y: float = 650.0

# Bờ trái: 0 → 1500, Sông: 1500 → 4000, Bờ phải: 4000 → 6000
const LEFT_BANK_END: float = 1500.0
const RIGHT_BANK_START: float = 4000.0
const RIVER_Y: float = 720.0  # Mặt nước

# Trụ cầu gãy (x positions, top y)
const BRIDGE_PILLARS = [
	[1700.0, 480.0],
	[2400.0, 500.0],
	[3100.0, 460.0],
	[3700.0, 490.0],
]

var targets_remaining: int = 0
var _wave_time: float = 0.0

func setup_level():
	level_name = "MÀN 2: VƯỢT SÔNG TIẾN QUÂN"
	
	# ── Lính tuần tra bờ trái ──
	for px in [400, 800, 1200]:
		_spawn_soldier(Vector2(float(px), GROUND_Y - 14.0))
	
	# ── Lính tuần tra bờ phải ──
	for px in [4200, 4600, 5000, 5400]:
		_spawn_soldier(Vector2(float(px), GROUND_Y - 14.0))
	
	# ── Sniper trên trụ cầu ──
	for pillar in BRIDGE_PILLARS:
		var sniper = sniper_enemy_scene.instantiate()
		sniper.global_position = Vector2(pillar[0], pillar[1] - 18)
		add_child(sniper)
		targets_remaining += 1
		sniper.enemy_died.connect(func(_x): _on_target_down())
	
	# ── Mảng gỗ di chuyển (3 chiếc nối tiếp vượt sông) ──
	_spawn_platform(
		Vector2(1400, GROUND_Y + 5),   # Bến bờ trái
		Vector2(2200, GROUND_Y + 5)    # Giữa sông 1
	)
	_spawn_platform(
		Vector2(2100, GROUND_Y - 10),  # Giữa sông 1
		Vector2(3000, GROUND_Y + 5)    # Giữa sông 2
	)
	_spawn_platform(
		Vector2(2900, GROUND_Y + 5),   # Giữa sông 2
		Vector2(4100, GROUND_Y + 5)    # Bến bờ phải
	)
	
	# ── Vùng nước tử thần (Water Death Zone) ──
	_create_water_death_zone()

func _spawn_soldier(pos: Vector2):
	var enemy_scene = load("res://scenes/objects/enemy_soldier.tscn")
	var enemy = enemy_scene.instantiate()
	enemy.global_position = pos
	enemy.health = 4
	add_child(enemy)
	targets_remaining += 1
	enemy.enemy_died.connect(func(_x): _on_target_down())

func _spawn_platform(a: Vector2, b: Vector2):
	var platform = moving_platform_scene.instantiate()
	platform.point_a = a
	platform.point_b = b
	add_child(platform)

func _create_water_death_zone():
	## Tạo Area2D bao phủ toàn bộ vùng sông
	## Khi Player rơi vào → trừ mạng + respawn
	var water_zone = Area2D.new()
	water_zone.name = "WaterDeathZone"
	water_zone.collision_layer = 0
	water_zone.collision_mask = 1  # Chỉ detect Player (layer 1)
	
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	# Vùng nước từ x=1400 đến x=4100, y=750 (dưới mặt sông)
	shape.size = Vector2(2700, 200)
	col.shape = shape
	col.position = Vector2(0, 0)
	water_zone.add_child(col)
	
	water_zone.global_position = Vector2(2750, 820)  # Trung tâm vùng sông
	add_child(water_zone)
	
	# Kết nối tín hiệu body_entered
	# Trong Inspector: Area2D → Signals → body_entered → connect
	# Trong code: connect trực tiếp như dưới đây
	water_zone.body_entered.connect(_on_water_entered)

func _on_water_entered(body: Node2D):
	## Xử lý khi body rơi vào nước
	## Chỉ xử lý Player, bỏ qua entity khác
	if not body.is_in_group("player"):
		return
	
	# Trừ 1 mạng
	GameManager.lives -= 1
	
	# Cập nhật UI
	if hud:
		hud.update_hud()
	
	if GameManager.lives <= 0:
		# Game Over
		if hud:
			hud.show_message("GAME OVER", 3.0)
		await get_tree().create_timer(3.0).timeout
		GameManager.go_to_menu()
	else:
		# Thông báo và respawn
		if hud:
			hud.show_message("RƠI XUỐNG SÔNG!\nCòn %d mạng" % GameManager.lives, 2.0)
		
		# Dịch chuyển Player về điểm bắt đầu
		var start_pos = Vector2(100, 600)
		var start_marker = get_node_or_null("PlayerStart")
		if start_marker:
			start_pos = start_marker.global_position
		
		body.global_position = start_pos
		body.velocity = Vector2.ZERO
		
		# Bất tử tạm thời sau khi respawn
		body.invincible = true
		body.invincible_timer = 3.0
		body.health = body.max_health
		body.health_changed.emit(body.health)

func _on_target_down():
	targets_remaining -= 1
	if targets_remaining <= 0:
		complete_level()

# ═══════════════════════════════════════════════════════════
#                        DRAWING
# ═══════════════════════════════════════════════════════════

func _ready():
	super._ready()
	_setup_level_bgm("res://assets/audio/game_background_music1.mp3", -10.0)
	queue_redraw()

func _process(delta):
	_wave_time += delta
	queue_redraw()

func _draw():
	_draw_dawn_sky()
	_draw_clouds()
	_draw_far_mountains()
	_draw_near_mountains()
	_draw_river()
	_draw_ground_banks()
	_draw_bridge_ruins()
	_draw_vegetation()
	_draw_details()

# ── Bầu trời bình minh ──
func _draw_dawn_sky():
	# Gradient từ tím đậm (trên) → cam hồng (giữa) → vàng (chân trời)
	draw_rect(Rect2(-100, -600, LEVEL_W + 200, 500), Color(0.12, 0.08, 0.25))  # Tím đậm
	draw_rect(Rect2(-100, -200, LEVEL_W + 200, 300), Color(0.25, 0.10, 0.30))  # Tím nhạt
	draw_rect(Rect2(-100, 50, LEVEL_W + 200, 200), Color(0.60, 0.25, 0.20))    # Cam đỏ
	draw_rect(Rect2(-100, 200, LEVEL_W + 200, 150), Color(0.85, 0.45, 0.20))   # Cam
	draw_rect(Rect2(-100, 320, LEVEL_W + 200, 120), Color(0.95, 0.65, 0.25))   # Vàng cam
	draw_rect(Rect2(-100, 420, LEVEL_W + 200, 100), Color(0.98, 0.80, 0.45))   # Vàng nhạt
	
	# Mặt trời mọc
	draw_circle(Vector2(4800, 380), 85, Color(1.0, 0.85, 0.4, 0.3))
	draw_circle(Vector2(4800, 380), 60, Color(1.0, 0.90, 0.5, 0.5))
	draw_circle(Vector2(4800, 380), 40, Color(1.0, 0.95, 0.7, 0.8))

func _draw_clouds():
	var cloud_positions = [
		Vector2(300, 80), Vector2(900, 120), Vector2(1600, 60),
		Vector2(2400, 140), Vector2(3200, 90), Vector2(4000, 110),
		Vector2(4600, 70), Vector2(5300, 130),
	]
	for pos in cloud_positions:
		_draw_cloud(pos)

func _draw_cloud(pos: Vector2):
	# Mây hồng bình minh
	draw_circle(pos, 30, Color(0.95, 0.70, 0.55, 0.4))
	draw_circle(pos + Vector2(25, 6), 22, Color(0.90, 0.65, 0.50, 0.35))
	draw_circle(pos + Vector2(-22, -3), 20, Color(0.88, 0.60, 0.48, 0.3))
	draw_circle(pos + Vector2(8, -12), 18, Color(0.92, 0.72, 0.58, 0.35))

# ── Núi xa ──
func _draw_far_mountains():
	var c = Color(0.18, 0.12, 0.22, 0.7)
	for i in range(15):
		var px = float(i) * 400.0 - 100.0
		var h = 380.0 + float((i * 37 + 11) % 80)
		_tri(Vector2(px, GROUND_Y + 50), Vector2(px + 200, h), Vector2(px + 400, GROUND_Y + 50), c)

func _draw_near_mountains():
	var c = Color(0.12, 0.18, 0.10)
	for i in range(13):
		var px = float(i) * 450.0 - 50.0
		var h = 420.0 + float((i * 29 + 7) % 60)
		_tri(Vector2(px, GROUND_Y + 20), Vector2(px + 225, h), Vector2(px + 450, GROUND_Y + 20), c)

# ── Sông ──
func _draw_river():
	# Nền nước sông (màu đậm)
	var river_rect = Rect2(LEFT_BANK_END - 50, GROUND_Y - 20, RIGHT_BANK_START - LEFT_BANK_END + 100, 350)
	draw_rect(river_rect, Color(0.05, 0.18, 0.30))
	
	# Lớp nước trên mặt (nhạt hơn)
	draw_rect(Rect2(LEFT_BANK_END - 50, GROUND_Y - 10, RIGHT_BANK_START - LEFT_BANK_END + 100, 30),
		Color(0.12, 0.35, 0.50, 0.7))
	
	# Phản chiếu ánh bình minh trên mặt nước
	for i in range(20):
		var rx = LEFT_BANK_END + float(i) * 130.0
		var ry = GROUND_Y + 10 + sin(_wave_time * 1.5 + float(i) * 0.8) * 4
		draw_rect(Rect2(rx, ry, 60, 3), Color(0.95, 0.65, 0.3, 0.15 + sin(_wave_time * 2.0 + float(i)) * 0.05))
	
	# Sóng lăn tăn
	for i in range(40):
		var wx = LEFT_BANK_END + float(i) * 65.0
		var wy = GROUND_Y + sin(_wave_time * 2.5 + float(i) * 1.2) * 3
		draw_line(
			Vector2(wx, wy),
			Vector2(wx + 25 + sin(_wave_time + float(i)) * 5, wy + 2),
			Color(0.4, 0.7, 0.8, 0.25), 1.5
		)

# ── Mặt đất 2 bờ ──
func _draw_ground_banks():
	# ── Bờ trái ──
	var left_bank = PackedVector2Array([
		Vector2(-100, GROUND_Y - 5),
		Vector2(300, GROUND_Y - 10),
		Vector2(700, GROUND_Y),
		Vector2(1100, GROUND_Y - 8),
		Vector2(LEFT_BANK_END, GROUND_Y + 10),
		Vector2(LEFT_BANK_END, 1000),
		Vector2(-100, 1000)
	])
	draw_colored_polygon(left_bank, Color(0.22, 0.14, 0.08))
	# Cỏ trên bờ
	draw_polyline(PackedVector2Array([
		Vector2(-100, GROUND_Y - 5),
		Vector2(300, GROUND_Y - 10),
		Vector2(700, GROUND_Y),
		Vector2(1100, GROUND_Y - 8),
		Vector2(LEFT_BANK_END, GROUND_Y + 10),
	]), Color(0.25, 0.55, 0.12), 8.0)
	
	# ── Bờ phải ──
	var right_bank = PackedVector2Array([
		Vector2(RIGHT_BANK_START, GROUND_Y + 10),
		Vector2(RIGHT_BANK_START + 400, GROUND_Y - 5),
		Vector2(RIGHT_BANK_START + 800, GROUND_Y),
		Vector2(RIGHT_BANK_START + 1200, GROUND_Y - 8),
		Vector2(LEVEL_W + 100, GROUND_Y + 5),
		Vector2(LEVEL_W + 100, 1000),
		Vector2(RIGHT_BANK_START, 1000)
	])
	draw_colored_polygon(right_bank, Color(0.22, 0.14, 0.08))
	draw_polyline(PackedVector2Array([
		Vector2(RIGHT_BANK_START, GROUND_Y + 10),
		Vector2(RIGHT_BANK_START + 400, GROUND_Y - 5),
		Vector2(RIGHT_BANK_START + 800, GROUND_Y),
		Vector2(RIGHT_BANK_START + 1200, GROUND_Y - 8),
		Vector2(LEVEL_W + 100, GROUND_Y + 5),
	]), Color(0.25, 0.55, 0.12), 8.0)
	
	# Lớp đất sẫm bên dưới
	draw_rect(Rect2(-100, GROUND_Y + 30, LEFT_BANK_END + 100, 300), Color(0.15, 0.09, 0.05))
	draw_rect(Rect2(RIGHT_BANK_START, GROUND_Y + 30, LEVEL_W - RIGHT_BANK_START + 100, 300), Color(0.15, 0.09, 0.05))

# ── Tàn tích cầu gãy ──
func _draw_bridge_ruins():
	for pillar_data in BRIDGE_PILLARS:
		var px = pillar_data[0]
		var top_y = pillar_data[1]
		_draw_pillar(px, top_y)
	
	# Thanh cầu gãy (nối giữa các trụ, vỡ ở giữa)
	# Mảnh cầu gãy bên trái
	var broken_pts_l = PackedVector2Array([
		Vector2(LEFT_BANK_END - 80, GROUND_Y - 30),
		Vector2(LEFT_BANK_END + 100, GROUND_Y - 20),
		Vector2(LEFT_BANK_END + 80, GROUND_Y - 15),
		Vector2(LEFT_BANK_END - 80, GROUND_Y - 22),
	])
	draw_colored_polygon(broken_pts_l, Color(0.35, 0.30, 0.25))
	
	# Mảnh cầu gãy bên phải
	var broken_pts_r = PackedVector2Array([
		Vector2(RIGHT_BANK_START - 80, GROUND_Y - 18),
		Vector2(RIGHT_BANK_START + 100, GROUND_Y - 28),
		Vector2(RIGHT_BANK_START + 100, GROUND_Y - 20),
		Vector2(RIGHT_BANK_START - 60, GROUND_Y - 12),
	])
	draw_colored_polygon(broken_pts_r, Color(0.35, 0.30, 0.25))
	
	# Thanh sắt lòi ra
	for i in range(5):
		var rx = LEFT_BANK_END + 70 + float(i) * 15
		var ry = GROUND_Y - 18 + float(i % 3) * 4
		draw_line(Vector2(rx, ry), Vector2(rx + 20, ry + 25), Color(0.5, 0.4, 0.3), 2.0)
	
	for i in range(4):
		var rx = RIGHT_BANK_START - 60 + float(i) * 12
		var ry = GROUND_Y - 14 + float(i % 3) * 3
		draw_line(Vector2(rx, ry), Vector2(rx - 15, ry + 20), Color(0.5, 0.4, 0.3), 2.0)

func _draw_pillar(x: float, top_y: float):
	var pillar_w = 40.0
	var bottom_y = GROUND_Y + 60
	
	# Bóng đổ trong nước
	draw_rect(Rect2(x - pillar_w * 0.5 + 3, GROUND_Y, pillar_w, 80), Color(0.03, 0.12, 0.20, 0.4))
	
	# Thân trụ chính (bê tông)
	draw_rect(Rect2(x - pillar_w * 0.5, top_y, pillar_w, bottom_y - top_y), Color(0.45, 0.42, 0.38))
	
	# Viền trụ
	draw_rect(Rect2(x - pillar_w * 0.5, top_y, pillar_w, 8), Color(0.50, 0.48, 0.42))
	
	# Vết nứt
	draw_line(Vector2(x - 5, top_y + 20), Vector2(x + 3, top_y + 60), Color(0.30, 0.28, 0.25), 1.5)
	draw_line(Vector2(x + 8, top_y + 30), Vector2(x + 2, top_y + 80), Color(0.30, 0.28, 0.25), 1.5)
	
	# Rêu mốc phía dưới (gần mặt nước)
	draw_rect(Rect2(x - pillar_w * 0.5, GROUND_Y - 15, pillar_w, 20), Color(0.15, 0.30, 0.12, 0.5))

# ── Cây cối ──
func _draw_vegetation():
	# Cây bờ trái
	for tx in [80, 250, 500, 750, 1000, 1300]:
		_draw_tree(Vector2(float(tx), GROUND_Y - 5), 0.8 + float(tx % 3) * 0.15)
	
	# Cây bờ phải
	for tx in [4200, 4500, 4800, 5100, 5400, 5700]:
		_draw_tree(Vector2(float(tx), GROUND_Y - 5), 0.7 + float(tx % 4) * 0.12)
	
	# Cỏ dại
	for i in range(30):
		var gx: float
		if i < 15:
			gx = float(i) * 100.0 + 30.0
		else:
			gx = RIGHT_BANK_START + float(i - 15) * 130.0 + 50.0
		if gx < LEFT_BANK_END or gx > RIGHT_BANK_START:
			_draw_grass(Vector2(gx, GROUND_Y - 8))

func _draw_tree(pos: Vector2, s: float):
	var th = 110.0 * s
	var tw = 14.0 * s
	# Thân cây
	draw_rect(Rect2(pos.x - tw * 0.5, pos.y - th, tw, th), Color(0.30, 0.18, 0.08))
	# Tán lá
	var cr = pos + Vector2(0, -th)
	draw_circle(cr + Vector2(0, 8 * s), 42 * s, Color(0.10, 0.28, 0.06))
	draw_circle(cr + Vector2(-15 * s, 16 * s), 34 * s, Color(0.10, 0.28, 0.06))
	draw_circle(cr + Vector2(16 * s, 14 * s), 32 * s, Color(0.10, 0.28, 0.06))
	draw_circle(cr + Vector2(-5 * s, -4 * s), 38 * s, Color(0.15, 0.38, 0.09))
	draw_circle(cr + Vector2(10 * s, -6 * s), 30 * s, Color(0.15, 0.38, 0.09))
	draw_circle(cr + Vector2(-10 * s, -12 * s), 26 * s, Color(0.20, 0.48, 0.12))

func _draw_grass(pos: Vector2):
	for i in range(5):
		var a = -PI * 0.82 + float(i) * PI * 0.16
		var c = Color(0.22, 0.50, 0.10) if i % 2 == 0 else Color(0.30, 0.65, 0.14)
		draw_line(pos, pos + Vector2(cos(a) * 12.0, sin(a) * 12.0), c, 2.0)

func _draw_details():
	# Bao cát bờ trái (chốt phòng thủ)
	for x in [350, 700, 1100]:
		_draw_sandbags(float(x), GROUND_Y - 2)
	
	# Bao cát bờ phải
	for x in [4300, 4700, 5200, 5600]:
		_draw_sandbags(float(x), GROUND_Y - 2)
	
	# Hố bom
	for x in [200, 600, 900, 4400, 5000, 5500]:
		_draw_crater(float(x))

func _draw_sandbags(x: float, y: float):
	var pts = PackedVector2Array([
		Vector2(x - 28, y + 6),
		Vector2(x - 18, y - 8),
		Vector2(x + 16, y - 10),
		Vector2(x + 30, y + 6),
	])
	draw_colored_polygon(pts, Color(0.42, 0.38, 0.28, 0.9))
	# Khe bắn
	draw_rect(Rect2(x - 8, y - 1, 16, 6), Color(0.08, 0.08, 0.08, 0.8))

func _draw_crater(cx: float):
	var gy = GROUND_Y
	var pts = PackedVector2Array()
	for i in range(12):
		var a = float(i) * PI * 2.0 / 12.0
		pts.append(Vector2(cx + cos(a) * 30.0, gy + 5.0 + sin(a) * 9.0))
	draw_colored_polygon(pts, Color(0.12, 0.07, 0.04))

func _tri(p1: Vector2, p2: Vector2, p3: Vector2, c: Color):
	draw_colored_polygon(PackedVector2Array([p1, p2, p3]), c)
