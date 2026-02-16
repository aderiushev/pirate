class_name PowerUpBase
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
	position.y = base_y + sin(time * 2.5) * 5.0
	# Glow pulse on the star visual
	var glow = get_node_or_null("Glow")
	if glow:
		glow.modulate.a = 0.3 + sin(time * 4.0) * 0.15

func _on_body_entered(body: Node2D) -> void:
	if collected:
		return
	if not body.is_in_group("player"):
		return
	collected = true
	set_deferred("monitoring", false)
	_apply_power_up(body)
	_play_collect_animation()
	_play_magic_sound()

func _apply_power_up(_player: Node2D) -> void:
	pass

func _play_collect_animation() -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(2.0, 2.0), 0.3).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", position.y - 80, 0.3).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)

func _play_magic_sound() -> void:
	var sample_rate = 22050.0
	var notes = [261.63, 329.63, 392.00, 523.25]
	var note_duration = 0.06
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
			# Triangle wave for softer magic sound
			var sample = (4.0 * absf(phase - 0.5) - 1.0) * 0.25 * env
			playback.push_frame(Vector2(sample, sample))

	var cleanup = get_parent().create_tween()
	cleanup.tween_interval(total_duration + 0.5)
	cleanup.tween_callback(player.queue_free)
