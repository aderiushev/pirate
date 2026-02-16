extends Area2D

const SPEED = 350.0
const MAX_LIFETIME = 3.0
const MAX_X = 5000.0
const SPIN_SPEED = 12.0

var lifetime: float = 0.0

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

	# Big star-burst explosion
	var burst = Polygon2D.new()
	burst.color = Color(1, 0.9, 0.2, 1)
	burst.polygon = PackedVector2Array([
		Vector2(0, -14), Vector2(4, -5),
		Vector2(13, -4), Vector2(6, 2),
		Vector2(8, 12), Vector2(0, 7),
		Vector2(-8, 12), Vector2(-6, 2),
		Vector2(-13, -4), Vector2(-4, -5)
	])
	effect.add_child(burst)

	# Inner white flash
	var flash = Polygon2D.new()
	flash.color = Color(1, 1, 1, 0.9)
	flash.polygon = PackedVector2Array([
		Vector2(0, -7), Vector2(2, -2),
		Vector2(7, -2), Vector2(3, 1),
		Vector2(4, 6), Vector2(0, 3),
		Vector2(-4, 6), Vector2(-3, 1),
		Vector2(-7, -2), Vector2(-2, -2)
	])
	effect.add_child(flash)

	# Orange ring
	var ring = Polygon2D.new()
	ring.color = Color(1, 0.5, 0.1, 0.6)
	ring.polygon = PackedVector2Array([
		Vector2(10, 0), Vector2(7, 7), Vector2(0, 10), Vector2(-7, 7),
		Vector2(-10, 0), Vector2(-7, -7), Vector2(0, -10), Vector2(7, -7)
	])
	ring.z_index = -1
	effect.add_child(ring)

	# Animate: pop out then shrink and fade
	var tween = effect.create_tween()
	tween.set_parallel(true)
	tween.tween_property(effect, "scale", Vector2(1.8, 1.8), 0.08).from(Vector2(0.3, 0.3))
	tween.set_parallel(false)
	tween.set_parallel(true)
	tween.tween_property(effect, "scale", Vector2(0.1, 0.1), 0.25)
	tween.tween_property(effect, "modulate:a", 0.0, 0.25)
	tween.tween_property(effect, "rotation", randf_range(-1.0, 1.0), 0.25)
	tween.set_parallel(false)
	tween.tween_callback(effect.queue_free)
