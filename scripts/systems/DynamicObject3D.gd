extends RigidBody3D
class_name DynamicObject3D

var display_name: String = "Dynamic Object"
var durability: float = 35.0
var can_activate_buttons: bool = true
var mesh_instance: MeshInstance3D
var penetration_loss: float = 18.0
var surface_id: String = "metal"
var carried_by: Node = null

func _ready() -> void:
	add_to_group("dynamic_environment")
	collision_layer = 1
	collision_mask = 1 | 2 | 8
	contact_monitor = true
	max_contacts_reported = 8
	body_entered.connect(_on_body_entered)

func configure(new_name: String, size: Vector3, color: Color, object_mass: float = 8.0, activates_buttons: bool = true) -> void:
	display_name = new_name
	mass = object_mass
	can_activate_buttons = activates_buttons
	_build_body(size, color)

func _build_body(size: Vector3, color: Color) -> void:
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	add_child(collision)
	_build_visual(size, color)

func _build_visual(size: Vector3, color: Color) -> void:
	mesh_instance = _add_box_mesh("ObjectBody", size, Vector3.ZERO, color, 0.0)
	_add_box_mesh("ObjectTopPlate", Vector3(size.x * 0.88, max(0.025, size.y * 0.08), size.z * 0.82), Vector3(0.0, size.y * 0.52, 0.0), color.lightened(0.12), 0.03)
	_add_box_mesh("ObjectFrontLatch", Vector3(size.x * 0.22, size.y * 0.32, max(0.025, size.z * 0.08)), Vector3(0.0, 0.0, -size.z * 0.54), color.darkened(0.35), 0.0)

func _add_box_mesh(mesh_name: String, size: Vector3, position: Vector3, color: Color, emission_energy: float = 0.0, rotation_degrees_value: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var new_mesh_instance := MeshInstance3D.new()
	new_mesh_instance.name = mesh_name
	var mesh := BoxMesh.new()
	mesh.size = size
	new_mesh_instance.mesh = mesh
	new_mesh_instance.position = position
	new_mesh_instance.rotation_degrees = rotation_degrees_value
	new_mesh_instance.material_override = _make_material(color, emission_energy)
	add_child(new_mesh_instance)
	return new_mesh_instance

func _add_cylinder_mesh(mesh_name: String, radius: float, height: float, position: Vector3, color: Color, emission_energy: float = 0.0, rotation_degrees_value: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var new_mesh_instance := MeshInstance3D.new()
	new_mesh_instance.name = mesh_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 16
	new_mesh_instance.mesh = mesh
	new_mesh_instance.position = position
	new_mesh_instance.rotation_degrees = rotation_degrees_value
	new_mesh_instance.material_override = _make_material(color, emission_energy)
	add_child(new_mesh_instance)
	return new_mesh_instance

func _add_sphere_mesh(mesh_name: String, radius: float, position: Vector3, color: Color, emission_energy: float = 0.0) -> MeshInstance3D:
	var new_mesh_instance := MeshInstance3D.new()
	new_mesh_instance.name = mesh_name
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 16
	mesh.rings = 8
	new_mesh_instance.mesh = mesh
	new_mesh_instance.position = position
	new_mesh_instance.material_override = _make_material(color, emission_energy)
	add_child(new_mesh_instance)
	return new_mesh_instance

func receive_generic_hit(damage: float, _hit_position: Vector3, hit_direction: Vector3) -> void:
	durability -= damage
	apply_central_impulse(hit_direction.normalized() * damage * 0.18)
	if durability <= 0.0:
		GameEvents.emit_environment_impulse(global_position, 1.6, damage * 0.6, self, "object_break")
		queue_free()

func apply_environment_impulse(origin: Vector3, force: float, _radius: float, _reason: String) -> void:
	var direction := global_position - origin
	if direction.length() < 0.05:
		direction = Vector3.UP
	apply_central_impulse(direction.normalized() * force)

func use(_actor: Node) -> void:
	apply_central_impulse(Vector3.UP * 1.5)

func get_penetration_loss() -> float:
	return penetration_loss

func get_surface_id() -> String:
	return surface_id

func begin_carry(actor: Node) -> void:
	carried_by = actor
	gravity_scale = 0.0
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO

func update_carried(target_position: Vector3) -> void:
	if not carried_by:
		return
	var to_target := target_position - global_position
	linear_velocity = to_target * 12.0
	angular_velocity = angular_velocity.move_toward(Vector3.ZERO, 0.35)

func end_carry(throw_velocity: Vector3 = Vector3.ZERO) -> void:
	carried_by = null
	gravity_scale = 1.0
	linear_velocity = throw_velocity

func _on_body_entered(body: Node) -> void:
	if not can_activate_buttons:
		return
	var speed := linear_velocity.length()
	if speed < 2.5:
		return
	if body.has_method("activate_from_physics"):
		body.activate_from_physics(self, speed)

func _make_material(color: Color, emission_energy: float) -> StandardMaterial3D:
	return EffectMaterialCache.get_material(color, emission_energy)
