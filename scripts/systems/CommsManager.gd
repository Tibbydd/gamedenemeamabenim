extends Node
class_name CommsManager

var mental: MentalStateManager
var comms_label: Label
var has_headset: bool = false
var message_timer: float = 0.0
var message_interval: float = 12.0
var last_message: String = ""
var trust_score: float = 1.0
var clean_patch_time: float = 0.0
var floor_signal_distance: int = 0
var flicker_timer: float = 0.0
var inconsistent_callsign: String = ""

func setup(mental_state: MentalStateManager, label: Label) -> void:
	mental = mental_state
	comms_label = label
	_refresh_display()

func set_headset_equipped(equipped: bool) -> void:
	has_headset = equipped
	message_timer = 0.0
	if has_headset:
		if inconsistent_callsign.is_empty():
			inconsistent_callsign = _pick(["Terry", "Relay", "Harper", "Nine"])
		announce("Signal acquired. I can hear you. Move slow.")
	else:
		last_message = ""
		_refresh_display()

func announce(message: String) -> void:
	if not has_headset:
		return
	last_message = message if clean_patch_time > 0.0 else _distort_message(message)
	var source_position := Vector3.ZERO
	if get_parent() is Node3D:
		source_position = (get_parent() as Node3D).global_position
	GameEvents.request_sound("comms", source_position, 0.7)
	_refresh_display()

func _process(delta: float) -> void:
	if not comms_label:
		return
	clean_patch_time = max(0.0, clean_patch_time - delta)
	flicker_timer = max(0.0, flicker_timer - delta)
	if not has_headset:
		_refresh_display()
		return
	message_timer -= delta
	if message_timer <= 0.0:
		announce(_pick_context_message())
		message_timer = message_interval + randf_range(-3.0, 4.0)

func _pick_context_message() -> String:
	var corruption := mental.corruption if mental else 0.0
	if trust_score < 0.35 and corruption >= 50.0:
		return "I am trying to help. The channel is making me sound wrong."
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
		"Your body is temporary. The station remembers.",
		"%s, if that is you, keep the line short." % inconsistent_callsign
	])

func _distort_message(message: String) -> String:
	var corruption := mental.corruption if mental else 0.0
	if corruption < 55.0:
		return message
	if corruption < 80.0:
		return _distort_words(message)
	return _pick([
		"I found you before they did.",
		"You left the door open for us.",
		"Recover the body. Feed the loop.",
		message
	])

func _distort_words(message: String) -> String:
	var result := ""
	var token := ""
	for index in range(message.length()):
		var character := message.substr(index, 1)
		if _is_word_character(character):
			token += character
		else:
			result += _distort_token(token)
			token = ""
			result += character
	result += _distort_token(token)
	return result

func _distort_token(token: String) -> String:
	if token.is_empty():
		return ""
	if token == "I":
		return "we"
	if token.to_lower() == "you":
		return "you?"
	return token

func _is_word_character(character: String) -> bool:
	if character.is_empty():
		return false
	var code := character.unicode_at(0)
	return (code >= 65 and code <= 90) or (code >= 97 and code <= 122) or code == 39

func _refresh_display() -> void:
	if not comms_label:
		return
	if not has_headset:
		comms_label.text = "COMMS: NO EARPIECE"
		comms_label.modulate = Color(0.45, 0.55, 0.55)
		return
	var corruption := mental.corruption if mental else 0.0
	var message := last_message if not last_message.is_empty() else _signal_quality_text()
	if corruption >= 70.0 and flicker_timer <= 0.0 and randf() < 0.035:
		flicker_timer = randf_range(0.12, 0.34)
	if flicker_timer > 0.0:
		message = _pick([
			"the exit is below your skin",
			"door open / door closed / door open",
			"do not recover them",
			"you already answered"
		])
	comms_label.text = "COMMS: %s" % message
	comms_label.modulate = Color(0.75, 1.0, 0.9).lerp(Color(1.0, 0.28, 0.2), clamp(corruption / 100.0, 0.0, 1.0))

func apply_clean_patch(duration: float = 90.0) -> void:
	clean_patch_time = max(clean_patch_time, duration)
	announce("Patch accepted. Cleaner channel for a little while.")

func set_floor_signal_distance(distance: int) -> void:
	floor_signal_distance = max(0, distance)
	if floor_signal_distance >= 2:
		trust_score = max(0.0, trust_score - 0.04)

func note_distorted_obedience(was_wrong: bool) -> void:
	if was_wrong:
		trust_score = max(0.0, trust_score - 0.16)
	else:
		trust_score = min(1.0, trust_score + 0.04)

func _signal_quality_text() -> String:
	if floor_signal_distance >= 4:
		return "signal thin, beacon too far"
	if floor_signal_distance >= 2:
		return "carrier weak"
	return "listening"

func _pick(options: Array) -> String:
	return options[randi() % options.size()]
