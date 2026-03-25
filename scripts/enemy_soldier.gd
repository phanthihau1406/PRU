extends CharacterBody2D

## Enemy Soldier - Basic enemy with patrol and shooting

signal enemy_died(enemy)

@export var speed: float = 80.0
@export var health: float = 3.0
@export var damage: int = 1
@export var gravity: float = 900.0
@export var detection_range: float = 350.0
@export var shoot_range: float = 300.0
@export var patrol_distance: float = 150.0
@export var enemy_color: Color = Color(0.5, 0.45, 0.35)  # Khaki
@export var topdown_mode: bool = false

enum State { PATROL, CHASE, SHOOT, DEAD }
var state: State = State.PATROL
var facing_right: bool = true
var patrol_origin: float = 0.0
var shoot_timer: float = 0.0
var shoot_cooldown: float = 1.2
var anim_timer: float = 0.0
var leg_angle: float = 0.0
var flash_timer: float = 0.0
var hit_flash: float = 0.0

var bullet_scene = preload("res://scenes/objects/bullet.tscn")

func _ready():
	patrol_origin = global_position.x
	add_to_group("enemies")
	z_index = 5
	scale = Vector2(1.5, 1.5)
	
	if topdown_mode:
		set_collision_mask_value(1, false)

func _physics_process(delta):
	if state == State.DEAD:
		return
		
	if topdown_mode and get_collision_mask_value(1):
		set_collision_mask_value(1, false)
	
	# Gravity
	if not is_on_floor() and not topdown_mode:
		velocity.y += gravity * delta
	
	# Find player
	var player = _find_player()
	var dist_to_player = INF
	if player:
		dist_to_player = global_position.distance_to(player.global_position)
	
	# State machine
	match state:
		State.PATROL:
			_patrol(delta)
			if dist_to_player < detection_range:
				state = State.CHASE
		State.CHASE:
			if player:
				_chase(player, delta)
			if dist_to_player < shoot_range:
				state = State.SHOOT
			elif dist_to_player > detection_range * 1.5:
				state = State.PATROL
		State.SHOOT:
			if player:
				_shoot_at(player, delta)
			if dist_to_player > shoot_range * 1.3:
				state = State.CHASE
	
	# Animation
	if abs(velocity.x) > 10:
		anim_timer += delta * 8
		leg_angle = sin(anim_timer) * 25
	else:
		leg_angle = 0
	
	# Hit flash
	if hit_flash > 0:
		hit_flash -= delta
	
	move_and_slide()
	queue_redraw()

func _patrol(delta):
	var dir = 1 if facing_right else -1
	velocity.x = speed * dir
	
	if global_position.x > patrol_origin + patrol_distance:
		facing_right = false
	elif global_position.x < patrol_origin - patrol_distance:
		facing_right = true

func _chase(player: Node2D, _delta):
	if player.global_position.x > global_position.x + 10:
		velocity.x = speed * 1.3
		facing_right = true
	elif player.global_position.x < global_position.x - 10:
		velocity.x = -speed * 1.3
		facing_right = false
	else:
		velocity.x = 0
		
	if topdown_mode:
		if player.global_position.y > global_position.y + 10:
			velocity.y = speed * 1.3
		elif player.global_position.y < global_position.y - 10:
			velocity.y = -speed * 1.3
		else:
			velocity.y = 0

func _shoot_at(player: Node2D, delta):
	velocity.x = 0
	if topdown_mode: velocity.y = 0
	facing_right = player.global_position.x > global_position.x
	
	shoot_timer -= delta
	if shoot_timer <= 0:
		_fire_bullet(player)
		shoot_timer = shoot_cooldown

func _fire_bullet(player: Node2D):
	if not bullet_scene:
		return
	var bullet = bullet_scene.instantiate()
	var dir = (player.global_position - global_position).normalized()
	bullet.setup(global_position + dir * 15, dir, 350, damage, Color(1, 0.6, 0.1), false)
	get_tree().current_scene.add_child(bullet)

func _find_player() -> Node2D:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	return null

func take_damage(amount: float):
	health -= amount
	hit_flash = 0.15
	if health <= 0:
		die()

func die():
	state = State.DEAD
	GameManager.add_score(100)
	enemy_died.emit(self)
	# Death effect
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)

func _draw():
	if state == State.DEAD:
		return
	
	# === BANG MAU LINH DICH - METAL SLUG STYLE ===
	var P = 3.0
	var col_helmet = Color("#5c5e3c")
	var col_helmet_hi = Color("#7c7e5c")
	var col_helmet_d = Color("#3c3e2c")
	var col_skin = Color("#d4a574")
	var col_skin_d = Color("#b48a5c")
	var col_skin_hi = Color("#e8c098")
	var col_eye = Color("#1a1208")
	var col_shirt = Color("#8b7d5c")
	var col_shirt_hi = Color("#a89870")
	var col_shirt_d = Color("#6b5d4c")
	var col_pants = Color("#9a8e6c")
	var col_pants_d = Color("#7a6e4c")
	var col_belt = Color("#3e2e1e")
	var col_belt_buckle = Color("#8a8a7a")
	var col_shoe = Color("#3e2e1e")
	var col_shoe_hi = Color("#5e4e3e")
	var col_gun_metal = Color("#1e1e1e")
	var col_gun_hi = Color("#3e3e3e")
	var col_webbing = Color("#5c5240")
	var col_dogtag = Color("#c0c0c0")
	
	if hit_flash > 0:
		col_shirt = Color.WHITE
		col_pants = Color.WHITE
		col_helmet = Color.WHITE
	
	var dir = 1 if facing_right else -1
	var leg_rad = deg_to_rad(leg_angle)
	var is_shooting_state = state == State.SHOOT

	var px = func(x: float, y: float, color: Color, sz: float = P):
		draw_rect(Rect2(x, y, sz, sz), color)
	var draw_limb = func(p1, p2, color, thickness):
		draw_line(p1, p2, color, thickness)

	# === CHAN ===
	var thigh = 6.0
	var shin = 7.0
	var hip_l = Vector2(-2 * dir, 3)
	var hip_r = Vector2( 2 * dir, 3)
	var knee_l = hip_l + Vector2(sin(leg_rad) * thigh * dir, 5)
	var knee_r = hip_r + Vector2(-sin(leg_rad) * thigh * dir, 5)
	var foot_l = knee_l + Vector2(sin(leg_rad) * shin * dir, 6)
	var foot_r = knee_r + Vector2(-sin(leg_rad) * shin * dir, 6)
	
	# Chan sau
	draw_limb.call(hip_l, knee_l, col_pants_d, 4.5)
	draw_limb.call(knee_l, foot_l, col_pants_d, 4.0)
	draw_rect(Rect2(foot_l.x - 2.5, foot_l.y - 1, 6, 5), col_shoe)
	draw_rect(Rect2(foot_l.x - 2.5, foot_l.y - 1, 6, 1), col_shoe_hi)
	draw_rect(Rect2(foot_l.x - 3, foot_l.y + 3, 7, 1.5), col_shoe.darkened(0.3))
	
	# Chan truoc
	draw_limb.call(hip_r, knee_r, col_pants, 4.5)
	draw_limb.call(knee_r, foot_r, col_pants, 4.0)
	draw_line(knee_r + Vector2(0, 3), knee_r + Vector2(2 * dir, 5), col_webbing, 1.0)
	draw_rect(Rect2(foot_r.x - 2.5, foot_r.y - 1, 6, 5), col_shoe)
	draw_rect(Rect2(foot_r.x - 2.5, foot_r.y - 1, 6, 1), col_shoe_hi)
	draw_line(Vector2(foot_r.x, foot_r.y), Vector2(foot_r.x + 2, foot_r.y + 1), col_webbing, 0.8)
	draw_rect(Rect2(foot_r.x - 3, foot_r.y + 3, 7, 1.5), col_shoe.darkened(0.3))

	# === THAN TREN ===
	var torso_y = -10
	var bp_x = -8 * dir if dir == 1 else 2
	draw_rect(Rect2(bp_x, torso_y + 2, 6, 9), col_shirt_d.darkened(0.1))
	draw_rect(Rect2(bp_x, torso_y + 2, 6, 2), col_shirt_d.darkened(0.2))
	px.call(bp_x + 1, torso_y + 5, col_belt, 4.0)
	
	draw_rect(Rect2(-5, torso_y, 10, 13), col_shirt)
	draw_rect(Rect2(-5 if dir == 1 else 3, torso_y + 2, 2, 7), col_shirt_hi)
	draw_rect(Rect2(3 if dir == 1 else -5, torso_y + 2, 2, 7), col_shirt_d)
	draw_rect(Rect2(-5, torso_y, 10, 3), col_shirt_d)
	px.call(-2, torso_y, col_shirt_hi, 4.0)
	
	# Dog tag
	draw_line(Vector2(-1, torso_y + 2), Vector2(0, torso_y + 5), col_dogtag, 0.8)
	px.call(-0.5, torso_y + 5, col_dogtag, 1.5)
	
	# Webbing + Ammo pouches
	draw_rect(Rect2(-2, torso_y + 2, 2, 9), col_webbing)
	draw_rect(Rect2( 2, torso_y + 2, 2, 9), col_webbing)
	draw_rect(Rect2(-3, torso_y + 5, 3, 2), col_belt)
	draw_rect(Rect2( 2, torso_y + 5, 3, 2), col_belt)
	draw_rect(Rect2(-3, torso_y + 5, 3, 1), col_belt.lightened(0.15))
	draw_rect(Rect2( 2, torso_y + 5, 3, 1), col_belt.lightened(0.15))
	
	draw_rect(Rect2(-5, torso_y + 11, 10, 2), col_belt)
	px.call(-1, torso_y + 11, col_belt_buckle, 2.0)

	# === DAU VA MU SAT M1 ===
	var head_y = -14
	draw_rect(Rect2(-1.5, head_y + 4, 3.5, 2.5), col_skin_d)
	draw_rect(Rect2(-4, head_y - 4, 8, 8), col_skin)
	px.call(-3, head_y, col_skin_hi, 2.0)
	draw_rect(Rect2(-3, head_y + 2.5, 6, 1), col_skin_d)
	px.call(1.5 * dir, head_y - 1.5, col_eye, 2.0)
	draw_rect(Rect2(0.5 * dir, head_y - 3, 3, 1), col_skin_d.darkened(0.3))
	
	# Mu sat M1
	draw_rect(Rect2(-5, head_y - 4, 11, 2), col_helmet_d)
	draw_rect(Rect2(-4, head_y - 8, 9, 5), col_helmet)
	draw_rect(Rect2(-3, head_y - 8, 6, 2), col_helmet_hi)
	draw_rect(Rect2(-2, head_y - 9, 5, 1), col_helmet.lightened(0.1))
	# Chin strap
	draw_line(Vector2(-4, head_y - 3), Vector2(-3, head_y + 1), col_webbing, 1.2)
	draw_line(Vector2(5, head_y - 3), Vector2(4, head_y + 1), col_webbing, 1.2)
	# Camo net
	px.call(-1, head_y - 7, col_helmet_d, 1.5)
	px.call(2, head_y - 6, col_helmet_d, 1.5)

	# === TAY VA SUNG M16 ===
	var shoulder = Vector2(2 * dir, -6)
	var gun_dir = Vector2(dir, 0)
	if is_shooting_state:
		var player = _find_player()
		if player:
			gun_dir = (player.global_position - global_position).normalized()
	
	var gun_perp = Vector2(-gun_dir.y, gun_dir.x)
	var gun_start = shoulder + Vector2(1 * dir, 2)
	
	# Bang sung M16
	var stock_end = gun_start - gun_dir * 5
	draw_line(gun_start, stock_end, col_gun_metal, 3.5)
	draw_line(gun_start - gun_dir * 1, stock_end, col_gun_hi, 1.0)
	
	# Than + carrying handle
	var body_end = gun_start + gun_dir * 6
	draw_line(gun_start, body_end, col_gun_metal, 4.0)
	draw_line(gun_start + gun_perp * 1.2, body_end + gun_perp * 1.2, col_gun_hi, 0.8)
	var handle_h = -3.5
	draw_line(gun_start + Vector2(0, handle_h), gun_start + gun_dir * 4.5 + Vector2(0, handle_h), col_gun_metal, 2.0)
	draw_line(gun_start, gun_start + Vector2(0, handle_h), col_gun_metal, 1.5)
	draw_line(gun_start + gun_dir * 4.5, gun_start + gun_dir * 4.5 + Vector2(0, handle_h), col_gun_metal, 1.5)
	
	# Pistol grip
	var grip_end = gun_start + Vector2(0, 4) + gun_dir * 2
	draw_line(gun_start + gun_dir * 2, grip_end, col_gun_metal, 2.5)
	
	# Handguard
	var handguard_start = body_end
	var handguard_end = handguard_start + gun_dir * 6
	draw_line(handguard_start, handguard_end, col_gun_metal.lightened(0.12), 4.0)
	
	# Nong + front sight + flash suppressor
	var barrel_end = handguard_end + gun_dir * 5
	draw_line(handguard_end, barrel_end, col_gun_metal, 2.0)
	draw_line(handguard_end + gun_dir * 2, handguard_end + gun_dir * 2 - gun_perp * 2.5, col_gun_metal, 1.5)
	draw_line(barrel_end - gun_dir * 1.5, barrel_end, col_gun_metal, 2.5)
	
	# STANAG magazine
	draw_line(body_end + gun_dir * 1, body_end + gun_dir * 1 + Vector2(0, 5), col_gun_metal, 3.0)

	# Muzzle flash
	if is_shooting_state and shoot_timer > shoot_cooldown - 0.15:
		var flash_pos = barrel_end + gun_dir * 2
		draw_circle(flash_pos, 4, Color(1, 0.7, 0.2, 0.7))
		draw_circle(flash_pos, 2.5, Color(1, 0.9, 0.4, 0.9))
		draw_line(flash_pos, flash_pos + gun_perp * 3, Color(1, 0.6, 0.1, 0.5), 1.0)
		draw_line(flash_pos, flash_pos - gun_perp * 3, Color(1, 0.6, 0.1, 0.5), 1.0)

	# Tay phai
	draw_limb.call(shoulder, gun_start, col_shirt, 4.0)
	draw_rect(Rect2(gun_start.x - 1.5, gun_start.y - 1.5, 3.5, 3.5), col_skin)
	px.call(gun_start.x - 1, gun_start.y + 1, col_skin_d, 1.5)
	
	# Tay trai
	var shoulder_l = Vector2(-3 * dir, -6)
	var handguard_pos = handguard_start + gun_dir * 2
	draw_limb.call(shoulder_l, handguard_pos, col_shirt.darkened(0.15), 4.0)
	draw_rect(Rect2(handguard_pos.x - 1.5, handguard_pos.y - 1.5, 3.5, 3.5), col_skin.darkened(0.15))
