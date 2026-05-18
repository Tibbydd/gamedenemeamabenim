extends Node
class_name WeaponController

signal ammo_changed(current: int, reserve: int)
signal shot_fired(projectile: BallisticProjectile)
signal recoil_requested(pitch_radians: float, yaw_radians: float, rearward_kick: float)
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
	if not data:
		equip_weapon("m7_colony_pistol")
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
	var condition_wear: float = 0.0025
	if data.weapon_family == "thermal":
		condition_wear = 0.004
	_degrade_condition(condition_wear)
	_apply_thermal_heat()
	_update_attachment_wear()
	var one_handed_penalty: float = 1.0
	if owner_health and owner_health.is_two_handed_compromised():
		one_handed_penalty = 1.25
	cooldown = (1.0 / max(0.1, data.fire_rate)) * one_handed_penalty
	GameEvents.emit_player_noise(owner_body.global_position, _get_effective_loudness())
	_emit_telemetry_ping()
	var shot_sound: String = "gunshot"
	if has_attachment("compact_suppressor"):
		shot_sound = "suppressed_gunshot"
	var sound_position: Vector3 = owner_body.global_position
	if muzzle:
		sound_position = muzzle.global_position
	GameEvents.request_sound(shot_sound, sound_position, clamp(_get_effective_loudness() / 70.0, 0.45, 1.4))
	if data.weapon_family == "thermal":
		_fire_flame_stream()
	else:
		_fire_projectile()
	var recoil_pitch: float = _get_effective_recoil_pitch()
	recoil_requested.emit(recoil_pitch, _get_effective_recoil_yaw(recoil_pitch), _get_effective_rearward_kick(recoil_pitch))
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
		var dropped_rounds: int = int(max(0, current_ammo - 1))
		if dropped_rounds > 0:
			_drop_partial_magazine(dropped_rounds)
		current_ammo = 1
		chamber_loaded = true
	is_reloading = true
	var handling: float = 1.0
	if owner_health:
		handling = owner_health.get_handling_modifier()
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
	var slot: String = _get_attachment_slot(attachment_id)
	if slot.is_empty():
		return ""
	attachments[slot] = attachment_id
	attachment_durability[attachment_id] = StationSystemsCatalog.get_weapon_attachment_durability(attachment_id)
	ammo_changed.emit(current_ammo, reserve_ammo)
	return StationSystemsCatalog.get_weapon_attachment_label(attachment_id)

func has_attachment(attachment_id: String) -> bool:
	return attachments.values().has(attachment_id)

func _finish_reload() -> void:
	var needed: int = _get_effective_magazine_size() - current_ammo
	var loaded: int = int(min(needed, reserve_ammo))
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
	var scene: Node = get_tree().current_scene
	if not scene:
		return
	var pickup: EquipmentPickup3D = EquipmentPickup3D.new()
	pickup.name = "DroppedPartialMagazine"
	pickup.configure_ammo(data.ammo_type, rounds)
	scene.add_child(pickup)
	var right: Vector3 = owner_body.global_transform.basis.x
	pickup.global_position = owner_body.global_position + right * 0.45 + Vector3(0.0, 0.35, 0.0)
	GameEvents.request_sound("mag_drop", pickup.global_position, 0.7)

func _apply_thermal_heat() -> void:
	if not data or data.weapon_family != "thermal":
		return
	thermal_heat = min(thermal_heat_ceiling, thermal_heat + 7.0 + data.fire_rate * 0.18)
	if thermal_heat >= 80.0 and owner_health:
		var burn_damage: float = 4.0
		if thermal_heat >= 100.0:
			burn_damage = 9.0
		owner_health.apply_damage(PlayerHealthBodyParts.PART_RIGHT_ARM, burn_damage, "burn")
		var burn_position: Vector3 = Vector3.ZERO
		if owner_body:
			burn_position = owner_body.global_position
		GameEvents.request_sound("hazard_steam", burn_position, 0.45)

func _fire_projectile() -> void:
	var direction: Vector3 = _get_barrel_direction()
	var projectile: BallisticProjectile = BallisticProjectile.new()
	var muzzle_origin: Vector3 = camera.global_position + direction * 0.55
	if muzzle:
		muzzle_origin = muzzle.global_position
	var scene: Node = get_tree().current_scene
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

func _fire_flame_stream() -> void:
	var direction: Vector3 = _get_barrel_direction()
	var origin: Vector3 = camera.global_position + direction * 0.55
	if muzzle:
		origin = muzzle.global_position
	var flame_range: float = clamp(data.muzzle_velocity * 0.09, 2.4, 5.2)
	var cone_width: float = 0.55 + data.spread_degrees * 0.16
	var damage_done: float = data.damage * 0.72
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not (enemy is Node3D):
			continue
		var enemy_node: Node3D = enemy as Node3D
		var to_enemy: Vector3 = enemy_node.global_position + Vector3.UP - origin
		var forward_distance: float = direction.dot(to_enemy)
		if forward_distance < 0.0 or forward_distance > flame_range:
			continue
		var closest: Vector3 = origin + direction * forward_distance
		var lateral_distance: float = closest.distance_to(enemy_node.global_position + Vector3.UP)
		var allowed_width: float = cone_width + forward_distance * 0.22
		if lateral_distance > allowed_width:
			continue
		var falloff: float = clamp(1.0 - forward_distance / flame_range, 0.22, 1.0)
		if enemy.has_method("receive_generic_hit"):
			enemy.receive_generic_hit(damage_done * falloff, closest, direction)
		if enemy.has_method("apply_shove"):
			enemy.apply_shove(origin, 1.6 * falloff, 0.05)
	GameEvents.emit_environment_impulse(origin + direction * (flame_range * 0.55), 1.4, 3.5, owner_body, "thermal_flame")
	_spawn_flame_visual(origin, direction, flame_range)

func _spawn_flame_visual(origin: Vector3, direction: Vector3, flame_range: float) -> void:
	var scene: Node = get_tree().current_scene
	if not scene:
		return
	for index in range(5):
		var puff: MeshInstance3D = MeshInstance3D.new()
		puff.name = "ThermalFlamePuff"
		var mesh: SphereMesh = SphereMesh.new()
		var t: float = float(index + 1) / 5.0
		mesh.radius = lerp(0.08, 0.32, t)
		mesh.height = mesh.radius * 1.6
		mesh.radial_segments = 12
		mesh.rings = 6
		puff.mesh = mesh
		puff.material_override = EffectMaterialCache.get_material(Color(1.0, lerp(0.72, 0.16, t), 0.04, 0.72), lerp(1.4, 0.55, t))
		scene.add_child(puff)
		puff.global_position = origin + direction * flame_range * t + Vector3(randf_range(-0.05, 0.05), randf_range(-0.035, 0.06), randf_range(-0.05, 0.05))
		var tween: Tween = puff.create_tween()
		tween.tween_property(puff, "scale", Vector3.ONE * 1.8, 0.12)
		tween.tween_property(puff, "transparency", 1.0, 0.08)
		tween.tween_callback(puff.queue_free)
	var light: OmniLight3D = OmniLight3D.new()
	light.name = "ThermalFlameLight"
	light.light_color = Color(1.0, 0.42, 0.08)
	light.light_energy = 2.8
	light.omni_range = 4.2
	scene.add_child(light)
	light.global_position = origin + direction * min(2.4, flame_range * 0.55)
	var light_tween: Tween = light.create_tween()
	light_tween.tween_property(light, "light_energy", 0.0, 0.14)
	light_tween.tween_callback(light.queue_free)

func _get_barrel_direction() -> Vector3:
	if muzzle:
		return (muzzle.global_transform.basis.z * -1.0).normalized()
	if camera:
		return (camera.global_transform.basis.z * -1.0).normalized()
	if owner_body:
		return (owner_body.global_transform.basis.z * -1.0).normalized()
	return Vector3.FORWARD

func get_ammo_display() -> String:
	var ammo_text: String = str(current_ammo)
	if mental:
		ammo_text = mental.get_display_ammo(current_ammo)
	return "%s / %d" % [ammo_text, reserve_ammo]

func get_manual_ammo_check() -> String:
	if current_ammo <= 0:
		return "MAG CHECK: chamber cold, magazine empty."
	var ratio: float = float(current_ammo) / float(max(1, _get_effective_magazine_size()))
	var chamber: String = "no chambered round"
	if chamber_loaded:
		chamber = "chambered"
	var tactile: String = "mag barely pulls"
	if ratio > 0.72:
		tactile = "mag tugs hard"
	elif ratio > 0.35:
		tactile = "mag has middle weight"
	var partial: String = ""
	if current_ammo < _get_effective_magazine_size() and current_ammo > 0:
		partial = " A partial magazine would feel uneven."
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
	var attachment_text: String = "no attachments"
	if not attachment_labels.is_empty():
		attachment_text = _join_labels(attachment_labels)
	var grip_text: String = "unknown grip"
	if owner_health:
		grip_text = owner_health.get_weapon_handling_state()
	var chamber_text: String = "chamber empty"
	if chamber_loaded:
		chamber_text = "chamber loaded"
	var heat_text: String = ""
	if data.weapon_family == "thermal":
		heat_text = "\nHeat %.0f%%" % thermal_heat
	return "%s\n%s / %s / %s\n%s\nCondition %.0f%%%s" % [data.weapon_name, data.weapon_family.to_upper(), data.ammo_type.replace("_", " "), chamber_text, attachment_text, weapon_condition * 100.0, heat_text] + "\n" + grip_text

func get_weapon_state() -> Dictionary:
	var weapon_id: String = "m7_colony_pistol"
	if data:
		weapon_id = data.weapon_id
	return {
		"weapon_id": weapon_id,
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
	var stored_attachments = {}
	var stored_attachments_value: Variant = state.get("attachments", {})
	if stored_attachments_value is Dictionary:
		stored_attachments = stored_attachments_value
	var stored_durability = {}
	var stored_durability_value: Variant = state.get("attachment_durability", {})
	if stored_durability_value is Dictionary:
		stored_durability = stored_durability_value
	for slot in stored_attachments.keys():
		var attachment_id: String = String(stored_attachments[slot])
		attachments[String(slot)] = attachment_id
		attachment_durability[attachment_id] = float(stored_durability.get(attachment_id, StationSystemsCatalog.get_weapon_attachment_durability(attachment_id)))
	ammo_changed.emit(current_ammo, reserve_ammo)
	condition_changed.emit(weapon_condition)

func degrade_from_drop(amount: float = 0.035) -> void:
	_degrade_condition(amount)

func _join_labels(labels: Array[String]) -> String:
	var text: String = ""
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
		var durability: float = float(attachment_durability.get("compact_suppressor", 1.0)) - (1.0 / 120.0)
		attachment_durability["compact_suppressor"] = durability
		if durability <= 0.0:
			_remove_attachment("compact_suppressor")
			var break_position: Vector3 = owner_body.global_position
			if muzzle:
				break_position = muzzle.global_position
			GameEvents.request_sound("mag_drop", break_position, 0.45)

func _remove_attachment(attachment_id: String) -> void:
	var slot_to_remove: String = ""
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
	var ping_position: Vector3 = owner_body.global_position
	if muzzle:
		ping_position = muzzle.global_position
	GameEvents.emit_player_noise(ping_position, 6.0)
	GameEvents.request_sound("telemetry_ping", ping_position, 0.22)

func _get_effective_recoil_pitch() -> float:
	var recoil: float = data.recoil_pitch
	if has_attachment("port_compensator"):
		recoil *= 0.72
	if has_attachment("foregrip"):
		recoil *= 0.82
	recoil *= lerp(1.25, 0.75, weapon_condition)
	if owner_health:
		recoil *= 1.0 + owner_health.pain / 140.0
		if owner_health.is_two_handed_compromised():
			recoil *= 1.35
	return recoil

func _get_effective_recoil_yaw(pitch_recoil: float) -> float:
	var family_bias: float = 0.14
	if data.weapon_family == "sidearm":
		family_bias = 0.22
	elif data.weapon_family == "smg":
		family_bias = 0.17
	elif data.weapon_family == "ar":
		family_bias = 0.11
	elif data.weapon_family == "lmg":
		family_bias = 0.06
	elif data.weapon_family == "thermal":
		family_bias = 0.03
	if owner_health and owner_health.is_two_handed_compromised():
		family_bias += 0.12
	if abs(barrel_push_side) > 0.01:
		family_bias += barrel_push_side * barrel_obstruction * 0.65
	return pitch_recoil * family_bias

func _get_effective_rearward_kick(pitch_recoil: float) -> float:
	var kick: float = clamp(pitch_recoil * 2.4, 0.018, 0.14)
	if data.weapon_family == "lmg":
		kick *= 1.25
	elif data.weapon_family == "thermal":
		kick *= 0.45
	if has_attachment("foregrip"):
		kick *= 0.85
	return kick

func _get_effective_magazine_size() -> int:
	var size: int = data.magazine_size
	if has_attachment("extended_magazine"):
		size += max(4, int(round(float(data.magazine_size) * 0.35)))
	return size

func _get_effective_reload_time() -> float:
	var reload: float = data.reload_time
	if has_attachment("extended_magazine"):
		reload *= 1.15
	if has_attachment("quickpull_magwell"):
		reload *= 0.82
	return reload

func _get_effective_loudness() -> float:
	var loudness: float = data.loudness
	if has_attachment("compact_suppressor"):
		loudness *= 0.58
	if has_attachment("port_compensator"):
		loudness *= 1.18
	return loudness

func _get_effective_velocity() -> float:
	var velocity: float = data.muzzle_velocity
	if has_attachment("compact_suppressor"):
		velocity *= 0.92
	return velocity

func _get_effective_spread_degrees() -> float:
	var spread: float = data.spread_degrees
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
