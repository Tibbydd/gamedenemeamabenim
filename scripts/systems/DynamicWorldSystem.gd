extends Node
class_name DynamicWorldSystem

func _ready() -> void:
	GameEvents.environment_impulse_made.connect(_on_environment_impulse_made)

func _on_environment_impulse_made(position: Vector3, radius: float, force: float, source: Node, reason: String) -> void:
	apply_impulse(position, radius, force, source, reason)

func apply_impulse(position: Vector3, radius: float, force: float, source: Node, reason: String) -> void:
	if radius <= 0.0 or force <= 0.0:
		return
	for node in get_tree().get_nodes_in_group("dynamic_environment"):
		if not (node is Node3D) or node == source:
			continue
		var node3d := node as Node3D
		var distance := node3d.global_position.distance_to(position)
		if distance > radius:
			continue
		var falloff := 1.0 - distance / radius
		var local_force := force * clamp(falloff, 0.0, 1.0)
		if node.has_method("apply_environment_impulse"):
			node.apply_environment_impulse(position, local_force, radius, reason)
		elif node is RigidBody3D:
			var body := node as RigidBody3D
			var direction := (node3d.global_position - position).normalized()
			if direction.length() < 0.01:
				direction = Vector3.UP
			body.apply_central_impulse(direction * local_force)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not (enemy is Node3D) or enemy == source:
			continue
		var enemy_node := enemy as Node3D
		var distance := enemy_node.global_position.distance_to(position)
		if distance > radius:
			continue
		if enemy.has_method("apply_shove"):
			enemy.apply_shove(position, force * 0.35, 0.18)
