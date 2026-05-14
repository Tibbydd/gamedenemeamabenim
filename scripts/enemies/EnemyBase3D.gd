extends CharacterBody3D
class_name EnemyBase3D

var target: PlayerControllerFPS
var health_zones: EnemyHealthHitZones
var senses: EnemySenses3D
var brain: EnemyDecisionStateMachine
var navigation_agent: NavigationAgent3D
var attack_range: float = 1.6
var attack_cooldown: float = 0.0
var base_speed: float = 3.3
var dead: bool = false
var stagger_timer: float = 0.0
var shove_velocity: Vector3 = Vector3.ZERO
var body_mesh: MeshInstance3D
var head_mesh: MeshInstance3D
var core_mesh: MeshInstance3D

func _ready() -> void:
	add_to_group("enemies")
	_build_physics_body()
	_build_visuals()
	navigation_agent = NavigationAgent3D.new()
	navigation_agent.name = "NavigationAgent3D"
	navigation_agent.path_desired_distance = 0.35
	navigation_agent.target_desired_distance = 0.8
	add_child(navigation_agent)
	health_zones = EnemyHealthHitZones.new()
	health_zones.name = "EnemyHealthHitZones"
	add_child(health_zones)
	health_zones.setup(self)
	senses = EnemySenses3D.new()
	senses.name = "EnemySenses3D"
	add_child(senses)
	senses.setup(self)
	brain = EnemyDecisionStateMachine.new()
	brain.name = "EnemyDecisionStateMachine"
	add_child(brain)

func set_target(new_target) -> void:
	target = new_target

func _physics_process(delta: float) -> void:
	if dead or not target:
		return
	attack_cooldown = max(0.0, attack_cooldown - delta)
	if stagger_timer > 0.0:
		stagger_timer -= delta
		velocity = shove_velocity
		shove_velocity = shove_velocity.move_toward(Vector3.ZERO, delta * 10.0)
		move_and_slide()
		return
	senses.update_senses(target, delta)
	brain.update(self, senses, target, delta)
	if brain.state == EnemyDecisionStateMachine.State.ATTACK:
		velocity = velocity.lerp(Vector3.ZERO, delta * 8.0)
		_try_attack()
	else:
		_move_toward(brain.desired_position, delta)
	move_and_slide()

func _move_toward(world_position: Vector3, delta: float) -> void:
	navigation_agent.target_position = world_position
	var next_position := world_position
	var direction := next_position - global_position
	direction.y = 0.0
	if direction.length() < 0.15:
		velocity.x = lerp(velocity.x, 0.0, delta * 7.0)
		velocity.z = lerp(velocity.z, 0.0, delta * 7.0)
		return
	direction = direction.normalized()
	var speed := base_speed * health_zones.get_speed_modifier()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	look_at(global_position + direction, Vector3.UP)

func _try_attack() -> void:
	if attack_cooldown > 0.0 or not target:
		return
	if global_position.distance_to(target.global_position) > attack_range + 0.35:
		return
	var attack_modifier := health_zones.get_attack_modifier()
	var zone := _pick_player_hit_zone()
	var damage := randf_range(12.0, 22.0) * attack_modifier
	target.health.apply_damage(zone, damage, "laceration")
	target.mental.add_corruption(randf_range(6.0, 12.0), "contact")
	GameEvents.emit_player_noise(global_position, 20.0)
	attack_cooldown = randf_range(0.85, 1.35) / max(0.35, attack_modifier)

func _pick_player_hit_zone() -> String:
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

func on_zone_damaged(zone_name: String, damage: float, hit_position: Vector3) -> void:
	if core_mesh and zone_name == "parasite_core":
		core_mesh.scale = Vector3.ONE * 1.45
	if senses:
		senses.last_known_position = target.global_position if target else global_position
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

func die(cause: String) -> void:
	if dead:
		return
	dead = true
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
	body_mesh = MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.35
	capsule.height = 1.45
	body_mesh.mesh = capsule
	body_mesh.position.y = 0.85
	body_mesh.material_override = _make_material(Color(0.22, 0.25, 0.28), 0.0)
	add_child(body_mesh)
	head_mesh = MeshInstance3D.new()
	var head := SphereMesh.new()
	head.radius = 0.24
	head.height = 0.48
	head_mesh.mesh = head
	head_mesh.position.y = 1.72
	head_mesh.material_override = _make_material(Color(0.5, 0.58, 0.62), 0.0)
	add_child(head_mesh)
	core_mesh = MeshInstance3D.new()
	var core := SphereMesh.new()
	core.radius = 0.18
	core.height = 0.36
	core_mesh.mesh = core
	core_mesh.position = Vector3(0, 1.12, -0.34)
	core_mesh.material_override = _make_material(Color(0.2, 1.0, 0.82), 0.8)
	add_child(core_mesh)

func _make_material(color: Color, emission_energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission_energy
	return material
