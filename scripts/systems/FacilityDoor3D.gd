extends ReactiveStaticBody3D
class_name FacilityDoor3D

signal door_forced_open(door_id: String)

var door_id: String = "door"
var state: String = "locked"
var force_work: float = 0.0
var mesh_instance: MeshInstance3D
var collision_shape: CollisionShape3D
var lock_housing: DoorLockHousing3D

func configure_door(new_door_id: String, initial_state: String, size: Vector3, color: Color) -> void:
	door_id = new_door_id
	state = initial_state
	_build_body(size, color)
	set_state(initial_state)

func set_state(new_state: String) -> void:
	state = new_state
	if collision_shape:
		collision_shape.disabled = state == FacilityProgression.DOOR_OPEN
	collision_layer = 0 if state == FacilityProgression.DOOR_OPEN else 1
	_update_door_visual()

func receive_generic_hit(damage: float, hit_position: Vector3, hit_direction: Vector3) -> void:
	super.receive_generic_hit(damage, hit_position, hit_direction)
	_stress_door(damage, "projectile")

func apply_environment_impulse(origin: Vector3, force: float, radius: float, reason: String) -> void:
	super.apply_environment_impulse(origin, force, radius, reason)
	var multiplier := 2.4 if reason == "player_shove" else 1.0
	_stress_door(force * multiplier, reason)

func activate_from_physics(body: Node, impact_speed: float) -> void:
	var mass_value := 8.0
	if body is RigidBody3D:
		mass_value = (body as RigidBody3D).mass
	var multiplier := 1.15 if body and body.is_in_group("heavy_pry_objects") else 1.0
	_stress_door(float(mass_value) * impact_speed * 0.55 * multiplier, "thrown_object")

func use(actor: Node) -> void:
	if state == FacilityProgression.DOOR_OPEN:
		return
	var pry_force := 16.0
	var player_actor := actor as PlayerControllerFPS
	if player_actor:
		GameEvents.emit_player_noise(player_actor.global_position, 12.0)
	_stress_door(pry_force, "manual_pry")

func _stress_door(amount: float, reason: String) -> void:
	if state == FacilityProgression.DOOR_OPEN or state == FacilityProgression.DOOR_SEALED:
		return
	force_work += amount
	var threshold := 70.0 if state == FacilityProgression.DOOR_JAMMED else 105.0
	if force_work >= threshold:
		set_state(FacilityProgression.DOOR_OPEN)
		door_forced_open.emit(door_id)
		GameEvents.request_sound("door_forced", global_position, 1.0)
		GameEvents.emit_environment_impulse(global_position, 1.4, 3.0, self, "door_forced_" + reason)

func apply_lock_hit(damage: float, _hit_position: Vector3, _hit_direction: Vector3, _weapon_name: String) -> void:
	if state != FacilityProgression.DOOR_LOCKED or damage <= 0.0:
		_stress_door(damage * 0.5, "lock_glance")
		return
	_stress_door(damage * 2.4, "lock_housing")
	scar_level = clamp(scar_level + damage * 0.018, 0.0, 1.0)
	_update_scar_visual()

func _build_body(size: Vector3, color: Color) -> void:
	collision_shape = CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision_shape.shape = shape
	add_child(collision_shape)
	mesh_instance = MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _make_material(color, 0.0)
	add_child(mesh_instance)
	lock_housing = DoorLockHousing3D.new()
	lock_housing.name = "LockHousing"
	var side_offset := size.x * 0.38 if size.x >= size.z else 0.0
	lock_housing.setup(self, side_offset)
	add_child(lock_housing)

func _update_door_visual() -> void:
	if not mesh_instance:
		return
	var color := Color(0.16, 0.22, 0.24)
	var emission := 0.05
	if state == FacilityProgression.DOOR_OPEN:
		color = Color(0.1, 0.55, 0.38)
		emission = 0.5
	elif state == FacilityProgression.DOOR_JAMMED:
		color = Color(0.42, 0.22, 0.1)
		emission = 0.25
	elif state == FacilityProgression.DOOR_SEALED:
		color = Color(0.24, 0.05, 0.04)
		emission = 0.65
	mesh_instance.material_override = _make_material(color, emission)

func _make_material(color: Color, emission_energy: float) -> StandardMaterial3D:
	return EffectMaterialCache.get_material(color, emission_energy)
