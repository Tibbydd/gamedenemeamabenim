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
var attachments: Dictionary = {}
var weapon_condition: float = 1.0

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

func equip_weapon(weapon_id: String) -> void:
	data = WeaponData.create_weapon(weapon_id)
	current_ammo = data.magazine_size
	reserve_ammo = data.reserve_ammo
	is_reloading = false
	reload_timer = 0.0
	cooldown = 0.0
	attachments.clear()
	weapon_condition = 1.0
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
	if owner_body and owner_body.has_method("can_operate_weapon") and not owner_body.can_operate_weapon():
		return false
	if owner_health and not owner_health.active_treatment.is_empty():
		return false
	if owner_health and not owner_health.can_hold_weapon():
		return false
	if current_ammo <= 0:
		start_reload()
		return false
	current_ammo -= 1
	var one_handed_penalty := 1.25 if owner_health and owner_health.is_two_handed_compromised() else 1.0
	cooldown = (1.0 / max(0.1, data.fire_rate)) * one_handed_penalty
	GameEvents.emit_player_noise(owner_body.global_position, _get_effective_loudness())
	_fire_projectile()
	ammo_changed.emit(current_ammo, reserve_ammo)
	return true

func set_barrel_interference(obstruction_amount: float, push_side: float) -> void:
	barrel_obstruction = clamp(obstruction_amount, 0.0, 1.0)
	barrel_push_side = clamp(push_side, -1.0, 1.0)

func start_reload() -> bool:
	if is_reloading or current_ammo >= _get_effective_magazine_size() or reserve_ammo <= 0:
		return false
	if owner_body and owner_body.has_method("can_operate_weapon") and not owner_body.can_operate_weapon():
		return false
	if owner_health and not owner_health.active_treatment.is_empty():
		return false
	if owner_health and not owner_health.can_hold_weapon():
		return false
	is_reloading = true
	var handling := owner_health.get_handling_modifier() if owner_health else 1.0
	reload_timer = _get_effective_reload_time() / max(0.35, handling)
	GameEvents.emit_player_noise(owner_body.global_position, 18.0)
	return true

func add_reserve_ammo(amount: int) -> void:
	reserve_ammo = max(0, reserve_ammo + amount)
	ammo_changed.emit(current_ammo, reserve_ammo)

func install_attachment(attachment_id: String) -> String:
	var slot := _get_attachment_slot(attachment_id)
	if slot.is_empty():
		return ""
	attachments[slot] = attachment_id
	if attachment_id == "extended_magazine":
		current_ammo = min(current_ammo + 8, _get_effective_magazine_size())
	ammo_changed.emit(current_ammo, reserve_ammo)
	return StationSystemsCatalog.get_weapon_attachment_label(attachment_id)

func has_attachment(attachment_id: String) -> bool:
	return attachments.values().has(attachment_id)

func _finish_reload() -> void:
	var needed := _get_effective_magazine_size() - current_ammo
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
		_get_effective_velocity(),
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
	var one_handed_spread := 0.055 if owner_health and owner_health.is_two_handed_compromised() else 0.0
	var spread_rad := deg_to_rad(_get_effective_spread_degrees() / max(0.4, handling)) + corruption_spread + obstruction_spread + one_handed_spread
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

func get_manual_ammo_check() -> String:
	if current_ammo <= 0:
		return "MAG CHECK: empty."
	var ratio := float(current_ammo) / float(max(1, _get_effective_magazine_size()))
	if ratio > 0.8:
		return "MAG CHECK: heavy, almost full."
	if ratio > 0.55:
		return "MAG CHECK: more than half."
	if ratio > 0.25:
		return "MAG CHECK: light, under half."
	return "MAG CHECK: very light."

func get_inspection_text() -> String:
	var attachment_labels: Array[String] = []
	for attachment_id in attachments.values():
		attachment_labels.append(StationSystemsCatalog.get_weapon_attachment_label(String(attachment_id)))
	var attachment_text := _join_labels(attachment_labels) if not attachment_labels.is_empty() else "no attachments"
	var grip_text := owner_health.get_weapon_handling_state() if owner_health else "unknown grip"
	return "%s\n%s / %s\n%s\nCondition %.0f%%" % [data.weapon_name, data.weapon_family.to_upper(), data.ammo_type.replace("_", " "), attachment_text, weapon_condition * 100.0] + "\n" + grip_text

func _join_labels(labels: Array[String]) -> String:
	var text := ""
	for label in labels:
		if not text.is_empty():
			text += ", "
		text += label
	return text

func _get_attachment_slot(attachment_id: String) -> String:
	for attachment in StationSystemsCatalog.get_weapon_attachments():
		if String(attachment["id"]) == attachment_id:
			return String(attachment["slot"])
	return ""

func _get_effective_magazine_size() -> int:
	var size := data.magazine_size
	if has_attachment("extended_magazine"):
		size += max(4, int(round(float(data.magazine_size) * 0.35)))
	return size

func _get_effective_reload_time() -> float:
	var reload := data.reload_time
	if has_attachment("extended_magazine"):
		reload *= 1.15
	if has_attachment("quickpull_magwell"):
		reload *= 0.82
	return reload

func _get_effective_loudness() -> float:
	var loudness := data.loudness
	if has_attachment("compact_suppressor"):
		loudness *= 0.58
	if has_attachment("port_compensator"):
		loudness *= 1.18
	return loudness

func _get_effective_velocity() -> float:
	var velocity := data.muzzle_velocity
	if has_attachment("compact_suppressor"):
		velocity *= 0.92
	return velocity

func _get_effective_spread_degrees() -> float:
	var spread := data.spread_degrees
	if has_attachment("foregrip"):
		spread *= 0.75
	if has_attachment("reflex_sight"):
		spread *= 0.88
	if has_attachment("laser_pointer"):
		spread *= 0.82
	if has_attachment("port_compensator"):
		spread *= 0.86
	if has_attachment("compact_suppressor"):
		spread *= 1.05
	return spread
