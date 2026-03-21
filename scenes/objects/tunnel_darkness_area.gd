extends Area2D

@export var darken_color: Color = Color(0.2, 0.2, 0.3, 1.0)
@export var transition_time: float = 1.0

var canvas_modulate: CanvasModulate
var tween: Tween

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	call_deferred("_setup_canvas_modulate")

func _setup_canvas_modulate():
	canvas_modulate = get_tree().current_scene.get_node_or_null("CanvasModulate")
	if not canvas_modulate:
		canvas_modulate = CanvasModulate.new()
		canvas_modulate.name = "CanvasModulate"
		canvas_modulate.color = Color.WHITE
		get_tree().current_scene.add_child(canvas_modulate)

func _on_body_entered(body):
	if body.is_in_group("player") and canvas_modulate:
		if tween: tween.kill()
		tween = create_tween()
		tween.tween_property(canvas_modulate, "color", darken_color, transition_time)

func _on_body_exited(body):
	if body.is_in_group("player") and canvas_modulate:
		if tween: tween.kill()
		tween = create_tween()
		tween.tween_property(canvas_modulate, "color", Color.WHITE, transition_time)
