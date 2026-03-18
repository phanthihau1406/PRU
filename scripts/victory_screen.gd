extends Control

## Victory Screen
## Trình chiếu kết quả của Chiến dịch Hồ Chí Minh

@onready var score_label = $VBoxContainer/ScoreLabel
@onready var title_label = $VBoxContainer/TitleLabel
@onready var subtitle_label = $VBoxContainer/SubTitleLabel

var firework_timer: float = 0.0
var fireworks = []

func _ready():
	score_label.text = "TỔNG ĐIỂM: " + str(GameManager.score)

func _process(delta):
	firework_timer -= delta
	if firework_timer <= 0:
		_spawn_firework()
		firework_timer = randf_range(0.2, 0.8)
	
	for i in range(fireworks.size() - 1, -1, -1):
		var fw = fireworks[i]
		fw.age += delta
		if fw.age > fw.max_age:
			fireworks.remove_at(i)
		else:
			for p in fw.particles:
				p.pos += p.vel * delta
				p.vel.y += 50 * delta
				
	queue_redraw()

func _spawn_firework():
	var pos = Vector2(randf_range(100, 1180), randf_range(50, 400))
	var col = Color(randf(), randf(), randf(), 1.0)
	if col.v < 0.5: col.v = 1.0
	
	var fw = {
		"pos": pos,
		"color": col,
		"age": 0.0,
		"max_age": randf_range(1.0, 2.5),
		"particles": []
	}
	
	var num_particles = randi_range(30, 60)
	for i in range(num_particles):
		var angle = randf() * TAU
		var speed = randf_range(100, 300)
		fw.particles.append({
			"pos": pos,
			"vel": Vector2(cos(angle), sin(angle)) * speed
		})
		
	fireworks.append(fw)

func _draw():
	# Nền đỏ sao vàng
	draw_rect(Rect2(0, 0, 1280, 720), Color(0.8, 0.15, 0.15))
	
	# Sao vàng khổng lồ ở giữa mờ mờ
	draw_star(Vector2(640, 360), 300, Color(1, 0.9, 0.1, 0.2))
	
	# Vẽ pháo hoa
	for fw in fireworks:
		var alpha = 1.0 - (fw.age / fw.max_age)
		for p in fw.particles:
			draw_circle(p.pos, 3, Color(fw.color, alpha))

func draw_star(center: Vector2, radius: float, color: Color):
	var points = PackedVector2Array()
	for i in range(10):
		var r = radius if i % 2 == 0 else radius * 0.4
		var a = deg_to_rad(i * 36 - 90)
		points.append(center + Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(points, color)

func _on_btn_menu_pressed():
	GameManager.go_to_menu()

func _exit_tree():
	pass
