extends Node
class_name WeaponController

signal ammo_changed(current: int, reserve: int)
signal shot_fired(projectile: BallisticProjectile)
signal recoil_requested(amount: float)
signal condition_changed(condition: float)

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
var attachment_durability: Dictionary = {}
var weapon_condition: float = 1.0
var thermal_heat: float = 0.0
var chamber_loaded: bool = true
var thermal_heat_ceiling: float = 120.0

func setup(new_owner: CharacterBody3D, new_camera: Camera3D, new_muzzle: Node3D, health: PlayerHealthBodyParts, mental_state: MentalStateManager) -> void:
	owner_body = new_owner
	camera = new_camera
	muzzle = new_muzzle
	owner_health = health
	mental = mental_state
	data = WeaponData.create_starting_pistol()
	current_ammo = data.magazine_size
	reserve_ammo = data.reserve_ammo
	chamber_loaded = current_ammo > 0
	ammo_changed.emit(current_ammo, reserve_ammo)

func equip_weapon(weapon_id: String) -> void:
	data = WeaponData.create_weapon(weapon_id)
	current_ammo = data.magazine_size
	reserve_ammo = data.reserve_ammo
	is_reloading = false
	reload_timer = 0.0
	cooldown = 0.0
	attachments.clear()
	attachment_durability.clear()
	weapon_condition = 1.0
	chamber_loaded = current_ammo > 0
	thermal_heat = 0.0
	ammo_changed.emit(current_ammo, reserve_ammo)
	condition_changed.emit(weapon_condition)

func _process(delta: float) -> void:
	cooldown = max(0.0, cooldown - delta)
	thermal_heat = max(0.0, thermal_heat - delta * 18.0)
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
	chamber_loaded = current_ammo > 0
	_degrade_condition(0.0025 if data.weapon_family != "thermal" else 0.004)
	_apply_thermal_heat()
	_update_attachment_wear()
	var one_handed_penalty := 1.25 if owner_health and owner_health.is_two_handed_compromised() else 1.0
	cooldown = (1.0 / max(0.1, data.fire_rate)) * one_handed_penalty
	GameEvents.emit_player_noise(owner_body.global_position, _get_effective_loudness())
	_emit_telemetry_ping()
	GameEvents.request_sound("suppressed_gunshot" if has_attachment("compact_suppressor") else "gunshot", muzzle.global_position if muzzle else owner_body.global_position, clamp(_get_effective_loudness() / 70.0, 0.45, 1.4))
	_fire_projectile()
	recoil_requested.emit(_get_effective_recoil_pitch())
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
	if current_ammo > 0 and _uses_partial_magazines():
		var dropped_rounds := max(0, current_ammo - 1)
		if dropped_rounds > 0:
			_drop_partial_magazine(dropped_rounds)
		current_ammo = 1
		chamber_loaded = true
	is_reloading = true
	var handling := owner_health.get_handling_modifier() if owner_health else 1.0
	reload_timer = _get_effective_reload_time() / max(0.35, handling)
	GameEvents.emit_player_noise(owner_body.global_position, 18.0)
	GameEvents.request_sound("reload", owner_body.global_position, 0.7)
	return true

func add_reserve_ammo(amount: int) -> void:
	reserve_ammo = max(0, reserve_ammo + amount)
	ammo_changed.emit(current_ammo, reserve_ammo)

func add_reserve_ammo_for_type(ammo_type: String, amount: int) -> bool:
	if not data or ammo_type != data.ammo_type:
		return false
	add_reserve_ammo(amount)
	return true

func install_attachment(attachment_id: String) -> String:
	var slot := _get_attachment_slot(attachment_id)
	if slot.is_empty():
		return ""
	attachments[slot] = attachment_id
	attachment_durability[attachment_id] = StationSystemsCatalog.get_weapon_attachment_durability(attachment_id)
	ammo_changed.emit(current_ammo, reserve_ammo)
	return StationSystemsCatalog.get_weapon_attachment_label(attachment_id)

func has_attachment(attachment_id: String) -> bool:
	return attachments.values().has(attachment_id)

func _finish_reload() -> void:
	var needed := _get_effective_magazine_size() - current_ammo
	var loaded := min(needed, reserve_ammo)
	current_ammo += loaded
	reserve_ammo -= loaded
	chamber_loaded = current_ammo > 0
	is_reloading = false
	reload_timer = 0.0
	ammo_changed.emit(current_ammo, reserve_ammo)

func _uses_partial_magazines() -> bool:
	return data and data.weapon_family != "thermal"

func _drop_partial_magazine(rounds: int) -> void:
	if rounds <= 0 or not owner_body:
		return
	var scene := get_tree().current_scene
	if not scene:
		return
	var pickup := EquipmentPickup3D.new()
	pickup.name = "DroppedPartialMagazine"
	pickup.configure_ammo(data.ammo_type, rounds)
	scene.add_child(pickup)
	var right := owner_body.global_transform.basis.x
	pickup.global_position = owner_body.global_position + right * 0.45 + Vector3(0.0, 0.35, 0.0)
	GameEvents.request_sound("mag_drop", pickup.global_position, 0.7)

func _apply_thermal_heat() -> void:
	if not data or data.weapon_family != "thermal":
		return
	thermal_heat = min(thermal_heat_ceiling, thermal_heat + 7.0 + data.fire_rate * 0.18)
	if thermal_heat >= 80.0 and owner_health:
		var burn_damage := 4.0 if thermal_heat < 100.0 else 9.0
		owner_health.apply_damage(PlayerHealthBodyParts.PART_RIGHT_ARM, burn_damage, "burn")
		GameEvents.request_sound("hazard_steam", owner_body.global_position if owner_body else Vector3.ZERO, 0.45)

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
	var pain_factor := float((owner_body as PlayerControllerFPS).pain_spread_modifier) if owner_body is PlayerControllerFPS else 1.0
	var pain_spread := owner_health.pain * 0.0004 * pain_factor if owner_health else 0.0
	var condition_spread := (1.0 - weapon_condition) * 0.045
	var spread_rad := deg_to_rad(_get_effective_spread_degrees() / max(0.4, handling)) + corruption_spread + obstruction_spread + one_handed_spread + pain_spread + condition_spread
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
		return "MAG CHECK: chamber cold, magazine empty."
	var ratio := float(current_ammo) / float(max(1, _get_effective_magazine_size()))
	var chamber := "chambered" if chamber_loaded else "no chambered round"
	var tactile := "mag tugs hard" if ratio > 0.72 else ("mag has middle weight" if ratio > 0.35 else "mag barely pulls")
	var partial := " A partial magazine would feel uneven." if current_ammo < _get_effective_magazine_size() and current_ammo > 0 else ""
	if ratio > 0.8:
		return "MAG CHECK: %s, %s, almost full.%s" % [chamber, tactile, partial]
	if ratio > 0.55:
		return "MAG CHECK: %s, %s, more than half.%s" % [chamber, tactile, partial]
	if ratio > 0.25:
		return "MAG CHECK: %s, %s, under half.%s" % [chamber, tactile, partial]
	return "MAG CHECK: %s, %s, nearly dry.%s" % [chamber, tactile, partial]

func get_inspection_text() -> String:
	var attachment_labels: Array[String] = []
	for attachment_id in attachments.values():
		attachment_labels.append(StationSystemsCatalog.get_weapon_attachment_label(String(attachment_id)))
	var attachment_text := _join_labels(attachment_labels) if not attachment_labels.is_empty() else "no attachments"
	var grip_text := owner_health.get_weapon_handling_state() if owner_health else "unknown grip"
	var chamber_text := "chamber loaded" if chamber_loaded else "chamber empty"
	var heat_text := "\nHeat %.0f%%" % thermal_heat if data.weapon_family == "thermal" else ""
	return "%s\n%s / %s / %s\n%s\nCondition %.0f%%%s" % [data.weapon_name, data.weapon_family.to_upper(), data.ammo_type.replace("_", " "), chamber_text, attachment_text, weapon_condition * 100.0, heat_text] + "\n" + grip_text

func get_weapon_state() -> Dictionary:
	return {
		"weapon_id": data.weapon_id if data else "m7_colony_pistol",
		"current_ammo": current_ammo,
		"reserve_ammo": reserve_ammo,
		"chamber_loaded": chamber_loaded,
		"condition": weapon_condition,
		"attachments": attachments.duplicate(true),
		"attachment_durability": attachment_durability.duplicate(true)
	}

func apply_weapon_state(state: Dictionary) -> void:
	equip_weapon(String(state.get("weapon_id", "m7_colony_pistol")))
	current_ammo = int(state.get("current_ammo", current_ammo))
	reserve_ammo = int(state.get("reserve_ammo", reserve_ammo))
	chamber_loaded = bool(state.get("chamber_loaded", current_ammo > 0))
	weapon_condition = clamp(float(state.get("condition", weapon_condition)), 0.05, 1.0)
	attachments.clear()
	attachment_durability.clear()
	var stored_attachments: Dictionary = state.get("attachments", {})
	var stored_durability: Dictionary = state.get("attachment_durability", {})
	for slot in stored_attachments.keys():
		var attachment_id := String(stored_attachments[slot])
		attachments[String(slot)] = attachment_id
		attachment_durability[attachment_id] = float(stored_durability.get(attachment_id, StationSystemsCatalog.get_weapon_attachment_durability(attachment_id)))
	ammo_changed.emit(current_ammo, reserve_ammo)
	condition_changed.emit(weapon_condition)

func degrade_from_drop(amount: float = 0.035) -> void:
	_degrade_condition(amount)

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

func _degrade_condition(amount: float) -> void:
	weapon_condition = clamp(weapon_condition - amount, 0.05, 1.0)
	condition_changed.emit(weapon_condition)

func _update_attachment_wear() -> void:
	if has_attachment("compact_suppressor"):
		var durability := float(attachment_durability.get("compact_suppressor", 1.0)) - (1.0 / 120.0)
		attachment_durability["compact_suppressor"] = durability
		if durability <= 0.0:
			_remove_attachment("compact_suppressor")
			GameEvents.request_sound("mag_drop", muzzle.global_position if muzzle else owner_body.global_position, 0.45)

func _remove_attachment(attachment_id: String) -> void:
	var slot_to_remove := ""
	for slot in attachments.keys():
		if String(attachments[slot]) == attachment_id:
			slot_to_remove = String(slot)
			break
	if slot_to_remove.is_empty():
		return
	attachments.erase(slot_to_remove)
	attachment_durability.erase(attachment_id)
	ammo_changed.emit(current_ammo, reserve_ammo)

func _emit_telemetry_ping() -> void:
	if not has_attachment("ammo_telemetry_transmitter"):
		return
	var ping_position := muzzle.global_position if muzzle else owner_body.global_position
	GameEvents.emit_player_noise(ping_position, 6.0)
	GameEvents.request_sound("telemetry_ping", ping_position, 0.22)

func _get_effective_recoil_pitch() -> float:
	var recoil := data.recoil_pitch
	if has_attachment("port_compensator"):
		recoil *= 0.72
	if has_attachment("foregrip"):
		recoil *= 0.82
	recoil *= lerp(1.25, 0.75, weapon_condition)
	if owner_health:
		recoil *= 1.0 + owner_health.pain / 140.0
	return recoil

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
