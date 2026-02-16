extends Area2D

var activated: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if activated:
		return
	if not body.is_in_group("player"):
		return
	activated = true
	body.last_checkpoint = global_position + Vector2(0, -20)
	_activate_animation()
	_play_checkpoint_sound()

func _activate_animation() -> void:
	var flag = $Flag
	if flag:
		flag.color = Color(1, 0.2, 0.1, 1)
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.15).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15)
	_spawn_sparkles()

func _spawn_sparkles() -> void:
	for i in range(8):
		var sparkle = Polygon2D.new()
		sparkle.color = Color(1, 0.9, 0.2, 1)
		sparkle.polygon = PackedVector2Array([
			Vector2(0, -3), Vector2(1, -1),
			Vector2(3, 0), Vector2(1, 1),
			Vector2(0, 3), Vector2(-1, 1),
			Vector2(-3, 0), Vector2(-1, -1)
		])
		sparkle.z_index = 10
		var angle = TAU * i / 8.0
		sparkle.position = global_position + Vector2(0, -20)
		get_parent().add_child(sparkle)
		var target = sparkle.position + Vector2(cos(angle) * 30, sin(angle) * 30)
		var tw = sparkle.create_tween()
		tw.set_parallel(true)
		tw.tween_property(sparkle, "position", target, 0.4).set_ease(Tween.EASE_OUT)
		tw.tween_property(sparkle, "modulate:a", 0.0, 0.4)
		tw.set_parallel(false)
		tw.tween_callback(sparkle.queue_free)

func _play_checkpoint_sound() -> void:
	var sample_rate = 22050.0
	var notes = [329.63, 392.00, 523.25]
	var note_duration = 0.08
	var total_duration = notes.size() * note_duration + 0.15

	var player = AudioStreamPlayer.new()
	var gen = AudioStreamGenerator.new()
	gen.mix_rate = sample_rate
	gen.buffer_length = total_duration + 0.2
	player.stream = gen
	player.volume_db = -8.0
	get_parent().add_child(player)
	player.play()

	var playback = player.get_stream_playback()
	if not playback:
		player.queue_free()
		return

	var phase = 0.0
	for freq in notes:
		var num_samples = int(sample_rate * note_duration)
		for s in range(num_samples):
			var t = 1.0 / sample_rate
			phase += freq * t
			if phase > 1.0:
				phase -= 1.0
			var pos = float(s) / float(num_samples)
			var env = 1.0
			if pos < 0.05:
				env = pos / 0.05
			elif pos > 0.6:
				env = (1.0 - pos) / 0.4
			var chord = sin(phase * TAU) * 0.2 + sin(phase * TAU * 1.5) * 0.1
			var sample = chord * env
			playback.push_frame(Vector2(sample, sample))

	var cleanup = get_parent().create_tween()
	cleanup.tween_interval(total_duration + 0.5)
	cleanup.tween_callback(player.queue_free)
