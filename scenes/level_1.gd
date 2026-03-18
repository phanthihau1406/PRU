extends Node2D

## Level 1: Rừng Điện Biên
## Uses TileMap created in editor, player/enemy/airplane placed in editor

var hud_scene = preload("res://scenes/ui/hud.tscn")
var hud: CanvasLayer
var player: Node2D
var rest_area_triggered: bool = false

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
	_setup_level_bgm("res://assets/audio/game_background_music1.mp3", -10.0)

	# Find the player (placed in editor)
	player = _find_node_by_type("CharacterBody2D", "player")
	if not player:
		# Try to find by group after a frame
		await get_tree().process_frame
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]
	
	# Instance HUD
	hud = hud_scene.instantiate()
	add_child(hud)
	
	# Connect player signals
	if player:
		if player.has_signal("player_died"):
			player.player_died.connect(_on_player_died)
	
	# Show level name
	hud.show_message("RỪNG ĐIỆN BIÊN", 3.0)
	
	# Setup rest area at end of map
	_create_rest_area()
	
	# Configure enemies and airplanes patrol ranges
	_setup_enemies()

func _process(_delta):
	pass

func _find_node_by_type(type_name: String, group_name: String) -> Node:
	# Search through direct children and their children
	for child in get_children():
		if child.is_in_group(group_name):
			return child
		for grandchild in child.get_children():
			if grandchild.is_in_group(group_name):
				return grandchild
	return null

func _setup_enemies():
	# Configure airplane patrol ranges based on their positions
	for child in get_children():
		if child.has_method("take_damage") and child.is_in_group("enemies"):
			if child is Node2D and "patrol_min_x" in child:
				# It's an airplane - set patrol range around its position
				child.patrol_min_x = child.global_position.x - 300
				child.patrol_max_x = child.global_position.x + 300
				child.patrol_y = child.global_position.y

func _create_rest_area():
	# Find the rightmost extent of the tilemap to place rest area
	var tilemap = get_node_or_null("TileMap")
	var rest_x = 3800.0  # default
	
	if tilemap:
		var used_rect = tilemap.get_used_rect()
		var tile_size = tilemap.tile_set.tile_size if tilemap.tile_set else Vector2i(16, 16)
		rest_x = float(used_rect.end.x * tile_size.x) - 200.0
	
	# Create rest area trigger
	var rest_area = Area2D.new()
	rest_area.name = "RestArea"
	rest_area.global_position = Vector2(rest_x, 300)
	rest_area.collision_layer = 0
	rest_area.collision_mask = 1
	
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(100, 400)
	col.shape = shape
	rest_area.add_child(col)
	
	rest_area.body_entered.connect(_on_rest_area_entered)
	add_child(rest_area)
	
	# Create visual marker for rest area
	var label = Label.new()
	label.text = "🏕️ NGHỈ NGƠI"
	label.global_position = Vector2(rest_x - 60, 250)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.3))
	add_child(label)

func _on_rest_area_entered(body):
	if rest_area_triggered:
		return
	if body.is_in_group("player"):
		rest_area_triggered = true
		hud.show_message("🏕️ KHU VỰC NGHỈ NGƠI\nHoàn thành Rừng Điện Biên!", 3.0)
		await get_tree().create_timer(3.0).timeout
		_complete_level()

func _on_player_died():
	# Single life - show score and return to menu
	_show_game_over_screen()

func _show_game_over_screen():
	# Create a full-screen game over overlay
	var overlay = CanvasLayer.new()
	overlay.layer = 100
	add_child(overlay)
	
	var panel = ColorRect.new()
	panel.color = Color(0, 0, 0, 0.75)
	panel.anchors_preset = Control.PRESET_FULL_RECT
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.anchors_preset = Control.PRESET_CENTER
	vbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	vbox.grow_vertical = Control.GROW_DIRECTION_BOTH
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	overlay.add_child(vbox)
	
	var title = Label.new()
	title.text = "ĐÃ HY SINH!"
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(1, 0.3, 0.2))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)
	
	var level_label = Label.new()
	level_label.text = "Màn: RỪNG ĐIỆN BIÊN"
	level_label.add_theme_font_size_override("font_size", 20)
	level_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.3))
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(level_label)
	
	var score_label = Label.new()
	score_label.text = "Điểm: %d" % GameManager.score
	score_label.add_theme_font_size_override("font_size", 28)
	score_label.add_theme_color_override("font_color", Color(1, 1, 1))
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(score_label)
	
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 15)
	vbox.add_child(spacer2)
	
	var hint = Label.new()
	hint.text = "Quay về menu trong 4s..."
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hint)
	
	# Wait then go to menu
	await get_tree().create_timer(4.0).timeout
	GameManager.go_to_menu()

func _complete_level():
	hud.show_message("HOÀN THÀNH NHIỆM VỤ!", 3.0)
	await get_tree().create_timer(3.0).timeout
	GameManager.complete_level()
