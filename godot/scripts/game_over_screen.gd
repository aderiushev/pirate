extends Control

const LEVEL_SCENES = {
	1: "res://scenes/levels/level_1.tscn",
	2: "res://scenes/levels/level_2.tscn",
	3: "res://scenes/levels/level_3.tscn",
}

func _ready() -> void:
	var title = $Title
	title.pivot_offset = title.size / 2
	var tween = create_tween().set_loops()
	tween.tween_property(title, "scale", Vector2(1.1, 1.1), 0.4)
	tween.tween_property(title, "scale", Vector2(1.0, 1.0), 0.4)

func _on_retry_pressed() -> void:
	GameState.reset_for_level()
	var level = GameState.current_level
	if level in LEVEL_SCENES:
		get_tree().change_scene_to_file(LEVEL_SCENES[level])
	else:
		get_tree().change_scene_to_file(LEVEL_SCENES[1])
