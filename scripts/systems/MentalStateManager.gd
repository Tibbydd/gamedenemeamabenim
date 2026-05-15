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
	var drift := randi_range(-2, 2)
	return str(max(0, real_ammo + drift))

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
