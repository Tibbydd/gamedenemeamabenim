extends CharacterBody3D
class_name EnemyBase3D

var target: PlayerControllerFPS
var health_zones: EnemyHealthHitZones
var senses: EnemySenses3D
var brain: EnemyDecisionStateMachine
var navigation_agent: NavigationAgent3D
var attack_range: float = 1.6
var attack_cooldown: float = 0.0
var attack_windup_timer: float = 0.0
var attack_recovery_timer: float = 0.0
var attack_damage_pending: bool = false
var queued_attack_zone: String = ""
var queued_attack_damage: float = 0.0
var queued_attack_type: String = "laceration"
var base_speed: float = 3.3
var attack_damage: float = 17.0
var body_radius: float = 0.35
var body_height: float = 1.45
var gravity: float = 18.0
var dead: bool = false
var archetype_id: String = "stalker_husk"
var archetype_label: String = "Stalker Husk"
var archetype_traits: Array = []
var stagger_timer: float = 0.0
var shove_velocity: Vector3 = Vector3.ZERO
var body_mesh: MeshInstance3D
var head_mesh: MeshInstance3D
var core_mesh: MeshInstance3D
var vocal_timer: float = 0.0
var dormant_awake: bool = true
var wander_timer: float = 0.0
var wander_target: Vector3 = Vector3.ZERO
var _group_alert_sent: bool = false

func _ready() -> void:
	add_to_group("enemies")
	gravity = ProjectSettings.get_setting("physics/3d/default_gravity", gravity)
	var archetype_definition := EnemyArchetypeCatalog.get_archetype(archetype_id)
	_apply_archetype_definition(archetype_definition)
	_build_physics_body()
	_build_visuals()
	navigation_agent = NavigationAgent3D.new()
	navigation_agent.name = "NavigationAgent3D"
	navigation_agent.path_desired_distance = 0.85
	navigation_agent.target_desired_distance = max(1.1, attack_range * 0.8)
	add_child(navigation_agent)
	health_zones = EnemyHealthHitZones.new()
	health_zones.name = "EnemyHealthHitZones"
	add_child(health_zones)
	health_zones.setup(self, archetype_definition)
	senses = EnemySenses3D.new()
	senses.name = "EnemySenses3D"
	add_child(senses)
	senses.setup(self)
	senses.sight_range = float(archetype_definition.get("sight", senses.sight_range))
	senses.hearing_sensitivity = float(archetype_definition.get("hearing", senses.hearing_sensitivity))
	brain = EnemyDecisionStateMachine.new()
	brain.name = "EnemyDecisionStateMachine"
	add_child(brain)
	if archetype_traits.has("dormant"):
		dormant_awake = false
		GameEvents.player_noise_made.connect(_on_noise_for_dormant)

func _apply_archetype_definition(definition: Dictionary) -> void:
	archetype_label = String(definition.get("label", archetype_label))
	base_speed = float(definition.get("speed", base_speed))
	attack_range = float(definition.get("attack_range", attack_range))
	attack_damage = float(definition.get("attack_damage", attack_damage))
	body_radius = float(definition.get("body_radius", body_radius))
	body_height = float(definition.get("body_height", body_height))
	var raw_traits: Variant = definition.get("traits")
	if raw_traits is Array:
		archetype_traits = raw_traits.duplicate(true)
	else:
		archetype_traits = []

func _on_noise_for_dormant(noise_position: Vector3, loudness: float) -> void:
	if dormant_awake:
		if not target and loudness >= 12.0 and global_position.distance_to(noise_position) <= loudness:
			_group_alert_sent = false
		return
	if not archetype_traits.has("dormant"):
		return
	if loudness >= 12.0 and global_position.distance_to(noise_position) <= loudness:
		dormant_awake = true
		GameEvents.request_sound("enemy_grunt", global_position, 0.9)

func set_target(new_target) -> void:
	var had_target: bool = target != null
	target = new_target
	if target and not had_target and not _group_alert_sent:
		_group_alert_sent = true
		_send_group_alert()
		GameEvents.request_sound("enemy_detect", global_position, randf_range(0.7, 1.1))
	elif not target:
		_group_alert_sent = false

func _physics_process(delta: float) -> void:
	if dead:
		return
	if not dormant_awake:
		velocity = Vector3.ZERO
		return
	if not target:
		_update_wander(delta)
		move_and_slide()
		return
	attack_cooldown = max(0.0, attack_cooldown - delta)
	vocal_timer = max(0.0, vocal_timer - delta)
	if stagger_timer > 0.0:
		stagger_timer -= delta
		velocity.x = shove_velocity.x
		velocity.z = shove_velocity.z
		shove_velocity = shove_velocity.move_toward(Vector3.ZERO, delta * 10.0)
		_apply_gravity(delta)
		move_and_slide()
		return
	senses.update_senses(target, delta)
	brain.update(self, senses, target, delta)
	_apply_trait_pressure(delta)
	_update_attack_sequence(delta)
	if brain.state == EnemyDecisionStateMachine.State.ATTACK:
		velocity.x = lerp(velocity.x, 0.0, delta * 8.0)
		velocity.z = lerp(velocity.z, 0.0, delta * 8.0)
		_start_attack()
	else:
		_move_toward(brain.desired_position, delta)
		_maybe_vocalize()
	_kick_nearby_dropped_weapons()
	_apply_gravity(delta)
	move_and_slide()

func _move_toward(world_position: Vector3, delta: float) -> void:
	if archetype_traits.has("immobile"):
		velocity.x = 0.0
		velocity.z = 0.0
		return
	navigation_agent.target_position = world_position
	var next_position := world_position
	if not navigation_agent.is_navigation_finished():
		var path_position := navigation_agent.get_next_path_position()
		if path_position.distance_squared_to(global_position) > 0.01:
			next_position = path_position
	var direction: Vector3 = next_position - global_position
	direction.y = 0.0
	if direction.length() < 0.15:
		velocity.x = lerp(velocity.x, 0.0, delta * 7.0)
		velocity.z = lerp(velocity.z, 0.0, delta * 7.0)
		return
	direction = direction.normalized()
	var speed: float = base_speed * health_zones.get_speed_modifier()
	var desired_velocity: Vector3 = direction * speed
	var steering: float = clamp(delta * 7.5, 0.0, 1.0)
	velocity.x = lerp(velocity.x, desired_velocity.x, steering)
	velocity.z = lerp(velocity.z, desired_velocity.z, steering)
	var facing_direction: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	if facing_direction.length_squared() > 0.01:
		look_at(global_position + facing_direction.normalized(), Vector3.UP)

func _update_wander(delta: float) -> void:
	if archetype_traits.has("immobile"):
		velocity.x = 0.0
		velocity.z = 0.0
		_apply_gravity(delta)
		return
	wander_timer -= delta
	if wander_timer <= 0.0:
		wander_timer = randf_range(3.0, 7.0)
		var offset: Vector3 = Vector3(randf_range(-10.0, 10.0), 0.0, randf_range(-10.0, 10.0))
		wander_target = global_position + offset
		if navigation_agent:
			navigation_agent.set_target_position(wander_target)
	if navigation_agent and not navigation_agent.is_navigation_finished():
		var next_position: Vector3 = navigation_agent.get_next_path_position()
		var direction: Vector3 = next_position - global_position
		direction.y = 0.0
		if direction.length() > 0.12:
			direction = direction.normalized()
			var desired_velocity: Vector3 = direction * (base_speed * health_zones.get_speed_modifier() * 0.4)
			var steering: float = clamp(delta * 4.0, 0.0, 1.0)
			velocity.x = lerp(velocity.x, desired_velocity.x, steering)
			velocity.z = lerp(velocity.z, desired_velocity.z, steering)
			look_at(global_position + direction, Vector3.UP)
		else:
			velocity.x = lerp(velocity.x, 0.0, delta * 5.0)
			velocity.z = lerp(velocity.z, 0.0, delta * 5.0)
	else:
		velocity.x = lerp(velocity.x, 0.0, delta * 4.0)
		velocity.z = lerp(velocity.z, 0.0, delta * 4.0)
	_apply_gravity(delta)

func _send_group_alert() -> void:
	for node in get_tree().get_nodes_in_group("enemies"):
		if not (node is EnemyBase3D) or node == self:
			continue
		var enemy: EnemyBase3D = node as EnemyBase3D
		if enemy.dead:
			continue
		if enemy.global_position.distance_to(global_position) > 9.0:
			continue
		enemy.dormant_awake = true
		if not enemy.target:
			enemy.target = target
			enemy._group_alert_sent = true

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = -0.05

func _start_attack() -> void:
	if attack_cooldown > 0.0 or not target:
		return
	if attack_windup_timer > 0.0 or attack_recovery_timer > 0.0 or attack_damage_pending:
		return
	if global_position.distance_to(target.global_position) > attack_range + 0.35:
		return
	var attack_modifier := health_zones.get_attack_modifier()
	var zone := _pick_player_hit_zone()
	var damage := randf_range(attack_damage * 0.8, attack_damage * 1.2) * attack_modifier
	var damage_type := "laceration"
	if archetype_traits.has("ranged_bleed"):
		damage_type = "bleed"
	GameEvents.emit_player_noise(global_position, 20.0)
	GameEvents.request_sound("enemy_windup", global_position, 0.55)
	queued_attack_zone = zone
	queued_attack_damage = damage
	queued_attack_type = damage_type
	attack_damage_pending = true
	attack_windup_timer = 0.32
	attack_recovery_timer = 0.0
	attack_cooldown = randf_range(1.05, 1.55) / max(0.35, attack_modifier)

func _update_attack_sequence(delta: float) -> void:
	if attack_windup_timer > 0.0:
		attack_windup_timer = max(0.0, attack_windup_timer - delta)
		_apply_attack_pose(1.0 - attack_windup_timer / 0.32)
		if attack_windup_timer <= 0.0 and attack_damage_pending:
			_resolve_attack_hit()
			attack_recovery_timer = 0.26
		return
	if attack_recovery_timer > 0.0:
		attack_recovery_timer = max(0.0, attack_recovery_timer - delta)
		_apply_attack_pose(attack_recovery_timer / 0.26)
		if attack_recovery_timer <= 0.0:
			_reset_attack_pose()

func _resolve_attack_hit() -> void:
	attack_damage_pending = false
	if not target or target.health.is_dead:
		return
	if global_position.distance_to(target.global_position) > attack_range + 0.55:
		GameEvents.request_sound("enemy_attack", global_position, 0.35)
		return
	target.health.apply_damage(queued_attack_zone, queued_attack_damage, queued_attack_type)
	target.mental.add_corruption(randf_range(6.0, 12.0), "contact")
	GameEvents.request_sound("enemy_attack", global_position, 0.9)

func _apply_attack_pose(phase: float) -> void:
	var windup: float = clamp(phase, 0.0, 1.0)
	if body_mesh:
		body_mesh.position.z = -0.08 * windup
		body_mesh.rotation_degrees.x = -8.0 + windup * 18.0
	if head_mesh:
		head_mesh.position.z = -0.02 - 0.12 * windup
	if core_mesh:
		core_mesh.scale = Vector3.ONE * (1.0 + 0.22 * windup)
	for child in get_children():
		if child is MeshInstance3D and String(child.name).find("Arm") >= 0:
			(child as MeshInstance3D).rotation_degrees.x = -24.0 - 42.0 * windup
		elif child is MeshInstance3D and String(child.name).find("Claw") >= 0:
			(child as MeshInstance3D).position.z = -0.24 - 0.28 * windup

func _reset_attack_pose() -> void:
	if body_mesh:
		body_mesh.position.z = 0.0
		body_mesh.rotation_degrees.x = 0.0
	if head_mesh:
		head_mesh.position.z = -0.02
	if core_mesh:
		core_mesh.scale = Vector3.ONE

func _maybe_vocalize() -> void:
	if vocal_timer > 0.0 or not brain:
		return
	var chance: float
	var sound_id: String
	match brain.state:
		EnemyDecisionStateMachine.State.CHASE, EnemyDecisionStateMachine.State.FLANK:
			chance = 0.038
			sound_id = _pick_chase_vocal()
		EnemyDecisionStateMachine.State.SEARCH:
			chance = 0.025
			sound_id = _pick_search_vocal()
		_:
			return
	if randf() < chance:
		GameEvents.request_sound(sound_id, global_position, randf_range(0.5, 0.9))
		vocal_timer = randf_range(2.2, 5.5)

func _pick_chase_vocal() -> String:
	match archetype_id:
		"howler":    return "enemy_alert"
		"choir":     return "enemy_alert"
		"bleeder":   return "enemy_grunt"
		"carapace":  return "enemy_grunt"
		"carrion_eater": return "enemy_grunt"
		_: return "enemy_grunt" if randf() < 0.65 else "enemy_alert"

func _pick_search_vocal() -> String:
	match archetype_id:
		"echo":         return "enemy_search"
		"glasswalker":  return "enemy_search"
		"relay_voice":  return "enemy_search"
		"mimic_prop":   return "enemy_search"
		_: return "enemy_search" if randf() < 0.6 else "enemy_grunt"

func _pick_player_hit_zone() -> String:
	if target and target.health and randf() < 0.28:
		var weak_zone := _pick_weakened_player_zone()
		if not weak_zone.is_empty():
			return weak_zone
	var zones := [
		PlayerHealthBodyParts.PART_LEFT_ARM,
		PlayerHealthBodyParts.PART_RIGHT_ARM,
		PlayerHealthBodyParts.PART_STOMACH,
		PlayerHealthBodyParts.PART_CHEST,
		PlayerHealthBodyParts.PART_LEFT_LEG,
		PlayerHealthBodyParts.PART_RIGHT_LEG
	]
	if randf() < 0.08:
		return PlayerHealthBodyParts.PART_HEAD
	return zones[randi() % zones.size()]

func _pick_weakened_player_zone() -> String:
	var candidates := [
		PlayerHealthBodyParts.PART_LEFT_ARM,
		PlayerHealthBodyParts.PART_RIGHT_ARM,
		PlayerHealthBodyParts.PART_LEFT_LEG,
		PlayerHealthBodyParts.PART_RIGHT_LEG,
		PlayerHealthBodyParts.PART_STOMACH
	]
	var lowest_zone := ""
	var lowest_ratio := 1.0
	for zone in candidates:
		var ratio := target.health.get_part_ratio(zone)
		if ratio < lowest_ratio:
			lowest_ratio = ratio
			lowest_zone = zone
	if lowest_ratio < 0.55:
		return lowest_zone
	return ""

func on_zone_damaged(zone_name: String, damage: float, hit_position: Vector3) -> void:
	_flash_hit(damage)
	_spawn_hit_particles(hit_position, damage)
	if core_mesh and zone_name == "parasite_core":
		core_mesh.scale = Vector3.ONE * 1.45
		GameEvents.emit_player_noise(hit_position, 12.0)
	if senses:
		if target:
			senses.last_known_position = target.global_position
		else:
			senses.last_known_position = global_position
		senses.has_last_known_position = true
	var hit_sound: String = "enemy_heavy_hit" if damage >= 28.0 else "enemy_hit"
	GameEvents.request_sound(hit_sound, hit_position, clamp(damage / 35.0, 0.5, 1.2))

func _flash_hit(damage: float = 10.0) -> void:
	var intensity: float = clamp(damage / 30.0, 0.5, 1.0)
	for child in get_children():
		if not (child is MeshInstance3D):
			continue
		var mesh: MeshInstance3D = child as MeshInstance3D
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.18, 0.04, 1.0)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.22, 0.04)
		mat.emission_energy_multiplier = 2.5 + intensity * 2.0
		mesh.set_surface_override_material(0, mat)
		var tween: Tween = create_tween()
		tween.tween_interval(0.07 + intensity * 0.04)
		tween.tween_callback(Callable(mesh, "set_surface_override_material").bind(0, null))
		break

func _spawn_hit_particles(hit_position: Vector3, damage: float) -> void:
	var scene := get_tree().current_scene
	if not scene:
		return
	var particles := CPUParticles3D.new()
	particles.name = "BloodHit"
	particles.one_shot = true
	particles.explosiveness = 0.92
	particles.amount = int(clamp(damage / 6.0, 4, 18))
	particles.lifetime = 0.55
	particles.emit_flags = CPUParticles3D.EMIT_FLAG_POSITION | CPUParticles3D.EMIT_FLAG_VELOCITY | CPUParticles3D.EMIT_FLAG_COLOR
	particles.direction = Vector3(0, 1, 0)
	particles.spread = 55.0
	particles.gravity = Vector3(0, -9.8, 0)
	particles.initial_velocity_min = 1.8
	particles.initial_velocity_max = 4.5
	particles.scale_amount_min = 0.025
	particles.scale_amount_max = 0.065
	particles.color = Color(0.62, 0.04, 0.04, 0.92)
	scene.add_child(particles)
	particles.global_position = hit_position
	particles.restart()
	var cleanup := particles.create_tween()
	cleanup.tween_interval(1.2)
	cleanup.tween_callback(particles.queue_free)

func receive_generic_hit(damage: float, hit_position: Vector3, hit_direction: Vector3) -> void:
	health_zones.receive_generic_hit(damage, hit_position, hit_direction)

func apply_shove(origin: Vector3, force: float, stun_duration: float) -> void:
	if dead:
		return
	var direction := global_position - origin
	direction.y = 0.0
	if direction.length() < 0.05:
		direction = -global_transform.basis.z
	direction = direction.normalized()
	shove_velocity = direction * force
	stagger_timer = max(stagger_timer, stun_duration)
	attack_cooldown = max(attack_cooldown, stun_duration)
	if senses and target:
		senses.last_known_position = target.global_position
		senses.has_last_known_position = true

func die(_cause: String) -> void:
	if dead:
		return
	dead = true
	if archetype_traits.has("death_noise"):
		GameEvents.emit_player_noise(global_position, 30.0)
		GameEvents.request_sound("howler_death", global_position, 1.0)
	else:
		GameEvents.request_sound("enemy_death", global_position, 0.8)
	# Stop all AI processing
	set_process(false)
	set_physics_process(false)
	if brain:
		brain.set_process(false)
	if navigation_agent:
		navigation_agent.set_process(false)
	# Remove hit zones and combat collision
	collision_layer = 0
	collision_mask = 1  # keep world collision so body rests on floor
	for child in get_children():
		if child is EnemyHitZone3D:
			child.collision_layer = 0
			child.collision_mask = 0
	# Death blood burst
	_spawn_death_particles()
	if archetype_traits.has("swarm"):
		var swarm_tween: Tween = create_tween()
		swarm_tween.tween_interval(2.0)
		swarm_tween.tween_property(self, "scale", Vector3.ZERO, 0.18)
		swarm_tween.tween_callback(Callable(self, "queue_free"))
		return
	# Mark as interactable corpse
	if not has_meta("display_name"):
		set_meta("display_name", "CORPSE — " + archetype_id.replace("_", " ").to_upper())
	# Animate collapse: tip over and settle on ground
	var fall_dir := randf_range(-1.0, 1.0)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "rotation_degrees:z",
		rotation_degrees.z + fall_dir * randf_range(72.0, 95.0), 0.28).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "position:y",
		position.y - 0.55, 0.28).set_ease(Tween.EASE_IN)
	# Darken all meshes to signal death state
	var death_tween := create_tween()
	death_tween.tween_interval(0.32)
	death_tween.tween_callback(Callable(self, "_apply_death_material"))

func revive_from_corpse() -> void:
	if not dead:
		return
	dead = false
	dormant_awake = true
	set_process(true)
	set_physics_process(true)
	collision_layer = 2
	collision_mask = 1
	rotation_degrees.z = 0.0
	position.y += 0.55
	remove_meta("display_name")
	if health_zones:
		health_zones.is_dead = false
		health_zones.health = max(1.0, health_zones.max_health * 0.25)
	if brain:
		brain.set_process(true)
	if navigation_agent:
		navigation_agent.set_process(true)
	if senses:
		senses.set_process(true)
	for child in get_children():
		if child is EnemyHitZone3D:
			var hit_zone: EnemyHitZone3D = child as EnemyHitZone3D
			hit_zone.collision_layer = 4
			hit_zone.collision_mask = 0
			hit_zone.monitoring = true
			hit_zone.monitorable = true
	GameEvents.request_sound("enemy_grunt", global_position, 0.85)

func _build_physics_body() -> void:
	collision_layer = 2
	collision_mask = 1
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = body_radius
	shape.height = body_height
	collision.shape = shape
	collision.position.y = body_height * 0.5 + body_radius * 0.15
	add_child(collision)

func _build_visuals() -> void:
	var arch_def: Dictionary = EnemyArchetypeCatalog.get_archetype(archetype_id)
	var color := Color(0.22, 0.25, 0.28)
	var raw_color: Variant = arch_def.get("color")
	if raw_color is Color:
		color = raw_color
	if archetype_traits.has("swarm"):
		_build_swarmer_visuals(color)
		return
	body_mesh = _add_visual_capsule("EnemyTorso", 0.31, 1.08, Vector3(0.0, 1.02, 0.0), color, 0.0)
	_add_visual_capsule("EnemyAbdomen", 0.24, 0.48, Vector3(0.0, 0.64, 0.02), color.darkened(0.18), 0.0)
	_add_visual_box("EnemyShoulderLine", Vector3(0.82, 0.16, 0.24), Vector3(0.0, 1.36, 0.0), color.lightened(0.08), 0.0)
	head_mesh = _add_visual_sphere("EnemyHead", 0.24, Vector3(0.0, 1.74, -0.02), Color(0.5, 0.58, 0.62), 0.0)
	_add_visual_box("EnemyJaw", Vector3(0.24, 0.08, 0.16), Vector3(0.0, 1.58, -0.13), Color(0.3, 0.35, 0.36), 0.0)
	_add_visual_box("EnemyEyeGlowLeft", Vector3(0.055, 0.035, 0.018), Vector3(-0.075, 1.76, -0.235), Color(0.1, 0.95, 0.78), 0.55)
	_add_visual_box("EnemyEyeGlowRight", Vector3(0.055, 0.035, 0.018), Vector3(0.075, 1.76, -0.235), Color(0.1, 0.95, 0.78), 0.55)
	_add_visual_capsule("EnemyLeftUpperArm", 0.075, 0.58, Vector3(-0.47, 1.12, -0.02), color.darkened(0.08), 0.0, Vector3(0.0, 0.0, -12.0))
	_add_visual_capsule("EnemyRightUpperArm", 0.075, 0.58, Vector3(0.47, 1.12, -0.02), color.darkened(0.08), 0.0, Vector3(0.0, 0.0, 12.0))
	_add_visual_capsule("EnemyLeftForearm", 0.065, 0.54, Vector3(-0.56, 0.75, -0.12), color.darkened(0.16), 0.0, Vector3(-24.0, 0.0, -4.0))
	_add_visual_capsule("EnemyRightForearm", 0.065, 0.54, Vector3(0.56, 0.75, -0.12), color.darkened(0.16), 0.0, Vector3(-24.0, 0.0, 4.0))
	_add_visual_sphere("EnemyLeftClaw", 0.095, Vector3(-0.58, 0.45, -0.24), Color(0.18, 0.2, 0.21), 0.0)
	_add_visual_sphere("EnemyRightClaw", 0.095, Vector3(0.58, 0.45, -0.24), Color(0.18, 0.2, 0.21), 0.0)
	_add_visual_capsule("EnemyLeftLeg", 0.095, 0.78, Vector3(-0.18, 0.34, 0.02), color.darkened(0.14), 0.0)
	_add_visual_capsule("EnemyRightLeg", 0.095, 0.78, Vector3(0.18, 0.34, 0.02), color.darkened(0.14), 0.0)
	_add_visual_box("EnemyLeftFoot", Vector3(0.2, 0.08, 0.34), Vector3(-0.18, 0.05, -0.08), Color(0.11, 0.12, 0.12), 0.0)
	_add_visual_box("EnemyRightFoot", Vector3(0.2, 0.08, 0.34), Vector3(0.18, 0.05, -0.08), Color(0.11, 0.12, 0.12), 0.0)
	core_mesh = _add_visual_sphere("ParasiteCore", 0.18, Vector3(0, 1.12, -0.34), Color(0.2, 1.0, 0.82), 0.8)
	_add_archetype_visual_marks(color)
	if archetype_traits.has("crawler_husk") or archetype_id == "crawler_husk":
		scale = Vector3(1.0, 0.55, 1.15)
	elif archetype_traits.has("immobile"):
		scale = Vector3(1.45, 1.2, 1.45)

func _build_swarmer_visuals(color: Color) -> void:
	body_mesh = _add_visual_capsule("SwarmerBody", 0.18, 0.55, Vector3(0.0, 0.38, 0.0), color, 0.0, Vector3(90.0, 0.0, 0.0))
	head_mesh = _add_visual_sphere("SwarmerHead", 0.13, Vector3(0.0, 0.44, -0.24), color.lightened(0.16), 0.0)
	core_mesh = _add_visual_sphere("SwarmerCore", 0.075, Vector3(0.0, 0.42, -0.36), Color(0.4, 1.0, 0.22), 0.7)
	_add_visual_box("SwarmerEyeLeft", Vector3(0.035, 0.022, 0.018), Vector3(-0.045, 0.48, -0.36), Color(0.82, 1.0, 0.36), 0.45)
	_add_visual_box("SwarmerEyeRight", Vector3(0.035, 0.022, 0.018), Vector3(0.045, 0.48, -0.36), Color(0.82, 1.0, 0.36), 0.45)
	for index in range(4):
		var side: float = -1.0 if index < 2 else 1.0
		var z_offset: float = -0.08 + float(index % 2) * 0.22
		_add_visual_capsule("SwarmerLeg%d" % index, 0.025, 0.42, Vector3(side * 0.2, 0.22, z_offset), color.darkened(0.28), 0.0, Vector3(72.0, 0.0, side * 35.0))

func _add_archetype_visual_marks(base_color: Color) -> void:
	match archetype_id:
		"stalker_husk":
			_add_visual_cylinder("StalkerSpineUpper", 0.035, 0.32, Vector3(0.0, 1.48, 0.14), Color(0.08, 0.14, 0.18), 0.14, Vector3(32.0, 0.0, 0.0))
			_add_visual_cylinder("StalkerSpineLower", 0.030, 0.26, Vector3(0.0, 1.18, 0.16), Color(0.08, 0.14, 0.18), 0.10, Vector3(28.0, 0.0, 0.0))
			_add_visual_box("StalkerRidgeL", Vector3(0.055, 0.28, 0.04), Vector3(-0.34, 1.42, 0.10), Color(0.08, 0.12, 0.20), 0.08)
			_add_visual_box("StalkerRidgeR", Vector3(0.055, 0.28, 0.04), Vector3(0.34, 1.42, 0.10), Color(0.08, 0.12, 0.20), 0.08)
		"crawler_husk":
			_add_visual_capsule("CrawlerLongLeftArm", 0.055, 0.72, Vector3(-0.68, 0.60, -0.18), base_color.darkened(0.18), 0.0, Vector3(-58.0, 0.0, -18.0))
			_add_visual_capsule("CrawlerLongRightArm", 0.055, 0.72, Vector3(0.68, 0.60, -0.18), base_color.darkened(0.18), 0.0, Vector3(-58.0, 0.0, 18.0))
			_add_visual_sphere("CrawlerKneeL", 0.08, Vector3(-0.14, 0.28, 0.06), Color(0.10, 0.24, 0.16), 0.0)
			_add_visual_sphere("CrawlerKneeR", 0.08, Vector3(0.14, 0.28, 0.06), Color(0.10, 0.24, 0.16), 0.0)
		"bleeder":
			_add_visual_sphere("BleederSacLeft", 0.18, Vector3(-0.24, 1.05, -0.30), Color(0.72, 0.06, 0.08), 0.22)
			_add_visual_sphere("BleederSacRight", 0.15, Vector3(0.22, 0.88, -0.31), Color(0.62, 0.04, 0.06), 0.16)
			_add_visual_sphere("BleederSacMid", 0.12, Vector3(0.0, 1.22, -0.32), Color(0.58, 0.08, 0.08), 0.12)
			_add_visual_box("BleederVeinA", Vector3(0.012, 0.36, 0.012), Vector3(-0.28, 0.95, -0.26), Color(0.78, 0.04, 0.04), 0.18)
			_add_visual_box("BleederVeinB", Vector3(0.012, 0.28, 0.012), Vector3(0.24, 0.82, -0.28), Color(0.68, 0.04, 0.04), 0.14)
		"carapace":
			for i in range(3):
				_add_visual_box("CarapacePlate%d" % i, Vector3(0.50 - i * 0.06, 0.06, 0.20), Vector3(0.0, 1.24 - i * 0.18, -0.30), base_color.lightened(0.26), 0.0, Vector3(12.0, 0.0, 0.0))
			_add_visual_box("CarapaceShoulderL", Vector3(0.22, 0.06, 0.18), Vector3(-0.52, 1.35, -0.06), base_color.lightened(0.20), 0.0, Vector3(0.0, -22.0, 18.0))
			_add_visual_box("CarapaceShoulderR", Vector3(0.22, 0.06, 0.18), Vector3(0.52, 1.35, -0.06), base_color.lightened(0.20), 0.0, Vector3(0.0, 22.0, -18.0))
		"echo":
			_add_visual_sphere("EchoGhostAuraL", 0.22, Vector3(-0.20, 1.65, -0.02), Color(0.04, 0.12, 0.60), 0.55)
			_add_visual_sphere("EchoGhostAuraR", 0.18, Vector3(0.22, 1.58, -0.04), Color(0.04, 0.10, 0.52), 0.45)
			_add_visual_box("EchoEyeL", Vector3(0.055, 0.035, 0.018), Vector3(-0.075, 1.76, -0.235), Color(0.08, 0.18, 0.92), 1.1)
			_add_visual_box("EchoEyeR", Vector3(0.055, 0.035, 0.018), Vector3(0.075, 1.76, -0.235), Color(0.08, 0.18, 0.92), 1.1)
		"howler":
			_add_visual_box("HowlerJawLower", Vector3(0.26, 0.10, 0.20), Vector3(0.0, 1.52, -0.18), Color(0.62, 0.22, 0.04), 0.0, Vector3(-22.0, 0.0, 0.0))
			_add_visual_box("HowlerFangL", Vector3(0.04, 0.12, 0.04), Vector3(-0.06, 1.47, -0.24), Color(0.88, 0.82, 0.72), 0.0)
			_add_visual_box("HowlerFangR", Vector3(0.04, 0.12, 0.04), Vector3(0.06, 1.47, -0.24), Color(0.88, 0.82, 0.72), 0.0)
			_add_visual_cylinder("HowlerNeckFrillL", 0.025, 0.28, Vector3(-0.22, 1.62, 0.04), Color(0.62, 0.24, 0.04), 0.08, Vector3(18.0, 0.0, -28.0))
			_add_visual_cylinder("HowlerNeckFrillR", 0.025, 0.28, Vector3(0.22, 1.62, 0.04), Color(0.62, 0.24, 0.04), 0.08, Vector3(18.0, 0.0, 28.0))
		"sleeper_pod":
			_add_visual_sphere("SleeperBlobA", 0.28, Vector3(-0.12, 0.92, -0.14), Color(0.32, 0.06, 0.48), 0.14)
			_add_visual_sphere("SleeperBlobB", 0.22, Vector3(0.14, 1.18, -0.10), Color(0.24, 0.04, 0.38), 0.10)
			_add_visual_capsule("SleeperTendrilA", 0.028, 0.42, Vector3(-0.38, 0.85, 0.08), Color(0.28, 0.06, 0.40), 0.12, Vector3(-30.0, 0.0, -40.0))
			_add_visual_capsule("SleeperTendrilB", 0.024, 0.38, Vector3(0.36, 0.78, 0.06), Color(0.22, 0.04, 0.34), 0.10, Vector3(-28.0, 0.0, 42.0))
		"stalker_twin":
			_add_visual_box("TwinStripeSpineL", Vector3(0.045, 0.72, 0.035), Vector3(-0.30, 1.22, 0.08), Color(0.58, 0.08, 0.72), 0.22)
			_add_visual_box("TwinStripeSpineR", Vector3(0.045, 0.72, 0.035), Vector3(0.30, 1.22, 0.08), Color(0.58, 0.08, 0.72), 0.22)
			_add_visual_sphere("TwinMarkHead", 0.055, Vector3(0.0, 1.90, -0.06), Color(0.72, 0.08, 0.88), 0.45)
		"glasswalker":
			_add_visual_capsule("GlassFingerL1", 0.025, 0.32, Vector3(-0.64, 0.36, -0.28), Color(0.14, 0.52, 0.72), 0.18, Vector3(-72.0, 0.0, -8.0))
			_add_visual_capsule("GlassFingerL2", 0.022, 0.28, Vector3(-0.68, 0.32, -0.20), Color(0.12, 0.46, 0.68), 0.14, Vector3(-68.0, 12.0, -12.0))
			_add_visual_capsule("GlassFingerR1", 0.025, 0.32, Vector3(0.64, 0.36, -0.28), Color(0.14, 0.52, 0.72), 0.18, Vector3(-72.0, 0.0, 8.0))
			_add_visual_capsule("GlassFingerR2", 0.022, 0.28, Vector3(0.68, 0.32, -0.20), Color(0.12, 0.46, 0.68), 0.14, Vector3(-68.0, -12.0, 12.0))
			_add_visual_box("GlassEyeL", Vector3(0.055, 0.035, 0.018), Vector3(-0.075, 1.76, -0.235), Color(0.08, 0.82, 1.0), 1.2)
			_add_visual_box("GlassEyeR", Vector3(0.055, 0.035, 0.018), Vector3(0.075, 1.76, -0.235), Color(0.08, 0.82, 1.0), 1.2)
		"surgeon":
			_add_visual_box("SurgeonApron", Vector3(0.68, 0.78, 0.06), Vector3(0.0, 0.96, -0.30), Color(0.72, 0.70, 0.64), 0.0)
			_add_visual_capsule("SurgeonToolL", 0.018, 0.52, Vector3(-0.54, 0.55, -0.28), Color(0.72, 0.72, 0.68), 0.0, Vector3(-62.0, 0.0, -12.0))
			_add_visual_capsule("SurgeonToolR", 0.018, 0.52, Vector3(0.54, 0.55, -0.28), Color(0.72, 0.72, 0.68), 0.0, Vector3(-62.0, 0.0, 12.0))
			_add_visual_sphere("SurgeonMaskGlass", 0.22, Vector3(0.0, 1.74, -0.04), Color(0.78, 0.82, 0.84), 0.08)
		"choir":
			_add_visual_sphere("ChoirVoiceL", 0.18, Vector3(-0.44, 1.52, -0.06), Color(0.52, 0.04, 0.82), 0.52)
			_add_visual_sphere("ChoirVoiceR", 0.16, Vector3(0.42, 1.58, -0.06), Color(0.48, 0.04, 0.76), 0.44)
			_add_visual_sphere("ChoirVoiceTop", 0.14, Vector3(0.0, 1.92, 0.06), Color(0.58, 0.06, 0.88), 0.60)
			_add_visual_box("ChoirEyeL", Vector3(0.055, 0.035, 0.018), Vector3(-0.075, 1.76, -0.235), Color(0.82, 0.06, 1.0), 1.4)
			_add_visual_box("ChoirEyeR", Vector3(0.055, 0.035, 0.018), Vector3(0.075, 1.76, -0.235), Color(0.82, 0.06, 1.0), 1.4)
		"shellroot":
			_add_visual_capsule("ShellRootA", 0.042, 0.58, Vector3(-0.52, -0.04, 0.06), Color(0.10, 0.22, 0.08), 0.0, Vector3(55.0, 0.0, -28.0))
			_add_visual_capsule("ShellRootB", 0.038, 0.52, Vector3(0.50, -0.04, 0.08), Color(0.08, 0.20, 0.08), 0.0, Vector3(55.0, 0.0, 28.0))
			_add_visual_capsule("ShellRootC", 0.036, 0.48, Vector3(0.0, -0.06, 0.38), Color(0.10, 0.20, 0.06), 0.0, Vector3(72.0, 0.0, 0.0))
			for i in range(4):
				_add_visual_box("ShellPlate%d" % i, Vector3(0.48, 0.055, 0.22), Vector3(0.0, 1.28 - i * 0.22, -0.31), base_color.lightened(0.28), 0.0, Vector3(10.0, 0.0, 0.0))
		"relay_voice":
			_add_visual_cylinder("RelayAntennaL", 0.020, 0.52, Vector3(-0.14, 2.10, 0.04), Color(0.22, 0.18, 0.72), 0.28, Vector3(-12.0, 0.0, -14.0))
			_add_visual_cylinder("RelayAntennaR", 0.020, 0.48, Vector3(0.14, 2.04, 0.06), Color(0.20, 0.16, 0.66), 0.24, Vector3(-10.0, 0.0, 16.0))
			_add_visual_sphere("RelayTransmitterL", 0.045, Vector3(-0.20, 2.36, 0.0), Color(0.18, 0.08, 0.88), 0.72)
			_add_visual_sphere("RelayTransmitterR", 0.040, Vector3(0.20, 2.30, 0.0), Color(0.18, 0.08, 0.88), 0.64)
			_add_visual_box("RelayEyeL", Vector3(0.055, 0.035, 0.018), Vector3(-0.075, 1.76, -0.235), Color(0.22, 0.08, 1.0), 1.0)
			_add_visual_box("RelayEyeR", Vector3(0.055, 0.035, 0.018), Vector3(0.075, 1.76, -0.235), Color(0.22, 0.08, 1.0), 1.0)
		"mimic_prop":
			# Intentionally plain — it looks like furniture until it moves
			_add_visual_box("MimicSeam", Vector3(0.70, 0.005, 0.30), Vector3(0.0, 1.06, -0.28), Color(0.28, 0.22, 0.14), 0.0)
		"door_closer":
			_add_visual_capsule("CloserArmL", 0.065, 0.82, Vector3(-0.52, 1.22, -0.06), Color(0.38, 0.14, 0.12), 0.0, Vector3(-14.0, 0.0, -18.0))
			_add_visual_capsule("CloserArmR", 0.065, 0.82, Vector3(0.52, 1.22, -0.06), Color(0.38, 0.14, 0.12), 0.0, Vector3(-14.0, 0.0, 18.0))
			_add_visual_box("CloserGripL", Vector3(0.16, 0.08, 0.10), Vector3(-0.62, 0.72, -0.22), Color(0.24, 0.10, 0.10), 0.0)
			_add_visual_box("CloserGripR", Vector3(0.16, 0.08, 0.10), Vector3(0.62, 0.72, -0.22), Color(0.24, 0.10, 0.10), 0.0)
		"carrion_eater":
			_add_visual_box("CarrionMandibleL", Vector3(0.06, 0.06, 0.38), Vector3(-0.12, 1.54, -0.28), Color(0.52, 0.38, 0.04), 0.0, Vector3(12.0, -22.0, 0.0))
			_add_visual_box("CarrionMandibleR", Vector3(0.06, 0.06, 0.38), Vector3(0.12, 1.54, -0.28), Color(0.52, 0.38, 0.04), 0.0, Vector3(12.0, 22.0, 0.0))
			_add_visual_sphere("CarrionGulletSac", 0.18, Vector3(0.0, 0.78, -0.30), Color(0.48, 0.36, 0.04), 0.08)
			_add_visual_box("CarrionEyeL", Vector3(0.055, 0.035, 0.018), Vector3(-0.075, 1.76, -0.235), Color(0.82, 0.66, 0.04), 0.72)
			_add_visual_box("CarrionEyeR", Vector3(0.055, 0.035, 0.018), Vector3(0.075, 1.76, -0.235), Color(0.82, 0.66, 0.04), 0.72)

func _add_visual_box(mesh_name: String, size: Vector3, position: Vector3, color: Color, emission_energy: float = 0.0, rotation_degrees_value: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = mesh_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = position
	mesh_instance.rotation_degrees = rotation_degrees_value
	mesh_instance.material_override = _make_material(color, emission_energy)
	add_child(mesh_instance)
	return mesh_instance

func _add_visual_capsule(mesh_name: String, radius: float, height: float, position: Vector3, color: Color, emission_energy: float = 0.0, rotation_degrees_value: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = mesh_name
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 14
	mesh.rings = 6
	mesh_instance.mesh = mesh
	mesh_instance.position = position
	mesh_instance.rotation_degrees = rotation_degrees_value
	mesh_instance.material_override = _make_material(color, emission_energy)
	add_child(mesh_instance)
	return mesh_instance

func _add_visual_sphere(mesh_name: String, radius: float, position: Vector3, color: Color, emission_energy: float = 0.0) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = mesh_name
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 18
	mesh.rings = 9
	mesh_instance.mesh = mesh
	mesh_instance.position = position
	mesh_instance.material_override = _make_material(color, emission_energy)
	add_child(mesh_instance)
	return mesh_instance

func _add_visual_cylinder(mesh_name: String, radius: float, height: float, position: Vector3, color: Color, emission_energy: float = 0.0, rotation_degrees_value: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = mesh_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	mesh_instance.mesh = mesh
	mesh_instance.position = position
	mesh_instance.rotation_degrees = rotation_degrees_value
	mesh_instance.material_override = _make_material(color, emission_energy)
	add_child(mesh_instance)
	return mesh_instance

func _apply_trait_pressure(delta: float) -> void:
	if archetype_traits.has("immobile"):
		velocity.x = 0.0
		velocity.z = 0.0
	if archetype_traits.has("corruption_aura") and target:
		if global_position.distance_to(target.global_position) <= 6.0:
			target.mental.add_corruption(1.5 * delta, "aura")
	if archetype_traits.has("kit_hunter"):
		_hunt_lost_kit()

func _hunt_lost_kit() -> void:
	var nearest: LostSurvivorKit3D = null
	var nearest_distance := 9999.0
	var kit_distance := 0.0
	for kit in get_tree().get_nodes_in_group("lost_survivor_kits"):
		if not (kit is LostSurvivorKit3D):
			continue
		var kit_node := kit as Node3D
		kit_distance = global_position.distance_to(kit_node.global_position)
		if kit_distance < nearest_distance:
			nearest_distance = kit_distance
			nearest = kit
	if not nearest:
		return
	if nearest_distance <= 1.2:
		nearest.consume_by_enemy(self)
		attack_cooldown = max(attack_cooldown, 1.5)
	elif brain and (not target or nearest_distance < global_position.distance_to(target.global_position)):
		brain.desired_position = nearest.global_position

func _kick_nearby_dropped_weapons() -> void:
	for pickup in get_tree().get_nodes_in_group("dropped_weapons"):
		if not (pickup is RigidBody3D) or not (pickup is Node3D):
			continue
		var pickup_node := pickup as Node3D
		if pickup_node.global_position.distance_to(global_position) > 0.85:
			continue
		var direction := (pickup_node.global_position - global_position)
		direction.y = 0.0
		if direction.length() < 0.05:
			direction = global_transform.basis.x
		var pickup_body := pickup as RigidBody3D
		pickup_body.apply_central_impulse(direction.normalized() * 3.5 + Vector3.UP * 0.6)
		GameEvents.request_sound("mag_drop", pickup_node.global_position, 0.35)

func _make_material(color: Color, emission_energy: float) -> StandardMaterial3D:
	return EffectMaterialCache.get_material(color, emission_energy)

func _spawn_death_particles() -> void:
	var scene := get_tree().current_scene
	if not scene:
		return
	var burst := CPUParticles3D.new()
	burst.name = "DeathBlood"
	burst.one_shot = true
	burst.explosiveness = 0.95
	burst.amount = 28
	burst.lifetime = 0.8
	burst.direction = Vector3(0, 1, 0)
	burst.spread = 75.0
	burst.gravity = Vector3(0, -12.0, 0)
	burst.initial_velocity_min = 2.5
	burst.initial_velocity_max = 7.0
	burst.scale_amount_min = 0.03
	burst.scale_amount_max = 0.09
	burst.color = Color(0.58, 0.02, 0.02, 0.88)
	scene.add_child(burst)
	burst.global_position = global_position + Vector3.UP * 1.0
	burst.restart()
	var cleanup := burst.create_tween()
	cleanup.tween_interval(1.6)
	cleanup.tween_callback(burst.queue_free)

func _apply_death_material() -> void:
	var death_mat := StandardMaterial3D.new()
	death_mat.albedo_color = Color(0.08, 0.07, 0.065, 1.0)
	death_mat.roughness = 0.95
	for child in get_children():
		if child is MeshInstance3D:
			(child as MeshInstance3D).material_override = death_mat
