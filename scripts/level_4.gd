extends "res://scripts/base_level.gd"

## Level 4: Căn cứ địch (night base)
## Nhiều ổ hỏa lực cố định và boss pháo đài.

var fortress_boss_scene = preload("res://scenes/objects/boss_fortress.tscn")
var tank_scene = preload("res://scenes/objects/tank_vehicle.tscn")
var prop_scene = preload("res://scenes/objects/destructible_prop.tscn")
var powerup_scene = preload("res://scenes/objects/powerup.tscn")

const LEVEL_W: float = 4000.0
const GROUND_Y: float = 650.0

var _spot_time: float = 0.0

func setup_level():
	level_name = "MÀN 4: CĂN CỨ ĐỊCH"

	for px in [300, 650, 1000, 1350, 1700, 2050, 2400, 2750, 3100, 3450]:
		_spawn_soldier(Vector2(float(px), GROUND_Y - 14.0))

	for px in [900, 1900, 2800]:
		_spawn_tank(Vector2(float(px), GROUND_Y - 10.0))

	for px in [700, 1600, 2300, 3000]:
		_spawn_prop(Vector2(float(px), GROUND_Y - 10.0), DestructibleProp.PropType.SANDBAG)
	for px in [1200, 2100, 3300]:
		_spawn_prop(Vector2(float(px), GROUND_Y - 10.0), DestructibleProp.PropType.CANNON)

	_spawn_powerup(Vector2(1500, GROUND_Y - 30), PowerUp.PowerType.SHIELD)
	_spawn_powerup(Vector2(2600, GROUND_Y - 30), PowerUp.PowerType.HEALTH)

	# Boss pháo đài
	var boss = fortress_boss_scene.instantiate()
	boss.global_position = Vector2(3600, GROUND_Y - 20)
	boss.boss_defeated.connect(_on_boss_defeated)
	add_child(boss)

func _ready():
	super._ready()
	_setup_level_bgm("res://assets/audio/game_background_music1.mp3", -10.0)
	queue_redraw()

func _process(delta):
	_spot_time += delta
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
	complete_level()

func _draw():
	_draw_night_sky()
	_draw_base_silhouettes()
	_draw_spotlights()
	_draw_ground()
	_draw_fences()

func _draw_night_sky():
	draw_rect(Rect2(-1000, -1000, 6000, 2000), Color(0.05, 0.06, 0.10))
	draw_rect(Rect2(-1000, -200, 6000, 400), Color(0.08, 0.09, 0.15, 0.9))
	for i in range(30):
		var px = float(i) * 200.0
		var py = 60 + float((i * 37) % 120)
		draw_circle(Vector2(px, py), 1.5, Color(0.6, 0.7, 0.9, 0.5))

func _draw_base_silhouettes():
	for i in range(10):
		var x = -200 + i * 500
		var w = 240 + float((i * 17) % 120)
		var h = 140 + float((i * 29) % 160)
		draw_rect(Rect2(x, 520 - h, w, h), Color(0.10, 0.10, 0.14))

func _draw_spotlights():
	for i in range(4):
		var x = 400 + i * 1000
		var sway = sin(_spot_time * 0.8 + float(i)) * 0.2
		var pts = PackedVector2Array([
			Vector2(x - 30, 540),
			Vector2(x + 30, 540),
			Vector2(x + 240, 0) + Vector2(0, sway * 120),
			Vector2(x - 240, 0) + Vector2(0, sway * 120)
		])
		draw_colored_polygon(pts, Color(1.0, 0.95, 0.7, 0.05))

func _draw_ground():
	draw_rect(Rect2(-1000, GROUND_Y, 6000, 720), Color(0.12, 0.10, 0.08))
	draw_rect(Rect2(-1000, GROUND_Y - 6, 6000, 6), Color(0.20, 0.16, 0.12))

func _draw_fences():
	for i in range(12):
		var x = 200 + i * 320
		draw_rect(Rect2(x, GROUND_Y - 40, 6, 40), Color(0.25, 0.24, 0.22))
		draw_line(Vector2(x - 80, GROUND_Y - 28), Vector2(x + 80, GROUND_Y - 22), Color(0.35, 0.32, 0.30), 2.0)
