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
	var raw_traits: Variant = definition.get("traits")
	if raw_traits is Array:
		archetype_traits = raw_traits.duplicate(true)
	else:
		archetype_traits = []

func _on_noise_for_dormant(noise_position: Vector3, loudness: float) -> void:
	if dormant_awake or not archetype_traits.has("dormant"):
		return
	if loudness >= 16.0 and global_position.distance_to(noise_position) <= loudness:
		dormant_awake = true
		GameEvents.request_sound("enemy_grunt", global_position, 0.9)

func set_target(new_target) -> void:
	target = new_target

func _physics_process(delta: float) -> void:
	if dead:
		return
	if not dormant_awake:
		velocity = Vector3.ZERO
		return
	if not target:
		_apply_gravity(delta)
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
	var damage := randf_range(12.0, 22.0) * attack_modifier
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
	if brain.state == EnemyDecisionStateMachine.State.CHASE or brain.state == EnemyDecisionStateMachine.State.FLANK or brain.state == EnemyDecisionStateMachine.State.SEARCH:
		if randf() < 0.035:
			GameEvents.request_sound("enemy_grunt", global_position, 0.55)
			vocal_timer = randf_range(2.5, 5.0)

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

func on_zone_damaged(zone_name: String, _damage: float, hit_position: Vector3) -> void:
	if core_mesh and zone_name == "parasite_core":
		core_mesh.scale = Vector3.ONE * 1.45
		GameEvents.emit_player_noise(hit_position, 12.0)
	if senses:
		if target:
			senses.last_known_position = target.global_position
		else:
			senses.last_known_position = global_position
		senses.has_last_known_position = true

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
	collision_layer = 0
	collision_mask = 0
	for child in get_children():
		if child is EnemyHitZone3D:
			child.collision_layer = 0
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3(1.0, 0.08, 1.0), 0.25)
	tween.tween_callback(queue_free)

func _build_physics_body() -> void:
	collision_layer = 2
	collision_mask = 1
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.35
	shape.height = 1.45
	collision.shape = shape
	collision.position.y = 0.85
	add_child(collision)

func _build_visuals() -> void:
	var arch_def: Dictionary = EnemyArchetypeCatalog.get_archetype(archetype_id)
	var color := Color(0.22, 0.25, 0.28)
	var raw_color: Variant = arch_def.get("color")
	if raw_color is Color:
		color = raw_color
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

func _add_archetype_visual_marks(base_color: Color) -> void:
	if archetype_id == "carapace":
		for index in range(3):
			_add_visual_box("CarapacePlate%d" % index, Vector3(0.5 - index * 0.06, 0.055, 0.18), Vector3(0.0, 1.24 - index * 0.18, -0.29), base_color.lightened(0.22), 0.0, Vector3(12.0, 0.0, 0.0))
	elif archetype_id == "bleeder":
		_add_visual_sphere("BleederSacLeft", 0.16, Vector3(-0.23, 1.05, -0.29), Color(0.62, 0.08, 0.08), 0.18)
		_add_visual_sphere("BleederSacRight", 0.14, Vector3(0.22, 0.88, -0.3), Color(0.52, 0.05, 0.06), 0.12)
	elif archetype_id == "crawler_husk":
		_add_visual_capsule("CrawlerLongLeftArm", 0.055, 0.7, Vector3(-0.68, 0.62, -0.18), base_color.darkened(0.18), 0.0, Vector3(-58.0, 0.0, -18.0))
		_add_visual_capsule("CrawlerLongRightArm", 0.055, 0.7, Vector3(0.68, 0.62, -0.18), base_color.darkened(0.18), 0.0, Vector3(-58.0, 0.0, 18.0))
	elif archetype_id == "stalker_husk":
		_add_visual_cylinder("StalkerSpineUpper", 0.035, 0.32, Vector3(0.0, 1.48, 0.14), Color(0.1, 0.16, 0.16), 0.12, Vector3(32.0, 0.0, 0.0))
		_add_visual_cylinder("StalkerSpineLower", 0.03, 0.26, Vector3(0.0, 1.18, 0.16), Color(0.1, 0.16, 0.16), 0.08, Vector3(28.0, 0.0, 0.0))

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
