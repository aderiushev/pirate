extends CharacterBody2D

const RUN_SPEED = 120.0
const JUMP_VELOCITY = -400.0
const DOUBLE_JUMP_VELOCITY = -350.0
const COYOTE_TIME = 0.25
const JUMP_BUFFER_TIME = 0.15
const WALK_ANIM_SPEED = 10.0
const LEG_SWING = 0.5
const ARM_SWING = 0.35
const SHOOT_INTERVAL = 0.5

const WEAPON_INTERVALS = {
	0: 0.4,   # SWORD
	1: 0.5,   # PISTOL
	2: 0.7,   # GUN
	3: 0.35,  # BLASTER
}

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var can_double_jump: bool = false
var last_checkpoint: Vector2 = Vector2.ZERO
var walk_time: float = 0.0
var was_on_floor: bool = true
var shoot_timer: float = 0.0
var bullet_scene: PackedScene = preload("res://scenes/projectiles/bullet.tscn")
var sword_scene: PackedScene = preload("res://scenes/projectiles/sword_slash.tscn")
var gun_bullet_scene: PackedScene = preload("res://scenes/projectiles/gun_bullet.tscn")
var blaster_bolt_scene: PackedScene = preload("res://scenes/projectiles/blaster_bolt.tscn")

var is_invincible: bool = false
var invincibility_timer: float = 0.0
var blink_timer: float = 0.0
var is_dead_flag: bool = false

var current_jump_velocity: float = JUMP_VELOCITY
var current_double_jump_velocity: float = DOUBLE_JUMP_VELOCITY
var current_shoot_interval: float = SHOOT_INTERVAL

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var body_visual: Node2D = $Body
@onready var left_leg: Node2D = $Body/LeftLeg
@onready var right_leg: Node2D = $Body/RightLeg
@onready var left_arm: Node2D = $Body/LeftArm
@onready var right_arm: Node2D = $Body/RightArm
@onready var gun_node: Node2D = $Body/RightArm/Gun

var muzzle: Marker2D
var muzzle_flash: Polygon2D
var muzzle_flash_inner: Polygon2D

func _ready() -> void:
	last_checkpoint = global_position
	add_to_group("player")
	# Set weapon interval based on current weapon
	current_shoot_interval = WEAPON_INTERVALS.get(GameState.current_weapon, 0.5)
	# Build weapon visual
	_build_weapon_visual()
	# Connect weapon changed signal
	GameState.weapon_changed.connect(_on_weapon_changed)

func _on_weapon_changed(_weapon: int) -> void:
	current_shoot_interval = WEAPON_INTERVALS.get(GameState.current_weapon, 0.5)
	_build_weapon_visual()

func _physics_process(delta: float) -> void:
	if is_dead_flag:
		return

	velocity.x = RUN_SPEED

	if not is_on_floor():
		velocity.y += gravity * delta
		coyote_timer -= delta
	else:
		coyote_timer = COYOTE_TIME
		can_double_jump = true

	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		jump_buffer_timer -= delta

	# First jump (coyote time + buffer)
	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = current_jump_velocity
		coyote_timer = 0.0
		jump_buffer_timer = 0.0
	# Double jump while airborne
	elif Input.is_action_just_pressed("jump") and can_double_jump and not is_on_floor():
		velocity.y = current_double_jump_velocity
		can_double_jump = false
		jump_buffer_timer = 0.0
		_play_spin()

	move_and_slide()

	# Auto-attack
	shoot_timer -= delta
	if shoot_timer <= 0.0:
		_attack()
		shoot_timer = current_shoot_interval

	# Landing squash-and-stretch
	if is_on_floor() and not was_on_floor:
		_play_land_squash()
	was_on_floor = is_on_floor()

	_animate_body(delta)
	_update_animation()

	# Invincibility blink
	if is_invincible:
		invincibility_timer -= delta
		blink_timer -= delta
		if blink_timer <= 0.0:
			blink_timer = 0.1
			if body_visual:
				body_visual.visible = not body_visual.visible
		if invincibility_timer <= 0.0:
			is_invincible = false
			if body_visual:
				body_visual.visible = true

	# Fall respawn — no health loss, just respawn at checkpoint
	if global_position.y > 600:
		_respawn()

# === WEAPON ATTACK DISPATCH ===

func _attack() -> void:
	match GameState.current_weapon:
		GameState.Weapon.SWORD:
			_attack_sword()
		GameState.Weapon.PISTOL:
			_attack_pistol()
		GameState.Weapon.GUN:
			_attack_gun()
		GameState.Weapon.BLASTER:
			_attack_blaster()

func _attack_sword() -> void:
	var slash = sword_scene.instantiate()
	slash.global_position = global_position + Vector2(20, 0)
	get_parent().add_child(slash)
	# Arm sweep animation (forward swing instead of recoil)
	if right_arm:
		var swing = create_tween()
		swing.tween_property(right_arm, "rotation", right_arm.rotation + 0.6, 0.05)
		swing.tween_property(right_arm, "rotation", right_arm.rotation, 0.1)

func _attack_pistol() -> void:
	if not muzzle:
		return
	var bullet = bullet_scene.instantiate()
	bullet.global_position = muzzle.global_position
	get_parent().add_child(bullet)
	_play_muzzle_flash(Color(1, 0.95, 0.3, 1), Color(1, 1, 0.9, 1), 1.3)
	# Gun recoil kick
	if right_arm:
		var recoil = create_tween()
		recoil.tween_property(right_arm, "rotation", right_arm.rotation - 0.3, 0.05)
		recoil.tween_property(right_arm, "rotation", right_arm.rotation, 0.1)
	_play_pistol_sound()

func _attack_gun() -> void:
	if not muzzle:
		return
	var bullet = gun_bullet_scene.instantiate()
	bullet.global_position = muzzle.global_position
	get_parent().add_child(bullet)
	_play_muzzle_flash(Color(1, 0.8, 0.2, 1), Color(1, 1, 0.8, 1), 1.8)
	# Stronger recoil
	if right_arm:
		var recoil = create_tween()
		recoil.tween_property(right_arm, "rotation", right_arm.rotation - 0.5, 0.06)
		recoil.tween_property(right_arm, "rotation", right_arm.rotation, 0.12)

func _attack_blaster() -> void:
	if not muzzle:
		return
	var bolt = blaster_bolt_scene.instantiate()
	bolt.global_position = muzzle.global_position
	get_parent().add_child(bolt)
	# Cyan muzzle flash, no recoil but glow pulse
	_play_muzzle_flash(Color(0, 0.9, 1, 1), Color(1, 1, 1, 0.9), 1.0)

func _play_muzzle_flash(outer_color: Color, inner_color: Color, flash_scale: float) -> void:
	if muzzle_flash:
		muzzle_flash.color = outer_color
		muzzle_flash.visible = true
		muzzle_flash.modulate.a = 1.0
		muzzle_flash.scale = Vector2(flash_scale, flash_scale)
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(muzzle_flash, "modulate:a", 0.0, 0.15)
		tween.tween_property(muzzle_flash, "scale", Vector2(0.3, 0.3), 0.15)
		tween.set_parallel(false)
		tween.tween_callback(func(): muzzle_flash.visible = false)
	if muzzle_flash_inner:
		muzzle_flash_inner.color = inner_color
		muzzle_flash_inner.visible = true
		muzzle_flash_inner.modulate.a = 1.0
		var tween2 = create_tween()
		tween2.tween_property(muzzle_flash_inner, "modulate:a", 0.0, 0.1)
		tween2.tween_callback(func(): muzzle_flash_inner.visible = false)

# === WEAPON VISUAL BUILDER ===

func _build_weapon_visual() -> void:
	if not gun_node:
		return
	# Clear all children of Gun node
	for child in gun_node.get_children():
		child.queue_free()

	match GameState.current_weapon:
		GameState.Weapon.SWORD:
			_build_sword_visual()
		GameState.Weapon.PISTOL:
			_build_pistol_visual()
		GameState.Weapon.GUN:
			_build_gun_visual()
		GameState.Weapon.BLASTER:
			_build_blaster_visual()

	# Rebuild muzzle point and flash (needed for ranged weapons)
	_build_muzzle_nodes()

func _build_sword_visual() -> void:
	# Brown handle
	var handle = Polygon2D.new()
	handle.name = "Handle"
	handle.color = Color(0.45, 0.25, 0.08, 1)
	handle.polygon = PackedVector2Array([
		Vector2(-2, 0), Vector2(2, 0), Vector2(2, 8), Vector2(-2, 8)
	])
	gun_node.add_child(handle)
	# Crossguard
	var guard = Polygon2D.new()
	guard.name = "Crossguard"
	guard.color = Color(0.7, 0.65, 0.2, 1)
	guard.polygon = PackedVector2Array([
		Vector2(-5, -1), Vector2(5, -1), Vector2(5, 1), Vector2(-5, 1)
	])
	gun_node.add_child(guard)
	# Silver blade
	var blade = Polygon2D.new()
	blade.name = "Blade"
	blade.color = Color(0.78, 0.8, 0.82, 1)
	blade.polygon = PackedVector2Array([
		Vector2(-2, -1), Vector2(2, -1), Vector2(1.5, -14), Vector2(0, -16), Vector2(-1.5, -14)
	])
	gun_node.add_child(blade)
	# Blade highlight
	var highlight = Polygon2D.new()
	highlight.name = "BladeHighlight"
	highlight.color = Color(0.9, 0.92, 0.95, 0.6)
	highlight.polygon = PackedVector2Array([
		Vector2(-0.5, -2), Vector2(0.5, -2), Vector2(0.3, -13), Vector2(-0.3, -13)
	])
	gun_node.add_child(highlight)

func _build_pistol_visual() -> void:
	# Recreate the original gun polygons from player.tscn
	var handle = Polygon2D.new()
	handle.name = "Handle"
	handle.color = Color(0.45, 0.25, 0.08, 1)
	handle.polygon = PackedVector2Array([
		Vector2(-3, 0), Vector2(3, 0), Vector2(2, 9), Vector2(-2, 9)
	])
	gun_node.add_child(handle)

	var handle_wrap = Polygon2D.new()
	handle_wrap.name = "HandleWrap"
	handle_wrap.color = Color(0.55, 0.35, 0.12, 1)
	handle_wrap.polygon = PackedVector2Array([
		Vector2(-2, 2), Vector2(2, 2), Vector2(2, 4), Vector2(-2, 4)
	])
	gun_node.add_child(handle_wrap)

	var handle_wrap2 = Polygon2D.new()
	handle_wrap2.name = "HandleWrap2"
	handle_wrap2.color = Color(0.55, 0.35, 0.12, 1)
	handle_wrap2.polygon = PackedVector2Array([
		Vector2(-2, 5), Vector2(2, 5), Vector2(2, 7), Vector2(-2, 7)
	])
	gun_node.add_child(handle_wrap2)

	var trigger = Polygon2D.new()
	trigger.name = "TriggerGuard"
	trigger.color = Color(0.3, 0.3, 0.32, 1)
	trigger.polygon = PackedVector2Array([
		Vector2(1, 2), Vector2(4, 2), Vector2(4, 6), Vector2(1, 6)
	])
	gun_node.add_child(trigger)

	var barrel = Polygon2D.new()
	barrel.name = "Barrel"
	barrel.color = Color(0.28, 0.28, 0.3, 1)
	barrel.polygon = PackedVector2Array([
		Vector2(-1, -2), Vector2(16, -2), Vector2(16, 3), Vector2(-1, 3)
	])
	gun_node.add_child(barrel)

	var barrel_hl = Polygon2D.new()
	barrel_hl.name = "BarrelHighlight"
	barrel_hl.color = Color(0.4, 0.4, 0.44, 1)
	barrel_hl.polygon = PackedVector2Array([
		Vector2(0, -2), Vector2(15, -2), Vector2(15, -1), Vector2(0, -1)
	])
	gun_node.add_child(barrel_hl)

	var flare = Polygon2D.new()
	flare.name = "BarrelFlare"
	flare.color = Color(0.25, 0.25, 0.28, 1)
	flare.polygon = PackedVector2Array([
		Vector2(14, -4), Vector2(20, -4), Vector2(20, 5), Vector2(14, 5)
	])
	gun_node.add_child(flare)

	var flare_inner = Polygon2D.new()
	flare_inner.name = "BarrelFlareInner"
	flare_inner.color = Color(0.15, 0.15, 0.17, 1)
	flare_inner.polygon = PackedVector2Array([
		Vector2(18, -2), Vector2(20, -2), Vector2(20, 3), Vector2(18, 3)
	])
	gun_node.add_child(flare_inner)

	var mechanism = Polygon2D.new()
	mechanism.name = "FiringMechanism"
	mechanism.color = Color(0.35, 0.35, 0.38, 1)
	mechanism.polygon = PackedVector2Array([
		Vector2(-2, -3), Vector2(2, -3), Vector2(2, -1), Vector2(-2, -1)
	])
	gun_node.add_child(mechanism)

	var gold = Polygon2D.new()
	gold.name = "GoldAccent"
	gold.color = Color(0.92, 0.78, 0.2, 1)
	gold.polygon = PackedVector2Array([
		Vector2(13, -3), Vector2(15, -3), Vector2(15, 4), Vector2(13, 4)
	])
	gun_node.add_child(gold)

func _build_gun_visual() -> void:
	# Bigger barrel, wider flare, gold trim — like pistol but 1.5x
	var handle = Polygon2D.new()
	handle.name = "Handle"
	handle.color = Color(0.4, 0.22, 0.06, 1)
	handle.polygon = PackedVector2Array([
		Vector2(-4, 0), Vector2(4, 0), Vector2(3, 12), Vector2(-3, 12)
	])
	gun_node.add_child(handle)

	var handle_wrap = Polygon2D.new()
	handle_wrap.name = "HandleWrap"
	handle_wrap.color = Color(0.55, 0.35, 0.12, 1)
	handle_wrap.polygon = PackedVector2Array([
		Vector2(-3, 3), Vector2(3, 3), Vector2(3, 5), Vector2(-3, 5)
	])
	gun_node.add_child(handle_wrap)

	var trigger = Polygon2D.new()
	trigger.name = "TriggerGuard"
	trigger.color = Color(0.3, 0.3, 0.32, 1)
	trigger.polygon = PackedVector2Array([
		Vector2(2, 2), Vector2(6, 2), Vector2(6, 7), Vector2(2, 7)
	])
	gun_node.add_child(trigger)

	var barrel = Polygon2D.new()
	barrel.name = "Barrel"
	barrel.color = Color(0.22, 0.22, 0.25, 1)
	barrel.polygon = PackedVector2Array([
		Vector2(-2, -3), Vector2(22, -3), Vector2(22, 4), Vector2(-2, 4)
	])
	gun_node.add_child(barrel)

	var barrel_hl = Polygon2D.new()
	barrel_hl.name = "BarrelHighlight"
	barrel_hl.color = Color(0.38, 0.38, 0.42, 1)
	barrel_hl.polygon = PackedVector2Array([
		Vector2(0, -3), Vector2(20, -3), Vector2(20, -2), Vector2(0, -2)
	])
	gun_node.add_child(barrel_hl)

	var flare = Polygon2D.new()
	flare.name = "BarrelFlare"
	flare.color = Color(0.2, 0.2, 0.23, 1)
	flare.polygon = PackedVector2Array([
		Vector2(19, -6), Vector2(28, -6), Vector2(28, 7), Vector2(19, 7)
	])
	gun_node.add_child(flare)

	var flare_inner = Polygon2D.new()
	flare_inner.name = "BarrelFlareInner"
	flare_inner.color = Color(0.12, 0.12, 0.14, 1)
	flare_inner.polygon = PackedVector2Array([
		Vector2(25, -3), Vector2(28, -3), Vector2(28, 4), Vector2(25, 4)
	])
	gun_node.add_child(flare_inner)

	# Gold trim accents
	var gold1 = Polygon2D.new()
	gold1.name = "GoldAccent1"
	gold1.color = Color(0.92, 0.78, 0.2, 1)
	gold1.polygon = PackedVector2Array([
		Vector2(18, -4), Vector2(20, -4), Vector2(20, 5), Vector2(18, 5)
	])
	gun_node.add_child(gold1)

	var gold2 = Polygon2D.new()
	gold2.name = "GoldAccent2"
	gold2.color = Color(0.92, 0.78, 0.2, 1)
	gold2.polygon = PackedVector2Array([
		Vector2(5, -4), Vector2(7, -4), Vector2(7, 5), Vector2(5, 5)
	])
	gun_node.add_child(gold2)

func _build_blaster_visual() -> void:
	# Sleek silver barrel, cyan glow strip, no flare, sci-fi look
	var handle = Polygon2D.new()
	handle.name = "Handle"
	handle.color = Color(0.35, 0.35, 0.38, 1)
	handle.polygon = PackedVector2Array([
		Vector2(-2, 0), Vector2(2, 0), Vector2(2, 8), Vector2(-2, 8)
	])
	gun_node.add_child(handle)

	var barrel = Polygon2D.new()
	barrel.name = "Barrel"
	barrel.color = Color(0.6, 0.62, 0.65, 1)
	barrel.polygon = PackedVector2Array([
		Vector2(-1, -2), Vector2(20, -2), Vector2(21, 0), Vector2(20, 2), Vector2(-1, 2)
	])
	gun_node.add_child(barrel)

	var barrel_hl = Polygon2D.new()
	barrel_hl.name = "BarrelHighlight"
	barrel_hl.color = Color(0.75, 0.77, 0.8, 1)
	barrel_hl.polygon = PackedVector2Array([
		Vector2(0, -2), Vector2(19, -2), Vector2(19, -1), Vector2(0, -1)
	])
	gun_node.add_child(barrel_hl)

	# Cyan glow strip along barrel
	var glow_strip = Polygon2D.new()
	glow_strip.name = "GlowStrip"
	glow_strip.color = Color(0, 0.9, 1, 0.6)
	glow_strip.polygon = PackedVector2Array([
		Vector2(2, -0.5), Vector2(19, -0.5), Vector2(19, 0.5), Vector2(2, 0.5)
	])
	gun_node.add_child(glow_strip)

	# Rear body (rounded back)
	var body = Polygon2D.new()
	body.name = "Body"
	body.color = Color(0.5, 0.52, 0.55, 1)
	body.polygon = PackedVector2Array([
		Vector2(-3, -3), Vector2(3, -3), Vector2(3, 3), Vector2(-3, 3)
	])
	gun_node.add_child(body)

	# Muzzle tip (bright cyan)
	var tip = Polygon2D.new()
	tip.name = "MuzzleTip"
	tip.color = Color(0, 0.9, 1, 0.8)
	tip.polygon = PackedVector2Array([
		Vector2(19, -1.5), Vector2(22, 0), Vector2(19, 1.5)
	])
	gun_node.add_child(tip)

func _build_muzzle_nodes() -> void:
	# Create MuzzlePoint Marker2D
	var muzzle_point = Marker2D.new()
	muzzle_point.name = "MuzzlePoint"
	match GameState.current_weapon:
		GameState.Weapon.SWORD:
			muzzle_point.position = Vector2(0, -16)
		GameState.Weapon.GUN:
			muzzle_point.position = Vector2(28, 0)
		GameState.Weapon.BLASTER:
			muzzle_point.position = Vector2(22, 0)
		_:
			muzzle_point.position = Vector2(20, 0)
	gun_node.add_child(muzzle_point)
	muzzle = muzzle_point

	# Create MuzzleFlash
	var flash = Polygon2D.new()
	flash.name = "MuzzleFlash"
	flash.visible = false
	flash.position = muzzle_point.position
	flash.z_index = 3
	flash.color = Color(1, 0.95, 0.3, 1)
	flash.polygon = PackedVector2Array([
		Vector2(0, -5), Vector2(10, -2), Vector2(12, 0), Vector2(10, 2),
		Vector2(0, 5), Vector2(2, 2), Vector2(3, 0), Vector2(2, -2)
	])
	gun_node.add_child(flash)
	muzzle_flash = flash

	# Create MuzzleFlashInner
	var flash_inner = Polygon2D.new()
	flash_inner.name = "MuzzleFlashInner"
	flash_inner.visible = false
	flash_inner.position = muzzle_point.position
	flash_inner.z_index = 4
	flash_inner.color = Color(1, 1, 0.9, 1)
	flash_inner.polygon = PackedVector2Array([
		Vector2(0, -2), Vector2(6, 0), Vector2(0, 2)
	])
	gun_node.add_child(flash_inner)
	muzzle_flash_inner = flash_inner

# === WEAPON SOUNDS ===

func _play_pistol_sound() -> void:
	var sample_rate = 22050.0
	var duration = 0.1
	var player_node = AudioStreamPlayer.new()
	var gen = AudioStreamGenerator.new()
	gen.mix_rate = sample_rate
	gen.buffer_length = duration + 0.1
	player_node.stream = gen
	player_node.volume_db = -8.0
	get_tree().current_scene.add_child(player_node)
	player_node.play()
	var playback = player_node.get_stream_playback()
	if not playback:
		player_node.queue_free()
		return
	var phase = 0.0
	var rng = RandomNumberGenerator.new()
	rng.seed = randi()
	var num_samples = int(sample_rate * duration)
	for i in range(num_samples):
		var t = 1.0 / sample_rate
		var pos = float(i) / float(num_samples)
		var freq = 120.0 - pos * 50.0
		phase += freq * t
		if phase > 1.0:
			phase -= 1.0
		var noise = rng.randf_range(-1.0, 1.0) * 0.3
		var sine = sin(phase * TAU) * 0.3
		var env = 1.0 - pos
		var sample = (sine + noise) * env * 0.4
		playback.push_frame(Vector2(sample, sample))
	var cleanup = get_tree().create_tween()
	cleanup.tween_interval(0.4)
	cleanup.tween_callback(player_node.queue_free)

# === DAMAGE & EFFECTS ===

func take_damage() -> void:
	if is_invincible or is_dead_flag:
		return
	var dead = GameState.take_damage()
	if dead:
		is_dead_flag = true
		velocity = Vector2.ZERO
		_play_oof_sound()
		_flash_red()
		set_physics_process(false)
		await get_tree().create_timer(0.8).timeout
		get_tree().change_scene_to_file("res://scenes/ui/game_over_screen.tscn")
	else:
		_play_oof_sound()
		_flash_red()
		is_invincible = true
		invincibility_timer = 2.0
		blink_timer = 0.1

func _flash_red() -> void:
	var flash_layer = CanvasLayer.new()
	flash_layer.layer = 100
	var flash_rect = ColorRect.new()
	flash_rect.color = Color(1, 0, 0, 0.4)
	flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash_rect.size = Vector2(1920, 1080)
	flash_layer.add_child(flash_rect)
	get_tree().current_scene.add_child(flash_layer)
	var tween = flash_layer.create_tween()
	tween.tween_property(flash_rect, "color:a", 0.0, 0.3)
	tween.tween_callback(flash_layer.queue_free)

func _play_oof_sound() -> void:
	var sample_rate = 22050.0
	var duration = 0.2
	var player_node = AudioStreamPlayer.new()
	var gen = AudioStreamGenerator.new()
	gen.mix_rate = sample_rate
	gen.buffer_length = duration + 0.1
	player_node.stream = gen
	player_node.volume_db = -6.0
	get_tree().current_scene.add_child(player_node)
	player_node.play()
	var playback = player_node.get_stream_playback()
	if not playback:
		player_node.queue_free()
		return
	var phase = 0.0
	var num_samples = int(sample_rate * duration)
	for i in range(num_samples):
		var t = 1.0 / sample_rate
		var pos = float(i) / float(num_samples)
		var freq = 80.0 - pos * 40.0
		phase += freq * t
		if phase > 1.0:
			phase -= 1.0
		var sample = (1.0 if phase < 0.5 else -1.0) * 0.3
		var env = 1.0 - pos
		sample *= env
		playback.push_frame(Vector2(sample, sample))
	var cleanup = get_tree().current_scene.create_tween()
	cleanup.tween_interval(0.5)
	cleanup.tween_callback(player_node.queue_free)

# === ANIMATION ===

func _animate_body(delta: float) -> void:
	if not body_visual:
		return

	if is_on_floor():
		# Walk cycle: legs and arms swing, body bobs
		walk_time += delta * WALK_ANIM_SPEED
		var swing = sin(walk_time)

		if left_leg:
			left_leg.rotation = swing * LEG_SWING
		if right_leg:
			right_leg.rotation = -swing * LEG_SWING
		if left_arm:
			left_arm.rotation = -swing * ARM_SWING
		if right_arm:
			right_arm.rotation = swing * ARM_SWING

		# Bouncy bob
		body_visual.position.y = abs(sin(walk_time)) * -2.0
	else:
		# Jump pose: legs tucked forward, arms raised
		if left_leg:
			left_leg.rotation = lerp(left_leg.rotation, 0.4, 0.12)
		if right_leg:
			right_leg.rotation = lerp(right_leg.rotation, -0.3, 0.12)
		if left_arm:
			left_arm.rotation = lerp(left_arm.rotation, -1.0, 0.12)
		if right_arm:
			right_arm.rotation = lerp(right_arm.rotation, -1.0, 0.12)
		body_visual.position.y = 0.0

func _play_spin() -> void:
	if body_visual:
		var tween = create_tween()
		tween.tween_property(body_visual, "rotation", TAU, 0.35).from(0.0)
		tween.tween_property(body_visual, "rotation", 0.0, 0.0)

func _play_land_squash() -> void:
	if body_visual:
		var tween = create_tween()
		tween.tween_property(body_visual, "scale", Vector2(1.3, 0.7), 0.07)
		tween.tween_property(body_visual, "scale", Vector2(0.9, 1.15), 0.07)
		tween.tween_property(body_visual, "scale", Vector2(1.0, 1.0), 0.1)

func _update_animation() -> void:
	if not anim or not anim.sprite_frames:
		return
	var anim_name = "jump" if not is_on_floor() else "run"
	if anim.sprite_frames.has_animation(anim_name) and anim.sprite_frames.get_frame_count(anim_name) > 0:
		anim.play(anim_name)

func _respawn() -> void:
	global_position = last_checkpoint
	velocity = Vector2.ZERO
