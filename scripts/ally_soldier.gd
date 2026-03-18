extends CharacterBody2D

## Ally Soldier - Follows player and shoots enemies

@export var speed: float = 140.0
@export var gravity: float = 900.0
@export var follow_distance: float = 120.0
@export var shoot_range: float = 520.0
@export var shoot_cooldown: float = 0.6
@export var max_health: int = 3

var shoot_timer: float = 0.0
var facing_right: bool = true
var anim_timer: float = 0.0
var leg_angle: float = 0.0
var health: int = 3

var bullet_scene = preload("res://scenes/objects/bullet.tscn")

func _ready():
	add_to_group("allies")
	z_index = 6
	collision_layer = 32
	collision_mask = 6
	health = max_health
	scale = Vector2(1.5, 1.5)

func _physics_process(delta):
	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	var player = _find_player()
	if player:
		var dx = player.global_position.x - global_position.x
		if abs(dx) > follow_distance:
			velocity.x = sign(dx) * speed
			facing_right = dx > 0
		else:
			velocity.x = move_toward(velocity.x, 0.0, speed * 2.0 * delta)

	var target = _find_enemy_in_range()
	shoot_timer -= delta
	if target and shoot_timer <= 0.0:
		_fire_at(target)
		shoot_timer = shoot_cooldown

	# Animation
	if abs(velocity.x) > 10:
		anim_timer += delta * 8.0
		leg_angle = sin(anim_timer) * 22.0
	else:
		leg_angle = 0.0

	move_and_slide()
	queue_redraw()

func _find_player() -> Node2D:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	return null

func _find_enemy_in_range() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest: Node2D = null
	var best = shoot_range
	for e in enemies:
		if not e or not is_instance_valid(e):
			continue
		var d = global_position.distance_to(e.global_position)
		if d < best:
			best = d
			nearest = e
	return nearest

func _fire_at(target: Node2D):
	if not bullet_scene:
		return
	var bullet = bullet_scene.instantiate()
	var dir = (target.global_position - global_position).normalized()
	bullet.setup(global_position + dir * 16, dir, 650, 1, Color(0.9, 0.9, 0.2), true)
	get_tree().current_scene.add_child(bullet)

func take_damage(amount: int = 1):
	health = max(health - max(1, amount), 0)
	if health <= 0:
		die()

func die():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.tween_callback(queue_free)

func _draw():
	if health <= 0:
		return

	# === BANG MAU DONG DOI (ALLY) - METAL SLUG STYLE ===
	var P = 3.0
	var col_hat = Color("#326b28")       # Mu tai beo xanh la
	var col_hat_hi = Color("#429b38")    # Mu highlight
	var col_hat_rim = Color("#224d1a")   # Vanh mu
	var col_skin = Color("#e5c198")      # Da vang
	var col_skin_d = Color("#c8a070")    # Da bong
	var col_skin_hi = Color("#f0d8b4")   # Da highlight
	var col_eye = Color("#1a1208")       # Mat
	var col_shirt = Color("#4a823c")     # Ao xanh reu nhat hon player
	var col_shirt_hi = Color("#5a9a4c")  # Ao highlight
	var col_shirt_d = Color("#38662c")   # Ao do bong
	var col_camo1 = Color("#3a6e30")     # Van camo
	var col_pants = Color("#385e2c")     # Quan xanh reu
	var col_pants_d = Color("#284a1e")   # Quan bong
	var col_belt = Color("#4a3620")      # That lung
	var col_shoe = Color("#1a1a1a")      # Dep rau den
	var col_shoe_strap = Color("#2a2a20")# Day dep rau
	var col_gun_metal = Color("#2a2a2a") # Kim loai sung
	var col_gun_hi = Color("#4a4a4a")    # Kim loai highlight
	var col_scarf = Color("#c42020")     # Khan do (dac trung dong doi)
	var col_bandage = Color("#e8dcc8")   # Bang tay trang

	var dir = 1 if facing_right else -1
	var leg_rad = deg_to_rad(leg_angle)
	var is_shooting = shoot_timer > shoot_cooldown - 0.2

	var px = func(x: float, y: float, color: Color, sz: float = P):
		draw_rect(Rect2(x, y, sz, sz), color)
	var draw_limb = func(p1, p2, color, thickness):
		draw_line(p1, p2, color, thickness)

	# === CHAN ===
	var thigh = 6.0
	var shin = 6.0
	var hip_l = Vector2(-2 * dir, 4)
	var hip_r = Vector2( 2 * dir, 4)
	var knee_l = hip_l + Vector2(sin(leg_rad) * thigh * dir, 5)
	var knee_r = hip_r + Vector2(-sin(leg_rad) * thigh * dir, 5)
	var foot_l = knee_l + Vector2(sin(leg_rad) * shin * dir, 5)
	var foot_r = knee_r + Vector2(-sin(leg_rad) * shin * dir, 5)
	
	# Chan sau
	draw_limb.call(hip_l, knee_l, col_pants_d, 4.0)
	draw_limb.call(knee_l, foot_l, col_pants_d, 3.5)
	draw_rect(Rect2(foot_l.x - 2, foot_l.y, 5, 3), col_shoe)
	draw_line(Vector2(foot_l.x - 1, foot_l.y), Vector2(foot_l.x + 2, foot_l.y + 2), col_shoe_strap, 1.0)
	
	# Chan truoc
	draw_limb.call(hip_r, knee_r, col_pants, 4.0)
	draw_limb.call(knee_r, foot_r, col_pants, 3.5)
	# Xa cap cuon
	draw_line(knee_r + Vector2(0, 2), knee_r + Vector2(1.5 * dir, 3.5), col_pants_d, 1.0)
	draw_rect(Rect2(foot_r.x - 2, foot_r.y, 5, 3), col_shoe)
	draw_line(Vector2(foot_r.x - 1, foot_r.y), Vector2(foot_r.x + 2, foot_r.y + 2), col_shoe_strap, 1.0)
	draw_line(Vector2(foot_r.x + 3, foot_r.y), Vector2(foot_r.x, foot_r.y + 2), col_shoe_strap, 1.0)

	# === THAN TREN ===
	var torso_y = -9
	
	# Than chinh
	draw_rect(Rect2(-4, torso_y, 9, 12), col_shirt)
	# Highlight
	draw_rect(Rect2(-4 if dir == 1 else 3, torso_y + 2, 2, 6), col_shirt_hi)
	# Bong
	draw_rect(Rect2(3 if dir == 1 else -4, torso_y + 2, 2, 6), col_shirt_d)
	# Co ao
	draw_rect(Rect2(-4, torso_y, 9, 3), col_shirt_d)
	px.call(-2, torso_y, col_shirt_hi, 4.0)
	
	# Van camo nhe
	px.call(-2, torso_y + 4, col_camo1, 1.5)
	px.call(1, torso_y + 6, col_camo1, 1.5)
	px.call(-1, torso_y + 8, col_camo1, 1.5)
	
	# Tui nguc nho
	draw_rect(Rect2(2 * dir, torso_y + 4, 2, 2), col_shirt_d)
	
	# That lung
	draw_rect(Rect2(-4, torso_y + 10, 9, 2), col_belt)

	# === DAU VA MU TAI BEO ===
	var head_y = -13
	
	# Co
	draw_rect(Rect2(-1, head_y + 3.5, 3, 2), col_skin_d)
	# Mat
	draw_rect(Rect2(-3.5, head_y - 4, 7, 7.5), col_skin)
	# Highlight ma
	px.call(-3, head_y, col_skin_hi, 1.5)
	# Bong cam
	draw_rect(Rect2(-2.5, head_y + 2, 5, 1), col_skin_d)
	# Mat
	px.call(1 * dir, head_y - 1.5, col_eye, 2.0)
	# Long may
	draw_rect(Rect2(0 * dir, head_y - 3, 2.5, 0.8), col_skin_d.darkened(0.3))
	
	# Mu tai beo (khong co ngoi sao - phan biet voi Player)
	draw_rect(Rect2(-3.5, head_y - 8, 7, 4), col_hat)
	draw_rect(Rect2(-2, head_y - 8, 4, 1.5), col_hat_hi)
	draw_rect(Rect2(-5, head_y - 4, 10, 2), col_hat_rim)
	draw_rect(Rect2(-4, head_y - 5, 8, 1), col_hat_rim.lightened(0.1))
	# Nep nhan mu
	px.call(-1, head_y - 7, col_hat_rim.lightened(0.05), 1.0)
	
	# Khan do buoc co (dac trung dong doi)
	draw_line(Vector2(-2, head_y + 3), Vector2(0, head_y + 5), col_scarf, 2.0)
	draw_line(Vector2(0, head_y + 5), Vector2(2 * dir, head_y + 6), col_scarf, 1.5)
	# Duoi khan bay
	draw_line(Vector2(2 * dir, head_y + 6), Vector2(3 * dir, head_y + 8), col_scarf.darkened(0.15), 1.2)

	# === TAY VA SUNG AK ===
	var shoulder = Vector2(2 * dir, -5)
	
	var gun_dir = Vector2(dir, 0)
	var target_e = _find_enemy_in_range()
	if target_e and is_instance_valid(target_e) and is_shooting:
		gun_dir = (target_e.global_position - global_position).normalized()
	
	var gun_perp = Vector2(-gun_dir.y, gun_dir.x)
	var gun_start = shoulder + Vector2(2 * dir, 2)
	
	# Sung AK nho gon hon player
	var gun_end = gun_start + gun_dir * 13
	draw_line(gun_start - gun_dir * 3, gun_start, Color("#6e4a2e"), 3.0)  # Bang go
	draw_line(gun_start, gun_start + gun_dir * 5, col_gun_metal, 3.5)     # Than
	draw_line(gun_start + gun_dir * 5, gun_start + gun_dir * 8, Color("#6e4a2e"), 3.0)  # Op tay cam
	draw_line(gun_start + gun_dir * 8, gun_end, col_gun_metal, 2.0)      # Nong
	
	# Bang dan cong
	var mag_dir = gun_dir.rotated(deg_to_rad(70 * dir))
	draw_line(gun_start + gun_dir * 4, gun_start + gun_dir * 4 + mag_dir * 4.5, col_gun_metal, 2.5)

	# Muzzle flash
	if is_shooting:
		var flash_pos = gun_end + gun_dir * 2
		draw_circle(flash_pos, 3.5, Color(1, 0.9, 0.3, 0.7))
		draw_circle(flash_pos, 2, Color(1, 0.8, 0.2, 0.9))

	# Tay phai
	draw_limb.call(shoulder, gun_start, col_shirt, 3.5)
	draw_rect(Rect2(gun_start.x - 1.5, gun_start.y - 1.5, 3, 3), col_skin)
	
	# Bang tay (bandage) tren canh tay phai - chi tiet dac biet
	var mid_arm = shoulder.lerp(gun_start, 0.4)
	draw_line(mid_arm + Vector2(-1, 0), mid_arm + Vector2(1, 1), col_bandage, 1.5)
	draw_line(mid_arm + Vector2(-1, 1), mid_arm + Vector2(1, 2), col_bandage, 1.5)
	
	# Tay trai (do sung)
	var shoulder_l = Vector2(-3 * dir, -5)
	var handguard_pos = gun_start + gun_dir * 6
	draw_limb.call(shoulder_l, handguard_pos, col_shirt.darkened(0.15), 3.5)
	draw_rect(Rect2(handguard_pos.x - 1.5, handguard_pos.y - 1.5, 3, 3), col_skin.darkened(0.15))
