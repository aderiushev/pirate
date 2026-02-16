extends Control

const LEVEL_SCENES = {
	1: "res://scenes/levels/level_1.tscn",
	2: "res://scenes/levels/level_2.tscn",
	3: "res://scenes/levels/level_3.tscn",
}

var weapon_buttons: Array = []

func _ready() -> void:
	_build_ui()
	# Pulsing title
	var title = $Title
	title.pivot_offset = title.size / 2
	var tween = create_tween().set_loops()
	tween.tween_property(title, "scale", Vector2(1.15, 1.15), 0.4)
	tween.tween_property(title, "scale", Vector2(1.0, 1.0), 0.4)

func _build_ui() -> void:
	for i in range(4):
		var weapon_id = i
		var is_unlocked = weapon_id in GameState.weapons_unlocked
		var is_current = weapon_id == GameState.current_weapon

		var btn = $Weapons.get_node("Weapon" + str(i))
		weapon_buttons.append(btn)

		# Build weapon icon (big, centered)
		var icon = btn.get_node("Icon")
		_build_weapon_icon(icon, weapon_id)

		if not is_unlocked:
			btn.disabled = true
			btn.modulate = Color(0.4, 0.4, 0.4, 1)
			var lock_label = btn.get_node("LockLabel")
			lock_label.visible = true
		else:
			btn.disabled = false
			btn.modulate = Color(1, 1, 1, 1)
			var lock_label = btn.get_node("LockLabel")
			lock_label.visible = false

		if is_current and is_unlocked:
			btn.modulate = Color(1, 0.95, 0.6, 1)

		btn.pressed.connect(_on_weapon_pressed.bind(weapon_id))

func _build_weapon_icon(icon_node: Node2D, weapon_id: int) -> void:
	for child in icon_node.get_children():
		child.queue_free()

	match weapon_id:
		GameState.Weapon.SWORD:
			var blade = Polygon2D.new()
			blade.color = Color(0.78, 0.8, 0.82, 1)
			blade.polygon = PackedVector2Array([
				Vector2(-2, 8), Vector2(2, 8), Vector2(1.5, -12), Vector2(0, -15), Vector2(-1.5, -12)
			])
			icon_node.add_child(blade)
			var guard = Polygon2D.new()
			guard.color = Color(0.7, 0.65, 0.2, 1)
			guard.polygon = PackedVector2Array([
				Vector2(-6, 8), Vector2(6, 8), Vector2(6, 10), Vector2(-6, 10)
			])
			icon_node.add_child(guard)
			var handle = Polygon2D.new()
			handle.color = Color(0.45, 0.25, 0.08, 1)
			handle.polygon = PackedVector2Array([
				Vector2(-2, 10), Vector2(2, 10), Vector2(2, 18), Vector2(-2, 18)
			])
			icon_node.add_child(handle)

		GameState.Weapon.PISTOL:
			var barrel = Polygon2D.new()
			barrel.color = Color(0.28, 0.28, 0.3, 1)
			barrel.polygon = PackedVector2Array([
				Vector2(-12, -2), Vector2(10, -2), Vector2(10, 2), Vector2(-12, 2)
			])
			icon_node.add_child(barrel)
			var flare = Polygon2D.new()
			flare.color = Color(0.25, 0.25, 0.28, 1)
			flare.polygon = PackedVector2Array([
				Vector2(-14, -4), Vector2(-10, -4), Vector2(-10, 4), Vector2(-14, 4)
			])
			icon_node.add_child(flare)
			var handle = Polygon2D.new()
			handle.color = Color(0.45, 0.25, 0.08, 1)
			handle.polygon = PackedVector2Array([
				Vector2(4, 2), Vector2(8, 2), Vector2(7, 12), Vector2(5, 12)
			])
			icon_node.add_child(handle)

		GameState.Weapon.GUN:
			var barrel = Polygon2D.new()
			barrel.color = Color(0.22, 0.22, 0.25, 1)
			barrel.polygon = PackedVector2Array([
				Vector2(-15, -3), Vector2(10, -3), Vector2(10, 3), Vector2(-15, 3)
			])
			icon_node.add_child(barrel)
			var flare = Polygon2D.new()
			flare.color = Color(0.2, 0.2, 0.23, 1)
			flare.polygon = PackedVector2Array([
				Vector2(-18, -5), Vector2(-13, -5), Vector2(-13, 5), Vector2(-18, 5)
			])
			icon_node.add_child(flare)
			var gold = Polygon2D.new()
			gold.color = Color(0.92, 0.78, 0.2, 1)
			gold.polygon = PackedVector2Array([
				Vector2(-14, -4), Vector2(-12, -4), Vector2(-12, 4), Vector2(-14, 4)
			])
			icon_node.add_child(gold)
			var handle = Polygon2D.new()
			handle.color = Color(0.4, 0.22, 0.06, 1)
			handle.polygon = PackedVector2Array([
				Vector2(4, 3), Vector2(8, 3), Vector2(7, 14), Vector2(5, 14)
			])
			icon_node.add_child(handle)

		GameState.Weapon.BLASTER:
			var barrel = Polygon2D.new()
			barrel.color = Color(0.6, 0.62, 0.65, 1)
			barrel.polygon = PackedVector2Array([
				Vector2(-14, -2), Vector2(10, -2), Vector2(12, 0), Vector2(10, 2), Vector2(-14, 2)
			])
			icon_node.add_child(barrel)
			var glow_strip = Polygon2D.new()
			glow_strip.color = Color(0, 0.9, 1, 0.6)
			glow_strip.polygon = PackedVector2Array([
				Vector2(-12, -0.5), Vector2(9, -0.5), Vector2(9, 0.5), Vector2(-12, 0.5)
			])
			icon_node.add_child(glow_strip)
			var tip = Polygon2D.new()
			tip.color = Color(0, 0.9, 1, 0.8)
			tip.polygon = PackedVector2Array([
				Vector2(-14, -1.5), Vector2(-17, 0), Vector2(-14, 1.5)
			])
			icon_node.add_child(tip)
			var handle = Polygon2D.new()
			handle.color = Color(0.35, 0.35, 0.38, 1)
			handle.polygon = PackedVector2Array([
				Vector2(4, 2), Vector2(8, 2), Vector2(7, 12), Vector2(5, 12)
			])
			icon_node.add_child(handle)

func _on_weapon_pressed(weapon_id: int) -> void:
	if weapon_id not in GameState.weapons_unlocked:
		return
	GameState.select_weapon(weapon_id)

	# Update button highlights
	for i in range(weapon_buttons.size()):
		var btn = weapon_buttons[i]
		if not btn.disabled:
			if i == weapon_id:
				btn.modulate = Color(1, 0.95, 0.6, 1)
			else:
				btn.modulate = Color(1, 1, 1, 1)

	# Load next level after short delay
	await get_tree().create_timer(0.3).timeout
	var next_level = GameState.pending_next_level
	if next_level in LEVEL_SCENES:
		get_tree().change_scene_to_file(LEVEL_SCENES[next_level])
	else:
		get_tree().change_scene_to_file(LEVEL_SCENES[GameState.current_level])
