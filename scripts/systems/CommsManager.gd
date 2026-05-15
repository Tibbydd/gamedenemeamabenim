extends Node
class_name CommsManager

var mental: MentalStateManager
var comms_label: Label
var has_headset: bool = false
var message_timer: float = 0.0
var message_interval: float = 12.0
var last_message: String = ""

func setup(mental_state: MentalStateManager, label: Label) -> void:
	mental = mental_state
	comms_label = label
	_refresh_display()

func set_headset_equipped(equipped: bool) -> void:
	has_headset = equipped
	message_timer = 0.0
	if has_headset:
		announce("Signal acquired. I can hear you. Move slow.")
	else:
		last_message = ""
		_refresh_display()

func announce(message: String) -> void:
	if not has_headset:
		return
	last_message = _distort_message(message)
	_refresh_display()

func _process(delta: float) -> void:
	if not comms_label:
		return
	if not has_headset:
		_refresh_display()
		return
	message_timer -= delta
	if message_timer <= 0.0:
		announce(_pick_context_message())
		message_timer = message_interval + randf_range(-3.0, 4.0)

func _pick_context_message() -> String:
	var corruption := mental.corruption if mental else 0.0
	if corruption >= 80.0:
		return _pick([
			"Do not trust that voice. Mine or yours, I mean.",
			"The signal is being copied. Listen for the mistake.",
			"If I tell you to run, ask why."
		])
	if corruption >= 55.0:
		return _pick([
			"Your feed is drifting. Verify doors with your eyes.",
			"I am getting false telemetry. Count your shots.",
			"Something is riding the channel. Stay deliberate."
		])
	return _pick([
		"Check corners before sprinting. Noise is a debt.",
		"If you lose the kit, the next survivor loses me too.",
		"Light helps you. It helps them find you.",
		"Your body is temporary. The station remembers."
	])

func _distort_message(message: String) -> String:
	var corruption := mental.corruption if mental else 0.0
	if corruption < 55.0:
		return message
	if corruption < 80.0:
		return message.replace("I", "we").replace("you", "you?")
	return _pick([
		"I found you before they did.",
		"You left the door open for us.",
		"Recover the body. Feed the loop.",
		message
	])

func _refresh_display() -> void:
	if not comms_label:
		return
	if not has_headset:
		comms_label.text = "COMMS: NO EARPIECE"
		comms_label.modulate = Color(0.45, 0.55, 0.55)
		return
	comms_label.text = "COMMS: %s" % (last_message if not last_message.is_empty() else "listening")
	var corruption := mental.corruption if mental else 0.0
	comms_label.modulate = Color(0.75, 1.0, 0.9).lerp(Color(1.0, 0.28, 0.2), clamp(corruption / 100.0, 0.0, 1.0))

func _pick(options: Array) -> String:
	return options[randi() % options.size()]
