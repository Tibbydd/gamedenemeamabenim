extends Node
class_name ThreatDirector

var player: PlayerControllerFPS
var enemy_container: Node3D
var spawn_points: Array[Node3D] = []
var active_enemies: Array[EnemyBase3D] = []
var breach_waves: Array[Dictionary] = []
var elapsed: float = 0.0
var threat_ramp_reference: float = 2400.0
var threat_level: float = 0.0
var spawn_timer: float = 4.0
var enemies_killed: int = 0
var noise_pressure: float = 0.0
var max_active_enemies: int = 28
var station_floor: int = 0
var player_corruption: float = 0.0
var vent_spawn_timer: float = 18.0
var vent_warning_light: OmniLight3D
var vent_warning_origin: Vector3 = Vector3.ZERO
var vent_warning_active: bool = false
var vent_warning_flicker_elapsed: float = 0.0

func setup(new_player: PlayerControllerFPS, new_enemy_container: Node3D, new_spawn_points: Array[Node3D]) -> void:
	player = new_player
	enemy_container = new_enemy_container
	spawn_points = new_spawn_points
	GameEvents.enemy_killed.connect(_on_enemy_killed)
	GameEvents.player_noise_made.connect(_on_player_noise)
	GameEvents.player_corruption_changed.connect(_on_player_corruption_changed)
	GameEvents.objective_triggered.connect(_on_objective_triggered)
	GameEvents.objective_completed.connect(_on_objective_completed)

func set_player(new_player: PlayerControllerFPS) -> void:
	player = new_player
	for enemy in active_enemies:
		if is_instance_valid(enemy):
			enemy.set_target(player)

func set_station_floor(floor_index: int) -> void:
	station_floor = floor_index

func _process(delta: float) -> void:
	if not GameEvents.run_active or not player:
		return
	elapsed += delta
	noise_pressure = max(0.0, noise_pressure - delta * 0.12)
	_cleanup_dead_enemies()
	_update_threat()
	_update_breach_waves(delta)
	_update_vent_spawns(delta)
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		_spawn_pressure_event()
		spawn_timer = _next_spawn_interval()

func spawn_breach_wave(source_position: Vector3, enemy_count: int, duration: float, reason: String = "objective") -> void:
	if enemy_count <= 0:
		return
	var adjusted_count: int = enemy_count + int(threat_level * (player_corruption / 100.0) * 4.0)
	var wave: Dictionary = {
		"position": source_position,
		"count": adjusted_count,
		"spawned": 0,
		"duration": max(1.0, duration),
		"elapsed": 0.0,
		"spawn_timer": 0.05,
		"reason": reason
	}
	breach_waves.append(wave)
	noise_pressure = min(0.55, noise_pressure + 0.12)

func _update_threat() -> void:
	var time_pressure: float = clamp(elapsed / max(1.0, threat_ramp_reference), 0.0, 0.45)
	var kill_pressure: float = float(enemies_killed) * 0.035
	if player and player.mental:
		player_corruption = player.mental.corruption
	var corruption_pressure: float = player_corruption / 180.0
	threat_level = clamp(time_pressure + kill_pressure + noise_pressure + corruption_pressure, 0.0, 1.0)
	GameEvents.report_threat_changed(threat_level)

func _spawn_pressure_event() -> void:
	if active_enemies.size() >= max_active_enemies:
		return
	var spawn_count: int = 1 + int(threat_level * 3.0)
	if randf() < threat_level:
		spawn_count += 1
	spawn_count = min(spawn_count, max_active_enemies - active_enemies.size())
	for index in range(spawn_count):
		_spawn_enemy()

func _update_breach_waves(delta: float) -> void:
	for index in range(breach_waves.size() - 1, -1, -1):
		var wave: Dictionary = breach_waves[index]
		var duration: float = float(wave.get("duration", 30.0))
		var count: int = int(wave.get("count", 0))
		var spawned: int = int(wave.get("spawned", 0))
		var elapsed_time: float = float(wave.get("elapsed", 0.0)) + delta
		var spawn_timer_value: float = float(wave.get("spawn_timer", 0.0)) - delta
		var interval: float = max(0.45, duration / max(1.0, float(count)))
		while spawn_timer_value <= 0.0 and spawned < count and active_enemies.size() < max_active_enemies:
			var origin: Vector3 = _dictionary_vector3(wave, "position", Vector3.ZERO)
			var spawn_position: Vector3 = _pick_breach_spawn_position(origin)
			spawn_enemy_at(spawn_position)
			spawned += 1
			spawn_timer_value += interval
		if active_enemies.size() >= max_active_enemies and spawned < count:
			spawn_timer_value = min(spawn_timer_value, 0.65)
		wave["elapsed"] = elapsed_time
		wave["spawn_timer"] = spawn_timer_value
		wave["spawned"] = spawned
		breach_waves[index] = wave
		if spawned >= count and elapsed_time >= duration:
			breach_waves.remove_at(index)

func _update_vent_spawns(delta: float) -> void:
	vent_spawn_timer -= delta
	if vent_spawn_timer <= 15.0 and vent_spawn_timer > 0.0 and not vent_warning_active:
		_start_vent_warning(_pick_swarmer_vent_origin())
	if vent_warning_active:
		_update_vent_warning_light(delta)
	if vent_spawn_timer > 0.0:
		return
	vent_spawn_timer = 30.0 if threat_level > 0.6 else 45.0
	if active_enemies.size() >= max_active_enemies - 2:
		_clear_vent_warning()
		return
	var origin: Vector3 = vent_warning_origin if vent_warning_active else _pick_swarmer_vent_origin()
	_clear_vent_warning()
	var cluster_count: int = randi_range(4, 5)
	cluster_count = min(cluster_count, max_active_enemies - active_enemies.size())
	for index in range(cluster_count):
		var offset: Vector3 = Vector3(randf_range(-1.0, 1.0), 0.5, randf_range(-1.0, 1.0))
		spawn_enemy_at(origin + offset, "swarmer")
	GameEvents.request_sound("enemy_alert", origin, 0.85)

func _start_vent_warning(origin: Vector3) -> void:
	vent_warning_origin = origin
	vent_warning_active = true
	vent_warning_flicker_elapsed = 0.0
	vent_warning_light = OmniLight3D.new()
	vent_warning_light.name = "VentBreachWarning"
	vent_warning_light.light_color = Color(0.9, 0.1, 0.04)
	vent_warning_light.light_energy = 1.8
	vent_warning_light.omni_range = 2.5
	vent_warning_light.shadow_enabled = false
	if enemy_container:
		enemy_container.add_child(vent_warning_light)
	else:
		add_child(vent_warning_light)
	vent_warning_light.global_position = origin + Vector3.UP * 0.15
	GameEvents.request_sound("hazard_blast", origin, 0.35)
	if player and player.comms:
		player.comms.announce("Vent breach detected.")

func _update_vent_warning_light(delta: float) -> void:
	if not vent_warning_light or not is_instance_valid(vent_warning_light):
		return
	vent_warning_flicker_elapsed += delta
	if vent_warning_flicker_elapsed > 12.0:
		vent_warning_light.light_energy = 0.25
		return
	var phase: int = int(floor(vent_warning_flicker_elapsed / 0.5)) % 2
	vent_warning_light.light_energy = 1.8 if phase == 0 else 0.25

func _clear_vent_warning() -> void:
	if vent_warning_light and is_instance_valid(vent_warning_light):
		vent_warning_light.queue_free()
	vent_warning_light = null
	vent_warning_active = false
	vent_warning_flicker_elapsed = 0.0

func _spawn_enemy() -> void:
	if spawn_points.is_empty() or not enemy_container:
		return
	var spawn: Node3D = _pick_spawn_point()
	spawn_enemy_at(spawn.global_position)

func spawn_enemy_at(spawn_position: Vector3, forced_archetype_id: String = "") -> EnemyBase3D:
	if not enemy_container:
		return null
	var enemy: EnemyBase3D = EnemyBase3D.new()
	if forced_archetype_id.is_empty():
		enemy.archetype_id = EnemyArchetypeCatalog.pick_for_floor_and_threat(station_floor, threat_level)
	else:
		enemy.archetype_id = forced_archetype_id
	enemy.global_position = spawn_position
	enemy_container.add_child(enemy)
	enemy.set_target(player)
	active_enemies.append(enemy)
	return enemy

func _pick_spawn_point() -> Node3D:
	var best_point: Node3D = spawn_points[0]
	var best_score: float = -99999.0
	for point in spawn_points:
		var distance: float = point.global_position.distance_to(player.global_position)
		var score: float = distance + randf_range(-6.0, 6.0)
		if distance < 8.0:
			score -= 100.0
		if score > best_score:
			best_score = score
			best_point = point
	return best_point

func _pick_breach_spawn_position(source_position: Vector3) -> Vector3:
	if spawn_points.is_empty():
		return source_position + Vector3(randf_range(-4.0, 4.0), 0.0, randf_range(-4.0, 4.0))
	var best_point: Node3D = spawn_points[0]
	var best_score: float = -99999.0
	for point in spawn_points:
		var distance_to_player: float = point.global_position.distance_to(player.global_position) if player else 99.0
		var distance_to_source: float = point.global_position.distance_to(source_position)
		var score: float = distance_to_player * 1.15 - distance_to_source * 0.35 + randf_range(-4.0, 4.0)
		if distance_to_player < 9.5:
			score -= 120.0
		if score > best_score:
			best_score = score
			best_point = point
	return best_point.global_position

func _pick_swarmer_vent_origin() -> Vector3:
	var best_vent: Node3D = null
	var best_score: float = -99999.0
	for vent in get_tree().get_nodes_in_group("swarmer_vents"):
		if not (vent is Node3D):
			continue
		var vent_node: Node3D = vent as Node3D
		var distance_to_player: float = vent_node.global_position.distance_to(player.global_position) if player else 10.0
		if distance_to_player < 6.0 or distance_to_player > 18.0:
			continue
		var score: float = -abs(distance_to_player - 10.0) + randf_range(-1.5, 1.5)
		if score > best_score:
			best_score = score
			best_vent = vent_node
	if best_vent:
		return best_vent.global_position
	if not player:
		return Vector3.ZERO
	var angle: float = randf() * TAU
	var distance: float = randf_range(6.0, 12.0)
	var origin: Vector3 = player.global_position + Vector3(cos(angle), 0.0, sin(angle)) * distance
	origin.x = clamp(origin.x, -34.0, 34.0)
	origin.z = clamp(origin.z, -34.0, 34.0)
	origin.y = 0.35
	return origin

func _next_spawn_interval() -> float:
	return lerp(24.0, 5.0, threat_level)

func _cleanup_dead_enemies() -> void:
	for index in range(active_enemies.size() - 1, -1, -1):
		if not is_instance_valid(active_enemies[index]) or active_enemies[index].dead:
			active_enemies.remove_at(index)

func _on_enemy_killed(_enemy: Node, _cause: String) -> void:
	enemies_killed += 1
	noise_pressure = min(0.45, noise_pressure + 0.04)

func _on_player_noise(_position: Vector3, loudness: float) -> void:
	noise_pressure = min(0.35, noise_pressure + loudness / 600.0)

func _on_player_corruption_changed(value: float) -> void:
	player_corruption = value

func _on_objective_triggered(_objective_id: String, _objective_type: String, _sector_id: String, position: Vector3) -> void:
	spawn_breach_wave(position, randi_range(8, 10), 30.0, "objective_triggered")

func _on_objective_completed(_objective_id: String, _objective_type: String, _sector_id: String, position: Vector3) -> void:
	spawn_breach_wave(position, randi_range(8, 12), 30.0, "objective_completed")

func _dictionary_vector3(source: Dictionary, key: String, fallback: Vector3) -> Vector3:
	var raw_value: Variant = source.get(key, fallback)
	if raw_value is Vector3:
		return raw_value
	return fallback

func get_remaining_time() -> float:
	return elapsed
