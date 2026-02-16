extends Area2D

const SPEED = 550.0
const MAX_LIFETIME = 3.0
const MAX_X = 5000.0
const SPIN_SPEED = 0.0

var lifetime: float = 0.0
var oscillation_time: float = 0.0

func _ready() -> void:
	_play_pew_sound()

func _physics_process(delta: float) -> void:
	position.x += SPEED * delta
	lifetime += delta
	# Slight Y oscillation for energy beam feel
	oscillation_time += delta * 15.0
	position.y += sin(oscillation_time) * 0.3
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

	# Cyan ring burst
	var ring = Polygon2D.new()
	ring.color = Color(0, 0.9, 1, 0.8)
	var ring_points: PackedVector2Array = PackedVector2Array()
	for i in range(12):
		var angle = (TAU / 12.0) * i
		ring_points.append(Vector2(cos(angle) * 12, sin(angle) * 12))
	ring.polygon = ring_points
	effect.add_child(ring)

	# Inner white flash
	var flash = Polygon2D.new()
	flash.color = Color(1, 1, 1, 0.9)
	var flash_points: PackedVector2Array = PackedVector2Array()
	for i in range(8):
		var angle = (TAU / 8.0) * i
		var r = 6.0 if i % 2 == 0 else 3.0
		flash_points.append(Vector2(cos(angle) * r, sin(angle) * r))
	flash.polygon = flash_points
	effect.add_child(flash)

	# Outer glow
	var glow = Polygon2D.new()
	glow.color = Color(0, 0.7, 1, 0.3)
	var glow_points: PackedVector2Array = PackedVector2Array()
	for i in range(12):
		var angle = (TAU / 12.0) * i
		glow_points.append(Vector2(cos(angle) * 18, sin(angle) * 18))
	glow.polygon = glow_points
	glow.z_index = -1
	effect.add_child(glow)

	var tween = effect.create_tween()
	tween.set_parallel(true)
	tween.tween_property(effect, "scale", Vector2(2.0, 2.0), 0.08).from(Vector2(0.2, 0.2))
	tween.set_parallel(false)
	tween.set_parallel(true)
	tween.tween_property(effect, "scale", Vector2(0.05, 0.05), 0.2)
	tween.tween_property(effect, "modulate:a", 0.0, 0.2)
	tween.set_parallel(false)
	tween.tween_callback(effect.queue_free)

func _play_pew_sound() -> void:
	var sample_rate = 22050.0
	var duration = 0.08
	var player = AudioStreamPlayer.new()
	var gen = AudioStreamGenerator.new()
	gen.mix_rate = sample_rate
	gen.buffer_length = duration + 0.1
	player.stream = gen
	player.volume_db = -8.0
	get_parent().add_child(player)
	player.play()
	var playback = player.get_stream_playback()
	if not playback:
		player.queue_free()
		return

	var phase = 0.0
	var num_samples = int(sample_rate * duration)
	for i in range(num_samples):
		var t = 1.0 / sample_rate
		var pos = float(i) / float(num_samples)
		# 800Hz -> 200Hz sine sweep, sci-fi zap
		var freq = 800.0 - pos * 600.0
		phase += freq * t
		if phase > 1.0:
			phase -= 1.0
		var sample = sin(phase * TAU) * 0.4
		var env = 1.0 - pos * 0.8
		sample *= env
		playback.push_frame(Vector2(sample, sample))

	var cleanup = get_tree().create_tween()
	cleanup.tween_interval(0.4)
	cleanup.tween_callback(player.queue_free)
