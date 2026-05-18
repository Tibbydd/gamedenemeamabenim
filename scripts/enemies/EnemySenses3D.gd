extends Node
class_name EnemySenses3D

var owner_enemy: EnemyBase3D
var sight_range: float = 28.0
var hearing_sensitivity: float = 1.0
var field_of_view_degrees: float = 115.0
var can_see_player: bool = false
var has_last_known_position: bool = false
var last_known_position: Vector3 = Vector3.ZERO
var last_heard_position: Vector3 = Vector3.ZERO
var time_since_seen: float = 999.0
var time_since_heard: float = 999.0
var last_noise_time: float = 999.0
var triangulated_timer: float = 0.0
var sighting_report_cooldown: float = 0.0
var active_hazes: Array[Dictionary] = []

func setup(enemy: EnemyBase3D) -> void:
	owner_enemy = enemy
	GameEvents.player_noise_made.connect(_on_player_noise_made)
	GameEvents.enemy_sighting_reported.connect(_on_enemy_sighting_reported)
	GameEvents.visibility_haze_requested.connect(_on_visibility_haze_requested)

func update_senses(player: PlayerControllerFPS, delta: float) -> void:
	time_since_seen += delta
	time_since_heard += delta
	last_noise_time += delta
	triangulated_timer = max(0.0, triangulated_timer - delta)
	sighting_report_cooldown = max(0.0, sighting_report_cooldown - delta)
	_update_hazes(delta)
	can_see_player = false
	if not owner_enemy or not player:
		return
	var to_player := player.global_position + Vector3.UP * 1.2 - (owner_enemy.global_position + Vector3.UP * 1.2)
	var distance := to_player.length()
	var effective_sight_range := sight_range * _player_visibility_modifier(player) * _haze_modifier(player.global_position)
	if distance > effective_sight_range:
		return
	var forward := -owner_enemy.global_transform.basis.z
	var angle := rad_to_deg(forward.angle_to(to_player.normalized()))
	if angle > field_of_view_degrees * 0.5:
		return
	if _has_line_of_sight(player):
		can_see_player = true
		has_last_known_position = true
		last_known_position = player.global_position
		time_since_seen = 0.0
		if sighting_report_cooldown <= 0.0:
			sighting_report_cooldown = 1.2
			GameEvents.report_enemy_sighting(player.global_position, owner_enemy, 12.0)

func get_best_known_position(player: PlayerControllerFPS) -> Vector3:
	if can_see_player and player:
		return player.global_position
	if time_since_heard < time_since_seen and time_since_heard < 8.0:
		return last_heard_position
	return last_known_position

func knows_any_position() -> bool:
	return has_last_known_position or time_since_heard < 8.0

func _has_line_of_sight(player: PlayerControllerFPS) -> bool:
	var start := owner_enemy.global_position + Vector3.UP * 1.45
	var end := player.global_position + Vector3.UP * 1.2
	var query := PhysicsRayQueryParameters3D.create(start, end)
	query.exclude = [owner_enemy.get_rid()]
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var hit := owner_enemy.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return true
	var collider = hit.get("collider")
	return collider == player

func _on_player_noise_made(noise_position: Vector3, loudness: float) -> void:
	if not owner_enemy:
		return
	var distance := owner_enemy.global_position.distance_to(noise_position)
	if distance <= loudness * hearing_sensitivity:
		if last_noise_time <= 2.0 and last_heard_position.distance_to(noise_position) > 1.2:
			triangulated_timer = 4.0
		last_noise_time = 0.0
		last_heard_position = noise_position
		last_known_position = noise_position
		has_last_known_position = true
		time_since_heard = 0.0

func _on_enemy_sighting_reported(position: Vector3, source: Node, radius: float) -> void:
	if not owner_enemy or source == owner_enemy:
		return
	if owner_enemy.global_position.distance_to(position) > radius:
		return
	last_known_position = position
	last_heard_position = position
	has_last_known_position = true
	time_since_heard = min(time_since_heard, 1.0)
	triangulated_timer = max(triangulated_timer, 2.0)

func _on_visibility_haze_requested(position: Vector3, radius: float, duration: float, strength: float) -> void:
	active_hazes.append({"position": position, "radius": radius, "time": duration, "strength": strength})

func _update_hazes(delta: float) -> void:
	for index in range(active_hazes.size() - 1, -1, -1):
		var haze := active_hazes[index]
		haze["time"] = float(haze["time"]) - delta
		if float(haze["time"]) <= 0.0:
			active_hazes.remove_at(index)
		else:
			active_hazes[index] = haze

func _haze_modifier(position: Vector3) -> float:
	var modifier := 1.0
	for haze in active_hazes:
		var haze_position: Vector3 = haze["position"]
		if haze_position.distance_to(position) <= float(haze["radius"]):
			modifier *= 1.0 - clamp(float(haze["strength"]), 0.0, 0.85)
	return clamp(modifier, 0.15, 1.0)

func _player_visibility_modifier(player: PlayerControllerFPS) -> float:
	if player and player.has_method("get_visibility_modifier"):
		var modifier := float(player.get_visibility_modifier())
		if owner_enemy and owner_enemy.archetype_traits.has("sound_driven") and player.has_wearable_module("low_light_filter"):
			modifier += 0.45
		return clamp(modifier, 0.3, 1.7)
	return 1.0

func has_recent_triangulation() -> bool:
	return triangulated_timer > 0.0
