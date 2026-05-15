extends Node
class_name PlayerHealthBodyParts

signal health_changed
signal treatment_started(treatment_name: String)
signal treatment_finished(treatment_name: String)
signal died(reason: String)
signal damage_taken(part_name: String, amount: float, damage_type: String, result: Dictionary)

const PART_HEAD := "head"
const PART_CHEST := "chest"
const PART_STOMACH := "stomach"
const PART_LEFT_ARM := "left_arm"
const PART_RIGHT_ARM := "right_arm"
const PART_LEFT_LEG := "left_leg"
const PART_RIGHT_LEG := "right_leg"

var parts := {}
var blood_volume: float = 100.0
var bleed_rate: float = 0.0
var untreated_bleed_time: float = 0.0
var pain: float = 0.0
var shock: float = 0.0
var stimulant_time: float = 0.0
var is_dead: bool = false
var active_treatment: String = ""
var treatment_time_left: float = 0.0

func _ready() -> void:
	reset()

func _process(delta: float) -> void:
	if is_dead:
		return
	if bleed_rate > 0.0:
		untreated_bleed_time += delta
		blood_volume = max(0.0, blood_volume - bleed_rate * delta)
		_update_infection_pressure(delta)
		if blood_volume <= 0.0:
			kill("blood loss")
	else:
		untreated_bleed_time = 0.0
	if pain > 0.0:
		pain = max(0.0, pain - delta * 2.0)
	if shock > 0.0:
		shock = max(0.0, shock - delta * 3.0)
	if stimulant_time > 0.0:
		stimulant_time = max(0.0, stimulant_time - delta)
	if treatment_time_left > 0.0:
		treatment_time_left -= delta
		if treatment_time_left <= 0.0:
			_finish_treatment()
	health_changed.emit()

func reset() -> void:
	parts = {
		PART_HEAD: _make_part(35.0),
		PART_CHEST: _make_part(85.0),
		PART_STOMACH: _make_part(70.0),
		PART_LEFT_ARM: _make_part(55.0),
		PART_RIGHT_ARM: _make_part(55.0),
		PART_LEFT_LEG: _make_part(60.0),
		PART_RIGHT_LEG: _make_part(60.0)
	}
	blood_volume = 100.0
	bleed_rate = 0.0
	untreated_bleed_time = 0.0
	pain = 0.0
	shock = 0.0
	stimulant_time = 0.0
	is_dead = false
	active_treatment = ""
	treatment_time_left = 0.0
	health_changed.emit()

func _make_part(max_value: float) -> Dictionary:
	return {
		"max": max_value,
		"current": max_value,
		"fractured": false,
		"destroyed": false,
		"infected": false
	}

func apply_damage(part_name: String, amount: float, damage_type: String = "trauma") -> Dictionary:
	if is_dead or not parts.has(part_name):
		return {}
	var part: Dictionary = parts[part_name]
	part["current"] = max(0.0, float(part["current"]) - amount)
	if float(part["current"]) <= 0.0:
		part["destroyed"] = true
	if _can_fracture(part_name) and amount >= 14.0 and randf() < 0.35:
		part["fractured"] = true
	if amount >= 10.0 and damage_type != "blunt":
		bleed_rate += amount * 0.035
	pain = min(100.0, pain + amount * 0.8)
	shock = min(100.0, shock + amount * 0.35)
	parts[part_name] = part
	_check_lethal_parts()
	health_changed.emit()
	var result := {
		"part": part_name,
		"remaining": part["current"],
		"bleeding": bleed_rate > 0.0,
		"fractured": part["fractured"],
		"destroyed": part["destroyed"],
		"infected": part["infected"]
	}
	damage_taken.emit(part_name, amount, damage_type, result)
	return result

func _can_fracture(part_name: String) -> bool:
	return part_name in [PART_LEFT_ARM, PART_RIGHT_ARM, PART_LEFT_LEG, PART_RIGHT_LEG]

func _check_lethal_parts() -> void:
	if float(parts[PART_HEAD]["current"]) <= 0.0:
		kill("head destroyed")
	elif float(parts[PART_CHEST]["current"]) <= 0.0:
		kill("chest destroyed")

func kill(reason: String) -> void:
	if is_dead:
		return
	is_dead = true
	active_treatment = ""
	treatment_time_left = 0.0
	died.emit(reason)

func start_quick_bandage() -> bool:
	if not _can_start_treatment() or bleed_rate <= 0.0:
		return false
	active_treatment = "quick_bandage"
	treatment_time_left = 1.2
	treatment_started.emit("Quick Bandage")
	return true

func start_trauma_kit(treatment_duration: float = 3.0) -> bool:
	if not _can_start_treatment():
		return false
	active_treatment = "trauma_kit"
	treatment_time_left = treatment_duration
	treatment_started.emit("Trauma Kit")
	return true

func use_cauterizer() -> bool:
	if bleed_rate <= 0.0 or is_dead:
		return false
	bleed_rate = 0.0
	untreated_bleed_time = 0.0
	pain = min(100.0, pain + 8.0)
	health_changed.emit()
	return true

func apply_splint_roll() -> bool:
	for part_name in [PART_LEFT_ARM, PART_RIGHT_ARM, PART_LEFT_LEG, PART_RIGHT_LEG]:
		var part: Dictionary = parts[part_name]
		if not bool(part["fractured"]):
			continue
		part["fractured"] = false
		var capped_max := float(part["max"]) * 0.5
		part["current"] = max(float(part["current"]), capped_max)
		part["current"] = min(float(part["current"]), capped_max)
		parts[part_name] = part
		health_changed.emit()
		return true
	return false

func use_injector() -> bool:
	if is_dead:
		return false
	stimulant_time = 18.0
	pain = max(0.0, pain - 45.0)
	shock = max(0.0, shock - 35.0)
	health_changed.emit()
	return true

func use_neural_stabilizer(mental_manager: Node) -> bool:
	if is_dead or not mental_manager or not mental_manager.has_method("reduce_corruption"):
		return false
	mental_manager.reduce_corruption(30.0)
	return true

func _can_start_treatment() -> bool:
	return not is_dead and active_treatment.is_empty()

func _finish_treatment() -> void:
	var finished := active_treatment
	if active_treatment == "quick_bandage":
		bleed_rate = max(0.0, bleed_rate - 3.0)
		if bleed_rate <= 0.0:
			untreated_bleed_time = 0.0
	elif active_treatment == "trauma_kit":
		var part_name := _most_damaged_part()
		var part: Dictionary = parts[part_name]
		part["current"] = min(float(part["max"]), float(part["current"]) + float(part["max"]) * 0.45)
		part["infected"] = false
		parts[part_name] = part
		pain = max(0.0, pain - 25.0)
	active_treatment = ""
	treatment_time_left = 0.0
	treatment_finished.emit(finished)
	health_changed.emit()

func _most_damaged_part() -> String:
	var worst_name := PART_CHEST
	var worst_ratio := 1.0
	for part_name in parts.keys():
		var part: Dictionary = parts[part_name]
		var ratio := float(part["current"]) / float(part["max"])
		if ratio < worst_ratio:
			worst_ratio = ratio
			worst_name = part_name
	return worst_name

func _update_infection_pressure(delta: float) -> void:
	if untreated_bleed_time < 45.0:
		return
	var infected_parts := 0
	for part_name in parts.keys():
		var part: Dictionary = parts[part_name]
		if bool(part["infected"]):
			infected_parts += 1
			pain = min(100.0, pain + 0.5 * delta)
	if infected_parts > 0:
		return
	var part_to_infect := _most_damaged_part()
	var infected_part: Dictionary = parts[part_to_infect]
	infected_part["infected"] = true
	parts[part_to_infect] = infected_part

func get_movement_modifier() -> float:
	if stimulant_time > 0.0:
		return 1.0
	var left_leg: Dictionary = parts[PART_LEFT_LEG]
	var right_leg: Dictionary = parts[PART_RIGHT_LEG]
	var modifier := 1.0
	for leg in [left_leg, right_leg]:
		var ratio := float(leg["current"]) / float(leg["max"])
		if bool(leg["destroyed"]):
			modifier -= 0.35
		elif bool(leg["fractured"]) or ratio < 0.35:
			modifier -= 0.18
	return clamp(modifier, 0.35, 1.0)

func get_handling_modifier() -> float:
	if stimulant_time > 0.0:
		return 1.0
	var modifier := 1.0
	for arm_name in [PART_LEFT_ARM, PART_RIGHT_ARM]:
		var arm: Dictionary = parts[arm_name]
		var ratio := float(arm["current"]) / float(arm["max"])
		if bool(arm["destroyed"]):
			modifier -= 0.3
		elif bool(arm["fractured"]) or ratio < 0.35:
			modifier -= 0.15
	return clamp(modifier, 0.45, 1.0)

func get_part_ratio(part_name: String) -> float:
	if not parts.has(part_name):
		return 1.0
	var part: Dictionary = parts[part_name]
	return clamp(float(part["current"]) / float(part["max"]), 0.0, 1.0)

func is_part_destroyed(part_name: String) -> bool:
	if not parts.has(part_name):
		return false
	return bool(parts[part_name]["destroyed"])

func is_arm_compromised(part_name: String) -> bool:
	if not [PART_LEFT_ARM, PART_RIGHT_ARM].has(part_name):
		return false
	var arm: Dictionary = parts[part_name]
	return bool(arm["destroyed"]) or bool(arm["fractured"]) or get_part_ratio(part_name) < 0.35

func is_two_handed_compromised() -> bool:
	return is_arm_compromised(PART_LEFT_ARM) or is_arm_compromised(PART_RIGHT_ARM)

func can_hold_weapon() -> bool:
	return not (is_part_destroyed(PART_LEFT_ARM) and is_part_destroyed(PART_RIGHT_ARM))

func get_weapon_handling_state() -> String:
	if is_part_destroyed(PART_LEFT_ARM) and is_part_destroyed(PART_RIGHT_ARM):
		return "NO FUNCTIONAL GRIP"
	if is_arm_compromised(PART_LEFT_ARM) and is_arm_compromised(PART_RIGHT_ARM):
		return "TWO BAD ARMS"
	if is_arm_compromised(PART_LEFT_ARM):
		return "LEFT ARM COMPROMISED"
	if is_arm_compromised(PART_RIGHT_ARM):
		return "RIGHT ARM COMPROMISED"
	return "STABLE GRIP"

func get_stamina_modifier() -> float:
	var stomach: Dictionary = parts[PART_STOMACH]
	var chest: Dictionary = parts[PART_CHEST]
	var stomach_ratio := float(stomach["current"]) / float(stomach["max"])
	var chest_ratio := float(chest["current"]) / float(chest["max"])
	var blood_modifier := clamp(blood_volume / 100.0, 0.25, 1.0)
	return clamp(min(stomach_ratio, chest_ratio) * blood_modifier, 0.25, 1.0)

func get_status_lines() -> Array[String]:
	var lines: Array[String] = []
	for part_name in [PART_HEAD, PART_CHEST, PART_STOMACH, PART_LEFT_ARM, PART_RIGHT_ARM, PART_LEFT_LEG, PART_RIGHT_LEG]:
		var part: Dictionary = parts[part_name]
		var text := "%s %d/%d" % [
			part_name.replace("_", " ").to_upper(),
			int(part["current"]),
			int(part["max"])
		]
		if bool(part["fractured"]):
			text += " FRACTURE"
		if bool(part["infected"]):
			text += " INFECTED"
		if bool(part["destroyed"]):
			text += " DESTROYED"
		lines.append(text)
	if bleed_rate > 0.0:
		lines.append("BLEEDING %.1f/s" % bleed_rate)
	if stimulant_time > 0.0:
		lines.append("STIM %.0fs" % stimulant_time)
	return lines
