extends Resource
class_name WeaponData

@export var weapon_name: String = "M-7 Colony Pistol"
@export var weapon_id: String = "m7_colony_pistol"
@export var weapon_family: String = "sidearm"
@export var ammo_type: String = "light_ballistic"
@export var damage: float = 38.0
@export var muzzle_velocity: float = 105.0
@export var projectile_gravity: float = 6.5
@export var projectile_lifetime: float = 2.2
@export var fire_rate: float = 5.0
@export var magazine_size: int = 12
@export var reserve_ammo: int = 48
@export var reload_time: float = 1.35
@export var spread_degrees: float = 0.35
@export var loudness: float = 58.0
@export var recoil_pitch: float = 0.02

static func create_starting_pistol() -> WeaponData:
	return create_weapon("m7_colony_pistol")

static func create_weapon(requested_id: String) -> WeaponData:
	for definition in get_weapon_catalog():
		if String(definition["id"]) == requested_id:
			return _from_definition(definition)
	return _from_definition(get_weapon_catalog()[0])

static func _from_definition(definition: Dictionary) -> WeaponData:
	var data := WeaponData.new()
	data.weapon_id = String(definition["id"])
	data.weapon_name = String(definition["name"])
	data.weapon_family = String(definition["family"])
	data.ammo_type = String(definition["ammo"])
	data.damage = float(definition["damage"])
	data.muzzle_velocity = float(definition["velocity"])
	data.projectile_gravity = float(definition["gravity"])
	data.projectile_lifetime = float(definition["lifetime"])
	data.fire_rate = float(definition["fire_rate"])
	data.magazine_size = int(definition["magazine"])
	data.reserve_ammo = int(definition["reserve"])
	data.reload_time = float(definition["reload"])
	data.spread_degrees = float(definition["spread"])
	data.loudness = float(definition["loudness"])
	data.recoil_pitch = float(definition["recoil"])
	return data

static func get_weapon_catalog() -> Array[Dictionary]:
	return [
		_w("m7_colony_pistol", "M-7 Colony Pistol", "sidearm", "light_ballistic", 38, 105, 6.5, 2.2, 5.0, 12, 48, 1.35, 0.35, 58, 0.02),
		_w("m3_holdout", "M-3 Holdout", "sidearm", "light_ballistic", 31, 95, 6.8, 2.0, 6.4, 10, 40, 1.05, 0.65, 42, 0.014),
		_w("m9_security_revolver", "M-9 Security Revolver", "sidearm", "heavy_ballistic", 56, 120, 5.8, 2.4, 2.6, 6, 30, 1.8, 0.25, 66, 0.035),
		_w("viper_machine_pistol", "Viper Machine Pistol", "sidearm", "light_ballistic", 24, 92, 7.2, 1.8, 12.0, 20, 80, 1.55, 1.7, 68, 0.013),
		_w("boltline_target_pistol", "Boltline Target Pistol", "sidearm", "light_ballistic", 44, 130, 4.8, 2.6, 3.8, 9, 45, 1.5, 0.18, 54, 0.024),
		_w("rattler_smg", "Rattler SMG", "smg", "light_ballistic", 27, 96, 7.0, 2.0, 13.0, 32, 128, 1.8, 1.25, 74, 0.014),
		_w("hushline_smg", "Hushline SMG", "smg", "light_ballistic", 25, 88, 7.4, 1.9, 10.0, 28, 112, 1.65, 0.95, 46, 0.011),
		_w("dockyard_breacher_smg", "Dockyard Breacher SMG", "smg", "light_ballistic", 32, 92, 8.0, 1.7, 9.2, 25, 100, 1.7, 1.45, 78, 0.017),
		_w("needle_storm_pdw", "Needle Storm PDW", "smg", "flechette", 22, 135, 3.0, 2.3, 15.0, 40, 160, 2.0, 1.8, 70, 0.012),
		_w("station_guard_carbine", "Station Guard Carbine", "smg", "light_ballistic", 34, 115, 5.6, 2.3, 8.5, 24, 96, 1.6, 0.75, 63, 0.018),
		_w("a12_service_rifle", "A-12 Service Rifle", "ar", "rifle_ballistic", 42, 145, 4.0, 2.8, 7.5, 30, 120, 2.1, 0.42, 78, 0.025),
		_w("a19_longwatch", "A-19 Longwatch", "ar", "rifle_ballistic", 55, 170, 3.2, 3.0, 4.0, 20, 80, 2.2, 0.18, 74, 0.032),
		_w("hullbreaker_ar", "Hullbreaker AR", "ar", "heavy_ballistic", 48, 132, 5.0, 2.5, 6.2, 25, 100, 2.35, 0.58, 82, 0.033),
		_w("survey_burst_rifle", "Survey Burst Rifle", "ar", "rifle_ballistic", 39, 150, 3.8, 2.7, 9.0, 27, 108, 2.0, 0.7, 68, 0.021),
		_w("rail_assist_carbine", "Rail Assist Carbine", "ar", "rifle_ballistic", 62, 210, 1.6, 2.4, 2.8, 12, 60, 2.4, 0.16, 88, 0.04),
		_w("l6_deck_lmg", "L-6 Deck LMG", "lmg", "rifle_ballistic", 39, 135, 4.8, 2.8, 11.0, 75, 225, 4.4, 1.4, 92, 0.026),
		_w("bracket_feed_lmg", "Bracket Feed LMG", "lmg", "heavy_ballistic", 46, 128, 5.4, 2.5, 8.2, 60, 180, 4.0, 1.0, 96, 0.034),
		_w("suppression_spooler", "Suppression Spooler", "lmg", "light_ballistic", 29, 118, 5.8, 2.3, 16.0, 100, 300, 5.2, 2.2, 98, 0.02),
		_w("mining_auto_rifle", "Mining Auto Rifle", "lmg", "industrial_slug", 64, 110, 6.5, 2.2, 4.5, 40, 120, 3.6, 0.85, 100, 0.052),
		_w("tripod_rescue_gun", "Tripod Rescue Gun", "lmg", "rifle_ballistic", 52, 145, 4.2, 2.7, 6.0, 45, 135, 3.2, 0.5, 90, 0.043),
		_w("torch_lance", "Torch Lance", "thermal", "fuel_canister", 9, 30, 0.5, 0.7, 18.0, 80, 160, 2.4, 4.2, 72, 0.006),
		_w("hab_sanitizer", "Hab Sanitizer", "thermal", "fuel_canister", 7, 26, 0.4, 0.8, 20.0, 100, 200, 2.8, 5.2, 66, 0.004),
		_w("industrial_flame_rig", "Industrial Flame Rig", "thermal", "fuel_canister", 12, 32, 0.6, 0.75, 14.0, 60, 180, 3.0, 3.6, 86, 0.01),
		_w("plasma_cutter_spray", "Plasma Cutter Spray", "thermal", "charged_cell", 18, 45, 0.7, 0.45, 8.0, 24, 96, 2.2, 1.2, 82, 0.018),
		_w("cryo_burner", "Cryo Burner", "thermal", "coolant_cell", 11, 28, 0.4, 0.9, 12.0, 50, 150, 2.6, 3.8, 58, 0.006),
	]

static func _w(id: String, name: String, family: String, ammo: String, damage: float, velocity: float, gravity: float, lifetime: float, fire_rate: float, magazine: int, reserve: int, reload: float, spread: float, loudness: float, recoil: float) -> Dictionary:
	return {
		"id": id,
		"name": name,
		"family": family,
		"ammo": ammo,
		"damage": damage,
		"velocity": velocity,
		"gravity": gravity,
		"lifetime": lifetime,
		"fire_rate": fire_rate,
		"magazine": magazine,
		"reserve": reserve,
		"reload": reload,
		"spread": spread,
		"loudness": loudness,
		"recoil": recoil
	}
