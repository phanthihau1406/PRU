extends CanvasLayer

## In-game HUD

@onready var hp_bar = $MarginContainer/HBoxContainer/VBoxContainer/HPBar
@onready var weapon_label = $MarginContainer/HBoxContainer/VBoxContainer/WeaponLabel
@onready var ammo_label = $MarginContainer/HBoxContainer/VBoxContainer/AmmoLabel
@onready var ammo_bar = $MarginContainer/HBoxContainer/VBoxContainer/AmmoBar
@onready var score_label = $MarginContainer/HBoxContainer/ScoreLabel
@onready var lives_label = $MarginContainer/HBoxContainer/LivesLabel
@onready var pause_menu = $PauseMenu
@onready var pause_volume_slider = $PauseMenu/Panel/VBox/VolumeSlider
@onready var pause_btn_resume = $PauseMenu/Panel/VBox/BtnResume
@onready var pause_btn_quit = $PauseMenu/Panel/VBox/BtnQuit

var player: Node2D
var hud_tick: float = 0.0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	_bind_player_if_needed()
	hp_bar.max_value = 10
	_pause_setup()
	update_hud()

func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		_toggle_pause()
		return
	_bind_player_if_needed()
	hud_tick += delta
	if hud_tick >= 0.15:
		hud_tick = 0.0
		update_hud()

func _pause_setup():
	if pause_menu:
		pause_menu.visible = false
		pause_btn_resume.pressed.connect(_on_resume_pressed)
		pause_btn_quit.pressed.connect(_on_quit_pressed)
		pause_volume_slider.value_changed.connect(_on_pause_volume_changed)
		var bus_index = _get_master_bus_index()
		var current_db = AudioServer.get_bus_volume_db(bus_index)
		pause_volume_slider.value = _db_to_linear(current_db)

func _toggle_pause():
	if not pause_menu:
		return
	var new_state = not get_tree().paused
	get_tree().paused = new_state
	pause_menu.visible = new_state
	if new_state:
		pause_btn_resume.grab_focus()

func _on_resume_pressed():
	if pause_menu:
		pause_menu.visible = false
	get_tree().paused = false

func _on_quit_pressed():
	get_tree().quit()

func _on_pause_volume_changed(value: float):
	var bus_index = _get_master_bus_index()
	AudioServer.set_bus_volume_db(bus_index, _linear_to_db(value))

func _get_master_bus_index() -> int:
	var bus_index = AudioServer.get_bus_index("Master")
	return 0 if bus_index < 0 else bus_index

func _linear_to_db(value: float) -> float:
	return linear_to_db(max(value, 0.001))

func _db_to_linear(value: float) -> float:
	return db_to_linear(value)

func _bind_player_if_needed():
	if player and is_instance_valid(player):
		return
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	player = players[0]
	hp_bar.max_value = player.max_health if "max_health" in player else 10
	if player.has_signal("health_changed") and not player.health_changed.is_connected(_on_health_changed):
		player.health_changed.connect(_on_health_changed)
	if player.has_signal("weapon_changed") and not player.weapon_changed.is_connected(_on_weapon_changed):
		player.weapon_changed.connect(_on_weapon_changed)
	if "health" in player:
		_on_health_changed(player.health)

func update_hud():
	if GameManager:
		var w_data = GameManager.get_weapon_data()
		weapon_label.text = "Vũ khí: " + w_data.name + " | Q/E đổi súng, R thay đạn"
		weapon_label.add_theme_color_override("font_color", w_data.color)

		if player and player.has_method("get_ammo_current") and player.has_method("get_ammo_max"):
			var ammo_curr = player.get_ammo_current()
			var ammo_max = maxi(1, player.get_ammo_max())
			ammo_bar.max_value = ammo_max
			ammo_bar.value = ammo_curr
			var reloading = player.has_method("is_weapon_reloading") and player.is_weapon_reloading()
			ammo_label.text = "Đạn: %d/%d%s" % [ammo_curr, ammo_max, " (Đang thay)" if reloading else ""]
		else:
			ammo_label.text = "Đạn"

		if player and "health" in player:
			hp_bar.value = player.health
		
		score_label.text = "Điểm: %06d" % GameManager.score
		lives_label.text = "Mạng: %d" % GameManager.lives

func _on_health_changed(new_health: int):
	hp_bar.value = new_health
	if new_health <= 3:
		hp_bar.add_theme_color_override("fill", Color(0.8, 0.1, 0.1))
	else:
		hp_bar.add_theme_color_override("fill", Color(0.2, 0.8, 0.2))

func _on_weapon_changed(_weapon_name: String):
	update_hud()

func show_message(text: String, duration: float = 3.0):
	$MessageLabel.text = text
	$MessageLabel.visible = true
	var timer = get_tree().create_timer(duration)
	timer.timeout.connect(func(): $MessageLabel.visible = false)
