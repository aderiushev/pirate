extends Area2D

const LIFETIME = 0.15
const SPEED = 0.0

var lifetime: float = 0.0
var hit_bodies: Array = []

func _ready() -> void:
	_play_swoosh_sound()

func _physics_process(delta: float) -> void:
	lifetime += delta
	if lifetime > LIFETIME:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body in hit_bodies:
		return
	hit_bodies.append(body)
	if body.has_method("take_hit"):
		body.take_hit()
	_spawn_hit_sparks()

func _spawn_hit_sparks() -> void:
	var effect = Node2D.new()
	effect.global_position = global_position
	get_parent().add_child(effect)

	# Small orange/white sparks
	for i in range(5):
		var spark = Polygon2D.new()
		spark.color = Color(1, 0.8, 0.3, 1) if i % 2 == 0 else Color(1, 1, 1, 0.9)
		spark.polygon = PackedVector2Array([
			Vector2(0, -2), Vector2(2, 0), Vector2(0, 2), Vector2(-2, 0)
		])
		var angle = (TAU / 5.0) * i
		spark.position = Vector2(cos(angle) * 4, sin(angle) * 4)
		effect.add_child(spark)

	var tween = effect.create_tween()
	tween.set_parallel(true)
	tween.tween_property(effect, "scale", Vector2(1.5, 1.5), 0.1).from(Vector2(0.3, 0.3))
	tween.set_parallel(false)
	tween.set_parallel(true)
	tween.tween_property(effect, "scale", Vector2(0.1, 0.1), 0.15)
	tween.tween_property(effect, "modulate:a", 0.0, 0.15)
	tween.set_parallel(false)
	tween.tween_callback(effect.queue_free)

func _play_swoosh_sound() -> void:
	var sample_rate = 22050.0
	var duration = 0.1
	var player = AudioStreamPlayer.new()
	var gen = AudioStreamGenerator.new()
	gen.mix_rate = sample_rate
	gen.buffer_length = duration + 0.1
	player.stream = gen
	player.volume_db = -10.0
	get_parent().add_child(player)
	player.play()
	var playback = player.get_stream_playback()
	if not playback:
		player.queue_free()
		return

	var rng = RandomNumberGenerator.new()
	rng.seed = randi()
	var num_samples = int(sample_rate * duration)
	for i in range(num_samples):
		var pos = float(i) / float(num_samples)
		# White noise filtered through bandpass, pitch sweep high to low
		var noise = rng.randf_range(-1.0, 1.0)
		var freq_factor = 1.0 - pos * 0.7  # sweep down
		var env = 1.0 - pos
		env *= env  # faster decay
		var sample = noise * 0.4 * env * freq_factor
		playback.push_frame(Vector2(sample, sample))

	var cleanup = get_tree().create_tween()
	cleanup.tween_interval(0.4)
	cleanup.tween_callback(player.queue_free)
