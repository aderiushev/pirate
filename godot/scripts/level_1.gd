extends Node2D

@onready var jump_hint: Label = $UI/JumpHint
@onready var wave_layer1: Polygon2D = $WaveLayer1
@onready var wave_layer2: Polygon2D = $WaveLayer2
@onready var outer_flame: Polygon2D = $Torch/OuterFlame
@onready var inner_flame: Polygon2D = $Torch/InnerFlame
@onready var torch_glow: Polygon2D = $Torch/TorchGlow

var hint_dismissed: bool = false
var time: float = 0.0
var wave1_base_y: float = 0.0
var wave2_base_y: float = 0.0

func _ready() -> void:
	GameState.current_level = 1
	GameState.reset_for_level()
	wave1_base_y = wave_layer1.position.y
	wave2_base_y = wave_layer2.position.y
	_start_cloud_drift()
	_flicker_torch()

func _process(delta: float) -> void:
	time += delta

	if not hint_dismissed and Input.is_action_just_pressed("jump"):
		hint_dismissed = true
		var tween = create_tween()
		tween.tween_property(jump_hint, "modulate:a", 0.0, 1.0)
		tween.tween_callback(func(): jump_hint.visible = false)

	# Wave bob
	wave_layer1.position.y = wave1_base_y + sin(time * 1.2) * 3.0
	wave_layer2.position.y = wave2_base_y + sin(time * 0.8 + 1.5) * 2.0

func _start_cloud_drift() -> void:
	for cloud in $Clouds.get_children():
		var drift_range = randf_range(40.0, 80.0)
		var drift_time = randf_range(40.0, 80.0)
		var start_x = cloud.position.x
		var tween = create_tween().set_loops()
		tween.tween_property(cloud, "position:x", start_x + drift_range, drift_time * 0.5) \
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		tween.tween_property(cloud, "position:x", start_x, drift_time * 0.5) \
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _flicker_torch() -> void:
	var tween = create_tween()
	var new_scale = randf_range(0.85, 1.2)
	var glow_alpha = randf_range(0.1, 0.25)
	var duration = randf_range(0.1, 0.25)
	tween.tween_property(outer_flame, "scale", Vector2(new_scale, new_scale), duration)
	tween.parallel().tween_property(inner_flame, "scale", Vector2(new_scale, new_scale), duration)
	tween.parallel().tween_property(torch_glow, "modulate:a", glow_alpha, duration)
	tween.tween_callback(_flicker_torch)

func _on_win_area_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		body.set_physics_process(false)
		GameState.complete_level()
		await get_tree().create_timer(0.5).timeout
		get_tree().change_scene_to_file("res://scenes/ui/win_screen.tscn")
