extends Node
class_name ThreatDirector

var player: PlayerControllerFPS
var enemy_container: Node3D
var spawn_points: Array[Node3D] = []
var active_enemies: Array[EnemyBase3D] = []
var elapsed: float = 0.0
var survival_duration: float = 2400.0
var floor_route_enable_time: float = 2100.0
var floor_route_active: bool = false
var threat_level: float = 0.0
var spawn_timer: float = 4.0
var enemies_killed: int = 0
var noise_pressure: float = 0.0
var max_active_enemies: int = 18

func setup(new_player: PlayerControllerFPS, new_enemy_container: Node3D, new_spawn_points: Array[Node3D]) -> void:
	player = new_player
	enemy_container = new_enemy_container
	spawn_points = new_spawn_points
	GameEvents.enemy_killed.connect(_on_enemy_killed)
	GameEvents.player_noise_made.connect(_on_player_noise)

func set_player(new_player) -> void:
	player = new_player
	for enemy in active_enemies:
		if is_instance_valid(enemy):
			enemy.set_target(player)

func _process(delta: float) -> void:
	if not GameEvents.run_active or not player:
		return
	elapsed += delta
	noise_pressure = max(0.0, noise_pressure - delta * 0.12)
	_cleanup_dead_enemies()
	_update_threat()
	if not floor_route_active and elapsed >= floor_route_enable_time:
		floor_route_active = true
		GameEvents.report_floor_route_available()
	if elapsed >= survival_duration:
		GameEvents.end_run(true, "secured this floor long enough to move on")
		return
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		_spawn_pressure_wave()
		spawn_timer = _next_spawn_interval()

func _update_threat() -> void:
	var time_pressure := elapsed / survival_duration
	var kill_pressure := enemies_killed * 0.035
	var corruption_pressure := player.mental.corruption / 180.0 if player.mental else 0.0
	threat_level = clamp(time_pressure + kill_pressure + noise_pressure + corruption_pressure, 0.0, 1.0)
	GameEvents.report_threat_changed(threat_level)

func _spawn_pressure_wave() -> void:
	if active_enemies.size() >= max_active_enemies:
		return
	var wave_size := 1 + int(threat_level * 3.0)
	if randf() < threat_level:
		wave_size += 1
	wave_size = min(wave_size, max_active_enemies - active_enemies.size())
	for i in range(wave_size):
		_spawn_enemy()

func _spawn_enemy() -> void:
	if spawn_points.is_empty() or not enemy_container:
		return
	var spawn := _pick_spawn_point()
	spawn_enemy_at(spawn.global_position)

func spawn_enemy_at(spawn_position: Vector3):
	if not enemy_container:
		return null
	var enemy := EnemyBase3D.new()
	enemy.global_position = spawn_position
	enemy_container.add_child(enemy)
	enemy.set_target(player)
	active_enemies.append(enemy)
	return enemy

func _pick_spawn_point() -> Node3D:
	var best_point := spawn_points[0]
	var best_score := -99999.0
	for point in spawn_points:
		var distance := point.global_position.distance_to(player.global_position)
		var score := distance + randf_range(-6.0, 6.0)
		if distance < 8.0:
			score -= 100.0
		if score > best_score:
			best_score = score
			best_point = point
	return best_point

func _next_spawn_interval() -> float:
	return lerp(24.0, 5.0, threat_level)

func _cleanup_dead_enemies() -> void:
	for i in range(active_enemies.size() - 1, -1, -1):
		if not is_instance_valid(active_enemies[i]) or active_enemies[i].dead:
			active_enemies.remove_at(i)

func _on_enemy_killed(enemy: Node, cause: String) -> void:
	enemies_killed += 1
	noise_pressure = min(0.45, noise_pressure + 0.04)

func _on_player_noise(position: Vector3, loudness: float) -> void:
	noise_pressure = min(0.35, noise_pressure + loudness / 600.0)

func get_remaining_time() -> float:
	return max(0.0, survival_duration - elapsed)
