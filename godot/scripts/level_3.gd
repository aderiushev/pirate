extends Node2D

@onready var lava_layer1: Polygon2D = $LavaLayer1
@onready var lava_layer2: Polygon2D = $LavaLayer2

var time: float = 0.0
var lava1_base_y: float = 0.0
var lava2_base_y: float = 0.0

func _ready() -> void:
	GameState.current_level = 3
	GameState.reset_for_level()
	lava1_base_y = lava_layer1.position.y
	lava2_base_y = lava_layer2.position.y
	_flicker_ambient()

func _process(delta: float) -> void:
	time += delta
	lava_layer1.position.y = lava1_base_y + sin(time * 0.8) * 2.0
	lava_layer2.position.y = lava2_base_y + sin(time * 0.6 + 1.0) * 1.5
	# Lava glow pulsation
	lava_layer1.modulate.a = 0.85 + sin(time * 2.0) * 0.1
	lava_layer2.modulate.a = 0.7 + sin(time * 1.5 + 0.5) * 0.1

func _flicker_ambient() -> void:
	var glow = get_node_or_null("AmbientGlow")
	if not glow:
		return
	var tween = create_tween()
	var new_alpha = randf_range(0.05, 0.15)
	var duration = randf_range(0.15, 0.3)
	tween.tween_property(glow, "modulate:a", new_alpha, duration)
	tween.tween_callback(_flicker_ambient)

func _on_win_area_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		body.set_physics_process(false)
		GameState.complete_level()
		await get_tree().create_timer(0.5).timeout
		get_tree().change_scene_to_file("res://scenes/ui/win_screen.tscn")
