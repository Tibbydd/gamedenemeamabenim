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

func setup(enemy: EnemyBase3D) -> void:
	owner_enemy = enemy
	GameEvents.player_noise_made.connect(_on_player_noise_made)

func update_senses(player: PlayerControllerFPS, delta: float) -> void:
	time_since_seen += delta
	time_since_heard += delta
	can_see_player = false
	if not owner_enemy or not player:
		return
	var to_player := player.global_position + Vector3.UP * 1.2 - (owner_enemy.global_position + Vector3.UP * 1.2)
	var distance := to_player.length()
	if distance > sight_range:
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
		last_heard_position = noise_position
		last_known_position = noise_position
		has_last_known_position = true
		time_since_heard = 0.0
