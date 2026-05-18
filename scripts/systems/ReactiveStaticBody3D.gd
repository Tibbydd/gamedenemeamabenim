extends StaticBody3D
class_name ReactiveStaticBody3D

var integrity: float = 120.0
var scar_level: float = 0.0
var surface_id: String = "metal"
var destroyed: bool = false
var destructible: bool = true
var accepts_impulse_damage: bool = true
var hit_damage_scale: float = 0.2
var impulse_damage_scale: float = 0.05

func _ready() -> void:
	add_to_group("dynamic_environment")
	collision_layer = 1
	collision_mask = 0

func configure_reactivity(new_surface_id: String, new_destructible: bool = true, new_integrity: float = 120.0, new_accepts_impulse_damage: bool = true) -> void:
	surface_id = new_surface_id
	destructible = new_destructible
	integrity = new_integrity
	accepts_impulse_damage = new_accepts_impulse_damage
	if not destructible:
		hit_damage_scale = 0.0
		impulse_damage_scale = 0.0
	else:
		hit_damage_scale = 0.2
		impulse_damage_scale = 0.05

func receive_generic_hit(damage: float, hit_position: Vector3, _hit_direction: Vector3) -> void:
	if destroyed:
		return
	scar_level = clamp(scar_level + damage * 0.01, 0.0, 1.0)
	if destructible:
		integrity -= damage * hit_damage_scale
	_update_scar_visual()
	_check_destroyed(hit_position)

func apply_environment_impulse(origin: Vector3, force: float, _radius: float, _reason: String) -> void:
	if destroyed:
		return
	scar_level = clamp(scar_level + force * 0.01, 0.0, 1.0)
	if destructible and accepts_impulse_damage:
		integrity -= force * impulse_damage_scale
	_update_scar_visual()
	_check_destroyed(origin)

func activate_from_physics(_body: Node, impact_speed: float) -> void:
	if impact_speed >= 3.0:
		scar_level = clamp(scar_level + impact_speed * 0.04, 0.0, 1.0)
		_update_scar_visual()

func use(_actor: Node) -> void:
	GameEvents.emit_environment_impulse(global_position, 0.8, 1.5, self, "manual_use_surface")

func get_surface_id() -> String:
	return surface_id

func get_penetration_loss() -> float:
	if not destructible:
		return 900.0
	return 42.0

func _check_destroyed(impact_position: Vector3) -> void:
	if not destructible or integrity > 0.0 or destroyed:
		return
	destroyed = true
	collision_layer = 0
	collision_mask = 0
	for child in get_children():
		if child is CollisionShape3D:
			(child as CollisionShape3D).disabled = true
		if child is MeshInstance3D:
			(child as MeshInstance3D).visible = false
	GameEvents.emit_environment_impulse(impact_position, 1.8, 3.5, self, "cover_destroyed")

func _update_scar_visual() -> void:
	var color := Color(0.18, 0.2, 0.2).lerp(Color(0.45, 0.18, 0.12), scar_level)
	var emission := scar_level * 0.25 if scar_level > 0.25 else 0.0
	var material := EffectMaterialCache.get_material(color, emission)
	for child in get_children():
		if child is MeshInstance3D:
			child.material_override = material
