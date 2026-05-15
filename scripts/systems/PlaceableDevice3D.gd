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
	mesh_instance = MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _make_material(color, 0.15)
	add_child(mesh_instance)

func use(_actor: Node) -> void:
	activate("manual_use")

func receive_generic_hit(damage: float, _hit_position: Vector3, hit_direction: Vector3) -> void:
	durability -= damage
	apply_central_impulse(hit_direction.normalized() * damage * 0.12)
	if behavior in ["trip_mine", "shock_pylon", "noisemaker"] and damage >= 8.0:
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
