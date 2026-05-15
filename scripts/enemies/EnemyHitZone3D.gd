extends Area3D
class_name EnemyHitZone3D

var zone_name: String = "torso"
var damage_multiplier: float = 1.0
var lethal: bool = false
var armor: float = 0.0
var health_owner: EnemyHealthHitZones

func configure(owner: EnemyHealthHitZones, new_zone_name: String, multiplier: float, is_lethal: bool, armor_value: float, shape: Shape3D, local_position: Vector3) -> void:
	health_owner = owner
	zone_name = new_zone_name
	damage_multiplier = multiplier
	lethal = is_lethal
	armor = armor_value
	position = local_position
	collision_layer = 4
	collision_mask = 0
	monitoring = true
	monitorable = true
	var collision := CollisionShape3D.new()
	collision.shape = shape
	add_child(collision)

func apply_hit(base_damage: float, hit_position: Vector3, hit_direction: Vector3, weapon_name: String) -> void:
	if health_owner:
		health_owner.receive_hit(zone_name, base_damage, damage_multiplier, lethal, armor, hit_position, hit_direction, weapon_name)
