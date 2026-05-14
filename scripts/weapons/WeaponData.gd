extends Resource
class_name WeaponData

@export var weapon_name: String = "M-7 Colony Pistol"
@export var damage: float = 36.0
@export var muzzle_velocity: float = 95.0
@export var projectile_gravity: float = 7.0
@export var projectile_lifetime: float = 2.0
@export var fire_rate: float = 5.5
@export var magazine_size: int = 12
@export var reserve_ammo: int = 48
@export var reload_time: float = 1.45
@export var spread_degrees: float = 0.45
@export var loudness: float = 52.0
@export var recoil_pitch: float = 0.018

static func create_starting_pistol() -> WeaponData:
	var data := WeaponData.new()
	data.weapon_name = "M-7 Colony Pistol"
	data.damage = 38.0
	data.muzzle_velocity = 105.0
	data.projectile_gravity = 6.5
	data.projectile_lifetime = 2.2
	data.fire_rate = 5.0
	data.magazine_size = 12
	data.reserve_ammo = 48
	data.reload_time = 1.35
	data.spread_degrees = 0.35
	data.loudness = 58.0
	data.recoil_pitch = 0.02
	return data
