extends CharacterBody2D

const SHUFFLE_SPEED = -30.0
const WALK_ANIM_SPEED = 4.0
const LEG_SWING = 0.3
const ARM_SWING = 0.2
const SHOUTS = ["КАРАМБА!", "НА АБОРДАЖ!", "ЙО-ХО-ХО!", "ТЫСЯЧА ЧЕРТЕЙ!", "ПУШКИ К БОЮ!"]
const ALIEN_SHOUTS = ["БИП-БОП!", "ЗЕМЛЯНИН!", "ИНОПЛАНЕТНО!", "КОСМОС!", "ЗАХВАТ!"]

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var walk_time: float = 0.0
var is_dead: bool = false
var is_alien: bool = false

@onready var body_visual: Node2D = $Body
@onready var left_leg: Node2D = $Body/LeftLeg
@onready var right_leg: Node2D = $Body/RightLeg
@onready var left_arm: Node2D = $Body/LeftArm
@onready var right_arm: Node2D = $Body/RightArm
@onready var head: Node2D = $Body/Head
@onready var left_eye: Polygon2D = $Body/Head/LeftEye
@onready var right_eye: Polygon2D = $Body/Head/RightEye
@onready var left_pupil: Polygon2D = $Body/Head/LeftPupil
@onready var right_pupil: Polygon2D = $Body/Head/RightPupil
@onready var mouth: Polygon2D = $Body/Head/Mouth

func _ready() -> void:
	if GameState.blaster_unlocked:
		_become_alien()

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.x = SHUFFLE_SPEED

	move_and_slide()
	_animate_walk(delta)

func _animate_walk(delta: float) -> void:
	if not body_visual:
		return
	if is_on_floor():
		walk_time += delta * WALK_ANIM_SPEED
		var swing = sin(walk_time)
		if left_leg:
			left_leg.rotation = swing * LEG_SWING
		if right_leg:
			right_leg.rotation = -swing * LEG_SWING
		if left_arm:
			left_arm.rotation = swing * ARM_SWING
		if right_arm:
			right_arm.rotation = -swing * ARM_SWING

func _on_damage_area_body_entered(body: Node2D) -> void:
	if is_dead:
		return
	if body.has_method("take_damage"):
		body.take_damage()

func take_hit() -> void:
	if is_dead:
		return
	is_dead = true
	velocity = Vector2.ZERO

	# Disable collision so zombie doesn't block anything
	set_collision_layer_value(2, false)

	# Swap eyes to X_X (funny KO face)
	_make_ko_face()

	# Spawn cartoon stars circling above head
	_spawn_stars()

	# Pick a random shout
	var shout_idx = randi() % _get_shouts().size()

	# Floating pirate shout — comic book style
	_spawn_shout(shout_idx)

	# Gruff pirate voice — Banjo-Kazooie style mumble
	if is_alien:
		_play_alien_voice(shout_idx)
	else:
		_play_pirate_voice(shout_idx)

	# Main death animation: bounce up, spin wildly, squash flat, fade
	var tween = create_tween()

	# Phase 1: Knockback bounce UP (funny launch)
	tween.set_parallel(true)
	tween.tween_property(body_visual, "position:y", body_visual.position.y - 50, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(body_visual, "rotation", PI * 2.5, 0.4).set_ease(Tween.EASE_OUT)
	tween.tween_property(body_visual, "scale", Vector2(1.2, 1.2), 0.1)
	tween.set_parallel(false)

	# Phase 2: Slam back down and squash flat like a pancake
	tween.set_parallel(true)
	tween.tween_property(body_visual, "position:y", body_visual.position.y + 10, 0.15).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property(body_visual, "scale", Vector2(2.0, 0.2), 0.15)
	tween.set_parallel(false)

	# Phase 3: Tiny bounce (cartoon squash recovery)
	tween.tween_property(body_visual, "scale", Vector2(1.5, 0.5), 0.1)

	# Phase 4: Fade out
	tween.tween_property(body_visual, "modulate:a", 0.0, 0.3)

	tween.tween_callback(queue_free)

func _get_shouts() -> Array:
	if is_alien:
		return ALIEN_SHOUTS
	return SHOUTS

# === ALIEN MODE ===

func _become_alien() -> void:
	is_alien = true

	# Recolor torso/shirt to green
	var shirt = body_visual.get_node_or_null("Shirt")
	if shirt:
		shirt.color = Color(0.2, 0.7, 0.2, 1)

	var tear1 = body_visual.get_node_or_null("ShirtTear1")
	if tear1:
		tear1.color = Color(0.3, 0.85, 0.3, 1)
	var tear2 = body_visual.get_node_or_null("ShirtTear2")
	if tear2:
		tear2.color = Color(0.3, 0.85, 0.3, 1)

	# Recolor head/face to light green
	var face = head.get_node_or_null("Face")
	if face:
		face.color = Color(0.4, 0.85, 0.3, 1)

	# Make eyes larger black ovals
	if left_eye:
		left_eye.color = Color(0.05, 0.05, 0.05, 1)
		left_eye.polygon = PackedVector2Array([
			Vector2(-7, -24), Vector2(-1, -24), Vector2(0, -21), Vector2(-1, -17),
			Vector2(-7, -17), Vector2(-8, -21)
		])
	if right_eye:
		right_eye.color = Color(0.05, 0.05, 0.05, 1)
		right_eye.polygon = PackedVector2Array([
			Vector2(1, -24), Vector2(7, -24), Vector2(8, -21), Vector2(7, -17),
			Vector2(1, -17), Vector2(0, -21)
		])

	# Hide normal pupils (alien eyes are all black)
	if left_pupil:
		left_pupil.visible = false
	if right_pupil:
		right_pupil.visible = false

	# Change mouth to small alien slit
	if mouth:
		mouth.color = Color(0.15, 0.4, 0.15, 1)
		mouth.polygon = PackedVector2Array([
			Vector2(-3, -14), Vector2(3, -14), Vector2(2, -13), Vector2(-2, -13)
		])

	# Recolor limbs green
	_recolor_limbs_green()

	# Add antenna on top of head
	_add_antenna()

func _recolor_limbs_green() -> void:
	# Left arm (sleeves and skin)
	for child_name in ["Sleeve", "Forearm", "Hand"]:
		var node = left_arm.get_node_or_null(child_name)
		if node:
			if child_name == "Sleeve":
				node.color = Color(0.25, 0.6, 0.25, 1)
			else:
				node.color = Color(0.4, 0.8, 0.3, 1)
	# Right arm
	for child_name in ["Sleeve", "Forearm", "Hand"]:
		var node = right_arm.get_node_or_null(child_name)
		if node:
			if child_name == "Sleeve":
				node.color = Color(0.28, 0.62, 0.28, 1)
			else:
				node.color = Color(0.42, 0.82, 0.32, 1)
	# Left leg
	var l_pants = left_leg.get_node_or_null("Pants")
	if l_pants:
		l_pants.color = Color(0.2, 0.5, 0.2, 1)
	var l_shoe = left_leg.get_node_or_null("Shoe")
	if l_shoe:
		l_shoe.color = Color(0.3, 0.3, 0.35, 1)
	# Right leg
	var r_pants = right_leg.get_node_or_null("Pants")
	if r_pants:
		r_pants.color = Color(0.22, 0.52, 0.22, 1)
	var r_shoe = right_leg.get_node_or_null("Shoe")
	if r_shoe:
		r_shoe.color = Color(0.32, 0.32, 0.37, 1)

func _add_antenna() -> void:
	var antenna = Node2D.new()
	antenna.name = "Antenna"
	antenna.position = Vector2(0, -28)
	head.add_child(antenna)

	# Thin line (stalk)
	var stalk = Polygon2D.new()
	stalk.color = Color(0.4, 0.85, 0.3, 1)
	stalk.polygon = PackedVector2Array([
		Vector2(-0.5, 0), Vector2(0.5, 0), Vector2(1, -10), Vector2(-1, -10)
	])
	antenna.add_child(stalk)

	# Ball on top
	var ball = Polygon2D.new()
	ball.color = Color(0.2, 1.0, 0.3, 1)
	ball.polygon = PackedVector2Array([
		Vector2(3, -10), Vector2(2.1, -7.9), Vector2(0, -7),
		Vector2(-2.1, -7.9), Vector2(-3, -10),
		Vector2(-2.1, -12.1), Vector2(0, -13),
		Vector2(2.1, -12.1)
	])
	antenna.add_child(ball)

	# Glow around ball
	var glow = Polygon2D.new()
	glow.color = Color(0.2, 1.0, 0.3, 0.3)
	glow.polygon = PackedVector2Array([
		Vector2(5, -10), Vector2(3.5, -6.5), Vector2(0, -5),
		Vector2(-3.5, -6.5), Vector2(-5, -10),
		Vector2(-3.5, -13.5), Vector2(0, -15),
		Vector2(3.5, -13.5)
	])
	glow.z_index = -1
	antenna.add_child(glow)

func _make_ko_face() -> void:
	# Replace yellow eyes with X shapes (funny KO face)
	if left_eye:
		left_eye.color = Color(1, 1, 1, 1)
	if right_eye:
		right_eye.color = Color(1, 1, 1, 1)
	# Make pupils into X marks by changing color to stand out
	if left_pupil:
		left_pupil.visible = true
		left_pupil.color = Color(0.1, 0.1, 0.1, 1)
		# Move to center of eye for "X" effect
		left_pupil.polygon = PackedVector2Array([
			Vector2(-6, -23), Vector2(-5, -23), Vector2(-4, -21.5),
			Vector2(-3, -23), Vector2(-2, -23), Vector2(-3.5, -21),
			Vector2(-2, -19), Vector2(-3, -19), Vector2(-4, -20.5),
			Vector2(-5, -19), Vector2(-6, -19), Vector2(-4.5, -21)
		])
	if right_pupil:
		right_pupil.visible = true
		right_pupil.color = Color(0.1, 0.1, 0.1, 1)
		right_pupil.polygon = PackedVector2Array([
			Vector2(2, -23), Vector2(3, -23), Vector2(4, -21.5),
			Vector2(5, -23), Vector2(6, -23), Vector2(4.5, -21),
			Vector2(6, -19), Vector2(5, -19), Vector2(4, -20.5),
			Vector2(3, -19), Vector2(2, -19), Vector2(3.5, -21)
		])
	# Open mouth wide — shocked O face
	if mouth:
		mouth.color = Color(0.15, 0.05, 0.05, 1)
		mouth.polygon = PackedVector2Array([
			Vector2(-3, -16), Vector2(3, -16),
			Vector2(4, -13), Vector2(3, -10),
			Vector2(-3, -10), Vector2(-4, -13)
		])

func _spawn_stars() -> void:
	# Add spinning cartoon stars above the head
	var stars_container = Node2D.new()
	stars_container.name = "Stars"
	stars_container.position = Vector2(0, -38)
	body_visual.add_child(stars_container)

	var star_color = Color(0.2, 1.0, 0.3, 1) if is_alien else Color(1, 0.9, 0.2, 1)

	for i in range(3):
		var star = Polygon2D.new()
		star.color = star_color
		# Small 4-pointed star
		star.polygon = PackedVector2Array([
			Vector2(0, -4), Vector2(1, -1),
			Vector2(4, 0), Vector2(1, 1),
			Vector2(0, 4), Vector2(-1, 1),
			Vector2(-4, 0), Vector2(-1, -1)
		])
		var angle = (TAU / 3.0) * i
		star.position = Vector2(cos(angle) * 10, sin(angle) * 5)
		stars_container.add_child(star)

	# Spin the stars
	var star_tween = create_tween()
	star_tween.set_loops(2)
	star_tween.tween_property(stars_container, "rotation", TAU, 0.5).from(0.0)

func _spawn_shout(shout_idx: int) -> void:
	# Comic-book style floating text that pops up and drifts away
	var shouts = _get_shouts()
	var shout_text = shouts[shout_idx]

	var label = Label.new()
	label.text = shout_text
	label.add_theme_font_size_override("font_size", 28)
	if is_alien:
		label.add_theme_color_override("font_color", Color(0.2, 1, 0.3, 1))
		label.add_theme_color_override("font_shadow_color", Color(0, 0.4, 0.1, 1))
	else:
		label.add_theme_color_override("font_color", Color(1, 0.95, 0.1, 1))
		label.add_theme_color_override("font_shadow_color", Color(0.8, 0.1, 0.05, 1))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-50, -70)

	# Add to level (not to zombie body, so it stays after queue_free)
	var level = get_parent()
	if level:
		var popup = Node2D.new()
		popup.global_position = global_position
		popup.z_index = 10
		popup.add_child(label)
		level.add_child(popup)

		# Animate: pop in big, float up, fade out
		popup.scale = Vector2(0.3, 0.3)
		var tween = popup.create_tween()
		tween.set_parallel(true)
		tween.tween_property(popup, "scale", Vector2(1.2, 1.2), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property(popup, "position:y", popup.position.y - 60, 1.0).set_ease(Tween.EASE_OUT)
		tween.set_parallel(false)
		tween.tween_property(popup, "modulate:a", 0.0, 0.4)
		tween.tween_callback(popup.queue_free)

func _play_pirate_voice(shout_idx: int) -> void:
	# Banjo-Kazooie style gruff pirate voice — syllable-based formant synthesis
	# Each shout has a pitch pattern matching the word's rhythm and intonation
	var sample_rate = 22050.0

	# Syllable definitions: [pitch_hz, duration_sec, vowel_brightness]
	# vowel_brightness: 0.0 = dark "o/u", 0.5 = mid "a", 1.0 = bright "i/e"
	var voice_patterns = [
		# КАРАМБА! — KA-RAM-BA! (punchy, last syllable strong)
		[[120, 0.12, 0.5], [150, 0.14, 0.5], [105, 0.2, 0.3]],
		# НА АБОРДАЖ! — NA A-BOR-DAZH! (rising dramatic command)
		[[130, 0.1, 0.5], [140, 0.08, 0.5], [160, 0.14, 0.3], [115, 0.2, 0.4]],
		# ЙО-ХО-ХО! — YO-KHO-KHO! (bouncy, fun)
		[[135, 0.14, 0.2], [145, 0.12, 0.2], [155, 0.16, 0.2]],
		# ТЫСЯЧА ЧЕРТЕЙ! — TY-SYA-CHA CHER-TEY! (dramatic rising)
		[[125, 0.09, 0.8], [135, 0.09, 0.6], [145, 0.09, 0.5], [160, 0.12, 0.7], [120, 0.18, 0.9]],
		# ПУШКИ К БОЮ! — PUSH-KI K-BO-YU! (military bark)
		[[140, 0.12, 0.3], [170, 0.08, 0.9], [150, 0.12, 0.2], [115, 0.16, 0.3]],
	]

	var syllables = voice_patterns[shout_idx % voice_patterns.size()]
	_play_voice_syllables(syllables, false)

func _play_alien_voice(shout_idx: int) -> void:
	# Higher pitch, more robotic (square wave, less vibrato), occasional beep tones
	var sample_rate = 22050.0

	var voice_patterns = [
		# БИП-БОП! — BEEP-BOP! (robotic staccato)
		[[250, 0.08, 0.8], [200, 0.1, 0.3]],
		# ЗЕМЛЯНИН! — ZEM-LYA-NIN! (dramatic alien)
		[[220, 0.1, 0.6], [260, 0.08, 0.7], [200, 0.12, 0.9]],
		# ИНОПЛАНЕТНО! — I-NO-PLA-NET-NO! (long word)
		[[240, 0.07, 0.9], [230, 0.07, 0.3], [260, 0.08, 0.5], [280, 0.07, 0.8], [210, 0.1, 0.3]],
		# КОСМОС! — KOS-MOS! (deep space)
		[[200, 0.12, 0.3], [230, 0.14, 0.3]],
		# ЗАХВАТ! — ZA-KHVAT! (aggressive)
		[[250, 0.1, 0.5], [280, 0.12, 0.4]],
	]

	var syllables = voice_patterns[shout_idx % voice_patterns.size()]
	_play_voice_syllables(syllables, true)

func _play_voice_syllables(syllables: Array, robotic: bool) -> void:
	var sample_rate = 22050.0

	# Calculate total audio duration
	var total_duration = 0.0
	for syl in syllables:
		total_duration += syl[1] + 0.03  # syllable + gap
	total_duration += 0.1  # padding

	var player = AudioStreamPlayer.new()
	var gen = AudioStreamGenerator.new()
	gen.mix_rate = sample_rate
	gen.buffer_length = total_duration + 0.2
	player.stream = gen
	player.volume_db = -4.0

	var level = get_parent()
	if not level:
		return
	level.add_child(player)
	player.play()

	var playback = player.get_stream_playback()
	if not playback:
		player.queue_free()
		return

	var prev_sample = 0.0
	var rng = RandomNumberGenerator.new()
	rng.seed = randi()

	for syl in syllables:
		var base_freq = float(syl[0])
		var duration = float(syl[1])
		var brightness = float(syl[2])
		var num_samples = int(sample_rate * duration)
		var phase = 0.0

		# Filter coefficient: brighter vowel = less filtering (more harmonics)
		var filter_coeff = 0.55 - brightness * 0.3  # 0.55 (dark) to 0.25 (bright)

		for i in range(num_samples):
			var t = 1.0 / sample_rate
			var pos = float(i) / float(num_samples)

			var freq: float
			if robotic:
				# Less vibrato, more precise pitch
				var vibrato = sin(float(i) * 0.02) * 1.0
				freq = base_freq + vibrato
			else:
				# Pitch wobble — gruff pirate vibrato
				var vibrato = sin(float(i) * 0.04) * 3.0
				var jitter = rng.randf_range(-2.0, 2.0)
				freq = base_freq + vibrato + jitter

			phase += freq * t
			if phase > 1.0:
				phase -= 1.0

			var raw: float
			if robotic:
				# Square wave for robotic sound
				raw = 1.0 if phase < 0.5 else -1.0
			else:
				# Sawtooth wave — rich harmonics, voice-like source
				raw = 2.0 * phase - 1.0
				# Add a bit of pulse character for gruffness
				var pulse = 1.0 if phase < 0.35 else -1.0
				raw = raw * 0.6 + pulse * 0.4

			# Simple low-pass filter — shapes the "vowel"
			var filtered = prev_sample * filter_coeff + raw * (1.0 - filter_coeff)
			prev_sample = filtered

			# Amplitude envelope: quick attack, sustain, quick release
			var env = 1.0
			if pos < 0.08:
				env = pos / 0.08
			elif pos > 0.75:
				env = (1.0 - pos) / 0.25
			env = clampf(env, 0.0, 1.0)

			# Slight volume accent on stressed syllables (lower pitch = louder)
			var vol = 0.4 + (1.0 - base_freq / 300.0) * 0.15

			var sample = filtered * vol * env
			sample = clampf(sample, -1.0, 1.0)
			playback.push_frame(Vector2(sample, sample))

		# Short silence between syllables
		for i in range(int(sample_rate * 0.03)):
			prev_sample *= 0.8  # quick fade
			playback.push_frame(Vector2(prev_sample * 0.1, prev_sample * 0.1))

	# Auto-cleanup
	var cleanup_tween = level.create_tween()
	cleanup_tween.tween_interval(total_duration + 0.5)
	cleanup_tween.tween_callback(player.queue_free)
