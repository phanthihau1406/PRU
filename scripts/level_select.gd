extends Control

## Level Select Screen

func _ready():
	var btn_level_1 = $VBoxContainer/BtnLevel1
	var btn_level_2 = $VBoxContainer/BtnLevel2
	var btn_level_3 = $VBoxContainer/BtnLevel3
	var btn_back = $VBoxContainer/BtnBack

	btn_level_1.pressed.connect(func(): _start_level(0))
	btn_level_2.pressed.connect(func(): _start_level(1))
	btn_level_3.pressed.connect(func(): _start_level(2))
	btn_back.pressed.connect(_on_back_pressed)

	btn_level_1.grab_focus()

func _start_level(level_index: int):
	GameManager.score = 0
	GameManager.lives = 3
	GameManager.current_weapon = 0
	GameManager.load_level(level_index)

func _on_back_pressed():
	GameManager.go_to_menu()

func _draw():
	draw_rect(Rect2(0, 0, 1280, 720), Color(0.08, 0.12, 0.08))
	for i in range(16):
		var pos = Vector2(randf() * 1280, randf() * 720)
		draw_circle(pos, randf() * 2 + 1, Color(1, 1, 1, randf() * 0.4 + 0.1))
