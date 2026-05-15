extends ReactiveStaticBody3D
class_name FacilityDoor3D

signal door_forced_open(door_id: String)

var door_id: String = "door"
var state: String = "locked"
var force_work: float = 0.0
var mesh_instance: MeshInstance3D
var collision_shape: CollisionShape3D

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
		GameEvents.emit_environment_impulse(global_position, 1.4, 3.0, self, "door_forced_" + reason)

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
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission_energy
	return material
