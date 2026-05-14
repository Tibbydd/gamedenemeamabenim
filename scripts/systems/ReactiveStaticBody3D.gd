extends StaticBody3D
class_name ReactiveStaticBody3D

var integrity: float = 120.0
var scar_level: float = 0.0

func _ready() -> void:
	add_to_group("dynamic_environment")
	collision_layer = 1
	collision_mask = 0

func receive_generic_hit(damage: float, hit_position: Vector3, hit_direction: Vector3) -> void:
	scar_level = clamp(scar_level + damage * 0.01, 0.0, 1.0)
	integrity -= damage * 0.2
	_update_scar_visual()

func apply_environment_impulse(origin: Vector3, force: float, radius: float, reason: String) -> void:
	scar_level = clamp(scar_level + force * 0.01, 0.0, 1.0)
	integrity -= force * 0.05
	_update_scar_visual()

func activate_from_physics(body: Node, impact_speed: float) -> void:
	if impact_speed >= 3.0:
		scar_level = clamp(scar_level + impact_speed * 0.04, 0.0, 1.0)
		_update_scar_visual()

func use(actor: Node) -> void:
	GameEvents.emit_environment_impulse(global_position, 0.8, 1.5, self, "manual_use_surface")

func _update_scar_visual() -> void:
	for child in get_children():
		if child is MeshInstance3D:
			var material := StandardMaterial3D.new()
			material.albedo_color = Color(0.18, 0.2, 0.2).lerp(Color(0.45, 0.18, 0.12), scar_level)
			material.emission_enabled = scar_level > 0.25
			material.emission = Color(0.45, 0.12, 0.06)
			material.emission_energy_multiplier = scar_level * 0.25
			child.material_override = material
