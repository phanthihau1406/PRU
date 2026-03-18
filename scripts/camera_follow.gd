extends Camera2D

var target: Node2D

func _ready():
	# Zoom in closer to focus on the player
	zoom = Vector2(1.5, 1.5)

func _process(delta: float) -> void:
	if not target or not is_instance_valid(target):
		_find_target()
		return

	# Follow player in both X and Y
	global_position.x = lerp(global_position.x, target.global_position.x, 5.0 * delta)
	global_position.y = lerp(global_position.y, target.global_position.y - 80.0, 4.0 * delta)

	# If tracking player but player is inside a tank, switch to tank
	if target.get("in_tank") == true:
		_find_target()
	# If tracking a tank but tank has no driver, switch back to player
	elif target.is_in_group("tank") and target.get("driver") == null:
		_find_target()

func _find_target() -> void:
	# Prefer occupied tank
	var tanks = get_tree().get_nodes_in_group("tank")
	if tanks.size() > 0 and tanks[0].get("driver") != null:
		target = tanks[0]
		return
	# Fallback to player
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target = players[0]
