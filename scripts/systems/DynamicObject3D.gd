extends RigidBody3D
class_name DynamicObject3D

var display_name: String = "Dynamic Object"
var durability: float = 35.0
var can_activate_buttons: bool = true
var mesh_instance: MeshInstance3D

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
	mesh_instance = MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _make_material(color, 0.0)
	add_child(mesh_instance)

func receive_generic_hit(damage: float, hit_position: Vector3, hit_direction: Vector3) -> void:
	durability -= damage
	apply_central_impulse(hit_direction.normalized() * damage * 0.18)
	if durability <= 0.0:
		GameEvents.emit_environment_impulse(global_position, 1.6, damage * 0.6, self, "object_break")
		queue_free()

func apply_environment_impulse(origin: Vector3, force: float, radius: float, reason: String) -> void:
	var direction := global_position - origin
	if direction.length() < 0.05:
		direction = Vector3.UP
	apply_central_impulse(direction.normalized() * force)

func use(actor: Node) -> void:
	apply_central_impulse(Vector3.UP * 1.5)

func _on_body_entered(body: Node) -> void:
	if not can_activate_buttons:
		return
	var speed := linear_velocity.length()
	if speed < 2.5:
		return
	if body.has_method("activate_from_physics"):
		body.activate_from_physics(self, speed)

func _make_material(color: Color, emission_energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission_energy
	return material
