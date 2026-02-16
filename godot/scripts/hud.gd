extends CanvasLayer

@onready var coin_label: Label = $CoinLabel
@onready var coin_icon: Polygon2D = $CoinIcon
var hearts: Array[Polygon2D] = []
var power_up_labels: Dictionary = {}

func _ready() -> void:
	_create_hearts()
	_create_power_up_indicators()
	_update_coin_display(GameState.coins)
	_update_hearts(GameState.health)
	GameState.coins_changed.connect(_update_coin_display)
	GameState.health_changed.connect(_update_hearts)
	GameState.power_up_activated.connect(_on_power_up_activated)
	GameState.power_up_expired.connect(_on_power_up_expired)

func _create_hearts() -> void:
	for i in range(GameState.max_health):
		var heart = Polygon2D.new()
		heart.polygon = PackedVector2Array([
			Vector2(0, 4), Vector2(-5, -2), Vector2(-7, -6),
			Vector2(-5, -9), Vector2(-3, -9), Vector2(0, -6),
			Vector2(3, -9), Vector2(5, -9), Vector2(7, -6),
			Vector2(5, -2)
		])
		heart.color = Color(0.9, 0.15, 0.15, 1)
		heart.scale = Vector2(4.0, 4.0)
		heart.position = Vector2(1700 + i * 55, 50)
		add_child(heart)
		hearts.append(heart)

func _create_power_up_indicators() -> void:
	var types = ["shield", "rapid_fire", "super_jump"]
	var colors = [Color(0.3, 0.6, 1.0), Color(1.0, 0.6, 0.1), Color(0.2, 0.9, 0.3)]
	var labels_text = ["🛡️", "🔥", "🦘"]
	for i in range(types.size()):
		var label = Label.new()
		label.text = labels_text[i]
		label.add_theme_font_size_override("font_size", 48)
		label.add_theme_color_override("font_color", colors[i])
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
		label.add_theme_constant_override("shadow_offset_x", 2)
		label.add_theme_constant_override("shadow_offset_y", 2)
		label.position = Vector2(1700 + i * 110, 85)
		label.visible = false
		add_child(label)
		power_up_labels[types[i]] = label

func _update_coin_display(total: int) -> void:
	coin_label.text = str(total)
	var tween = create_tween()
	tween.tween_property(coin_label, "scale", Vector2(1.3, 1.3), 0.1)
	tween.tween_property(coin_label, "scale", Vector2(1.0, 1.0), 0.1)

func _update_hearts(current_health: int) -> void:
	for i in range(hearts.size()):
		if i < current_health:
			hearts[i].color = Color(0.9, 0.15, 0.15, 1)
		else:
			hearts[i].color = Color(0.4, 0.4, 0.4, 0.5)
			if i == current_health:
				var tween = create_tween()
				tween.tween_property(hearts[i], "position:x", hearts[i].position.x - 5, 0.05)
				tween.tween_property(hearts[i], "position:x", hearts[i].position.x + 5, 0.05)
				tween.tween_property(hearts[i], "position:x", hearts[i].position.x, 0.05)

func _on_power_up_activated(type: String) -> void:
	if type in power_up_labels:
		power_up_labels[type].visible = true
		var label = power_up_labels[type]
		var tween = create_tween().set_loops()
		tween.tween_property(label, "modulate:a", 0.5, 0.4)
		tween.tween_property(label, "modulate:a", 1.0, 0.4)

func _on_power_up_expired(type: String) -> void:
	if type in power_up_labels:
		power_up_labels[type].visible = false
