extends StaticBody3D
class_name DynamicButton3D

signal activated(button_id: String)

var button_id: String = "button"
var active: bool = false
var mesh_instance: MeshInstance3D
var inactive_color: Color = Color(0.12, 0.26, 0.27)
var active_color: Color = Color(0.1, 0.95, 0.68)
var sticky_body: Node = null

func _ready() -> void:
	add_to_group("dynamic_environment")
	add_to_group("immersive_buttons")
	collision_layer = 1
	collision_mask = 1 | 8

func configure(new_button_id: String, size: Vector3 = Vector3(0.7, 0.28, 0.18)) -> void:
	button_id = new_button_id
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	add_child(collision)
	mesh_instance = MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _make_material(inactive_color, 0.1)
	add_child(mesh_instance)

func receive_generic_hit(damage: float, _hit_position: Vector3, _hit_direction: Vector3) -> void:
	if damage >= 2.0:
		activate("projectile")

func apply_environment_impulse(_origin: Vector3, force: float, _radius: float, reason: String) -> void:
	if force >= 2.0:
		activate(reason)

func activate_from_physics(body: Node, impact_speed: float) -> void:
	if impact_speed >= 2.5:
		if body and body is PlaceableDevice3D and String((body as PlaceableDevice3D).behavior) == "pressure_decoy":
			sticky_body = body
			if not active:
				_set_active(true, "pressure_decoy")
			return
		activate("thrown_object")

func use(_actor: Node) -> void:
	activate("manual_use")

func activate(reason: String) -> void:
	_set_active(not active, reason)

func _process(_delta: float) -> void:
	if sticky_body and (not is_instance_valid(sticky_body) or global_position.distance_to((sticky_body as Node3D).global_position) > 0.95):
		sticky_body = null
		if active:
			_set_active(false, "pressure_released")

func _set_active(new_active: bool, reason: String) -> void:
	active = new_active
	if mesh_instance:
		var color := active_color if active else inactive_color
		mesh_instance.material_override = _make_material(color, 0.7 if active else 0.1)
	activated.emit(button_id)
	GameEvents.request_sound("button", global_position, 0.8)
	GameEvents.emit_environment_impulse(global_position, 1.2, 2.0, self, "button_" + reason)

func _make_material(color: Color, emission_energy: float) -> StandardMaterial3D:
	return EffectMaterialCache.get_material(color, emission_energy)
