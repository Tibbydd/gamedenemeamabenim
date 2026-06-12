extends Area3D
class_name BallisticProjectile

var damage: float = 35.0
var velocity: Vector3 = Vector3.ZERO
var projectile_gravity: float = 9.8
var lifetime: float = 2.0
var weapon_name: String = "Projectile Weapon"
var source_body: Node
var has_impacted: bool = false
var previous_position: Vector3 = Vector3.ZERO
var projectile_shape: SphereShape3D
var max_step_distance: float = 0.18
var penetrations_remaining: int = 2

func configure(origin: Vector3, direction: Vector3, speed: float, new_damage: float, new_gravity: float, new_lifetime: float, new_weapon_name: String, new_source_body: Node) -> void:
	global_position = origin
	previous_position = origin
	velocity = direction.normalized() * speed
	damage = new_damage
	projectile_gravity = new_gravity
	lifetime = new_lifetime
	weapon_name = new_weapon_name
	source_body = new_source_body

func _ready() -> void:
	collision_layer = 8
	collision_mask = 1 | 2 | 4
	monitoring = true
	monitorable = false
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	_build_debug_visual()

func _physics_process(delta: float) -> void:
	if has_impacted:
		return
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	previous_position = global_position
	_advance_projectile(delta)

func _advance_projectile(delta: float) -> void:
	var projected_motion := velocity * delta
	var step_count: int = max(1, int(ceil(projected_motion.length() / max_step_distance)))
	var step_delta := delta / float(step_count)
	for i in range(step_count):
		velocity.y -= projectile_gravity * step_delta
		var next_position := global_position + velocity * step_delta
		var collider: Object = _find_overlap_at(next_position)
		global_position = next_position
		if collider:
			_impact_collider(collider)
			return

func _on_area_entered(area: Area3D) -> void:
	if has_impacted or area == source_body:
		return
	_impact_collider(area)

func _on_body_entered(body: Node3D) -> void:
	if has_impacted or body == source_body:
		return
	_impact_collider(body)

func _find_overlap_at(test_position: Vector3) -> Object:
	if not projectile_shape:
		return null
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = projectile_shape
	query.transform = Transform3D(Basis(), test_position)
	query.collision_mask = 1 | 2 | 4
	query.collide_with_areas = true
	query.collide_with_bodies = true
	if source_body and source_body is CollisionObject3D:
		query.exclude = [source_body.get_rid()]
	var hits := get_world_3d().direct_space_state.intersect_shape(query, 8)
	var fallback_collider: Object = null
	for hit in hits:
		var collider: Object = hit.get("collider")
		if collider and collider != self and collider != source_body:
			if collider.has_method("apply_hit"):
				return collider
			if not fallback_collider:
				fallback_collider = collider
	return fallback_collider

func _impact_collider(collider: Object) -> void:
	# Check for shootable light fixture first — bullet is consumed on hit
	if collider is StaticBody3D and (collider as StaticBody3D).has_meta("breakable_light"):
		_break_light_fixture(collider as StaticBody3D)
		_impact()
		return
	if collider.has_method("apply_hit"):
		collider.apply_hit(damage, global_position, velocity.normalized(), weapon_name)
	elif collider.has_method("receive_generic_hit"):
		collider.receive_generic_hit(damage, global_position, velocity.normalized())
	if collider.has_method("get_penetration_loss") and penetrations_remaining > 0:
		var penetration_loss := float(collider.get_penetration_loss())
		if penetration_loss > 0.0 and damage > penetration_loss + 8.0:
			damage -= penetration_loss
			velocity *= clamp(1.0 - penetration_loss / 90.0, 0.25, 0.82)
			penetrations_remaining -= 1
			GameEvents.emit_environment_impulse(global_position, 0.55, max(1.2, damage * 0.12), source_body, "bullet_penetration")
			return
	GameEvents.emit_environment_impulse(global_position, 0.95, max(2.0, damage * 0.22), source_body, "bullet_impact")
	# Material-specific visual + audio impact
	var is_flesh := collider.is_in_group("enemies") or collider.has_method("apply_hit")
	if is_flesh:
		_spawn_flesh_impact(global_position, velocity.normalized())
	else:
		_spawn_metal_impact(global_position, velocity.normalized())
		_try_spawn_ricochet()
	_impact()

func _impact() -> void:
	has_impacted = true
	_create_impact_flash()
	queue_free()

func _spawn_flesh_impact(pos: Vector3, dir: Vector3) -> void:
	var scene := get_tree().current_scene
	if not scene:
		return
	# Dark-red particle burst traveling in the bullet's exit direction
	var particles := GPUParticles3D.new()
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(dir.x, dir.y + 0.15, dir.z).normalized()
	pm.spread = 28.0
	pm.initial_velocity_min = 2.2
	pm.initial_velocity_max = 4.8
	pm.gravity = Vector3(0.0, -6.0, 0.0)
	pm.color = Color(0.48, 0.04, 0.04, 0.9)
	pm.scale_min = 0.018
	pm.scale_max = 0.036
	particles.process_material = pm
	var mesh_p := QuadMesh.new()
	mesh_p.size = Vector2(0.025, 0.025)
	particles.draw_pass_1 = mesh_p
	particles.amount = 14
	particles.lifetime = 0.55
	particles.explosiveness = 0.92
	particles.one_shot = true
	particles.global_position = pos
	scene.add_child(particles)
	particles.emitting = true
	GameEvents.request_sound("enemy_hit", pos, 0.8)
	scene.get_tree().create_timer(1.2).timeout.connect(particles.queue_free)

func _spawn_metal_impact(pos: Vector3, dir: Vector3) -> void:
	var scene := get_tree().current_scene
	if not scene:
		return
	# White-orange sparks
	var particles := GPUParticles3D.new()
	var pm := ParticleProcessMaterial.new()
	pm.direction = (Vector3(-dir.x, 0.4, -dir.z)).normalized()
	pm.spread = 52.0
	pm.initial_velocity_min = 1.8
	pm.initial_velocity_max = 5.5
	pm.gravity = Vector3(0.0, -9.8, 0.0)
	pm.color = Color(1.0, 0.72, 0.18, 1.0)
	pm.scale_min = 0.010
	pm.scale_max = 0.022
	particles.process_material = pm
	var mesh_p := QuadMesh.new()
	mesh_p.size = Vector2(0.015, 0.015)
	particles.draw_pass_1 = mesh_p
	particles.amount = 18
	particles.lifetime = 0.45
	particles.explosiveness = 0.88
	particles.one_shot = true
	particles.global_position = pos
	scene.add_child(particles)
	particles.emitting = true
	# Ricochet sound — metal footstep pitched up
	GameEvents.request_sound("footstep_metal", pos, 1.8)
	# Bullet mark: small dark disc inset into wall surface
	var mark := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 0.038
	disc.bottom_radius = 0.038
	disc.height = 0.002
	mark.mesh = disc
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.08, 0.07, 0.07)
	mat.metallic = 0.0
	mat.roughness = 1.0
	mark.material_override = mat
	# Orient disc to face along shot direction (lying flat on surface)
	mark.global_position = pos + (-dir) * 0.012
	mark.look_at(pos + (-dir) * 0.1, Vector3.UP if abs(dir.y) < 0.95 else Vector3.RIGHT)
	mark.rotate_object_local(Vector3.RIGHT, PI * 0.5)
	scene.add_child(mark)
	scene.get_tree().create_timer(1.5).timeout.connect(particles.queue_free)
	# Bullet marks fade and persist (45s)
	var fade_tween := mark.create_tween()
	fade_tween.tween_interval(40.0)
	fade_tween.tween_property(mark, "modulate:a", 0.0, 5.0)
	fade_tween.tween_callback(mark.queue_free)

func _build_debug_visual() -> void:
	var collision := CollisionShape3D.new()
	projectile_shape = SphereShape3D.new()
	projectile_shape.radius = 0.045
	collision.shape = projectile_shape
	add_child(collision)
	var mesh_instance := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.045
	mesh.height = 0.09
	mesh_instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.78, 0.32)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.42, 0.12)
	material.emission_energy_multiplier = 1.5
	mesh_instance.material_override = material
	add_child(mesh_instance)

func _create_impact_flash() -> void:
	var flash := OmniLight3D.new()
	flash.light_color = Color(1.0, 0.55, 0.22)
	flash.light_energy = 1.4
	flash.omni_range = 2.0
	flash.global_position = global_position
	var scene := get_tree().current_scene
	if not scene:
		return
	scene.add_child(flash)
	var tween := flash.create_tween()
	tween.tween_property(flash, "light_energy", 0.0, 0.08)
	tween.tween_callback(flash.queue_free)

func _try_spawn_ricochet() -> void:
	if penetrations_remaining <= 0 or damage < 10.0:
		return
	var speed := velocity.length()
	if speed < 80.0:
		return
	var space := get_world_3d().direct_space_state
	var probe_start := global_position - velocity.normalized() * 0.12
	var probe_end := global_position + velocity.normalized() * 0.12
	var query := PhysicsRayQueryParameters3D.create(probe_start, probe_end)
	query.collision_mask = 1
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return
	var normal := Vector3(hit.get("normal"))
	# Only ricochet at glancing angles (bullet nearly parallel to surface)
	var cos_incidence := abs(velocity.normalized().dot(normal))
	if cos_incidence > 0.42:  # > ~25° incidence — too steep to ricochet
		return
	var reflect_dir := velocity.normalized().bounce(normal)
	var scene := get_tree().current_scene
	if not scene:
		return
	var rico := BallisticProjectile.new()
	scene.add_child(rico)
	rico.configure(
		global_position + reflect_dir * 0.09,
		reflect_dir,
		speed * 0.52,
		damage * 0.35,
		projectile_gravity,
		min(lifetime, 1.4),
		weapon_name,
		source_body
	)
	rico.penetrations_remaining = 0

func _break_light_fixture(shell: StaticBody3D) -> void:
	var scene := get_tree().current_scene
	if not scene:
		return
	# Kill the shell's collision so follow-up bullets pass through
	for child in shell.get_children():
		if child is CollisionShape3D:
			(child as CollisionShape3D).disabled = true
	# Fade out the light
	var light_var: Variant = shell.get_meta("light_node")
	if light_var is OmniLight3D and is_instance_valid(light_var as OmniLight3D):
		var omni: OmniLight3D = light_var as OmniLight3D
		var tween := omni.create_tween()
		tween.tween_property(omni, "light_energy", 0.0, 0.12)\
			.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		tween.tween_callback(omni.queue_free)
	# Electrical spark shower — white-blue particles
	var sparks := GPUParticles3D.new()
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0.0, -1.0, 0.0)
	pm.spread = 80.0
	pm.initial_velocity_min = 1.5
	pm.initial_velocity_max = 5.8
	pm.gravity = Vector3(0.0, -9.8, 0.0)
	pm.color = Color(0.72, 0.88, 1.0, 1.0)
	pm.scale_min = 0.010
	pm.scale_max = 0.022
	sparks.process_material = pm
	var quad := QuadMesh.new()
	quad.size = Vector2(0.015, 0.015)
	sparks.draw_pass_1 = quad
	sparks.amount = 22
	sparks.lifetime = 0.6
	sparks.explosiveness = 0.95
	sparks.one_shot = true
	sparks.global_position = shell.global_position
	scene.add_child(sparks)
	sparks.emitting = true
	# Lingering arc flash light
	var arc := OmniLight3D.new()
	arc.light_color = Color(0.55, 0.78, 1.0)
	arc.light_energy = 3.5
	arc.omni_range = 3.5
	arc.global_position = shell.global_position
	scene.add_child(arc)
	var arc_tween := arc.create_tween()
	arc_tween.tween_property(arc, "light_energy", 0.0, 0.18)\
		.set_trans(Tween.TRANS_EXPO)
	arc_tween.tween_callback(arc.queue_free)
	# Electrical pop sound
	GameEvents.request_sound("footstep_metal", shell.global_position, 1.9)
	scene.get_tree().create_timer(1.5).timeout.connect(sparks.queue_free)
