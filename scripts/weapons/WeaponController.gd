extends Node
class_name WeaponController

signal ammo_changed(current: int, reserve: int)
signal shot_fired(projectile: BallisticProjectile)

var data: WeaponData
var current_ammo: int = 0
var reserve_ammo: int = 0
var cooldown: float = 0.0
var reload_timer: float = 0.0
var is_reloading: bool = false
var camera: Camera3D
var muzzle: Node3D
var owner_body: CharacterBody3D
var owner_health: PlayerHealthBodyParts
var mental: MentalStateManager
var barrel_obstruction: float = 0.0
var barrel_push_side: float = 0.0

func setup(new_owner: CharacterBody3D, new_camera: Camera3D, new_muzzle: Node3D, health: PlayerHealthBodyParts, mental_state: MentalStateManager) -> void:
	owner_body = new_owner
	camera = new_camera
	muzzle = new_muzzle
	owner_health = health
	mental = mental_state
	data = WeaponData.create_starting_pistol()
	current_ammo = data.magazine_size
	reserve_ammo = data.reserve_ammo
	ammo_changed.emit(current_ammo, reserve_ammo)

func _process(delta: float) -> void:
	cooldown = max(0.0, cooldown - delta)
	if is_reloading:
		reload_timer -= delta
		if reload_timer <= 0.0:
			_finish_reload()
		return
	if InputBus.wants_fire():
		try_fire()

func try_fire() -> bool:
	if not data or not camera or cooldown > 0.0 or is_reloading:
		return false
	if owner_health and not owner_health.active_treatment.is_empty():
		return false
	if current_ammo <= 0:
		start_reload()
		return false
	current_ammo -= 1
	cooldown = 1.0 / data.fire_rate
	GameEvents.emit_player_noise(owner_body.global_position, data.loudness)
	_fire_projectile()
	ammo_changed.emit(current_ammo, reserve_ammo)
	return true

func set_barrel_interference(obstruction_amount: float, push_side: float) -> void:
	barrel_obstruction = clamp(obstruction_amount, 0.0, 1.0)
	barrel_push_side = clamp(push_side, -1.0, 1.0)

func start_reload() -> bool:
	if is_reloading or current_ammo >= data.magazine_size or reserve_ammo <= 0:
		return false
	if owner_health and not owner_health.active_treatment.is_empty():
		return false
	is_reloading = true
	var handling := owner_health.get_handling_modifier() if owner_health else 1.0
	reload_timer = data.reload_time / max(0.35, handling)
	GameEvents.emit_player_noise(owner_body.global_position, 18.0)
	return true

func _finish_reload() -> void:
	var needed := data.magazine_size - current_ammo
	var loaded := min(needed, reserve_ammo)
	current_ammo += loaded
	reserve_ammo -= loaded
	is_reloading = false
	reload_timer = 0.0
	ammo_changed.emit(current_ammo, reserve_ammo)

func _fire_projectile() -> void:
	var spread := _get_spread_radians()
	var direction := _get_spread_direction(spread)
	var projectile := BallisticProjectile.new()
	var muzzle_origin := muzzle.global_position if muzzle else camera.global_position + direction * 0.55
	var scene := get_tree().current_scene
	if not scene:
		return
	scene.add_child(projectile)
	projectile.configure(
		muzzle_origin,
		direction,
		data.muzzle_velocity,
		data.damage,
		data.projectile_gravity,
		data.projectile_lifetime,
		data.weapon_name,
		owner_body
	)
	shot_fired.emit(projectile)

func _get_spread_radians() -> float:
	var handling := owner_health.get_handling_modifier() if owner_health else 1.0
	var corruption_spread := mental.corruption * 0.004 if mental else 0.0
	var obstruction_spread := barrel_obstruction * 0.09
	var spread_rad := deg_to_rad(data.spread_degrees / max(0.4, handling)) + corruption_spread + obstruction_spread
	return max(0.0, spread_rad)

func _get_spread_direction(spread_radians: float) -> Vector3:
	var aim_point := camera.global_position + -camera.global_transform.basis.z * 80.0
	var origin := muzzle.global_position if muzzle else camera.global_position
	var direction := (aim_point - origin).normalized()
	if barrel_obstruction > 0.01 and abs(barrel_push_side) > 0.01:
		direction = (direction + camera.global_transform.basis.x * barrel_push_side * barrel_obstruction * 0.45).normalized()
	if spread_radians <= 0.001:
		return direction.normalized()
	var right := camera.global_transform.basis.x
	var up := camera.global_transform.basis.y
	var offset := right * randf_range(-spread_radians, spread_radians) + up * randf_range(-spread_radians, spread_radians)
	return (direction + offset).normalized()

func get_ammo_display() -> String:
	var ammo_text := str(current_ammo)
	if mental:
		ammo_text = mental.get_display_ammo(current_ammo)
	return "%s / %d" % [ammo_text, reserve_ammo]
