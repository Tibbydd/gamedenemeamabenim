extends Node
class_name DynamicWorldSystem

var recent_coolant_events: Array[Dictionary] = []
var recent_electric_events: Array[Dictionary] = []

func _ready() -> void:
	GameEvents.environment_impulse_made.connect(_on_environment_impulse_made)

func _on_environment_impulse_made(position: Vector3, radius: float, force: float, source: Node, reason: String) -> void:
	_update_combo_memory(position, radius, force, reason)
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

func _process(delta: float) -> void:
	_decay_events(recent_coolant_events, delta)
	_decay_events(recent_electric_events, delta)

func _update_combo_memory(position: Vector3, radius: float, force: float, reason: String) -> void:
	if reason.find("coolant") >= 0:
		recent_coolant_events.append({"position": position, "radius": max(radius, 2.5), "time": 12.0})
		_try_coolant_arc_combo(position, radius, force, recent_electric_events)
	elif reason.find("electric") >= 0 or reason.find("shock") >= 0:
		recent_electric_events.append({"position": position, "radius": max(radius, 2.0), "time": 4.0})
		_try_coolant_arc_combo(position, radius, force, recent_coolant_events)

func _try_coolant_arc_combo(position: Vector3, radius: float, force: float, other_events: Array[Dictionary]) -> void:
	for event in other_events:
		var other_position: Vector3 = event["position"]
		var other_radius := float(event["radius"])
		if other_position.distance_to(position) > other_radius + radius:
			continue
		GameEvents.request_sound("hazard_electric", position.lerp(other_position, 0.5), 1.0)
		apply_impulse(position.lerp(other_position, 0.5), max(radius, other_radius) + 1.5, max(force, 8.0) * 1.25, self, "coolant_arc_combo")
		break

func _decay_events(events: Array[Dictionary], delta: float) -> void:
	for index in range(events.size() - 1, -1, -1):
		var event := events[index]
		event["time"] = float(event["time"]) - delta
		if float(event["time"]) <= 0.0:
			events.remove_at(index)
		else:
			events[index] = event
