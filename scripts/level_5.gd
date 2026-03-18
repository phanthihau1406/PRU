extends "res://scripts/base_level.gd"

## Level 5: Tổng tiến công (final assault)
## Đường phố Sài Gòn, địch phòng thủ mạnh, boss cuối ở cổng Dinh.

var final_boss_scene = preload("res://scenes/objects/boss_final.tscn")
var tank_scene = preload("res://scenes/objects/tank_vehicle.tscn")
var prop_scene = preload("res://scenes/objects/destructible_prop.tscn")
var powerup_scene = preload("res://scenes/objects/powerup.tscn")

const LEVEL_W: float = 4000.0
const GROUND_Y: float = 650.0

func setup_level():
	level_name = "MÀN 5: TỔNG TIẾN CÔNG"

	for px in [350, 650, 950, 1250, 1550, 1850, 2150, 2450, 2750, 3050]:
		_spawn_soldier(Vector2(float(px), GROUND_Y - 14.0))

	for px in [1100, 2000, 2900]:
		_spawn_tank(Vector2(float(px), GROUND_Y - 10.0))

	for px in [800, 1700, 2600, 3200]:
		_spawn_prop(Vector2(float(px), GROUND_Y - 10.0), DestructibleProp.PropType.SANDBAG)
	for px in [1400, 2400, 3400]:
		_spawn_prop(Vector2(float(px), GROUND_Y - 10.0), DestructibleProp.PropType.BARREL)

	_spawn_powerup(Vector2(1800, GROUND_Y - 30.0), PowerUp.PowerType.INFINITE_AMMO)
	_spawn_powerup(Vector2(3000, GROUND_Y - 30.0), PowerUp.PowerType.HEALTH)

	# Boss cuối
	var boss = final_boss_scene.instantiate()
	boss.global_position = Vector2(3600, GROUND_Y - 20)
	boss.boss_defeated.connect(_on_boss_defeated)
	add_child(boss)

func _ready():
	super._ready()
	_setup_level_bgm("res://assets/audio/game_background_music1.mp3", -10.0)
	queue_redraw()

func _spawn_soldier(pos: Vector2):
	var enemy_scene = load("res://scenes/objects/enemy_soldier.tscn")
	var enemy = enemy_scene.instantiate()
	enemy.global_position = pos
	add_child(enemy)

func _spawn_tank(pos: Vector2):
	var tank = tank_scene.instantiate()
	tank.global_position = pos
	add_child(tank)

func _spawn_prop(pos: Vector2, ptype: int):
	var p = prop_scene.instantiate()
	p.prop_type = ptype
	p.global_position = pos
	add_child(p)

func _spawn_powerup(pos: Vector2, ptype: int):
	var p = powerup_scene.instantiate()
	p.power_type = ptype
	p.global_position = pos
	add_child(p)

func _on_boss_defeated():
	hud.show_message("DINH ĐỘC LẬP ĐÃ THUỘC VỀ TA", 2.5)
	await get_tree().create_timer(2.5).timeout
	complete_level()

func _draw():
	_draw_sky()
	_draw_city_layers()
	_draw_road()
	_draw_flags()

func _draw_sky():
	draw_rect(Rect2(-1000, -1000, 6000, 2000), Color(0.45, 0.72, 0.95))
	draw_rect(Rect2(-1000, -200, 6000, 400), Color(0.70, 0.85, 1.0, 0.7))
	draw_circle(Vector2(900, 140), 60, Color(1.0, 0.95, 0.7, 0.7))

func _draw_city_layers():
	for i in range(10):
		var x = -200 + i * 420
		var h = 220 + float((i * 37) % 120)
		draw_rect(Rect2(x, 640 - h, 240, h), Color(0.32, 0.36, 0.40, 0.7))
		for w in range(3):
			for r in range(4):
				if (i + w + r) % 2 == 0:
					draw_rect(Rect2(x + 20 + w * 60, 640 - h + 30 + r * 40, 18, 24), Color(0.95, 0.95, 0.75, 0.35))

func _draw_road():
	draw_rect(Rect2(-1000, GROUND_Y, 6000, 720), Color(0.18, 0.18, 0.20))
	draw_rect(Rect2(-1000, GROUND_Y - 8, 6000, 8), Color(0.26, 0.24, 0.22))
	for i in range(-4, 30):
		draw_rect(Rect2(i * 140, 690, 70, 6), Color(0.95, 0.95, 0.95, 0.6))

func _draw_flags():
	for i in range(6):
		var x = 400 + i * 600
		_draw_flag(Vector2(float(x), GROUND_Y))

func _draw_flag(pos: Vector2):
	draw_line(pos, pos + Vector2(0, -180), Color(0.8, 0.8, 0.8), 4)
	var time = Time.get_ticks_msec() / 250.0
	var pts = PackedVector2Array([
		pos + Vector2(0, -180),
		pos + Vector2(110 + sin(time) * 6, -180 + cos(time) * 4),
		pos + Vector2(110 + sin(time - 1) * 6, -130 + cos(time - 1) * 4),
		pos + Vector2(0, -130),
	])
	draw_colored_polygon(pts, Color(0.9, 0.1, 0.1))
	var center = pos + Vector2(45, -155)
	var star_points = PackedVector2Array()
	var radius = 16
	for i in range(10):
		var r = radius if i % 2 == 0 else radius * 0.4
		var a = deg_to_rad(i * 36 - 90)
		star_points.append(center + Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(star_points, Color(1, 1, 0))
