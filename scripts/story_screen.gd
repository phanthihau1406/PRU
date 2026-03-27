extends Control

## Story Screen - Cutscene between levels

var story_data = {}
var next_action: Callable
var current_line = 0
var char_index = 0
var type_timer: float = 0.0
var type_speed: float = 0.05
var is_typing: bool = false
var selected_voice: String = ""
var tts_available: bool = false
var vietnamese_voice_available: bool = false
var online_tts_ready: bool = true
var narration_request_version: int = 0
var pending_tts_request: HTTPRequest = null
var narration_player: AudioStreamPlayer = null

@onready var title_label = $VBoxContainer/TitleLabel
@onready var text_label = $VBoxContainer/TextLabel
@onready var continue_label = $ContinueLabel
@onready var background_texture = $BackgroundTexture
@onready var background_overlay = $BackgroundOverlay

func _ready():
	_setup_narration_nodes()
	tts_available = DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH)
	if tts_available:
		selected_voice = _pick_narration_voice()
		vietnamese_voice_available = selected_voice != ""
		if not vietnamese_voice_available:
			print("[StoryScreen] Chua co voice tieng Viet tren he thong. Danh sach voice hien tai:", DisplayServer.tts_get_voices())
		else:
			print("[StoryScreen] Dang dung voice tieng Viet:", selected_voice)
	else:
		print("[StoryScreen] Thiet bi/OS khong ho tro TTS (DisplayServer.FEATURE_TEXT_TO_SPEECH=false)")

	if GameManager:
		var idx = GameManager.current_story_index
		story_data = GameManager.story_texts[idx]
		next_action = func(): GameManager.load_level(idx)
		_setup_story_background(idx)

	if story_data.is_empty():
		story_data = {
			"title": "TEST STORY",
			"lines": ["Line 1...", "Line 2..."]
		}
	
	title_label.text = story_data["title"]
	text_label.text = ""
	continue_label.visible = false
	if not _can_narrate_vietnamese():
		text_label.text = "[Can cai voice TTS tieng Viet trong Windows de doc thuyet minh.]\n"
	start_typing_next_line()

func _process(delta):
	# Always check input regardless of typing state
	if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("shoot"):
		if continue_label.visible:
			_stop_narration()
			if next_action.is_valid():
				next_action.call()
			return
		else:
			# Skip typing - show all text immediately
			_stop_narration()
			is_typing = false
			current_line = story_data["lines"].size()  # prevent pending coroutines from resuming
			var full_text = ""
			for line in story_data["lines"]:
				full_text += line + "\n"
			text_label.text = full_text
			continue_label.visible = true
			return

	if is_typing:
		type_timer += delta
		if type_timer >= type_speed:
			type_timer = 0
			char_index += 1
			
			var full_text = ""
			for i in range(current_line):
				full_text += story_data["lines"][i] + "\n"
			
			var current_str = story_data["lines"][current_line]
			if char_index <= current_str.length():
				full_text += current_str.substr(0, char_index)
				text_label.text = full_text
			else:
				is_typing = false
				current_line += 1
				
				if current_line < story_data["lines"].size():
					start_typing_next_line()
				else:
					continue_label.visible = true

func start_typing_next_line():
	# Small pause between lines
	await get_tree().create_timer(0.5).timeout
	# If user skipped while waiting, don't resume typing
	if current_line >= story_data["lines"].size():
		return

	# Avoid cutting previous line narration when moving to next line.
	while _is_narration_active() and current_line < story_data["lines"].size():
		await get_tree().create_timer(0.08).timeout
	if current_line >= story_data["lines"].size():
		return

	_narrate_line(story_data["lines"][current_line])
	char_index = 0
	is_typing = true

func _exit_tree():
	_stop_narration()

func _pick_narration_voice() -> String:
	var all_voices: Array[String] = []
	for v in DisplayServer.tts_get_voices():
		all_voices.append(str(v))

	var vi_candidates: Array = []
	var vi_lang_codes = ["vi-VN", "vi_VN", "vi-vn", "vi"]
	for lang in vi_lang_codes:
		for voice in DisplayServer.tts_get_voices_for_language(lang):
			var v = str(voice)
			if not vi_candidates.has(v):
				vi_candidates.append(v)

	# Some systems expose Vietnamese voices only in global list.
	for voice in all_voices:
		if _is_vietnamese_voice(voice) and not vi_candidates.has(voice):
			vi_candidates.append(voice)

	if GameManager and GameManager.narration_voice != "":
		var wanted = GameManager.narration_voice
		if vi_candidates.has(wanted):
			return wanted

	if vi_candidates.size() > 0:
		vi_candidates.sort_custom(func(a, b): return _voice_score(a) > _voice_score(b))
		return vi_candidates[0]

	return ""

func _voice_score(voice_id: String) -> int:
	var v = voice_id.to_lower()
	var score = 0
	if " vi" in (" " + v) or "vi-" in v or "_vi" in v or "vi_" in v:
		score += 50
	if "vietnam" in v:
		score += 40
	if "hoaimy" in v or "hoài" in v:
		score += 30
	if "natural" in v or "neural" in v:
		score += 20
	if "female" in v or "nu" in v:
		score += 8
	return score

func _is_vietnamese_voice(voice_id: String) -> bool:
	var v = voice_id.to_lower()
	return (" vi" in (" " + v)) or ("vi-" in v) or ("_vi" in v) or ("vi_" in v) or ("vietnam" in v) or ("hoaimy" in v) or ("hoài" in v)

func _setup_story_background(story_index: int):
	if not background_texture or not background_overlay:
		return

	var bg_info = {
		"path": "res://assets/sprites/background2.jpg",
		"tint": Color(0.85, 0.82, 0.74, 0.95)
	}
	if GameManager and GameManager.has_method("get_story_background"):
		bg_info = GameManager.get_story_background(story_index)

	var bg_path = str(bg_info.get("path", "res://assets/sprites/background2.jpg"))
	if ResourceLoader.exists(bg_path):
		background_texture.texture = load(bg_path)
	background_overlay.color = bg_info.get("tint", Color(0.85, 0.82, 0.74, 0.95))

func _narrate_line(line: String):
	if line.strip_edges() == "":
		return
	if GameManager and not GameManager.narration_enabled:
		return

	if _try_narrate_online_vi(line):
		return

	_play_system_tts(line, true)

func _stop_narration():
	narration_request_version += 1
	if pending_tts_request:
		pending_tts_request.cancel_request()
		pending_tts_request.queue_free()
		pending_tts_request = null
	if narration_player and narration_player.playing:
		narration_player.stop()
	if tts_available:
		DisplayServer.tts_stop()

func _is_narration_active() -> bool:
	if narration_player and narration_player.playing:
		return true
	if tts_available and DisplayServer.tts_is_speaking():
		return true
	return false

func _setup_narration_nodes():
	narration_player = AudioStreamPlayer.new()
	narration_player.name = "NarrationPlayer"
	narration_player.bus = "Master"
	add_child(narration_player)

func _can_narrate_vietnamese() -> bool:
	if GameManager and GameManager.online_vi_tts_enabled:
		return true
	return tts_available and vietnamese_voice_available

func _try_narrate_online_vi(line: String) -> bool:
	if not GameManager or not GameManager.online_vi_tts_enabled:
		return false
	if not online_tts_ready:
		return false

	narration_request_version += 1
	var version = narration_request_version
	_call_online_tts(version, line)
	return true

func _call_online_tts(version: int, line: String) -> void:
	_fetch_and_play_online_tts(version, line)

func _fetch_and_play_online_tts(version: int, line: String) -> void:
	var cache_path = "user://tts_vi_%s.mp3" % line.md5_text()
	if FileAccess.file_exists(cache_path):
		if version != narration_request_version:
			return
		if not _play_mp3_file(cache_path):
			_play_system_tts(line, true)
		return

	if pending_tts_request:
		pending_tts_request.cancel_request()
		pending_tts_request.queue_free()
		pending_tts_request = null

	pending_tts_request = HTTPRequest.new()
	pending_tts_request.timeout = 6.0
	add_child(pending_tts_request)

	var encoded_text = line.uri_encode()
	var url = "https://translate.google.com/translate_tts?ie=UTF-8&tl=vi&client=tw-ob&q=%s" % encoded_text
	var headers = ["User-Agent: Mozilla/5.0"]
	var err = pending_tts_request.request(url, headers, HTTPClient.METHOD_GET)
	if err != OK:
		online_tts_ready = false
		pending_tts_request.queue_free()
		pending_tts_request = null
		_play_system_tts(line, true)
		return

	var result = await pending_tts_request.request_completed
	if pending_tts_request:
		pending_tts_request.queue_free()
		pending_tts_request = null

	if version != narration_request_version:
		return

	var response_code = int(result[1])
	var body: PackedByteArray = result[3]
	if response_code != 200 or body.is_empty():
		online_tts_ready = false
		_play_system_tts(line, true)
		return

	var f = FileAccess.open(cache_path, FileAccess.WRITE)
	if f:
		f.store_buffer(body)
		f.close()

	if not _play_mp3_bytes(body):
		_play_system_tts(line, true)

func _play_mp3_file(path: String) -> bool:
	if not narration_player:
		return false
	var f = FileAccess.open(path, FileAccess.READ)
	if not f:
		return false
	var data = f.get_buffer(f.get_length())
	f.close()
	return _play_mp3_bytes(data)

func _play_mp3_bytes(data: PackedByteArray) -> bool:
	if not narration_player:
		return false
	var stream = AudioStreamMP3.new()
	stream.data = data
	stream.loop = false
	narration_player.stream = stream
	_apply_narration_volume_pitch()
	narration_player.play()
	return true

func _play_system_tts(line: String, allow_non_vi_fallback: bool = false) -> bool:
	if not tts_available:
		return false

	var voice_to_use = selected_voice
	if GameManager and GameManager.narration_voice != "":
		voice_to_use = GameManager.narration_voice

	if voice_to_use == "" and allow_non_vi_fallback:
		var voices = DisplayServer.tts_get_voices()
		if voices.size() > 0:
			voice_to_use = str(voices[0])

	if voice_to_use == "":
		return false

	var volume = 80
	var pitch = 1.0
	var rate = 1.0
	if GameManager:
		volume = int(round(clampf(GameManager.narration_volume, 0.0, 1.0) * 100.0))
		pitch = GameManager.narration_pitch
		rate = GameManager.narration_rate

	DisplayServer.tts_stop()
	DisplayServer.tts_speak(line, voice_to_use, volume, pitch, rate, 0, true)
	return true

func _apply_narration_volume_pitch():
	if not narration_player:
		return
	var volume_linear = 0.9
	var pitch = 1.0
	if GameManager:
		volume_linear = clampf(GameManager.narration_volume, 0.0, 1.0)
		pitch = clampf(GameManager.narration_pitch * GameManager.narration_rate, 0.6, 1.8)
	narration_player.volume_db = linear_to_db(maxf(volume_linear, 0.001))
	narration_player.pitch_scale = pitch

func _draw():
	draw_rect(Rect2(0, 0, 1280, 720), Color(0.04, 0.04, 0.04, 0.2))
	
	# Draw simple film strip effect
	for i in range(20):
		draw_rect(Rect2(10, i * 40 + 10, 20, 20), Color(1, 1, 1, 0.65))
		draw_rect(Rect2(1250, i * 40 + 10, 20, 20), Color(1, 1, 1, 0.65))
