extends Node
class_name AudioRouter

const MIX_RATE := 22050

var sound_profiles: Dictionary = {}

func _ready() -> void:
	sound_profiles = {
		"gunshot": _profile(0.16, 95.0, 0.55, 18.0, true),
		"suppressed_gunshot": _profile(0.11, 140.0, 0.32, 10.0, true),
		"reload": _profile(0.18, 420.0, 0.22, 4.0, false),
		"mag_drop": _profile(0.12, 260.0, 0.18, 5.0, true),
		"interact": _profile(0.12, 540.0, 0.16, 4.0, false),
		"pickup": _profile(0.16, 680.0, 0.18, 4.0, false),
		"enemy_grunt": _profile(0.34, 72.0, 0.32, 14.0, true),
		"enemy_attack": _profile(0.22, 110.0, 0.4, 12.0, true),
		"enemy_death": _profile(0.45, 62.0, 0.38, 18.0, true),
		"howler_death": _profile(0.75, 88.0, 0.78, 30.0, true),
		"hazard_blast": _profile(0.42, 58.0, 0.9, 30.0, true),
		"hazard_electric": _profile(0.34, 180.0, 0.55, 18.0, true),
		"hazard_steam": _profile(0.5, 260.0, 0.45, 14.0, true),
		"hazard_coolant": _profile(0.42, 210.0, 0.38, 14.0, true),
		"door_forced": _profile(0.32, 130.0, 0.5, 18.0, true),
		"button": _profile(0.12, 760.0, 0.2, 5.0, false),
		"movement": _profile(0.09, 180.0, 0.08, 4.0, true),
		"loud_movement": _profile(0.12, 150.0, 0.2, 7.0, true),
		"telemetry_ping": _profile(0.055, 1420.0, 0.12, 5.0, false),
		"heartbeat": _profile(0.16, 52.0, 0.18, 1.0, false),
		"comms": _profile(0.2, 920.0, 0.16, 2.0, false)
	}
	GameEvents.sound_requested.connect(_on_sound_requested)

func _profile(duration: float, frequency: float, volume: float, range_value: float, noisy: bool) -> Dictionary:
	return {
		"duration": duration,
		"frequency": frequency,
		"volume": volume,
		"range": range_value,
		"noisy": noisy
	}

func _on_sound_requested(sound_id: String, position: Vector3, intensity: float) -> void:
	var profile := _resolve_profile(sound_id)
	_play_profile(profile, position, intensity)

func _resolve_profile(sound_id: String) -> Dictionary:
	if sound_profiles.has(sound_id):
		return sound_profiles[sound_id]
	if sound_id.begins_with("hazard_blast"):
		return sound_profiles["hazard_blast"]
	if sound_id.begins_with("hazard_electric"):
		return sound_profiles["hazard_electric"]
	if sound_id.begins_with("hazard_steam") or sound_id.begins_with("hazard_pressure_dump") or sound_id.begins_with("pressure_dump"):
		return sound_profiles["hazard_steam"]
	if sound_id.begins_with("hazard_coolant"):
		return sound_profiles["hazard_coolant"]
	if sound_id.begins_with("hazard_crusher"):
		return sound_profiles["door_forced"]
	if sound_id.begins_with("door_forced"):
		return sound_profiles["door_forced"]
	if sound_id.begins_with("button"):
		return sound_profiles["button"]
	if sound_id.begins_with("equipment_pickup"):
		return sound_profiles["pickup"]
	return sound_profiles["interact"]

func _play_profile(profile: Dictionary, position: Vector3, intensity: float) -> void:
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = MIX_RATE
	stream.buffer_length = float(profile["duration"]) + 0.05
	var player := AudioStreamPlayer3D.new()
	player.stream = stream
	player.global_position = position
	player.max_distance = float(profile["range"]) * max(0.4, intensity)
	player.unit_size = 4.0
	player.volume_db = linear_to_db(clamp(float(profile["volume"]) * intensity, 0.01, 1.0))
	add_child(player)
	player.play()
	var playback = player.get_stream_playback()
	if playback:
		_fill_stream(playback, profile, intensity)
	await get_tree().create_timer(float(profile["duration"]) + 0.08).timeout
	if is_instance_valid(player):
		player.queue_free()

func _fill_stream(playback, profile: Dictionary, intensity: float) -> void:
	var duration := float(profile["duration"])
	var frequency := float(profile["frequency"])
	var volume := float(profile["volume"]) * intensity
	var frame_count := int(MIX_RATE * duration)
	var noisy := bool(profile["noisy"])
	for frame in range(frame_count):
		var t := float(frame) / float(MIX_RATE)
		var envelope := 1.0 - clamp(t / max(0.01, duration), 0.0, 1.0)
		var tone := sin(TAU * frequency * t)
		if noisy:
			tone = tone * 0.45 + randf_range(-1.0, 1.0) * 0.55
		var sample := clamp(tone * volume * envelope, -1.0, 1.0)
		playback.push_frame(Vector2(sample, sample))
