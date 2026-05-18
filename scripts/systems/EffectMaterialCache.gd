extends RefCounted
class_name EffectMaterialCache

static var _materials: Dictionary = {}

static func get_material(color: Color, emission_energy: float = 0.0) -> StandardMaterial3D:
	var key := "%0.3f:%0.3f:%0.3f:%0.3f:%0.3f" % [
		color.r,
		color.g,
		color.b,
		color.a,
		emission_energy
	]
	if _materials.has(key):
		return _materials[key]
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission_energy
	_materials[key] = material
	return material
