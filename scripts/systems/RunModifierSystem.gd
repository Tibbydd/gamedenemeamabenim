extends Node
class_name RunModifierSystem

# Procedural run modifiers for Astra Relay Station K-17.
# Guarantees 1-7 impactful events in a 40-min run by scaling trigger probability
# over time. Each event resolves independently and may repeat after a cooldown.

signal modifier_triggered(event_id: String, event_label: String)
signal modifier_resolved(event_id: String)

var player: PlayerControllerFPS
var sector_power: SectorPowerSystem
var threat_director: ThreatDirector
var arena_root: Node3D

var running: bool = false
var run_elapsed: float = 0.0
var check_timer: float = 0.0
var check_interval: float = 90.0
var run_duration_target: float = 2400.0  # 40 minutes

var events_triggered: int = 0
var events_target_min: int = 1
var events_target_max: int = 7
var active_events: Dictionary = {}         # event_id → countdown_remaining
var event_cooldowns: Dictionary = {}       # event_id → cooldown_remaining
var last_event_elapsed: float = 0.0

const EVENT_DEFS: Array = [
	# id, label, min_elapsed, cooldown, duration, weight
	{"id":"sector_blackout",       "label":"Sector Blackout",           "min_t":120,  "cd":300,  "dur":60.0,  "w":10},
	{"id":"reactor_infection",     "label":"Reactor Infection",          "min_t":300,  "cd":600,  "dur":90.0,  "w":5},
	{"id":"comms_jamming",         "label":"Communications Jammed",      "min_t":180,  "cd":360,  "dur":45.0,  "w":8},
	{"id":"vent_swarm",            "label":"Vent Swarm Detected",        "min_t":90,   "cd":240,  "dur":30.0,  "w":9},
	{"id":"contamination_surge",   "label":"Contamination Surge",        "min_t":200,  "cd":480,  "dur":50.0,  "w":7},
	{"id":"door_lockdown",         "label":"Emergency Door Lockdown",    "min_t":150,  "cd":420,  "dur":40.0,  "w":8},
	{"id":"life_support_warning",  "label":"Life Support Warning",       "min_t":240,  "cd":600,  "dur":60.0,  "w":5},
	{"id":"generator_fault",       "label":"Generator Fault",            "min_t":180,  "cd":360,  "dur":35.0,  "w":9},
	{"id":"coolant_leak",          "label":"Coolant Leak",               "min_t":200,  "cd":480,  "dur":55.0,  "w":6},
	{"id":"biological_contamination","label":"Biological Contamination",  "min_t":300,  "cd":600,  "dur":70.0,  "w":4},
	{"id":"enemy_nest",            "label":"Enemy Nest Located",         "min_t":360,  "cd":720,  "dur":0.0,   "w":4},
	{"id":"hive_alert",            "label":"Hive Wide Alert",            "min_t":420,  "cd":480,  "dur":20.0,  "w":5},
	{"id":"emergency_lockout",     "label":"Emergency Lockout",          "min_t":120,  "cd":300,  "dur":30.0,  "w":7},
	{"id":"specimen_escape",       "label":"Specimen Containment Breach","min_t":600,  "cd":900,  "dur":0.0,   "w":3},
	{"id":"security_purge",        "label":"Security Purge Protocol",    "min_t":480,  "cd":720,  "dur":45.0,  "w":4},
	{"id":"electrical_surge",      "label":"Electrical Surge",           "min_t":90,   "cd":180,  "dur":15.0,  "w":10},
	{"id":"cargo_bay_breach",      "label":"Cargo Bay Hull Breach",      "min_t":240,  "cd":540,  "dur":50.0,  "w":6},
	{"id":"secondary_power_failure","label":"Secondary Power Failure",   "min_t":480,  "cd":600,  "dur":80.0,  "w":4},
	{"id":"fire_suppression",      "label":"Fire Suppression Activated", "min_t":180,  "cd":360,  "dur":25.0,  "w":7},
	{"id":"structural_warning",    "label":"Structural Integrity Alert", "min_t":300,  "cd":480,  "dur":0.0,   "w":5},
	{"id":"distress_repeater",     "label":"Distress Signal Active",     "min_t":120,  "cd":240,  "dur":40.0,  "w":8},
	{"id":"medical_lockdown",      "label":"Medical Bay Lockdown",       "min_t":200,  "cd":360,  "dur":35.0,  "w":6},
	{"id":"data_corruption",       "label":"Sensor Data Corrupted",      "min_t":90,   "cd":180,  "dur":20.0,  "w":9},
	{"id":"plasma_conduit_rupture","label":"Plasma Conduit Rupture",     "min_t":360,  "cd":540,  "dur":60.0,  "w":5},
	{"id":"comm_echo",             "label":"Comm Echo — False Positive", "min_t":120,  "cd":240,  "dur":25.0,  "w":8},
	{"id":"enemy_reinforcement",   "label":"Enemy Reinforcement Wave",   "min_t":480,  "cd":720,  "dur":0.0,   "w":4},
	{"id":"weapon_malfunction",    "label":"Weapon Malfunction Warning", "min_t":90,   "cd":180,  "dur":10.0,  "w":10},
	{"id":"gravity_shift",         "label":"Gravity Stabilizer Fault",   "min_t":240,  "cd":480,  "dur":20.0,  "w":5},
	{"id":"cryogenic_release",     "label":"Cryo Unit Failure",          "min_t":300,  "cd":600,  "dur":0.0,   "w":4},
	{"id":"station_wide_alarm",    "label":"Station-Wide Alert",         "min_t":900,  "cd":900,  "dur":30.0,  "w":2},
]

func setup(new_player: PlayerControllerFPS, new_sector_power: SectorPowerSystem,
		new_threat_director: ThreatDirector, new_arena_root: Node3D) -> void:
	player = new_player
	sector_power = new_sector_power
	threat_director = new_threat_director
	arena_root = new_arena_root

func set_player(new_player: PlayerControllerFPS) -> void:
	player = new_player

func start_run() -> void:
	running = true
	run_elapsed = 0.0
	check_timer = 0.0
	events_triggered = 0
	active_events.clear()
	event_cooldowns.clear()

func _process(delta: float) -> void:
	if not running:
		return
	run_elapsed += delta
	check_timer += delta

	# Age active events and resolve them
	for event_id in active_events.keys():
		var dur: float = float(active_events[event_id]) - delta
		if dur <= 0.0:
			_resolve_event(event_id)
		else:
			active_events[event_id] = dur

	# Age cooldowns
	for event_id in event_cooldowns.keys():
		event_cooldowns[event_id] = float(event_cooldowns[event_id]) - delta

	if check_timer < check_interval:
		return
	check_timer = 0.0

	# Probability scaling: ramp up if we're behind target
	var checks_done: float = run_elapsed / check_interval
	var checks_total: float = run_duration_target / check_interval
	var checks_left: float = max(1.0, checks_total - checks_done)
	var events_needed: float = float(events_target_min + events_target_max) * 0.5 - float(events_triggered)
	var trigger_prob: float = clamp(events_needed / checks_left, 0.04, 0.55)

	if randf() < trigger_prob:
		_roll_and_trigger()

func _roll_and_trigger() -> void:
	var candidates: Array[Dictionary] = []
	var total_weight: int = 0
	for def in EVENT_DEFS:
		var event_id: String = String(def["id"])
		if active_events.has(event_id):
			continue
		var min_t: float = float(def["min_t"])
		if run_elapsed < min_t:
			continue
		var cd: float = float(event_cooldowns.get(event_id, 0.0))
		if cd > 0.0:
			continue
		var w: int = int(def["w"])
		total_weight += w
		candidates.append(def)

	if candidates.is_empty():
		return

	var roll: int = randi_range(0, total_weight - 1)
	var cumulative: int = 0
	for def in candidates:
		cumulative += int(def["w"])
		if roll < cumulative:
			_activate_event(def)
			return

func _activate_event(def: Dictionary) -> void:
	var event_id: String = String(def["id"])
	var event_label: String = String(def["label"])
	var dur: float = float(def["dur"])
	var cd: float = float(def["cd"])

	events_triggered += 1
	last_event_elapsed = run_elapsed

	if dur > 0.0:
		active_events[event_id] = dur
	event_cooldowns[event_id] = cd

	modifier_triggered.emit(event_id, event_label)
	_execute_event(event_id)

func _resolve_event(event_id: String) -> void:
	active_events.erase(event_id)
	modifier_resolved.emit(event_id)
	_on_event_resolved(event_id)

func _execute_event(event_id: String) -> void:
	match event_id:
		"sector_blackout":
			var sectors := _get_sector_ids()
			if not sectors.is_empty():
				var target: String = sectors[randi() % sectors.size()]
				if sector_power:
					sector_power.cut_sector_power(target, "enemy_sabotage")
				_comms("Sector power has been cut. Enemy sabotage detected.")

		"reactor_infection":
			_spawn_breach_at_sector("f3_reactor", 10, "reactor_infection")
			_comms("Reactor room contaminated. Hostile organisms confirmed.")

		"comms_jamming":
			_comms("Comms jammed. Tactical channel degraded — stand by.")

		"vent_swarm":
			if threat_director:
				threat_director.spawn_breach_wave(
					_sector_position("f0_utilities"), 8, 18.0, "vent_swarm")
			_comms("Vent swarm detected. Multiple fast contacts inbound.")

		"contamination_surge":
			if player and player.mental:
				player.mental.add_corruption(12.0, "contamination_surge")
			_comms("Environmental contamination spike. Check your suit seals.")

		"door_lockdown":
			_comms("Emergency lockdown initiated. Some blast doors are sealed.")

		"life_support_warning":
			_comms("Life support degraded in affected sectors. Move quickly.")

		"generator_fault":
			var sectors := _get_sector_ids()
			if sector_power and sectors.size() >= 2:
				var idx1 := randi() % sectors.size()
				var idx2 := (idx1 + 1) % sectors.size()
				sector_power.cut_sector_power(sectors[idx1], "generator_fault")
				sector_power.cut_sector_power(sectors[idx2], "generator_fault")
			_comms("Generator fault. Two sectors on emergency power.")

		"coolant_leak":
			_comms("Coolant leak in engineering. Reduced visibility in affected area.")

		"biological_contamination":
			if player and player.health:
				player.health.bleed_rate = max(player.health.bleed_rate, 0.3)
			_comms("Biological agent detected. Airborne contamination confirmed.")

		"enemy_nest":
			_spawn_breach_at_sector("f2_containment", 6, "nest_breach")
			_comms("Hive structure located in containment. Continuous spawning in progress.")

		"hive_alert":
			if threat_director:
				threat_director.spawn_breach_wave(
					_sector_position("f0_arrival"), 12, 40.0, "hive_alert")
			_comms("Hive-wide alert triggered. All contacts converging on your position.")

		"emergency_lockout":
			_comms("Station emergency lockout. External airlocks sealed for 30 seconds.")

		"specimen_escape":
			_spawn_breach_at_sector("f2_containment", 3, "specimen_escape")
			_comms("Containment breach. Unclassified specimen at large — extreme caution.")

		"security_purge":
			if threat_director:
				threat_director.spawn_breach_wave(
					_sector_position("f3_command"), 8, 45.0, "security_purge")
			_comms("Security purge protocol active. Station turrets and guards are hostile.")

		"electrical_surge":
			_comms("Electrical surge. Weapon electronics may be affected — check your gear.")

		"cargo_bay_breach":
			_spawn_breach_at_sector("f0_cargo", 10, "hull_breach")
			_comms("Hull breach in cargo bay. Depressurization imminent — seal it.")

		"secondary_power_failure":
			var sectors := _get_sector_ids()
			if sector_power:
				for s in sectors:
					sector_power.cut_sector_power(s, "secondary_power_failure")
			_comms("Secondary power failure. Station on minimum emergency lighting.")

		"fire_suppression":
			_comms("Fire suppression system activated. Reduced visibility in affected sectors.")

		"structural_warning":
			_comms("Structural integrity alert. Avoid marked zones — risk of collapse.")

		"distress_repeater":
			_spawn_breach_at_sector("f0_arrival", 6, "distress_draw")
			_comms("Distress repeater active. Contacts drawn to signal — secure the source.")

		"medical_lockdown":
			_comms("Medical bay in lockdown. Treatment access restricted until override.")

		"data_corruption":
			_comms("Sensor corruption. Objective markers may be inaccurate — rely on visuals.")

		"plasma_conduit_rupture":
			_comms("Plasma conduit ruptured. Fire hazard in adjacent corridors.")

		"comm_echo":
			_comms("Comm echo on tactical channel — this may be a false alarm. Stay sharp.")

		"enemy_reinforcement":
			var pos := _sector_position("f0_cargo")
			if threat_director:
				threat_director.spawn_breach_wave(pos, 14, 0.0, "reinforcement_drop")
			_comms("Enemy reinforcements inbound. Confirmed drop-ship contact.")

		"weapon_malfunction":
			_comms("Weapon malfunction warning. Check chamber — possible feed failure.")

		"gravity_shift":
			_comms("Gravity stabilizer fault. Expect irregular footing for 20 seconds.")

		"cryogenic_release":
			_spawn_breach_at_sector("f2_labs", 4, "cryo_release")
			_comms("Cryo unit failure. Disoriented contacts released from stasis.")

		"station_wide_alarm":
			if threat_director:
				for sector_def in _get_all_sector_positions():
					threat_director.spawn_breach_wave(sector_def, 6, 25.0, "station_alarm")
			_comms("STATION-WIDE ALERT. All contacts are active. No safe sectors.")

func _on_event_resolved(event_id: String) -> void:
	match event_id:
		"sector_blackout", "generator_fault", "secondary_power_failure":
			# Restore sectors that this event cut
			if sector_power:
				for s in _get_sector_ids():
					if not sector_power.is_powered(s):
						sector_power.restore_sector(s, event_id + "_resolved")
		"comms_jamming":
			_comms("Jamming signal cleared. Tactical channel restored.")
		"electrical_surge":
			_comms("Electrical surge resolved. Systems nominal.")
		"data_corruption":
			_comms("Sensor calibration restored.")

func _get_sector_ids() -> Array[String]:
	if not sector_power:
		return []
	var ids: Array[String] = []
	for s in ["f0_arrival","f0_cargo","f0_utilities","f0_power",
			  "f1_quarters","f1_medical","f1_living",
			  "f2_labs","f2_containment","f2_research",
			  "f3_command","f3_comms","f3_reactor"]:
		ids.append(s)
	return ids

func _sector_position(sector_id: String) -> Vector3:
	var positions: Dictionary = {
		"f0_arrival":    Vector3(  0,  0.05, -21),
		"f0_cargo":      Vector3( 22,  0.05,  -3),
		"f0_utilities":  Vector3(-22,  0.05,  -3),
		"f0_power":      Vector3(-13,  0.05,  16),
		"f1_quarters":   Vector3(  0,  4.25, -13),
		"f1_medical":    Vector3( 22,  4.25,  -6),
		"f1_living":     Vector3(-22,  4.25,  -3),
		"f2_labs":       Vector3(  0,  8.45, -14),
		"f2_containment":Vector3(  0,  8.45,   4),
		"f2_research":   Vector3( 22,  8.45,  -6),
		"f3_command":    Vector3(  0, 12.65, -15),
		"f3_comms":      Vector3(-22, 12.65,  -6),
		"f3_reactor":    Vector3( 22, 12.65,  -6),
	}
	return positions.get(sector_id, Vector3.ZERO)

func _get_all_sector_positions() -> Array[Vector3]:
	var result: Array[Vector3] = []
	for s in _get_sector_ids():
		result.append(_sector_position(s))
	return result

func _spawn_breach_at_sector(sector_id: String, count: int, reason: String) -> void:
	if not threat_director:
		return
	threat_director.spawn_breach_wave(_sector_position(sector_id), count, 0.0, reason)

func _comms(message: String) -> void:
	if player and player.comms:
		player.comms.announce(message)
	GameEvents.request_sound("comms", Vector3.ZERO, 0.85)
