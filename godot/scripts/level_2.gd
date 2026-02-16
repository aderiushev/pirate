extends Node2D

@onready var wave_layer1: Polygon2D = $WaveLayer1
@onready var wave_layer2: Polygon2D = $WaveLayer2

var time: float = 0.0
var wave1_base_y: float = 0.0
var wave2_base_y: float = 0.0

func _ready() -> void:
	GameState.current_level = 2
	GameState.reset_for_level()
	wave1_base_y = wave_layer1.position.y
	wave2_base_y = wave_layer2.position.y
	_start_cloud_drift()

func _process(delta: float) -> void:
	time += delta
	wave_layer1.position.y = wave1_base_y + sin(time * 1.0) * 3.0
	wave_layer2.position.y = wave2_base_y + sin(time * 0.7 + 1.5) * 2.0

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

func _on_win_area_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		body.set_physics_process(false)
		GameState.complete_level()
		await get_tree().create_timer(0.5).timeout
		get_tree().change_scene_to_file("res://scenes/ui/win_screen.tscn")
