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
		{"id": "crash_kit", "label": "Crash Kit", "uses": ["fast trauma treatment", "emergency stabilization", "body recovery"]},
		{"id": "field_cauterizer_pen", "label": "Field Cauterizer Pen", "uses": ["stop bleeding without med stock", "pain tradeoff", "burn risk"]},
		{"id": "earpiece_patch", "label": "Earpiece Patch", "uses": ["temporary clean comms", "signal repair", "paranoia counterplay"]},
		{"id": "suppressor_wrap", "label": "Suppressor Wrap", "uses": ["temporary quiet shots", "single-use weapon prep", "stealth breach"]},
		{"id": "magnetic_puller", "label": "Magnetic Puller", "uses": ["recover dropped weapon", "drag lost kit", "safe reach tool"]},
		{"id": "suit_patch", "label": "Suit Patch", "uses": ["exterior routes", "oxygen leaks", "airlock mistakes"]},
		{"id": "match_grade_rounds", "label": "Match-Grade Rounds", "uses": ["one strong magazine", "weak-point prep", "rare ammo pressure"]},
		{"id": "boot_grips", "label": "Boot Grips", "uses": ["quiet movement", "hard-surface stealth", "catwalk safety"]},
		{"id": "coolant_canister", "label": "Coolant Canister", "uses": ["throwable slow zone", "thermal control", "brittle parasite armor"]},
		{"id": "static_charge", "label": "Static Charge", "uses": ["single-use stun", "door actuator shock", "brief crowd control"]},
		{"id": "splint_roll", "label": "Splint Roll", "uses": ["fracture support", "field brace", "limb salvage"]},
	]

static func get_wearable_modules() -> Array[Dictionary]:
	return [
		{"id": "hud_glasses", "label": "Diagnostic Glasses", "slot": "glasses", "power": 0.0, "effect": "enables diegetic vitals and stamina overlay"},
		{"id": "ammo_link_receiver", "label": "Ammo Link Receiver", "slot": "glasses_module", "power": 0.7, "effect": "shows ammo only when weapon transmitter is installed"},
		{"id": "brainwave_reader", "label": "Brainwave Reader", "slot": "glasses_module", "power": 1.1, "effect": "shows mental corruption state"},
		{"id": "compass_module", "label": "Compass Module", "slot": "glasses_module", "power": 0.45, "effect": "shows facing direction"},
		{"id": "route_mapper", "label": "Route Mapper", "slot": "glasses_module", "power": 0.9, "effect": "shows floor and discovered route context"},
		{"id": "comms_transcriber", "label": "Comms Transcriber", "slot": "glasses_module", "power": 0.5, "effect": "renders earpiece speech as text"},
		{"id": "reticle_lens", "label": "Reticle Lens", "slot": "glasses_module", "power": 0.35, "effect": "adds a simple projected aiming mark"},
		{"id": "sound_meter", "label": "Sound Meter", "slot": "glasses_module", "power": 0.8, "effect": "estimates stealth noise"},
		{"id": "low_light_filter", "label": "Low-Light Filter", "slot": "glasses_module", "power": 1.2, "effect": "boosts dark-sector visibility but gives Echo-class threats a glow to track"},
		{"id": "threat_classifier", "label": "Threat Classifier", "slot": "glasses_module", "power": 1.0, "effect": "future enemy silhouette classification"},
	]

static func get_weapon_attachments() -> Array[Dictionary]:
	return [
		{"id": "ammo_telemetry_transmitter", "label": "Ammo Telemetry Transmitter", "slot": "sensor", "durability": 1.0, "effect": "pairs with glasses receiver for exact ammo display"},
		{"id": "compact_suppressor", "label": "Compact Suppressor", "slot": "muzzle", "durability": 1.0, "effect": "lower report, slightly lower velocity"},
		{"id": "port_compensator", "label": "Port Compensator", "slot": "muzzle", "durability": 1.0, "effect": "lower climb, louder report"},
		{"id": "reflex_sight", "label": "Reflex Sight", "slot": "optic", "durability": 1.0, "effect": "faster visual alignment, requires working eyes not HUD"},
		{"id": "laser_pointer", "label": "Laser Pointer", "slot": "underbarrel", "durability": 1.0, "effect": "better hip alignment, visible to enemies later"},
		{"id": "foregrip", "label": "Foregrip", "slot": "underbarrel", "durability": 1.0, "effect": "better two-handed control"},
		{"id": "extended_magazine", "label": "Extended Magazine", "slot": "magazine", "durability": 1.0, "effect": "larger magazine, slower reload"},
		{"id": "quickpull_magwell", "label": "Quickpull Magwell", "slot": "magazine", "durability": 1.0, "effect": "faster reload, no capacity gain"},
		{"id": "weapon_light", "label": "Weapon Light", "slot": "underbarrel", "durability": 1.0, "effect": "future weapon-mounted illumination"},
		{"id": "retention_sling", "label": "Retention Sling", "slot": "stock", "durability": 1.0, "effect": "reduces weapon drop chance on injury shock"},
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

static func get_wearable_module_slot(module_id: String) -> String:
	for module in get_wearable_modules():
		if String(module["id"]) == module_id:
			return String(module["slot"])
	return "glasses_module"

static func get_wearable_module_power(module_id: String) -> float:
	for module in get_wearable_modules():
		if String(module["id"]) == module_id:
			return float(module.get("power", 0.0))
	return 0.0

static func get_weapon_attachment_durability(attachment_id: String) -> float:
	for attachment in get_weapon_attachments():
		if String(attachment["id"]) == attachment_id:
			return float(attachment.get("durability", 1.0))
	return 1.0

static func get_background_traits(background_id: String) -> Dictionary:
	match background_id:
		"Engineer":
			return {"service_speed": 0.5, "notes": "restores power faster"}
		"Medic":
			return {"treatment_speed": 0.5, "notes": "uses trauma care faster"}
		"Miner":
			return {"thermal_heat_ceiling": 145.0, "notes": "handles thermal tools harder"}
		"Courier":
			return {"resource_bonus": 2, "notes": "usually carries more salvage"}
		"Survey Tech":
			return {"route_hint_bonus": 1, "notes": "spots one extra hidden route"}
		"Security":
			return {"recoil_bonus": 0.88, "notes": "slightly cleaner recoil"}
		"Researcher":
			return {"corruption_resistance": 0.85, "notes": "slower corruption drift"}
		"Prisoner":
			return {"pain_resistance": 0.85, "notes": "pain affects aim less"}
		_:
			return {}

static func get_surface_profiles() -> Dictionary:
	return {
		"deck": {"noise": 1.0},
		"metal": {"noise": 1.1},
		"grate": {"noise": 1.55},
		"carpet": {"noise": 0.55},
		"vent": {"noise": 0.9},
		"wet": {"noise": 1.25}
	}

# --- Additions below: tangible-mechanics catalogs. ----------------------------
# Each entry codifies a mechanic as concrete verbs/effects/triggers rather than
# numeric stat shifts. A "buff" should always become a named capability the
# player can point to: a real item that opens a real cabinet, a real plate that
# really shatters, a real flare that really provokes a specific archetype.

# Salvage ID tags pulled from predecessor corpses. The tag is a real item that
# carries its dead owner's role + last login sector and acts as a low-tier
# access credential for that role's areas only.
static func get_salvage_id_tags() -> Array[Dictionary]:
	return [
		{"id": "tag_medic", "label": "Medic ID Tag", "role": "medical", "opens": ["medical_cabinet", "triage_locker"], "blocks": ["admin_terminal", "armory"], "route_hint": "medical_deck"},
		{"id": "tag_security", "label": "Security ID Tag", "role": "security", "opens": ["armory_low", "checkpoint_door"], "blocks": ["admin_terminal", "research_specimen"], "route_hint": "admin_spine"},
		{"id": "tag_engineer", "label": "Engineer ID Tag", "role": "engineering", "opens": ["maintenance_panel", "generator_room_low"], "blocks": ["medical_cabinet", "armory"], "route_hint": "industrial_core"},
		{"id": "tag_researcher", "label": "Researcher ID Tag", "role": "research", "opens": ["specimen_locker_low", "lab_drawer"], "blocks": ["armory", "checkpoint_door"], "route_hint": "research_vault"},
		{"id": "tag_courier", "label": "Courier ID Tag", "role": "logistics", "opens": ["cargo_locker", "courier_dropbox"], "blocks": ["admin_terminal", "research_specimen"], "route_hint": "exterior_works"},
		{"id": "tag_admin", "label": "Admin ID Tag", "role": "administration", "opens": ["admin_terminal_low", "office_lift_call"], "blocks": ["specimen_locker", "armory"], "route_hint": "admin_spine"},
	]

# Damaged helmet outcomes are physical, not statistical.
static func get_damaged_helmet_states() -> Array[Dictionary]:
	return [
		{"id": "cracked_visor", "label": "Cracked Visor", "tangible_effect": "adds corruption_drift module to glasses readouts (sound, ammo, route text can briefly lie)", "removable": true},
		{"id": "destroyed_helmet", "label": "Destroyed Helmet", "tangible_effect": "absorbs exactly one fatal head shot, then breaks and is left lying in the room as a marker", "removable": true},
		{"id": "soot_streaked", "label": "Soot-Streaked Helmet", "tangible_effect": "low_light_filter cannot mount until cleaned at a workbench", "removable": false},
		{"id": "scratched_lens", "label": "Scratched Lens", "tangible_effect": "reticle_lens projects a doubled crosshair until visor is replaced", "removable": true},
	]

# Portable beacons. Real placed devices with HP and a lighthouse effect.
static func get_portable_beacons() -> Array[Dictionary]:
	return [
		{"id": "comms_beacon_short", "label": "Short-Range Comms Beacon", "place_verb": "place_beacon", "hp": 60.0, "destroyed_by": ["bleeder_acid", "carapace_charge", "trip_mine"], "lighthouse_for": ["echo", "bleeder"], "sector_power_cost": "low"},
		{"id": "comms_beacon_long", "label": "Long-Range Comms Beacon", "place_verb": "place_beacon", "hp": 90.0, "destroyed_by": ["carapace_charge", "explosive"], "lighthouse_for": ["echo", "bleeder", "relay_voice"], "sector_power_cost": "high"},
		{"id": "navigation_beacon", "label": "Navigation Beacon", "place_verb": "place_beacon", "hp": 75.0, "destroyed_by": ["bullet_5_56_or_heavier", "carapace_charge"], "lighthouse_for": [], "sector_power_cost": "low"},
	]

# Chemical flares. Color codes are real reactions, not damage modifiers.
static func get_chemical_flares() -> Array[Dictionary]:
	return [
		{"id": "flare_red", "label": "Red Chemical Flare", "burn_seconds": 45.0, "provokes": ["carapace"], "confuses": [], "oxygen_consumes_per_second": 0.3},
		{"id": "flare_blue", "label": "Blue Chemical Flare", "burn_seconds": 40.0, "provokes": [], "confuses": ["echo"], "oxygen_consumes_per_second": 0.25},
		{"id": "flare_green", "label": "Green Chemical Flare", "burn_seconds": 60.0, "provokes": [], "confuses": ["surgeon"], "oxygen_consumes_per_second": 0.2},
		{"id": "flare_yellow", "label": "Yellow Chemical Flare", "burn_seconds": 35.0, "provokes": ["bleeder"], "confuses": ["howler"], "oxygen_consumes_per_second": 0.3},
		{"id": "flare_white", "label": "White Phosphor Flare", "burn_seconds": 20.0, "provokes": ["shellroot"], "confuses": ["sleeper_pod"], "oxygen_consumes_per_second": 0.8},
	]

# Door wedges with degradation, visible cracked state, and timed enemy removal.
static func get_door_wedges() -> Array[Dictionary]:
	return [
		{"id": "wedge_rubber", "label": "Rubber Wedge", "force_work_resistance_hits": 3, "visible_cracked_after_hits": 2, "enemy_removal_seconds": 8.0, "differentiator_vs_barricade": "passable from one side, blocks from the other"},
		{"id": "wedge_steel", "label": "Steel Wedge", "force_work_resistance_hits": 5, "visible_cracked_after_hits": 4, "enemy_removal_seconds": 12.0, "differentiator_vs_barricade": "leaves the door 1cm ajar, sound leaks more"},
		{"id": "wedge_polymer", "label": "Polymer Wedge", "force_work_resistance_hits": 2, "visible_cracked_after_hits": 1, "enemy_removal_seconds": 6.0, "differentiator_vs_barricade": "cheap, craftable from tool_parts, audibly cracks on first hit"},
	]

# Field recorder. A real device with a battery slot that captures the last
# 30 seconds of comms + ambient through the audio router.
static func get_field_recorder() -> Dictionary:
	return {
		"id": "field_recorder",
		"label": "Field Recorder",
		"slot": "belt",
		"battery_slot": "power_cell_small",
		"capture_seconds": 30.0,
		"playback_distortion_source": "player_corruption",
		"verbs": ["record", "playback", "save_clip", "swap_battery"],
		"never_always_on": true
	}

# Battery charger with a noise tradeoff and brownout coupling.
static func get_battery_chargers() -> Array[Dictionary]:
	return [
		{"id": "charger_slow", "label": "Slow Bench Charger", "charge_rate": "slow", "noise_signature": "quiet", "trips_brownout": false, "compatible_cells": ["power_cell_small", "power_cell"]},
		{"id": "charger_fast", "label": "Fast Bench Charger", "charge_rate": "fast", "noise_signature": "loud", "trips_brownout": true, "compatible_cells": ["power_cell", "charged_cell"]},
		{"id": "charger_field", "label": "Field Hand Charger", "charge_rate": "slow", "noise_signature": "quiet", "trips_brownout": false, "compatible_cells": ["power_cell_small"]},
	]

# Makeshift sling differentiated from the retention_sling attachment.
static func get_makeshift_sling() -> Dictionary:
	return {
		"id": "makeshift_sling",
		"label": "Makeshift Sling",
		"craft_recipe": {"cable_spool": 1, "tool_parts": 1},
		"drop_resistance_relative_to_retention_sling": "60_percent",
		"weapon_swap_speed_relative_to_retention_sling": "slower",
		"failure_mode": "snaps on heavy impact; survivor watches the gun fall and must pick it up",
		"visible_decay_state": true
	}

# Trauma foam: between bandage and trauma kit, with a real cost and second verb.
static func get_trauma_foam() -> Dictionary:
	return {
		"id": "trauma_foam",
		"label": "Trauma Foam",
		"primary_verb": "spray_joint",
		"primary_effect": "joint mobility drops; survivor cannot sprint or jump with that limb for 90s",
		"secondary_verb": "spray_hinge",
		"secondary_effect": "wedges a door open or shut for 60s",
		"between": ["quick_bandage", "trauma_kit"]
	}

# Route chalk. Diegetic marks that corruption can rewrite and that some
# parasites can read as a scent.
static func get_route_chalk() -> Dictionary:
	return {
		"id": "route_chalk",
		"label": "Route Chalk",
		"verbs": ["mark_arrow", "mark_x", "mark_safe", "wipe_mark"],
		"corruption_rewrite_threshold": 55,
		"visible_to_archetypes": ["echo", "stalker_husk"],
		"player_made_mark_visibility_tiers": ["faint", "normal", "bold"]
	}

# Sound occlusion as a real per-material attenuation table.
static func get_sound_occlusion_table() -> Dictionary:
	return {
		"open_air": {"attenuation_db": 0.0, "leaks_through_when_jammed": false},
		"drywall": {"attenuation_db": 8.0, "leaks_through_when_jammed": false},
		"thin_metal": {"attenuation_db": 6.0, "leaks_through_when_jammed": false},
		"pressure_door_open": {"attenuation_db": 0.0, "leaks_through_when_jammed": false},
		"pressure_door_closed": {"attenuation_db": 22.0, "leaks_through_when_jammed": false},
		"pressure_door_jammed": {"attenuation_db": 10.0, "leaks_through_when_jammed": true},
		"vent_grate": {"attenuation_db": 4.0, "leaks_through_when_jammed": false},
		"airlock_closed": {"attenuation_db": 28.0, "leaks_through_when_jammed": false},
		"crawlspace_hatch_open": {"attenuation_db": 2.0, "leaks_through_when_jammed": false},
		"glass": {"attenuation_db": 5.0, "leaks_through_when_jammed": false},
	}

# Limb armor slots with physical plates that shatter and drop loot.
static func get_limb_armor_slots() -> Array[Dictionary]:
	return [
		{"id": "plate_chest", "label": "Chest Plate", "slot": "chest", "absorbs_lethality_up_to": "incap", "shatters_after_lethal_hits": 1, "drops_shard": true, "movement_noise_cost": "loud_steps"},
		{"id": "plate_back", "label": "Back Plate", "slot": "back", "absorbs_lethality_up_to": "incap", "shatters_after_lethal_hits": 1, "drops_shard": true, "movement_noise_cost": "loud_steps"},
		{"id": "plate_shoulder", "label": "Shoulder Pauldron", "slot": "shoulder", "absorbs_lethality_up_to": "deep", "shatters_after_lethal_hits": 2, "drops_shard": false, "movement_noise_cost": "slight_clink"},
		{"id": "plate_thigh", "label": "Thigh Plate", "slot": "thigh", "absorbs_lethality_up_to": "deep", "shatters_after_lethal_hits": 2, "drops_shard": false, "movement_noise_cost": "slight_clink"},
		{"id": "plate_shin", "label": "Shin Plate", "slot": "shin", "absorbs_lethality_up_to": "graze", "shatters_after_lethal_hits": 3, "drops_shard": false, "movement_noise_cost": "metallic_step"},
		{"id": "plate_visor", "label": "Visor Plate", "slot": "visor", "absorbs_lethality_up_to": "deep", "shatters_after_lethal_hits": 1, "drops_shard": true, "movement_noise_cost": "none"},
	]

# Oxygen pockets in exterior_works and vent sectors.
static func get_oxygen_zones() -> Array[Dictionary]:
	return [
		{"id": "exterior_catwalk", "oxygen_level": "low", "suit_patch_consumed_per_second": 0.05, "panic_on_zero": true, "carrion_archetype_spawns": false},
		{"id": "broken_vent_stack", "oxygen_level": "thin", "suit_patch_consumed_per_second": 0.02, "panic_on_zero": true, "carrion_archetype_spawns": true},
		{"id": "vacuum_pocket", "oxygen_level": "vacuum", "suit_patch_consumed_per_second": 0.12, "panic_on_zero": true, "carrion_archetype_spawns": true},
		{"id": "biohazard_quarantine", "oxygen_level": "stale", "suit_patch_consumed_per_second": 0.01, "panic_on_zero": false, "carrion_archetype_spawns": false},
	]

# Scent trails. The predecessor's blood beacon channel is the same one
# bleeding survivors leave, and decon stations cancel it.
static func get_scent_trail_rules() -> Dictionary:
	return {
		"trail_source_player_bleeding": true,
		"trail_decay_seconds": 240.0,
		"trackers": ["bleeder", "surgeon", "stalker_twin"],
		"cancel_verb": "use_decon_station",
		"cancel_duration_seconds": 300.0,
		"decon_station_resource": "tool_parts",
		"decon_station_amount": 1
	}

# Door memory. Forced doors stay weaker; jam_count is surfaced in route_mapper.
static func get_door_memory_rules() -> Dictionary:
	return {
		"force_open_threshold_reduction_per_force": 0.25,
		"max_reductions": 3,
		"jam_count_surface": "route_mapper_per_door_history_line",
		"never_repair_to_full_without": "install_actuator_part"
	}

# Weapon fouling. A real different state with a real cleaning verb.
static func get_weapon_fouling_states() -> Array[Dictionary]:
	return [
		{"id": "coolant_fouled", "label": "Coolant Fouled", "trigger": "walked_through_coolant", "visible_tint": "blue_film", "cleaning_verb": "field_clean", "cleaning_seconds": 8.0, "cleaning_noise_spike": true},
		{"id": "biofouled", "label": "Biofouled", "trigger": "brushed_growth", "visible_tint": "green_film", "cleaning_verb": "scrape_and_clean", "cleaning_seconds": 12.0, "cleaning_noise_spike": true},
		{"id": "carbon_fouled", "label": "Carbon Fouled", "trigger": "thermal_tool_overheat", "visible_tint": "soot", "cleaning_verb": "carbon_brush", "cleaning_seconds": 10.0, "cleaning_noise_spike": false},
	]

# Light heat: flashlight intensity tiers and a thermal threat-classifier mode.
static func get_flashlight_intensity_tiers() -> Array[Dictionary]:
	return [
		{"id": "vest_light", "label": "Vest Light", "intensity_tier": "weak", "parasite_avoidance": "none"},
		{"id": "handheld", "label": "Handheld Light", "intensity_tier": "medium", "parasite_avoidance": "soft_avoidance_for_low_cognition"},
		{"id": "helmet_light", "label": "Helmet Light", "intensity_tier": "strong", "parasite_avoidance": "noticeable_for_echo_and_sleeper"},
		{"id": "weapon_light", "label": "Weapon Light", "intensity_tier": "focused", "parasite_avoidance": "ignored_unless_aimed_at_target"},
	]

static func get_threat_classifier_modes() -> Array[Dictionary]:
	return [
		{"id": "silhouette", "label": "Silhouette Mode", "verb": "tap_classifier", "cost": "tiny", "side_effect": "outlines threats only when seen directly"},
		{"id": "thermal", "label": "Thermal Mode", "verb": "hold_classifier", "cost": "drains_power_cell", "side_effect": "sees lights through walls but eats power and emits a faint hum"}
	]

# Panic reload concrete triggers. No abstract "panic chance" — drop is driven
# by pain + shock thresholds, with role-based modifiers as named flags.
static func get_panic_reload_rules() -> Dictionary:
	return {
		"drop_on_reload_threshold": {"pain": 60.0, "shock": 45.0, "combined": 90.0},
		"drop_on_reload_with_compromised_arm": true,
		"role_flags": {
			"Security": "panic_drop_threshold_raised",
			"Researcher": "panic_drop_threshold_lowered",
			"Engineer": "no_change",
			"Medic": "no_change",
			"Prisoner": "panic_drop_threshold_raised_when_low_blood"
		},
		"telegraph": "weapon_dips_visibly_for_0_3s_before_drop"
	}

# Route fatigue. Crawl volumes drain stamina; low stamina at the exit feeds
# the ambush rules.
static func get_route_fatigue_rules() -> Dictionary:
	return {
		"stamina_drain_per_second_in_crawlspace": 6.0,
		"stamina_drain_per_second_in_vent": 4.0,
		"stamina_drain_per_second_in_catwalk_wind": 2.0,
		"ambush_bonus_lethality_when_exit_stamina_below_25_percent": "first_attack_one_tier_more_lethal"
	}

# Manual map sketching. Only physical presence updates the sketch.
static func get_map_sketching_rules() -> Dictionary:
	return {
		"updates_only_by_physical_presence": true,
		"corruption_inserts_false_dead_ends_threshold": 50,
		"corruption_max_false_dead_ends": 3,
		"recoverable_from_predecessor_kit": true
	}

# Movement / traversal additions.
static func get_stance_states() -> Array[Dictionary]:
	return [
		{"id": "stand", "label": "Standing", "silhouette_fraction": 1.0, "noise_multiplier": 1.0, "fire_rate_multiplier": 1.0},
		{"id": "mid", "label": "Mid Stance", "silhouette_fraction": 0.6, "noise_multiplier": 0.75, "fire_rate_multiplier": 0.85},
		{"id": "crouch", "label": "Crouch", "silhouette_fraction": 0.4, "noise_multiplier": 0.5, "fire_rate_multiplier": 0.95},
		{"id": "prone", "label": "Prone", "silhouette_fraction": 0.2, "noise_multiplier": 0.25, "fire_rate_multiplier": 0.9}
	]

static func get_lean_states() -> Array[Dictionary]:
	return [
		{"id": "lean_none", "label": "No Lean", "exposed_zones": ["full_body"], "ads_only": false},
		{"id": "lean_left", "label": "Lean Left", "exposed_zones": ["head"], "ads_only": true},
		{"id": "lean_right", "label": "Lean Right", "exposed_zones": ["head"], "ads_only": true}
	]

static func get_traversal_verbs() -> Array[Dictionary]:
	return [
		{"id": "vault", "label": "Vault Low Cover", "trigger": "sprint_into_low_cover", "cost": "minor_stamina"},
		{"id": "mantle", "label": "Mantle Tall Cover", "trigger": "hold_jump_at_tall_edge", "cost": "moderate_stamina"},
		{"id": "stack_up", "label": "Stack Up at Door", "trigger": "hold_E_on_door", "cost": "ready_state_1_5s_window"},
		{"id": "drag_corpse", "label": "Drag Corpse", "trigger": "hold_E_on_body", "cost": "movement_noise_up_and_one_hand_off_weapon"},
	]

static func get_reload_modes() -> Array[Dictionary]:
	return [
		{"id": "dump", "label": "Dump Reload", "input": "tap_R", "speed": "fast", "preserves_partial_mag": false},
		{"id": "tactical", "label": "Tactical Reload", "input": "hold_R", "speed": "slower", "preserves_partial_mag": true},
		{"id": "manual_check", "label": "Manual Check", "input": "tap_H", "speed": "instant", "preserves_partial_mag": true, "describes_chamber_and_mag": true}
	]

static func get_weapon_malfunctions() -> Array[Dictionary]:
	return [
		{"id": "stovepipe", "label": "Stovepipe", "trigger": "weapon_condition_below_60_and_dirty", "clear_verb": "tap_rack", "clear_seconds": 1.5},
		{"id": "failure_to_feed", "label": "Failure to Feed", "trigger": "magazine_durability_below_50_or_lip_bent", "clear_verb": "tap_rack", "clear_seconds": 1.5},
		{"id": "double_feed", "label": "Double Feed", "trigger": "rare_random_under_50_condition", "clear_verb": "drop_mag_rack_clear", "clear_seconds": 3.5},
		{"id": "hangfire", "label": "Hangfire", "trigger": "ammo_subload_aged", "clear_verb": "wait_then_rack", "clear_seconds": 2.0},
	]

static func get_zeroed_optics() -> Array[Dictionary]:
	return [
		{"id": "reflex_sight", "zero_meters": 25.0, "drop_at_50m": "noticeable", "drop_at_100m": "obvious"},
		{"id": "low_power_scope", "zero_meters": 100.0, "drop_at_50m": "rises_slightly", "drop_at_100m": "on_zero"},
	]

# Bolt-throwing — using any cheap dynamic prop as a hazard probe / sound bait.
static func get_bolt_throw_rules() -> Dictionary:
	return {
		"props_usable": ["cable_spool", "fuse", "tool_parts", "small_scrap"],
		"trips_traps": true,
		"writes_last_heard_position": true,
		"never_consumes_attention_of": ["shellroot", "carapace"]
	}

# Stress shake driving a real camera/weapon micro-tremor, not aim cones.
static func get_stress_shake_rules() -> Dictionary:
	return {
		"inputs": ["pain", "shock", "player_corruption", "low_oxygen"],
		"output_target": "weapon_pivot_and_camera",
		"tremor_form": "micro_pitch_yaw_drift",
		"never_locks_aim": true
	}

# Stealth/senses adds.
static func get_shadow_visibility_table() -> Dictionary:
	return {
		"dark_no_lights": "almost_invisible",
		"sector_emergency_red": "low_visibility",
		"sector_emergency_strobe": "occasional_pings",
		"flashlight_on_player": "fully_visible",
		"sector_full_lights": "fully_visible",
		"echo_class_reads_through_dark": true
	}

static func get_body_hiding_rules() -> Dictionary:
	return {
		"hide_targets": ["closet", "vent_entry", "crawlspace", "supply_drawer"],
		"hidden_corpse_blocks_scent_trigger": true,
		"hidden_corpse_blocks_surgeon_attractor": true,
		"requires_drag_corpse_verb": true
	}

static func get_whistle_shout_rules() -> Dictionary:
	return {
		"verb": "hold_F_shout",
		"baits_archetypes": ["crawler_husk", "stalker_husk"],
		"ignored_by_archetypes": ["carapace", "choir", "shellroot"],
		"single_use_per_room_window_seconds": 30.0,
		"loudness_value": 85.0
	}

static func get_sound_triangulation_rules() -> Dictionary:
	return {
		"requires_module": "sound_meter",
		"shows_direction_arrow": true,
		"never_shows_amplitude_only": true,
		"corruption_can_flip_direction": true
	}

# Diegetic UI / Trust additions.
static func get_comm_wheel_options() -> Array[Dictionary]:
	return [
		{"id": "mark_route", "label": "Mark this route"},
		{"id": "request_solution", "label": "What do I do here?"},
		{"id": "report_kill", "label": "I dropped one"},
		{"id": "request_silence", "label": "Be quiet for a minute"},
		{"id": "request_status", "label": "Where am I?"},
		{"id": "request_lift", "label": "Call me an elevator"},
	]

# Inventory / economy additions.
static func get_attache_case_inventory() -> Dictionary:
	return {
		"id": "attache_case",
		"label": "Attaché Case",
		"grid_size": [6, 4],
		"holds": ["attachments", "splints", "ammo", "stim", "small_tools"],
		"on_drop": "case_pops_open_and_spills"
	}

static func get_safehouse_lockbox() -> Dictionary:
	return {
		"id": "safehouse_lockbox",
		"label": "Safehouse Lockbox",
		"persists_across_deaths_if_reached_in_time": true,
		"reach_time_window_seconds_for_predecessor": 600.0,
		"slots": 4,
		"diegetic": true
	}

static func get_condition_pickup_rules() -> Dictionary:
	return {
		"found_weapon_condition_range": [0.3, 0.95],
		"found_weapon_attachment_durability_range": [0.2, 1.0],
		"suppressor_remaining_uses_range": [10, 220]
	}

static func get_attachment_conflicts() -> Array[Dictionary]:
	return [
		{"a": "foregrip", "b": "bipod", "reason": "underbarrel slot conflict"},
		{"a": "compact_suppressor", "b": "port_compensator", "reason": "muzzle slot conflict"},
		{"a": "extended_magazine", "b": "quickpull_magwell", "reason": "magazine slot conflict"},
		{"a": "reflex_sight", "b": "low_power_scope", "reason": "optic slot conflict"},
		{"a": "laser_pointer", "b": "weapon_light", "reason": "both occupy the rail bracket without an adapter"},
	]

static func get_stack_aware_reload_descriptors() -> Array[String]:
	return [
		"feels light",
		"feels heavy",
		"feels half",
		"rattles, partial",
		"full, fresh",
		"empty"
	]

# Environment / hazards.
static func get_anomaly_rooms() -> Array[Dictionary]:
	return [
		{"id": "moving_radiation_zone", "label": "Reactor Anomaly Room", "verbs": ["throw_pressure_decoy_to_ride_out", "time_movement"], "consumes": ["pressure_decoy"]},
		{"id": "gravity_pocket", "label": "Gravity Pocket", "verbs": ["vault_in", "no_aim_in_zone"], "consumes": []},
		{"id": "static_storm_room", "label": "Static Storm Room", "verbs": ["powerless_electronics_in_zone"], "consumes": []},
	]

static func get_fire_spread_rules() -> Dictionary:
	return {
		"ignites": ["coolant_pool", "oil_pool", "bio_growth"],
		"spread_seconds_per_tile": 1.2,
		"max_spread_seconds": 20.0,
		"ignite_sources": ["torch_lance", "incendiary_round", "arc_junction_overload"]
	}

static func get_electrified_water_rules() -> Dictionary:
	return {
		"sources": ["coolant_flood", "burst_pipe", "open_drain"],
		"trigger_arc_junctions": ["arc_junction"],
		"stuns_entities_in_zone": true,
		"stun_seconds": 3.5
	}

static func get_pressure_differential_rules() -> Dictionary:
	return {
		"trigger_events": ["airlock_cycle", "broken_window", "vented_panel"],
		"pulls_props_and_corpses_toward_breach": true,
		"pull_seconds": 6.0,
		"during_pull": "first_person_camera_resists_with_micro_tremor"
	}

static func get_temperature_rules() -> Dictionary:
	return {
		"low_temp_zones": ["exterior_works", "broken_vent_stack", "vacuum_pocket"],
		"high_temp_zones": ["industrial_core_steam", "reactor_anomaly_room"],
		"low_temp_effects_on_player": ["bleed_rate_slows", "pain_recovery_slows", "stamina_recovery_slows"],
		"high_temp_effects_on_player": ["bleed_rate_rises", "shock_recovery_slows"],
		"counter_low_temp_items": ["thermal_overlayer", "heat_pack"],
		"counter_high_temp_items": ["coolant_canister", "wetted_undersuit"]
	}

# Survivor identity — tangible liabilities replacing pure numeric perks.
# Each background now lists a real concrete benefit AND a real concrete cost,
# and a flag the runtime can check by name.
static func get_background_liabilities() -> Array[Dictionary]:
	return [
		{"id": "Engineer", "benefit_verb": "sector_restore_uses_one_less_tool_part", "liability_flag": "arm_fracture_recovery_slower_until_splint_at_workbench"},
		{"id": "Security", "benefit_verb": "panic_reload_drop_threshold_raised", "liability_flag": "trauma_kit_use_seconds_extended"},
		{"id": "Medic", "benefit_verb": "trauma_kit_use_seconds_shortened", "liability_flag": "loud_movement_when_carrying_two_med_items"},
		{"id": "Researcher", "benefit_verb": "module_contradictions_show_a_tell_glyph", "liability_flag": "panic_reload_drop_threshold_lowered"},
		{"id": "Miner", "benefit_verb": "thermal_tool_overheat_warning_30s_earlier", "liability_flag": "vent_route_fatigue_drain_increased"},
		{"id": "Courier", "benefit_verb": "carries_one_extra_attache_case_row", "liability_flag": "louder_steps_when_full"},
		{"id": "Survey Tech", "benefit_verb": "spots_one_extra_hidden_route_per_floor", "liability_flag": "map_sketching_corruption_false_dead_ends_higher"},
		{"id": "Prisoner", "benefit_verb": "pain_does_not_block_first_treatment_per_floor", "liability_flag": "no_access_credential_pickups_will_open_admin_doors"},
	]

# Kit case persists per-survivor identity in the lost kit.
static func get_kit_case_definition() -> Dictionary:
	return {
		"id": "kit_case",
		"label": "Personal Kit Case",
		"per_survivor": true,
		"serialized_into_lost_kit": true,
		"contents_categories": ["belt", "splints", "small_ammo", "personal_id_tag"]
	}

# Encountered NPC survivors — concrete branch outcomes only.
static func get_npc_survivor_encounters() -> Array[Dictionary]:
	return [
		{"id": "wounded_courier", "label": "Wounded Courier", "verbs": ["help_with_med_stock", "leave", "loot_after_death"], "guaranteed_outcome_help": "gives_route_chalk_mark_to_next_objective"},
		{"id": "panicked_researcher", "label": "Panicked Researcher", "verbs": ["calm_with_neural_stabilizer", "lock_in_room", "kill"], "guaranteed_outcome_calm": "shares_one_glyph_tell_for_corruption_ui"},
		{"id": "trapped_engineer", "label": "Trapped Engineer", "verbs": ["free_with_cutting_charge", "leave_in_place", "argue"], "guaranteed_outcome_free": "permanently_restores_one_adjacent_sector_light"},
	]

# Predecessor ghost route fed into route_mapper.
static func get_predecessor_ghost_rules() -> Dictionary:
	return {
		"requires_module": "route_mapper",
		"trail_seconds_recorded": 60.0,
		"render": "dotted_trail_in_overlay_only",
		"corruption_can_distort_endpoint": true
	}

# Floor-as-chapter identity locks and unique pickups.
static func get_chapter_floor_identities() -> Array[Dictionary]:
	return [
		{"id": "medical_deck", "lock_kind": "biohazard_lock", "unique_pickups": ["pharma_vial", "field_cauterizer_pen", "stim_injector"]},
		{"id": "industrial_core", "lock_kind": "crusher_steam_block", "unique_pickups": ["cutting_charge", "industrial_slug", "coolant_canister"]},
		{"id": "research_vault", "lock_kind": "anomaly_seal", "unique_pickups": ["specimen_lens", "brainwave_reader", "neural_stabilizer"]},
		{"id": "admin_spine", "lock_kind": "credentials_chip_required", "unique_pickups": ["access_credential", "executive_lift_key", "admin_audio_log"]},
		{"id": "hab_ring", "lock_kind": "personal_locker_keyed", "unique_pickups": ["personal_log", "kit_case", "safehouse_lockbox_key"]},
		{"id": "exterior_works", "lock_kind": "airlock_cycle", "unique_pickups": ["suit_patch", "boot_grips", "lighthouse_fuse"]},
	]

# Resource decay across floors. Cleared floors stop respawning resources.
static func get_resource_decay_rules() -> Dictionary:
	return {
		"floor_marked_cleared_when": "all_objective_unlocks_used_and_player_descended",
		"cleared_floor_respawns_resources": false,
		"surgeon_can_still_arrive_on_cleared_floor": true,
		"safehouse_lockbox_remains_accessible": true
	}

# Lighthouse beacons re-power comms safe radius.
static func get_lighthouse_beacons() -> Array[Dictionary]:
	return [
		{"id": "antenna_lighthouse", "label": "Antenna Lighthouse", "module": "exterior_works", "verb": "restore_power", "resource": "fuse", "amount": 2, "extends_safe_comms_radius_to": "next_two_floors", "acts_as_rest_point": true},
		{"id": "research_relay", "label": "Research Relay", "module": "research_vault", "verb": "restore_power", "resource": "power_cell", "amount": 1, "extends_safe_comms_radius_to": "current_and_adjacent_floor", "acts_as_rest_point": true},
		{"id": "admin_uplink", "label": "Admin Uplink", "module": "admin_spine", "verb": "restore_power", "resource": "access_credential", "amount": 1, "extends_safe_comms_radius_to": "current_and_adjacent_floor", "acts_as_rest_point": true},
	]

# Audio logs scattered through the station. Corruption rewrites them on
# replay through the field_recorder.
static func get_audio_logs() -> Array[Dictionary]:
	return [
		{"id": "log_med_triage_01", "module": "medical_deck", "topic": "first triage shift after the breach"},
		{"id": "log_admin_purge_02", "module": "admin_spine", "topic": "the order to seal exterior_works"},
		{"id": "log_engineer_reactor_03", "module": "industrial_core", "topic": "what the engineer heard in the crusher loop"},
		{"id": "log_researcher_subject_04", "module": "research_vault", "topic": "the subject that started speaking back"},
		{"id": "log_courier_dropbox_05", "module": "hab_ring", "topic": "a goodbye to family on the inner colonies"},
	]

# --- Lookup helpers for tangible mechanics ------------------------------------

static func get_door_wedge(wedge_id: String) -> Dictionary:
	for wedge in get_door_wedges():
		if String(wedge["id"]) == wedge_id:
			return wedge
	return {}

static func get_chemical_flare(flare_id: String) -> Dictionary:
	for flare in get_chemical_flares():
		if String(flare["id"]) == flare_id:
			return flare
	return {}

static func get_salvage_id_tag(tag_id: String) -> Dictionary:
	for tag in get_salvage_id_tags():
		if String(tag["id"]) == tag_id:
			return tag
	return {}

static func get_attachment_conflict_pairs() -> Array[Array]:
	var pairs: Array[Array] = []
	for entry in get_attachment_conflicts():
		pairs.append([String(entry["a"]), String(entry["b"])])
	return pairs

static func attachments_conflict(attachment_a: String, attachment_b: String) -> bool:
	for pair in get_attachment_conflict_pairs():
		if (pair[0] == attachment_a and pair[1] == attachment_b) or (pair[0] == attachment_b and pair[1] == attachment_a):
			return true
	return false

# --- Extended economy items (consumables, tools, deployables) ---

static func get_extended_economy_items() -> Array[Dictionary]:
	return [
		{
			"id": "hemostatic_gauze",
			"label": "Hemostatic Gauze",
			"uses": ["stop_bleed_limb", "reduce_bleed_rate"],
			"apply_time": "slow",
			"slot": "pouch",
			"notes": "packs a wound; buys time before full treatment"
		},
		{
			"id": "tourniquet",
			"label": "Tourniquet",
			"uses": ["stop_bleed_arm", "stop_bleed_leg", "sever_circulation_for_splint"],
			"apply_time": "fast",
			"slot": "pouch",
			"notes": "stops bleed instantly; movement penalty on affected limb"
		},
		{
			"id": "blood_bag_iv",
			"label": "Blood Bag IV",
			"uses": ["restore_blood_volume", "remove_hypovolemic_shock"],
			"apply_time": "very_slow",
			"slot": "inventory",
			"notes": "requires sitting still; best used at safehouse or behind cover"
		},
		{
			"id": "antibiotic_syringe",
			"label": "Antibiotic Syringe",
			"uses": ["clear_surface_infection", "slow_deep_infection", "halt_bio_contamination"],
			"apply_time": "fast",
			"slot": "pouch",
			"notes": "only course-correct for infection; does not heal wounds"
		},
		{
			"id": "radiation_tabs",
			"label": "Radiation Tabs",
			"uses": ["reduce_rad_exposure_tier", "delay_rad_sickness_onset"],
			"apply_time": "instant",
			"slot": "pouch",
			"notes": "one tab drops exposure one tier; multiple tabs queue"
		},
		{
			"id": "decon_wipes",
			"label": "Decon Wipes",
			"uses": ["clear_bio_contamination_surface", "remove_scent_trail", "clear_footprint_transfer"],
			"apply_time": "fast",
			"slot": "pouch",
			"notes": "removes tracked residue from boots and hands"
		},
		{
			"id": "oxygen_sniffer",
			"label": "Oxygen Sniffer",
			"uses": ["detect_oxygen_thin_zone", "warn_pressure_breach_approach"],
			"apply_time": "passive",
			"slot": "pouch",
			"notes": "audible chirp accelerates as O2 drops; silent model uses glasses display"
		},
		{
			"id": "glow_stick",
			"label": "Glow Stick",
			"uses": ["place_persistent_light", "mark_route", "lure_echo_archetype"],
			"apply_time": "instant",
			"slot": "pouch",
			"duration": "long",
			"notes": "dim but lasts hours; attracts echo; does not require power"
		},
		{
			"id": "door_charge_patch",
			"label": "Door Charge Patch",
			"uses": ["breach_locked_door", "destroy_lock_housing", "clear_jammed_door"],
			"apply_time": "slow",
			"slot": "inventory",
			"notes": "adheres to door surface; detonated remotely up to eight meters"
		},
		{
			"id": "whisker_probe",
			"label": "Whisker Probe",
			"uses": ["detect_gas_under_door", "sample_air_composition", "sense_heat_gradient"],
			"apply_time": "fast",
			"slot": "pouch",
			"notes": "slip under door gap; read result on glasses or by earpiece tone"
		},
		{
			"id": "bone_conduction_mic",
			"label": "Bone Conduction Mic",
			"uses": ["listen_through_wall", "hear_enemy_breathing_adjacent", "detect_stalker_husk_proximity"],
			"apply_time": "fast",
			"slot": "pouch",
			"notes": "press against bulkhead; audible up to two rooms; noisy armor degrades result"
		},
		{
			"id": "signal_jammer",
			"label": "Signal Jammer",
			"uses": ["block_relay_voice_broadcast", "prevent_echo_coordination", "disable_locked_keypad"],
			"apply_time": "slow",
			"slot": "inventory",
			"duration": "medium",
			"notes": "placed device; also blocks player comms in radius while active"
		},
		{
			"id": "bioscanner_patch",
			"label": "Bioscanner Patch",
			"uses": ["detect_sleeper_pod_dormant", "locate_bio_growth_source", "tag_bleeding_enemy"],
			"apply_time": "passive",
			"slot": "glasses_module",
			"power_draw": "low",
			"notes": "wet mass signature only; walls block scan; carapace shielded"
		},
		{
			"id": "stasis_foam_canister",
			"label": "Stasis Foam Canister",
			"uses": ["seal_pressure_breach_small", "slow_door_forced_open", "immobilize_crawler_husk"],
			"apply_time": "fast",
			"slot": "inventory",
			"notes": "hardens on contact; one canister seals one small breach or jams one door"
		},
		{
			"id": "ferrofluid_lure",
			"label": "Ferrofluid Lure",
			"uses": ["attract_carapace_archetype", "mark_floor_visible_to_glasswalker", "block_magnetic_lock"],
			"apply_time": "instant",
			"slot": "pouch",
			"notes": "splatter on floor; magnetic archetypes divert toward strongest concentration"
		},
		{
			"id": "grapple_clamp",
			"label": "Grapple Clamp",
			"uses": ["traverse_shaft_vertical", "anchor_rope_for_successor", "yank_enemy_off_ledge"],
			"apply_time": "slow",
			"slot": "inventory",
			"notes": "anchors to vent grilles or pipe flanges; rope stays for successor run"
		},
		{
			"id": "cryo_patch",
			"label": "Cryo Patch",
			"uses": ["reduce_high_temp_exposure", "slow_bleed_rate_temporarily", "extend_low_temp_tolerance"],
			"apply_time": "fast",
			"slot": "pouch",
			"notes": "adhesive cooling element; single use; pairs with blood_bag_iv for field stabilization"
		},
		{
			"id": "breaching_slug",
			"label": "Breaching Slug",
			"uses": ["destroy_lock_housing_at_range", "crack_carapace_plate_at_range", "breach_pressure_door_weak_point"],
			"apply_time": "passive",
			"slot": "weapon_magazine",
			"notes": "12ga subload; single shell; extremely loud; one-shot barrier interaction"
		},
	]

# --- Extended wearable modules ---

static func get_extended_wearable_modules() -> Array[Dictionary]:
	return [
		{
			"id": "blood_pressure_cuff",
			"label": "Blood Pressure Cuff",
			"slot": "wrist",
			"power_draw": "none",
			"passive": true,
			"effect": "display_hypovolemic_warning_and_bleed_rate",
			"notes": "purely mechanical; always accurate regardless of corruption"
		},
		{
			"id": "geiger_counter_module",
			"label": "Geiger Counter",
			"slot": "glasses_module",
			"power_draw": "low",
			"passive": true,
			"effect": "display_rad_exposure_tier_and_zone_intensity",
			"notes": "audible ticks always play regardless of glasses display state"
		},
		{
			"id": "infection_sentinel",
			"label": "Infection Sentinel",
			"slot": "glasses_module",
			"power_draw": "low",
			"passive": true,
			"effect": "display_infection_stage_and_antibiotic_countdown",
			"notes": "corrupted display may show wrong stage name; tone cue remains truthful"
		},
		{
			"id": "proximity_silhouette_detector",
			"label": "Proximity Silhouette Detector",
			"slot": "glasses_module",
			"power_draw": "high",
			"passive": true,
			"effect": "draw_wire_outline_enemies_within_four_meters_through_wall",
			"notes": "high draw; glasswalker and mimic_prop suppress their own signature"
		},
		{
			"id": "oxygen_meter",
			"label": "Oxygen Meter",
			"slot": "wrist",
			"power_draw": "none",
			"passive": true,
			"effect": "display_local_o2_level_and_time_to_hypoxia",
			"notes": "wrist-mount; readable even if glasses are cracked or powered off"
		},
		{
			"id": "rad_dose_counter",
			"label": "Rad Dose Counter",
			"slot": "glasses_module",
			"power_draw": "minimal",
			"passive": true,
			"effect": "display_cumulative_rad_dose_and_safe_daily_limit_remaining",
			"notes": "cumulative; resets at safehouse rest only"
		},
		{
			"id": "motion_blur_suppressor",
			"label": "Motion Blur Suppressor",
			"slot": "glasses_module",
			"power_draw": "low",
			"passive": true,
			"effect": "cancel_stress_shake_visual_and_reduce_sway_during_sprint",
			"notes": "counteracts corruption-induced visual shake; does not affect actual aim spread"
		},
	]

# --- Extended weapon attachments ---

static func get_extended_weapon_attachments() -> Array[Dictionary]:
	return [
		{
			"id": "bipod",
			"label": "Bipod",
			"slot": "underbarrel",
			"compatible_families": ["rifle_ballistic", "industrial_slug"],
			"effect_deployed": "eliminate_sway_when_prone_or_braced",
			"effect_undeployed": "minor_handling_penalty",
			"deploy_verb": "brace_bipod"
		},
		{
			"id": "cheek_rest",
			"label": "Cheek Rest",
			"slot": "stock",
			"compatible_families": ["rifle_ballistic", "heavy_ballistic", "shotgun_ballistic"],
			"effect": "reduce_time_to_first_accurate_shot_from_low_ready",
			"notes": "paired with zeroed optic for maximum benefit"
		},
		{
			"id": "heat_shield",
			"label": "Heat Shield",
			"slot": "body",
			"compatible_families": ["rifle_ballistic", "shotgun_ballistic"],
			"effect": "prevent_arm_burn_from_sustained_fire",
			"notes": "suppresses heat transfer to hands; no effect on weapon_condition degradation"
		},
		{
			"id": "drum_magazine",
			"label": "Drum Magazine",
			"slot": "magazine",
			"compatible_families": ["light_ballistic", "rifle_ballistic"],
			"effect": "double_capacity_increase_reload_time_and_noise",
			"notes": "rattles audibly when moving; partial drum tactile feel is unreliable"
		},
		{
			"id": "wire_wrapped_stock",
			"label": "Wire-Wrapped Stock",
			"slot": "stock",
			"compatible_families": ["light_ballistic", "heavy_ballistic", "rifle_ballistic", "shotgun_ballistic"],
			"effect": "improve_grip_when_hands_wet_or_bloody",
			"notes": "crude field mod; no durability loss but adds minor weight"
		},
		{
			"id": "folding_stock",
			"label": "Folding Stock",
			"slot": "stock",
			"compatible_families": ["light_ballistic", "rifle_ballistic"],
			"effect_folded": "fit_weapon_in_backpack_slot_not_sling",
			"effect_unfolded": "normal_handling",
			"notes": "folding takes a moment; folded weapons cannot be fired"
		},
		{
			"id": "ported_barrel",
			"label": "Ported Barrel",
			"slot": "muzzle",
			"compatible_families": ["heavy_ballistic", "rifle_ballistic"],
			"effect": "reduce_muzzle_rise_increase_noise_signature",
			"notes": "incompatible with any suppressor; ports redirect gas upward and outward"
		},
		{
			"id": "muzzle_brake",
			"label": "Muzzle Brake",
			"slot": "muzzle",
			"compatible_families": ["rifle_ballistic", "industrial_slug", "shotgun_ballistic"],
			"effect": "reduce_felt_recoil_increase_muzzle_blast_radius",
			"notes": "nearby enemies react to concussive blast; suppressor incompatible"
		},
	]

# --- Extended attachment conflict pairs ---

static func get_extended_attachment_conflicts() -> Array[Dictionary]:
	return [
		{"a": "cheek_rest", "b": "wire_wrapped_stock", "reason": "stock_slot_occupied"},
		{"a": "muzzle_brake", "b": "compact_suppressor", "reason": "muzzle_slot_occupied"},
		{"a": "muzzle_brake", "b": "ported_barrel", "reason": "muzzle_slot_occupied"},
		{"a": "ported_barrel", "b": "compact_suppressor", "reason": "vents_negate_suppression"},
		{"a": "drum_magazine", "b": "extended_magazine", "reason": "magazine_slot_occupied"},
		{"a": "bipod", "b": "foregrip", "reason": "underbarrel_slot_occupied"},
		{"a": "folding_stock", "b": "cheek_rest", "reason": "stock_slot_occupied"},
		{"a": "folding_stock", "b": "wire_wrapped_stock", "reason": "stock_slot_occupied"},
		{"a": "heat_shield", "b": "laser_designator", "reason": "body_slot_occupied"},
		{"a": "bipod", "b": "laser_designator", "reason": "underbarrel_slot_occupied"},
		{"a": "drum_magazine", "b": "subsonic_magazine", "reason": "magazine_slot_occupied"},
		{"a": "muzzle_brake", "b": "flash_hider", "reason": "muzzle_slot_occupied"},
		{"a": "ported_barrel", "b": "flash_hider", "reason": "muzzle_slot_occupied"},
	]

# --- Extended floor traversal routes ---

static func get_extended_floor_routes() -> Array[Dictionary]:
	return [
		{
			"id": "emergency_blast_door_override",
			"label": "Emergency Blast Door Override",
			"floor_delta": 1,
			"access_kind": "panel",
			"unlock": "access_credential",
			"condition": "power_online_in_corridor",
			"notes": "only accessible if corridor power restored; opens both directions"
		},
		{
			"id": "specimen_tube_transit",
			"label": "Specimen Tube Transit",
			"floor_delta": 2,
			"access_kind": "crawl",
			"unlock": "none",
			"condition": "specimen_containment_unit_offline",
			"notes": "research vault to medical deck; requires containment unit deactivated first"
		},
		{
			"id": "collapsed_ceiling_crawl",
			"label": "Collapsed Ceiling Crawl",
			"floor_delta": 1,
			"access_kind": "climb",
			"unlock": "none",
			"condition": "structural_zone_state_collapsed",
			"notes": "opens when ceiling buckles; unstable_ceiling state precedes it"
		},
		{
			"id": "water_reclaim_pipe",
			"label": "Water Reclaim Pipe",
			"floor_delta": -1,
			"access_kind": "crawl",
			"unlock": "none",
			"condition": "pipe_drained",
			"notes": "goes down one floor; player must drain it with coolant_canister first"
		},
		{
			"id": "reactor_heat_shaft",
			"label": "Reactor Heat Shaft",
			"floor_delta": 3,
			"access_kind": "climb",
			"unlock": "none",
			"condition": "reactor_vented_and_heat_shield_equipped",
			"notes": "skip three floors but requires heat_shield attachment to survive passage"
		},
	]

# --- Extended environmental kills ---

static func get_extended_environmental_kills() -> Array[Dictionary]:
	return [
		{
			"id": "specimen_containment_breach",
			"label": "Specimen Containment Breach",
			"trigger": "shoot_containment_unit_while_active",
			"result": "release_bio_growth_flood_room",
			"tags": ["bio_growth", "high_temp"],
			"lures": ["carrion_eater", "shellroot"],
			"notes": "containment fluid ignites on sustained fire; growth clears with fire"
		},
		{
			"id": "oil_slick_ignition",
			"label": "Oil Slick Ignition",
			"trigger": "fire_tag_contacts_oil_slick_zone",
			"result": "floor_fire_spreads_to_adjacent_tiles",
			"tags": ["fire", "high_temp", "smoke"],
			"lures": ["shellroot"],
			"notes": "oil spreads from tipped tanks; fire follows spread boundary"
		},
		{
			"id": "structural_collapse_trigger",
			"label": "Structural Collapse",
			"trigger": "explosive_in_stressed_zone",
			"result": "zone_state_becomes_collapsed_creates_crawlspace_and_blocks_route",
			"tags": ["smoke"],
			"notes": "prerequisite buckling state; collapse is permanent for the run"
		},
		{
			"id": "bio_growth_eruption",
			"label": "Bio Growth Eruption",
			"trigger": "high_temp_tag_contacts_mature_bio_growth",
			"result": "spore_burst_infects_unmasked_targets_in_radius",
			"tags": ["bio_growth", "smoke"],
			"lures": ["shellroot", "carrion_eater"],
			"notes": "player without decon_wipes acquires surface_infection immediately"
		},
		{
			"id": "gravity_anchor_rip",
			"label": "Gravity Anchor Rip",
			"trigger": "grapple_clamp_applied_to_enemy_at_shaft_edge",
			"result": "enemy_pulled_into_shaft_instant_lethal",
			"tags": [],
			"notes": "works on any non-shellroot enemy; shellroot anchors resist pull"
		},
		{
			"id": "decon_shower_burst",
			"label": "Decon Shower Burst",
			"trigger": "activate_decon_shower_station_while_enemy_inside",
			"result": "chemical_spray_strips_bio_growth_and_inflicts_deep_wound_carapace",
			"tags": ["water", "gas"],
			"notes": "decon chemical is corrosive to carapace plate specifically"
		},
		{
			"id": "coolant_pipe_rupture",
			"label": "Coolant Pipe Rupture",
			"trigger": "shoot_marked_pipe_joint",
			"result": "coolant_flood_zone_combo_ready_for_electric",
			"tags": ["coolant", "low_temp"],
			"notes": "pipe joint marked by orange stripe; rupture persists until player patches it"
		},
	]

# --- Workbench crafting recipes ---

static func get_workbench_crafting_recipes() -> Array[Dictionary]:
	return [
		{
			"id": "noise_lure_from_speaker",
			"label": "Wired Noise Lure",
			"inputs": ["earpiece_patch", "cable_spool", "fuse"],
			"output": "noise_lure",
			"time_seconds": 12,
			"noise": "quiet",
			"requires_workbench": true
		},
		{
			"id": "makeshift_suppressor",
			"label": "Makeshift Suppressor",
			"inputs": ["suppressor_wrap", "tool_parts", "coolant_canister"],
			"output": "compact_suppressor",
			"time_seconds": 20,
			"noise": "quiet",
			"requires_workbench": true
		},
		{
			"id": "splint_from_parts",
			"label": "Field Splint",
			"inputs": ["splint_roll", "tool_parts"],
			"output": "splint_reinforced",
			"time_seconds": 8,
			"noise": "silent",
			"requires_workbench": false
		},
		{
			"id": "trip_mine_from_charge",
			"label": "Trip Mine",
			"inputs": ["door_charge_patch", "cable_spool", "magnetic_puller"],
			"output": "trip_mine",
			"time_seconds": 18,
			"noise": "silent",
			"requires_workbench": true
		},
		{
			"id": "chemical_flare_from_canister",
			"label": "Chemical Flare",
			"inputs": ["stasis_foam_canister", "static_charge"],
			"output": "chemical_flare",
			"time_seconds": 6,
			"noise": "silent",
			"requires_workbench": false
		},
		{
			"id": "signal_jammer_from_parts",
			"label": "Field Signal Jammer",
			"inputs": ["tool_parts", "earpiece_patch", "power_cell"],
			"output": "signal_jammer",
			"time_seconds": 24,
			"noise": "quiet",
			"requires_workbench": true
		},
		{
			"id": "hemostatic_gauze_from_medstock",
			"label": "Hemostatic Gauze",
			"inputs": ["med_stock"],
			"output": "hemostatic_gauze",
			"time_seconds": 4,
			"noise": "silent",
			"requires_workbench": false
		},
		{
			"id": "glow_stick_from_flare_chemical",
			"label": "Glow Stick",
			"inputs": ["chemical_flare", "coolant_canister"],
			"output": "glow_stick",
			"time_seconds": 5,
			"noise": "silent",
			"requires_workbench": false
		},
		{
			"id": "door_wedge_reinforced",
			"label": "Reinforced Door Wedge",
			"inputs": ["door_wedge", "tool_parts"],
			"output": "door_wedge_reinforced",
			"time_seconds": 10,
			"noise": "quiet",
			"requires_workbench": true
		},
		{
			"id": "ferrofluid_lure_from_charge",
			"label": "Ferrofluid Lure",
			"inputs": ["static_charge", "coolant_canister"],
			"output": "ferrofluid_lure",
			"time_seconds": 8,
			"noise": "silent",
			"requires_workbench": false
		},
	]

# --- Prop interaction catalog ---

static func get_prop_interaction_catalog() -> Array[Dictionary]:
	return [
		{
			"id": "pressure_valve",
			"label": "Pressure Valve",
			"verbs": ["turn_open", "turn_closed", "force_open"],
			"effects": {
				"turn_open": "release_steam_tag_into_room",
				"turn_closed": "cut_steam_tag_from_room",
				"force_open": "rupture_pipe_release_steam_burst_and_damage_valve"
			}
		},
		{
			"id": "emergency_bulkhead_lever",
			"label": "Emergency Bulkhead Lever",
			"verbs": ["pull", "lock", "sabotage"],
			"effects": {
				"pull": "seal_bulkhead_door_state_sealed",
				"lock": "prevent_lever_use_until_unlocked",
				"sabotage": "freeze_lever_in_current_state_permanently"
			}
		},
		{
			"id": "generator_fuel_tank",
			"label": "Generator Fuel Tank",
			"verbs": ["inspect", "drain", "ignite"],
			"effects": {
				"inspect": "reveal_fuel_level_low_medium_full",
				"drain": "render_generator_non_functional_spill_oil_slick",
				"ignite": "trigger_oil_slick_ignition_chain"
			}
		},
		{
			"id": "specimen_containment_unit",
			"label": "Specimen Containment Unit",
			"verbs": ["inspect", "deactivate", "shoot"],
			"effects": {
				"inspect": "reveal_contents_and_containment_integrity",
				"deactivate": "open_specimen_tube_transit_route",
				"shoot": "trigger_specimen_containment_breach_environmental_kill"
			}
		},
		{
			"id": "data_terminal",
			"label": "Data Terminal",
			"verbs": ["access", "insert_credential", "hard_reset"],
			"effects": {
				"access": "display_room_map_fragment_and_last_logged_event",
				"insert_credential": "unlock_access_credential_door_or_cache",
				"hard_reset": "wipe_lock_credentials_and_drop_door_to_jammed"
			}
		},
		{
			"id": "medical_cot",
			"label": "Medical Cot",
			"verbs": ["rest", "treat_wound", "search"],
			"effects": {
				"rest": "slow_bleed_rate_and_reduce_infection_stage_timer",
				"treat_wound": "apply_med_stock_with_doubled_effectiveness",
				"search": "chance_find_med_stock_or_crash_kit"
			}
		},
		{
			"id": "armory_locker",
			"label": "Armory Locker",
			"verbs": ["open", "force_open", "breach"],
			"effects": {
				"open": "access_cached_weapon_or_ammo_if_unlocked",
				"force_open": "noise_loud_and_door_forced_tag_applied_to_room",
				"breach": "use_door_charge_patch_silent_but_destroys_contents_partially"
			}
		},
		{
			"id": "corpse_disposal_chute",
			"label": "Corpse Disposal Chute",
			"verbs": ["open", "deposit_body", "crawl_in"],
			"effects": {
				"open": "reveal_chute_shaft_to_floor_below",
				"deposit_body": "remove_body_from_room_deny_carrion_eater_feed",
				"crawl_in": "traverse_to_floor_below_one_way_no_return"
			}
		},
		{
			"id": "vault_keypad",
			"label": "Vault Keypad",
			"verbs": ["enter_code", "bypass_with_credential", "destroy"],
			"effects": {
				"enter_code": "unlock_if_code_correct_otherwise_alert_signal",
				"bypass_with_credential": "unlock_silently_and_consume_access_credential",
				"destroy": "trigger_door_forced_reputation_tag_and_seal_door_permanently"
			}
		},
		{
			"id": "reinforced_floor_panel",
			"label": "Reinforced Floor Panel",
			"verbs": ["pry_open", "cut_with_cutting_charge", "knock_to_listen"],
			"effects": {
				"pry_open": "reveal_sub_floor_crawl_space_if_structural_zone_stable",
				"cut_with_cutting_charge": "create_opening_and_drop_structural_zone_to_stressed",
				"knock_to_listen": "hear_enemy_movement_in_room_below"
			}
		},
		{
			"id": "portable_generator_cart",
			"label": "Portable Generator Cart",
			"verbs": ["start", "refuel", "push_to_room"],
			"effects": {
				"start": "restore_power_to_adjacent_sockets_and_doors",
				"refuel": "requires_power_cell_extends_run_time",
				"push_to_room": "relocate_power_supply_to_target_room"
			}
		},
		{
			"id": "decon_shower_station",
			"label": "Decon Shower Station",
			"verbs": ["activate", "hold_enemy_inside", "sabotage"],
			"effects": {
				"activate": "clear_bio_contamination_from_player_and_emit_water_gas_tags",
				"hold_enemy_inside": "trigger_decon_shower_burst_environmental_kill",
				"sabotage": "overload_nozzles_fill_room_with_gas_tag"
			}
		},
		{
			"id": "comms_relay_node",
			"label": "Comms Relay Node",
			"verbs": ["repair", "broadcast_noise_lure", "destroy"],
			"effects": {
				"repair": "restore_comms_signal_to_floor_and_increase_trust_delta",
				"broadcast_noise_lure": "transmit_noise_lure_sound_through_speaker_network",
				"destroy": "silence_relay_voice_archetype_on_floor_until_repaired"
			}
		},
	]

# --- Environmental propagation rules ---

static func get_smoke_propagation_rules() -> Dictionary:
	return {
		"movement": "follows_pressure_differential_toward_pressure_breach",
		"stacking": "multiple_sources_increase_haze_density_tier",
		"tiers": ["clear", "thin_haze", "heavy_haze", "blinding"],
		"haze_effects": {
			"thin_haze": "reduce_sight_range",
			"heavy_haze": "reduce_sight_range_and_cough_noise",
			"blinding": "near_zero_sight_and_fire_spreads_slowly"
		},
		"archetype_immunity": ["echo"],
		"clears_via": ["pressure_breach", "ventilation_active", "fire_starves"]
	}

static func get_oil_slick_rules() -> Dictionary:
	return {
		"origin": "tipped_generator_fuel_tank_or_damaged_machinery",
		"spread": "flows_downhill_or_along_floor_cracks_up_to_four_meters",
		"ignition_sources": ["fire_tag", "static_charge", "sparking_electric_tag"],
		"slip_chance": "any_character_crossing_at_run_speed_may_stumble",
		"fire_multiplier": "fire_on_oil_spreads_faster_and_intensifies",
		"extinguish_via": ["coolant_tag", "stasis_foam_canister"],
		"tracks_boots": "characters_crossing_slick_leave_oil_footprints"
	}

static func get_radiation_exposure_rules() -> Dictionary:
	return {
		"tiers": ["trace", "low", "moderate", "high", "critical"],
		"tier_effects": {
			"trace": "none",
			"low": "geiger_chirp_and_rad_dose_counter_update",
			"moderate": "vision_grain_and_nausea_slow",
			"high": "bleed_rate_increase_and_manual_aim_shake",
			"critical": "organ_failure_rapid_lethal_if_untreated"
		},
		"mitigation": {
			"radiation_tabs": "drop_one_tier_per_tab",
			"leaving_zone": "exposure_tier_holds_for_ninety_seconds_then_decays",
			"rad_dose_counter": "warns_before_high_tier"
		},
		"zone_sources": ["reactor_core_breach", "irradiated_specimen_fluid", "damaged_rad_shielding"]
	}

static func get_footprint_tracking_rules() -> Dictionary:
	return {
		"substances": ["blood", "coolant", "oil", "bio_growth_spore"],
		"transfer": "player_crossing_tagged_tile_coats_boots_for_up_to_ten_steps",
		"visibility": "footprints_visible_as_residue_marks_on_clean_floor",
		"trackers": ["bleeder", "stalker_husk", "surgeon"],
		"counter": "decon_wipes_clear_boot_coating_and_erase_trail",
		"persistence": "footprints_remain_for_the_run_unless_cleaned"
	}

static func get_campfire_rules() -> Dictionary:
	return {
		"craft_inputs": ["tool_parts", "cable_spool"],
		"craft_time": "slow",
		"requires_workbench": false,
		"warmth_radius": "three_meters",
		"effects": {
			"player_in_warmth": "slow_bleed_rate_rise_from_high_temp_and_dry_wet_suit",
			"light_emitted": "medium_glow_attracts_echo_and_carrion_eater",
			"fire_tag": "fire_tag_active_for_reaction_chains"
		},
		"repels": ["echo"],
		"attracts": ["stalker_husk", "carrion_eater"],
		"extinguish_via": ["coolant_tag", "stasis_foam_canister", "water_tag"]
	}

static func get_noise_trap_creation_rules() -> Dictionary:
	return {
		"components": ["earpiece_patch", "cable_spool", "fuse"],
		"wire_to": "powered_speaker_or_comms_relay_node",
		"trigger": "tripwire_or_remote_via_earpiece_patch",
		"sound_output": "loud_sharp_noise_burst_at_speaker_location",
		"lures": ["stalker_husk", "crawler_husk", "echo"],
		"alarm_raises": "noise_pressure_in_threat_director",
		"limitations": "speaker_must_have_power; cable_spool_consumed_on_placement"
	}

static func get_room_barricade_state_rules() -> Dictionary:
	return {
		"states": ["open", "lightly_barricaded", "heavily_barricaded", "sealed"],
		"state_effects": {
			"open": "normal_enemy_and_player_movement",
			"lightly_barricaded": "slow_enemy_forced_entry_noise_door_forced_tag",
			"heavily_barricaded": "require_cutting_charge_or_prolonged_forced_entry",
			"sealed": "impassable_without_breach_door_charge_patch_or_structural_collapse"
		},
		"persistence": "state_survives_across_survivor_runs",
		"build_materials": {
			"lightly_barricaded": ["door_wedge"],
			"heavily_barricaded": ["door_wedge", "cable_spool", "tool_parts"],
			"sealed": ["cutting_charge", "tool_parts", "cable_spool"]
		},
		"decay": "enemies_with_forced_entry_trait_downgrade_one_tier_per_assault"
	}

static func get_speaker_network_rules() -> Dictionary:
	return {
		"requirement": "comms_relay_node_repaired_on_floor",
		"archetype_uses": {
			"relay_voice": "broadcasts_misdirection_audio_through_repaired_nodes",
		},
		"player_uses": {
			"broadcast_noise_lure": "transmit_noise_lure_to_any_active_speaker_on_floor",
			"hear_adjacent_room": "passive_audio_bleed_from_connected_rooms"
		},
		"disable_via": ["signal_jammer", "destroy_comms_relay_node", "cut_cable_spool"],
		"relay_voice_suppressed_when": "all_nodes_on_floor_disabled_or_jammed"
	}

static func get_bioluminescence_rules() -> Dictionary:
	return {
		"source": "mature_bio_growth_in_rooms_with_no_active_lights",
		"light_level": "faint_blue_green_enough_to_navigate_without_flashlight",
		"corruption_effect": "at_corruption_above_fifty_bioluminescence_pulses_and_appears_to_move",
		"archetype_interaction": {
			"echo": "attracted_not_repelled_uses_glow_as_patrol_anchor",
			"shellroot": "anchors_growth_nodes_near_glow_patches"
		},
		"player_action": "bio_growth_can_be_harvested_with_decon_wipes_as_temp_light_source",
		"fire_interaction": "fire_tag_clears_growth_and_extinguishes_bioluminescence_permanently_in_tile"
	}

# --- Infection states ---

static func get_infection_states() -> Array[Dictionary]:
	return [
		{
			"id": "surface_infection",
			"label": "Surface Infection",
			"onset_time": 45,
			"symptoms": ["minor_itch_sound_cue"],
			"progresses_to": "deep_infection",
			"treatment": ["antibiotic_syringe", "decon_wipes"]
		},
		{
			"id": "deep_infection",
			"label": "Deep Infection",
			"onset_time": 90,
			"symptoms": ["bleed_rate_increase", "movement_slow", "stamina_drain"],
			"progresses_to": "septic",
			"treatment": ["antibiotic_syringe"]
		},
		{
			"id": "septic",
			"label": "Septic",
			"onset_time": 120,
			"symptoms": ["vision_grain", "corruption_gain_per_second", "severe_stamina_drain"],
			"progresses_to": "lethal_if_untreated",
			"treatment": ["antibiotic_syringe_double_dose"]
		},
		{
			"id": "bio_contamination",
			"label": "Bio Contamination",
			"onset_time": 0,
			"symptoms": ["immediate_surface_infection", "spore_cloud_on_movement", "infects_nearby_player"],
			"progresses_to": "deep_infection",
			"treatment": ["antibiotic_syringe", "decon_shower_station"]
		},
	]

# --- Structural zone states ---

static func get_structural_zone_states() -> Array[Dictionary]:
	return [
		{
			"id": "stable",
			"label": "Stable",
			"traversal": "full",
			"collapse_risk": "none"
		},
		{
			"id": "stressed",
			"label": "Stressed",
			"traversal": "full",
			"collapse_risk": "explosive_or_heavy_impact",
			"visual_cue": "cracked_panels_dust_on_footstep"
		},
		{
			"id": "buckling",
			"label": "Buckling",
			"traversal": "full_with_noise",
			"collapse_risk": "any_gunshot_or_forced_entry",
			"visual_cue": "sagging_ceiling_active_debris_fall",
			"noise": "structural_groan_periodically"
		},
		{
			"id": "collapsed",
			"label": "Collapsed",
			"traversal": "crawl_only",
			"collapse_risk": "none",
			"visual_cue": "rubble_field_low_ceiling",
			"opens_route": "collapsed_ceiling_crawl",
			"blocks_route": "original_upright_passage"
		},
		{
			"id": "unstable_ceiling",
			"label": "Unstable Ceiling",
			"traversal": "full",
			"collapse_risk": "sustained_noise_above_threshold",
			"visual_cue": "ceiling_tiles_loose_dust_streams",
			"notes": "precursor to buckling; loud combat can skip directly to collapsed"
		},
	]

# --- Weapon inspection verbs ---

static func get_weapon_inspection_verbs() -> Array[Dictionary]:
	return [
		{
			"id": "check_barrel",
			"label": "Check Barrel",
			"time": "fast",
			"result": "reveal_fouling_level_and_jam_risk",
			"noise": "silent"
		},
		{
			"id": "field_strip",
			"label": "Field Strip",
			"time": "slow",
			"result": "clear_any_active_malfunction_and_reset_weapon_condition_partial",
			"noise": "quiet",
			"requires": "tool_parts"
		},
		{
			"id": "tap_feed",
			"label": "Tap and Feed",
			"time": "fast",
			"result": "clear_failure_to_feed_malfunction",
			"noise": "quiet"
		},
		{
			"id": "count_remaining",
			"label": "Count Remaining",
			"time": "fast",
			"result": "tactile_feel_of_magazine_weight_rough_round_count",
			"noise": "silent",
			"notes": "drum_magazine gives unreliable feel; corruption may distort display"
		},
		{
			"id": "clear_chamber",
			"label": "Clear Chamber",
			"time": "fast",
			"result": "eject_chambered_round_to_floor_safe_weapon_state",
			"noise": "quiet"
		},
	]

# --- Door charge rules ---

static func get_door_charge_rules() -> Dictionary:
	return {
		"item": "door_charge_patch",
		"apply_verb": "plant",
		"apply_time": "slow",
		"detonate_range_meters": 8,
		"detonate_verb": "detonate_remote",
		"barrier_results": {
			"lock_housing": "destroy",
			"pressure_door": "stop_pit",
			"thin_metal": "pass"
		},
		"noise": "hazard_blast",
		"structural_effect": "drop_zone_state_one_tier_if_stressed_or_buckling",
		"corpse_effect": "scatter_any_body_in_one_meter_radius"
	}

# --- Body language cues ---

static func get_body_language_cues() -> Array[Dictionary]:
	return [
		{
			"id": "labored_breathing",
			"label": "Labored Breathing",
			"condition": "stamina_below_25_percent",
			"cue": "audible_ragged_inhale_exhale",
			"detectable_by": ["bleeder", "stalker_husk", "echo"],
			"player_aware": true
		},
		{
			"id": "blood_drip_sound",
			"label": "Blood Drip",
			"condition": "bleed_rate_above_3_per_second",
			"cue": "intermittent_wet_impact_on_floor",
			"detectable_by": ["bleeder", "surgeon", "carrion_eater"],
			"leaves_footprint_substance": "blood",
			"player_aware": true
		},
		{
			"id": "armor_clink",
			"label": "Armor Clink",
			"condition": "plate_armor_equipped_and_moving_at_run_speed",
			"cue": "rhythmic_metal_tap",
			"detectable_by": ["echo", "stalker_husk", "choir"],
			"suppress_via": "wire_wrapped_stock_has_no_effect_only_suit_patch_dampens",
			"player_aware": false
		},
		{
			"id": "suppressed_cough",
			"label": "Suppressed Cough",
			"condition": "in_heavy_haze_smoke_without_mask",
			"cue": "stifled_cough_every_few_seconds",
			"detectable_by": ["stalker_husk", "crawler_husk", "howler"],
			"player_aware": true
		},
		{
			"id": "corruption_hum",
			"label": "Corruption Hum",
			"condition": "corruption_above_65",
			"cue": "faint_electronic_resonance_from_glasses_and_earpiece",
			"detectable_by": ["relay_voice", "echo", "choir"],
			"notes": "signal noise makes player detectable to signal-aware archetypes regardless of movement noise"
		},
	]

# =============================================================================
# FLUID DYNAMICS
# =============================================================================

static func get_water_pooling_rules() -> Dictionary:
	return {
		"origin_sources": ["burst_pipe", "decon_shower_activated", "coolant_that_warmed_above_freeze"],
		"spread_per_tick": "one_tile_downhill_or_lateral_if_level",
		"depth_tiers": ["film", "shallow", "deep"],
		"depth_effects": {
			"film": "slip_chance_low_short_circuits_electronics",
			"shallow": "slip_chance_medium_slows_movement_conducts_electric",
			"deep": "traversal_slowed_heavily_drowning_risk_if_prone"
		},
		"freeze_threshold": "transitions_to_ice_patch_when_low_temp_tag_present_for_four_seconds",
		"evaporation": "film_evaporates_in_high_temp_zone_within_thirty_seconds",
		"blocks": "water_does_not_pass_through_sealed_doors_or_pressure_bulkheads",
		"carries": "water_flow_moves_lightweight_props_and_blood_stains_with_it"
	}

static func get_coolant_spread_rules() -> Dictionary:
	return {
		"origin_sources": ["coolant_pipe_rupture", "coolant_canister_poured", "damaged_cooling_loop"],
		"flow_rate": "faster_than_water_lower_viscosity",
		"spread_tiles": "up_to_six_tiles_from_source_along_floor_gradient",
		"electric_combo_window": "coolant_pool_remains_electric_reactive_for_twelve_seconds",
		"freeze_behavior": "forms_ice_patch_faster_than_water_in_low_temp_zone",
		"temperature_drop": "lowers_local_tile_temperature_while_present",
		"bio_growth_interaction": "slows_bio_growth_expansion_on_coolant_soaked_tiles",
		"fire_interaction": "extinguishes_fire_on_contact_does_not_ignite",
		"evaporation": "evaporates_in_high_temp_zones_releasing_chemical_vapor_tag",
		"cleanup": "suit_patch_and_decon_wipes_prevent_boot_coating",
		"conducts_electric": true,
		"marks_boots": "coolant_footprint_substance"
	}

static func get_blood_pooling_rules() -> Dictionary:
	return {
		"volume_source": "accumulates_from_active_bleed_rate_above_one_per_second",
		"spread": "pools_in_place_spreads_one_tile_when_volume_threshold_exceeded",
		"depth_tiers": ["smear", "pool", "spreading_pool"],
		"visibility": "visible_dark_red_stain_on_all_floor_types",
		"archetype_attraction": {
			"bleeder": "follows_freshest_blood_pool_as_trail",
			"surgeon": "detects_pool_from_two_rooms_away",
			"carrion_eater": "attracted_to_any_pool_regardless_of_age"
		},
		"age_stages": ["fresh", "drying", "dried"],
		"age_effects": {
			"fresh": "slippery_carries_infection_if_bio_contaminated",
			"drying": "no_slip_still_visible_still_tracked",
			"dried": "permanent_visual_stain_no_mechanical_effect"
		},
		"bio_growth_interaction": "bio_growth_spreads_faster_through_blood_soaked_tiles",
		"freeze": "freezes_solid_in_low_temp_zone_becomes_non_slip_but_permanent"
	}

static func get_fluid_mixing_rules() -> Array[Dictionary]:
	return [
		{
			"fluid_a": "blood",
			"fluid_b": "bio_growth_spore",
			"result": "infected_pool",
			"effect": "any_contact_causes_immediate_surface_infection",
			"visual": "dark_green_red_swirl"
		},
		{
			"fluid_a": "oil",
			"fluid_b": "coolant",
			"result": "foul_mix",
			"effect": "non_conductive_non_flammable_extreme_slip_chance_hard_to_clean",
			"visual": "iridescent_grey_sheen"
		},
		{
			"fluid_a": "water",
			"fluid_b": "blood",
			"result": "diluted_blood",
			"effect": "slip_chance_low_trail_fades_faster_still_trackable",
			"visual": "pink_wash"
		},
		{
			"fluid_a": "coolant",
			"fluid_b": "oil",
			"result": "foul_mix",
			"effect": "same_as_oil_coolant_mix",
			"visual": "grey_iridescent"
		},
		{
			"fluid_a": "water",
			"fluid_b": "coolant",
			"result": "diluted_coolant",
			"effect": "electric_reactive_but_weaker_stun_two_seconds_instead_of_four",
			"visual": "blue_tinted_water"
		},
		{
			"fluid_a": "bio_growth_spore",
			"fluid_b": "water",
			"result": "spore_suspension",
			"effect": "spore_suspension_spreads_infection_zone_wider_than_dry_spore",
			"visual": "murky_green_water"
		},
	]

static func get_drainage_and_slope_rules() -> Dictionary:
	return {
		"floor_slope_tags": ["level", "slight_slope", "steep_slope", "drain_grate"],
		"slope_effects": {
			"level": "fluid_pools_in_place",
			"slight_slope": "fluid_drifts_slowly_toward_low_end",
			"steep_slope": "fluid_flows_rapidly_can_outpace_spread_limit",
			"drain_grate": "fluid_removed_from_tile_within_two_seconds"
		},
		"drain_grate_blocked_by": ["debris_pile", "corpse_on_tile", "bio_growth_mat"],
		"slope_direction_set_by": "room_geometry_tag_applied_at_map_load",
		"player_effect_on_slope": "running_upslope_costs_extra_stamina",
		"enemy_effect": "enemies_pathfind_around_steep_slope_fluid_zones"
	}

static func get_fluid_pressure_flow_rules() -> Dictionary:
	return {
		"pipe_pressure_tiers": ["low", "normal", "high", "critical"],
		"burst_behavior": {
			"low": "dribble_one_tile_radius",
			"normal": "spray_three_tile_radius",
			"high": "jet_six_tiles_in_direction_damages_anything_in_path",
			"critical": "catastrophic_rupture_ten_tile_radius_structural_stress_zone"
		},
		"pressure_visible_via": "pipe_vibration_sound_and_pressure_gauge_prop",
		"player_can_reduce_pressure": "turn_pressure_valve_to_closed",
		"high_pressure_jet_damage": "deep_wound_to_unprotected_flesh_on_direct_hit",
		"burst_direction": "follows_pipe_orientation_tag_not_random"
	}

static func get_fluid_freeze_rules() -> Dictionary:
	return {
		"freeze_candidates": ["water", "coolant", "diluted_coolant", "diluted_blood"],
		"condition": "low_temp_tag_present_continuously_for_four_seconds",
		"result": "ice_patch",
		"ice_patch_effects": {
			"slip_chance": "high_for_any_character_regardless_of_speed",
			"electric_insulation": "ice_patch_does_not_conduct_electricity",
			"fire_resistance": "fire_tag_melts_ice_to_water_does_not_ignite_it",
			"traversal_noise": "footsteps_on_ice_crack_louder_than_metal_grating"
		},
		"melt_condition": "high_temp_tag_or_fire_tag_present_melts_in_three_seconds",
		"melt_result": "returns_to_water_puddle_at_original_volume",
		"structural_effect": "ice_buildup_in_joint_can_jam_door_or_lever_mechanism"
	}

static func get_condensation_rules() -> Dictionary:
	return {
		"condition": "hot_surface_adjacent_to_cold_humid_air",
		"hot_surface_sources": ["heated_pipe", "fire_adjacent_wall", "active_reactor_panel"],
		"cold_air_condition": "low_temp_or_oxygen_thin_zone_present",
		"result": "moisture_film_on_surface",
		"moisture_film_effects": {
			"floor": "film_slip_chance_low",
			"electronics_panel": "short_circuit_risk_if_powered",
			"weapon": "contributes_to_coolant_fouling_state_after_sustained_exposure",
			"glass_surface": "obscures_vision_through_pane_until_wiped"
		},
		"accumulation": "film_becomes_water_pool_if_surface_stays_hot_and_cold_for_sixty_seconds",
		"decon_wipes_use": "wipe_condensation_from_electronics_to_prevent_short"
	}

static func get_fluid_contamination_chain_rules() -> Array[Dictionary]:
	return [
		{
			"input": "blood_pool_plus_bio_growth_spore",
			"output": "infected_pool",
			"spread_rate": "faster_than_either_alone",
			"player_effect": "contact_causes_immediate_surface_infection"
		},
		{
			"input": "oil_plus_electric_arc",
			"output": "burning_oil_slick",
			"spread_rate": "rapid",
			"player_effect": "deep_wound_on_contact_fire_tag_applied_to_player"
		},
		{
			"input": "coolant_plus_bio_growth",
			"output": "stunted_growth_patch",
			"spread_rate": "growth_expansion_halted_in_coolant_soaked_tiles",
			"player_effect": "coolant_footprint_transfer_still_applies"
		},
		{
			"input": "water_plus_radiation_source",
			"output": "irradiated_water",
			"spread_rate": "same_as_water",
			"player_effect": "contact_applies_low_tier_radiation_exposure"
		},
		{
			"input": "blood_plus_coolant",
			"output": "frozen_blood_coolant",
			"spread_rate": "stops_spreading_freezes_in_place",
			"player_effect": "no_slip_but_permanent_visual_and_bio_contamination_risk"
		},
	]

static func get_capillary_seep_rules() -> Dictionary:
	return {
		"seep_capable_surfaces": ["cracked_concrete_wall", "old_grout_line", "unsealed_door_gap", "porous_tile"],
		"fluids_that_seep": ["water", "coolant", "blood", "spore_suspension"],
		"seep_rate": "one_tile_per_twenty_seconds_through_crack",
		"seep_requires": "source_tile_at_shallow_or_deep_depth",
		"door_gap_seep": "fluid_film_appears_under_door_warns_player_of_fluid_on_other_side",
		"wall_seep_visual": "dark_wet_streak_on_wall_surface_dripping_sound",
		"blocked_by": ["stasis_foam_canister_applied_to_crack", "sealed_door_state"],
		"utility": "player_can_detect_fluid_type_by_color_of_seep_before_opening_door"
	}

static func get_hydrostatic_pressure_rules() -> Dictionary:
	return {
		"principle": "deeper_fluid_column_exerts_more_force_on_containing_surface",
		"depth_tiers_to_force": {
			"film": "negligible",
			"shallow": "enough_to_soak_under_door_gap",
			"deep": "enough_to_burst_cracked_panel_or_weaker_seal"
		},
		"sealed_container_effect": "sealed_tank_with_deep_fluid_at_critical_pressure_can_rupture_if_struck",
		"player_use": "filling_a_sealed_room_with_coolant_can_burst_its_weak_panel_into_adjacent_room",
		"structural_interaction": "deep_fluid_on_stressed_floor_panel_accelerates_collapse_to_buckling"
	}

static func get_fluid_on_electronics_rules() -> Dictionary:
	return {
		"conductive_fluids": ["water", "coolant", "diluted_coolant", "irradiated_water"],
		"non_conductive_fluids": ["oil", "foul_mix", "blood_dried"],
		"panel_states": ["powered_dry", "powered_wet", "unpowered_wet", "shorted"],
		"powered_plus_conductive_fluid": "immediate_arc_flash_stuns_in_radius_starts_short_circuit",
		"short_circuit_propagation": "follows_connected_circuit_see_get_short_circuit_propagation_rules",
		"unpowered_wet": "panel_will_short_if_power_restored_before_fluid_clears",
		"player_use": "deliberately_pour_water_on_powered_panel_to_trigger_arc_flash_zone_denial",
		"recovery": "panel_dries_in_high_temp_zone_or_via_decon_wipes_then_functions_again"
	}

static func get_fluid_on_fire_rules() -> Dictionary:
	return {
		"water_on_fire": "extinguishes_one_tile_per_shallow_depth_leaves_steam_tag",
		"coolant_on_fire": "extinguishes_faster_than_water_leaves_coolant_pool_for_electric_combo",
		"oil_on_fire": "intensifies_fire_spread_rate_doubled_duration_extended",
		"blood_on_fire": "blood_dries_rapidly_does_not_fuel_fire_leaves_char_stain",
		"stasis_foam_on_fire": "smothers_fire_removes_oxygen_from_tile_temporarily",
		"bio_growth_on_fire": "growth_burns_rapidly_releases_spore_cloud_then_cleared",
		"steam_from_water": "water_on_fire_generates_steam_tag_that_persists_six_seconds",
		"foul_mix_on_fire": "foul_mix_does_not_ignite_but_smothers_fire_like_foam"
	}

static func get_fluid_viscosity_rules() -> Dictionary:
	return {
		"viscosity_tiers": {
			"water": "low",
			"blood_fresh": "low_medium",
			"coolant": "low",
			"oil": "high",
			"foul_mix": "very_high",
			"bio_growth_fluid": "medium",
			"blood_cold": "medium_high"
		},
		"high_viscosity_effects": "spreads_slower_harder_to_clean_slip_lasts_longer",
		"low_temp_on_viscosity": "all_fluids_increase_one_viscosity_tier_in_low_temp_zone",
		"high_temp_on_viscosity": "oil_thins_slightly_spreads_faster_in_high_temp",
		"player_movement": "wading_through_high_viscosity_fluid_costs_extra_stamina",
		"enemy_effect": "crawler_husk_and_bleeder_partially_immune_to_high_viscosity_slow"
	}

static func get_slick_zone_persistence_rules() -> Dictionary:
	return {
		"persistence_by_fluid": {
			"water": "evaporates_in_ninety_seconds_in_normal_temp_faster_in_high_temp",
			"coolant": "persists_three_minutes_unless_heated_or_drained",
			"blood_fresh": "dries_to_stain_in_two_minutes_stain_permanent",
			"blood_dried": "permanent_visual_no_mechanical_effect",
			"oil": "persists_indefinitely_until_ignited_or_cleaned",
			"foul_mix": "persists_indefinitely_harder_to_remove_than_oil",
			"ice_patch": "persists_until_melted_by_heat_tag"
		},
		"cleaning_methods": {
			"water": "decon_wipes_absorb_film_only",
			"coolant": "decon_wipes_and_tool_parts_for_deep_clean",
			"oil": "fire_burns_it_off_or_stasis_foam_absorbs",
			"blood_fresh": "decon_wipes_before_dry_stage",
			"foul_mix": "requires_both_stasis_foam_and_decon_wipes"
		},
		"successor_persistence": "all_permanent_stains_and_dried_fluids_survive_across_runs"
	}

# =============================================================================
# GAS DISPERSAL
# =============================================================================

static func get_gas_density_and_gravity_rules() -> Dictionary:
	return {
		"heavy_gases": ["co2", "coolant_vapor", "toxic_industrial", "propellant"],
		"light_gases": ["bio_spore_gas", "oxygen", "hydrogen_trace"],
		"neutral_gases": ["air", "diluted_gas"],
		"heavy_gas_behavior": "sinks_to_floor_level_first_concentrates_in_low_points_and_drains",
		"light_gas_behavior": "rises_to_ceiling_concentrates_in_vents_and_high_corners",
		"gravity_anomaly_exception": "in_gravity_pocket_zones_all_gases_disperse_uniformly",
		"detection": {
			"heavy_floor_gas": "visible_at_ankle_level_if_thick_enough",
			"ceiling_gas": "detected_by_oxygen_sniffer_before_visible"
		},
		"player_exposure_height": "crouching_in_heavy_floor_gas_exposes_face_to_higher_concentration"
	}

static func get_gas_pocket_formation_rules() -> Dictionary:
	return {
		"formation_conditions": ["sealed_room_with_gas_source", "low_point_with_heavy_gas_and_no_ventilation", "blocked_vent_stack"],
		"concentration_tiers": ["trace", "building", "pocket", "saturated"],
		"pocket_visible": "faint_shimmer_or_distortion_in_air_visible_at_medium_concentration",
		"ignition_at_tier": "pocket_or_higher_ignites_on_spark_or_flame",
		"deflagration_vs_detonation": "pocket_causes_deflagration_saturated_causes_full_detonation",
		"player_detection": "oxygen_sniffer_and_whisker_probe_detect_before_visible",
		"dispersion": "opening_door_into_pocket_causes_rapid_gas_rush_toward_low_pressure_area",
		"bleed_through_vents": "pocket_in_adjacent_room_seeps_slowly_through_vent_grates"
	}

static func get_gas_mixing_rules() -> Array[Dictionary]:
	return [
		{
			"gas_a": "propellant",
			"gas_b": "oxygen",
			"result": "enriched_combustible_mix",
			"ignition_result": "deflagration_blast_larger_than_propellant_alone"
		},
		{
			"gas_a": "coolant_vapor",
			"gas_b": "bio_spore_gas",
			"result": "stunted_spore_mix",
			"effect": "spores_suspended_but_less_infectious_coolant_vapour_inhibits_growth"
		},
		{
			"gas_a": "toxic_industrial",
			"gas_b": "oxygen",
			"result": "diluted_toxic",
			"effect": "toxicity_drops_one_tier_per_doubling_of_oxygen_ratio"
		},
		{
			"gas_a": "steam",
			"gas_b": "coolant_vapor",
			"result": "condensation_cloud",
			"effect": "rapid_liquid_droplet_formation_creates_water_film_on_all_surfaces_in_tile"
		},
		{
			"gas_a": "bio_spore_gas",
			"gas_b": "smoke",
			"result": "masked_spore_cloud",
			"effect": "spore_gas_invisible_within_smoke_archetype_scent_trackers_lose_trail"
		},
	]

static func get_gas_ignition_threshold_rules() -> Dictionary:
	return {
		"deflagration_threshold": "gas_at_pocket_concentration_plus_any_ignition_source",
		"detonation_threshold": "gas_at_saturated_concentration_with_confined_space",
		"ignition_sources": ["open_flame", "spark_from_electric_arc", "muzzle_flash", "static_discharge", "tracer_round"],
		"suppressor_effect": "suppressed_weapon_reduces_muzzle_flash_ignition_risk",
		"deflagration_result": "rapid_burn_wave_one_second_duration_knocks_enemies_applies_fire_tag",
		"detonation_result": "shockwave_and_fire_ball_structural_damage_lethal_in_epicenter",
		"chain_ignition": "deflagration_can_ignite_adjacent_gas_pocket_if_present",
		"player_warning_cue": "oxygen_sniffer_alarm_at_building_concentration"
	}

static func get_gas_toxicity_tiers() -> Array[Dictionary]:
	return [
		{
			"tier": "trace",
			"ppm_equivalent": "barely_detectable",
			"effect": "oxygen_sniffer_chirps_no_player_effect",
			"onset_seconds": 0
		},
		{
			"tier": "irritant",
			"ppm_equivalent": "low_ambient",
			"effect": "cough_noise_eyes_water_vision_edge_blur",
			"onset_seconds": 10
		},
		{
			"tier": "disabling",
			"ppm_equivalent": "moderate_pocket",
			"effect": "severe_cough_stamina_drain_vision_narrowing_movement_slow",
			"onset_seconds": 20
		},
		{
			"tier": "lethal",
			"ppm_equivalent": "saturated",
			"effect": "rapid_organ_shutdown_lethal_without_extraction_in_thirty_seconds",
			"onset_seconds": 5
		},
	]

static func get_gas_dispersal_rules() -> Dictionary:
	return {
		"spread_rate_by_ventilation": {
			"vents_active": "rapid_one_tile_per_three_seconds",
			"vents_inactive": "slow_one_tile_per_fifteen_seconds_by_diffusion",
			"pressure_breach_present": "very_rapid_all_gas_pulled_toward_breach_within_six_seconds"
		},
		"door_gap_transmission": "gas_seeps_under_door_at_one_third_concentration_per_room",
		"sealed_door_blocks": "sealed_door_state_prevents_gas_transmission_entirely",
		"forced_door_gap": "door_in_forced_state_allows_full_concentration_transmission",
		"concentration_loss_per_room": "gas_halves_in_concentration_per_additional_room_without_source",
		"signal_jammer_effect": "none_gas_is_not_electronic"
	}

static func get_oxygen_depletion_rules() -> Dictionary:
	return {
		"fire_o2_consumption": "active_fire_reduces_o2_in_sealed_room_by_one_percent_per_second",
		"o2_thresholds": {
			"normal": "twenty_one_percent",
			"thin": "seventeen_percent_stamina_recovery_slowed",
			"hypoxic": "fourteen_percent_vision_darkens_judgment_impaired",
			"dangerous": "ten_percent_unconsciousness_risk_per_thirty_seconds",
			"lethal": "six_percent_loss_of_consciousness_then_death"
		},
		"fire_smothers_at": "fire_self_extinguishes_when_o2_drops_below_ten_percent",
		"co2_buildup": "fire_and_breathing_raise_co2_compounding_hypoxia_effect",
		"ventilation_restores": "active_vents_restore_o2_at_two_percent_per_minute",
		"pressure_breach_effect": "breach_rapidly_equalizes_o2_but_pulls_atmosphere_out"
	}

static func get_propellant_gas_rules() -> Dictionary:
	return {
		"source": "every_weapon_discharge_emits_propellant_gas",
		"volume_by_weapon": {
			"pistol": "minimal_dissipates_in_two_seconds",
			"rifle": "moderate_dissipates_in_four_seconds",
			"shotgun": "significant_dissipates_in_five_seconds",
			"suppressed": "most_retained_inside_suppressor_dissipates_in_one_second"
		},
		"concentration_buildup": "sustained_fire_in_sealed_room_can_reach_irritant_tier",
		"ignition_risk": "propellant_gas_at_building_tier_ignites_on_next_muzzle_flash_if_no_suppressor",
		"suppressor_benefit": "suppressor_traps_and_slows_propellant_dispersal_reduces_ignition_risk",
		"ventilation_clears": "active_vents_clear_propellant_gas_in_one_firing_cycle"
	}

static func get_gas_absorption_rules() -> Dictionary:
	return {
		"absorbing_materials": ["bio_growth_mat", "textile_surface", "porous_concrete", "loose_fill_insulation"],
		"absorption_rate": "absorbing_material_reduces_local_concentration_by_up_to_half",
		"saturation_point": "material_saturates_and_begins_re_releasing_when_source_removed",
		"release_rate": "slower_than_absorption_can_maintain_irritant_tier_after_source_gone",
		"fire_on_absorbing_material": "burning_textile_releases_stored_gas_and_ignites_it",
		"player_use": "pulling_bio_growth_from_walls_releases_stored_spore_gas"
	}

static func get_bio_gas_rules() -> Dictionary:
	return {
		"source": "mature_bio_growth_emits_spore_gas_continuously",
		"emission_rate_by_maturity": {
			"seedling": "none",
			"established": "trace_tier",
			"mature": "irritant_tier",
			"dominant": "disabling_tier_in_sealed_room"
		},
		"spore_gas_composition": "biological_not_chemical_resists_standard_gas_filters",
		"exposure_effect": "cumulative_spore_count_triggers_infection_stages",
		"archetype_interaction": {
			"shellroot": "produces_highest_spore_volume_of_any_growth_host",
			"carrion_eater": "immune_to_spore_gas"
		},
		"fire_clears": "fire_burns_spores_from_air_simultaneously_with_growth",
		"antibiotic_syringe": "reduces_cumulative_spore_exposure_counter"
	}

static func get_gas_masking_rules() -> Dictionary:
	return {
		"masking_agents": ["smoke", "steam", "coolant_vapor"],
		"masking_effect_on_trackers": "bleeder_and_surgeon_lose_scent_trail_in_masked_gas_zone",
		"player_benefit": "decon_wipes_plus_smoke_mask_scent_completely",
		"echo_exception": "echo_does_not_use_scent_unaffected_by_masking",
		"gas_detector_affected": "oxygen_sniffer_shows_degraded_reading_in_smoke_mixed_zone",
		"mask_duration": "masking_persists_as_long_as_masking_agent_present_in_tile"
	}

static func get_gas_current_rules() -> Dictionary:
	return {
		"current_sources": ["active_ventilation_duct", "pressure_breach_pull", "airlock_cycling", "spinning_fan_blade"],
		"current_effect_on_gas": "pulls_gas_along_current_direction_at_twice_normal_spread_rate",
		"current_effect_on_smoke": "smoke_follows_current_same_rate",
		"current_effect_on_spore_gas": "spore_gas_pulled_into_vents_can_seed_adjacent_rooms",
		"player_use": "activate_ventilation_to_clear_gas_from_room_or_push_gas_into_enemy_area",
		"enemy_use": "relay_voice_can_activate_vents_to_push_gas_toward_player",
		"blocking": "stasis_foam_in_vent_opening_blocks_current"
	}

# =============================================================================
# THERMAL SYSTEM
# =============================================================================

static func get_heat_transfer_rules() -> Dictionary:
	return {
		"conduction_rate_by_material": {
			"metal": "rapid_one_tile_per_four_seconds",
			"concrete": "slow_one_tile_per_twenty_seconds",
			"plastic": "medium_one_tile_per_ten_seconds",
			"ceramic": "very_slow_one_tile_per_forty_seconds",
			"vacuum_gap": "none_thermal_isolation"
		},
		"source_types": ["active_fire", "high_temp_zone", "steam_pipe", "reactor_panel"],
		"heated_tile_effect": "adjacent_character_takes_radiant_heat_damage_if_not_insulated",
		"cooling_conduction": "coolant_pool_pulls_heat_from_adjacent_tile_same_rate_as_heating",
		"player_insulation": "cryo_patch_and_thermal_overlayer_add_one_conduction_step_delay",
		"structural_effect": "metal_floor_heated_to_high_drops_structural_zone_one_tier_over_time"
	}

static func get_thermal_shock_rules() -> Dictionary:
	return {
		"definition": "rapid_swing_from_high_temp_to_low_or_vice_versa_within_five_seconds",
		"triggers": {
			"hot_to_cold": "step_from_fire_zone_into_coolant_pool",
			"cold_to_hot": "cryo_patch_wearing_off_while_in_high_temp_zone"
		},
		"material_effects": {
			"glass": "shatters_into_full_shatter_pattern",
			"pressurized_metal": "stress_crack_increases_burst_risk",
			"biological_tissue": "stuns_target_for_two_seconds_deep_wound_if_sustained"
		},
		"player_effect": "stress_shake_triggered_vision_blur_for_three_seconds",
		"archetype_effects": {
			"carapace": "carapace_plate_cracks_on_thermal_shock_reduces_to_stop_chip_result",
			"bleeder": "no_armor_high_vulnerability_to_biological_stun"
		}
	}

static func get_ignition_threshold_by_material() -> Array[Dictionary]:
	return [
		{"material": "paper_textile_packaging", "threshold": "any_flame_or_spark", "burn_rate": "fast", "smoke_output": "high"},
		{"material": "dry_bio_growth", "threshold": "any_flame_or_spark", "burn_rate": "very_fast", "smoke_output": "very_high"},
		{"material": "wood_composite_panel", "threshold": "sustained_flame_three_seconds", "burn_rate": "medium", "smoke_output": "high"},
		{"material": "plastic_polymer", "threshold": "sustained_flame_five_seconds", "burn_rate": "medium", "smoke_output": "very_high"},
		{"material": "rubber_seal", "threshold": "sustained_flame_eight_seconds", "burn_rate": "slow", "smoke_output": "extreme"},
		{"material": "thin_metal_sheet", "threshold": "never_ignites_conducts_heat_only", "burn_rate": "none", "smoke_output": "none"},
		{"material": "oil_pool", "threshold": "any_flame_or_spark", "burn_rate": "rapid", "smoke_output": "high"},
		{"material": "reinforced_composite_panel", "threshold": "never_ignites", "burn_rate": "none", "smoke_output": "none"},
	]

static func get_cooling_rate_rules() -> Dictionary:
	return {
		"passive_cooling": "heated_tile_drops_one_temp_tier_per_thirty_seconds_without_fuel",
		"accelerated_cooling": {
			"coolant_pool_on_tile": "drops_to_low_temp_in_four_seconds",
			"water_pool_on_tile": "drops_to_normal_in_ten_seconds",
			"cryo_patch_applied": "drops_two_tiers_in_two_seconds_single_use",
			"pressure_breach": "rapid_cooling_as_atmosphere_vents"
		},
		"fire_self_sustaining": "fire_stays_at_high_temp_while_fuel_present_and_o2_above_ten_percent",
		"residual_heat": "tile_cools_from_fire_but_retains_warm_tier_for_twenty_seconds_after_fire_out",
		"archetype_heat_persistence": "shellroot_and_carrion_eater_retain_body_heat_longer_than_other_archetypes"
	}

static func get_insulation_rules() -> Dictionary:
	return {
		"insulating_items": ["cryo_patch", "thermal_overlayer", "suit_patch"],
		"insulating_materials": ["ceramic_wall_panel", "rubber_seal", "vacuum_gap"],
		"effect": "reduces_heat_or_cold_transfer_rate_by_one_tier",
		"stacking": "two_insulating_layers_reduce_by_two_tiers_cannot_reduce_below_zero",
		"breach_of_insulation": "bullet_hole_in_ceramic_panel_creates_thermal_bridge_at_that_point",
		"cryo_patch_duration": "single_use_thirty_seconds_then_insulation_lost",
		"suit_patch_thermal_note": "suit_patch_also_provides_minor_cold_insulation_primary_use_is_o2_seal"
	}

static func get_radiant_heat_rules() -> Dictionary:
	return {
		"radiant_sources": ["large_fire_three_plus_tiles", "active_reactor_panel", "heated_metal_wall"],
		"radiant_radius": "two_tiles_for_large_fire_one_tile_for_panel",
		"exposure_effect": {
			"one_tile": "discomfort_stamina_drain_minor",
			"adjacent": "burn_risk_deep_wound_without_insulation"
		},
		"blocked_by": ["solid_wall", "reinforced_floor_panel", "sealed_door"],
		"archetype_effects": {
			"shellroot": "generates_own_radiant_heat_repels_non_heat_immune_archetypes",
			"echo": "no_thermal_mass_not_affected_by_radiant_heat"
		},
		"fire_growth_effect": "radiant_heat_from_large_fire_can_pre_heat_adjacent_tile_to_ignition"
	}

static func get_cryo_shock_rules() -> Dictionary:
	return {
		"trigger": "exposure_to_coolant_jet_or_sudden_low_temp_zone_entry_while_body_temp_normal",
		"biological_effects": {
			"player": "stun_one_second_pain_response_movement_slowed_for_five_seconds",
			"bleeder": "flash_freeze_surface_causes_incap_on_affected_limb",
			"carapace": "plate_becomes_brittle_next_hit_upgrades_one_penetration_tier"
		},
		"material_effects": {
			"water_pipe": "sudden_pressure_drop_can_crack_pipe_fitting",
			"pressurized_tank": "rapid_contraction_stress_crack_risk"
		},
		"mitigations": "cryo_patch_already_active_negates_cryo_shock_immune_from_cold",
		"warm_recovery": "entering_warmth_radius_of_campfire_reverses_slow_in_ten_seconds"
	}

static func get_heat_signature_rules() -> Dictionary:
	return {
		"signature_sources": ["living_biological", "active_fire", "hot_pipe", "reactor_panel", "campfire"],
		"signature_intensity_tiers": ["faint", "clear", "strong", "intense"],
		"archetype_detectors": {
			"surgeon": "detects_living_signatures_up_to_four_tiles",
			"stalker_husk": "detects_residual_body_heat_from_recently_vacated_cover",
			"echo": "no_thermal_detection_uses_acoustic_only"
		},
		"player_heat_suppression": "cryo_patch_reduces_player_signature_by_two_tiers_for_thirty_seconds",
		"fire_masks_player": "large_fire_strong_signature_overwhelms_player_faint_signature_at_range",
		"dead_archetype_signature": "corpse_retains_faint_signature_for_ninety_seconds_post_death"
	}

static func get_heated_surface_rules() -> Dictionary:
	return {
		"surfaces_that_heat": ["metal_floor_near_fire", "steam_pipe_wall", "reactor_panel_floor"],
		"heat_tier_effects_on_contact": {
			"warm": "discomfort_only_minor_stamina_drain",
			"hot": "burn_graze_per_second_of_contact_for_unprotected_skin",
			"scorching": "burn_deep_wound_per_second_forces_movement_off_surface"
		},
		"prone_player": "prone_on_hot_metal_floor_applies_effect_continuously",
		"footwear_protection": "boot_grips_provide_partial_insulation_from_floor_heat",
		"door_handle_hot": "forcing_open_door_adjacent_to_fire_deals_graze_to_hands",
		"visual_cue": "surface_glows_faint_orange_at_hot_tier_distortion_shimmer_at_scorching"
	}

static func get_fire_behavior_in_vacuum_rules() -> Dictionary:
	return {
		"low_o2_fire_shape": "flame_becomes_spherical_not_directional_in_oxygen_thin_zone",
		"extinction_threshold": "fire_self_extinguishes_below_ten_percent_o2",
		"spread_rate_in_low_o2": "drastically_reduced_halved_below_fifteen_percent",
		"pressure_breach_fire": "fire_pulled_toward_breach_then_dies_as_o2_vents_outboard",
		"vacuum_pocket_fire": "cannot_sustain_any_flame_in_true_vacuum_zone",
		"smoldering": "fire_below_extinction_threshold_smolders_emitting_smoke_no_flame",
		"smolder_reignition": "smoldering_tile_reignites_if_o2_restored_before_cooling"
	}

# =============================================================================
# ELECTRICAL SYSTEM
# =============================================================================

static func get_circuit_overload_rules() -> Dictionary:
	return {
		"overload_trigger": "combined_draw_exceeds_circuit_capacity",
		"draw_sources": ["active_powered_door", "active_elevator", "glasses_power_load", "portable_generator_running"],
		"overload_sequence": ["flicker", "breaker_trip", "sustained_overload_heat_buildup", "fire_at_panel"],
		"breaker_trip_effect": "cuts_power_to_circuit_restores_manually_at_breaker_panel",
		"sustained_overload": "if_breaker_bypassed_or_absent_heat_builds_to_fire_within_sixty_seconds",
		"player_trigger": "adding_power_cell_to_overloaded_circuit_skips_to_fire_step",
		"archetype_use": "echo_can_induce_overload_to_cut_lights_in_room"
	}

static func get_grounding_rules() -> Dictionary:
	return {
		"grounded_surfaces": ["bare_metal_floor", "wet_floor_any_fluid", "metal_wall_panels"],
		"insulating_surfaces": ["rubber_mat", "plastic_floor_tile", "dry_ceramic_tile"],
		"player_footwear": {
			"boot_grips": "partial_insulation_reduces_electric_stun_duration_by_half",
			"bare_no_boots": "full_conductivity_maximum_stun_duration",
			"suit_patch_boots": "same_as_boot_grips"
		},
		"arc_path": "electric_arc_follows_path_of_least_resistance_to_nearest_ground",
		"grounded_enemy": "enemy_standing_on_wet_metal_floor_takes_full_arc_stun",
		"player_exploitation": "lure_enemy_onto_wet_metal_floor_before_triggering_arc_junction"
	}

static func get_arc_flash_rules() -> Dictionary:
	return {
		"trigger_conditions": ["conductive_fluid_on_powered_panel", "short_circuit_event", "overloaded_arc_junction"],
		"flash_radius": "two_tiles",
		"flash_effects": {
			"player_in_radius": "deep_wound_and_three_second_stun_and_glasses_flicker",
			"enemy_in_radius": "full_stun_duration_four_seconds_applies_electric_tag"
		},
		"fire_risk": "arc_flash_in_gas_pocket_triggers_deflagration",
		"electronics_affected": "all_electronics_in_radius_glitch_for_ten_seconds",
		"insulation_protection": "rubber_mat_under_feet_reduces_to_graze_and_one_second_stun",
		"visual": "bright_blue_white_flash_leaves_scorch_mark_on_nearest_surface"
	}

static func get_emp_effects_rules() -> Dictionary:
	return {
		"emp_sources": ["static_charge_item_overloaded", "arc_flash_large", "specific_archetype_ability"],
		"effect_tiers": ["minor_glitch", "malfunction", "fried", "destroyed"],
		"affected_by_tier": {
			"minor_glitch": "glasses_display_static_for_five_seconds",
			"malfunction": "glasses_off_earpiece_dead_keypad_unresponsive_for_thirty_seconds",
			"fried": "glasses_modules_require_tool_parts_to_repair_before_use",
			"destroyed": "device_permanently_non_functional_for_run"
		},
		"emp_radius": "three_tiles_for_large_arc_one_tile_for_static_discharge",
		"shielded_items": ["mechanical_items_with_no_electronics", "bone_conduction_mic", "tourniquet"],
		"archetype_effects": {
			"echo": "echo_is_itself_electromagnetic_minor_emp_causes_brief_confusion",
			"relay_voice": "emp_silences_relay_voice_broadcast_for_thirty_seconds"
		}
	}

static func get_static_charge_buildup_rules() -> Dictionary:
	return {
		"buildup_conditions": ["dry_insulated_surface_traversal", "rubbing_suit_against_plastic_panel", "low_humidity_zone"],
		"buildup_rate": "one_tier_per_thirty_seconds_in_buildup_condition",
		"discharge_tiers": ["harmless_spark", "painful_shock", "arc_discharge"],
		"discharge_triggers": {
			"harmless_spark": "touching_grounded_metal_at_low_charge",
			"painful_shock": "touching_grounded_metal_at_medium_charge_graze_wound",
			"arc_discharge": "touching_grounded_metal_at_high_charge_arc_flash_radius_one"
		},
		"item_use": "static_charge_item_can_be_deliberately_discharged_as_weapon",
		"humidity_effect": "high_humidity_zones_prevent_buildup_and_slowly_discharge_existing_charge",
		"enemy_detection": "choir_and_echo_detect_high_static_charge_as_distinct_signal"
	}

static func get_short_circuit_propagation_rules() -> Dictionary:
	return {
		"trigger": "conductive_fluid_on_powered_panel_or_arc_flash_event",
		"propagation": "short_travels_along_shared_circuit_to_all_connected_panels_on_floor",
		"propagation_speed": "one_panel_per_second",
		"effect_at_each_panel": "arc_flash_radius_one_at_that_panel_lights_flicker_then_die",
		"breaker_stops_propagation": "circuit_breaker_panel_absorbs_short_and_trips_preventing_further_spread",
		"no_breaker_result": "short_reaches_generator_and_overloads_it_potential_fire",
		"player_exploit": "short_circuit_remotely_by_pouring_fluid_on_one_panel_to_kill_all_lights_on_floor"
	}

static func get_power_grid_cascade_rules() -> Dictionary:
	return {
		"cascade_stages": ["single_circuit_failure", "floor_blackout", "generator_strain", "generator_fire"],
		"stage_triggers": {
			"single_circuit": "one_short_circuit_or_breaker_trip",
			"floor_blackout": "three_circuits_fail_simultaneously",
			"generator_strain": "floor_blackout_while_generator_running_at_capacity",
			"generator_fire": "generator_strain_sustained_ninety_seconds"
		},
		"restoration": "each_stage_reversed_by_resetting_breakers_and_addressing_fault",
		"archetype_effects": {
			"echo": "thrives_in_blackout_patrol_speed_increases",
			"glasswalker": "loses_wall_phase_advantage_in_full_blackout"
		},
		"player_exploitation": "intentional_floor_blackout_as_tactical_choice"
	}

static func get_electronic_device_failure_tiers() -> Array[Dictionary]:
	return [
		{
			"tier": "glitch",
			"cause": ["brief_arc_flash", "minor_emp", "glasses_power_overdraw"],
			"effect": "device_static_or_incorrect_display_for_five_to_ten_seconds",
			"recovery": "automatic"
		},
		{
			"tier": "malfunction",
			"cause": ["sustained_fluid_exposure", "circuit_overload", "moderate_emp"],
			"effect": "device_offline_until_manually_reset",
			"recovery": "interact_to_reset"
		},
		{
			"tier": "fried",
			"cause": ["direct_arc_flash_hit", "large_emp", "full_short_circuit"],
			"effect": "device_offline_requires_tool_parts_repair",
			"recovery": "tool_parts_consumed"
		},
		{
			"tier": "destroyed",
			"cause": ["generator_explosion", "direct_explosive_damage", "sustained_fried_without_repair"],
			"effect": "device_permanently_non_functional_for_run",
			"recovery": "none"
		},
	]

static func get_battery_behavior_in_temp_rules() -> Dictionary:
	return {
		"cold_effects": {
			"cool": "capacity_reduced_twenty_percent",
			"low_temp": "capacity_reduced_fifty_percent_glasses_power_drain_accelerated",
			"extreme_cold": "battery_may_refuse_to_discharge_device_dead_until_warmed"
		},
		"heat_effects": {
			"warm": "no_effect",
			"high_temp": "battery_swells_capacity_normal_but_vent_gas_toxic_irritant_tier",
			"scorching": "thermal_runaway_battery_ruptures_fire_tag_radius_one_tile"
		},
		"power_cell_in_cold": "power_cell_item_gives_less_charge_at_low_temp_tier",
		"recovery": "battery_warmed_to_normal_temp_restores_capacity_within_sixty_seconds"
	}

static func get_electromagnetic_interference_rules() -> Dictionary:
	return {
		"emi_sources": ["arc_junction_active", "echo_archetype_proximity", "signal_jammer_active", "reactor_panel_damaged"],
		"emi_tiers": ["background", "noticeable", "disruptive", "overwhelming"],
		"effect_by_tier": {
			"background": "none",
			"noticeable": "glasses_display_occasional_static_line",
			"disruptive": "glasses_modules_read_errors_earpiece_static_keypad_unresponsive",
			"overwhelming": "all_electronics_malfunction_tier"
		},
		"echo_archetype_emi": "echo_projects_noticeable_emi_in_two_tile_radius_at_all_times",
		"signal_jammer_emi": "disruptive_tier_in_radius_including_to_player",
		"physical_shielding": "faraday_cage_room_tag_blocks_external_emi_but_also_blocks_comms"
	}

# =============================================================================
# STRUCTURAL AND DEBRIS
# =============================================================================

static func get_shrapnel_rules() -> Dictionary:
	return {
		"sources": ["explosive_device", "door_charge_patch", "pressurized_tank_rupture", "deflagration_blast"],
		"cone_angle": "forty_five_degrees_from_blast_face",
		"shrapnel_material": "inherits_from_destroyed_object_metal_shrapnel_from_metal_door",
		"velocity_tiers": ["low", "medium", "high"],
		"penetration_by_velocity": {
			"low": "graze_wound_stopped_by_soft_armor",
			"medium": "deep_wound_stopped_by_plate_armor",
			"high": "incap_wound_cracks_carapace_plate"
		},
		"distance_falloff": "shrapnel_loses_one_velocity_tier_per_three_tiles",
		"ricochet": "shrapnel_can_ricochet_off_hard_surfaces_see_ricochet_rules",
		"structural_effect": "high_velocity_shrapnel_in_stressed_zone_drops_structural_state"
	}

static func get_ricochet_rules() -> Dictionary:
	return {
		"ricochet_capable_surfaces": ["metal_plate", "reinforced_concrete", "glass_intact", "blast_door"],
		"non_ricochet_surfaces": ["bio_growth_mat", "textile", "loose_debris", "plastic_panel"],
		"angle_effect": "shallow_angle_high_retention_steep_angle_bullet_embeds_or_shatters_surface",
		"energy_retention": {
			"thirty_degrees": "eighty_percent_energy_kept",
			"forty_five_degrees": "fifty_percent_energy_kept",
			"sixty_plus_degrees": "twenty_percent_energy_kept_or_less"
		},
		"ricochet_deviation": "random_spread_within_fifteen_degrees_of_ideal_angle",
		"frangible_exception": "frangible_rounds_never_ricochet_fragment_on_hard_surface",
		"player_risk": "ricochet_can_return_toward_shooter_at_reduced_penetration"
	}

static func get_concussive_wave_rules() -> Dictionary:
	return {
		"sources": ["door_charge_patch_detonation", "deflagration_blast", "detonation_blast", "cargo_crusher"],
		"propagation": "travels_through_open_corridors_reflects_off_walls",
		"force_by_distance": {
			"epicenter": "lethal_if_unprotected_full_structural_damage",
			"one_tile": "deep_wound_stun_two_seconds_knockback",
			"two_tiles": "graze_stun_one_second_items_knocked_over",
			"three_tiles": "stagger_no_wound_props_shift"
		},
		"door_propagation": "wave_passes_through_open_door_at_fifty_percent_force",
		"sealed_door_blocks": "sealed_door_stops_wave_entirely",
		"structural_effect": "concussive_wave_drops_buckling_zone_to_collapsed_instantly",
		"archetype_effects": {
			"shellroot": "immune_to_knockback_takes_structural_damage_instead",
			"choir": "choir_members_disrupted_formation_broken_for_ten_seconds"
		}
	}

static func get_weight_load_bearing_rules() -> Dictionary:
	return {
		"floor_load_tiers": ["light", "medium", "heavy", "overloaded"],
		"load_sources": {
			"light": "single_player_or_enemy",
			"medium": "player_plus_two_props",
			"heavy": "multiple_heavy_props_or_group_of_enemies",
			"overloaded": "above_heavy_in_stressed_or_buckling_zone"
		},
		"structural_interaction": {
			"stable": "all_loads_safe",
			"stressed": "heavy_load_drops_to_buckling",
			"buckling": "medium_load_triggers_noise_heavy_triggers_collapse"
		},
		"player_action": "stack_heavy_props_on_buckling_floor_to_trigger_collapse_from_above",
		"enemy_weight": "carapace_archetype_counts_as_heavy_load_due_to_plate_mass"
	}

static func get_falling_object_rules() -> Dictionary:
	return {
		"fall_sources": ["structural_collapse_debris", "shelf_knocked_over", "pipe_section_failure", "thrown_prop"],
		"impact_force_by_height": {
			"one_meter": "graze_to_unprotected_head",
			"three_meters": "deep_wound_to_head_incap_to_shoulder",
			"five_plus_meters": "lethal_if_hits_head_incap_if_hits_body"
		},
		"noise": "proportional_to_mass_and_height_heavy_object_at_height_is_hazard_blast_tier",
		"lures": "loud_impact_raises_noise_pressure_in_threat_director",
		"player_use": "drop_heavy_cargo_prop_from_elevated_platform_onto_enemy_below",
		"archetype_immunity": "shellroot_takes_graze_only_from_falling_objects_due_to_mass"
	}

static func get_blast_door_resistance_rules() -> Dictionary:
	return {
		"damage_states": ["intact", "dented", "cracked", "breached"],
		"damage_sources": {
			"door_charge_patch": "intact_to_dented_or_dented_to_cracked",
			"fifty_bmg_sustained": "dented_to_cracked_after_five_rounds",
			"deflagration_on_door": "cracked_to_breached",
			"detonation_on_door": "intact_to_breached"
		},
		"state_effects": {
			"dented": "door_still_functional_slight_seal_loss",
			"cracked": "seal_broken_gas_and_smoke_pass_through_door_forced_tag_applies",
			"breached": "door_non_functional_open_permanently_full_passage"
		},
		"repair": "cracked_can_be_sealed_with_stasis_foam_temporary_gas_block",
		"successor_persistence": "damage_state_persists_across_runs"
	}

static func get_wall_penetration_depth_rules() -> Dictionary:
	return {
		"wall_materials": ["drywall", "thin_metal", "concrete", "reinforced_composite", "blast_panel"],
		"penetration_by_caliber_family": {
			"light_ballistic": {
				"drywall": "pass",
				"thin_metal": "pass_deformed",
				"concrete": "stop_embedded",
				"reinforced_composite": "stop",
				"blast_panel": "stop"
			},
			"rifle_ballistic": {
				"drywall": "pass",
				"thin_metal": "pass",
				"concrete": "stop_crack",
				"reinforced_composite": "stop_embedded",
				"blast_panel": "stop"
			},
			"industrial_slug": {
				"drywall": "pass",
				"thin_metal": "pass",
				"concrete": "pass_deformed",
				"reinforced_composite": "stop_crack",
				"blast_panel": "stop"
			}
		},
		"pass_effect": "bullet_exits_wall_at_reduced_velocity_one_penetration_tier_lower",
		"stop_embedded": "bullet_remains_in_wall_no_exit_wound",
		"stop_crack": "wall_surface_damaged_weakens_structural_zone"
	}

static func get_glass_break_pattern_rules() -> Dictionary:
	return {
		"break_types": ["spider_crack", "partial_shatter", "full_shatter", "explosive_shatter"],
		"cause_to_pattern": {
			"single_pistol_round": "spider_crack_hole_with_radial_fractures",
			"rifle_round": "partial_shatter_hole_plus_fragments_around_impact",
			"shotgun_buck": "full_shatter_all_glass_falls",
			"explosive_concussive_wave": "explosive_shatter_glass_projected_as_shrapnel",
			"impact_thrown_object": "spider_crack_or_partial_depending_on_mass"
		},
		"fragment_effect": "shattered_glass_on_floor_creates_noisy_tile_and_graze_risk_if_crawled",
		"pressure_seal": "any_break_in_exterior_glass_panel_creates_pressure_breach_at_that_point",
		"frangible_exception": "frangible_round_creates_spider_crack_only_no_full_shatter"
	}

# =============================================================================
# BIOLOGICAL SYSTEMS
# =============================================================================

static func get_bio_growth_spread_rules() -> Dictionary:
	return {
		"spread_rate_normal": "one_tile_per_ninety_seconds",
		"accelerating_conditions": {
			"blood_soaked_tile": "spread_rate_halved",
			"high_humidity": "spread_rate_halved",
			"darkness": "spread_rate_reduced_by_twenty_five_percent",
			"water_pool_adjacent": "spreads_into_water_pool_tile_immediately"
		},
		"inhibiting_conditions": {
			"coolant_soaked_tile": "spread_stopped_at_that_tile",
			"fire_tag": "growth_burned_clears_tile",
			"bright_light": "spread_rate_doubled_time_growth_slows",
			"dry_heat": "growth_withers_spread_rate_tripled_time"
		},
		"maximum_density": "dominant_growth_tier_not_exceeded",
		"spread_direction": "expands_outward_from_seed_tile_in_all_directions_equally",
		"wall_growth": "can_spread_up_walls_and_across_ceilings_at_half_floor_rate"
	}

static func get_bio_growth_nutrient_rules() -> Dictionary:
	return {
		"preferred_substrates": ["blood_soaked_floor", "organic_debris", "porous_concrete", "textile"],
		"preferred_humidity": "high_moisture_or_fluid_adjacent",
		"growth_on_preferred": "double_maturation_speed",
		"starvation_condition": "no_moisture_and_no_organic_substrate_within_two_tiles",
		"starvation_effect": "growth_maturation_halts_then_slowly_dies_back_over_two_minutes",
		"player_exploitation": "clear_all_fluid_from_room_and_heat_to_kill_growth_without_fire",
		"shellroot_as_host": "shellroot_archetype_provides_continuous_nutrient_supply_prevents_starvation"
	}

static func get_npc_infection_spread_rules() -> Dictionary:
	return {
		"infected_archetypes": ["any_with_bio_contamination_status"],
		"transmission_method": "spore_cloud_emitted_on_movement_from_bio_contaminated_archetype",
		"transmission_radius": "one_tile_per_second_of_proximity",
		"exposure_threshold": "three_seconds_of_proximity_causes_surface_infection",
		"player_counter": "antibiotic_syringe_after_exposure_prevents_progression",
		"archetype_immunity": {
			"carrion_eater": "immune",
			"shellroot": "immune",
			"carapace": "immune_due_to_sealed_plate"
		},
		"archetype_vulnerability": {
			"bleeder": "progresses_two_stages_faster_than_player",
			"choir": "infection_disrupts_coordination_breaks_formation"
		}
	}

static func get_archetype_immune_response_rules() -> Array[Dictionary]:
	return [
		{"archetype": "carrion_eater", "immunity": "full", "reason": "symbiotic_with_growth"},
		{"archetype": "shellroot", "immunity": "full", "reason": "is_growth_host"},
		{"archetype": "carapace", "immunity": "partial", "reason": "sealed_plate_armor", "vulnerable_if": "plate_cracked"},
		{"archetype": "echo", "immunity": "full", "reason": "no_biological_tissue"},
		{"archetype": "glasswalker", "immunity": "full", "reason": "no_biological_tissue"},
		{"archetype": "relay_voice", "immunity": "full", "reason": "no_biological_tissue"},
		{"archetype": "surgeon", "immunity": "partial", "reason": "surgical_preparation", "progression_rate": "half_speed"},
		{"archetype": "stalker_husk", "immunity": "none", "progression_rate": "normal"},
		{"archetype": "bleeder", "immunity": "none", "progression_rate": "double_speed"},
		{"archetype": "howler", "immunity": "none", "progression_rate": "normal"},
		{"archetype": "choir", "immunity": "none", "progression_rate": "normal_but_disrupts_formation"},
	]

static func get_spore_density_rules() -> Dictionary:
	return {
		"density_tiers": ["ambient", "light", "dense", "saturated"],
		"density_by_growth_maturity": {
			"seedling": "ambient",
			"established": "light",
			"mature": "dense",
			"dominant": "saturated"
		},
		"density_effects_on_infection_rate": {
			"ambient": "no_effect",
			"light": "exposure_threshold_doubled_time",
			"dense": "normal_exposure_threshold",
			"saturated": "exposure_threshold_halved_time"
		},
		"dispersal_on_impact": "impact_to_growth_tile_releases_one_tier_higher_density_burst",
		"dispersal_on_fire": "fire_ignition_of_growth_releases_saturated_burst_then_clears",
		"wind_effect": "pressure_breach_carries_spores_to_adjacent_room_at_light_density"
	}

static func get_decomposition_rules() -> Dictionary:
	return {
		"stages": ["fresh", "bloating", "decomposing", "skeletal"],
		"stage_duration_seconds": {
			"fresh": 120,
			"bloating": 240,
			"decomposing": 480,
			"skeletal": "permanent"
		},
		"scent_level_by_stage": {
			"fresh": "low",
			"bloating": "medium",
			"decomposing": "high",
			"skeletal": "trace"
		},
		"carrion_eater_attraction": {
			"fresh": "detected_at_two_rooms",
			"bloating": "detected_at_three_rooms",
			"decomposing": "detected_at_four_rooms",
			"skeletal": "ignored"
		},
		"bio_growth_seeding": "decomposing_stage_body_seeds_one_bio_growth_tile_at_its_location",
		"high_temp_accelerates": "all_stages_halved_in_high_temp_zone",
		"low_temp_preserves": "all_stages_tripled_in_low_temp_zone",
		"disposal_chute_resets": "deposited_body_removed_from_room_scent_and_growth_seeding_prevented"
	}

static func get_bio_growth_and_water_rules() -> Dictionary:
	return {
		"water_on_growth": "growth_spreads_into_water_pool_tile_immediately",
		"water_transport": "bio_growth_spores_suspend_in_water_and_travel_with_water_flow",
		"coolant_on_growth": "coolant_inhibits_spread_no_growth_on_coolant_soaked_tile",
		"coolant_kills_seedling": "seedling_growth_on_coolant_tile_dies_within_thirty_seconds",
		"coolant_stunts_mature": "mature_growth_on_coolant_tile_cannot_advance_to_dominant",
		"water_plus_growth_tile": "creates_spore_suspension_fluid_see_fluid_contamination_chain_rules",
		"flooding_a_growth_room": "large_water_flood_carries_spores_to_all_floor_tiles_in_room"
	}

static func get_bio_growth_and_light_rules() -> Dictionary:
	return {
		"bright_light_effect": "retards_spread_rate_doubles_spread_time",
		"dim_light_effect": "no_effect_neutral",
		"darkness_effect": "growth_spreads_at_standard_rate_bioluminescence_visible",
		"uv_light_effect": "kills_seedling_and_established_growth_on_tile_within_fifteen_seconds",
		"uv_source": "specific_lamp_prop_in_medical_deck_and_research_vault",
		"bioluminescence_feedback": "dominant_growth_produces_glow_visible_in_darkness",
		"player_use": "uv_lamp_prop_can_clear_bio_growth_without_fire_risk",
		"archetype_interaction": "echo_uses_bioluminescence_as_patrol_anchor_uv_clearing_disrupts_patrol"
	}

static func get_parasite_dormancy_rules() -> Dictionary:
	return {
		"dormancy_condition": "sleeper_pod_archetype_inactive_until_trigger",
		"emergence_triggers": ["sound_above_threshold_within_two_tiles", "light_source_within_one_tile", "player_in_contact", "blood_pool_adjacent"],
		"dormancy_visual": "pod_appears_as_organic_growth_mass_no_movement",
		"dormancy_detection": "bioscanner_patch_detects_wet_mass_signature",
		"false_dormancy": "sleeper_pod_can_feign_dormancy_after_emerging_if_target_retreats",
		"emergence_sequence": "two_second_unfurling_animation_during_which_pod_is_vulnerable",
		"environmental_trigger_priority": "blood_pool_overrides_all_other_triggers_guaranteed_emergence"
	}

static func get_wound_environment_interaction_rules() -> Dictionary:
	return {
		"infection_risk_multiplier_by_zone": {
			"clean_dry": "one_x",
			"dusty_undisturbed": "one_point_five_x",
			"bio_growth_present": "three_x",
			"infected_pool_contact": "immediate_surface_infection",
			"irradiated_zone": "infection_risk_two_x_also_rad_exposure"
		},
		"open_wound_in_gas_zone": "irritant_gas_causes_wound_pain_spike_and_cough",
		"wound_in_coolant": "coolant_contact_with_open_wound_causes_cryo_sting_and_bleed_rate_spike",
		"wound_in_high_temp": "high_temp_cauterizes_wound_reduces_bleed_but_causes_deep_wound_burn",
		"wound_in_pressure_breach": "decompression_pulls_blood_out_faster_bleed_rate_doubled",
		"treatment_in_bad_zone": "treating_wound_in_bio_growth_zone_risks_surface_infection_during_apply"
	}

# =============================================================================
# ACOUSTICS AND VIBRATION
# =============================================================================

static func get_sound_material_transmission_rules() -> Dictionary:
	return {
		"transmission_by_material": {
			"metal_wall": "conducts_sound_well_bone_conduction_mic_effective_through_two_rooms",
			"concrete_wall": "attenuates_significantly_bone_conduction_mic_effective_through_one_room",
			"reinforced_composite": "high_attenuation_bone_conduction_mic_only_adjacent_room",
			"glass_pane": "low_attenuation_sound_passes_clearly",
			"bio_growth_mat": "sound_absorbed_bone_conduction_mic_ineffective"
		},
		"bone_conduction_mic_range": "determined_by_wall_material_between_rooms",
		"sound_bleed_under_door": "sounds_above_medium_loudness_heard_as_muffled_in_adjacent_room",
		"sealed_door_attenuation": "sealed_door_reduces_transmitted_sound_to_near_inaudible",
		"water_transmission": "impact_sound_on_flooded_tile_travels_farther_than_dry_floor"
	}

static func get_vibration_resonance_rules() -> Dictionary:
	return {
		"resonance_frequency_sources": ["sustained_howler_scream", "specific_machinery_vibration", "choir_combined_frequency"],
		"resonant_materials": ["glass_pane", "thin_metal_sheet", "pressurized_tank_wall"],
		"resonance_effect": {
			"glass_pane": "cracks_to_spider_crack_pattern_after_five_seconds_exposure",
			"thin_metal": "vibrates_audibly_may_loosen_fittings",
			"pressurized_tank": "stress_crack_develops_burst_risk_increases"
		},
		"howler_resonance": "howler_scream_sustained_for_three_seconds_shatters_adjacent_glass",
		"choir_resonance": "choir_combined_hum_creates_structural_vibration_in_buckling_zone",
		"player_use": "lure_howler_adjacent_to_glass_panel_hiding_gas_pocket_for_chain_reaction"
	}

static func get_subsonic_vibration_detection_rules() -> Dictionary:
	return {
		"detecting_archetypes": ["shellroot", "bleeder", "stalker_husk"],
		"detection_method": "feel_vibration_through_floor_structure",
		"detectable_sources": ["player_footsteps_on_metal_grating", "heavy_prop_movement", "distant_explosion"],
		"detection_range_by_surface": {
			"metal_floor": "five_tiles",
			"concrete_floor": "three_tiles",
			"textile_floor": "one_tile"
		},
		"player_counter": "move_on_textile_or_bio_growth_mat_to_eliminate_vibration_signature",
		"shellroot_advantage": "shellroot_detects_vibration_through_walls_not_just_floor",
		"boot_grips_effect": "boot_grips_slightly_dampen_footstep_vibration_transfer_to_floor"
	}

static func get_reverb_chamber_rules() -> Dictionary:
	return {
		"chamber_types": ["tight_corridor", "medium_room", "large_bay", "vertical_shaft"],
		"reverb_by_chamber": {
			"tight_corridor": "sound_bounces_directionally_enemy_can_triangulate_precisely",
			"medium_room": "moderate_reverb_direction_detectable_range_uncertain",
			"large_bay": "diffuse_reverb_direction_obscured_range_very_uncertain",
			"vertical_shaft": "extreme_reverb_sound_travels_up_and_down_highly_confusing"
		},
		"echo_archetype_advantage": "echo_is_unaffected_by_reverb_confusion_uses_acoustic_map",
		"howler_scream_in_shaft": "shaft_amplifies_and_broadcasts_scream_to_all_floors_in_shaft",
		"whistle_shout_in_large_bay": "player_shout_confuses_direction_for_most_archetypes_except_echo",
		"player_use": "fire_into_large_bay_to_obscure_direction_of_shot"
	}

static func get_white_noise_masking_rules() -> Dictionary:
	return {
		"white_noise_sources": ["active_steam_vent", "burst_pipe_water", "large_running_machinery", "pressure_release"],
		"masking_threshold": "noise_source_above_medium_loudness_in_same_tile_or_adjacent",
		"masked_sounds": ["footsteps", "reload_noise", "door_open", "quiet_crafting"],
		"not_masked": ["gunshot", "explosion", "howler_scream", "door_forced_open"],
		"archetype_effects": {
			"echo": "white_noise_partially_masks_player_even_from_echo",
			"stalker_husk": "loses_footstep_tracking_in_white_noise_zone",
			"bleeder": "loses_breathing_detection_in_white_noise_zone"
		},
		"player_use": "open_steam_valve_to_mask_movement_through_adjacent_room"
	}

static func get_sound_triggered_structural_failure_rules() -> Dictionary:
	return {
		"trigger_condition": "sustained_loud_sound_in_room_with_buckling_zone",
		"loud_sound_sources": ["gunshot", "explosion_adjacent", "howler_scream", "sustained_choir_harmonics"],
		"threshold": "three_or_more_loud_events_within_ten_seconds_in_buckling_zone",
		"result": "buckling_transitions_to_collapsed",
		"single_detonation_rule": "single_detonation_always_collapses_buckling_zone_regardless_of_count",
		"player_warning": "structural_groan_intensifies_before_collapse_audio_cue",
		"archetype_risk": "howler_in_buckling_zone_may_accidentally_collapse_ceiling_on_itself"
	}

static func get_frequency_damage_rules() -> Dictionary:
	return {
		"bio_growth_resonant_frequency": "low_bass_sustained_causes_growth_mat_to_rupture_release_spore_burst",
		"glass_resonant_frequency": "matched_to_choir_harmonic_shatters_glass_within_two_tiles",
		"electronic_vulnerable_frequency": "specific_high_frequency_from_echo_causes_glitch_tier_interference",
		"pressurized_tank_frequency": "mid_range_vibration_from_machinery_causes_stress_crack_over_time",
		"player_audible_range": "player_cannot_hear_subsonic_sources_but_takes_their_effects",
		"sources_by_frequency": {
			"howler_scream": "broadband_many_effects",
			"choir_harmonics": "glass_and_bio_growth_targeted",
			"echo_emission": "electronic_targeted"
		}
	}

static func get_impact_sound_material_rules() -> Dictionary:
	return {
		"footstep_sound_by_surface": {
			"metal_grating": "loud_ringing_highest_noise_output",
			"bare_concrete": "medium_solid_thud",
			"plastic_tile": "medium_hollow_tap",
			"bio_growth_mat": "quiet_muffled_lowest_noise_output",
			"ice_patch": "loud_crack_similar_to_metal_grating",
			"water_film": "quiet_splash",
			"water_shallow": "medium_slosh_audible_to_adjacent_rooms",
			"debris_rubble": "loud_crunch_variable"
		},
		"armor_clink_surfaces": "plate_armor_amplifies_on_metal_grating_and_bare_concrete",
		"prone_movement_noise": "fifty_percent_of_standing_footstep_noise_for_all_surfaces",
		"boot_grips_effect": "reduces_metal_grating_noise_to_concrete_equivalent"
	}

# =============================================================================
# PRESSURE AND ATMOSPHERE
# =============================================================================

static func get_pressure_vessel_failure_rules() -> Dictionary:
	return {
		"vessel_types": ["coolant_tank", "pressurized_pipe", "oxygen_cylinder", "fuel_canister"],
		"damage_states": ["intact", "stressed_hairline", "stressed_crack", "critical_leak", "rupture"],
		"damage_triggers": {
			"stressed_hairline": "bullet_graze_or_minor_impact",
			"stressed_crack": "direct_hit_or_thermal_shock",
			"critical_leak": "sustained_damage_or_second_direct_hit",
			"rupture": "explosive_nearby_or_third_direct_hit"
		},
		"leak_effects_by_type": {
			"coolant_tank": "coolant_flood_at_critical_arc_stun_zone_at_rupture",
			"pressurized_pipe": "steam_burst_at_critical_jet_at_rupture",
			"oxygen_cylinder": "o2_enrichment_fire_risk_at_critical_explosive_at_rupture",
			"fuel_canister": "oil_slick_at_critical_explosion_at_rupture"
		},
		"repair": "stasis_foam_seals_stressed_states_only_not_critical_or_rupture"
	}

static func get_explosive_decompression_rules() -> Dictionary:
	return {
		"trigger": "sealed_pressurized_room_suddenly_breached_by_large_opening",
		"trigger_sources": ["blast_door_breached", "window_explosive_shatter", "large_wall_penetration"],
		"duration": "four_seconds_of_violent_outflow",
		"effects_by_mass": {
			"lightweight_prop": "ejected_through_breach_at_lethal_velocity",
			"medium_prop": "thrown_toward_breach_stops_at_door_frame",
			"corpse": "dragged_toward_breach_may_be_ejected",
			"player": "strong_pull_camera_shake_stagger_must_grab_fixture_or_be_ejected",
			"shellroot": "unaffected_too_heavy"
		},
		"grab_fixture": "player_can_hold_a_pipe_or_railing_prop_to_resist_ejection",
		"aftermath": "room_pressure_equalizes_after_four_seconds_pull_stops"
	}

static func get_gradual_pressure_loss_rules() -> Dictionary:
	return {
		"trigger": "small_breach_in_hull_or_seal_from_bullet_hole_or_crack",
		"rate": "slow_room_pressure_drops_over_ninety_seconds_to_exterior_level",
		"audible_cues": ["hissing_from_breach_location", "subtle_wind_toward_breach", "fog_near_breach_in_cold"],
		"player_effects_by_pressure_drop": {
			"ten_percent_drop": "earache_sound_distortion",
			"thirty_percent_drop": "stamina_drain_begins",
			"fifty_percent_drop": "equivalent_to_thin_oxygen_zone",
			"full_equalization": "equivalent_to_exterior_catwalk_o2_level"
		},
		"frostbite_risk": "exposed_skin_near_breach_in_cold_environment_graze_per_thirty_seconds",
		"sealing": "stasis_foam_seals_small_breach_restores_pressure_over_sixty_seconds"
	}

static func get_pressure_equalization_rules() -> Dictionary:
	return {
		"equalization_rate_by_gap": {
			"door_cracked": "equalization_over_ten_minutes",
			"door_open": "equalization_over_ninety_seconds",
			"breach_small": "equalization_over_three_minutes",
			"breach_large": "equalization_over_thirty_seconds",
			"airlock_cycle": "equalization_controlled_and_staged"
		},
		"direction": "always_from_high_pressure_to_low",
		"gas_follows": "any_gas_in_high_pressure_room_flows_to_low_pressure_at_equalization_rate",
		"sealed_door_prevents": "sealed_door_state_stops_equalization_completely",
		"equalization_wind": "audible_airflow_heard_throughout_process_masks_movement_noise"
	}

static func get_atmospheric_mixing_rules() -> Dictionary:
	return {
		"tracked_components": ["o2_percent", "co2_percent", "gas_tag_concentration", "humidity_percent"],
		"base_atmosphere": "twenty_one_percent_o2_zero_point_four_percent_co2_normal_humidity",
		"fire_effect": "o2_decreases_co2_increases_per_second_active",
		"gas_source_effect": "gas_tag_concentration_increases_per_second_of_active_source",
		"breathing_effect": "occupants_consume_o2_and_produce_co2_negligible_without_sealed_room",
		"compound_effects": {
			"high_co2_plus_low_o2": "hypercapnia_confusion_and_hypoxia_combined_severe",
			"gas_plus_o2_enriched": "ignition_threshold_lower_deflagration_risk_higher"
		},
		"ventilation_resets": "active_ventilation_returns_all_components_to_base_over_two_minutes"
	}

static func get_airlock_cycle_physics_rules() -> Dictionary:
	return {
		"cycle_stages": ["pressurized_entry", "equalization_inner_depressurizing", "equalization_outer_pressurizing", "exit"],
		"stage_durations_seconds": {
			"equalization_inner_depressurizing": 8,
			"equalization_outer_pressurizing": 8
		},
		"intermediate_state": "both_doors_locked_during_equalization_cannot_be_forced",
		"gas_purge": "cycle_vents_room_atmosphere_to_exterior_clears_all_gas_tags",
		"item_ejection_risk": "loose_props_in_airlock_during_cycle_may_be_vented_outboard",
		"emergency_cycle": "emergency_override_skips_equalization_explosive_decompression_result",
		"power_requirement": "airlock_requires_power_manual_crank_exists_for_inner_door_only"
	}

static func get_pressure_on_door_rules() -> Dictionary:
	return {
		"pressure_differential_effect": "high_pressure_differential_requires_more_force_to_open_door",
		"threshold_effects": {
			"small_differential": "door_opens_slightly_harder_player_can_manage",
			"medium_differential": "door_requires_two_handed_brace_takes_two_seconds",
			"high_differential": "door_cannot_be_opened_by_player_without_pressure_equalization",
			"extreme_differential": "door_slams_shut_automatically_if_opened_can_injure"
		},
		"door_slam_injury": "deep_wound_to_arm_or_hand_if_caught_in_slam",
		"cracked_seal_bypass": "gas_and_pressure_seep_through_crack_reduces_effective_differential",
		"player_exploit": "high_pressure_room_with_forced_door_state_slams_door_on_pursuing_enemy"
	}

static func get_inertia_in_pressure_events_rules() -> Dictionary:
	return {
		"mass_categories": ["lightweight", "medium", "heavy", "anchored"],
		"mass_examples": {
			"lightweight": "empty_canister_glow_stick_paper",
			"medium": "weapon_backpack_med_kit",
			"heavy": "generator_cart_corpse_large_pipe_section",
			"anchored": "shellroot_structural_elements_bolted_machinery"
		},
		"pull_force_by_mass": {
			"lightweight": "ejected_immediately_full_speed",
			"medium": "dragged_toward_breach_stops_if_obstructed",
			"heavy": "barely_moved_scrapes_toward_breach",
			"anchored": "unmoved"
		},
		"player_exploit": "place_heavy_prop_against_breach_point_to_partially_seal_it_reduce_equalization_rate"
	}

# =============================================================================
# MATERIAL PROPERTIES
# =============================================================================

static func get_corrosion_rules() -> Dictionary:
	return {
		"corrosive_substances": ["decon_shower_chemical", "irradiated_fluid", "bio_growth_secretion"],
		"corrosion_stages": ["surface_tarnish", "pitting", "structural_weakening", "failure"],
		"stage_durations_seconds": {
			"surface_tarnish": 60,
			"pitting": 120,
			"structural_weakening": 180,
			"failure": "collapses_or_ruptures"
		},
		"material_resistance": {
			"reinforced_composite": "only_reaches_pitting",
			"metal": "reaches_structural_weakening_in_normal_time",
			"thin_metal": "reaches_failure_in_half_time"
		},
		"structural_effect": "structural_weakening_stage_drops_zone_to_stressed",
		"player_use": "decon_shower_chemical_corrodes_carapace_plate_over_time_if_held_under"
	}

static func get_material_fatigue_rules() -> Dictionary:
	return {
		"principle": "repeated_stress_below_single_event_threshold_accumulates_damage",
		"tracked_objects": ["blast_door", "pressurized_tank", "structural_joint", "weapon_barrel"],
		"stress_events": ["near_miss_explosion", "repeated_forced_open", "sustained_vibration", "temperature_cycling"],
		"fatigue_accumulation": "each_sub_threshold_event_adds_one_fatigue_point",
		"failure_thresholds": {
			"blast_door": "ten_fatigue_points_drops_to_dented",
			"pressurized_tank": "five_fatigue_points_drops_to_hairline_crack",
			"structural_joint": "three_fatigue_points_drops_structural_zone_to_stressed",
			"weapon_barrel": "fifteen_fatigue_points_increases_jam_risk_one_tier"
		},
		"fatigue_visibility": "visual_micro_cracks_or_discoloration_at_high_fatigue",
		"successor_persistence": "fatigue_points_persist_across_runs"
	}

static func get_surface_hardness_matrix() -> Array[Dictionary]:
	return [
		{"material": "bio_growth_mat", "hardness": "soft", "bullet_result": "absorbed", "melee_result": "splash", "shrapnel_result": "absorbed"},
		{"material": "textile_panel", "hardness": "soft", "bullet_result": "pass", "melee_result": "tear", "shrapnel_result": "pass"},
		{"material": "plastic_polymer", "hardness": "medium", "bullet_result": "pass_deformed", "melee_result": "crack", "shrapnel_result": "pass_deformed"},
		{"material": "drywall", "hardness": "medium", "bullet_result": "pass", "melee_result": "hole", "shrapnel_result": "pass"},
		{"material": "wood_composite", "hardness": "medium", "bullet_result": "pass_deformed", "melee_result": "split", "shrapnel_result": "stop"},
		{"material": "concrete", "hardness": "hard", "bullet_result": "stop_crack", "melee_result": "spark", "shrapnel_result": "stop"},
		{"material": "thin_metal_sheet", "hardness": "hard", "bullet_result": "pass_deformed", "melee_result": "dent", "shrapnel_result": "stop"},
		{"material": "reinforced_composite", "hardness": "armored", "bullet_result": "stop", "melee_result": "no_effect", "shrapnel_result": "stop"},
		{"material": "blast_panel", "hardness": "armored", "bullet_result": "stop", "melee_result": "no_effect", "shrapnel_result": "stop"},
		{"material": "carapace_plate", "hardness": "armored", "bullet_result": "stop_chip", "melee_result": "no_effect", "shrapnel_result": "stop"},
	]

static func get_material_flammability_tiers() -> Array[Dictionary]:
	return [
		{"material": "reinforced_composite", "tier": "inert", "ignition": "never", "smoke": "none"},
		{"material": "blast_panel", "tier": "inert", "ignition": "never", "smoke": "none"},
		{"material": "concrete", "tier": "inert", "ignition": "never", "smoke": "none"},
		{"material": "metal_sheet", "tier": "inert", "ignition": "never", "smoke": "none"},
		{"material": "plastic_polymer", "tier": "slow_burn", "ignition": "sustained_five_seconds", "smoke": "very_high"},
		{"material": "wood_composite", "tier": "slow_burn", "ignition": "sustained_three_seconds", "smoke": "high"},
		{"material": "rubber_seal", "tier": "slow_burn", "ignition": "sustained_eight_seconds", "smoke": "extreme"},
		{"material": "textile_panel", "tier": "fast_burn", "ignition": "any_flame", "smoke": "high"},
		{"material": "bio_growth_mat", "tier": "fast_burn", "ignition": "any_flame", "smoke": "very_high"},
		{"material": "oil_pool", "tier": "explosive", "ignition": "any_spark", "smoke": "high"},
		{"material": "gas_pocket", "tier": "explosive", "ignition": "any_spark", "smoke": "none"},
	]

static func get_thermal_conductivity_matrix() -> Array[Dictionary]:
	return [
		{"material": "metal", "conductivity": "high", "heat_transfer_rate": "one_tile_per_four_seconds"},
		{"material": "thin_metal_sheet", "conductivity": "high", "heat_transfer_rate": "one_tile_per_four_seconds"},
		{"material": "concrete", "conductivity": "medium_low", "heat_transfer_rate": "one_tile_per_twenty_seconds"},
		{"material": "wood_composite", "conductivity": "medium", "heat_transfer_rate": "one_tile_per_twelve_seconds"},
		{"material": "plastic_polymer", "conductivity": "medium", "heat_transfer_rate": "one_tile_per_ten_seconds"},
		{"material": "ceramic", "conductivity": "low", "heat_transfer_rate": "one_tile_per_forty_seconds"},
		{"material": "rubber_seal", "conductivity": "very_low", "heat_transfer_rate": "one_tile_per_sixty_seconds"},
		{"material": "bio_growth_mat", "conductivity": "very_low", "heat_transfer_rate": "one_tile_per_sixty_seconds"},
		{"material": "vacuum_gap", "conductivity": "none", "heat_transfer_rate": "no_transfer"},
		{"material": "water", "conductivity": "medium", "heat_transfer_rate": "one_tile_per_ten_seconds"},
		{"material": "coolant", "conductivity": "high", "heat_transfer_rate": "one_tile_per_three_seconds_cooling_only"},
	]

static func get_porosity_and_absorption_rules() -> Array[Dictionary]:
	return [
		{"material": "concrete", "porosity": "medium", "absorbs": ["water", "blood", "gas"], "release_rate": "slow"},
		{"material": "textile_panel", "porosity": "high", "absorbs": ["water", "blood", "gas", "coolant"], "release_rate": "medium"},
		{"material": "bio_growth_mat", "porosity": "very_high", "absorbs": ["all_fluids", "all_gas"], "release_rate": "slow"},
		{"material": "wood_composite", "porosity": "medium_high", "absorbs": ["water", "blood"], "release_rate": "medium", "note": "absorbed_water_makes_wood_burn_slower_initially"},
		{"material": "plastic_polymer", "porosity": "none", "absorbs": [], "release_rate": "none"},
		{"material": "metal", "porosity": "none", "absorbs": [], "release_rate": "none"},
		{"material": "reinforced_composite", "porosity": "none", "absorbs": [], "release_rate": "none"},
		{"material": "blast_panel", "porosity": "none", "absorbs": [], "release_rate": "none"},
	]

static func get_magnetism_rules() -> Dictionary:
	return {
		"ferromagnetic_materials": ["metal_props", "weapon_without_polymer_frame", "pipe_section", "loose_fuse"],
		"magnetic_sources": ["active_mag_lock", "ferrofluid_lure_concentration", "arc_junction_powered"],
		"attraction_radius": {
			"mag_lock": "one_tile_for_lightweight_ferromagnetic",
			"ferrofluid_concentration": "two_tiles_for_carapace_archetype",
			"arc_junction": "one_tile_weak_attraction"
		},
		"player_items_affected": "weapons_with_metal_components_may_be_slightly_pulled_affecting_aim",
		"carapace_archetype": "strongly_attracted_to_ferrofluid_concentration",
		"glasswalker_interaction": "glasswalker_not_affected_non_ferromagnetic",
		"blocking": "non_ferromagnetic_barrier_between_source_and_item_negates_attraction"
	}

static func get_reflectivity_rules() -> Dictionary:
	return {
		"high_reflectivity": ["polished_metal_surface", "glass_pane_intact", "ice_patch"],
		"medium_reflectivity": ["painted_metal", "plastic_surface"],
		"low_reflectivity": ["concrete", "textile", "wood_composite"],
		"no_reflectivity": ["bio_growth_mat", "dark_rubber"],
		"flashlight_reflection": "high_reflectivity_surface_bounces_flashlight_cone_to_adjacent_area",
		"reflection_reveal": "flashlight_around_corner_can_be_detected_via_reflection_on_metal_wall",
		"player_exploit": "angle_light_off_polished_surface_to_illuminate_area_without_line_of_sight",
		"enemy_use": "glasswalker_uses_reflective_surfaces_to_detect_light_sources"
	}

static func get_oxidation_rules() -> Dictionary:
	return {
		"oxidizing_condition": "metal_surface_exposed_to_water_or_humid_air_over_time",
		"oxidation_stages": ["clean", "surface_rust", "deep_rust", "degraded"],
		"stage_durations_seconds": {
			"surface_rust": 300,
			"deep_rust": 600,
			"degraded": "permanent_unless_treated"
		},
		"stage_effects": {
			"surface_rust": "visual_only",
			"deep_rust": "door_hinge_or_mechanism_stiffness_verb_takes_longer",
			"degraded": "mechanism_fails_door_jams_pipe_bursts_at_lower_pressure"
		},
		"coolant_accelerates": "coolant_exposure_doubles_oxidation_rate",
		"oil_prevents": "oil_coating_prevents_oxidation_while_present",
		"successor_persistence": "oxidation_stage_persists_across_runs"
	}

static func get_material_spall_rules() -> Dictionary:
	return {
		"spall_definition": "back_face_fragmentation_of_material_hit_by_high_velocity_projectile",
		"spall_capable_materials": ["concrete", "reinforced_composite", "thin_metal_sheet"],
		"spall_trigger": "rifle_ballistic_or_industrial_slug_impacting_stop_result",
		"spall_fragment_count": "two_to_five_fragments_per_impact",
		"spall_direction": "radiate_outward_from_back_face_in_cone",
		"spall_velocity_tier": "low_velocity_graze_wound_to_unprotected_targets_behind_wall",
		"spall_detection": "target_behind_cover_may_take_spall_wounds_despite_cover",
		"armor_vs_spall": "soft_armor_stops_spall_fragments_plate_armor_stops_all"
	}

# =============================================================================
# ENVIRONMENTAL CASCADE AND FEEDBACK
# =============================================================================

static func get_multi_step_reaction_chain_rules() -> Array[Dictionary]:
	return [
		{
			"id": "gas_ignition_to_fire_to_oil",
			"steps": ["gas_pocket_at_pocket_tier", "spark_ignition", "deflagration_blast", "fire_tag_spreads_to_oil_slick", "burning_oil_intensifies"],
			"end_state": "sustained_room_fire",
			"player_escape_window": "one_second_between_deflagration_and_oil_ignition"
		},
		{
			"id": "pipe_rupture_to_stun_kill",
			"steps": ["shoot_coolant_pipe_joint", "coolant_flood", "lure_enemy_into_zone", "trigger_arc_junction", "stunned_zone_incapacitates_enemy"],
			"end_state": "enemy_incapacitated_in_coolant",
			"player_action_count": 3
		},
		{
			"id": "growth_ignition_spore_rain",
			"steps": ["mature_bio_growth_present", "fire_tag_applied", "bio_growth_burns", "spore_burst_released", "smoke_tag_masks_spore_cloud"],
			"end_state": "masked_infection_zone",
			"danger": "player_may_not_see_spore_cloud_in_smoke"
		},
		{
			"id": "structural_chain_collapse",
			"steps": ["unstable_ceiling_present", "sustained_howler_scream", "buckling_state", "explosive_nearby", "full_collapse"],
			"end_state": "collapsed_zone_with_debris_field",
			"player_use": "prepare_zone_then_lure_howler_as_trigger"
		},
		{
			"id": "pressure_cascade_decontamination",
			"steps": ["sealed_gas_room", "open_blast_door", "explosive_decompression", "gas_vented_outboard", "room_cleared"],
			"end_state": "clean_room_with_breach_side_now_gassed",
			"player_risk": "player_must_brace_or_be_pulled_out_during_decompression"
		},
	]

static func get_zone_tag_inheritance_rules() -> Dictionary:
	return {
		"spread_conditions": {
			"fire": "spreads_to_adjacent_if_flammable_material_present",
			"smoke": "spreads_to_adjacent_following_pressure_differential",
			"coolant": "spreads_to_adjacent_along_floor_slope",
			"bio_growth": "spreads_to_adjacent_over_time",
			"electric": "spreads_via_conductive_fluid_contact",
			"gas": "spreads_by_diffusion_and_ventilation_current"
		},
		"blocking_conditions": {
			"fire": "sealed_door_coolant_pool_stasis_foam",
			"smoke": "sealed_door_pressure_breach_redirects",
			"coolant": "drain_grate_slope_up",
			"bio_growth": "coolant_soaked_tile_high_temp_tile",
			"electric": "rubber_mat_insulating_tile",
			"gas": "sealed_door_stasis_foam_in_vent"
		},
		"priority": "coolant_suppresses_fire_takes_priority_over_spread_in_same_tile",
		"simultaneous_tags": "tile_can_hold_multiple_tags_simultaneously_all_effects_apply"
	}

static func get_environmental_memory_rules() -> Dictionary:
	return {
		"persistence_tiers": ["seconds", "minutes", "run_persistent", "permanent"],
		"examples": {
			"seconds": ["gas_pocket_dispersed", "steam_burst_cleared", "arc_flash_resolved"],
			"minutes": ["coolant_pool_evaporating", "fresh_blood_drying", "fire_ember_cooling"],
			"run_persistent": ["dried_blood_stain", "ice_patch_unmelted", "structural_damage_state", "oxidation_stage"],
			"permanent": ["collapsed_zone_state", "fully_decomposed_remains", "destroyed_device", "successor_rope"]
		},
		"corruption_interaction": "at_high_corruption_some_seconds_tier_memories_appear_to_persist_as_hallucinations",
		"successor_sees": "run_persistent_and_permanent_memories_visible_to_next_survivor"
	}

static func get_feedback_loop_rules() -> Array[Dictionary]:
	return [
		{
			"id": "fire_oil_runaway",
			"components": ["active_fire", "oil_slick_adjacent"],
			"loop": "fire_ignites_oil_larger_fire_spreads_to_more_oil",
			"termination": "coolant_or_stasis_foam_breaks_loop",
			"unchecked_result": "entire_room_fire_within_sixty_seconds"
		},
		{
			"id": "coolant_electric_chain_stun",
			"components": ["coolant_spreading", "multiple_arc_junctions"],
			"loop": "coolant_reaches_arc_junction_triggers_stun_zone_stun_zone_arc_flash_can_rupture_next_pipe",
			"termination": "power_cut_to_floor",
			"unchecked_result": "cascading_stun_zones_across_floor"
		},
		{
			"id": "bio_growth_decomposition_feed",
			"components": ["bio_growth", "decomposing_corpse"],
			"loop": "growth_expands_to_corpse_tile_feeds_on_organic_matter_expands_faster",
			"termination": "fire_or_coolant_covering_corpse_tile",
			"unchecked_result": "dominant_growth_in_room_within_ten_minutes"
		},
		{
			"id": "oxygen_fire_extinction",
			"components": ["large_fire", "sealed_room"],
			"loop": "fire_consumes_o2_low_o2_slows_fire_less_heat_less_spread",
			"termination": "fire_self_extinguishes_at_ten_percent_o2",
			"note": "self_limiting_loop_fire_eventually_kills_itself"
		},
	]

static func get_event_priority_rules() -> Dictionary:
	return {
		"override_pairs": {
			"coolant_vs_fire": "coolant_wins_extinguishes_fire_even_in_oil",
			"stasis_foam_vs_gas_spread": "stasis_foam_in_vent_wins_blocks_gas_current",
			"pressure_breach_vs_smoke_movement": "pressure_breach_wins_overrides_normal_smoke_diffusion",
			"fire_vs_bio_growth": "fire_wins_clears_growth_instantly",
			"water_vs_electric_on_floor": "water_wins_conducts_arc_regardless_of_insulating_tile"
		},
		"simultaneous_reactions": "if_two_reactions_trigger_same_tick_both_resolve_in_order_fire_then_electric_then_bio",
		"player_priority": "player_direct_action_always_takes_priority_over_passive_environmental_process"
	}

static func get_cross_zone_contamination_rules() -> Dictionary:
	return {
		"vectors": ["shared_ventilation_duct", "door_gap", "vent_grate", "blast_door_crack", "capillary_seep"],
		"contaminants_that_travel": ["gas", "smoke", "spore_gas", "bio_growth_spore_in_suspension"],
		"transmission_rate_by_vector": {
			"shared_ventilation_duct": "full_concentration_transfer_per_vent_cycle",
			"door_gap": "one_third_concentration_per_room",
			"blast_door_crack": "trace_concentration_only",
			"capillary_seep": "fluid_contaminants_only_very_slow"
		},
		"blocking": "sealed_door_and_stasis_foam_in_vent_block_all_vectors",
		"player_use": "open_vent_between_gas_room_and_enemy_room_to_push_toxin_through",
		"tracking": "contamination_reaching_new_room_starts_at_trace_tier_builds_from_there"
	}

static func get_humidity_and_moisture_rules() -> Dictionary:
	return {
		"humidity_tiers": ["dry", "normal", "humid", "saturated"],
		"humidity_sources": {
			"humid": ["active_decon_shower", "large_water_pool", "steam_tag_persisting"],
			"saturated": ["flooded_room", "coolant_flood_with_no_drain"]
		},
		"humidity_effects": {
			"dry": "static_charge_builds_faster_bio_growth_spread_slows",
			"normal": "no_special_effect",
			"humid": "condensation_forms_on_cold_surfaces_bio_growth_spread_accelerates",
			"saturated": "electronics_at_risk_without_protective_cover_bio_growth_at_maximum_spread"
		},
		"temperature_interaction": "hot_humid_zone_is_high_temp_plus_humid_stacks_both_effect_sets",
		"dehumidification": "high_temp_zone_or_pressure_breach_reduces_humidity_one_tier"
	}

static func get_dust_accumulation_rules() -> Dictionary:
	return {
		"accumulation_condition": "room_undisturbed_no_events_no_occupants_for_extended_period",
		"dust_tiers": ["clean", "light_dust", "heavy_dust", "thick_undisturbed"],
		"dust_effects": {
			"light_dust": "movement_in_room_creates_particle_cloud_visible_for_ten_seconds",
			"heavy_dust": "particle_cloud_larger_and_lingers_twenty_seconds",
			"thick_undisturbed": "particle_cloud_obscures_like_thin_haze_thirty_seconds"
		},
		"footprint_interaction": "footprints_clearly_visible_in_heavy_dust_even_without_substance",
		"archetype_detection": "dust_particle_cloud_detected_by_echo_as_movement_signature",
		"player_exploit": "throw_object_into_heavy_dust_room_to_create_false_movement_signature",
		"clearing": "ventilation_or_pressure_event_removes_accumulated_dust_resets_to_clean"
	}

static func get_crystallization_rules() -> Dictionary:
	return {
		"crystal_forming_substances": ["coolant_at_low_temp", "water_at_extreme_low_temp", "irradiated_fluid_at_low_temp"],
		"crystal_formation_time": "fifteen_seconds_at_low_temp_tier_five_seconds_at_extreme_cold",
		"crystal_surfaces": ["floor_tile", "wall_panel", "pipe_exterior", "door_frame"],
		"crystal_effects": {
			"floor": "very_high_slip_chance_similar_to_ice_patch_but_harder_crunch_sound",
			"wall": "visual_only_but_blocks_capillary_seep_at_crack",
			"pipe_exterior": "insulates_pipe_from_further_heat_loss_extends_coolant_window",
			"door_frame": "jams_door_mechanism_door_requires_force_open_verb"
		},
		"electric_conductivity": "crystals_are_non_conductive_insulate_floor",
		"fire_melts": "fire_tag_melts_crystals_to_fluid_instantly",
		"weapon_use": "breaching_slug_impact_shatters_door_frame_crystals"
	}

static func get_gravity_anomaly_physics_rules() -> Dictionary:
	return {
		"gravity_pocket_zones": "defined_in_get_anomaly_rooms",
		"projectile_arc_in_low_g": "bullets_arc_upward_require_aim_compensation_for_long_range",
		"fluid_behavior_in_low_g": "fluids_do_not_pool_form_floating_spheres_or_coat_all_surfaces",
		"enemy_movement_in_low_g": {
			"stalker_husk": "moves_across_ceiling_as_easily_as_floor",
			"crawler_husk": "natural_advantage_full_speed_on_any_surface",
			"carapace": "reduced_speed_mass_works_against_it_in_low_g",
			"shellroot": "cannot_anchor_effectively_reduced_effectiveness"
		},
		"player_movement_in_low_g": "slower_horizontal_speed_but_can_push_off_walls_to_accelerate",
		"sound_in_low_g": "no_change_vibration_travels_through_structure_normally",
		"fire_in_low_g": "spherical_flame_no_directional_rise_burns_in_all_directions_equally"
	}

static func get_cascade_kill_chain_rules() -> Array[Dictionary]:
	return [
		{
			"id": "reactor_room_shutdown",
			"steps": ["gain_access_to_reactor_panel", "overload_circuit", "reactor_heat_rises", "coolant_pipe_rupture_triggered", "coolant_flood_reactor_room", "arc_flash_from_coolant_on_reactor_panel", "power_grid_cascade_floor_blackout"],
			"player_requirement": "access_credential_plus_tool_parts",
			"result": "floor_blackout_large_coolant_zone_arc_stun_region",
			"difficulty": "high"
		},
		{
			"id": "specimen_lab_purge",
			"steps": ["deactivate_containment_unit", "bio_growth_floods_lab", "lure_carrion_eater_into_lab", "close_blast_door", "activate_decon_shower", "chemical_spray_kills_growth_and_carrion_eater"],
			"player_requirement": "access_to_decon_shower_and_blast_door_controls",
			"result": "room_cleared_of_growth_and_enemy_simultaneously",
			"difficulty": "medium"
		},
		{
			"id": "gas_room_purge_with_pressure",
			"steps": ["gas_pocket_builds_in_sealed_room", "place_door_charge_patch_on_blast_door", "move_to_safe_distance", "detonate_charge", "explosive_decompression_purges_gas_outboard"],
			"player_requirement": "door_charge_patch_plus_eight_meter_range",
			"result": "gas_room_cleared_without_entering_it",
			"difficulty": "low"
		},
		{
			"id": "enemy_cluster_thermal_kill",
			"steps": ["identify_enemy_cluster_in_stressed_zone", "lure_howler_into_same_zone", "howler_scream_buckling", "throw_door_charge_patch_onto_ceiling", "detonate_triggers_collapse_and_concussive_wave"],
			"player_requirement": "howler_lure_and_door_charge_patch",
			"result": "multiple_enemies_killed_by_structural_collapse_and_blast",
			"difficulty": "high"
		},
		{
			"id": "flooding_electrical_kill",
			"steps": ["rupture_coolant_pipe", "wait_for_coolant_to_pool_under_arc_junction", "trigger_arc_junction", "stunned_zone_created", "enemies_in_zone_incapacitated"],
			"player_requirement": "line_of_sight_to_pipe_joint_and_arc_junction",
			"result": "area_denial_zone_with_multiple_enemy_incapacitation",
			"difficulty": "medium"
		},
	]
