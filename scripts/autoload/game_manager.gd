extends Node

## Game Manager - Autoload Singleton
## Quản lý game state, level transitions, story data

# Game State
enum GameState { MENU, STORY, PLAYING, PAUSED, VICTORY }
var current_state: GameState = GameState.MENU
var current_level: int = 0
var score: int = 0
var lives: int = 3
var current_weapon: int = 0  # 0=rifle, 1=rocket
var narration_enabled: bool = true
var online_vi_tts_enabled: bool = true
var narration_voice: String = ""
var narration_volume: float = 0.9
var narration_rate: float = 1.22
var narration_pitch: float = 0.98

# Weapon data
var weapons = [
	{"name": "Súng trường", "fire_rate": 0.14, "damage": 1, "color": Color(1, 1, 0.3), "speed": 720, "spread": 0.3, "mag_size": 45, "reload_time": 1.3},
	{"name": "Tên lửa", "fire_rate": 0.35, "damage": 4, "color": Color(1, 0.2, 0.2), "speed": 560, "spread": 0, "mag_size": 45, "reload_time": 1.8},
]

# Story texts for cutscenes between levels
var story_texts = {
	0: {
		"title": "BỐI CẢNH LỊCH SỬ",
		"lines": [
			"Từ năm 1955–1975, Việt Nam bị chia thành hai miền sau Hiệp định Genève 1954.",
			"Miền Bắc: Việt Nam Dân chủ Cộng hòa.",
			"Miền Nam: Việt Nam Cộng hòa, được Mỹ và đồng minh hỗ trợ.",
			"Sau khi Hiệp định Paris 1973 được ký, quân Mỹ rút khỏi Việt Nam.",
			"Tuy nhiên chiến sự giữa hai bên vẫn tiếp tục...",
			"",
			"Bạn nhập vai một Chiến sĩ Giải phóng,",
			"hành trình bắt đầu từ miền Bắc tiến về phía Nam..."
		]
	},
	1: {
		"title": "CHIẾN DỊCH HỒ CHÍ MINH",
		"lines": [
			"Cuối tháng 4/1975, quân đội miền Bắc và lực lượng giải phóng",
			"mở cuộc tổng tấn công vào Sài Gòn.",
			"",
			"Các mũi quân tiến vào từ nhiều hướng:",
			"  → Tây Bắc    → Đông    → Đông Nam",
			"  → Tây Nam    → Bắc",
			"",
			"Mục tiêu: chiếm các cơ quan đầu não của chính quyền Sài Gòn."
		]
	},
	2: {
		"title": "TIẾN VÀO SÀI GÒN - 30/4/1975",
		"lines": [
			"Sáng ngày 30/4/1975...",
			"Xe tăng của quân giải phóng ào ạt tiến vào Sài Gòn.",
			"",
			"Phá hủy mọi chốt chặn trên đường,",
			"vượt cầu, tiến thẳng đến Dinh Độc Lập.",
			"",
			"Đích đến cuối cùng: Dinh Độc Lập!"
		]
	},
	3: {
		"title": "DINH ĐỘC LẬP - KHOẢNH KHẮC LỊCH SỬ",
		"lines": [
			"Khoảng 10:45 sáng ngày 30/4/1975,",
			"xe tăng của quân giải phóng húc đổ cổng Dinh Độc Lập.",
			"",
			"Bên trong, Tổng thống Dương Văn Minh",
			"đang chờ để tuyên bố đầu hàng vô điều kiện.",
			"",
			"Đây là trận chiến cuối cùng..."
		]
	},
	4: {
		"title": "THỐNG NHẤT ĐẤT NƯỚC",
		"lines": [
			"Lá cờ giải phóng được kéo lên tại Dinh Độc Lập.",
			"Chiến tranh kết thúc. Đất nước thống nhất.",
			"",
			"Năm 1976, Việt Nam chính thức thống nhất thành",
			"Cộng hòa Xã hội Chủ nghĩa Việt Nam.",
			"",
			"Sài Gòn được đổi tên thành Thành phố Hồ Chí Minh.",
			"Ngày 30/4 trở thành Ngày Giải phóng miền Nam."
		]
	}
}

# Story backgrounds (reusing available assets with different color moods)
var story_backgrounds = {
	0: {"path": "res://assets/sprites/historical_tank.png", "tint": Color(0.1, 0.1, 0.1, 0.6)},
	1: {"path": "res://assets/sprites/menu_background.png", "tint": Color(0.55, 0.38, 0.28, 0.36)},
	2: {"path": "res://assets/sprites/background2.jpg", "tint": Color(0.56, 0.42, 0.30, 0.36)},
	3: {"path": "res://assets/sprites/menu_background.png", "tint": Color(0.38, 0.42, 0.50, 0.34)},
	4: {"path": "res://assets/sprites/menu_background.png", "tint": Color(0.36, 0.52, 0.38, 0.32)},
}

# Level scene paths
var level_scenes = [
	"res://scenes/level_1.tscn",
	"res://scenes/level_2.tscn",
	"res://scenes/level_3.tscn",
	"res://scenes/level_4.tscn",
	"res://scenes/level_5.tscn",
]

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func start_game():
	score = 0
	lives = 3
	current_weapon = 0 # always start with rifle
	current_level = 0
	show_story(0)

var current_story_index: int = 0

func show_story(story_index: int):
	current_state = GameState.STORY
	current_story_index = story_index
	get_tree().change_scene_to_file("res://scenes/story_screen.tscn")

func load_level(level_index: int):
	current_level = level_index
	current_state = GameState.PLAYING
	if level_index >= level_scenes.size():
		show_victory()
		return
	get_tree().change_scene_to_file(level_scenes[level_index])

func complete_level():
	var next = current_level + 1
	if next >= level_scenes.size():
		show_story(4)  # Final story before victory
	else:
		show_story(next)

func show_victory():
	current_state = GameState.VICTORY
	get_tree().change_scene_to_file("res://scenes/victory_screen.tscn")

func go_to_menu():
	current_state = GameState.MENU
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func get_weapon_data() -> Dictionary:
	return weapons[current_weapon]

func set_weapon(index: int):
	current_weapon = clampi(index, 0, weapons.size() - 1)

func next_weapon():
	current_weapon = (current_weapon + 1) % weapons.size()

func prev_weapon():
	current_weapon = (current_weapon - 1 + weapons.size()) % weapons.size()

func upgrade_weapon():
	if current_weapon < weapons.size() - 1:
		current_weapon += 1

func add_score(points: int):
	score += points

func set_narration_volume(value: float):
	narration_volume = clampf(value, 0.0, 1.0)

func set_narration_rate(value: float):
	narration_rate = clampf(value, 0.6, 2.0)

func set_narration_pitch(value: float):
	narration_pitch = clampf(value, 0.7, 1.4)

func set_narration_enabled(value: bool):
	narration_enabled = value

func set_narration_voice(voice_id: String):
	narration_voice = voice_id

func get_story_background(story_index: int) -> Dictionary:
	if story_backgrounds.has(story_index):
		return story_backgrounds[story_index]
	return story_backgrounds[0]
