extends CharacterBody2D

## Player - Chien si Giai phong
## Run-and-gun character with jumping, shooting in 8 directions

signal player_died
signal health_changed(new_health: int)
signal weapon_changed(weapon_name: String)

@export var speed: float = 320.0
@export var jump_force: float = -520.0
@export var gravity: float = 1050.0
@export var max_health: int = 10
@export var max_jumps: int = 2
@export var accel_ground: float = 3600.0
@export var decel_ground: float = 4200.0
@export var accel_air: float = 2600.0
@export var max_fall_speed: float = 1200.0
@export var coyote_time: float = 0.10
@export var jump_buffer_time: float = 0.10
@export var jump_cut_multiplier: float = 0.50
@export var fall_gravity_multiplier: float = 1.25
@export var roll_speed: float = 460.0
@export var roll_duration: float = 0.32

var health: int = 10
@export var topdown_mode: bool = false
var aim_direction: Vector2 = Vector2.RIGHT
var facing_right: bool = true
var is_shooting: bool = false
var shoot_timer: float = 0.0
var invincible: bool = false
var invincible_timer: float = 0.0
var shield_active: bool = false
var shield_timer: float = 0.0
var infinite_ammo_timer: float = 0.0
var speed_boost_timer: float = 0.0
var in_tank: bool = false
var flash_timer: float = 0.0
var is_dead: bool = false

# Animation
var anim_frame: int = 0
var anim_timer: float = 0.0
var leg_angle: float = 0.0
var was_on_floor: bool = false
var land_bounce: float = 0.0
var idle_time: float = 0.0
var is_crouching: bool = false
var jumps_left: int = 2
var ammo_in_mag: Dictionary = {}
var is_reloading: bool = false
var reload_timer: float = 0.0
var double_jump_pose_timer: float = 0.0
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var jump_just_started: bool = false
var is_rolling: bool = false
var roll_timer: float = 0.0
var roll_dir: float = 1.0
var flip_active: bool = false
var flip_angle: float = 0.0
var flip_rotations: float = 1.0
var step_timer: float = 0.0

var sfx_shoot: AudioStreamPlayer
var sfx_reload: AudioStreamPlayer
var sfx_death: AudioStreamPlayer
var sfx_steps: Array = []

# Bullet scene
var bullet_scene = preload("res://scenes/objects/bullet.tscn")

func _ready():
	GameManager.set_weapon(0)
	health = max_health
	jumps_left = max_jumps
	_init_magazines()
	z_index = 10
	add_to_group("player")
	weapon_changed.emit(GameManager.get_weapon_data().name)
	infinite_ammo_timer = 0.0
	_setup_audio()
	scale = Vector2(1.5, 1.5)
	
	if topdown_mode:
		set_collision_mask_value(1, false)


func _physics_process(delta):
	if is_dead:
		velocity = Vector2.ZERO
		return
	if in_tank:
		return
		
	# Update collision mask dynamically if topdown_mode is toggled
	if topdown_mode and get_collision_mask_value(1):
		set_collision_mask_value(1, false)
	
	# Gravity
	if not is_on_floor() and not topdown_mode:
		var g = gravity
		if velocity.y > 0.0:
			g *= fall_gravity_multiplier
		velocity.y += g * delta
		velocity.y = minf(velocity.y, max_fall_speed)
	
	# Movement
	var move_speed = speed
	var is_grounded = is_on_floor() or topdown_mode
	if is_grounded and absf(Input.get_axis("move_left", "move_right")) > 0.01:
		move_speed *= 1.08
	if speed_boost_timer > 0:
		move_speed *= 1.5
		speed_boost_timer -= delta
	
	var input_dir = Input.get_axis("move_left", "move_right")
	var input_y = Input.get_axis("move_up", "move_down") if topdown_mode else 0.0
	
	if is_rolling:
		roll_timer -= delta
		velocity.x = roll_dir * roll_speed
		if topdown_mode: velocity.y = 0
		if roll_timer <= 0.0:
			is_rolling = false
	else:
		var target_x = input_dir * move_speed
		if absf(input_dir) > 0.01:
			var accel = accel_ground if is_grounded else accel_air
			if absf(velocity.x) > 40.0 and signf(velocity.x) != signf(target_x):
				accel *= 1.6
			velocity.x = move_toward(velocity.x, target_x, accel * delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, decel_ground * delta)
			
		if topdown_mode:
			var target_y = input_y * move_speed
			if absf(input_y) > 0.01:
				velocity.y = move_toward(velocity.y, target_y, accel_ground * delta)
			else:
				velocity.y = move_toward(velocity.y, 0.0, decel_ground * delta)
	
	if input_dir > 0:
		facing_right = true
	elif input_dir < 0:
		facing_right = false

	# Footsteps
	if is_grounded and (absf(velocity.x) > 30.0 or (topdown_mode and absf(velocity.y) > 30.0)) and not is_rolling:
		step_timer -= delta
		if step_timer <= 0.0:
			_play_step()
			step_timer = 0.22
	else:
		step_timer = 0.0
	
	# Jump helpers
	jump_just_started = false
	if is_grounded:
		jumps_left = max_jumps
		double_jump_pose_timer = 0.0
		coyote_timer = coyote_time
		flip_active = false
		flip_angle = 0.0
	else:
		coyote_timer = maxf(0.0, coyote_timer - delta)

	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer = maxf(0.0, jump_buffer_timer - delta)

	# Contra-like roll: press down + jump on ground
	if is_grounded and Input.is_action_pressed("move_down") and Input.is_action_just_pressed("jump") and not topdown_mode:
		is_rolling = true
		roll_timer = roll_duration
		roll_dir = 1.0 if facing_right else -1.0
		jump_buffer_timer = 0.0
	elif topdown_mode and Input.is_action_just_pressed("jump"): # Simple dodge in topdown
		is_rolling = true
		roll_timer = roll_duration
		roll_dir = 1.0 if facing_right else -1.0
		jump_buffer_timer = 0.0

	var can_ground_jump = coyote_timer > 0.0 and jumps_left == max_jumps
	var can_air_jump = jumps_left > 0 and not can_ground_jump
	if jump_buffer_timer > 0.0 and (can_ground_jump or can_air_jump):
		var second_jump_boost = can_air_jump
		velocity.y = jump_force
		jumps_left -= 1
		coyote_timer = 0.0
		jump_buffer_timer = 0.0
		jump_just_started = true
		flip_active = true
		flip_angle = 0.0
		flip_rotations = 1.0
		if second_jump_boost:
			double_jump_pose_timer = 0.22

	# Variable jump height
	if Input.is_action_just_released("jump") and velocity.y < 0.0 and not jump_just_started:
		velocity.y *= jump_cut_multiplier

	# Aim direction (8 directions)
	var aim = Vector2.ZERO
	if Input.is_action_pressed("move_right"):
		aim.x = 1
	elif Input.is_action_pressed("move_left"):
		aim.x = -1
	if Input.is_action_pressed("move_up"):
		aim.y = -1
	elif Input.is_action_pressed("move_down"):
		aim.y = 1
	
	if aim != Vector2.ZERO:
		aim_direction = aim.normalized()
	else:
		aim_direction = Vector2.RIGHT if facing_right else Vector2.LEFT
	
	_handle_weapon_controls(delta)

	# Shooting
	shoot_timer -= delta
	if Input.is_action_pressed("shoot") and shoot_timer <= 0 and not is_reloading:
		shoot()
		var weapon = GameManager.get_weapon_data()
		shoot_timer = weapon.fire_rate
	
	# Invincibility timer
	if invincible:
		invincible_timer -= delta
		flash_timer += delta
		if invincible_timer <= 0:
			invincible = false
	
	# Shield timer
	if shield_active:
		shield_timer -= delta
		if shield_timer <= 0:
			shield_active = false
	
	# Infinite ammo timer
	if infinite_ammo_timer > 0:
		infinite_ammo_timer -= delta

	if double_jump_pose_timer > 0.0:
		double_jump_pose_timer -= delta
	if flip_active and not is_on_floor():
		flip_angle = minf(flip_angle + delta * TAU * 2.6, TAU * flip_rotations)
	
	# Animation
	if abs(velocity.x) > 10:
		anim_timer += delta * 12
		leg_angle = sin(anim_timer) * 38
	else:
		leg_angle = sin(anim_timer * 0.6) * 8
		anim_timer = 0

	# Landing squish
	var on_floor_now = is_grounded
	if on_floor_now and not was_on_floor:
		land_bounce = 0.35
	was_on_floor = on_floor_now
	if land_bounce > 0.0:
		land_bounce -= delta * 3.0

	# Crouch when pressing down on ground
	is_crouching = Input.is_action_pressed("move_down") and is_grounded and not is_rolling and not topdown_mode

	# Idle breath timer
	if abs(velocity.x) < 10 and (not topdown_mode or abs(velocity.y) < 10) and is_grounded:
		idle_time += delta
	else:
		idle_time = 0.0
	
	move_and_slide()
	queue_redraw()

func shoot():
	if not bullet_scene:
		return
	if not _can_fire_current_weapon():
		_start_reload()
		return

	var bullet = bullet_scene.instantiate()
	var weapon = GameManager.get_weapon_data()
	var spread_rad = deg_to_rad(weapon.spread)
	var dir = aim_direction.rotated(randf_range(-spread_rad, spread_rad))
	bullet.setup(global_position + aim_direction * 20, dir, weapon.speed, weapon.damage, weapon.color, true)
	get_tree().current_scene.add_child(bullet)
	_play_sfx(sfx_shoot)

	if infinite_ammo_timer <= 0.0:
		var widx = GameManager.current_weapon
		ammo_in_mag[widx] = maxi(0, int(ammo_in_mag.get(widx, int(weapon.mag_size))) - 1)

func take_damage(amount: int = 1):
	if invincible or shield_active:
		return
	health = max(health - max(1, amount), 0)
	health_changed.emit(health)
	invincible = true
	invincible_timer = 1.2
	flash_timer = 0
	if health <= 0:
		die()

func die():
	is_dead = true
	velocity = Vector2.ZERO
	is_rolling = false
	get_node("CollisionShape2D").set_deferred("disabled", true)
	_play_sfx(sfx_death)
	GameManager.lives -= 1
	player_died.emit()
	if GameManager.lives <= 0:
		await get_tree().create_timer(0.9).timeout
		GameManager.go_to_menu()

func heal(amount: int):
	health = min(health + amount, max_health)
	health_changed.emit(health)

func activate_shield(duration: float = 5.0):
	shield_active = true
	shield_timer = duration

func activate_speed_boost(duration: float = 5.0):
	speed_boost_timer = duration

func activate_infinite_ammo(duration: float = 5.0):
	infinite_ammo_timer = duration

func _init_magazines():
	ammo_in_mag.clear()
	for i in range(GameManager.weapons.size()):
		var w = GameManager.weapons[i]
		ammo_in_mag[i] = int(w.mag_size)

func _handle_weapon_controls(delta: float):
	if Input.is_action_just_pressed("reload"):
		_start_reload()

	if is_reloading:
		reload_timer -= delta
		if reload_timer <= 0.0:
			var widx = GameManager.current_weapon
			ammo_in_mag[widx] = int(GameManager.get_weapon_data().mag_size)
			is_reloading = false

func _can_fire_current_weapon() -> bool:
	if infinite_ammo_timer > 0.0:
		return true
	var widx = GameManager.current_weapon
	if not ammo_in_mag.has(widx):
		ammo_in_mag[widx] = int(GameManager.get_weapon_data().mag_size)
	return int(ammo_in_mag[widx]) > 0

func _start_reload():
	if infinite_ammo_timer > 0.0 or is_reloading:
		return
	var widx = GameManager.current_weapon
	var weapon = GameManager.get_weapon_data()
	if int(ammo_in_mag.get(widx, int(weapon.mag_size))) >= int(weapon.mag_size):
		return
	is_reloading = true
	reload_timer = float(weapon.reload_time)
	_play_sfx(sfx_reload)

func get_ammo_status_text() -> String:
	if infinite_ammo_timer > 0.0:
		return "INF"
	var widx = GameManager.current_weapon
	var weapon = GameManager.get_weapon_data()
	var curr = int(ammo_in_mag.get(widx, int(weapon.mag_size)))
	var postfix = " (Reloading)" if is_reloading else ""
	return "%d/%d%s" % [curr, int(weapon.mag_size), postfix]

func get_ammo_current() -> int:
	if infinite_ammo_timer > 0.0:
		return get_ammo_max()
	var widx = GameManager.current_weapon
	if not ammo_in_mag.has(widx):
		ammo_in_mag[widx] = int(GameManager.get_weapon_data().mag_size)
	return int(ammo_in_mag[widx])

func get_ammo_max() -> int:
	return int(GameManager.get_weapon_data().mag_size)

func is_weapon_reloading() -> bool:
	return is_reloading

func refill_current_magazine():
	var widx = GameManager.current_weapon
	ammo_in_mag[widx] = int(GameManager.get_weapon_data().mag_size)
	is_reloading = false
	reload_timer = 0.0

func _setup_audio():
	sfx_shoot = _create_sfx_player("res://assets/audio/ak47_fire.mp3", -26.0)
	sfx_reload = _create_sfx_player("res://assets/audio/reload_ak47.mp3", -6.0)
	sfx_death = _create_sfx_player("res://assets/audio/reload_ak47.mp3", -8.0)
	sfx_death.pitch_scale = 0.55
	sfx_steps = [
		_create_sfx_player("res://assets/audio/walk-on-grass-1.mp3", 0.0),
		_create_sfx_player("res://assets/audio/walk-on-grass-2.mp3", 0.0),
		_create_sfx_player("res://assets/audio/walk-on-grass-3.mp3", 0.0),
	]

func _create_sfx_player(path: String, volume_db: float) -> AudioStreamPlayer:
	var p = AudioStreamPlayer.new()
	p.stream = load(path)
	p.volume_db = volume_db
	add_child(p)
	return p

func _play_sfx(p: AudioStreamPlayer):
	if not p:
		return
	if p.playing:
		p.stop()
	p.play()

func _play_step():
	if sfx_steps.is_empty():
		return
	var idx = randi() % sfx_steps.size()
	_play_sfx(sfx_steps[idx])

func _draw():
	if invincible and fmod(flash_timer, 0.2) > 0.1:
		return

	# === BẢNG MÀU LÍNH CỤ HỒ VN - METAL SLUG STYLE ===
	var P = 3.0  # Pixel block size (3x3)
	var col_hat = Color("#2a5a22")       # Mũ tai bèo xanh lá đậm
	var col_hat_hi = Color("#3a7a32")    # Mũ highlight
	var col_hat_rim = Color("#1e4218")   # Vành mũ
	var col_star = Color("#f4d03f")      # Ngôi sao vàng
	var col_star_out = Color("#c4a020")  # Viền ngôi sao
	var col_skin = Color("#e5c198")      # Da vàng
	var col_skin_d = Color("#c8a070")    # Da tối (bóng)
	var col_skin_hi = Color("#f0d8b4")   # Da sáng (highlight)
	var col_eye = Color("#1a1208")       # Mắt đen
	var col_brow = Color("#2e1e10")      # Lông mày
	var col_mouth = Color("#b07850")     # Miệng
	var col_shirt = Color("#3a6e2e")     # Áo lính xanh rêu
	var col_shirt_hi = Color("#4a8e3e")  # Áo highlight
	var col_shirt_d = Color("#2a5220")   # Áo đổ bóng
	var col_camo1 = Color("#2e5826")     # Vằn camo 1
	var col_camo2 = Color("#4a7e3a")     # Vằn camo 2
	var col_pants = Color("#2a4a22")     # Quần xanh rêu đậm
	var col_pants_d = Color("#1e3818")   # Quần bóng
	var col_belt = Color("#3a2a18")      # Thắt lưng da nâu
	var col_belt_buckle = Color("#c8a830") # Khóa thắt lưng vàng
	var col_shoe = Color("#1a1a1a")      # Dép râu đen
	var col_shoe_strap = Color("#2a2a20")# Dây dép râu
	var col_gun_wood = Color("#6e4a2e")  # Gỗ súng AK
	var col_gun_wood_hi = Color("#8e6a4e") # Gỗ highlight
	var col_gun_metal = Color("#2a2a2a") # Kim loại súng AK
	var col_gun_hi = Color("#4a4a4a")    # Kim loại highlight
	var col_backpack = Color("#3e5a2e")  # Ba lô
	var col_bandolier = Color("#4a3a20") # Dây đạn chéo

	var dir = 1 if facing_right else -1
	var move_speed_ratio = (abs(velocity.x) + (abs(velocity.y) if topdown_mode else 0.0)) / max(speed, 1.0)
	var speed_ratio = clampf(move_speed_ratio, 0.0, 1.0)
	var idle_sway = sin(idle_time * 2.0) * 0.6
	var sway = sin(anim_timer * 1.4) * (1.6 * speed_ratio) + idle_sway * (1.0 - speed_ratio)
	var bob = sin(anim_timer * 1.2) * (1.4 * speed_ratio)
	
	var recoil = 0.0
	if shoot_timer > 0.0:
		recoil = 2.0
	var aim_pitch = clampf(aim_direction.y, -1.0, 1.0)

	# Squish / stretch
	var sx: float = 1.0
	var sy: float = 1.0
	var oy: float = 0.0
	if is_crouching:
		sy *= 0.75; sx *= 1.12; oy += 6.0
	if is_rolling:
		sy *= 0.62; sx *= 1.30; oy += 9.0
	if double_jump_pose_timer > 0.0:
		sy *= 1.12; sx *= 0.92; oy -= 1.0

	var rot = 0.0
	if flip_active:
		rot = flip_angle * dir

	draw_set_transform(Vector2(0.0, oy), rot, Vector2(sx, sy))

	var leg_rad = deg_to_rad(leg_angle)

	# Helper: vẽ pixel block
	var px = func(x: float, y: float, color: Color, size: float = P):
		draw_rect(Rect2(x, y, size, size), color)

	# Helper: vẽ limb
	var draw_limb = func(p1, p2, color, thickness):
		draw_line(p1, p2, color, thickness)

	# === CHÂN (Pixel Art Legs) ===
	var leg_scale = 0.6 if is_rolling else (0.85 if is_crouching else 1.0)
	var thigh = 7.0 * leg_scale
	var shin = 7.0 * leg_scale
	
	var hip_l = Vector2(-3 * dir, 5)
	var hip_r = Vector2( 2 * dir, 5)
	var knee_l = hip_l + Vector2(sin(leg_rad) * thigh * dir, 5)
	var knee_r = hip_r + Vector2(-sin(leg_rad) * thigh * dir, 5)
	var foot_l = knee_l + Vector2(sin(leg_rad) * shin * dir, 5)
	var foot_r = knee_r + Vector2(-sin(leg_rad) * shin * dir, 5)
	
	# Chân sau (darker)
	draw_limb.call(hip_l, knee_l, col_pants_d, 4.5)
	draw_limb.call(knee_l, foot_l, col_pants_d, 4.0)
	# Dép râu sau - dây chéo
	draw_rect(Rect2(foot_l.x - 2.5, foot_l.y, 6, 3), col_shoe)
	draw_line(Vector2(foot_l.x - 1, foot_l.y), Vector2(foot_l.x + 2, foot_l.y + 2), col_shoe_strap, 1.0)
	
	# Chân trước
	draw_limb.call(hip_r, knee_r, col_pants, 4.5)
	draw_limb.call(knee_r, foot_r, col_pants, 4.0)
	# Xà cạp cuốn (leg wrapping) - nét nhỏ quấn quanh ống chân
	draw_line(knee_r + Vector2(0, 2), knee_r + Vector2(2 * dir, 4), col_pants_d, 1.0)
	# Dép râu trước - dây chéo kiểu VN
	draw_rect(Rect2(foot_r.x - 2.5, foot_r.y, 6, 3), col_shoe)
	draw_line(Vector2(foot_r.x - 1, foot_r.y), Vector2(foot_r.x + 2, foot_r.y + 2), col_shoe_strap, 1.0)
	draw_line(Vector2(foot_r.x + 3, foot_r.y), Vector2(foot_r.x, foot_r.y + 2), col_shoe_strap, 1.0)

	# === THÂN TRÊN (Torso) - Metal Slug Style ===
	var torso_y = -10 + sway + aim_pitch * 2.0 + bob
	
	# Ba lô quân sự (sau lưng) - chi tiết hơn
	var bp_x = -9 * dir if dir == 1 else 3
	draw_rect(Rect2(bp_x, torso_y + 1, 6, 11), col_backpack)
	draw_rect(Rect2(bp_x, torso_y + 1, 6, 2), col_backpack.darkened(0.2)) # Nắp ba lô
	draw_rect(Rect2(bp_x + 1, torso_y + 4, 4, 1), col_belt) # Dây đai ba lô
	draw_rect(Rect2(bp_x + 1, torso_y + 8, 4, 1), col_belt) # Dây đai dưới
	# Bi đông nước treo hông
	draw_circle(Vector2(bp_x + 3, torso_y + 11), 2.5, col_backpack.darkened(0.3))
	
	# Thân chính - áo lính
	draw_rect(Rect2(-5, torso_y, 10, 14), col_shirt)
	# Highlight bên sáng
	draw_rect(Rect2(-5 if dir == 1 else 3, torso_y + 2, 2, 8), col_shirt_hi)
	# Bóng bên tối
	draw_rect(Rect2(3 if dir == 1 else -5, torso_y + 2, 2, 8), col_shirt_d)
	# Cổ áo V
	draw_rect(Rect2(-5, torso_y, 10, 3), col_shirt_d)
	px.call(-2, torso_y, col_shirt_hi, 4.0)  # Cổ áo V sáng giữa
	
	# Vằn camo trên áo (pixel blocks nhỏ)
	px.call(-3, torso_y + 4, col_camo1, 2.0)
	px.call(1, torso_y + 6, col_camo2, 2.0)
	px.call(-2, torso_y + 8, col_camo1, 2.0)
	px.call(2, torso_y + 3, col_camo2, 1.5)
	
	# Túi ngực trái
	draw_rect(Rect2(-4 * dir, torso_y + 4, 3, 3), col_shirt_d)
	draw_rect(Rect2(-4 * dir, torso_y + 4, 3, 1), col_belt.lightened(0.2)) # Nắp túi
	
	# Dây đạn chéo (bandolier)
	var band_start = Vector2(-4 * dir, torso_y + 1)
	var band_end = Vector2(4 * dir, torso_y + 11)
	draw_line(band_start, band_end, col_bandolier, 2.0)
	# Viên đạn nhỏ trên dây
	for i in range(4):
		var t = (i + 1) * 0.2
		var bp = band_start.lerp(band_end, t)
		px.call(bp.x, bp.y, col_gun_metal, 1.5)
	
	# Thắt lưng da nâu với khóa
	draw_rect(Rect2(-5, torso_y + 12, 10, 2), col_belt)
	px.call(-1, torso_y + 12, col_belt_buckle, 2.0) # Khóa thắt lưng vàng

	# === ĐẦU VÀ MŨ TAI BÈO - Chi tiết Metal Slug ===
	var head_y = -14 + sway + aim_pitch * 2.0 + bob
	
	# Cổ
	draw_rect(Rect2(-2, head_y + 4, 4, 3), col_skin_d)
	
	# Mặt chữ điền - pixel art chi tiết
	draw_rect(Rect2(-4, head_y - 4, 9, 9), col_skin)
	# Highlight má
	px.call(-3, head_y, col_skin_hi, 2.0)
	# Bóng cằm
	draw_rect(Rect2(-3, head_y + 3, 7, 1), col_skin_d)
	
	# Lông mày
	draw_rect(Rect2(0.5 * dir, head_y - 3, 3, 1), col_brow)
	# Mắt - 2 pixel block
	px.call(1 * dir, head_y - 1.5, col_eye, 2.0)
	# Đồng tử sáng (pixel nhỏ)
	px.call(1.5 * dir + 0.5, head_y - 1.0, Color(0.3, 0.25, 0.15), 0.8)
	# Miệng (đường ngang nhỏ)
	draw_rect(Rect2(0, head_y + 2, 2 * dir, 1), col_mouth)
	
	# Mũ tai bèo đặc trưng (Bucket hat) - chi tiết hơn
	# Đỉnh mũ - 2 tầng
	draw_rect(Rect2(-5, head_y - 9, 10, 5), col_hat)
	# Highlight đỉnh mũ
	draw_rect(Rect2(-3, head_y - 9, 6, 2), col_hat_hi)
	# Vành mũ rộng hai bên (tai bèo rủ xuống)
	draw_rect(Rect2(-7, head_y - 4, 14, 2), col_hat_rim)
	# Viền vành mũ
	draw_rect(Rect2(-6, head_y - 5, 12, 1), col_hat_rim.lightened(0.1))
	# Nếp gấp/nhăn trên mũ
	px.call(-2, head_y - 7, col_hat_rim.lightened(0.05), 1.5)
	px.call(3, head_y - 6, col_hat_rim.lightened(0.05), 1.5)
	
	# Ngôi sao vàng 5 cánh (pixel art) - to hơn, rõ hơn
	var sx_star = 0.0
	var sy_star = head_y - 7.5
	# Viền ngôi sao
	px.call(sx_star - 1.5, sy_star - 0.5, col_star_out, 4.5)
	# Thân ngôi sao
	px.call(sx_star - 1, sy_star, col_star, 3.5)
	# Tâm sáng
	px.call(sx_star - 0.5, sy_star + 0.5, col_star.lightened(0.3), 1.5)

	# === TAY VÀ SÚNG AK-47 - Chi tiết Metal Slug ===
	var arm_swing = sin(anim_timer * 1.6) * (3.0 * speed_ratio)
	var shoulder = Vector2(3 * dir, -5 + sway + aim_pitch * 3.0 + bob)
	var elbow = shoulder + Vector2(dir * (4 + arm_swing), 3 + aim_pitch * 2.0)
	
	# Súng AK-47 Pixel Art chi tiết
	var gun_dir = aim_direction.normalized()
	var gun_perp = Vector2(-gun_dir.y, gun_dir.x)  # Vuông góc
	var gun_start = elbow + Vector2(2 * dir, 0)
	
	# Báng súng gỗ (AK stock) - 2 lớp
	var stock_end = gun_start - gun_dir * 5
	draw_line(gun_start, stock_end, col_gun_wood, 3.5)
	draw_line(gun_start - gun_dir * 1, stock_end, col_gun_wood_hi, 1.5) # Highlight vân gỗ
	
	# Thân súng receiver
	var body_end = gun_start + gun_dir * 7
	draw_line(gun_start, body_end, col_gun_metal, 4.0)
	draw_line(gun_start + gun_perp * 1.2, body_end + gun_perp * 1.2, col_gun_hi, 1.0) # Edge highlight
	
	# Tay cầm (pistol grip)
	var grip_end = gun_start + Vector2(0, 4) + gun_dir * 2
	draw_line(gun_start + gun_dir * 2, grip_end, col_gun_metal, 2.5)
	
	# Ốp tay cầm gỗ (handguard)
	var handguard_start = body_end
	var handguard_end = handguard_start + gun_dir * 5
	draw_line(handguard_start, handguard_end, col_gun_wood, 3.5)
	draw_line(handguard_start + gun_perp * 0.8, handguard_end + gun_perp * 0.8, col_gun_wood_hi, 1.0)
	# Lỗ thoát hơi trên ốp gỗ
	px.call(handguard_start.x + gun_dir.x * 2, handguard_start.y + gun_dir.y * 2, col_gun_metal.lightened(0.1), 1.0)
	
	# Nòng súng dài
	var barrel_end = handguard_end + gun_dir * (9 + recoil)
	draw_line(handguard_end, barrel_end, col_gun_metal, 2.0)
	# Đầu bù lửa (muzzle brake)
	draw_line(barrel_end - gun_dir * 2, barrel_end, col_gun_metal, 2.8)
	
	# Băng đạn cong AK đặc trưng (iconic curved mag)
	var mag_dir = gun_dir.rotated(deg_to_rad(75 * dir))
	var mag_start = body_end + gun_dir * 1
	draw_line(mag_start, mag_start + mag_dir * 6, col_gun_metal, 3.0)
	draw_line(mag_start + gun_perp * 0.8, mag_start + mag_dir * 5 + gun_perp * 0.8, col_gun_hi, 1.0)
	
	# Đầu ngắm trước (front sight)
	draw_line(handguard_end + gun_dir * 1, handguard_end + gun_dir * 1 - gun_perp * 2, col_gun_metal, 1.5)

	# Muzzle flash - hiệu ứng đẹp hơn
	if shoot_timer > 0.05:
		var flash_pos = barrel_end + gun_dir * 2
		draw_circle(flash_pos, 5, Color(1, 0.9, 0.3, 0.6))
		draw_circle(flash_pos, 3, Color(1, 0.8, 0.2, 0.9))
		draw_circle(flash_pos + gun_dir * 2, 2, Color(1, 1, 0.5, 0.5))
		# Tia lửa nhỏ
		draw_line(flash_pos, flash_pos + gun_perp * 4, Color(1, 0.7, 0.1, 0.5), 1.0)
		draw_line(flash_pos, flash_pos - gun_perp * 4, Color(1, 0.7, 0.1, 0.5), 1.0)

	# Tay phải (cầm cò) - bàn tay pixel
	draw_limb.call(shoulder, elbow, col_shirt, 4.0)
	# Cơ bắp tay
	var mid_arm = shoulder.lerp(elbow, 0.5)
	draw_circle(mid_arm, 2.5, col_shirt_hi)
	# Bàn tay
	draw_rect(Rect2(elbow.x - 1.5, elbow.y - 1.5, 3.5, 3.5), col_skin)
	px.call(elbow.x - 1, elbow.y + 1, col_skin_d, 1.5) # Ngón tay
	
	# Tay trái (đỡ ốp gỗ bảo vệ)
	var free_swing = Vector2(-sin(leg_rad) * 0.9 * dir, 0.45).normalized() * (8.0 + speed_ratio * 3.0)
	var shoulder_l = Vector2(-4 * dir, -5 + sway)
	var elbow_l = shoulder_l + free_swing
	
	# Nếu đang đứng yên / bắn, tay trái đỡ súng
	if speed_ratio < 0.1 and shoot_timer > 0:
		elbow_l = handguard_start
	
	draw_limb.call(shoulder_l, elbow_l, col_shirt.darkened(0.15), 4.0)
	draw_rect(Rect2(elbow_l.x - 1.5, elbow_l.y - 1.5, 3.5, 3.5), col_skin.darkened(0.15))

	# === HIỆU ỨNG ĐẶC BIỆT ===
	
	# Shield effect - hào quang xanh
	if shield_active:
		var shield_pulse = sin(anim_timer * 6.0) * 0.1
		draw_arc(Vector2.ZERO, 26, 0, TAU, 32, Color(0.3, 0.5, 1.0, 0.30 + shield_pulse), 2.5)
		draw_arc(Vector2.ZERO, 24, 0, TAU, 32, Color(0.5, 0.7, 1.0, 0.18 + shield_pulse), 1.5)
		draw_arc(Vector2.ZERO, 22, 0, TAU, 32, Color(0.7, 0.9, 1.0, 0.10), 1.0)
	
	# Speed boost afterimage glow
	if speed_boost_timer > 0:
		draw_circle(Vector2(0, 0), 18, Color(0.2, 1.0, 0.3, 0.1))

	# Reset transform
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
