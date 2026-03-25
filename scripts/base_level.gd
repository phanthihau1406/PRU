extends Node2D
class_name BaseLevel

## Base Level class
## Handles common level spawning, pausing, and victory conditions

@export var level_name: String = "LEVEL NAME"
@export var level_music: String = ""

var hud_scene = preload("res://scenes/ui/hud.tscn")
var player_scene = preload("res://scenes/Player/PLayer.tscn")

var player: Node2D
var hud: CanvasLayer

func _setup_level_bgm(path: String = "res://assets/audio/game_background_music1.mp3", volume_db: float = -10.0):
	var bgm = get_node_or_null("BGM")
	if bgm == null:
		bgm = AudioStreamPlayer.new()
		bgm.name = "BGM"
		add_child(bgm)

	var loaded_stream = load(path)
	if loaded_stream:
		if loaded_stream is AudioStreamMP3:
			(loaded_stream as AudioStreamMP3).loop = true
		elif loaded_stream is AudioStreamOggVorbis:
			(loaded_stream as AudioStreamOggVorbis).loop = true
		elif loaded_stream is AudioStreamWAV:
			(loaded_stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
		bgm.stream = loaded_stream

	bgm.volume_db = volume_db
	if not bgm.playing:
		bgm.play()

func _ready():
	# Instance HUD
	hud = hud_scene.instantiate()
	add_child(hud)
	
	# Spawn player at start marker if it exists, else at 100, 500
	var start_pos = Vector2(100, 500)
	var start_marker = get_node_or_null("PlayerStart")
	if start_marker:
		start_pos = start_marker.global_position
		
	player = player_scene.instantiate()
	player.global_position = start_pos
	add_child(player)
	
	player.player_died.connect(_on_player_died)
	
	setup_level()
	
	hud.show_message(level_name, 3.0)

## Dành cho các level con override để setup boss, enemy...
func setup_level():
	pass

func _on_player_died():
	get_tree().paused = true
	
	var overlay = CanvasLayer.new()
	overlay.layer = 100
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().current_scene.add_child(overlay)
	
	var control = Control.new()
	overlay.add_child(control)
	var vp_size = get_viewport_rect().size
	control.size = vp_size
	
	var panel = ColorRect.new()
	panel.color = Color(0.2, 0.0, 0.0, 0.85) # Dark red overlay
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
	title.text = "ĐỒNG CHÍ ĐÃ CỐ GẮNG"
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(1.0, 0.3, 0.2))
	title.add_theme_color_override("font_shadow_color", Color.BLACK)
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 40)
	vbox.add_child(btn_hbox)
	
	var btn_retry = Button.new()
	btn_retry.text = " CHƠI LẠI "
	btn_retry.add_theme_font_size_override("font_size", 28)
	btn_retry.pressed.connect(func(): 
		get_tree().paused = false
		get_tree().reload_current_scene()
	)
	btn_hbox.add_child(btn_retry)
	
	var btn_menu = Button.new()
	btn_menu.text = " MÀN HÌNH CHÍNH "
	btn_menu.add_theme_font_size_override("font_size", 28)
	btn_menu.pressed.connect(func(): 
		get_tree().paused = false
		GameManager.go_to_menu()
	)
	btn_hbox.add_child(btn_menu)

func respawn_player():
	var start_pos = Vector2(100, 500)
	var start_marker = get_node_or_null("PlayerStart")
	if start_marker:
		start_pos = start_marker.global_position

	player.global_position = start_pos
	player.velocity = Vector2.ZERO
	player.in_tank = false
	player.visible = true
	player.is_dead = false
	player.health = player.max_health
	player.invincible = true
	player.invincible_timer = 3.0
	player.get_node("CollisionShape2D").set_deferred("disabled", false)
	hud.update_hud()

func complete_level():
	hud.show_message("HOÀN THÀNH NHIỆM VỤ!", 3.0)
	await get_tree().create_timer(3.0).timeout
	GameManager.complete_level()
