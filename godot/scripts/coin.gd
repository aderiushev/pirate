extends Area2D

var collected: bool = false
var time: float = 0.0
var base_y: float = 0.0

func _ready() -> void:
	base_y = position.y
	body_entered.connect(_on_body_entered)
	time = randf() * TAU

func _process(delta: float) -> void:
	if collected:
		return
	time += delta
	position.y = base_y + sin(time * 3.0) * 4.0
	rotation = sin(time * 1.5) * 0.15

func _on_body_entered(body: Node2D) -> void:
	if collected:
		return
	if not body.is_in_group("player"):
		return
	collected = true
	set_deferred("monitoring", false)
	GameState.add_coins(1)
	_play_collect_animation()
	_spawn_sparkles()
	_play_ding_sound()

func _play_collect_animation() -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(2.5, 2.5), 0.3).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", position.y - 60, 0.3).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)

func _spawn_sparkles() -> void:
	for i in range(10):
		var sparkle = Polygon2D.new()
		sparkle.color = Color(1, 0.9, 0.2, 1)
		sparkle.polygon = PackedVector2Array([
			Vector2(0, -3), Vector2(1, -1),
			Vector2(3, 0), Vector2(1, 1),
			Vector2(0, 3), Vector2(-1, 1),
			Vector2(-3, 0), Vector2(-1, -1)
		])
		sparkle.z_index = 10
		var angle = TAU * i / 10.0
		sparkle.position = global_position
		get_parent().add_child(sparkle)
		var target = global_position + Vector2(cos(angle) * 40, sin(angle) * 40)
		var tween = sparkle.create_tween()
		tween.set_parallel(true)
		tween.tween_property(sparkle, "position", target, 0.4).set_ease(Tween.EASE_OUT)
		tween.tween_property(sparkle, "modulate:a", 0.0, 0.4)
		tween.tween_property(sparkle, "scale", Vector2(0.3, 0.3), 0.4)
		tween.set_parallel(false)
		tween.tween_callback(sparkle.queue_free)

func _play_ding_sound() -> void:
	var sample_rate = 22050.0
	var notes = [523.25, 659.25, 783.99, 1046.50]
	var note_duration = 0.04
	var total_duration = notes.size() * note_duration + 0.1

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
	for note_freq in notes:
		var num_samples = int(sample_rate * note_duration)
		for s in range(num_samples):
			var t = 1.0 / sample_rate
			phase += note_freq * t
			if phase > 1.0:
				phase -= 1.0
			var pos = float(s) / float(num_samples)
			var env = 1.0
			if pos < 0.05:
				env = pos / 0.05
			elif pos > 0.7:
				env = (1.0 - pos) / 0.3
			var sample = sin(phase * TAU) * 0.3 * env
			playback.push_frame(Vector2(sample, sample))

	for s in range(int(sample_rate * 0.1)):
		var decay = 1.0 - float(s) / (sample_rate * 0.1)
		var sample = sin(phase * TAU) * 0.1 * decay
		phase += 1046.50 / sample_rate
		if phase > 1.0:
			phase -= 1.0
		playback.push_frame(Vector2(sample, sample))

	var cleanup = get_parent().create_tween()
	cleanup.tween_interval(total_duration + 0.5)
	cleanup.tween_callback(player.queue_free)
