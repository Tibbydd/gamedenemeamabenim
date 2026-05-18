extends StaticBody3D
class_name NpcSurvivor3D

# Procedural humanoid NPC used for survivor encounters.
# Lives long enough to give the arena a sense of population and to test the
# NPC survivor encounter verbs from ImmersiveSimDesign.get_npc_survivor_encounters().

var encounter_id: String = "wounded_courier"
var role_label: String = "Courier"
var body_color: Color = Color(0.32, 0.36, 0.4)
var helped: bool = false
var killed: bool = false

func configure(new_encounter_id: String, new_role_label: String, new_color: Color) -> void:
	encounter_id = new_encounter_id
	role_label = new_role_label
	body_color = new_color
	name = "NpcSurvivor_%s" % encounter_id

func _ready() -> void:
	add_to_group("npc_survivors")
	# Layer 1 = world geometry, so both the player (mask 1|2) and enemies
	# (mask 1) treat the NPC as solid. No mask needed; the NPC doesn't move.
	collision_layer = 1
	collision_mask = 0
	_build_visuals()
	_build_collision()
	_build_interaction_label()

func _build_visuals() -> void:
	_add_capsule("NpcTorso", 0.3, 1.0, Vector3(0.0, 1.0, 0.0), body_color, 0.0)
	_add_box("NpcShoulders", Vector3(0.72, 0.12, 0.18), Vector3(0.0, 1.34, 0.0), body_color.lightened(0.08), 0.0)
	_add_box("NpcBelt", Vector3(0.52, 0.08, 0.18), Vector3(0.0, 0.55, -0.01), Color(0.07, 0.07, 0.065), 0.0)
	_add_capsule("NpcHead", 0.21, 0.36, Vector3(0.0, 1.73, -0.01), Color(0.74, 0.66, 0.6), 0.0)
	_add_box("NpcHairOrCap", Vector3(0.32, 0.075, 0.24), Vector3(0.0, 1.91, -0.015), body_color.darkened(0.3), 0.0)
	_add_capsule("NpcLeftArm", 0.065, 0.72, Vector3(-0.43, 1.03, 0.0), body_color.darkened(0.12), 0.0, Vector3(0.0, 0.0, -8.0))
	_add_capsule("NpcRightArm", 0.065, 0.72, Vector3(0.43, 1.03, 0.0), body_color.darkened(0.12), 0.0, Vector3(0.0, 0.0, 8.0))
	_add_sphere("NpcLeftHand", 0.08, Vector3(-0.49, 0.64, -0.04), Color(0.68, 0.55, 0.44), 0.0)
	_add_sphere("NpcRightHand", 0.08, Vector3(0.49, 0.64, -0.04), Color(0.68, 0.55, 0.44), 0.0)
	_add_capsule("NpcLeftLeg", 0.08, 0.72, Vector3(-0.15, 0.25, 0.02), Color(0.13, 0.15, 0.16), 0.0)
	_add_capsule("NpcRightLeg", 0.08, 0.72, Vector3(0.15, 0.25, 0.02), Color(0.13, 0.15, 0.16), 0.0)
	_add_box("NpcLeftBoot", Vector3(0.18, 0.07, 0.3), Vector3(-0.15, 0.04, -0.08), Color(0.035, 0.04, 0.04), 0.0)
	_add_box("NpcRightBoot", Vector3(0.18, 0.07, 0.3), Vector3(0.15, 0.04, -0.08), Color(0.035, 0.04, 0.04), 0.0)
	_add_box("NpcRoleMarker", Vector3(0.34, 0.055, 0.045), Vector3(0.0, 1.42, -0.22), body_color.lightened(0.25), 0.4)
	_add_role_prop()

func _add_role_prop() -> void:
	if role_label == "Engineer":
		_add_box("EngineerToolPouch", Vector3(0.22, 0.18, 0.12), Vector3(0.34, 0.6, 0.08), Color(0.42, 0.32, 0.16), 0.0)
	elif role_label == "Researcher":
		_add_box("ResearcherTablet", Vector3(0.22, 0.15, 0.025), Vector3(-0.2, 1.04, -0.29), Color(0.05, 0.12, 0.14), 0.25, Vector3(12.0, 0.0, -12.0))
	elif role_label == "Courier":
		_add_box("CourierSatchel", Vector3(0.38, 0.24, 0.12), Vector3(-0.34, 0.86, 0.11), Color(0.18, 0.12, 0.07), 0.0, Vector3(0.0, 0.0, -8.0))

func _build_collision() -> void:
	var collision := CollisionShape3D.new()
	collision.name = "NpcCollision"
	var shape := CapsuleShape3D.new()
	shape.radius = 0.36
	shape.height = 1.5
	collision.shape = shape
	collision.position.y = 0.86
	add_child(collision)

func _build_interaction_label() -> void:
	var label := Label3D.new()
	label.name = "NpcLabel"
	label.text = role_label
	label.position = Vector3(0.0, 2.05, 0.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = false
	label.modulate = Color(0.86, 0.94, 0.9)
	label.pixel_size = 0.004
	add_child(label)

func use(actor: Node) -> void:
	if killed or helped:
		return
	helped = true
	if actor and actor.has_method("show_diegetic_notice"):
		actor.show_diegetic_notice("%s acknowledges you." % role_label, 2.0)
	GameEvents.request_sound("interact", global_position, 0.6)

func _make_material(color: Color, emission_energy: float) -> StandardMaterial3D:
	return EffectMaterialCache.get_material(color, emission_energy)

func _add_box(mesh_name: String, size: Vector3, position: Vector3, color: Color, emission_energy: float = 0.0, rotation_degrees_value: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = mesh_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = position
	mesh_instance.rotation_degrees = rotation_degrees_value
	mesh_instance.material_override = _make_material(color, emission_energy)
	add_child(mesh_instance)
	return mesh_instance

func _add_capsule(mesh_name: String, radius: float, height: float, position: Vector3, color: Color, emission_energy: float = 0.0, rotation_degrees_value: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = mesh_name
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 14
	mesh.rings = 6
	mesh_instance.mesh = mesh
	mesh_instance.position = position
	mesh_instance.rotation_degrees = rotation_degrees_value
	mesh_instance.material_override = _make_material(color, emission_energy)
	add_child(mesh_instance)
	return mesh_instance

func _add_sphere(mesh_name: String, radius: float, position: Vector3, color: Color, emission_energy: float = 0.0) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = mesh_name
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 16
	mesh.rings = 8
	mesh_instance.mesh = mesh
	mesh_instance.position = position
	mesh_instance.material_override = _make_material(color, emission_energy)
	add_child(mesh_instance)
	return mesh_instance
