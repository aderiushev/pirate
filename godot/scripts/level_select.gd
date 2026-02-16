extends Control

const LEVEL_SCENES = {
	1: "res://scenes/levels/level_1.tscn",
	2: "res://scenes/levels/level_2.tscn",
	3: "res://scenes/levels/level_3.tscn",
}

func _ready() -> void:
	$CoinCount.text = "Монеты: " + str(GameState.coins)
	_update_buttons()

func _update_buttons() -> void:
	# Level 1 always unlocked
	$Level1Button.disabled = false
	# Level 2
	if GameState.levels_unlocked >= 2:
		$Level2Button.disabled = false
		$Level2Button.modulate = Color(1, 1, 1, 1)
		$Lock2.visible = false
	else:
		$Level2Button.disabled = true
		$Level2Button.modulate = Color(0.5, 0.5, 0.5, 0.7)
		$Lock2.visible = true
	# Level 3
	if GameState.levels_unlocked >= 3:
		$Level3Button.disabled = false
		$Level3Button.modulate = Color(1, 1, 1, 1)
		$Lock3.visible = false
	else:
		$Level3Button.disabled = true
		$Level3Button.modulate = Color(0.5, 0.5, 0.5, 0.7)
		$Lock3.visible = true

func _on_level_1_pressed() -> void:
	GameState.current_level = 1
	_go_to_level(1)

func _on_level_2_pressed() -> void:
	GameState.current_level = 2
	_go_to_level(2)

func _on_level_3_pressed() -> void:
	GameState.current_level = 3
	_go_to_level(3)

func _go_to_level(level: int) -> void:
	if GameState.weapons_unlocked.size() >= 2:
		GameState.pending_next_level = level
		get_tree().change_scene_to_file("res://scenes/ui/weapon_select.tscn")
	else:
		get_tree().change_scene_to_file(LEVEL_SCENES[level])
