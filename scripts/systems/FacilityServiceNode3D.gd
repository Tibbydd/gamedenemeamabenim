extends StaticBody3D
class_name FacilityServiceNode3D

signal service_used(node_id: String, service_type: String, target_id: String, method_id: String, actor: Node)

var node_id: String = "service_node"
var service_type: String = "sector_power"
var target_id: String = "arena"
var method_id: String = "reset_breaker"
var requirement_id: String = ""
var requirement_amount: int = 0
var activated: bool = false
var mesh_instance: MeshInstance3D

func configure(new_node_id: String, new_service_type: String, new_target_id: String, new_method_id: String, new_requirement_id: String = "", new_requirement_amount: int = 0) -> void:
	node_id = new_node_id
	service_type = new_service_type
	target_id = new_target_id
	method_id = new_method_id
	requirement_id = new_requirement_id
	requirement_amount = new_requirement_amount
	_build_body()

func _ready() -> void:
	add_to_group("dynamic_environment")
	collision_layer = 1
	collision_mask = 1 | 8

func use(actor: Node) -> void:
	if activated:
		return
	if requirement_amount > 0:
		if not actor or not actor.has_method("consume_resource"):
			return
		if not actor.consume_resource(requirement_id, requirement_amount):
			if actor.has_method("notify_service_failure"):
				actor.notify_service_failure(_requirement_text())
			return
	activated = true
	_update_visual(true)
	GameEvents.request_sound("interact", global_position, 0.75)
	service_used.emit(node_id, service_type, target_id, method_id, actor)

func receive_generic_hit(damage: float, _hit_position: Vector3, _hit_direction: Vector3) -> void:
	if method_id == "impact_reset" and damage >= 8.0:
		use(null)

func activate_from_physics(body: Node, impact_speed: float) -> void:
	if method_id == "impact_reset" and impact_speed >= 2.5:
		use(body)

func _requirement_text() -> String:
	return "Requires %s x%d." % [requirement_id.replace("_", " "), requirement_amount]

func _build_body() -> void:
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.74, 0.46, 0.18)
	collision.shape = shape
	add_child(collision)
	mesh_instance = MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.74, 0.46, 0.18)
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _make_material(Color(0.12, 0.2, 0.22), 0.12)
	add_child(mesh_instance)

func _update_visual(active: bool) -> void:
	if mesh_instance:
		mesh_instance.material_override = _make_material(Color(0.16, 0.8, 0.52) if active else Color(0.12, 0.2, 0.22), 0.55 if active else 0.12)

func _make_material(color: Color, emission_energy: float) -> StandardMaterial3D:
	return EffectMaterialCache.get_material(color, emission_energy)
