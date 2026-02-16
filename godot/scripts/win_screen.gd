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
	tween.tween_property(title, "scale", Vector2(1.2, 1.2), 0.5)
	tween.tween_property(title, "scale", Vector2(1.0, 1.0), 0.5)

	$CoinCount.text = "🪙 " + str(GameState.coins)

	# Special display for level 3 completion
	if GameState.current_level >= 3:
		$Stars1.text = "⭐ ⭐ ⭐ ⭐ ⭐"
		if GameState.blaster_unlocked:
			$NextLevel.text = "👽"
			$NextLevel.visible = true
		else:
			$NextLevel.visible = false
	else:
		$NextLevel.visible = true

func _on_play_again_pressed() -> void:
	var level = GameState.current_level
	if level in LEVEL_SCENES:
		get_tree().change_scene_to_file(LEVEL_SCENES[level])
	else:
		get_tree().change_scene_to_file(LEVEL_SCENES[1])

func _on_next_level_pressed() -> void:
	var next = GameState.current_level + 1
	if next > 3:
		next = 1

	if GameState.weapons_unlocked.size() >= 2:
		GameState.pending_next_level = next
		GameState.current_level = next
		get_tree().change_scene_to_file("res://scenes/ui/weapon_select.tscn")
	elif next in LEVEL_SCENES:
		GameState.current_level = next
		get_tree().change_scene_to_file(LEVEL_SCENES[next])

func _on_levels_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/level_select.tscn")
