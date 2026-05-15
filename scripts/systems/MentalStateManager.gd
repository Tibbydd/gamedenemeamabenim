extends Node
class_name MentalStateManager

signal corruption_changed(value: float)

var corruption: float = 0.0
var recovery_rate: float = 1.5
var camera: Camera3D
var overlay: ColorRect
var status_label: Label
var base_fov: float = 75.0
var false_ui_timer: float = 0.0
var last_false_hint: String = ""
var hallucination_timer: float = 0.0
var hallucination_sounds: Array[String] = ["enemy_grunt", "reload", "mag_drop", "gunshot", "door_forced", "loud_movement"]

func setup(new_camera: Camera3D, new_overlay: ColorRect, new_status_label: Label) -> void:
	camera = new_camera
	overlay = new_overlay
	status_label = new_status_label
	if camera:
		base_fov = camera.fov

func _process(delta: float) -> void:
	if corruption > 0.0:
		corruption = max(0.0, corruption - recovery_rate * delta)
	false_ui_timer = max(0.0, false_ui_timer - delta)
	_update_audio_hallucinations(delta)
	_apply_placeholder_effects(delta)
	GameEvents.report_player_corruption(corruption)
	corruption_changed.emit(corruption)

func add_corruption(amount: float, source: String = "unknown") -> void:
	corruption = clamp(corruption + amount, 0.0, 100.0)
	if corruption >= 35.0 and false_ui_timer <= 0.0:
		last_false_hint = _make_false_hint(source)
		false_ui_timer = randf_range(1.5, 3.5)
	corruption_changed.emit(corruption)

func reduce_corruption(amount: float) -> void:
	corruption = max(0.0, corruption - amount)
	false_ui_timer = 0.0
	last_false_hint = ""
	corruption_changed.emit(corruption)

func get_display_ammo(real_ammo: int) -> String:
	if corruption < 55.0 or randf() > corruption / 160.0:
		return str(real_ammo)
	var drift_range := 3 if corruption >= 70.0 else 2
	var drift := randi_range(-drift_range, drift_range)
	return str(max(0, real_ammo + drift))

func get_display_ammo_count(real_ammo: int) -> int:
	return int(get_display_ammo(real_ammo))

func get_status_suffix() -> String:
	if corruption < 25.0:
		return "STABLE"
	if false_ui_timer > 0.0 and not last_false_hint.is_empty():
		return last_false_hint
	if corruption < 55.0:
		return "AUDIO CONTACT?"
	if corruption < 80.0:
		return "DISPLAY TRUST DEGRADED"
	return "REALITY DESYNC"

func _apply_placeholder_effects(delta: float) -> void:
	var amount := corruption / 100.0
	if camera:
		camera.fov = lerp(camera.fov, base_fov + sin(Time.get_ticks_msec() * 0.004) * amount * 5.0, delta * 4.0)
		camera.h_offset = sin(Time.get_ticks_msec() * 0.006) * amount * 0.035
		camera.v_offset = cos(Time.get_ticks_msec() * 0.005) * amount * 0.025
	if overlay:
		overlay.color.a = clamp(amount * 0.32 + randf() * amount * 0.08, 0.0, 0.42)
	if status_label:
		status_label.text = "COGNITIVE LINK: %s  %d%%" % [get_status_suffix(), int(corruption)]
		status_label.modulate.a = 0.65 + sin(Time.get_ticks_msec() * 0.01) * amount * 0.35

func _update_audio_hallucinations(delta: float) -> void:
	hallucination_timer -= delta
	if corruption < 62.0:
		hallucination_timer = max(hallucination_timer, 2.0)
		return
	if hallucination_timer > 0.0:
		return
	hallucination_timer = randf_range(8.0, 17.0) * lerp(1.0, 0.45, corruption / 100.0)
	var parent_node := get_parent()
	if not (parent_node is Node3D):
		return
	var base_position := (parent_node as Node3D).global_position
	var angle := randf() * TAU
	var distance := randf_range(5.0, 16.0)
	var sound_position := base_position + Vector3(cos(angle), 0.0, sin(angle)) * distance
	var sound_id := hallucination_sounds[randi() % hallucination_sounds.size()]
	GameEvents.request_sound(sound_id, sound_position, randf_range(0.22, 0.75))
	if randi() % 8 == 0:
		GameEvents.emit_player_noise(sound_position, 14.0)

func _make_false_hint(source: String) -> String:
	var hints := [
		"FALSE FOOTSTEPS LEFT",
		"DOOR STATE UNCERTAIN",
		"AMMO TELEMETRY DRIFT",
		"MOTION AT EDGE OF VISION",
		"BREATHING NOT YOURS"
	]
	if source == "contact":
		hints.append("PARASITE SIGNAL IN BLOOD")
	return hints[randi() % hints.size()]
