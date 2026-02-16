extends PowerUpBase

func _apply_power_up(player: Node2D) -> void:
	GameState.shield_active = true
	GameState.power_up_activated.emit("shield")
	_create_shield_bubble(player)

func _create_shield_bubble(player: Node2D) -> void:
	var bubble = Polygon2D.new()
	bubble.name = "ShieldBubble"
	bubble.color = Color(0.3, 0.6, 1.0, 0.25)
	bubble.z_index = 5
	# 12-sided circle
	var points = PackedVector2Array()
	for i in range(12):
		var angle = TAU * i / 12.0
		points.append(Vector2(cos(angle) * 22, sin(angle) * 22 - 5))
	bubble.polygon = points

	var body_visual = player.get_node_or_null("Body")
	if body_visual:
		body_visual.add_child(bubble)

	# Pulse animation
	var tween = bubble.create_tween().set_loops()
	tween.tween_property(bubble, "modulate:a", 0.6, 0.5)
	tween.tween_property(bubble, "modulate:a", 1.0, 0.5)

	# Listen for shield breaking
	GameState.power_up_expired.connect(func(type: String):
		if type == "shield" and is_instance_valid(bubble):
			_pop_bubble(bubble)
	)

func _pop_bubble(bubble: Polygon2D) -> void:
	var tween = bubble.create_tween()
	tween.tween_property(bubble, "scale", Vector2(2.0, 2.0), 0.15)
	tween.parallel().tween_property(bubble, "modulate:a", 0.0, 0.15)
	tween.tween_callback(bubble.queue_free)
