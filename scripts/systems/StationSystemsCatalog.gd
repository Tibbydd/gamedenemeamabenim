extends RefCounted
class_name StationSystemsCatalog

static func get_floor_routes() -> Array[Dictionary]:
	return [
		{"id": "main_stairwell", "label": "Main Stairwell", "delta_floor": 1, "requirements": ["power_or_manual_pry"], "risk": "predictable enemy choke point"},
		{"id": "service_elevator", "label": "Service Elevator", "delta_floor": 1, "requirements": ["fuse", "power_cell"], "risk": "loud motor call"},
		{"id": "executive_hidden_lift", "label": "Executive Hidden Lift", "delta_floor": 3, "requirements": ["access_credential", "discovered_office_switch"], "risk": "rare but bypasses large station sections"},
		{"id": "maintenance_ladder_riser", "label": "Maintenance Ladder Riser", "delta_floor": 1, "requirements": ["crouch_route"], "risk": "slow climb and no reload room"},
		{"id": "cargo_hoist_shaft", "label": "Cargo Hoist Shaft", "delta_floor": -2, "requirements": ["hoist_power", "brake_release"], "risk": "crush hazard and noise"},
		{"id": "ventilation_stack", "label": "Ventilation Stack", "delta_floor": 1, "requirements": ["small_entry", "fan_lockout"], "risk": "ambush pockets and oxygen loss"},
		{"id": "exterior_catwalk", "label": "Exterior Catwalk", "delta_floor": 2, "requirements": ["suit_patch", "airlock_cycle"], "risk": "low gravity shove risk"},
	]

static func get_environmental_kills() -> Array[Dictionary]:
	return [
		{"id": "volatile_tank", "label": "Volatile Tank", "verbs": ["shoot", "throw", "wire_trip"], "effect": "blast and fragmentation"},
		{"id": "arc_junction", "label": "Arc Junction", "verbs": ["overload", "wet_floor", "shove_enemy"], "effect": "electrical stun and burn"},
		{"id": "steam_main", "label": "Steam Main", "verbs": ["open_valve", "rupture_pipe", "button_cycle"], "effect": "cone of heat and vision block"},
		{"id": "pressure_dump", "label": "Pressure Dump", "verbs": ["cycle_airlock", "break_window", "vent_panel"], "effect": "pulls bodies toward breach"},
		{"id": "cargo_crusher", "label": "Cargo Crusher", "verbs": ["button", "thrown_object", "timed_lure"], "effect": "localized lethal impact"},
		{"id": "coolant_flood", "label": "Coolant Flood", "verbs": ["shoot_coupling", "open_drain", "reroute_pump"], "effect": "slow, brittle, visibility haze"},
		{"id": "security_crossfire", "label": "Security Crossfire", "verbs": ["repair_turret", "spoof_target", "bait_enemy"], "effect": "ballistic area denial"},
	]

static func get_light_failure_reasons() -> Array[Dictionary]:
	return [
		{"id": "missing_fuse", "label": "Fuse missing from local panel"},
		{"id": "tripped_breaker", "label": "Breaker tripped after short"},
		{"id": "cut_cable", "label": "Cable severed in service wall"},
		{"id": "generator_offline", "label": "Generator offline on another floor"},
		{"id": "battery_bank_drained", "label": "Emergency battery bank drained"},
		{"id": "flooded_conduit", "label": "Conduit flooded and unsafe"},
		{"id": "manual_lockout", "label": "Technician lockout still engaged"},
		{"id": "burned_transformer", "label": "Transformer burned out"},
		{"id": "ai_load_shed", "label": "Station logic shed lighting load"},
		{"id": "parasite_growth", "label": "Growth occluding fixtures and cable paths"},
	]

static func get_light_restore_methods() -> Array[Dictionary]:
	return [
		{"id": "replace_fuse", "label": "Replace fuse", "resource": "fuse", "amount": 1},
		{"id": "reset_breaker", "label": "Reset breaker", "resource": "", "amount": 0},
		{"id": "patch_cable", "label": "Patch cable", "resource": "cable_spool", "amount": 1},
		{"id": "slot_power_cell", "label": "Slot power cell", "resource": "power_cell", "amount": 1},
		{"id": "restart_generator", "label": "Restart generator", "resource": "tool_parts", "amount": 1},
		{"id": "reroute_from_adjacent_floor", "label": "Reroute adjacent floor power", "resource": "access_credential", "amount": 1},
	]

static func get_door_problem_solutions() -> Array[Dictionary]:
	return [
		{"problem": "locked", "solution": "use_access_credential", "resource": "access_credential", "amount": 1},
		{"problem": "locked", "solution": "power_local_override", "resource": "fuse", "amount": 1},
		{"problem": "locked", "solution": "shoot_lock_housing", "resource": "ammo", "amount": 1},
		{"problem": "locked", "solution": "maintenance_bypass", "resource": "tool_parts", "amount": 1},
		{"problem": "locked", "solution": "hidden_route_around", "resource": "", "amount": 0},
		{"problem": "jammed", "solution": "manual_pry", "resource": "", "amount": 0},
		{"problem": "jammed", "solution": "shove_or_bash", "resource": "", "amount": 0},
		{"problem": "jammed", "solution": "reverse_motor", "resource": "power_cell", "amount": 1},
		{"problem": "jammed", "solution": "cut_debris", "resource": "cutting_charge", "amount": 1},
		{"problem": "jammed", "solution": "go_through_service_space", "resource": "", "amount": 0},
		{"problem": "broken", "solution": "replace_fuse", "resource": "fuse", "amount": 1},
		{"problem": "broken", "solution": "patch_control_cable", "resource": "cable_spool", "amount": 1},
		{"problem": "broken", "solution": "install_actuator_part", "resource": "tool_parts", "amount": 2},
		{"problem": "broken", "solution": "force_open_permanently", "resource": "", "amount": 0},
		{"problem": "broken", "solution": "route_power_from_other_floor", "resource": "access_credential", "amount": 1},
	]

static func get_station_modules() -> Array[Dictionary]:
	return [
		{"id": "hab_ring", "label": "Habitation Ring", "uses": ["rest points", "personal stories", "hidden offices", "food stores", "identity clues"]},
		{"id": "medical_deck", "label": "Medical Deck", "uses": ["treatment", "body horror", "pharma storage", "triage logs", "sterile hazards"]},
		{"id": "industrial_core", "label": "Industrial Core", "uses": ["power", "heavy tools", "crushers", "heat", "noise"]},
		{"id": "research_vault", "label": "Research Vault", "uses": ["specimen containment", "weird sensors", "restricted routes", "story evidence", "corruption spikes"]},
		{"id": "admin_spine", "label": "Admin Spine", "uses": ["access credentials", "hidden elevators", "security routing", "maps", "blackmail rooms"]},
		{"id": "exterior_works", "label": "Exterior Works", "uses": ["catwalks", "antennae", "low oxygen", "long sightlines", "alternate floor skips"]},
	]

static func get_economy_items() -> Array[Dictionary]:
	return [
		{"id": "fuse", "label": "Fuse", "uses": ["lights", "doors", "elevators", "medical cabinets", "defense relays"]},
		{"id": "power_cell", "label": "Power Cell", "uses": ["emergency lights", "door motors", "tools", "turret frames", "lift calls"]},
		{"id": "cable_spool", "label": "Cable Spool", "uses": ["light repair", "button rewiring", "generator bypass", "sensor tripline", "door patch"]},
		{"id": "tool_parts", "label": "Tool Parts", "uses": ["generator repair", "weapon maintenance", "door actuators", "turrets", "medical devices"]},
		{"id": "access_credential", "label": "Access Credential", "uses": ["doors", "office lifts", "admin terminals", "armories", "floor reroutes"]},
		{"id": "cutting_charge", "label": "Cutting Charge", "uses": ["sealed panels", "jammed doors", "floor grates", "emergency bulkheads", "heavy locks"]},
		{"id": "med_stock", "label": "Medical Stock", "uses": ["trauma kits", "stabilizers", "field surgery", "tradeoffs", "story triage"]},
	]

static func get_wearable_modules() -> Array[Dictionary]:
	return [
		{"id": "hud_glasses", "label": "Diagnostic Glasses", "slot": "glasses", "effect": "enables diegetic vitals and stamina overlay"},
		{"id": "ammo_link_receiver", "label": "Ammo Link Receiver", "slot": "glasses_module", "effect": "shows ammo only when weapon transmitter is installed"},
		{"id": "brainwave_reader", "label": "Brainwave Reader", "slot": "glasses_module", "effect": "shows mental corruption state"},
		{"id": "compass_module", "label": "Compass Module", "slot": "glasses_module", "effect": "shows facing direction"},
		{"id": "route_mapper", "label": "Route Mapper", "slot": "glasses_module", "effect": "shows floor and discovered route context"},
		{"id": "comms_transcriber", "label": "Comms Transcriber", "slot": "glasses_module", "effect": "renders earpiece speech as text"},
		{"id": "reticle_lens", "label": "Reticle Lens", "slot": "glasses_module", "effect": "adds a simple projected aiming mark"},
		{"id": "sound_meter", "label": "Sound Meter", "slot": "glasses_module", "effect": "estimates stealth noise"},
		{"id": "low_light_filter", "label": "Low-Light Filter", "slot": "glasses_module", "effect": "future visibility aid in dark sectors"},
		{"id": "threat_classifier", "label": "Threat Classifier", "slot": "glasses_module", "effect": "future enemy silhouette classification"},
	]

static func get_weapon_attachments() -> Array[Dictionary]:
	return [
		{"id": "ammo_telemetry_transmitter", "label": "Ammo Telemetry Transmitter", "slot": "sensor", "effect": "pairs with glasses receiver for exact ammo display"},
		{"id": "compact_suppressor", "label": "Compact Suppressor", "slot": "muzzle", "effect": "lower report, slightly lower velocity"},
		{"id": "port_compensator", "label": "Port Compensator", "slot": "muzzle", "effect": "lower climb, louder report"},
		{"id": "reflex_sight", "label": "Reflex Sight", "slot": "optic", "effect": "faster visual alignment, requires working eyes not HUD"},
		{"id": "laser_pointer", "label": "Laser Pointer", "slot": "underbarrel", "effect": "better hip alignment, visible to enemies later"},
		{"id": "foregrip", "label": "Foregrip", "slot": "underbarrel", "effect": "better two-handed control"},
		{"id": "extended_magazine", "label": "Extended Magazine", "slot": "magazine", "effect": "larger magazine, slower reload"},
		{"id": "quickpull_magwell", "label": "Quickpull Magwell", "slot": "magazine", "effect": "faster reload, no capacity gain"},
		{"id": "weapon_light", "label": "Weapon Light", "slot": "underbarrel", "effect": "future weapon-mounted illumination"},
		{"id": "retention_sling", "label": "Retention Sling", "slot": "stock", "effect": "reduces weapon drop chance on injury shock"},
	]

static func get_wearable_module_label(module_id: String) -> String:
	for module in get_wearable_modules():
		if String(module["id"]) == module_id:
			return String(module["label"])
	return module_id.replace("_", " ").capitalize()

static func get_weapon_attachment_label(attachment_id: String) -> String:
	for attachment in get_weapon_attachments():
		if String(attachment["id"]) == attachment_id:
			return String(attachment["label"])
	return attachment_id.replace("_", " ").capitalize()
