extends PowerUpBase

const JUMP_DURATION = 8.0
const SUPER_JUMP_VELOCITY = -600.0
const SUPER_DOUBLE_JUMP_VELOCITY = -525.0
const NORMAL_JUMP_VELOCITY = -400.0
const NORMAL_DOUBLE_JUMP_VELOCITY = -350.0

func _apply_power_up(player: Node2D) -> void:
	GameState.super_jump_active = true
	GameState.power_up_activated.emit("super_jump")
	player.current_jump_velocity = SUPER_JUMP_VELOCITY
	player.current_double_jump_velocity = SUPER_DOUBLE_JUMP_VELOCITY

	# Auto-expire after duration
	var scene_tree = player.get_tree()
	await scene_tree.create_timer(JUMP_DURATION).timeout
	if is_instance_valid(player):
		player.current_jump_velocity = NORMAL_JUMP_VELOCITY
		player.current_double_jump_velocity = NORMAL_DOUBLE_JUMP_VELOCITY
		GameState.super_jump_active = false
		GameState.power_up_expired.emit("super_jump")
