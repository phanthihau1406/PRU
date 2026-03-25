extends Control

## Main Menu Screen

var _saved_volume: float = 0.7
var bg_texture: Texture2D = null

func _ready():
	# Load background image
	bg_texture = load("res://assets/sprites/menu_background.png")
	
	# Configure buttons
	var btn_start = $VBoxContainer/BtnStart
	var btn_level_select = $VBoxContainer/BtnLevelSelect
	var btn_settings = $VBoxContainer/BtnSettings
	var btn_quit = $VBoxContainer/BtnQuit
	
	btn_start.pressed.connect(_on_btn_start_pressed)
	btn_level_select.pressed.connect(_on_btn_level_select_pressed)
	btn_settings.pressed.connect(_on_btn_settings_pressed)
	btn_quit.pressed.connect(_on_btn_quit_pressed)

	_add_settings_popup()
	btn_start.grab_focus()

func _on_btn_start_pressed():
	GameManager.start_game()

func _on_btn_quit_pressed():
	get_tree().quit()

func _on_btn_level_select_pressed():
	get_tree().change_scene_to_file("res://scenes/level_select.tscn")

func _on_btn_settings_pressed():
	var popup = get_node_or_null("SettingsPopup")
	if popup:
		popup.visible = true

func _on_volume_changed(value: float):
	var bus_index = _get_master_bus_index()
	AudioServer.set_bus_volume_db(bus_index, _linear_to_db(value))
	if value > 0.001:
		_saved_volume = value

func _linear_to_db(value: float) -> float:
	return linear_to_db(max(value, 0.001))

func _db_to_linear(value: float) -> float:
	return db_to_linear(value)

func _get_master_bus_index() -> int:
	var bus_index = AudioServer.get_bus_index("Master")
	return 0 if bus_index < 0 else bus_index

func _add_settings_popup():
	if get_node_or_null("SettingsPopup") != null:
		return
	
	var popup = Control.new()
	popup.name = "SettingsPopup"
	popup.visible = false
	popup.anchors_preset = Control.PRESET_FULL_RECT
	popup.anchor_right = 1.0
	popup.anchor_bottom = 1.0
	add_child(popup)
	
	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.anchors_preset = Control.PRESET_FULL_RECT
	dim.anchor_right = 1.0
	dim.anchor_bottom = 1.0
	popup.add_child(dim)
	
	var panel = Panel.new()
	panel.size = Vector2(520, 320)
	panel.position = (get_viewport_rect().size - panel.size) * 0.5
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.16, 0.10, 0.95)
	style.border_color = Color(0.85, 0.7, 0.2)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)
	popup.add_child(panel)
	
	var title = Label.new()
	title.text = "CAI DAT"
	title.position = Vector2(20, 16)
	title.size = Vector2(480, 36)
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.85, 0.7, 0.2))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(title)
	
	var sep = ColorRect.new()
	sep.position = Vector2(40, 60)
	sep.size = Vector2(440, 2)
	sep.color = Color(0.85, 0.7, 0.2, 0.5)
	panel.add_child(sep)
	
	var vol_row = HBoxContainer.new()
	vol_row.position = Vector2(40, 90)
	vol_row.size = Vector2(440, 40)
	vol_row.add_theme_constant_override("separation", 12)
	panel.add_child(vol_row)
	
	var vol_lbl = Label.new()
	vol_lbl.text = "AM LUONG"
	vol_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	vol_lbl.add_theme_font_size_override("font_size", 18)
	vol_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vol_row.add_child(vol_lbl)
	
	var vol_slider = HSlider.new()
	vol_slider.name = "VolumeSlider"
	vol_slider.custom_minimum_size = Vector2(180, 28)
	vol_slider.min_value = 0.0
	vol_slider.max_value = 1.0
	vol_slider.step = 0.01
	vol_row.add_child(vol_slider)
	
	var mute_btn = Button.new()
	mute_btn.name = "MuteButton"
	mute_btn.custom_minimum_size = Vector2(70, 30)
	mute_btn.text = "MUTE"
	vol_row.add_child(mute_btn)
	
	var god_row = HBoxContainer.new()
	god_row.position = Vector2(40, 140)
	god_row.size = Vector2(440, 40)
	god_row.add_theme_constant_override("separation", 12)
	panel.add_child(god_row)
	
	var god_lbl = Label.new()
	god_lbl.text = "GOD MODE (BAT TU)"
	god_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	god_lbl.add_theme_font_size_override("font_size", 18)
	god_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	god_row.add_child(god_lbl)
	
	var god_check = CheckBox.new()
	god_check.button_pressed = GameManager.god_mode
	god_check.toggled.connect(func(val: bool):
		GameManager.god_mode = val
	)
	god_row.add_child(god_check)
	
	var bus_index = _get_master_bus_index()
	var current_db = AudioServer.get_bus_volume_db(bus_index)
	vol_slider.value = _db_to_linear(current_db)
	_saved_volume = max(vol_slider.value, 0.01)

	vol_slider.value_changed.connect(func(value: float):
		_on_volume_changed(value)
		mute_btn.text = "MUTE" if value > 0.001 else "UNMUTE"
	)

	mute_btn.pressed.connect(func():
		var is_muted = vol_slider.value <= 0.001
		if is_muted:
			vol_slider.value = max(_saved_volume, 0.01)
		else:
			vol_slider.value = 0.0
	)
	
	var quit_btn = Button.new()
	quit_btn.text = "THOAT"
	quit_btn.size = Vector2(140, 40)
	quit_btn.position = Vector2(300, 240)
	quit_btn.pressed.connect(_on_btn_quit_pressed)
	panel.add_child(quit_btn)
	
	var close_btn = Button.new()
	close_btn.text = "DONG"
	close_btn.size = Vector2(140, 40)
	close_btn.position = Vector2(80, 240)
	close_btn.pressed.connect(func(): popup.visible = false)
	panel.add_child(close_btn)

func _draw():
	var vp_size = get_viewport_rect().size
	
	# Ve anh nen background
	if bg_texture:
		var tex_size = bg_texture.get_size()
		# Scale anh vua man hinh (cover mode)
		var scale_x = vp_size.x / tex_size.x
		var scale_y = vp_size.y / tex_size.y
		var s = maxf(scale_x, scale_y)
		var draw_size = tex_size * s
		var offset = (vp_size - draw_size) * 0.5
		draw_texture_rect(bg_texture, Rect2(offset, draw_size), false)
	else:
		# Fallback: nen toi
		draw_rect(Rect2(0, 0, vp_size.x, vp_size.y), Color(0.1, 0.15, 0.1))
	
	# Overlay toi nhe de text doc ro hon
	draw_rect(Rect2(0, 0, vp_size.x, vp_size.y), Color(0, 0, 0, 0.25))

func draw_star(center: Vector2, radius: float, color: Color):
	var points = PackedVector2Array()
	for i in range(10):
		var r = radius if i % 2 == 0 else radius * 0.4
		var a = deg_to_rad(i * 36 - 90)
		points.append(center + Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(points, color)
