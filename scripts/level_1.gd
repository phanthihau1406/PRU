extends "res://scripts/base_level.gd"

## Level 1: Tieu diet tat ca ke dich de hoan thanh nhiem vu!

var helicopter_boss_scene = preload("res://scenes/objects/boss_helicopter.tscn")
var airplane_scene        = preload("res://scenes/objects/enemy_airplane.tscn")
var powerup_scene         = preload("res://scenes/objects/powerup.tscn")
var ally_scene            = preload("res://scenes/objects/ally_soldier.tscn")
var tank_scene            = preload("res://scenes/objects/tank_vehicle.tscn")
var prop_scene            = preload("res://scenes/objects/destructible_prop.tscn")

const LEVEL_W  : float = 10000.0
const GROUND_Y : float = 650.0

const PLATFORMS = [
	[950,  560, 160],
	[1600, 500, 260],
	[2350, 528, 160],
	[3100, 480, 260],
	[3900, 515, 160],
	[4700, 490, 260],
	[5500, 510, 160],
	[6300, 530, 260],
	[7100, 495, 160],
	[7850, 560, 260],
	[8450, 470, 160],
	[9050, 540, 260],
	[9650, 455, 160],
]

const TERRAIN_TOP = [
	Vector2(0, 650),
	Vector2(700, 630),
	Vector2(1400, 615),
	Vector2(2100, 680),
	Vector2(2800, 705),
	Vector2(3500, 645),
	Vector2(4200, 640),
	Vector2(4900, 705),
	Vector2(5600, 720),
	Vector2(6300, 660),
	Vector2(7000, 690),
	Vector2(7700, 705),
	Vector2(8400, 635),
	Vector2(9100, 655),
	Vector2(10000, 680),
]

var boss_spawned: bool = false
var preboss_spawned: bool = false
var mini_event_triggered: bool = false
var shake_timer: float = 0.0
var shake_strength: float = 0.0
var cam: Camera2D

func setup_level():
	level_name = "MÀN 1: HÀNH QUÂN QUA RỪNG"
	cam = get_node_or_null("Camera2D")

	# Tutorial 0-800
	_spawn_soldier(Vector2(260, GROUND_Y - 14.0))
	_spawn_soldier(Vector2(560, GROUND_Y - 14.0))
	_spawn_powerup(Vector2(1200, GROUND_Y - 30), PowerUp.PowerType.WEAPON_UP)

	# Combat 1: 800-2500
	for px in [820, 960, 1180, 1360, 1540, 1760, 2060, 2320]:
		_spawn_soldier(Vector2(float(px), GROUND_Y - 14.0))
	_spawn_soldier(Vector2(1600, 486.0))
	_spawn_prop(Vector2(1460, GROUND_Y - 10.0), DestructibleProp.PropType.SANDBAG)
	_spawn_prop(Vector2(1780, GROUND_Y - 10.0), DestructibleProp.PropType.SANDBAG)
	_spawn_prop(Vector2(1120, GROUND_Y - 10.0), DestructibleProp.PropType.BARREL)

	# Air attack: 2500-5000
	for px in [2580, 2940, 3320, 3720, 4460]:
		_spawn_soldier(Vector2(float(px), GROUND_Y - 14.0))
	_spawn_airplane(Vector2(2800, 170), 2500.0, 4200.0)
	_spawn_airplane(Vector2(4300, 160), 3200.0, 5000.0)
	_spawn_powerup(Vector2(2600, GROUND_Y - 30), PowerUp.PowerType.SPEED)
	_spawn_prop(Vector2(2920, GROUND_Y - 10.0), DestructibleProp.PropType.BARREL)

	# Mixed battle: 5000-8000
	for px in [5000, 5200, 5480, 5760, 6000, 6320, 6680, 7000, 7420]:
		_spawn_soldier(Vector2(float(px), GROUND_Y - 14.0))
	_spawn_airplane(Vector2(5600, 170), 5200.0, 6600.0)
	_spawn_airplane(Vector2(7200, 165), 6400.0, 8000.0)
	_spawn_tank(Vector2(6200, GROUND_Y - 10.0))
	_spawn_powerup(Vector2(5200, GROUND_Y - 30), PowerUp.PowerType.HEALTH)
	_spawn_powerup(Vector2(7600, GROUND_Y - 30), PowerUp.PowerType.SHIELD)
	_spawn_prop(Vector2(5400, GROUND_Y - 10.0), DestructibleProp.PropType.BARREL)
	_spawn_prop(Vector2(7080, GROUND_Y - 10.0), DestructibleProp.PropType.JEEP)

	# Pre-boss: 8000-9000
	for px in [8120, 8340, 8560, 8780, 8920]:
		_spawn_soldier(Vector2(float(px), GROUND_Y - 14.0))
	_spawn_airplane(Vector2(8600, 160), 8200.0, 9000.0)

	# Allies support
	for a in [Vector2(300, GROUND_Y - 8), Vector2(5400, GROUND_Y - 8), Vector2(8200, GROUND_Y - 8)]:
		var al = ally_scene.instantiate()
		al.global_position = a
		add_child(al)

	# Checkpoints
	_spawn_checkpoint(3000)
	_spawn_checkpoint(6000)
	_spawn_checkpoint(8500)

	# Power-up before boss
	_spawn_powerup(Vector2(9000, GROUND_Y - 30), PowerUp.PowerType.INFINITE_AMMO)

func _spawn_soldier(pos: Vector2):
	var e = load("res://scenes/objects/enemy_soldier.tscn").instantiate()
	e.global_position = pos
	add_child(e)

func _spawn_airplane(pos: Vector2, mn: float, mx: float):
	var ap = airplane_scene.instantiate()
	ap.global_position = pos
	ap.patrol_min_x    = mn
	ap.patrol_max_x    = mx
	ap.crashed.connect(_on_plane_crashed)
	add_child(ap)

func _spawn_tank(pos: Vector2):
	var t = tank_scene.instantiate()
	t.global_position = pos
	add_child(t)

func _spawn_powerup(pos: Vector2, ptype: int):
	var p = powerup_scene.instantiate()
	p.power_type = ptype
	p.global_position = pos
	add_child(p)

func _spawn_prop(pos: Vector2, ptype: int):
	var p = prop_scene.instantiate()
	p.prop_type = ptype
	p.global_position = pos
	add_child(p)

func _spawn_checkpoint(x: float):
	var area = Area2D.new()
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(60, 120)
	col.shape = shape
	area.add_child(col)
	area.position = Vector2(x, GROUND_Y - 60)
	area.body_entered.connect(func(body): _on_checkpoint_reached(body, x))
	add_child(area)

func _on_checkpoint_reached(body: Node, x: float):
	if not body.is_in_group("player"):
		return
	var marker = get_node_or_null("PlayerStart")
	if marker:
		marker.global_position = Vector2(x, GROUND_Y - 20)
		hud.show_message("CHECKPOINT", 1.2)

func _ready():
	super._ready()
	if get_node_or_null("BGM") == null:
		var bgm = AudioStreamPlayer.new()
		bgm.name = "BGM"
		bgm.stream = load("res://assets/audio/game_background_music1.mp3")
		bgm.volume_db = -10.0
		bgm.autoplay = true
		add_child(bgm)
	queue_redraw()

func _process(delta):
	if not player:
		return
	# Mini event at x=4200
	if not mini_event_triggered and player.global_position.x >= 4200:
		mini_event_triggered = true
		_start_camera_shake(0.7, 6.0)
		for px in [4200, 4380, 4560]:
			_spawn_soldier(Vector2(float(px), GROUND_Y - 14.0))
		_spawn_airplane(Vector2(4500, 160), 4100.0, 5200.0)
		_spawn_prop(Vector2(4280, GROUND_Y - 10.0), DestructibleProp.PropType.CANNON)

	# Pre-boss spawn
	if not preboss_spawned and player.global_position.x >= 8800:
		preboss_spawned = true
		_start_camera_shake(0.7, 6.0)
		for px in [8800, 9000, 9200, 9400]:
			_spawn_soldier(Vector2(float(px), GROUND_Y - 14.0))
		_spawn_airplane(Vector2(9000, 160), 8600.0, 9800.0)

	# Boss intro trigger
	if not boss_spawned and player.global_position.x >= 9000:
		boss_spawned = true
		_start_camera_shake(1.2, 8.0)
		_spawn_boss_intro()

	# Camera shake
	if shake_timer > 0.0:
		shake_timer -= delta
		if cam:
			cam.offset = Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength))
	else:
		if cam:
			cam.offset = Vector2.ZERO

func _start_camera_shake(duration: float, strength: float):
	shake_timer = duration
	shake_strength = strength

func _spawn_boss_intro():
	# Pre-boss message and helicopter fly-in
	hud.show_message("TRỰC THĂNG ĐỊCH XUẤT HIỆN!", 2.0)
	var bgm = get_node_or_null("BGM")
	if bgm and bgm is AudioStreamPlayer:
		bgm.volume_db = -6.0
	var boss = helicopter_boss_scene.instantiate()
	boss.global_position = Vector2(9900, 240)
	boss.boss_defeated.connect(_on_boss_defeated)
	add_child(boss)

func _on_plane_crashed(_pos: Vector2):
	_start_camera_shake(0.6, 7.0)

func _on_boss_defeated():
	hud.show_message("TIẾN VỀ SÀI GÒN", 2.5)
	await get_tree().create_timer(2.5).timeout
	complete_level()

func _draw():
	_draw_sky()
	_draw_sun_rays()
	_draw_atmosphere()
	_draw_horizon_haze()
	_draw_far_mountains()
	_draw_near_mountains()
	_draw_treeline_silhouette()
	_draw_ground()
	_draw_platforms()
	_draw_battlefield_props()
	_draw_battlefield_camps()
	_draw_bamboo_groups()
	_draw_trees()
	_draw_details()

func _draw_sky():
	draw_rect(Rect2(-100, -600, LEVEL_W + 200, 1400), Color(0.43, 0.64, 0.80))
	draw_rect(Rect2(-100, -600, LEVEL_W + 200,  500), Color(0.56, 0.78, 0.92))
	draw_circle(Vector2(1260, 120), 78, Color(1.0, 0.92, 0.66, 0.40))
	draw_circle(Vector2(1260, 120), 50, Color(1.0, 0.95, 0.78, 0.65))
	draw_rect(Rect2(-100,  530, LEVEL_W + 200,   50), Color(0.62, 0.78, 0.55, 0.5))
	draw_rect(Rect2(-100,  568, LEVEL_W + 200,   38), Color(0.50, 0.65, 0.35, 0.4))
	for i in range(22):
		var cx = float(i) * 380.0 + 80.0
		var cy = 78.0 + float((i * 31 + 11) % 60)
		_cloud(Vector2(cx, cy))
	# Birds
	for i in range(10):
		var bx = 200.0 + float(i) * 820.0
		var by = 140.0 + float((i * 19) % 80)
		_draw_bird(Vector2(bx, by))

func _draw_sun_rays():
	# Subtle radial rays from sun
	for i in range(6):
		var ang = deg_to_rad(-35 + i * 12)
		var a = Vector2(1260, 120)
		var b = a + Vector2(cos(ang), sin(ang)) * 380.0
		var c = a + Vector2(cos(ang + 0.09), sin(ang + 0.09)) * 380.0
		var pts = PackedVector2Array([a, b, c])
		draw_colored_polygon(pts, Color(1.0, 0.92, 0.66, 0.08))

func _draw_atmosphere():
	# Light fog bands to add depth and reduce flatness.
	draw_rect(Rect2(-100, 210, LEVEL_W + 200, 42), Color(0.78, 0.86, 0.82, 0.18))
	draw_rect(Rect2(-100, 290, LEVEL_W + 200, 36), Color(0.70, 0.82, 0.74, 0.15))
	# Narrow river strip for contrast.
	draw_rect(Rect2(-100, 622, LEVEL_W + 200, 14), Color(0.13, 0.38, 0.44, 0.55))
	draw_rect(Rect2(-100, 628, LEVEL_W + 200, 5), Color(0.42, 0.70, 0.74, 0.40))
	# River glints
	for i in range(0, 18):
		var x = float(i) * 520.0 - 60.0
		draw_rect(Rect2(x, 626, 140, 3), Color(0.60, 0.80, 0.85, 0.35))

func _draw_horizon_haze():
	# Warm haze near horizon
	draw_rect(Rect2(-100, 480, LEVEL_W + 200, 120), Color(0.80, 0.84, 0.72, 0.12))

func _cloud(pos: Vector2):
	draw_circle(pos,                     32, Color(1,1,1,0.55))
	draw_circle(pos + Vector2( 28,  8),  24, Color(1,1,1,0.50))
	draw_circle(pos + Vector2(-26, -4),  22, Color(1,1,1,0.48))
	draw_circle(pos + Vector2(  8,-14),  20, Color(1,1,1,0.45))

func _draw_far_mountains():
	var c  = Color(0.32, 0.49, 0.28, 0.65)
	var hs = [390,315,365,295,350,320,375,300,345,315,360,290,370]
	for i in range(23):
		var px = float(i) * 380.0 - 200.0
		_tri(Vector2(px, GROUND_Y+80), Vector2(px+190, float(hs[i % hs.size()])), Vector2(px+380, GROUND_Y+80), c)

func _draw_near_mountains():
	var c  = Color(0.16, 0.33, 0.13)
	var hs = [270,195,255,225,245,205,268,238,215,262,232]
	for i in range(21):
		var px = float(i) * 400.0 - 80.0
		_tri(Vector2(px, GROUND_Y+30), Vector2(px+200, float(hs[i % hs.size()])), Vector2(px+400, GROUND_Y+30), c)

func _draw_treeline_silhouette():
	var c = Color(0.10, 0.20, 0.07)
	for i in range(42):
		var px = float(i) * 200.0 - 50.0
		var ho = float((i * 37 + 13) % 40) - 20.0
		_tri(Vector2(px, GROUND_Y+10), Vector2(px+100, 555.0+ho), Vector2(px+200, GROUND_Y+10), c)

func _draw_ground():
	var poly = PackedVector2Array()
	for p in TERRAIN_TOP:
		poly.append(p)
	poly.append(Vector2(LEVEL_W, 900))
	poly.append(Vector2(0, 900))

	draw_colored_polygon(poly, Color(0.20, 0.12, 0.07))

	# Soil layers under the surface
	var soil = PackedVector2Array()
	for p in TERRAIN_TOP:
		soil.append(p + Vector2(0, 35))
	soil.append(Vector2(LEVEL_W, 900))
	soil.append(Vector2(0, 900))
	draw_colored_polygon(soil, Color(0.16, 0.09, 0.05))

	# Grass strip along the top
	draw_polyline(PackedVector2Array(TERRAIN_TOP), Color(0.27, 0.58, 0.13), 7.0)
	draw_polyline(PackedVector2Array(TERRAIN_TOP), Color(0.20, 0.46, 0.10), 12.0)

func _draw_battlefield_props():
	for x in [520, 2140, 3680, 5880, 7420, 9400]:
		_draw_bunker(float(x), _ground_y(float(x)) + 3.0)
	for x in [980, 2740, 4760, 6660, 8520]:
		_draw_flag(Vector2(float(x), _ground_y(float(x)) - 15.0))
	# Smoke plumes near bunkers
	for x in [520, 2140, 3680, 5880, 7420, 9400]:
		_draw_smoke(Vector2(float(x) + 30.0, _ground_y(float(x)) - 40.0))
	# Extra props
	_draw_destroyed_tank(Vector2(5600, _ground_y(5600) + 6))
	_draw_jeep(Vector2(7200, _ground_y(7200) + 6))
	_draw_aa_gun(Vector2(4600, _ground_y(4600) + 4))

func _draw_battlefield_camps():
	# Field tents and supplies
	for x in [1200, 3050, 5050, 7050, 8850]:
		_draw_tent(Vector2(float(x), _ground_y(float(x)) + 4.0))
	for x in [1680, 3480, 5480, 7480, 9280]:
		_draw_supply(Vector2(float(x), _ground_y(float(x)) + 8.0))

func _draw_bunker(x: float, y: float):
	var pts = PackedVector2Array([
		Vector2(x - 34, y + 8),
		Vector2(x - 22, y - 10),
		Vector2(x + 20, y - 12),
		Vector2(x + 35, y + 8)
	])
	draw_colored_polygon(pts, Color(0.36, 0.32, 0.25, 0.95))
	draw_rect(Rect2(x - 10, y - 2, 20, 8), Color(0.08, 0.08, 0.08, 0.85))

func _draw_flag(pos: Vector2):
	draw_line(pos, pos + Vector2(0, -32), Color(0.30, 0.22, 0.14), 2.0)
	var p = pos + Vector2(0, -32)
	var cloth = PackedVector2Array([
		p,
		p + Vector2(24, 4),
		p + Vector2(24, 15),
		p + Vector2(0, 12)
	])
	draw_colored_polygon(cloth, Color(0.72, 0.12, 0.10, 0.95))

func _draw_smoke(pos: Vector2):
	draw_circle(pos, 14, Color(0.45, 0.45, 0.45, 0.25))
	draw_circle(pos + Vector2(12, -8), 12, Color(0.45, 0.45, 0.45, 0.20))
	draw_circle(pos + Vector2(-10, -10), 10, Color(0.45, 0.45, 0.45, 0.18))

func _draw_tent(pos: Vector2):
	var pts = PackedVector2Array([
		Vector2(pos.x - 30, pos.y),
		Vector2(pos.x, pos.y - 30),
		Vector2(pos.x + 30, pos.y)
	])
	draw_colored_polygon(pts, Color(0.40, 0.48, 0.24))
	draw_rect(Rect2(pos.x - 28, pos.y, 56, 12), Color(0.30, 0.34, 0.18))

func _draw_supply(pos: Vector2):
	draw_rect(Rect2(pos.x - 16, pos.y - 12, 32, 12), Color(0.36, 0.28, 0.18))
	draw_rect(Rect2(pos.x + 10, pos.y - 18, 14, 18), Color(0.30, 0.22, 0.14))

func _draw_destroyed_tank(pos: Vector2):
	draw_rect(Rect2(pos.x - 32, pos.y - 12, 64, 16), Color(0.20, 0.22, 0.18))
	draw_rect(Rect2(pos.x - 14, pos.y - 26, 28, 14), Color(0.18, 0.20, 0.16))
	draw_line(Vector2(pos.x + 6, pos.y - 22), Vector2(pos.x + 34, pos.y - 28), Color(0.12, 0.12, 0.12), 4.0)
	draw_circle(Vector2(pos.x - 18, pos.y + 6), 6, Color(0.10, 0.10, 0.10))
	draw_circle(Vector2(pos.x + 18, pos.y + 6), 6, Color(0.10, 0.10, 0.10))

func _draw_jeep(pos: Vector2):
	draw_rect(Rect2(pos.x - 20, pos.y - 10, 40, 14), Color(0.25, 0.28, 0.22))
	draw_rect(Rect2(pos.x - 10, pos.y - 20, 20, 10), Color(0.18, 0.20, 0.18))
	draw_circle(Vector2(pos.x - 14, pos.y + 6), 5, Color(0.10, 0.10, 0.10))
	draw_circle(Vector2(pos.x + 14, pos.y + 6), 5, Color(0.10, 0.10, 0.10))

func _draw_aa_gun(pos: Vector2):
	draw_rect(Rect2(pos.x - 14, pos.y - 6, 28, 12), Color(0.20, 0.20, 0.22))
	draw_rect(Rect2(pos.x + 6, pos.y - 12, 26, 6), Color(0.12, 0.12, 0.12))
	draw_line(Vector2(pos.x - 6, pos.y + 6), Vector2(pos.x - 16, pos.y + 18), Color(0.18, 0.18, 0.18), 3.0)
	draw_line(Vector2(pos.x + 6, pos.y + 6), Vector2(pos.x + 16, pos.y + 18), Color(0.18, 0.18, 0.18), 3.0)

func _draw_bird(pos: Vector2):
	var wing = 10.0
	draw_line(pos, pos + Vector2(wing, -4), Color(0.25, 0.25, 0.25, 0.6), 2.0)
	draw_line(pos, pos + Vector2(-wing, -4), Color(0.25, 0.25, 0.25, 0.6), 2.0)

func _draw_platforms():
	for p in PLATFORMS:
		var px  = float(p[0])
		var py  = float(p[1])
		var pw  = float(p[2])
		var top = py - 11.0
		draw_rect(Rect2(px - pw*0.5 + 5, top + 6, pw, 16), Color(0.06, 0.04, 0.02, 0.55))
		draw_rect(Rect2(px - pw*0.5, top, pw, 18), Color(0.24, 0.15, 0.08))
		draw_rect(Rect2(px - pw*0.5, top, pw, 7), Color(0.22, 0.50, 0.12))
		draw_rect(Rect2(px - pw*0.5, top, pw, 3), Color(0.30, 0.62, 0.16))
		for j in range(int(pw / 28)):
			draw_circle(Vector2(px - pw*0.5 + float(j)*28 + 14, top + 4), 3.5, Color(0.35, 0.70, 0.18))

func _draw_bamboo_groups():
	var b1 = [115,270,440,610,785,1020,1255,1475,1695,1915,2170,2420,2650,2875,3085,3330,3555,3780,4010,4280,4530,4770,5020,5280,5520,5760,6010,6250,6480,6720,6960,7200,7440,7680,7870,8120,8360,8600,8840,9080,9320,9560,9800]
	for i in range(0, b1.size(), 2):
		var bx = float(b1[i])
		_bamboo(Vector2(bx, _ground_y(bx) - 5), 1.0)
	var b2 = [195,365,540,720,985,1190,1418,1640,1860,2120,2375,2600,2820,3020,3260,3490,3700,3950,4190,4440,4690,4940,5200,5450,5680,5920,6160,6390,6630,6870,7110,7350,7590,7830,8060,8300,8540,8780,9020,9260,9500,9740,9960]
	for i in range(0, b2.size(), 2):
		var bx = float(b2[i])
		_bamboo(Vector2(bx, _ground_y(bx)) - Vector2(0, 5), 0.62)

func _bamboo(pos: Vector2, s: float):
	var h  = 200.0 * s
	var w  = 7.0 * s
	var gc = Color(0.33, 0.52, 0.16)
	var nc = Color(0.26, 0.41, 0.12)
	var lc = Color(0.22, 0.50, 0.11)
	var sg = maxi(3, int(5.0 * s))
	for i in range(sg):
		var sy = pos.y - float(i) * (h / float(sg))
		draw_rect(Rect2(pos.x - w*0.5, sy - h/float(sg), w, h/float(sg) - 1.0), gc)
		draw_rect(Rect2(pos.x - w*0.5 - 1.0, sy - 3.0, w + 2.0, 4.0), nc)
	var top = Vector2(pos.x, pos.y - h)
	for j in range(5):
		var a = -PI * 0.55 + float(j) * PI * 0.28
		draw_line(top, top + Vector2(cos(a), sin(a)) * 32.0 * s, lc, 2.0 * s)

func _draw_trees():
	var t1 = [215,560,920,1310,1670,2070,2465,2840,3195,3570,3940,4320,4700,5070,5440,5810,6180,6550,6920,7290,7660,8040,8420,8800,9180,9560,9940]
	for i in range(0, t1.size(), 2):
		var tx = float(t1[i])
		_tree(Vector2(tx, _ground_y(tx)), 1.0)
	var t2 = [390,740,1100,1495,1890,2278,2678,3030,3385,3755,4135,4510,4880,5250,5620,5990,6360,6730,7100,7470,7840,8210,8580,8950,9320,9690]
	for i in range(0, t2.size(), 2):
		var tx = float(t2[i])
		_tree(Vector2(tx, _ground_y(tx)), 0.70)

func _tree(pos: Vector2, s: float):
	var th = 130.0 * s
	var tw = 18.0 * s
	draw_rect(Rect2(pos.x - tw*0.5, pos.y - th, tw, th), Color(0.34, 0.21, 0.09))
	draw_line(Vector2(pos.x-3*s, pos.y-th*0.8), Vector2(pos.x-2*s, pos.y-12), Color(0.27,0.16,0.07), 2)
	draw_line(Vector2(pos.x+4*s, pos.y-th*0.7), Vector2(pos.x+3*s, pos.y-15), Color(0.27,0.16,0.07), 2)
	for v in range(4):
		var vy = pos.y - 22.0*float(v)*s - 18.0
		draw_circle(Vector2(pos.x + 9.0*s*sin(float(v)*1.3), vy), 3.0*s, Color(0.22,0.52,0.10))
	var cr = pos + Vector2(0, -th)
	draw_circle(cr + Vector2(  0, 10*s), 54*s, Color(0.11, 0.30, 0.07))
	draw_circle(cr + Vector2(-19*s, 20*s), 42*s, Color(0.11, 0.30, 0.07))
	draw_circle(cr + Vector2( 21*s, 18*s), 40*s, Color(0.11, 0.30, 0.07))
	draw_circle(cr + Vector2( -7*s, -4*s), 48*s, Color(0.17, 0.42, 0.10))
	draw_circle(cr + Vector2( 13*s, -7*s), 38*s, Color(0.17, 0.42, 0.10))
	draw_circle(cr + Vector2(-14*s,-15*s), 34*s, Color(0.23, 0.52, 0.13))
	draw_circle(cr + Vector2(  5*s,-18*s), 30*s, Color(0.23, 0.52, 0.13))

func _draw_details():
	for cx in [340,1370,2470,3540,4650,5850,7050,8250,9450]:
		_crater(float(cx))
	for p in [[155,-5],[675,-4],[1545,-4],[2415,-5],[3170,-5],[4050,-4],[4990,-5],[5930,-5],[6870,-5],[7810,-4],[8750,-4],[9690,-4]]:
		_rock(Vector2(float(p[0]), _ground_y(float(p[0])) + float(p[1])))
	for vx in [305,865,1678,2548,3395,4330,5230,6130,7030,7900,8740,9580]:
		_vine(Vector2(float(vx), 445.0))
	for i in range(0, 68, 2):
		var gx = 75.0 + float(i) * 148.0
		_grass(Vector2(gx, _ground_y(gx) - 7.0))

func _crater(cx: float):
	var gy = _ground_y(cx)
	var pts = PackedVector2Array()
	for i in range(16):
		var a = float(i) * PI * 2.0 / 16.0
		pts.append(Vector2(cx + cos(a)*36.0, gy + 7.0 + sin(a)*11.0))
	draw_colored_polygon(pts, Color(0.13, 0.07, 0.04))
	draw_arc(Vector2(cx, gy+1.0), 40.0, PI*1.1, PI*2.1, 12, Color(0.29,0.18,0.09), 4.0)

func _ground_y(x: float) -> float:
	if x <= TERRAIN_TOP[0].x:
		return TERRAIN_TOP[0].y
	for i in range(TERRAIN_TOP.size() - 1):
		var a = TERRAIN_TOP[i]
		var b = TERRAIN_TOP[i + 1]
		if x <= b.x:
			var t = (x - a.x) / max(b.x - a.x, 1.0)
			return lerp(a.y, b.y, t)
	return TERRAIN_TOP[TERRAIN_TOP.size() - 1].y

func _rock(pos: Vector2):
	var pts = PackedVector2Array([
		pos+Vector2(-17,0), pos+Vector2(-9,-14), pos+Vector2(5,-18),
		pos+Vector2(17,-8), pos+Vector2(13,0)])
	draw_colored_polygon(pts, Color(0.42, 0.38, 0.30))
	draw_polyline(PackedVector2Array([pts[0],pts[1],pts[2],pts[3],pts[4],pts[0]]), Color(0.34,0.30,0.23), 1.0)

func _vine(pos: Vector2):
	var c = Color(0.22, 0.50, 0.13)
	var pts = PackedVector2Array()
	for i in range(12):
		var t = float(i) / 11.0
		pts.append(Vector2(pos.x + sin(t*PI*2.4)*14.0, pos.y + t*170.0))
	draw_polyline(pts, c, 2.0)
	for i in range(0, 12, 3):
		var t  = float(i) / 11.0
		var lp = Vector2(pos.x + sin(t*PI*2.4)*14.0, pos.y + t*170.0)
		draw_circle(lp + Vector2( 7, 0), 5, c)
		draw_circle(lp + Vector2(-7, 0), 5, c)

func _grass(pos: Vector2):
	for i in range(5):
		var a = -PI*0.82 + float(i)*PI*0.16
		draw_line(pos, pos + Vector2(cos(a)*14.0, sin(a)*14.0), Color(0.24,0.55,0.12) if i%2==0 else Color(0.32,0.68,0.16), 2.0)

func _tri(p1: Vector2, p2: Vector2, p3: Vector2, c: Color):
	draw_colored_polygon(PackedVector2Array([p1, p2, p3]), c)
