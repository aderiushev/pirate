extends PowerUpBase

const RAPID_DURATION = 8.0

var _original_interval: float = 0.5

func _apply_power_up(player: Node2D) -> void:
	GameState.rapid_fire_active = true
	GameState.power_up_activated.emit("rapid_fire")
	_original_interval = player.current_shoot_interval
	player.current_shoot_interval = player.current_shoot_interval / 3.0

	# Auto-expire after duration
	var scene_tree = player.get_tree()
	await scene_tree.create_timer(RAPID_DURATION).timeout
	if is_instance_valid(player):
		player.current_shoot_interval = _original_interval
		GameState.rapid_fire_active = false
		GameState.power_up_expired.emit("rapid_fire")
