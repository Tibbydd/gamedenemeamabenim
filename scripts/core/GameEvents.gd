extends Node

signal run_started
signal run_ended(success: bool, reason: String)
signal player_noise_made(position: Vector3, loudness: float)
signal enemy_killed(enemy: Node, cause: String)
signal threat_changed(threat_level: float)
signal floor_route_available
signal player_corruption_changed(value: float)
signal environment_impulse_made(position: Vector3, radius: float, force: float, source: Node, reason: String)

var run_active: bool = false
var run_success: bool = false
var run_end_reason: String = ""

func reset_run() -> void:
	run_active = true
	run_success = false
	run_end_reason = ""
	run_started.emit()

func end_run(success: bool, reason: String) -> void:
	if not run_active:
		return
	run_active = false
	run_success = success
	run_end_reason = reason
	run_ended.emit(success, reason)

func emit_player_noise(position: Vector3, loudness: float) -> void:
	if run_active:
		player_noise_made.emit(position, loudness)

func report_enemy_killed(enemy: Node, cause: String) -> void:
	enemy_killed.emit(enemy, cause)

func report_threat_changed(threat_level: float) -> void:
	threat_changed.emit(threat_level)

func report_floor_route_available() -> void:
	floor_route_available.emit()

func report_player_corruption(value: float) -> void:
	player_corruption_changed.emit(value)

func emit_environment_impulse(position: Vector3, radius: float, force: float, source: Node, reason: String) -> void:
	environment_impulse_made.emit(position, radius, force, source, reason)
