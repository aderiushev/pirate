extends Node

enum Weapon { SWORD, PISTOL, GUN, BLASTER }

signal coins_changed(new_total: int)
signal health_changed(new_health: int)
signal power_up_activated(type: String)
signal power_up_expired(type: String)
signal player_died
signal weapon_changed(weapon: int)

var coins: int = 0
var health: int = 5
var max_health: int = 5
var current_level: int = 1
var levels_unlocked: int = 1

var current_weapon: int = Weapon.SWORD
var weapons_unlocked: Array[int] = [Weapon.SWORD]
var blaster_unlocked: bool = false
var pending_next_level: int = 0

var shield_active: bool = false
var rapid_fire_active: bool = false
var super_jump_active: bool = false

func add_coins(amount: int = 1) -> void:
	coins += amount
	coins_changed.emit(coins)

func take_damage() -> bool:
	if shield_active:
		shield_active = false
		power_up_expired.emit("shield")
		return false
	health -= 1
	health_changed.emit(health)
	if health <= 0:
		player_died.emit()
		return true
	return false

func reset_for_level() -> void:
	health = max_health
	shield_active = false
	rapid_fire_active = false
	super_jump_active = false
	health_changed.emit(health)

func complete_level() -> void:
	if current_level >= levels_unlocked:
		levels_unlocked = current_level + 1
	# Unlock weapons based on level completed
	if current_level >= 1 and Weapon.PISTOL not in weapons_unlocked:
		weapons_unlocked.append(Weapon.PISTOL)
	if current_level >= 2 and Weapon.GUN not in weapons_unlocked:
		weapons_unlocked.append(Weapon.GUN)
	if current_level >= 3 and Weapon.BLASTER not in weapons_unlocked:
		weapons_unlocked.append(Weapon.BLASTER)
		blaster_unlocked = true

func select_weapon(weapon: int) -> void:
	current_weapon = weapon
	weapon_changed.emit(weapon)

func reset_game() -> void:
	coins = 0
	health = max_health
	current_level = 1
	current_weapon = Weapon.SWORD
	weapons_unlocked = [Weapon.SWORD]
	blaster_unlocked = false
	pending_next_level = 0
	shield_active = false
	rapid_fire_active = false
	super_jump_active = false
	coins_changed.emit(coins)
	health_changed.emit(health)
