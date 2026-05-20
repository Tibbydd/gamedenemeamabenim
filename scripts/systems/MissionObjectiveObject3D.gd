extends StaticBody3D
class_name MissionObjectiveObject3D

signal objective_triggered(objective_id: String, objective_type: String, sector_id: String, position: Vector3)
signal objective_completed(objective_id: String, objective_type: String, sector_id: String, position: Vector3)
signal objective_progress_changed(objective_id: String, progress: float)

var objective_id: String = ""
var objective_type: String = "purge_node"
var sector_id: String = ""
var display_label: String = "Objective"
var sector_label: String = "Sector"
var status: String = "pending"
var integrity: float = 100.0
var max_integrity: float = 100.0
var hold_required: float = 0.0
var hold_progress: float = 0.0
var active_actor: Node = null
var sector_power: SectorPowerSystem = null
var mesh_root: Node3D
var core_mesh: MeshInstance3D
var accent_meshes: Array[MeshInstance3D] = []
var objective_light: OmniLight3D
var progress_bar: MeshInstance3D
var pulse_time: float = 0.0
var haze_pulse_timer: float = 8.0

func configure(definition: Dictionary, new_sector_power: SectorPowerSystem) -> void:
	objective_id = String(definition.get("id", "objective"))
	objective_type = String(definition.get("type", "purge_node"))
	sector_id = String(definition.get("sector_id", "arena"))
	display_label = String(definition.get("label", "Objective"))
	sector_label = String(definition.get("sector_label", sector_id.replace("_", " ")))
	sector_power = new_sector_power
	max_integrity = float(definition.get("integrity", 100.0))
	integrity = max_integrity
	hold_required = float(definition.get("hold_required", 0.0))
	_build_body()
	_update_visual_state()

func use(actor: Node) -> void:
	if status == "done":
		return
	_mark_triggered()
	if objective_type == "restore_power":
		if sector_power:
			sector_power.restore_sector(sector_id, "mission_restore")
		_complete_objective()
		return
	if objective_type == "uplink_terminal":
		active_actor = actor
		return
	if actor and actor.has_method("show_diegetic_notice"):
		actor.show_diegetic_notice("PURGE NODE\nDestroy the growth.", 1.2)

func receive_generic_hit(damage: float, hit_position: Vector3, hit_direction: Vector3) -> void:
	if status == "done":
		return
	_mark_triggered()
	if objective_type != "purge_node":
		GameEvents.emit_environment_impulse(hit_position, 0.5, max(1.0, damage * 0.08), self, "objective_panel_hit")
		return
	integrity = max(0.0, integrity - damage)
	GameEvents.emit_environment_impulse(hit_position, 1.0, max(2.0, damage * 0.16), self, "hive_node_hit")
	_update_visual_state()
	objective_progress_changed.emit(objective_id, get_progress())
	if integrity <= 0.0:
		_complete_objective()

func apply_environment_impulse(origin: Vector3, force: float, _radius: float, reason: String) -> void:
	if status == "done" or objective_type != "purge_node":
		return
	_mark_triggered()
	var impulse_damage: float = force * 0.65
	if reason.find("thermal") >= 0:
		impulse_damage *= 1.8
	integrity = max(0.0, integrity - impulse_damage)
	_update_visual_state()
	objective_progress_changed.emit(objective_id, get_progress())
	if integrity <= 0.0:
		_complete_objective()

func get_display_name() -> String:
	if status == "done":
		return "%s complete" % display_label
	if objective_type == "purge_node":
		var ratio: float = clamp(integrity / max(1.0, max_integrity), 0.0, 1.0)
		return "%s %.0f%%" % [display_label, ratio * 100.0]
	if objective_type == "uplink_terminal":
		if active_actor:
			return "Hold E: %s %.0f%%" % [display_label, _get_hold_ratio() * 100.0]
		return "Hold E: %s" % display_label
	return "%s" % display_label

func get_penetration_loss() -> float:
	if objective_type == "purge_node":
		return 14.0
	return 900.0

func _process(delta: float) -> void:
	pulse_time += delta
	if objective_light:
		var pulse: float = 0.5 + sin(pulse_time * 4.1) * 0.5
		var base_energy: float = 0.9
		if status == "active":
			base_energy = 1.55
		elif status == "done":
			base_energy = 0.35
		objective_light.light_energy = base_energy + pulse * 0.45
	if core_mesh:
		core_mesh.rotation.y += delta * (0.6 if objective_type == "purge_node" else 0.18)
	if objective_type == "purge_node" and status != "done":
		_update_hive_haze(delta)
	if objective_type == "uplink_terminal":
		_update_uplink_hold(delta)

func _update_uplink_hold(delta: float) -> void:
	if status == "done":
		return
	if not active_actor or not is_instance_valid(active_actor):
		hold_progress = max(0.0, hold_progress - delta * 1.4)
		_update_progress_bar()
		objective_progress_changed.emit(objective_id, get_progress())
		return
	var actor_node: Node3D = active_actor as Node3D
	if not actor_node or actor_node.global_position.distance_to(global_position) > 3.2 or not Input.is_key_pressed(KEY_E):
		active_actor = null
		hold_progress = max(0.0, hold_progress - delta * 1.4)
		_update_progress_bar()
		objective_progress_changed.emit(objective_id, get_progress())
		return
	hold_progress = min(hold_required, hold_progress + delta)
	_update_progress_bar()
	objective_progress_changed.emit(objective_id, get_progress())
	if hold_progress >= hold_required:
		_complete_objective()

func _update_hive_haze(delta: float) -> void:
	haze_pulse_timer -= delta
	if haze_pulse_timer > 0.0:
		return
	haze_pulse_timer = 8.0
	GameEvents.request_visibility_haze(global_position, 12.0, 3.5, 0.4)
	for node in get_tree().get_nodes_in_group("player"):
		if node is PlayerControllerFPS:
			var player: PlayerControllerFPS = node as PlayerControllerFPS
			if player.mental:
				player.mental.add_corruption(2.0, "hive_node")
			break

func _mark_triggered() -> void:
	if status != "pending":
		return
	status = "active"
	_update_visual_state()
	objective_progress_changed.emit(objective_id, get_progress())
	objective_triggered.emit(objective_id, objective_type, sector_id, global_position)
	GameEvents.request_sound("objective_alarm", global_position, 0.9)

func _complete_objective() -> void:
	if status == "done":
		return
	status = "done"
	active_actor = null
	hold_progress = hold_required
	collision_layer = 1
	_update_visual_state()
	objective_progress_changed.emit(objective_id, 1.0)
	objective_completed.emit(objective_id, objective_type, sector_id, global_position)
	GameEvents.request_sound("interact", global_position, 1.0)

func get_progress() -> float:
	if status == "done":
		return 1.0
	if objective_type == "purge_node":
		return clamp(1.0 - integrity / max(1.0, max_integrity), 0.0, 1.0)
	if objective_type == "uplink_terminal":
		return _get_hold_ratio()
	if objective_type == "restore_power":
		return 0.0
	return 0.0

func _get_hold_ratio() -> float:
	if hold_required <= 0.0:
		return 1.0
	return clamp(hold_progress / hold_required, 0.0, 1.0)

func _build_body() -> void:
	collision_layer = 1
	collision_mask = 0
	var collision: CollisionShape3D = CollisionShape3D.new()
	if objective_type == "purge_node":
		var sphere_shape: SphereShape3D = SphereShape3D.new()
		sphere_shape.radius = 0.82
		collision.shape = sphere_shape
		collision.position.y = 0.82
	else:
		var box_shape: BoxShape3D = BoxShape3D.new()
		box_shape.size = Vector3(1.0, 1.55, 0.45)
		collision.shape = box_shape
		collision.position.y = 0.78
	add_child(collision)
	mesh_root = Node3D.new()
	mesh_root.name = "ObjectiveVisual"
	add_child(mesh_root)
	if objective_type == "purge_node":
		_build_purge_node_visual()
	elif objective_type == "uplink_terminal":
		_build_uplink_visual()
	else:
		_build_power_visual()
	objective_light = OmniLight3D.new()
	objective_light.name = "ObjectiveLight"
	objective_light.omni_range = 7.0
	objective_light.shadow_enabled = true
	objective_light.position = Vector3(0.0, 1.4, 0.0)
	add_child(objective_light)

func _build_purge_node_visual() -> void:
	core_mesh = MeshInstance3D.new()
	var core: SphereMesh = SphereMesh.new()
	core.radius = 0.66
	core.height = 1.32
	core.radial_segments = 24
	core.rings = 12
	core_mesh.mesh = core
	core_mesh.position = Vector3(0.0, 0.82, 0.0)
	mesh_root.add_child(core_mesh)
	for index in range(8):
		var angle: float = float(index) / 8.0 * TAU
		var limb: MeshInstance3D = MeshInstance3D.new()
		var capsule: CapsuleMesh = CapsuleMesh.new()
		capsule.radius = 0.08
		capsule.height = 1.35
		limb.mesh = capsule
		limb.position = Vector3(cos(angle) * 0.58, 0.5, sin(angle) * 0.58)
		limb.rotation_degrees = Vector3(68.0, rad_to_deg(-angle), 0.0)
		mesh_root.add_child(limb)
		accent_meshes.append(limb)

func _build_uplink_visual() -> void:
	core_mesh = _add_box_mesh("UplinkTerminalBody", Vector3(0.95, 1.35, 0.34), Vector3(0.0, 0.72, 0.0), Color(0.08, 0.13, 0.15), 0.0)
	_add_box_mesh("UplinkScreen", Vector3(0.62, 0.32, 0.035), Vector3(0.0, 1.04, -0.19), Color(0.12, 0.72, 0.78), 0.8)
	_add_box_mesh("UplinkKeyboard", Vector3(0.68, 0.08, 0.26), Vector3(0.0, 0.56, -0.28), Color(0.025, 0.035, 0.04), 0.0)
	_add_cylinder_mesh("UplinkAntenna", 0.025, 0.85, Vector3(0.32, 1.74, 0.0), Color(0.42, 0.9, 0.88), 0.3, Vector3.ZERO)
	progress_bar = _add_box_mesh("UplinkProgress", Vector3(0.05, 0.04, 0.04), Vector3(-0.31, 1.26, -0.22), Color(0.22, 0.95, 0.82), 0.7)

func _build_power_visual() -> void:
	core_mesh = _add_box_mesh("PowerCouplerBody", Vector3(0.78, 1.22, 0.36), Vector3(0.0, 0.66, 0.0), Color(0.12, 0.1, 0.075), 0.0)
	_add_box_mesh("PowerBreakerHandle", Vector3(0.14, 0.62, 0.08), Vector3(0.0, 0.78, -0.24), Color(0.82, 0.52, 0.16), 0.25, Vector3(0.0, 0.0, -22.0))
	_add_box_mesh("PowerStatusPlate", Vector3(0.5, 0.18, 0.035), Vector3(0.0, 1.26, -0.205), Color(0.1, 0.6, 0.42), 0.5)
	for index in range(3):
		_add_cylinder_mesh("PowerCable%d" % index, 0.035, 0.82, Vector3(-0.26 + float(index) * 0.26, 0.16, 0.0), Color(0.04, 0.05, 0.05), 0.0, Vector3(90.0, 0.0, 0.0))

func _add_box_mesh(mesh_name: String, size: Vector3, local_position: Vector3, color: Color, emission: float, rotation_degrees_value: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.name = mesh_name
	var box: BoxMesh = BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	mesh_instance.position = local_position
	mesh_instance.rotation_degrees = rotation_degrees_value
	mesh_instance.material_override = EffectMaterialCache.get_material(color, emission)
	mesh_root.add_child(mesh_instance)
	accent_meshes.append(mesh_instance)
	return mesh_instance

func _add_cylinder_mesh(mesh_name: String, radius: float, height: float, local_position: Vector3, color: Color, emission: float, rotation_degrees_value: Vector3) -> MeshInstance3D:
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.name = mesh_name
	var cylinder: CylinderMesh = CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = height
	cylinder.radial_segments = 12
	mesh_instance.mesh = cylinder
	mesh_instance.position = local_position
	mesh_instance.rotation_degrees = rotation_degrees_value
	mesh_instance.material_override = EffectMaterialCache.get_material(color, emission)
	mesh_root.add_child(mesh_instance)
	accent_meshes.append(mesh_instance)
	return mesh_instance

func _update_visual_state() -> void:
	var color: Color = Color(0.86, 0.18, 0.13)
	var emission: float = 0.85
	if objective_type == "restore_power":
		color = Color(0.86, 0.58, 0.16)
	elif objective_type == "uplink_terminal":
		color = Color(0.16, 0.8, 0.9)
	if status == "active":
		emission = 1.35
	elif status == "done":
		color = Color(0.18, 0.86, 0.48)
		emission = 0.65
	if objective_light:
		objective_light.light_color = color
	if core_mesh:
		core_mesh.material_override = EffectMaterialCache.get_material(color.darkened(0.18), emission)
	for mesh_instance in accent_meshes:
		if mesh_instance and is_instance_valid(mesh_instance) and mesh_instance != core_mesh:
			var accent_color: Color = color.lerp(Color(0.04, 0.055, 0.06), 0.45)
			mesh_instance.material_override = EffectMaterialCache.get_material(accent_color, emission * 0.28)
	_update_progress_bar()

func _update_progress_bar() -> void:
	if not progress_bar:
		return
	var ratio: float = _get_hold_ratio()
	progress_bar.scale.x = max(0.06, ratio * 8.4)
	progress_bar.position.x = -0.31 + ratio * 0.31
