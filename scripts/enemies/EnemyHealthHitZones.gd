extends Node
class_name EnemyHealthHitZones

signal died(cause: String)
signal damaged(zone_name: String, final_damage: float)

var enemy: EnemyBase3D
var max_health: float = 65.0
var health: float = 65.0
var is_dead: bool = false
var leg_impairment: float = 0.0
var attack_impairment: float = 0.0
var armor_profile: Dictionary = {}

func setup(new_enemy: EnemyBase3D, definition: Dictionary = {}) -> void:
	enemy = new_enemy
	if not definition.is_empty():
		max_health = float(definition.get("health", max_health))
		var armor: Dictionary = definition.get("armor", {})
		armor_profile = armor.duplicate(true)
	health = max_health
	_create_hit_zones()

func receive_hit(zone_name: String, base_damage: float, multiplier: float, lethal: bool, armor: float, hit_position: Vector3, _hit_direction: Vector3, weapon_name: String) -> void:
	if is_dead:
		return
	var armor_reduction := clamp(armor, 0.0, 0.85)
	var final_damage := base_damage * multiplier * (1.0 - armor_reduction)
	if lethal and base_damage >= 24.0:
		final_damage = max(final_damage, max_health * 2.0)
	if zone_name in ["left_leg", "right_leg"]:
		leg_impairment = min(0.65, leg_impairment + 0.28)
	elif zone_name in ["left_arm", "right_arm"]:
		attack_impairment = min(0.55, attack_impairment + 0.22)
	health = max(0.0, health - final_damage)
	damaged.emit(zone_name, final_damage)
	if enemy:
		enemy.on_zone_damaged(zone_name, final_damage, hit_position)
	if health <= 0.0:
		kill("%s shot with %s" % [zone_name, weapon_name])

func receive_generic_hit(base_damage: float, hit_position: Vector3, hit_direction: Vector3) -> void:
	receive_hit("torso", base_damage, 1.0, false, 0.0, hit_position, hit_direction, "generic")

func kill(cause: String) -> void:
	if is_dead:
		return
	is_dead = true
	GameEvents.report_enemy_killed(enemy, cause)
	died.emit(cause)
	if enemy:
		enemy.die(cause)

func _create_hit_zones() -> void:
	_make_zone("head", _sphere(0.23), Vector3(0, 1.72, 0), 3.0, true, _armor("head", 0.0))
	_make_zone("parasite_core", _sphere(0.19), Vector3(0, 1.12, -0.32), 3.5, true, _armor("parasite_core", 0.0))
	_make_zone("torso", _box(Vector3(0.55, 0.8, 0.35)), Vector3(0, 1.0, 0), 1.0, false, _armor("torso", 0.08))
	_make_zone("left_arm", _box(Vector3(0.22, 0.7, 0.22)), Vector3(-0.43, 1.08, 0), 0.65, false, _armor("left_arm", 0.0))
	_make_zone("right_arm", _box(Vector3(0.22, 0.7, 0.22)), Vector3(0.43, 1.08, 0), 0.65, false, _armor("right_arm", 0.0))
	_make_zone("left_leg", _box(Vector3(0.24, 0.75, 0.24)), Vector3(-0.18, 0.38, 0), 0.55, false, _armor("left_leg", 0.0))
	_make_zone("right_leg", _box(Vector3(0.24, 0.75, 0.24)), Vector3(0.18, 0.38, 0), 0.55, false, _armor("right_leg", 0.0))

func _armor(zone_name: String, fallback: float) -> float:
	return float(armor_profile.get(zone_name, fallback))

func _make_zone(zone_name: String, shape: Shape3D, local_position: Vector3, multiplier: float, lethal: bool, armor: float) -> void:
	var zone := EnemyHitZone3D.new()
	zone.name = zone_name.capitalize().replace(" ", "") + "HitZone"
	enemy.add_child(zone)
	zone.configure(self, zone_name, multiplier, lethal, armor, shape, local_position)

func _sphere(radius: float) -> SphereShape3D:
	var shape := SphereShape3D.new()
	shape.radius = radius
	return shape

func _box(size: Vector3) -> BoxShape3D:
	var shape := BoxShape3D.new()
	shape.size = size
	return shape

func get_speed_modifier() -> float:
	return clamp(1.0 - leg_impairment, 0.25, 1.0)

func get_attack_modifier() -> float:
	return clamp(1.0 - attack_impairment, 0.35, 1.0)
