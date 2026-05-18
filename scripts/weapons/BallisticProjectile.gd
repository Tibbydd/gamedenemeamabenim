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
	_impact()

func _impact() -> void:
	has_impacted = true
	_create_impact_flash()
	queue_free()

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
