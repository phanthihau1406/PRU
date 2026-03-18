extends Node2D
class_name BaseLevel

## Base Level class
## Handles common level spawning, pausing, and victory conditions

@export var level_name: String = "LEVEL NAME"
@export var level_music: String = ""

var hud_scene = preload("res://scenes/ui/hud.tscn")
var player_scene = preload("res://scenes/objects/player.tscn")

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
	if GameManager.lives > 0:
		hud.show_message("ĐÃ HY SINH!\nCòn %d mạng" % GameManager.lives, 2.0)
		await get_tree().create_timer(2.0).timeout
		respawn_player()
	else:
		hud.show_message("GAME OVER", 3.0)

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
