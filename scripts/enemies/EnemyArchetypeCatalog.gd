extends RefCounted
class_name EnemyArchetypeCatalog

static func get_archetypes() -> Array[Dictionary]:
	return [
		_a("stalker_husk", "Stalker Husk", 65, 3.3, 1.6, 28, 1.0, Color(0.22, 0.25, 0.28), {}, []),
		_a("crawler_husk", "Crawler Husk", 38, 4.1, 1.15, 18, 1.3, Color(0.18, 0.28, 0.24), {}, ["small_route"]),
		_a("bleeder", "Bleeder", 54, 2.8, 8.5, 24, 1.0, Color(0.34, 0.16, 0.18), {}, ["ranged_bleed"]),
		_a("carapace", "Carapace", 120, 2.1, 1.8, 22, 0.75, Color(0.18, 0.2, 0.18), {"torso": 0.6, "left_arm": 0.45, "right_arm": 0.45, "left_leg": 0.35, "right_leg": 0.35, "head": 0.25}, ["armored_core"]),
		_a("echo", "Echo", 46, 3.4, 1.5, 4, 2.5, Color(0.12, 0.18, 0.22), {}, ["sound_driven"]),
		_a("howler", "Howler", 58, 3.0, 1.7, 26, 1.2, Color(0.3, 0.22, 0.14), {}, ["death_noise"]),
		_a("sleeper_pod", "Sleeper Pod", 42, 0.0, 1.3, 8, 0.4, Color(0.16, 0.12, 0.18), {"torso": 0.2}, ["dormant"]),
		_a("stalker_twin", "Stalker Twin", 58, 3.6, 1.55, 27, 1.0, Color(0.24, 0.22, 0.32), {}, ["paired_flanker"]),
		_a("glasswalker", "Glasswalker", 52, 3.9, 1.45, 30, 0.9, Color(0.18, 0.3, 0.34), {}, ["vertical_route"]),
		_a("surgeon", "Surgeon", 62, 3.0, 1.4, 22, 1.0, Color(0.34, 0.28, 0.26), {}, ["kit_hunter"]),
		_a("choir", "Choir", 150, 1.55, 1.8, 20, 0.8, Color(0.2, 0.16, 0.26), {"torso": 0.25}, ["corruption_aura"]),
		_a("shellroot", "Shellroot", 180, 0.0, 0.0, 0, 0.0, Color(0.14, 0.2, 0.16), {"torso": 0.7, "left_arm": 0.7, "right_arm": 0.7, "left_leg": 0.7, "right_leg": 0.7}, ["thermal_blocker", "immobile"]),
		_a("relay_voice", "Relay Voice", 48, 2.7, 1.4, 18, 1.1, Color(0.25, 0.2, 0.3), {}, ["false_comms"])
	]

static func get_archetype(archetype_id: String) -> Dictionary:
	for archetype in get_archetypes():
		if String(archetype["id"]) == archetype_id:
			return archetype
	return get_archetypes()[0]

static func pick_for_threat(threat_level: float) -> String:
	var roll := randf()
	if threat_level > 0.72 and roll < 0.12:
		return "choir"
	if threat_level > 0.58 and roll < 0.18:
		return "carapace"
	if threat_level > 0.45 and roll < 0.28:
		return "bleeder"
	if threat_level > 0.35 and roll < 0.36:
		return "echo"
	if threat_level > 0.28 and roll < 0.44:
		return "howler"
	if roll < 0.18:
		return "crawler_husk"
	return "stalker_husk"

static func pick_for_floor_and_threat(floor_index: int, threat_level: float) -> String:
	var roll := randf()
	if floor_index <= 1:
		if roll < 0.28:
			return "crawler_husk"
		if roll < 0.42:
			return "howler"
	elif floor_index >= 4:
		if roll < 0.16:
			return "carapace"
		if roll < 0.28:
			return "choir"
		if roll < 0.38:
			return "surgeon"
	elif floor_index >= 2 and roll < 0.22:
		return "echo"
	return pick_for_threat(threat_level)

static func _a(id: String, label: String, health: float, speed: float, attack_range: float, sight: float, hearing: float, color: Color, armor: Dictionary, traits: Array[String]) -> Dictionary:
	return {
		"id": id,
		"label": label,
		"health": health,
		"speed": speed,
		"attack_range": attack_range,
		"sight": sight,
		"hearing": hearing,
		"color": color,
		"armor": armor,
		"traits": traits
	}
