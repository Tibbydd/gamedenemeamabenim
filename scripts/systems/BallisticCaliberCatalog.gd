extends RefCounted
class_name BallisticCaliberCatalog

# Real-world caliber data. The point of this catalog is to express bullets as
# physical things, not balance knobs. A round either reliably ends a person or
# it does not. Damage is not a slider; per-part lethality and barrier behavior
# are spelled out explicitly. Game code should read these structures and act on
# the discrete outcomes ("one-shot lethal to head", "fails to penetrate plate",
# "overpenetrates light wall and may hit next room") rather than scaling a
# damage number.

const PART_HEAD := "head"
const PART_NECK := "neck"
const PART_CHEST := "chest"
const PART_STOMACH := "stomach"
const PART_ARM := "arm"
const PART_LEG := "leg"

const LETHALITY_LETHAL := "lethal"          # one solid hit ends the target
const LETHALITY_INCAPACITATE := "incap"     # disables that part, drops the target if vital
const LETHALITY_DEEP_WOUND := "deep"        # heavy bleed, fracture risk, will kill if untreated
const LETHALITY_GRAZE := "graze"            # painful, slows, can cause panic-drop
const LETHALITY_STOP := "stop"              # bullet is stopped by armor/material, may still bruise

const BARRIER_DRYWALL := "drywall"
const BARRIER_THIN_METAL := "thin_metal"
const BARRIER_PRESSURE_DOOR := "pressure_door"
const BARRIER_GLASS := "glass"
const BARRIER_BODY_ARMOR_SOFT := "soft_armor"
const BARRIER_BODY_ARMOR_PLATE := "plate_armor"
const BARRIER_CARAPACE_PLATE := "carapace_plate"
const BARRIER_LOCK_HOUSING := "lock_housing"

static func get_calibers() -> Array[Dictionary]:
	return [
		_c("9x19_para", "9x19 Parachute", "light_ballistic",
			{
				PART_HEAD: LETHALITY_LETHAL,
				PART_NECK: LETHALITY_LETHAL,
				PART_CHEST: LETHALITY_DEEP_WOUND,
				PART_STOMACH: LETHALITY_DEEP_WOUND,
				PART_ARM: LETHALITY_GRAZE,
				PART_LEG: LETHALITY_DEEP_WOUND
			},
			{
				BARRIER_DRYWALL: "pass",
				BARRIER_THIN_METAL: "pass_deformed",
				BARRIER_PRESSURE_DOOR: "stop",
				BARRIER_GLASS: "pass",
				BARRIER_BODY_ARMOR_SOFT: "stop",
				BARRIER_BODY_ARMOR_PLATE: "stop",
				BARRIER_CARAPACE_PLATE: "stop",
				BARRIER_LOCK_HOUSING: "damage"
			},
			"supersonic"),
		_c("45_acp", ".45 Service", "heavy_ballistic",
			{
				PART_HEAD: LETHALITY_LETHAL,
				PART_NECK: LETHALITY_LETHAL,
				PART_CHEST: LETHALITY_INCAPACITATE,
				PART_STOMACH: LETHALITY_DEEP_WOUND,
				PART_ARM: LETHALITY_DEEP_WOUND,
				PART_LEG: LETHALITY_DEEP_WOUND
			},
			{
				BARRIER_DRYWALL: "pass",
				BARRIER_THIN_METAL: "stop",
				BARRIER_PRESSURE_DOOR: "stop",
				BARRIER_GLASS: "pass",
				BARRIER_BODY_ARMOR_SOFT: "stop_bruise",
				BARRIER_BODY_ARMOR_PLATE: "stop",
				BARRIER_CARAPACE_PLATE: "stop",
				BARRIER_LOCK_HOUSING: "destroy"
			},
			"subsonic"),
		_c("357_magnum", ".357 Magnum", "heavy_ballistic",
			{
				PART_HEAD: LETHALITY_LETHAL,
				PART_NECK: LETHALITY_LETHAL,
				PART_CHEST: LETHALITY_LETHAL,
				PART_STOMACH: LETHALITY_INCAPACITATE,
				PART_ARM: LETHALITY_DEEP_WOUND,
				PART_LEG: LETHALITY_INCAPACITATE
			},
			{
				BARRIER_DRYWALL: "pass",
				BARRIER_THIN_METAL: "pass",
				BARRIER_PRESSURE_DOOR: "stop",
				BARRIER_GLASS: "pass",
				BARRIER_BODY_ARMOR_SOFT: "stop_bruise",
				BARRIER_BODY_ARMOR_PLATE: "stop",
				BARRIER_CARAPACE_PLATE: "stop",
				BARRIER_LOCK_HOUSING: "destroy"
			},
			"supersonic"),
		_c("57x28", "5.7x28 Needle", "light_ballistic",
			{
				PART_HEAD: LETHALITY_LETHAL,
				PART_NECK: LETHALITY_LETHAL,
				PART_CHEST: LETHALITY_INCAPACITATE,
				PART_STOMACH: LETHALITY_DEEP_WOUND,
				PART_ARM: LETHALITY_GRAZE,
				PART_LEG: LETHALITY_DEEP_WOUND
			},
			{
				BARRIER_DRYWALL: "pass",
				BARRIER_THIN_METAL: "pass",
				BARRIER_PRESSURE_DOOR: "stop",
				BARRIER_GLASS: "pass",
				BARRIER_BODY_ARMOR_SOFT: "pass",
				BARRIER_BODY_ARMOR_PLATE: "stop",
				BARRIER_CARAPACE_PLATE: "stop_chip",
				BARRIER_LOCK_HOUSING: "damage"
			},
			"supersonic"),
		_c("556x45", "5.56x45 Service", "rifle_ballistic",
			{
				PART_HEAD: LETHALITY_LETHAL,
				PART_NECK: LETHALITY_LETHAL,
				PART_CHEST: LETHALITY_LETHAL,
				PART_STOMACH: LETHALITY_INCAPACITATE,
				PART_ARM: LETHALITY_INCAPACITATE,
				PART_LEG: LETHALITY_INCAPACITATE
			},
			{
				BARRIER_DRYWALL: "pass",
				BARRIER_THIN_METAL: "pass",
				BARRIER_PRESSURE_DOOR: "stop",
				BARRIER_GLASS: "pass",
				BARRIER_BODY_ARMOR_SOFT: "pass",
				BARRIER_BODY_ARMOR_PLATE: "stop",
				BARRIER_CARAPACE_PLATE: "stop_chip",
				BARRIER_LOCK_HOUSING: "destroy"
			},
			"supersonic"),
		_c("762x39", "7.62x39 Conscript", "rifle_ballistic",
			{
				PART_HEAD: LETHALITY_LETHAL,
				PART_NECK: LETHALITY_LETHAL,
				PART_CHEST: LETHALITY_LETHAL,
				PART_STOMACH: LETHALITY_LETHAL,
				PART_ARM: LETHALITY_INCAPACITATE,
				PART_LEG: LETHALITY_INCAPACITATE
			},
			{
				BARRIER_DRYWALL: "pass",
				BARRIER_THIN_METAL: "pass",
				BARRIER_PRESSURE_DOOR: "stop_pit",
				BARRIER_GLASS: "pass",
				BARRIER_BODY_ARMOR_SOFT: "pass",
				BARRIER_BODY_ARMOR_PLATE: "stop_crack",
				BARRIER_CARAPACE_PLATE: "stop_crack",
				BARRIER_LOCK_HOUSING: "destroy"
			},
			"supersonic"),
		_c("308_win", ".308 Long", "rifle_ballistic",
			{
				PART_HEAD: LETHALITY_LETHAL,
				PART_NECK: LETHALITY_LETHAL,
				PART_CHEST: LETHALITY_LETHAL,
				PART_STOMACH: LETHALITY_LETHAL,
				PART_ARM: LETHALITY_LETHAL,
				PART_LEG: LETHALITY_LETHAL
			},
			{
				BARRIER_DRYWALL: "pass",
				BARRIER_THIN_METAL: "pass",
				BARRIER_PRESSURE_DOOR: "pass",
				BARRIER_GLASS: "pass",
				BARRIER_BODY_ARMOR_SOFT: "pass",
				BARRIER_BODY_ARMOR_PLATE: "pass",
				BARRIER_CARAPACE_PLATE: "stop_crack",
				BARRIER_LOCK_HOUSING: "destroy"
			},
			"supersonic"),
		_c("12ga_buck", "12ga Buckshot", "shotgun_ballistic",
			{
				PART_HEAD: LETHALITY_LETHAL,
				PART_NECK: LETHALITY_LETHAL,
				PART_CHEST: LETHALITY_LETHAL,
				PART_STOMACH: LETHALITY_LETHAL,
				PART_ARM: LETHALITY_INCAPACITATE,
				PART_LEG: LETHALITY_INCAPACITATE
			},
			{
				BARRIER_DRYWALL: "pass",
				BARRIER_THIN_METAL: "stop",
				BARRIER_PRESSURE_DOOR: "stop",
				BARRIER_GLASS: "pass",
				BARRIER_BODY_ARMOR_SOFT: "stop_bruise",
				BARRIER_BODY_ARMOR_PLATE: "stop",
				BARRIER_CARAPACE_PLATE: "stop",
				BARRIER_LOCK_HOUSING: "destroy"
			},
			"subsonic"),
		_c("12ga_slug", "12ga Slug", "shotgun_ballistic",
			{
				PART_HEAD: LETHALITY_LETHAL,
				PART_NECK: LETHALITY_LETHAL,
				PART_CHEST: LETHALITY_LETHAL,
				PART_STOMACH: LETHALITY_LETHAL,
				PART_ARM: LETHALITY_LETHAL,
				PART_LEG: LETHALITY_LETHAL
			},
			{
				BARRIER_DRYWALL: "pass",
				BARRIER_THIN_METAL: "pass",
				BARRIER_PRESSURE_DOOR: "stop_pit",
				BARRIER_GLASS: "pass",
				BARRIER_BODY_ARMOR_SOFT: "stop_bruise",
				BARRIER_BODY_ARMOR_PLATE: "stop_crack",
				BARRIER_CARAPACE_PLATE: "stop_crack",
				BARRIER_LOCK_HOUSING: "destroy"
			},
			"supersonic"),
		_c("50_bmg", ".50 Heavy", "industrial_slug",
			{
				PART_HEAD: LETHALITY_LETHAL,
				PART_NECK: LETHALITY_LETHAL,
				PART_CHEST: LETHALITY_LETHAL,
				PART_STOMACH: LETHALITY_LETHAL,
				PART_ARM: LETHALITY_LETHAL,
				PART_LEG: LETHALITY_LETHAL
			},
			{
				BARRIER_DRYWALL: "pass",
				BARRIER_THIN_METAL: "pass",
				BARRIER_PRESSURE_DOOR: "pass",
				BARRIER_GLASS: "pass",
				BARRIER_BODY_ARMOR_SOFT: "pass",
				BARRIER_BODY_ARMOR_PLATE: "pass",
				BARRIER_CARAPACE_PLATE: "pass",
				BARRIER_LOCK_HOUSING: "destroy"
			},
			"supersonic"),
		_c("flechette_dart", "Flechette Dart", "flechette",
			{
				PART_HEAD: LETHALITY_LETHAL,
				PART_NECK: LETHALITY_LETHAL,
				PART_CHEST: LETHALITY_DEEP_WOUND,
				PART_STOMACH: LETHALITY_DEEP_WOUND,
				PART_ARM: LETHALITY_GRAZE,
				PART_LEG: LETHALITY_GRAZE
			},
			{
				BARRIER_DRYWALL: "pass",
				BARRIER_THIN_METAL: "pass",
				BARRIER_PRESSURE_DOOR: "stop",
				BARRIER_GLASS: "pass",
				BARRIER_BODY_ARMOR_SOFT: "pass",
				BARRIER_BODY_ARMOR_PLATE: "stop",
				BARRIER_CARAPACE_PLATE: "stop",
				BARRIER_LOCK_HOUSING: "damage"
			},
			"supersonic"),
	]

# Sub-loads ride on top of the caliber and change concrete behavior, not damage.
static func get_ammo_subloads() -> Array[Dictionary]:
	return [
		{
			"id": "full_metal_jacket",
			"label": "Full Metal Jacket",
			"penetration_shift": "up_one_tier",
			"wound_channel": "narrow",
			"behavior": "overpenetrates soft targets; can pass through and hit room behind"
		},
		{
			"id": "armor_piercing",
			"label": "Armor Piercing",
			"penetration_shift": "up_two_tiers",
			"wound_channel": "narrow",
			"behavior": "cracks Carapace plate in one hit, but body wound is small"
		},
		{
			"id": "hollow_point",
			"label": "Hollow Point",
			"penetration_shift": "down_one_tier",
			"wound_channel": "wide",
			"behavior": "shreds Bleeder soft tissue; stops on plate"
		},
		{
			"id": "tracer",
			"label": "Tracer",
			"penetration_shift": "same",
			"wound_channel": "narrow",
			"behavior": "visible streak betrays firing position to nearby parasites"
		},
		{
			"id": "subsonic",
			"label": "Subsonic",
			"penetration_shift": "down_one_tier",
			"wound_channel": "narrow",
			"behavior": "no supersonic crack; suppressed weapons stay near-silent"
		},
		{
			"id": "match_grade",
			"label": "Match Grade",
			"penetration_shift": "same",
			"wound_channel": "narrow",
			"behavior": "tighter group at range; pairs with weapon zero"
		},
		{
			"id": "incendiary",
			"label": "Incendiary",
			"penetration_shift": "same",
			"wound_channel": "narrow",
			"behavior": "ignites coolant/oil tiles on impact; tags target with burning_pain"
		},
		{
			"id": "frangible",
			"label": "Frangible",
			"penetration_shift": "stop_at_thin_metal",
			"wound_channel": "wide",
			"behavior": "safe against pressure hulls and reactor walls; brutal at point blank"
		},
	]

static func get_caliber(caliber_id: String) -> Dictionary:
	for caliber in get_calibers():
		if String(caliber["id"]) == caliber_id:
			return caliber
	return {}

static func get_lethality(caliber_id: String, part: String, subload: String = "") -> String:
	var caliber := get_caliber(caliber_id)
	if caliber.is_empty():
		return LETHALITY_GRAZE
	var lethality_table: Dictionary = caliber.get("lethality", {})
	var result: String = String(lethality_table.get(part, LETHALITY_GRAZE))
	if subload == "hollow_point":
		# Wider channel never weakens a hit, but it cannot upgrade past lethal either.
		if result == LETHALITY_GRAZE:
			result = LETHALITY_DEEP_WOUND
		elif result == LETHALITY_DEEP_WOUND:
			result = LETHALITY_INCAPACITATE
	elif subload == "armor_piercing":
		# AP through soft tissue makes a narrower channel; downgrade unless already lethal.
		if result == LETHALITY_INCAPACITATE:
			result = LETHALITY_DEEP_WOUND
		elif result == LETHALITY_DEEP_WOUND:
			result = LETHALITY_GRAZE
	return result

static func get_barrier_result(caliber_id: String, barrier: String, subload: String = "") -> String:
	var caliber := get_caliber(caliber_id)
	if caliber.is_empty():
		return "stop"
	var barriers: Dictionary = caliber.get("barriers", {})
	var base: String = String(barriers.get(barrier, "stop"))
	if subload == "armor_piercing":
		match base:
			"stop_chip": return "stop_crack"
			"stop_crack": return "pass"
			"stop": return "stop_crack"
			_: return base
	elif subload == "hollow_point":
		match base:
			"pass": return "stop_bruise"
			"pass_deformed": return "stop"
			"stop_crack": return "stop"
			_: return base
	elif subload == "frangible":
		match base:
			"pass": return "stop"
			"pass_deformed": return "stop"
			_: return base
	return base

static func emits_supersonic_crack(caliber_id: String, subload: String = "") -> bool:
	if subload == "subsonic":
		return false
	var caliber := get_caliber(caliber_id)
	return String(caliber.get("acoustic", "supersonic")) == "supersonic"

static func _c(id: String, label: String, family: String, lethality: Dictionary, barriers: Dictionary, acoustic: String) -> Dictionary:
	return {
		"id": id,
		"label": label,
		"family": family,
		"lethality": lethality,
		"barriers": barriers,
		"acoustic": acoustic
	}
