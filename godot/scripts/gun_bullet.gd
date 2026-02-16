extends Area2D

const SPEED = 450.0
const MAX_LIFETIME = 3.0
const MAX_X = 5000.0
const SPIN_SPEED = 8.0

var lifetime: float = 0.0

func _ready() -> void:
	_play_boom_sound()

func _physics_process(delta: float) -> void:
	position.x += SPEED * delta
	rotation += SPIN_SPEED * delta
	lifetime += delta
	if lifetime > MAX_LIFETIME or position.x > MAX_X:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_hit"):
		body.take_hit()
	_spawn_hit_effect()
	queue_free()

func _spawn_hit_effect() -> void:
	var effect = Node2D.new()
	effect.name = "HitEffect"
	effect.global_position = global_position
	get_parent().add_child(effect)

	# Bigger star-burst explosion (1.5x of normal bullet)
	var burst = Polygon2D.new()
	burst.color = Color(1, 0.85, 0.15, 1)
	burst.polygon = PackedVector2Array([
		Vector2(0, -21), Vector2(6, -7.5),
		Vector2(19.5, -6), Vector2(9, 3),
		Vector2(12, 18), Vector2(0, 10.5),
		Vector2(-12, 18), Vector2(-9, 3),
		Vector2(-19.5, -6), Vector2(-6, -7.5)
	])
	effect.add_child(burst)

	var flash = Polygon2D.new()
	flash.color = Color(1, 1, 1, 0.9)
	flash.polygon = PackedVector2Array([
		Vector2(0, -10.5), Vector2(3, -3),
		Vector2(10.5, -3), Vector2(4.5, 1.5),
		Vector2(6, 9), Vector2(0, 4.5),
		Vector2(-6, 9), Vector2(-4.5, 1.5),
		Vector2(-10.5, -3), Vector2(-3, -3)
	])
	effect.add_child(flash)

	var ring = Polygon2D.new()
	ring.color = Color(1, 0.4, 0.05, 0.6)
	ring.polygon = PackedVector2Array([
		Vector2(15, 0), Vector2(10.5, 10.5), Vector2(0, 15), Vector2(-10.5, 10.5),
		Vector2(-15, 0), Vector2(-10.5, -10.5), Vector2(0, -15), Vector2(10.5, -10.5)
	])
	ring.z_index = -1
	effect.add_child(ring)

	var tween = effect.create_tween()
	tween.set_parallel(true)
	tween.tween_property(effect, "scale", Vector2(2.2, 2.2), 0.1).from(Vector2(0.3, 0.3))
	tween.set_parallel(false)
	tween.set_parallel(true)
	tween.tween_property(effect, "scale", Vector2(0.1, 0.1), 0.3)
	tween.tween_property(effect, "modulate:a", 0.0, 0.3)
	tween.tween_property(effect, "rotation", randf_range(-1.0, 1.0), 0.3)
	tween.set_parallel(false)
	tween.tween_callback(effect.queue_free)

func _play_boom_sound() -> void:
	var sample_rate = 22050.0
	var duration = 0.15
	var player = AudioStreamPlayer.new()
	var gen = AudioStreamGenerator.new()
	gen.mix_rate = sample_rate
	gen.buffer_length = duration + 0.1
	player.stream = gen
	player.volume_db = -6.0
	get_parent().add_child(player)
	player.play()
	var playback = player.get_stream_playback()
	if not playback:
		player.queue_free()
		return

	var phase = 0.0
	var rng = RandomNumberGenerator.new()
	rng.seed = randi()
	var num_samples = int(sample_rate * duration)
	for i in range(num_samples):
		var t = 1.0 / sample_rate
		var pos = float(i) / float(num_samples)
		# 60Hz sine + noise burst (deeper than pistol)
		var freq = 60.0 + (1.0 - pos) * 20.0
		phase += freq * t
		if phase > 1.0:
			phase -= 1.0
		var sine = sin(phase * TAU) * 0.5
		var noise = rng.randf_range(-1.0, 1.0) * 0.3 * (1.0 - pos)
		var env = 1.0 - pos
		var sample = (sine + noise) * env * 0.5
		playback.push_frame(Vector2(sample, sample))

	var cleanup = get_tree().create_tween()
	cleanup.tween_interval(0.5)
	cleanup.tween_callback(player.queue_free)
