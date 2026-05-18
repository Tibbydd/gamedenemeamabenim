extends RefCounted
class_name ImmersiveSimDesign

# Design pillars expressed as queryable data. Other systems read this catalog
# instead of hard-coding tone/policy decisions. Everything here is concrete:
# no abstract numeric buffs, only named tags, triggers, verbs, and thresholds
# that downstream code already understands.

static func get_pillars() -> Array[Dictionary]:
	return [
		{"id": "station_judges_you", "label": "Station judges you", "consumer": "threat_director", "input": "room_reputation_tags"},
		{"id": "death_leaves_testimony", "label": "Death leaves testimony", "consumer": "lost_kit", "input": "predecessor_corruption_and_cause"},
		{"id": "tools_are_verbs", "label": "Tools as verbs", "consumer": "economy", "input": "item_verb_list_unlocks_with_blueprints"},
		{"id": "light_is_language", "label": "Light as language", "consumer": "comms_and_archetypes", "input": "flashlight_blink_pattern_and_sector_light_state"},
		{"id": "trust_is_resource", "label": "Trust as resource", "consumer": "comms_manager", "input": "obey_distorted_message_decays_trust"},
		{"id": "bodies_are_history", "label": "Bodies as history", "consumer": "threat_director_and_recorder", "input": "corpse_density_and_recovered_gear_narrative"},
		{"id": "combat_is_surgery", "label": "Combat as surgery", "consumer": "enemy_hit_zones", "input": "independently_destructible_armor_pieces"},
		{"id": "floors_are_chapters", "label": "Floors as chapters", "consumer": "facility_progression", "input": "per_floor_identity_locks_and_pickups"},
		{"id": "corruption_is_ui_horror", "label": "Corruption as interface horror", "consumer": "mental_state_manager", "input": "module_contradictions_and_learnable_tells"},
		{"id": "causality_first", "label": "Immersive sim causality first", "consumer": "dynamic_world_system", "input": "shared_event_bus_with_environment_tags"},
	]

# Reputation tags stick to rooms. The threat director queries these when
# choosing archetypes for the next pressure beat in that room.
static func get_room_reputation_tags() -> Array[Dictionary]:
	return [
		{"id": "bloodshed", "label": "Bloodshed", "trigger": "n_kills_in_room >= 3", "attracts": ["surgeon", "carrion_eater"]},
		{"id": "forced", "label": "Forced", "trigger": "any_door_force_opened", "attracts": ["carapace", "stalker_husk"]},
		{"id": "hoarder", "label": "Hoarder", "trigger": "player_stash_or_loop_loot", "attracts": ["surgeon", "stalker_twin"]},
		{"id": "wired", "label": "Wired", "trigger": "lights_or_power_repaired", "attracts": ["echo", "relay_voice"]},
		{"id": "silent", "label": "Silent", "trigger": "no_shot_for_5_min_in_room", "attracts": ["choir", "sleeper_pod"]},
		{"id": "scorched", "label": "Scorched", "trigger": "thermal_or_fire_event", "attracts": ["shellroot", "carrion_eater"]},
	]

# Trust is a private float, surfaced only by comms tone and accuracy.
static func get_trust_thresholds() -> Dictionary:
	return {
		"healthy": 0.85,
		"strained": 0.55,
		"distorted": 0.3,
		"hostile_interpretation": 0.1
	}

# What concretely changes when the player obeys vs refuses a distorted message.
static func get_trust_deltas() -> Dictionary:
	return {
		"obey_distorted_route": -0.18,
		"obey_distorted_threat_call": -0.12,
		"refuse_distorted_request": +0.08,
		"verify_with_field_recorder": +0.12,
		"complete_genuine_favor": +0.22
	}

# Floor-specific objectives. Each ties to a specific chapter identity.
static func get_floor_chapter_objectives() -> Array[Dictionary]:
	return [
		{"floor": "medical_deck", "objective_id": "recover_three_vials", "label": "Recover three pharma vials", "unlock": "biohazard_lock_to_industrial_core"},
		{"floor": "industrial_core", "objective_id": "restart_main_crusher_loop", "label": "Restart the main crusher loop", "unlock": "research_vault_blast_door"},
		{"floor": "research_vault", "objective_id": "pull_credentials_chip", "label": "Pull the admin credentials chip", "unlock": "admin_spine_lift"},
		{"floor": "admin_spine", "objective_id": "purge_security_lockout", "label": "Purge the security lockout", "unlock": "exterior_works_airlock"},
		{"floor": "exterior_works", "objective_id": "align_comms_antenna", "label": "Align the comms antenna", "unlock": "final_escape_route"},
		{"floor": "hab_ring", "objective_id": "recover_personal_log", "label": "Recover a habitation log", "unlock": "trust_meter_reveal"},
	]

# Archetype reputation. Killing too many of one kind escalates a counter.
static func get_archetype_reputation_responses() -> Array[Dictionary]:
	return [
		{"trigger": "kills_of_choir >= 3", "response": "spawn_surgeon_hunt"},
		{"trigger": "clean_carapace_plate_shots >= 4", "response": "spawn_stalker_twin_pair"},
		{"trigger": "stealth_kills >= 6", "response": "spawn_relay_voice_misdirection"},
		{"trigger": "loud_fights >= 4", "response": "raise_howler_floor_spawn_weight"},
		{"trigger": "scent_trail_left", "response": "spawn_bleeder_tracker"},
	]

# Environment tags for the shared event bus. Causality chains read these.
static func get_environment_tags() -> Array[String]:
	return [
		"fire",
		"gas",
		"water",
		"coolant",
		"electric",
		"steam",
		"oxygen_thin",
		"pressure_breach",
		"smoke",
		"bio_growth",
		"low_temp",
		"high_temp"
	]

# Concrete pairwise reaction outcomes consumed by DynamicWorldSystem.
static func get_environment_reactions() -> Array[Dictionary]:
	return [
		{"a": "coolant", "b": "electric", "result": "stunned_zone", "duration": 4.0},
		{"a": "steam", "b": "fire", "result": "scalding_burst", "duration": 1.0},
		{"a": "gas", "b": "fire", "result": "deflagration_blast", "duration": 0.2},
		{"a": "water", "b": "electric", "result": "wide_stun_area", "duration": 3.5},
		{"a": "bio_growth", "b": "fire", "result": "clear_growth_emit_smoke", "duration": 6.0},
		{"a": "oxygen_thin", "b": "fire", "result": "fire_starves_quickly", "duration": 1.5},
		{"a": "pressure_breach", "b": "smoke", "result": "smoke_pulled_outboard", "duration": 6.0},
		{"a": "pressure_breach", "b": "fire", "result": "fire_pulled_outboard_then_dies", "duration": 4.0},
		{"a": "low_temp", "b": "bleeding_player", "result": "bleed_rate_slows_but_pain_recovery_slows", "duration": 0.0},
		{"a": "high_temp", "b": "bleeding_player", "result": "bleed_rate_rises", "duration": 0.0},
	]

# Save terminals only exist at safehouse facility nodes.
static func get_save_terminal_nodes() -> Array[Dictionary]:
	return [
		{"id": "hab_safehouse_a", "module": "hab_ring", "label": "Habitation safehouse A"},
		{"id": "hab_safehouse_b", "module": "hab_ring", "label": "Habitation safehouse B"},
		{"id": "research_quarantine", "module": "research_vault", "label": "Quarantine annex"},
		{"id": "admin_chapel", "module": "admin_spine", "label": "Admin chapel"},
		{"id": "exterior_lighthouse", "module": "exterior_works", "label": "Powered lighthouse beacon"},
	]
