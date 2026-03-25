extends Area2D

var triggered = false

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if triggered:
		return
	if body.is_in_group("player") or body.is_in_group("allies") or body.is_in_group("tank"):
		triggered = true
		_trigger_victory()

func _trigger_victory():
	get_tree().paused = true
	
	# Create overlay CanvasLayer FIRST so tweens can be bound to it
	var overlay = CanvasLayer.new()
	overlay.layer = 100
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().current_scene.add_child(overlay)
	
	# Stop all background music fading out
	for node in get_tree().current_scene.get_children():
		if node is AudioStreamPlayer and node.playing:
			var tw_audio = overlay.create_tween()
			tw_audio.tween_property(node, "volume_db", -80.0, 1.0)
			tw_audio.tween_callback(node.stop)
			
	# Play victory music "khải hoàn"
	var audio = AudioStreamPlayer.new()
	audio.stream = load("res://assets/audio/nhacchienthang.mp3")
	audio.volume_db = -2.0
	audio.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().current_scene.add_child(audio)
	audio.play()
	
	var control = Control.new()
	overlay.add_child(control)
	var vp_size = get_viewport_rect().size
	control.size = vp_size
	
	# Fade from entirely transparent to red/black curtain
	var panel = ColorRect.new()
	panel.color = Color(0.2, 0.05, 0.05, 0.0) 
	panel.size = vp_size
	control.add_child(panel)
	
	var center = CenterContainer.new()
	center.size = vp_size
	control.add_child(center)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 30)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(vbox)
	
	var title = Label.new()
	title.text = "CHIẾN DỊCH TOÀN THẮNG!"
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2)) # Gold/Yellow star color
	title.add_theme_color_override("font_shadow_color", Color.BLACK)
	title.add_theme_constant_override("shadow_offset_x", 4)
	title.add_theme_constant_override("shadow_offset_y", 4)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate.a = 0.0
	vbox.add_child(title)
	
	var sub = Label.new()
	sub.text = "Giải Phóng Miền Nam - Thống Nhất Đất Nước"
	sub.add_theme_font_size_override("font_size", 32)
	sub.add_theme_color_override("font_color", Color.WHITE)
	sub.add_theme_color_override("font_shadow_color", Color.BLACK)
	sub.add_theme_constant_override("shadow_offset_x", 2)
	sub.add_theme_constant_override("shadow_offset_y", 2)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.modulate.a = 0.0
	vbox.add_child(sub)
	
	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 40)
	btn_hbox.modulate.a = 0.0
	vbox.add_child(btn_hbox)
	
	var btn_menu = Button.new()
	btn_menu.text = " MÀN HÌNH CHÍNH "
	btn_menu.add_theme_font_size_override("font_size", 32)
	btn_menu.pressed.connect(func(): 
		get_tree().paused = false
		GameManager.go_to_menu()
	)
	btn_hbox.add_child(btn_menu)
	
	# Intro animations
	var tw = overlay.create_tween()
	tw.set_parallel(true)
	tw.tween_property(panel, "color:a", 0.9, 2.0)
	tw.tween_property(title, "modulate:a", 1.0, 2.0).set_delay(1.5)
	tw.tween_property(sub, "modulate:a", 1.0, 2.0).set_delay(3.5)
	tw.tween_property(btn_hbox, "modulate:a", 1.0, 1.0).set_delay(6.0)
