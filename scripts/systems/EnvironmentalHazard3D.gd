extends StaticBody3D
class_name EnvironmentalHazard3D

var hazard_id: String = "hazard"
var hazard_type: String = "blast"
var armed: bool = true
var trigger_damage: float = 10.0
var effect_radius: float = 3.0
var effect_damage: float = 55.0
var effect_force: float = 8.0
var mesh_instance: MeshInstance3D

func configure(new_id: String, new_type: String, size: Vector3, color: Color, radius: float, damage: float, force: float, threshold: float = 10.0) -> void:
	hazard_id = new_id
	hazard_type = new_type
	effect_radius = radius
	effect_damage = damage
	effect_force = force
	trigger_damage = threshold
	_build_body(size, color)

func _ready() -> void:
	add_to_group("dynamic_environment")
	collision_layer = 1
	collision_mask = 1 | 8

func use(_actor: Node) -> void:
	if hazard_type in ["steam", "pressure_dump", "crusher"]:
		activate("manual_use")

func receive_generic_hit(damage: float, _hit_position: Vector3, _hit_direction: Vector3) -> void:
	if damage >= trigger_damage:
		activate("projectile")

func apply_environment_impulse(_origin: Vector3, force: float, _radius: float, reason: String) -> void:
	if force >= trigger_damage * 0.45:
		activate(reason)

func activate(reason: String) -> void:
	if not armed:
		return
	armed = false
	_update_visual_active()
	GameEvents.request_sound("hazard_" + hazard_type, global_position, 1.0)
	GameEvents.emit_environment_impulse(global_position, effect_radius, effect_force, self, hazard_type + "_" + reason)
	if hazard_type == "steam":
		GameEvents.request_visibility_haze(global_position, effect_radius + 1.5, 8.0, 0.65)
	elif hazard_type == "coolant":
		GameEvents.request_visibility_haze(global_position, effect_radius, 10.0, 0.35)
	_damage_nearby_enemies()
	_damage_nearby_player()
	if hazard_type in ["blast", "coolant"]:
		queue_free()

func _damage_nearby_enemies() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not (enemy is Node3D):
			continue
		var enemy_node := enemy as Node3D
		var distance := enemy_node.global_position.distance_to(global_position)
		if distance > effect_radius:
			continue
		var falloff := clamp(1.0 - distance / effect_radius, 0.2, 1.0)
		var direction := (enemy_node.global_position - global_position).normalized()
		if direction.length() < 0.01:
			direction = Vector3.UP
		if enemy.has_method("receive_generic_hit"):
			enemy.receive_generic_hit(effect_damage * falloff, global_position, direction)
		if enemy.has_method("apply_shove"):
			enemy.apply_shove(global_position, effect_force * falloff, 0.35)

func _damage_nearby_player() -> void:
	for node in get_tree().get_nodes_in_group("player"):
		if not (node is PlayerControllerFPS):
			continue
		var player := node as PlayerControllerFPS
		var distance := player.global_position.distance_to(global_position)
		if distance > effect_radius:
			continue
		var falloff := clamp(1.0 - distance / effect_radius, 0.15, 1.0)
		var zone := PlayerHealthBodyParts.PART_CHEST
		if hazard_type == "steam":
			zone = PlayerHealthBodyParts.PART_HEAD
		elif hazard_type == "crusher":
			zone = PlayerHealthBodyParts.PART_STOMACH
		player.health.apply_damage(zone, effect_damage * 0.35 * falloff, hazard_type)

func _build_body(size: Vector3, color: Color) -> void:
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	add_child(collision)
	mesh_instance = MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _make_material(color, 0.22)
	add_child(mesh_instance)

func _update_visual_active() -> void:
	if not mesh_instance:
		return
	var color := Color(1.0, 0.4, 0.12)
	if hazard_type == "electric":
		color = Color(0.25, 0.7, 1.0)
	elif hazard_type == "steam":
		color = Color(0.85, 0.9, 0.85)
	elif hazard_type == "pressure_dump":
		color = Color(0.35, 0.65, 0.8)
	elif hazard_type == "crusher":
		color = Color(0.9, 0.1, 0.08)
	elif hazard_type == "coolant":
		color = Color(0.35, 0.95, 0.85)
	mesh_instance.material_override = _make_material(color, 0.85)

func _make_material(color: Color, emission_energy: float) -> StandardMaterial3D:
	return EffectMaterialCache.get_material(color, emission_energy)
