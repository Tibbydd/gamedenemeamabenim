extends RigidBody3D
class_name PlaceableDevice3D

var device_id: String = "device"
var label: String = "Device"
var behavior: String = "cover"
var armed: bool = true
var radius: float = 2.0
var impulse_force: float = 6.0
var durability: float = 45.0
var mesh_instance: MeshInstance3D
var flare_burn_time: float = 0.0
var pulse_timer: float = 0.0

func _ready() -> void:
	add_to_group("dynamic_environment")
	add_to_group("player_placeables")
	collision_layer = 1
	collision_mask = 1 | 2 | 8
	contact_monitor = true
	max_contacts_reported = 8
	body_entered.connect(_on_body_entered)

func configure(definition: Dictionary) -> void:
	device_id = String(definition.get("id", "device"))
	label = String(definition.get("label", "Device"))
	behavior = String(definition.get("behavior", "cover"))
	radius = float(definition.get("radius", 2.0))
	impulse_force = float(definition.get("impulse", 6.0))
	durability = float(definition.get("durability", 45.0))
	mass = float(definition.get("mass", 12.0))
	var size: Vector3 = definition.get("size", Vector3(0.8, 0.5, 0.25))
	var color: Color = definition.get("color", Color(0.2, 0.35, 0.36))
	_build_body(size, color)
	if behavior == "flare":
		_add_light(Color(0.95, 0.4, 0.18), 2.0, 7.0)
		flare_burn_time = 55.0
	elif behavior == "sensor":
		_add_light(Color(0.1, 0.7, 1.0), 0.8, 4.0)

func _process(delta: float) -> void:
	if behavior != "flare" or flare_burn_time <= 0.0:
		return
	flare_burn_time = max(0.0, flare_burn_time - delta)
	pulse_timer -= delta
	if pulse_timer <= 0.0:
		pulse_timer = 3.0
		GameEvents.emit_player_noise(global_position, 10.0)
		GameEvents.request_sound("telemetry_ping", global_position, 0.12)

func _build_body(size: Vector3, color: Color) -> void:
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	add_child(collision)
	_build_visual(size, color)

func _build_visual(size: Vector3, color: Color) -> void:
	if behavior == "cover":
		mesh_instance = _add_box_mesh("CoverPanel", size, Vector3.ZERO, color, 0.12)
		_add_box_mesh("CoverTopRail", Vector3(size.x * 1.04, size.y * 0.08, size.z * 1.08), Vector3(0.0, size.y * 0.46, 0.0), color.lightened(0.12), 0.08)
		_add_box_mesh("CoverLowerRail", Vector3(size.x * 1.04, size.y * 0.08, size.z * 1.08), Vector3(0.0, -size.y * 0.46, 0.0), color.darkened(0.16), 0.0)
		for x in [-0.32, 0.0, 0.32]:
			_add_box_mesh("CoverRib", Vector3(size.x * 0.07, size.y * 0.9, size.z * 1.12), Vector3(size.x * x, 0.0, 0.0), color.darkened(0.22), 0.0)
	elif behavior == "trip_mine":
		mesh_instance = _add_box_mesh("TripMineBase", Vector3(size.x, size.y * 0.38, size.z), Vector3.ZERO, color, 0.14)
		_add_cylinder_mesh("TripMineSensor", size.x * 0.22, size.y * 0.5, Vector3(0.0, size.y * 0.35, 0.0), Color(0.85, 0.22, 0.12), 0.5)
		_add_box_mesh("TripMineLens", Vector3(size.x * 0.15, size.y * 0.16, size.z * 0.12), Vector3(0.0, size.y * 0.38, -size.z * 0.48), Color(1.0, 0.4, 0.2), 0.65)
	elif behavior == "noisemaker":
		mesh_instance = _add_box_mesh("NoisemakerBody", Vector3(size.x, size.y, size.z), Vector3.ZERO, color, 0.12)
		_add_cylinder_mesh("NoisemakerSpeaker", size.x * 0.3, size.z * 0.08, Vector3(0.0, 0.0, -size.z * 0.54), Color(0.02, 0.04, 0.045), 0.0, Vector3(90.0, 0.0, 0.0))
		_add_box_mesh("NoisemakerAntenna", Vector3(size.x * 0.06, size.y * 0.85, size.z * 0.06), Vector3(size.x * 0.34, size.y * 0.55, 0.0), color.lightened(0.22), 0.2)
	elif behavior == "shock_pylon":
		mesh_instance = _add_cylinder_mesh("ShockPylonMast", size.x * 0.18, size.y, Vector3.ZERO, color, 0.35)
		_add_cylinder_mesh("ShockPylonBase", size.x * 0.42, size.y * 0.14, Vector3(0.0, -size.y * 0.45, 0.0), color.darkened(0.15), 0.12)
		for y in [-0.14, 0.12, 0.36]:
			_add_cylinder_mesh("ShockPylonCoil", size.x * 0.28, size.y * 0.055, Vector3(0.0, size.y * y, 0.0), Color(0.18, 0.85, 1.0), 0.65)
	elif behavior == "flare":
		mesh_instance = _add_cylinder_mesh("FlareTube", size.x * 0.5, size.z, Vector3.ZERO, color, 0.65, Vector3(90.0, 0.0, 0.0))
		_add_cylinder_mesh("FlareHotEnd", size.x * 0.52, size.z * 0.08, Vector3(0.0, 0.0, -size.z * 0.55), Color(1.0, 0.55, 0.12), 1.1, Vector3(90.0, 0.0, 0.0))
	elif behavior == "sensor":
		mesh_instance = _add_box_mesh("SensorCore", Vector3(size.x, size.y * 0.55, size.z), Vector3(0.0, size.y * 0.1, 0.0), color, 0.22)
		_add_cylinder_mesh("SensorLens", size.x * 0.22, size.z * 0.08, Vector3(0.0, size.y * 0.12, -size.z * 0.55), Color(0.18, 0.8, 1.0), 0.7, Vector3(90.0, 0.0, 0.0))
		_add_box_mesh("SensorLegA", Vector3(size.x * 0.08, size.y * 0.55, size.z * 0.08), Vector3(-size.x * 0.32, -size.y * 0.35, size.z * 0.18), color.darkened(0.25), 0.0, Vector3(0.0, 0.0, -14.0))
		_add_box_mesh("SensorLegB", Vector3(size.x * 0.08, size.y * 0.55, size.z * 0.08), Vector3(size.x * 0.32, -size.y * 0.35, size.z * 0.18), color.darkened(0.25), 0.0, Vector3(0.0, 0.0, 14.0))
	elif behavior == "pressure_decoy":
		mesh_instance = _add_box_mesh("PressureDecoyWeight", Vector3(size.x, size.y * 0.65, size.z), Vector3.ZERO, color, 0.0)
		_add_box_mesh("PressureDecoyHandle", Vector3(size.x * 0.52, size.y * 0.16, size.z * 0.16), Vector3(0.0, size.y * 0.44, 0.0), color.lightened(0.16), 0.0)
	else:
		mesh_instance = _add_box_mesh("DeviceBody", size, Vector3.ZERO, color, 0.15)
		_add_box_mesh("DeviceDetailPlate", Vector3(size.x * 0.72, size.y * 0.12, size.z * 0.75), Vector3(0.0, size.y * 0.48, 0.0), color.lightened(0.14), 0.12)

func use(_actor: Node) -> void:
	activate("manual_use")

func receive_generic_hit(damage: float, _hit_position: Vector3, hit_direction: Vector3) -> void:
	durability -= damage
	apply_central_impulse(hit_direction.normalized() * damage * 0.12)
	var can_trigger_from_damage := behavior == "trip_mine" or behavior == "shock_pylon" or behavior == "noisemaker"
	if can_trigger_from_damage and damage >= 8.0:
		activate("projectile")
	elif durability <= 0.0:
		activate("destroyed")

func apply_environment_impulse(origin: Vector3, force: float, _impulse_radius: float, reason: String) -> void:
	var direction := global_position - origin
	if direction.length() < 0.05:
		direction = Vector3.UP
	apply_central_impulse(direction.normalized() * force)
	if behavior == "trip_mine" and force >= 5.0:
		activate(reason)

func activate(_reason: String) -> void:
	if not armed:
		return
	if behavior == "trip_mine":
		armed = false
		GameEvents.emit_environment_impulse(global_position, radius, impulse_force, self, "trip_mine")
		queue_free()
	elif behavior == "noisemaker":
		GameEvents.emit_player_noise(global_position, 58.0)
		GameEvents.emit_environment_impulse(global_position, radius, impulse_force * 0.35, self, "noisemaker")
	elif behavior == "shock_pylon":
		GameEvents.emit_environment_impulse(global_position, radius, impulse_force, self, "shock_pylon")
	elif behavior == "flare":
		GameEvents.emit_player_noise(global_position, 18.0)
	elif behavior == "sensor":
		GameEvents.emit_player_noise(global_position, 12.0)
	elif behavior == "gap_brace":
		linear_velocity = Vector3.ZERO

func _on_body_entered(body: Node) -> void:
	if not armed:
		return
	if behavior == "trip_mine" and body.is_in_group("enemies"):
		activate("enemy_contact")
	elif behavior == "pressure_decoy" and linear_velocity.length() > 2.0 and body.has_method("activate_from_physics"):
		body.activate_from_physics(self, linear_velocity.length())

func _add_light(color: Color, energy: float, range_value: float) -> void:
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = energy
	light.omni_range = range_value
	add_child(light)

func _make_material(color: Color, emission_energy: float) -> StandardMaterial3D:
	return EffectMaterialCache.get_material(color, emission_energy)

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
