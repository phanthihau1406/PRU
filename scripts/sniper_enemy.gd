extends CharacterBody2D

## Sniper Enemy - Ke dich ban tia tren tru cau
## Dung yen, phat hien Player trong tam ngam va ban moi 2 giay

signal enemy_died(enemy)

@export var health: float = 4.0
@export var damage: int = 2
@export var detection_radius: float = 450.0
@export var shoot_cooldown: float = 2.0
@export var gravity: float = 900.0
@export var enemy_color: Color = Color(0.4, 0.35, 0.3)

var is_dead: bool = false
var player_in_range: bool = false
var target_player: Node2D = null
var shoot_timer: float = 0.0
var hit_flash: float = 0.0
var facing_right: bool = true
var anim_timer: float = 0.0

var bullet_scene = preload("res://scenes/objects/bullet.tscn")

func _ready():
	add_to_group("enemies")
	z_index = 6
	scale = Vector2(1.5, 1.5)
	
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(14, 24)
	col.shape = shape
	col.position = Vector2(0, 0)
	add_child(col)
	
	collision_layer = 2
	collision_mask = 5
	
	var detection_area = Area2D.new()
	detection_area.name = "DetectionArea"
	detection_area.collision_layer = 0
	detection_area.collision_mask = 1
	
	var area_col = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = detection_radius
	area_col.shape = circle
	detection_area.add_child(area_col)
	add_child(detection_area)
	
	detection_area.body_entered.connect(_on_body_detected)
	detection_area.body_exited.connect(_on_body_lost)
	
	shoot_timer = shoot_cooldown * 0.5

func _physics_process(delta):
	if is_dead:
		return
	
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0
	
	if target_player and is_instance_valid(target_player):
		facing_right = target_player.global_position.x > global_position.x
	
	if player_in_range and target_player and is_instance_valid(target_player):
		shoot_timer -= delta
		if shoot_timer <= 0:
			_fire_at_player()
			shoot_timer = shoot_cooldown
	
	if hit_flash > 0:
		hit_flash -= delta
	
	anim_timer += delta
	
	move_and_slide()
	queue_redraw()

func _on_body_detected(body: Node2D):
	if body.is_in_group("player"):
		player_in_range = true
		target_player = body

func _on_body_lost(body: Node2D):
	if body.is_in_group("player"):
		player_in_range = false

func _fire_at_player():
	if not bullet_scene or not target_player:
		return
	
	var bullet = bullet_scene.instantiate()
	var dir = (target_player.global_position - global_position).normalized()
	bullet.setup(global_position + dir * 18, dir, 420, damage, Color(1, 0.3, 0.1), false)
	get_tree().current_scene.add_child(bullet)

func take_damage(amount: float):
	if is_dead:
		return
	health -= amount
	hit_flash = 0.15
	if health <= 0:
		die()

func die():
	is_dead = true
	GameManager.add_score(200)
	enemy_died.emit(self)
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.tween_callback(queue_free)

func _draw():
	if is_dead:
		return
	
	# === BANG MAU LINH BAN TIA (SNIPER) - METAL SLUG STYLE ===
	var P = 3.0
	var col_hat = Color("#3e4a2e")       # Mu rung ran ri
	var col_hat_hi = Color("#5e6a4e")    # Mu highlight
	var col_hat_d = Color("#2e3a1e")     # Mu bong
	var col_skin = Color("#d4a574")      # Da sang
	var col_skin_d = Color("#b48a5c")    # Da bong
	var col_skin_hi = Color("#e8c098")   # Da highlight
	var col_eye = Color("#1a1208")       # Mat
	var col_shirt = Color("#5a6b4a")     # Ao ran ri (camo)
	var col_shirt_hi = Color("#7a8b6a")  # Ao highlight
	var col_shirt_d = Color("#3e4a2e")   # Ao bong
	var col_camo1 = Color("#4a5a3a")     # Van camo
	var col_camo2 = Color("#6a7b5a")     # Van camo sang
	var col_camo3 = Color("#3e4830")     # Van camo toi
	var col_pants = Color("#6b7d5a")     # Quan ran ri sang
	var col_pants_d = Color("#4b5d3a")   # Quan bong
	var col_belt = Color("#2e1e0e")      # That lung
	var col_shoe = Color("#2e1e0e")      # Giay den/nau dam
	var col_shoe_hi = Color("#4e3e2e")   # Giay highlight
	var col_gun_metal = Color("#1e1e1e") # Kim loai sung Sniper
	var col_gun_hi = Color("#3e3e3e")    # Kim loai highlight
	var col_scope = Color("#0a0a0a")     # Ong ngam den
	var col_scope_lens = Color("#2060a0")# Thau kinh xanh
	var col_ghillie = Color("#4a5a30")   # Ghillie suit strips
	
	if hit_flash > 0:
		col_shirt = Color.WHITE
		col_pants = Color.WHITE
		col_hat = Color.WHITE
	
	var dir = 1 if facing_right else -1
	
	var px = func(x: float, y: float, color: Color, sz: float = P):
		draw_rect(Rect2(x, y, sz, sz), color)
	var draw_limb = func(p1, p2, color, thickness):
		draw_line(p1, p2, color, thickness)
		
	# === CHAN (Tu the quy - Kneeling) ===
	var hip_pos = Vector2(0, 3)
	
	# Chan sau (quy han xuong dat)
	var back_knee = hip_pos + Vector2(4 * dir, 7)
	var back_foot = back_knee + Vector2(2 * dir, 0)
	draw_limb.call(hip_pos + Vector2(1*dir,0), back_knee, col_pants_d, 4.0)
	draw_limb.call(back_knee, back_foot, col_pants_d, 3.5)
	draw_rect(Rect2(back_foot.x - 2, back_foot.y - 1, 5, 3.5), col_shoe)
	draw_rect(Rect2(back_foot.x - 2, back_foot.y - 1, 5, 1), col_shoe_hi)
	
	# Chan truoc (chong len)
	var front_knee = hip_pos + Vector2(-4 * dir, 3)
	var front_foot = front_knee + Vector2(0, 7)
	draw_limb.call(hip_pos + Vector2(-1*dir,0), front_knee, col_pants, 4.0)
	draw_limb.call(front_knee, front_foot, col_pants, 3.5)
	# Ghệt (gaiter)
	draw_line(front_knee + Vector2(0, 3), front_knee + Vector2(1.5 * dir, 5), col_belt, 1.0)
	draw_rect(Rect2(front_foot.x - 2, front_foot.y, 5, 3.5), col_shoe)
	draw_rect(Rect2(front_foot.x - 2, front_foot.y, 5, 1), col_shoe_hi)

	# === THAN TREN (Nghieng ve phia truoc) ===
	var torso_bend = Vector2(2 * dir, 0)
	var torso_top = Vector2(-1 * dir, -7) + torso_bend
	var torso_bottom = Vector2(0, 3)
	
	# Than ao
	draw_limb.call(torso_top, torso_bottom, col_shirt, 9.0)
	# Highlight
	draw_limb.call(torso_top + Vector2(-2 * dir, 0), torso_bottom + Vector2(-2 * dir, 0), col_shirt_hi, 2.0)
	# Bong
	draw_limb.call(torso_top + Vector2(2 * dir, 0), torso_bottom + Vector2(2 * dir, 0), col_shirt_d, 2.0)
	
	# Van ran ri (camo pattern) tren ao
	px.call(torso_top.x - 1, torso_top.y + 1, col_camo1, 2.0)
	px.call(torso_top.x + 1, torso_top.y + 3, col_camo2, 1.5)
	px.call(torso_bottom.x - 2, torso_bottom.y - 3, col_camo3, 2.0)
	px.call(torso_bottom.x + 1, torso_bottom.y - 5, col_camo1, 1.5)
	
	# Ghillie strips (day nguy trang) treo tren vai
	draw_line(torso_top + Vector2(-3 * dir, 0), torso_top + Vector2(-4 * dir, 4), col_ghillie, 1.2)
	draw_line(torso_top + Vector2(-2 * dir, 1), torso_top + Vector2(-3 * dir, 5), col_ghillie.lightened(0.1), 1.0)
	draw_line(torso_top + Vector2(1 * dir, 0), torso_top + Vector2(2 * dir, 3), col_ghillie.darkened(0.1), 1.0)
	
	# Dem vai chong giat (shoulder pad)
	draw_rect(Rect2(torso_top.x - 2, torso_top.y, 4, 3), col_belt)
	px.call(torso_top.x - 1, torso_top.y + 1, col_belt.lightened(0.15), 2.0)
	
	# That lung
	draw_rect(Rect2(torso_bottom.x - 3, torso_bottom.y - 1, 6, 2), col_belt)

	# === DAU VA MU ===
	var head_pos = torso_top + Vector2(1 * dir, -4)
	
	# Mat
	draw_rect(Rect2(head_pos.x - 3.5, head_pos.y - 3.5, 7, 7), col_skin)
	# Highlight ma
	px.call(head_pos.x - 3, head_pos.y, col_skin_hi, 1.5)
	# Bong cam
	draw_rect(Rect2(head_pos.x - 2.5, head_pos.y + 2, 5, 1), col_skin_d)
	# Mat (dang nhom ong ngam - nham 1 mat)
	px.call(head_pos.x + 1.5 * dir, head_pos.y - 1, col_eye, 2.0)
	# Mat con lai nham (duong ngang)
	draw_line(Vector2(head_pos.x - 1.5 * dir, head_pos.y - 0.5), Vector2(head_pos.x - 1.5 * dir + 1.5, head_pos.y - 0.5), col_skin_d.darkened(0.3), 1.0)
	# Long may
	draw_rect(Rect2(head_pos.x + 0.5 * dir, head_pos.y - 3, 2.5, 0.8), col_skin_d.darkened(0.3))
	
	# Son mat nguy trang (face paint) - 2 van ngang
	draw_line(Vector2(head_pos.x - 2.5, head_pos.y + 0.5), Vector2(head_pos.x + 3, head_pos.y + 0.5), col_camo3, 1.0)
	
	# Mu (Boonie hat / Mu rung) - chi tiet hon
	draw_rect(Rect2(head_pos.x - 4.5, head_pos.y - 7, 9, 4), col_hat)
	draw_rect(Rect2(head_pos.x - 3, head_pos.y - 7, 5, 1.5), col_hat_hi) # Highlight
	draw_rect(Rect2(head_pos.x - 5.5, head_pos.y - 3, 11, 1.5), col_hat.darkened(0.2)) # Vanh mu cup
	# Van ran ri tren mu
	px.call(head_pos.x - 2, head_pos.y - 6, col_hat_d, 1.5)
	px.call(head_pos.x + 1, head_pos.y - 5, col_hat_d, 1.5)
	# La cay nguy trang (foliage) tuc tren mu
	draw_line(Vector2(head_pos.x - 3, head_pos.y - 7), Vector2(head_pos.x - 5, head_pos.y - 9), col_ghillie, 1.2)
	draw_line(Vector2(head_pos.x + 2, head_pos.y - 7), Vector2(head_pos.x + 4, head_pos.y - 9), col_ghillie.lightened(0.1), 1.0)
	draw_line(Vector2(head_pos.x, head_pos.y - 7), Vector2(head_pos.x - 1, head_pos.y - 9.5), col_ghillie.darkened(0.05), 1.0)

	# === TAY VA SUNG BAN TIA (SNIPER RIFLE) - Chi tiet Metal Slug ===
	var shoulder = torso_top + Vector2(0, 1)
	
	var gun_dir = Vector2(dir, 0)
	if target_player and is_instance_valid(target_player) and player_in_range:
		gun_dir = (target_player.global_position - global_position).normalized()
	
	var gun_perp = Vector2(-gun_dir.y, gun_dir.x)
	var gun_start = shoulder + Vector2(2 * dir, 1)
	
	# Bang sung dai, ti vao vai
	var stock_end = gun_start - gun_dir * 6
	draw_line(gun_start, stock_end, col_gun_metal, 3.5)
	draw_line(gun_start - gun_dir * 1, stock_end, col_gun_hi, 1.0)
	# Dem bang sung (cheek rest)
	draw_line(stock_end + gun_perp * 1, stock_end + gun_dir * 3 + gun_perp * 1, col_gun_hi, 1.5)
	
	# Than sung
	var body_end = gun_start + gun_dir * 7
	draw_line(gun_start, body_end, col_gun_metal, 4.0)
	draw_line(gun_start + gun_perp * 1.2, body_end + gun_perp * 1.2, col_gun_hi, 0.8)
	
	# Co dan (trigger guard)
	var grip_end = gun_start + Vector2(0, 3) + gun_dir * 2
	draw_line(gun_start + gun_dir * 2, grip_end, col_gun_metal, 2.0)
	
	# Nong sung ban tia (rat dai)
	var barrel_end = body_end + gun_dir * 14
	draw_line(body_end, barrel_end, col_gun_metal, 2.0)
	# Dau bu lua (compensator)
	draw_line(barrel_end - gun_dir * 2, barrel_end, col_gun_metal, 2.8)
	
	# Bi-pod (chan chong) gap lai
	var bipod_pos = body_end + gun_dir * 2
	draw_line(bipod_pos, bipod_pos + Vector2(1 * dir, 3), col_gun_metal, 1.0)
	draw_line(bipod_pos, bipod_pos + Vector2(-1 * dir, 3), col_gun_metal, 1.0)
	
	# Ong ngam (Scope) - to va chi tiet
	var scope_start = gun_start + gun_dir * 2 - gun_perp * 3
	var scope_end = scope_start + gun_dir * 6
	# Than ong ngam
	draw_line(scope_start, scope_end, col_scope, 3.0)
	# Highlight ong ngam
	draw_line(scope_start + gun_perp * 0.8, scope_end + gun_perp * 0.8, col_gun_hi, 0.8)
	# Chan de ong ngam (scope mounts)
	draw_line(scope_start + gun_dir * 1, scope_start + gun_dir * 1 + gun_perp * 2.5, col_scope, 1.5)
	draw_line(scope_end - gun_dir * 1, scope_end - gun_dir * 1 + gun_perp * 2.5, col_scope, 1.5)
	# Thau kinh phia truoc (objective lens)
	draw_circle(scope_end + gun_dir * 0.5, 1.8, col_scope_lens)
	draw_circle(scope_end + gun_dir * 0.5, 1.0, col_scope_lens.lightened(0.3))
	# Thau kinh phia sau (eyepiece)
	draw_circle(scope_start - gun_dir * 0.5, 1.2, col_scope)
	# Noi chinh (turret knobs)
	px.call(scope_start.x + gun_dir.x * 3, scope_start.y - 2, col_gun_hi, 1.5)
	
	# Bang dan nho
	draw_line(body_end + gun_dir * 1, body_end + gun_dir * 1 + Vector2(0, 3.5), col_gun_metal, 2.5)

	# Muzzle flash
	if shoot_timer > shoot_cooldown - 0.12:
		var flash_pos = barrel_end + gun_dir * 2
		draw_circle(flash_pos, 5, Color(1, 0.6, 0.2, 0.8))
		draw_circle(flash_pos, 3, Color(1, 0.9, 0.5, 0.9))
		draw_circle(flash_pos + gun_dir * 3, 2, Color(1, 1, 0.6, 0.5))
		# Tia lua
		draw_line(flash_pos, flash_pos + gun_perp * 5, Color(1, 0.7, 0.1, 0.4), 1.0)
		draw_line(flash_pos, flash_pos - gun_perp * 5, Color(1, 0.7, 0.1, 0.4), 1.0)

	# Laser sight (tia ngam do khi phat hien Player)
	if player_in_range and target_player and is_instance_valid(target_player):
		var laser_end = barrel_end + gun_dir * 100
		# Tia laser chinh
		draw_line(barrel_end, laser_end, Color(1, 0.1, 0.1, 0.30), 1.0)
		# Laser dot (cham do)
		draw_circle(laser_end, 2, Color(1, 0.1, 0.1, 0.5))
		draw_circle(laser_end, 1, Color(1, 0.3, 0.3, 0.8))

	# Tay phai (cam co)
	draw_limb.call(shoulder, gun_start, col_shirt, 3.5)
	draw_rect(Rect2(gun_start.x - 1.5, gun_start.y - 1.5, 3, 3), col_skin)
	px.call(gun_start.x - 1, gun_start.y + 1, col_skin_d, 1.5)
	
	# Tay trai (do nong sung, ti len dau goi truoc)
	var shoulder_l = torso_top + Vector2(-2 * dir, 1)
	var handguard_pos = body_end + gun_dir * 2
	draw_limb.call(shoulder_l, handguard_pos, col_shirt.darkened(0.15), 3.5)
	draw_rect(Rect2(handguard_pos.x - 1.5, handguard_pos.y - 1.5, 3, 3), col_skin.darkened(0.15))
	# Bao tay (gloves)
	draw_rect(Rect2(handguard_pos.x - 1.5, handguard_pos.y - 1.5, 3, 3), col_belt.lightened(0.1))
