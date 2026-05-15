extends Node

signal run_started
signal run_ended(success: bool, reason: String)
signal player_noise_made(position: Vector3, loudness: float)
signal enemy_killed(enemy: Node, cause: String)
signal threat_changed(threat_level: float)
signal player_corruption_changed(value: float)
signal environment_impulse_made(position: Vector3, radius: float, force: float, source: Node, reason: String)
signal sound_requested(sound_id: String, position: Vector3, intensity: float)
signal enemy_sighting_reported(position: Vector3, source: Node, radius: float)
signal visibility_haze_requested(position: Vector3, radius: float, duration: float, strength: float)

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
		request_sound("movement" if loudness < 10.0 else "loud_movement", position, clamp(loudness / 40.0, 0.2, 1.2))

func report_enemy_killed(enemy: Node, cause: String) -> void:
	enemy_killed.emit(enemy, cause)

func report_threat_changed(threat_level: float) -> void:
	threat_changed.emit(threat_level)

func report_player_corruption(value: float) -> void:
	player_corruption_changed.emit(value)

func emit_environment_impulse(position: Vector3, radius: float, force: float, source: Node, reason: String) -> void:
	environment_impulse_made.emit(position, radius, force, source, reason)
	request_sound(reason, position, clamp(force / 10.0, 0.25, 1.6))

func request_sound(sound_id: String, position: Vector3, intensity: float = 1.0) -> void:
	sound_requested.emit(sound_id, position, intensity)

func report_enemy_sighting(position: Vector3, source: Node, radius: float = 12.0) -> void:
	enemy_sighting_reported.emit(position, source, radius)

func request_visibility_haze(position: Vector3, radius: float, duration: float, strength: float) -> void:
	visibility_haze_requested.emit(position, radius, duration, strength)
