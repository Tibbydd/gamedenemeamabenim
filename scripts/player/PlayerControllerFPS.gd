extends CharacterBody3D
class_name PlayerControllerFPS

signal died(reason: String)

var walk_speed: float = 5.2
var sprint_speed: float = 8.1
var crouch_speed: float = 2.9
var acceleration: float = 13.0
var air_control: float = 2.0
var gravity: float = 18.0
var stamina: float = 100.0
var max_stamina: float = 100.0
var stamina_recovery: float = 18.0
var sprint_stamina_cost: float = 24.0

var yaw: float = 0.0
var pitch: float = 0.0
var is_crouching: bool = false
var run_finished: bool = false
var noise_timer: float = 0.0

var head: Node3D
var camera: Camera3D
var collision_shape: CollisionShape3D
var capsule_shape: CapsuleShape3D
var weapon: WeaponController
var build_system: BuildPlacementSystem
var health: PlayerHealthBodyParts
var mental: MentalStateManager
var comms: CommsManager
var weapon_pivot: Node3D
var muzzle_marker: Node3D
var flashlight: SpotLight3D
var survivor_loadout: Dictionary = {}
var resources: Dictionary = {}
var weapon_slots: Array[Dictionary] = []
var equipped_weapon_slot: int = 0
var carry_capacity: int = 18
var wearable_modules: Dictionary = {}
var wearable_slots: Dictionary = {}
var has_headset: bool = false
var flashlight_type: String = "none"
var stealth_focus: bool = false
var weapon_dropped: bool = false
var equipped_weapon_id: String = "m7_colony_pistol"
var dropped_weapon_pickup: EquipmentPickup3D = null
var carried_object: DynamicObject3D = null
var weapon_default_position: Vector3 = Vector3(0.34, -0.34, -0.62)
var weapon_obstructed_position: Vector3 = Vector3(0.12, -0.12, -0.28)
var barrel_obstruction: float = 0.0
var barrel_push_side: float = 0.0
var recoil_recovery_pitch_remaining: float = 0.0
var recoil_recovery_yaw_remaining: float = 0.0
var weapon_kick_offset: Vector3 = Vector3.ZERO
var weapon_kick_rotation: Vector3 = Vector3.ZERO
var current_weapon_visual_id: String = ""
var hit_bob_timer: float = 0.0
var hit_bob_duration: float = 0.0
var hit_bob_strength: float = 0.0
var hit_bob_side: float = 0.0
var shove_cooldown: float = 0.0
var shove_cooldown_time: float = 0.85
var intro_lock_timer: float = 0.0
var intro_duration: float = 1.05
var intro_start_head_y: float = 1.08
var intro_start_roll: float = 0.0
var intro_message_active: bool = false
var notice_timer: float = 0.0
var notice_active: bool = false
var allow_restart: bool = false
var neural_anchor_active: bool = false
var neural_anchor_time: float = 0.0
var neural_anchor_required: float = 4.0
var glasses_lens_mesh: MeshInstance3D
var glasses_lens_damage: float = 0.0
var glasses_power_load: float = 0.0
var glasses_power_empty: bool = false
var glasses_power_accumulator: float = 0.0
var heartbeat_timer: float = 0.0
var last_path_sample_timer: float = 0.0
var survivor_path: Array[Vector3] = []
var event_log: Array[String] = []
var treatment_speed_modifier: float = 1.0
var pain_spread_modifier: float = 1.0
var recoil_trait_modifier: float = 1.0

var hud_layer: CanvasLayer
var ammo_label: Label
var body_label: Label
var status_label: Label
var inventory_label: Label
var comms_label: Label
var timer_label: Label
var compass_label: Label
var treatment_label: Label
var crosshair_label: Label
var end_label: Label
var debug_label: Label
var body_silhouette: BodySilhouetteHUD
var corruption_overlay: ColorRect
var debug_overlay_visible: bool = true

func _ready() -> void:
	add_to_group("player")
	gravity = ProjectSettings.get_setting("physics/3d/default_gravity", gravity)
	_build_collision()
	_build_camera()
	_build_systems()
	_build_hud()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _build_collision() -> void:
	collision_layer = 1
	collision_mask = 1 | 2
	capsule_shape = CapsuleShape3D.new()
	capsule_shape.radius = 0.34
	capsule_shape.height = 1.55
	collision_shape = CollisionShape3D.new()
	collision_shape.name = "BodyCollision"
	collision_shape.shape = capsule_shape
	collision_shape.position.y = 0.86
	add_child(collision_shape)

func _build_camera() -> void:
	head = Node3D.new()
	head.name = "Head"
	head.position.y = 1.58
	add_child(head)
	camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.current = true
	camera.fov = 75.0
	head.add_child(camera)
	_build_body_visual()
	_build_weapon_visual()

func _build_body_visual() -> void:
	# Body and head meshes are SHADOWS_ONLY so the FPS camera never sees them,
	# but the player still casts a real silhouette into the world for lighting
	# and external camera reviews. No collision is added here — the existing
	# capsule_shape already provides physical presence.
	var body = MeshInstance3D.new()
	body.name = "PlayerBodyShadow"
	var body_mesh = CapsuleMesh.new()
	body_mesh.radius = 0.34
	body_mesh.height = 1.5
	body.mesh = body_mesh
	body.position.y = 0.88
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	add_child(body)
	var head_silhouette = MeshInstance3D.new()
	head_silhouette.name = "PlayerHeadShadow"
	var head_mesh = SphereMesh.new()
	head_mesh.radius = 0.22
	head_mesh.height = 0.44
	head_silhouette.mesh = head_mesh
	head_silhouette.position.y = 1.7
	head_silhouette.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	add_child(head_silhouette)

func _build_weapon_visual() -> void:
	weapon_pivot = Node3D.new()
	weapon_pivot.name = "WeaponPivot"
	weapon_pivot.position = weapon_default_position
	camera.add_child(weapon_pivot)
	_add_weapon_box("PistolGrip", weapon_pivot, Vector3(0.19, 0.42, 0.18), Vector3(0.0, -0.18, 0.03), Color(0.06, 0.065, 0.07), 0.0, Vector3(-13.0, 0.0, 0.0))
	_add_weapon_box("MagazineBase", weapon_pivot, Vector3(0.21, 0.07, 0.22), Vector3(0.0, -0.43, 0.08), Color(0.035, 0.04, 0.045), 0.0, Vector3(-13.0, 0.0, 0.0))
	_add_weapon_box("LowerFrame", weapon_pivot, Vector3(0.25, 0.12, 0.48), Vector3(0.0, -0.04, -0.25), Color(0.09, 0.11, 0.115), 0.0)
	_add_weapon_box("Slide", weapon_pivot, Vector3(0.27, 0.17, 0.62), Vector3(0.0, 0.08, -0.34), Color(0.16, 0.19, 0.2), 0.0)
	_add_weapon_box("SlideTopPlane", weapon_pivot, Vector3(0.18, 0.025, 0.52), Vector3(0.0, 0.18, -0.34), Color(0.26, 0.31, 0.31), 0.08)
	_add_weapon_box("EjectionPort", weapon_pivot, Vector3(0.012, 0.055, 0.18), Vector3(0.141, 0.105, -0.28), Color(0.025, 0.03, 0.032), 0.0)
	_add_weapon_box("TriggerGuardFront", weapon_pivot, Vector3(0.035, 0.19, 0.035), Vector3(0.0, -0.17, -0.24), Color(0.04, 0.05, 0.055), 0.0, Vector3(10.0, 0.0, 0.0))
	_add_weapon_box("TriggerGuardBottom", weapon_pivot, Vector3(0.045, 0.035, 0.22), Vector3(0.0, -0.25, -0.13), Color(0.04, 0.05, 0.055), 0.0)
	_add_weapon_box("Trigger", weapon_pivot, Vector3(0.035, 0.13, 0.035), Vector3(0.0, -0.18, -0.08), Color(0.02, 0.025, 0.028), 0.0, Vector3(-18.0, 0.0, 0.0))
	_add_weapon_cylinder("PistolBarrel", weapon_pivot, 0.043, 0.42, Vector3(0.0, 0.09, -0.67), Color(0.42, 0.5, 0.49), 0.35, Vector3(90.0, 0.0, 0.0))
	_add_weapon_cylinder("MuzzleCrown", weapon_pivot, 0.057, 0.055, Vector3(0.0, 0.09, -0.91), Color(0.12, 0.15, 0.15), 0.12, Vector3(90.0, 0.0, 0.0))
	_add_weapon_box("FrontSight", weapon_pivot, Vector3(0.05, 0.045, 0.035), Vector3(0.0, 0.225, -0.62), Color(0.03, 0.04, 0.04), 0.05)
	_add_weapon_box("RearSight", weapon_pivot, Vector3(0.13, 0.04, 0.035), Vector3(0.0, 0.22, -0.08), Color(0.03, 0.04, 0.04), 0.05)
	_add_weapon_box("AccessoryRail", weapon_pivot, Vector3(0.18, 0.035, 0.28), Vector3(0.0, -0.115, -0.43), Color(0.055, 0.07, 0.075), 0.0)
	_add_weapon_capsule("RightHandGrip", weapon_pivot, 0.105, 0.28, Vector3(0.09, -0.25, 0.0), Color(0.55, 0.43, 0.34), 0.0, Vector3(-18.0, 0.0, 8.0))
	_add_weapon_capsule("LeftSupportHand", weapon_pivot, 0.095, 0.32, Vector3(-0.1, -0.13, -0.39), Color(0.52, 0.4, 0.32), 0.0, Vector3(78.0, 0.0, -12.0))
	muzzle_marker = Node3D.new()
	muzzle_marker.name = "Muzzle"
	muzzle_marker.position = Vector3(0.0, 0.09, -0.95)
	weapon_pivot.add_child(muzzle_marker)
	_build_glasses_lens()

func _refresh_weapon_view_model() -> void:
	if not weapon_pivot or not weapon or not weapon.data:
		return
	var visual_id: String = weapon.data.weapon_id
	if current_weapon_visual_id == visual_id:
		return
	current_weapon_visual_id = visual_id
	for child in weapon_pivot.get_children():
		if child is MeshInstance3D:
			child.queue_free()
	var family: String = weapon.data.weapon_family
	if family == "thermal":
		_build_thermal_view_weapon()
	elif family == "lmg":
		_build_long_view_weapon(1.28, 0.25, Color(0.12, 0.16, 0.17), true)
	elif family == "ar":
		_build_long_view_weapon(1.08, 0.18, Color(0.11, 0.14, 0.16), false)
	elif family == "smg":
		_build_smg_view_weapon()
	else:
		_build_sidearm_view_weapon()

func _build_sidearm_view_weapon() -> void:
	_add_weapon_box("SidearmGrip", weapon_pivot, Vector3(0.19, 0.42, 0.18), Vector3(0.0, -0.18, 0.03), Color(0.06, 0.065, 0.07), 0.0, Vector3(-13.0, 0.0, 0.0))
	_add_weapon_box("SidearmFrame", weapon_pivot, Vector3(0.25, 0.12, 0.48), Vector3(0.0, -0.04, -0.25), Color(0.09, 0.11, 0.115), 0.0)
	_add_weapon_box("SidearmSlide", weapon_pivot, Vector3(0.27, 0.17, 0.62), Vector3(0.0, 0.08, -0.34), Color(0.16, 0.19, 0.2), 0.0)
	_add_weapon_box("SidearmPort", weapon_pivot, Vector3(0.012, 0.055, 0.18), Vector3(0.141, 0.105, -0.28), Color(0.025, 0.03, 0.032), 0.0)
	_add_weapon_cylinder("SidearmBarrel", weapon_pivot, 0.043, 0.42, Vector3(0.0, 0.09, -0.67), Color(0.42, 0.5, 0.49), 0.28, Vector3(90.0, 0.0, 0.0))
	_add_weapon_box("SidearmSightRear", weapon_pivot, Vector3(0.13, 0.04, 0.035), Vector3(0.0, 0.22, -0.08), Color(0.03, 0.04, 0.04), 0.05)
	_add_weapon_box("SidearmSightFront", weapon_pivot, Vector3(0.05, 0.045, 0.035), Vector3(0.0, 0.225, -0.62), Color(0.03, 0.04, 0.04), 0.05)
	muzzle_marker.position = Vector3(0.0, 0.09, -0.95)
	_add_weapon_hands(Vector3(0.09, -0.25, 0.0), Vector3(-0.1, -0.13, -0.39))

func _build_smg_view_weapon() -> void:
	_add_weapon_box("SMGReceiver", weapon_pivot, Vector3(0.27, 0.22, 0.78), Vector3(0.0, 0.03, -0.34), Color(0.08, 0.1, 0.105), 0.0)
	_add_weapon_box("SMGTopRail", weapon_pivot, Vector3(0.2, 0.045, 0.64), Vector3(0.0, 0.18, -0.35), Color(0.16, 0.2, 0.2), 0.05)
	_add_weapon_box("SMGMag", weapon_pivot, Vector3(0.16, 0.46, 0.14), Vector3(0.0, -0.25, -0.22), Color(0.035, 0.04, 0.045), 0.0, Vector3(10.0, 0.0, 0.0))
	_add_weapon_box("SMGStock", weapon_pivot, Vector3(0.21, 0.13, 0.42), Vector3(0.0, 0.0, 0.18), Color(0.045, 0.055, 0.06), 0.0)
	_add_weapon_cylinder("SMGBarrel", weapon_pivot, 0.036, 0.48, Vector3(0.0, 0.07, -0.86), Color(0.36, 0.42, 0.42), 0.22, Vector3(90.0, 0.0, 0.0))
	_add_weapon_box("SMGForegrip", weapon_pivot, Vector3(0.11, 0.34, 0.12), Vector3(0.0, -0.25, -0.62), Color(0.05, 0.06, 0.065), 0.0, Vector3(5.0, 0.0, 0.0))
	muzzle_marker.position = Vector3(0.0, 0.07, -1.12)
	_add_weapon_hands(Vector3(0.1, -0.24, 0.02), Vector3(-0.11, -0.19, -0.58))

func _build_long_view_weapon(length: float, bulk: float, color: Color, heavy: bool) -> void:
	_add_weapon_box("LongReceiver", weapon_pivot, Vector3(0.28 + bulk * 0.18, 0.23 + bulk * 0.1, length * 0.54), Vector3(0.0, 0.04, -0.36), color, 0.0)
	_add_weapon_box("LongHandguard", weapon_pivot, Vector3(0.24 + bulk * 0.12, 0.2, length * 0.42), Vector3(0.0, -0.02, -0.78), color.darkened(0.18), 0.0)
	_add_weapon_box("LongStock", weapon_pivot, Vector3(0.28, 0.18, 0.48), Vector3(0.0, 0.0, 0.22), Color(0.045, 0.055, 0.06), 0.0)
	_add_weapon_box("LongMagazine", weapon_pivot, Vector3(0.17 + bulk * 0.12, 0.48 + bulk * 0.45, 0.16), Vector3(0.0, -0.34 - bulk * 0.18, -0.3), Color(0.035, 0.04, 0.045), 0.0, Vector3(7.0, 0.0, 0.0))
	_add_weapon_cylinder("LongBarrel", weapon_pivot, 0.035 + bulk * 0.035, length * 0.5, Vector3(0.0, 0.07, -1.1), Color(0.34, 0.39, 0.39), 0.18, Vector3(90.0, 0.0, 0.0))
	if heavy:
		_add_weapon_box("LMGFeedBox", weapon_pivot, Vector3(0.42, 0.34, 0.28), Vector3(-0.24, -0.13, -0.28), Color(0.06, 0.07, 0.07), 0.0)
		_add_weapon_cylinder("LMGHeatSleeve", weapon_pivot, 0.095, 0.62, Vector3(0.0, 0.06, -0.88), Color(0.16, 0.18, 0.18), 0.08, Vector3(90.0, 0.0, 0.0))
	_add_weapon_box("OpticBody", weapon_pivot, Vector3(0.16, 0.1, 0.24), Vector3(0.0, 0.24, -0.35), Color(0.04, 0.05, 0.05), 0.04)
	muzzle_marker.position = Vector3(0.0, 0.07, -1.38)
	_add_weapon_hands(Vector3(0.1, -0.26, 0.0), Vector3(-0.12, -0.17, -0.72))

func _build_thermal_view_weapon() -> void:
	_add_weapon_cylinder("ThermalFuelTank", weapon_pivot, 0.13, 0.68, Vector3(-0.2, -0.04, -0.28), Color(0.42, 0.16, 0.08), 0.08, Vector3(90.0, 0.0, 0.0))
	_add_weapon_box("ThermalValveBlock", weapon_pivot, Vector3(0.36, 0.2, 0.32), Vector3(0.0, 0.02, -0.35), Color(0.11, 0.13, 0.12), 0.0)
	_add_weapon_box("ThermalPilotCage", weapon_pivot, Vector3(0.28, 0.18, 0.2), Vector3(0.0, 0.04, -0.78), Color(0.18, 0.12, 0.07), 0.12)
	_add_weapon_cylinder("ThermalNozzle", weapon_pivot, 0.07, 0.58, Vector3(0.0, 0.05, -0.95), Color(0.58, 0.38, 0.16), 0.35, Vector3(90.0, 0.0, 0.0))
	_add_weapon_cylinder("ThermalHose", weapon_pivot, 0.035, 0.72, Vector3(0.16, -0.1, -0.35), Color(0.025, 0.03, 0.028), 0.0, Vector3(78.0, 16.0, 0.0))
	_add_weapon_box("ThermalIgniter", weapon_pivot, Vector3(0.08, 0.08, 0.06), Vector3(0.0, 0.12, -1.19), Color(1.0, 0.42, 0.08), 0.9)
	muzzle_marker.position = Vector3(0.0, 0.05, -1.22)
	_add_weapon_hands(Vector3(0.12, -0.25, -0.02), Vector3(-0.1, -0.16, -0.68))

func _add_weapon_hands(right_position: Vector3, left_position: Vector3) -> void:
	_add_weapon_capsule("RightHandGrip", weapon_pivot, 0.105, 0.28, right_position, Color(0.55, 0.43, 0.34), 0.0, Vector3(-18.0, 0.0, 8.0))
	_add_weapon_capsule("LeftSupportHand", weapon_pivot, 0.095, 0.32, left_position, Color(0.52, 0.4, 0.32), 0.0, Vector3(78.0, 0.0, -12.0))

func _add_weapon_box(mesh_name: String, parent: Node3D, size: Vector3, local_position: Vector3, color: Color, emission_energy: float = 0.0, rotation_degrees_value: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = mesh_name
	var mesh = BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = local_position
	mesh_instance.rotation_degrees = rotation_degrees_value
	mesh_instance.material_override = _make_weapon_material(color, emission_energy)
	parent.add_child(mesh_instance)
	return mesh_instance

func _add_weapon_cylinder(mesh_name: String, parent: Node3D, radius: float, height: float, local_position: Vector3, color: Color, emission_energy: float = 0.0, rotation_degrees_value: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = mesh_name
	var mesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 18
	mesh_instance.mesh = mesh
	mesh_instance.position = local_position
	mesh_instance.rotation_degrees = rotation_degrees_value
	mesh_instance.material_override = _make_weapon_material(color, emission_energy)
	parent.add_child(mesh_instance)
	return mesh_instance

func _add_weapon_capsule(mesh_name: String, parent: Node3D, radius: float, height: float, local_position: Vector3, color: Color, emission_energy: float = 0.0, rotation_degrees_value: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = mesh_name
	var mesh = CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 14
	mesh.rings = 6
	mesh_instance.mesh = mesh
	mesh_instance.position = local_position
	mesh_instance.rotation_degrees = rotation_degrees_value
	mesh_instance.material_override = _make_weapon_material(color, emission_energy)
	parent.add_child(mesh_instance)
	return mesh_instance

func _build_glasses_lens() -> void:
	glasses_lens_mesh = MeshInstance3D.new()
	glasses_lens_mesh.name = "DiagnosticLensDamage"
	var mesh = PlaneMesh.new()
	mesh.size = Vector2(0.95, 0.55)
	glasses_lens_mesh.mesh = mesh
	glasses_lens_mesh.position = Vector3(0.0, 0.0, -0.08)
	glasses_lens_mesh.visible = false
	camera.add_child(glasses_lens_mesh)
	_update_lens_material()

func _make_weapon_material(color: Color, emission_energy: float) -> StandardMaterial3D:
	return EffectMaterialCache.get_material(color, emission_energy)

func _build_systems() -> void:
	health = PlayerHealthBodyParts.new()
	health.name = "PlayerHealthBodyParts"
	add_child(health)
	health.died.connect(_on_health_died)
	health.damage_taken.connect(_on_damage_taken)
	mental = MentalStateManager.new()
	mental.name = "MentalStateManager"
	add_child(mental)
	weapon = WeaponController.new()
	weapon.name = "WeaponController"
	add_child(weapon)
	weapon.setup(self, camera, muzzle_marker, health, mental)
	weapon.recoil_requested.connect(_on_weapon_recoil_requested)
	weapon.condition_changed.connect(_on_weapon_condition_changed)
	build_system = BuildPlacementSystem.new()
	build_system.name = "BuildPlacementSystem"
	add_child(build_system)
	build_system.setup(self, camera)
	comms = CommsManager.new()
	comms.name = "CommsManager"
	add_child(comms)

func _build_hud() -> void:
	hud_layer = CanvasLayer.new()
	hud_layer.name = "PrototypeHUD"
	add_child(hud_layer)
	corruption_overlay = ColorRect.new()
	corruption_overlay.color = Color(0.1, 0.8, 0.9, 0.0)
	corruption_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	corruption_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud_layer.add_child(corruption_overlay)
	crosshair_label = Label.new()
	crosshair_label.text = "+"
	crosshair_label.add_theme_font_size_override("font_size", 28)
	crosshair_label.add_theme_color_override("font_color", Color(0.8, 1.0, 0.95))
	crosshair_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	hud_layer.add_child(crosshair_label)
	crosshair_label.visible = false
	var left_panel = VBoxContainer.new()
	left_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	left_panel.offset_left = 24.0
	left_panel.offset_top = 18.0
	left_panel.offset_right = 760.0
	left_panel.offset_bottom = 760.0
	hud_layer.add_child(left_panel)
	status_label = _make_hud_label("COGNITIVE LINK: STABLE  0%")
	inventory_label = _make_hud_label("LOADOUT: UNKNOWN")
	comms_label = _make_hud_label("COMMS: NO EARPIECE")
	timer_label = _make_hud_label("STATION TIME: 00:00")
	compass_label = _make_hud_label("COMPASS: --")
	ammo_label = _make_hud_label("M-7: 12 / 48")
	body_label = _make_hud_label("")
	body_silhouette = BodySilhouetteHUD.new()
	body_silhouette.name = "BodySilhouetteHUD"
	body_silhouette.custom_minimum_size = Vector2(190.0, 270.0)
	treatment_label = _make_hud_label("")
	debug_label = _make_hud_label("")
	left_panel.add_child(status_label)
	left_panel.add_child(inventory_label)
	left_panel.add_child(comms_label)
	left_panel.add_child(timer_label)
	left_panel.add_child(compass_label)
	left_panel.add_child(ammo_label)
	left_panel.add_child(body_silhouette)
	left_panel.add_child(body_label)
	left_panel.add_child(treatment_label)
	left_panel.add_child(debug_label)
	debug_label.visible = true
	end_label = _make_hud_label("")
	end_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	end_label.add_theme_font_size_override("font_size", 34)
	end_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	end_label.offset_left = -520.0
	end_label.offset_right = 520.0
	end_label.offset_top = -120.0
	end_label.offset_bottom = 120.0
	hud_layer.add_child(end_label)
	mental.setup(camera, corruption_overlay, status_label)
	comms.setup(mental, comms_label)

func _make_hud_label(text_value: String) -> Label:
	var label = Label.new()
	label.text = text_value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.75, 1.0, 0.95))
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	return label

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and not run_finished:
		yaw -= event.relative.x * InputBus.mouse_sensitivity
		var y_sign = -1.0 if InputBus.invert_y else 1.0
		pitch -= event.relative.y * InputBus.mouse_sensitivity * y_sign
		pitch = clamp(pitch, deg_to_rad(-82.0), deg_to_rad(82.0))
		rotation.y = yaw
		head.rotation.x = pitch
	if event is InputEventKey and event.keycode == KEY_X and not event.echo and not run_finished and intro_lock_timer <= 0.0:
		if event.pressed:
			neural_anchor_active = true
			neural_anchor_time = 0.0
		else:
			if neural_anchor_active and neural_anchor_time < 0.45:
				health.use_neural_stabilizer(mental)
				GameEvents.request_sound("interact", global_position, 0.6)
			neural_anchor_active = false
			neural_anchor_time = 0.0
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		elif event.keycode == KEY_ENTER:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		elif InputBus.wants_debug_overlay(event):
			debug_overlay_visible = true
			debug_label.visible = true
		elif not run_finished and intro_lock_timer <= 0.0 and InputBus.wants_interact(event):
			_try_interact()
		elif not run_finished and intro_lock_timer <= 0.0 and InputBus.wants_build_next(event):
			build_system.cycle_next()
		elif not run_finished and intro_lock_timer <= 0.0 and InputBus.wants_build_place(event):
			build_system.try_place()
		elif not run_finished and intro_lock_timer <= 0.0 and InputBus.wants_weapon_check(event):
			_manual_ammo_check()
		elif not run_finished and intro_lock_timer <= 0.0 and InputBus.wants_weapon_inspect(event):
			_inspect_weapon()
		elif not run_finished and intro_lock_timer <= 0.0 and _wants_weapon_slot(event):
			_equip_weapon_slot(_weapon_slot_from_event(event))
		elif not run_finished and intro_lock_timer <= 0.0 and InputBus.wants_reload(event):
			weapon.start_reload()
		elif not run_finished and intro_lock_timer <= 0.0 and InputBus.wants_quick_bandage(event):
			_try_quick_bleed_control()
		elif not run_finished and intro_lock_timer <= 0.0 and InputBus.wants_trauma_kit(event):
			_try_trauma_or_splint()
		elif not run_finished and intro_lock_timer <= 0.0 and InputBus.wants_injector(event):
			health.use_injector()
		elif not run_finished and intro_lock_timer <= 0.0 and InputBus.wants_shove(event):
			_try_shove()
		elif run_finished and allow_restart and InputBus.wants_restart(event):
			get_tree().reload_current_scene()

func _physics_process(delta: float) -> void:
	if run_finished or health.is_dead:
		velocity = Vector3.ZERO
		move_and_slide()
		return
	if intro_lock_timer > 0.0:
		intro_lock_timer = max(0.0, intro_lock_timer - delta)
		velocity = Vector3.ZERO
		move_and_slide()
		var intro_blend = smoothstep(0.0, 1.0, 1.0 - intro_lock_timer / intro_duration)
		head.position.y = lerp(intro_start_head_y, 1.58, intro_blend)
		camera.rotation.z = lerp(intro_start_roll, 0.0, intro_blend)
		weapon_pivot.position = weapon_obstructed_position.lerp(weapon_default_position, intro_blend)
		weapon_pivot.rotation = Vector3(deg_to_rad(-28.0 * (1.0 - intro_blend)), 0.0, 0.0)
		if intro_lock_timer <= 0.0 and intro_message_active:
			end_label.text = ""
			intro_message_active = false
		return
	var move_input = InputBus.get_move_vector()
	is_crouching = InputBus.wants_crouch()
	stealth_focus = InputBus.wants_stealth_walk()
	var wish_dir = (global_transform.basis * Vector3(move_input.x, 0.0, move_input.y)).normalized()
	var speed = _get_target_speed(move_input)
	if carried_object:
		speed *= 0.6
	var control = acceleration if is_on_floor() else air_control
	var target_velocity = wish_dir * speed
	velocity.x = lerp(velocity.x, target_velocity.x, clamp(control * delta, 0.0, 1.0))
	velocity.z = lerp(velocity.z, target_velocity.z, clamp(control * delta, 0.0, 1.0))
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = -0.05
	move_and_slide()
	_update_stamina(move_input, delta)
	_update_crouch(delta)
	_update_weapon_obstruction(delta)
	_update_carried_object()
	shove_cooldown = max(0.0, shove_cooldown - delta)
	_emit_movement_noise(delta, move_input, speed)

func _process(delta: float) -> void:
	if not run_finished and health and not health.is_dead:
		_sync_weapon_hand_state()
	_update_cognitive_anchor(delta)
	_update_blood_tunnel()
	_update_wearable_power(delta)
	_update_heartbeat(delta)
	_sample_survivor_path(delta)
	_update_hud()
	_update_debug_overlay()
	_update_notice(delta)
	_recover_recoil(delta)
	_update_hit_bob(delta)

func _update_cognitive_anchor(delta: float) -> void:
	if not neural_anchor_active:
		return
	if run_finished or health.is_dead or not InputBus.is_neural_stabilizer_held():
		neural_anchor_active = false
		neural_anchor_time = 0.0
		return
	neural_anchor_time += delta
	if neural_anchor_time < neural_anchor_required:
		return
	mental.reduce_corruption(35.0)
	if _visible_to_any_enemy():
		mental.add_corruption(25.0, "anchor_interrupted")
		_show_diegetic_notice("ANCHOR BROKEN\nSomething saw you.", 1.8)
	else:
		_show_diegetic_notice("BREATH CONTROL\nSignal steadied.", 1.6)
	GameEvents.request_sound("comms", global_position, 0.5)
	neural_anchor_active = false
	neural_anchor_time = 0.0

func _visible_to_any_enemy() -> bool:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is EnemyBase3D and enemy.senses and enemy.senses.can_see_player:
			return true
	return false

func _get_target_speed(move_input: Vector2) -> float:
	var movement_penalty = health.get_movement_modifier() * health.get_stamina_modifier()
	if is_crouching:
		return crouch_speed * movement_penalty
	if stealth_focus:
		return walk_speed * 0.48 * movement_penalty
	if InputBus.wants_sprint() and stamina > 1.0 and move_input.length() > 0.1:
		return sprint_speed * movement_penalty
	return walk_speed * movement_penalty

func _update_stamina(move_input: Vector2, delta: float) -> void:
	var sprinting = InputBus.wants_sprint() and move_input.length() > 0.1 and not is_crouching
	if sprinting:
		stamina = max(0.0, stamina - sprint_stamina_cost * delta)
	else:
		stamina = min(max_stamina, stamina + stamina_recovery * health.get_stamina_modifier() * delta)

func _update_crouch(delta: float) -> void:
	var target_head_y = 1.08 if is_crouching else 1.58
	head.position.y = lerp(head.position.y, target_head_y, delta * 10.0)
	capsule_shape.height = lerp(capsule_shape.height, 1.05 if is_crouching else 1.55, delta * 10.0)
	collision_shape.position.y = lerp(collision_shape.position.y, 0.62 if is_crouching else 0.86, delta * 10.0)

func _emit_movement_noise(delta: float, move_input: Vector2, speed: float) -> void:
	noise_timer -= delta
	if move_input.length() <= 0.1 or noise_timer > 0.0:
		return
	var loudness = 8.0
	if speed > walk_speed:
		loudness = 24.0
	elif stealth_focus and is_crouching:
		loudness = 0.55
	elif stealth_focus:
		loudness = 1.4
	elif is_crouching:
		loudness = 3.0
	loudness *= _get_surface_noise_modifier()
	if int(resources.get("boot_grips", 0)) > 0 and _get_surface_id_underfoot() in ["metal", "grate", "deck"]:
		loudness *= 0.5
	GameEvents.emit_player_noise(global_position, loudness)
	noise_timer = 0.62 if stealth_focus else (0.45 if is_crouching else 0.28)

func _get_surface_noise_modifier() -> float:
	var surface_id = _get_surface_id_underfoot()
	var profiles = StationSystemsCatalog.get_surface_profiles()
	if not profiles.has(surface_id):
		return 1.0
	return float(profiles[surface_id].get("noise", 1.0))

func _get_surface_id_underfoot() -> String:
	var start = global_position + Vector3.UP * 0.2
	var end = global_position + Vector3.DOWN * 0.75
	var query = PhysicsRayQueryParameters3D.create(start, end)
	query.exclude = [get_rid()]
	query.collision_mask = 1
	var hit = get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return "deck"
	var collider = hit.get("collider")
	if collider and collider.has_method("get_surface_id"):
		return String(collider.get_surface_id())
	return "deck"

func _update_hud() -> void:
	if not ammo_label:
		return
	var glasses_online: bool = has_wearable_module("hud_glasses") and not glasses_power_empty
	if glasses_lens_mesh:
		glasses_lens_mesh.visible = glasses_online and glasses_lens_damage > 0.04
	crosshair_label.visible = false
	status_label.visible = true
	inventory_label.visible = true
	comms_label.visible = true
	timer_label.visible = true
	compass_label.visible = true
	ammo_label.visible = true
	body_label.visible = true
	treatment_label.visible = true
	if body_silhouette:
		body_silhouette.visible = true
		body_silhouette.update_status(health, stamina, health.get_weapon_handling_state())
	if not weapon or not weapon.data:
		_force_weapon_ready(equipped_weapon_id)
	if weapon and weapon.data:
		ammo_label.text = "%s: %s" % [weapon.data.weapon_name, _get_diegetic_ammo_display()]
	else:
		ammo_label.text = "NO WEAPON"
	var body_text: String = "VITALS  STAM %d  BLOOD %d  PAIN %d  SHOCK %d\n" % [int(stamina), int(health.blood_volume), int(health.pain), int(health.shock)]
	if health.bleed_rate > 0.0:
		body_text += "BLEED %.1f/s  " % health.bleed_rate
	if health.burn_time > 0.0:
		body_text += "BURN %.0fs  " % health.burn_time
	if health.stimulant_time > 0.0:
		body_text += "STIM %.0fs  " % health.stimulant_time
	if has_wearable_module("sound_meter"):
		body_text += "SOUND %s  " % _get_estimated_noise_readout()
	if glasses_power_load > 3.0:
		body_text += "FRAME %.1fU  " % glasses_power_load
	if glasses_lens_damage > 0.15:
		body_text += "LENS %.0f%%  " % (glasses_lens_damage * 100.0)
	body_label.text = body_text
	if health.active_treatment.is_empty():
		var foul_text: String = "   BARREL FOULED" if barrel_obstruction > 0.55 else ""
		var stealth_text: String = "   STEALTH STEP" if stealth_focus else ""
		var build_text: String = ""
		if build_system:
			build_text = "   G %s   C NEXT" % build_system.get_selected_status()
		var anchor_text: String = "   X TAP/HOLD"
		if neural_anchor_active:
			anchor_text = "   X HOLD %.0f%%" % (neural_anchor_time / neural_anchor_required * 100.0)
		var carry_text: String = "   CARRYING" if carried_object else ""
		treatment_label.text = "E USE   LMB FIRE   R RELOAD   1-3 WEAPONS   F SHOVE/THROW   H MAG CHECK   I INSPECT   B BANDAGE   T TRAUMA   V INJECT" + anchor_text + build_text + foul_text + stealth_text + carry_text
	else:
		treatment_label.text = "TREATING: %s %.1fs" % [health.active_treatment.to_upper(), health.treatment_time_left]
	inventory_label.text = _get_inventory_summary()
	compass_label.text = _get_compass_summary()

func _get_diegetic_ammo_display() -> String:
	if not mental or mental.corruption < 70.0:
		return weapon.get_ammo_display()
	if randf() < 0.35:
		var false_count: int = max(0, weapon.current_ammo + randi_range(-3, 3))
		return "%d / %d" % [false_count, weapon.reserve_ammo]
	return weapon.get_ammo_display()

func _get_estimated_noise_readout() -> String:
	var value = _get_surface_noise_modifier()
	if mental and mental.corruption >= 60.0 and has_wearable_module("brainwave_reader"):
		value += randf_range(-0.45, 0.65)
	if value < 0.7:
		return "low"
	if value < 1.25:
		return "medium"
	return "high"

func _update_debug_overlay() -> void:
	if not debug_label or not debug_overlay_visible:
		return
	var enemy_lines: Array[String] = []
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is EnemyBase3D and enemy.brain:
			enemy_lines.append("%s:%s" % [enemy.archetype_id, str(enemy.brain.state)])
	var weapon_debug = "none"
	if weapon and weapon.data:
		weapon_debug = "%s %d/%d dropped:%s pivot:%s" % [
			weapon.data.weapon_id,
			weapon.current_ammo,
			weapon.reserve_ammo,
			str(weapon_dropped),
			str(weapon_pivot and weapon_pivot.visible)
		]
	debug_label.text = "DEBUG\nCORR %.0f  BLEED %.1f  ENEMIES %d\nWPN %s\n%s" % [
		mental.corruption if mental else 0.0,
		health.bleed_rate if health else 0.0,
		enemy_lines.size(),
		weapon_debug,
		_join_debug_lines(enemy_lines, 6)
	]

func _join_debug_lines(lines: Array[String], max_lines: int) -> String:
	var text = ""
	for index in range(min(lines.size(), max_lines)):
		if not text.is_empty():
			text += "\n"
		text += lines[index]
	return text

func _update_weapon_obstruction(delta: float) -> void:
	if not camera or not weapon_pivot:
		return
	var forward = -camera.global_transform.basis.z
	var wall_obstruction = _get_forward_obstruction(forward)
	var enemy_interference = _get_close_enemy_interference(forward)
	barrel_obstruction = max(wall_obstruction, enemy_interference.x)
	barrel_push_side = enemy_interference.y
	if wall_obstruction > enemy_interference.x:
		barrel_push_side = 0.0
	var target_position = weapon_default_position.lerp(weapon_obstructed_position, barrel_obstruction)
	if abs(barrel_push_side) > 0.01:
		target_position.x += barrel_push_side * barrel_obstruction * 0.18
	target_position += weapon_kick_offset
	weapon_pivot.position = weapon_pivot.position.lerp(target_position, clamp(delta * 14.0, 0.0, 1.0))
	var target_rotation = Vector3(
		deg_to_rad(-20.0 * barrel_obstruction),
		deg_to_rad(24.0 * barrel_push_side * barrel_obstruction),
		deg_to_rad(10.0 * barrel_push_side * barrel_obstruction)
	) + weapon_kick_rotation
	weapon_pivot.rotation = weapon_pivot.rotation.lerp(target_rotation, clamp(delta * 12.0, 0.0, 1.0))
	weapon.set_barrel_interference(barrel_obstruction, barrel_push_side)

func _get_forward_obstruction(forward: Vector3) -> float:
	var start = camera.global_position
	var end = start + forward * 1.15
	var query = PhysicsRayQueryParameters3D.create(start, end)
	query.exclude = [get_rid()]
	query.collision_mask = 1 | 2 | 4
	query.collide_with_areas = true
	query.collide_with_bodies = true
	var hit = get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return 0.0
	var distance = start.distance_to(hit.get("position"))
	return clamp(1.0 - distance / 1.15, 0.0, 1.0)

func _get_close_enemy_interference(forward: Vector3) -> Vector2:
	var best_amount = 0.0
	var best_side = 0.0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not (enemy is Node3D):
			continue
		var to_enemy: Vector3 = enemy.global_position + Vector3.UP - camera.global_position
		var distance = to_enemy.length()
		if distance > 1.35:
			continue
		var forward_dot = forward.dot(to_enemy.normalized())
		if forward_dot < 0.35:
			continue
		var local_enemy: Vector3 = camera.global_transform.affine_inverse() * (enemy.global_position as Vector3)
		var side: float = sign(local_enemy.x)
		if side == 0.0:
			side = barrel_push_side if abs(barrel_push_side) > 0.01 else 1.0
		var amount: float = clamp(1.0 - (distance - 0.35) / 1.0, 0.0, 1.0) * forward_dot
		if amount > best_amount:
			best_amount = amount
			best_side = side
	return Vector2(best_amount, best_side)

func _try_shove() -> void:
	if carried_object:
		_throw_carried_object()
		return
	if shove_cooldown > 0.0 or health.is_dead or not health.active_treatment.is_empty():
		return
	shove_cooldown = shove_cooldown_time
	GameEvents.emit_player_noise(global_position, 20.0)
	GameEvents.request_sound("interact", global_position, 0.9)
	var shoved = false
	var forward = -camera.global_transform.basis.z
	GameEvents.emit_environment_impulse(camera.global_position + forward * 1.0, 1.55, 9.0, self, "player_shove")
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not (enemy is Node3D):
			continue
		var to_enemy: Vector3 = enemy.global_position + Vector3.UP - camera.global_position
		var distance = to_enemy.length()
		if distance > 1.75:
			continue
		if forward.dot(to_enemy.normalized()) < 0.25:
			continue
		if enemy.has_method("apply_shove"):
			enemy.apply_shove(global_position, 7.5, 0.55)
			shoved = true
	if shoved:
		weapon_pivot.position += Vector3(0.0, 0.06, 0.08)

func _try_interact() -> void:
	if carried_object:
		_drop_carried_object()
		return
	var start = camera.global_position
	var forward = -camera.global_transform.basis.z
	var query = PhysicsRayQueryParameters3D.create(start, start + forward * 2.6)
	query.exclude = [get_rid()]
	query.collision_mask = 1 | 2 | 4
	query.collide_with_areas = true
	query.collide_with_bodies = true
	var hit = get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		GameEvents.emit_environment_impulse(start + forward * 1.2, 0.9, 2.5, self, "use_air_push")
		return
	var collider = hit.get("collider")
	var hit_position: Vector3 = start + forward * 2.6
	var raw_hit_position: Variant = hit.get("position", hit_position)
	if raw_hit_position is Vector3:
		hit_position = raw_hit_position
	if collider is DynamicObject3D and not (collider is EquipmentPickup3D) and not (collider is LostSurvivorKit3D):
		_start_carry_object(collider as DynamicObject3D)
		return
	if collider and collider.has_method("use"):
		collider.use(self)
		GameEvents.request_sound("interact", hit_position, 0.65)
	else:
		GameEvents.emit_environment_impulse(hit_position, 0.8, 2.5, self, "use_push")

func apply_survivor_loadout(loadout: Dictionary) -> void:
	survivor_loadout = loadout.duplicate(true)
	has_headset = bool(survivor_loadout.get("has_headset", false))
	flashlight_type = String(survivor_loadout.get("flashlight", "none"))
	wearable_modules.clear()
	wearable_slots.clear()
	glasses_power_empty = false
	glasses_lens_damage = float(survivor_loadout.get("glasses_lens_damage", 0.0))
	_apply_background_traits(String(survivor_loadout.get("background", "Survivor")))
	for module_id in survivor_loadout.get("wearable_modules", []):
		_install_wearable_module_internal(String(module_id), false)
	if weapon:
		equipped_weapon_id = String(survivor_loadout.get("weapon_id", equipped_weapon_id))
		weapon.equip_weapon(equipped_weapon_id)
		weapon.thermal_heat_ceiling = float(survivor_loadout.get("thermal_heat_ceiling", 120.0))
		weapon.add_reserve_ammo(int(survivor_loadout.get("extra_ammo", 0)))
		for attachment_id in survivor_loadout.get("weapon_attachments", []):
			weapon.install_attachment(String(attachment_id))
		_force_weapon_ready(equipped_weapon_id)
		weapon_slots.clear()
		_ensure_weapon_inventory()
		weapon_slots[equipped_weapon_slot] = weapon.get_weapon_state()
	resources = survivor_loadout.get("resources", {}).duplicate(true)
	if comms:
		comms.set_headset_equipped(has_headset)
	_setup_flashlight(flashlight_type)
	_update_lens_material()

func recover_lost_kit(loadout: Dictionary, contains_headset: bool) -> void:
	if contains_headset:
		has_headset = true
		if comms:
			comms.set_headset_equipped(true)
			comms.announce("Recovered your predecessor's earpiece. I am back.")
	for module_id in loadout.get("wearable_modules", []):
		install_wearable_module(String(module_id))
	if loadout.has("glasses_lens_damage"):
		glasses_lens_damage = max(glasses_lens_damage, float(loadout["glasses_lens_damage"]))
		_update_lens_material()
	if loadout.has("last_note"):
		_show_diegetic_notice("LAST NOTE\n%s" % String(loadout["last_note"]), 3.2)
	if has_wearable_module("route_mapper") and loadout.has("last_path"):
		_spawn_predecessor_ghost_route(loadout["last_path"])
	if weapon:
		if loadout.has("weapon_state"):
			equip_found_weapon_state(loadout["weapon_state"])
		var predecessor_weapon = String(loadout.get("weapon_id", ""))
		if not loadout.has("weapon_state") and not predecessor_weapon.is_empty() and predecessor_weapon != weapon.data.weapon_id:
			weapon.equip_weapon(predecessor_weapon)
			equipped_weapon_id = predecessor_weapon
			for attachment_id in loadout.get("weapon_attachments", []):
				weapon.install_attachment(String(attachment_id))
			_force_weapon_ready(predecessor_weapon)
			survivor_loadout["weapon_id"] = predecessor_weapon
			if comms:
				comms.announce("Recovered predecessor weapon: %s." % weapon.data.weapon_name)
		var recovered_ammo_type = String(loadout.get("recoverable_ammo_type", weapon.data.ammo_type))
		var recovered_ammo = int(loadout.get("recoverable_ammo", 12))
		if not weapon.add_reserve_ammo_for_type(recovered_ammo_type, recovered_ammo):
			add_resource("ammo_" + recovered_ammo_type, recovered_ammo)
	if build_system and int(loadout.get("recoverable_build_charge", 0)) > 0:
		var build_item = String(loadout.get("recoverable_build_item", "barricade_panel"))
		build_system.add_charge_to_item(build_item, int(loadout.get("recoverable_build_charge", 0)))
	var recovered_resources: Dictionary = {}
	var raw_recovered_resources: Variant = loadout.get("resources", {})
	if raw_recovered_resources is Dictionary:
		recovered_resources = raw_recovered_resources
	for key in recovered_resources.keys():
		add_resource(String(key), int(recovered_resources[key]))
	survivor_loadout["recovered_kit"] = true

func add_ammo_by_type(ammo_type: String, amount: int) -> void:
	if amount <= 0:
		return
	if weapon and weapon.add_reserve_ammo_for_type(ammo_type, amount):
		if comms:
			comms.announce("Recovered compatible ammunition.")
		return
	add_resource("ammo_" + ammo_type, amount)

func _try_quick_bleed_control() -> void:
	if int(resources.get("field_cauterizer_pen", 0)) > 0 and health.use_cauterizer():
		consume_resource("field_cauterizer_pen", 1)
		_show_diegetic_notice("BLEED CAUTERIZED\nPain spike.", 1.5)
		GameEvents.request_sound("hazard_steam", global_position, 0.35)
		return
	if health.start_quick_bandage():
		return

func _try_trauma_or_splint() -> void:
	if int(resources.get("splint_roll", 0)) > 0 and health.apply_splint_roll():
		consume_resource("splint_roll", 1)
		_show_diegetic_notice("SPLINT SET\nLimb usable, not whole.", 1.6)
		GameEvents.request_sound("interact", global_position, 0.7)
		return
	if int(resources.get("crash_kit", 0)) > 0:
		if health.start_trauma_kit(1.4 * treatment_speed_modifier):
			consume_resource("crash_kit", 1)
			return
	health.start_trauma_kit(3.0 * treatment_speed_modifier)

func equip_found_weapon(weapon_id: String) -> void:
	if weapon:
		equipped_weapon_id = weapon_id
		_replace_equipped_weapon_with_state(_make_weapon_state(equipped_weapon_id), true)
		_reinstall_known_cross_weapon_attachments()
		_force_weapon_ready(equipped_weapon_id)
		survivor_loadout["weapon_id"] = equipped_weapon_id
		survivor_loadout.erase("weapon_state")
		if comms:
			comms.announce("Weapon found: %s." % weapon.data.weapon_name)

func equip_found_weapon_state(state: Dictionary) -> void:
	if not weapon:
		return
	_replace_equipped_weapon_with_state(state, true)
	dropped_weapon_pickup = null
	survivor_loadout["weapon_id"] = weapon.data.weapon_id
	survivor_loadout["weapon_state"] = weapon.get_weapon_state()
	if comms:
		comms.announce("Recovered weapon: %s." % weapon.data.weapon_name)

func install_weapon_attachment(attachment_id: String) -> void:
	if not weapon:
		return
	if attachment_id == "retention_sling" and flashlight_type == "helmet":
		_show_diegetic_notice("SLOT CONFLICT\nHelmet lamp and sling snag the same shoulder arc.", 1.9)
		return
	var label = weapon.install_attachment(attachment_id)
	if label.is_empty():
		return
	var installed: Array = []
	var raw_installed: Variant = survivor_loadout.get("weapon_attachments", [])
	if raw_installed is Array:
		installed = raw_installed
	if not installed.has(attachment_id):
		installed.append(attachment_id)
	survivor_loadout["weapon_attachments"] = installed
	_show_diegetic_notice("ATTACHMENT INSTALLED\n%s" % label, 1.8)

func install_wearable_module(module_id: String) -> void:
	if not _install_wearable_module_internal(module_id, true):
		return
	var installed: Array = []
	var raw_installed: Variant = survivor_loadout.get("wearable_modules", [])
	if raw_installed is Array:
		installed = raw_installed
	if not installed.has(module_id):
		installed.append(module_id)
	survivor_loadout["wearable_modules"] = installed
	var label = StationSystemsCatalog.get_wearable_module_label(module_id)
	_show_diegetic_notice("MODULE INSTALLED\n%s" % label, 1.8)

func equip_found_flashlight(new_type: String) -> void:
	if new_type == "helmet" and weapon and weapon.has_attachment("retention_sling"):
		_show_diegetic_notice("SLOT CONFLICT\nRetention sling fouls a helmet lamp.", 1.8)
		return
	flashlight_type = new_type
	survivor_loadout["flashlight"] = new_type
	_setup_flashlight(new_type)
	if comms:
		comms.announce("Found light source attached: %s." % new_type.replace("_", " "))

func _install_wearable_module_internal(module_id: String, show_conflict: bool) -> bool:
	var slot = StationSystemsCatalog.get_wearable_module_slot(module_id)
	if slot == "glasses":
		wearable_slots[slot] = module_id
	elif slot == "glasses_module":
		var module_slots: Array = []
		var raw_module_slots: Variant = wearable_slots.get(slot, [])
		if raw_module_slots is Array:
			module_slots = raw_module_slots
		if not module_slots.has(module_id):
			module_slots.append(module_id)
		wearable_slots[slot] = module_slots
	else:
		if wearable_slots.has(slot) and String(wearable_slots[slot]) != module_id:
			if show_conflict:
				_show_diegetic_notice("SLOT OCCUPIED\n%s" % slot.replace("_", " "), 1.5)
			return false
		wearable_slots[slot] = module_id
	wearable_modules[module_id] = true
	if module_id == "hud_glasses":
		_update_lens_material()
	return true

func add_resource(resource_id: String, amount: int) -> void:
	if amount <= 0:
		return
	if _get_carried_units() + amount > carry_capacity:
		_show_diegetic_notice("INVENTORY FULL\nNeed %d free carry space." % amount, 1.5)
		return
	resources[resource_id] = int(resources.get(resource_id, 0)) + amount
	survivor_loadout["resources"] = resources
	if resource_id == "earpiece_patch" and has_headset and comms:
		consume_resource("earpiece_patch", 1)
		comms.apply_clean_patch(90.0)
	elif resource_id == "suppressor_wrap" and weapon:
		consume_resource("suppressor_wrap", 1)
		weapon.install_attachment("compact_suppressor")
	if comms:
		comms.announce("Recovered %s x%d." % [resource_id.replace("_", " "), amount])
	_log_event("picked up %s" % resource_id.replace("_", " "))

func consume_resource(resource_id: String, amount: int) -> bool:
	if amount <= 0:
		return true
	var current = int(resources.get(resource_id, 0))
	if current < amount:
		return false
	resources[resource_id] = current - amount
	survivor_loadout["resources"] = resources
	return true

func notify_service_failure(message: String) -> void:
	if comms:
		comms.announce(message)
	_show_diegetic_notice(message, 1.6)

func show_diegetic_notice(text: String, duration: float) -> void:
	_show_diegetic_notice(text, duration)

func has_wearable_module(module_id: String) -> bool:
	return bool(wearable_modules.get(module_id, false))

func get_visibility_modifier() -> float:
	var modifier = 0.78
	if flashlight:
		modifier += 0.35
	if has_wearable_module("low_light_filter") and not glasses_power_empty:
		modifier += 0.18
	if stealth_focus and is_crouching:
		modifier -= 0.12
	return clamp(modifier, 0.35, 1.45)

func had_headset_when_lost() -> bool:
	return has_headset

func _setup_flashlight(new_type: String) -> void:
	if flashlight:
		flashlight.queue_free()
		flashlight = null
	if new_type == "none":
		return
	flashlight = SpotLight3D.new()
	flashlight.name = "SurvivorFlashlight"
	flashlight.light_color = Color(0.82, 0.92, 1.0)
	flashlight.spot_range = 17.0
	flashlight.spot_angle = 28.0
	flashlight.light_energy = 2.2
	if new_type == "handheld":
		flashlight.position = Vector3(0.26, -0.22, -0.28)
		flashlight.rotation_degrees = Vector3(-2.0, 0.0, 0.0)
		camera.add_child(flashlight)
	elif new_type == "vest":
		flashlight.position = Vector3(0.22, -0.55, -0.18)
		flashlight.spot_angle = 42.0
		flashlight.light_energy = 1.7
		camera.add_child(flashlight)
	elif new_type == "helmet":
		flashlight.position = Vector3(0.0, 0.06, -0.18)
		flashlight.spot_angle = 34.0
		flashlight.light_energy = 2.5
		camera.add_child(flashlight)
	elif new_type == "weapon_mount":
		flashlight.position = Vector3(0.0, 0.03, -0.5)
		flashlight.spot_range = 14.0
		flashlight.spot_angle = 24.0
		weapon_pivot.add_child(flashlight)
	else:
		camera.add_child(flashlight)

func _get_inventory_summary() -> String:
	var background = String(survivor_loadout.get("background", "Survivor"))
	var light_text = flashlight_type.replace("_", " ").to_upper()
	var comms_text = "EARPIECE" if has_headset else "NO COMMS"
	var weapon_text = weapon.data.weapon_family.to_upper() if weapon and weapon.data else "NO WEAPON"
	var resource_count: int = _get_carried_units()
	for key in resources.keys():
		pass
	var route_noise = ""
	if mental and mental.corruption >= 70.0 and randf() < 0.08:
		route_noise = " / DOOR STATE: OPEN?"
	_ensure_weapon_inventory()
	var weapon_slots_text: Array[String] = []
	for index in range(weapon_slots.size()):
		var slot_prefix: String = ">"
		if index != equipped_weapon_slot:
			slot_prefix = " "
		weapon_slots_text.append("%s%d %s" % [slot_prefix, index + 1, _weapon_state_label(weapon_slots[index])])
	return "LOADOUT: %s / %s / %s / %s / CARRY %d/%d%s\n%s" % [background.to_upper(), weapon_text, light_text, comms_text, resource_count, carry_capacity, route_noise, "   ".join(weapon_slots_text)]

func _get_compass_summary() -> String:
	var forward = -global_transform.basis.z
	var angle = rad_to_deg(atan2(forward.x, forward.z))
	if angle < 0.0:
		angle += 360.0
	var directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
	var index = int(round(angle / 45.0)) % directions.size()
	return "COMPASS: %s %03d" % [directions[index], int(angle)]

func _wants_weapon_slot(event: InputEvent) -> bool:
	return event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_1, KEY_2, KEY_3]

func _weapon_slot_from_event(event: InputEvent) -> int:
	if not (event is InputEventKey):
		return -1
	if event.keycode == KEY_1:
		return 0
	if event.keycode == KEY_2:
		return 1
	if event.keycode == KEY_3:
		return 2
	return -1

func _ensure_weapon_inventory() -> void:
	while weapon_slots.size() < 3:
		weapon_slots.append({})
	if weapon and weapon.data and weapon_slots[equipped_weapon_slot].is_empty():
		weapon_slots[equipped_weapon_slot] = weapon.get_weapon_state()

func _update_equipped_weapon_slot_state() -> void:
	_ensure_weapon_inventory()
	if weapon and weapon.data and equipped_weapon_slot >= 0 and equipped_weapon_slot < weapon_slots.size():
		weapon_slots[equipped_weapon_slot] = weapon.get_weapon_state()

func _equip_weapon_slot(slot_index: int) -> void:
	_ensure_weapon_inventory()
	if slot_index < 0 or slot_index >= weapon_slots.size():
		return
	var slot_state: Dictionary = weapon_slots[slot_index]
	if slot_state.is_empty():
		_show_diegetic_notice("WEAPON SLOT EMPTY\nSlot %d has no weapon." % (slot_index + 1), 1.4)
		return
	if slot_index == equipped_weapon_slot:
		_show_diegetic_notice("EQUIPPED\n%s" % _weapon_state_label(slot_state), 1.1)
		return
	_update_equipped_weapon_slot_state()
	equipped_weapon_slot = slot_index
	weapon.apply_weapon_state(slot_state)
	equipped_weapon_id = weapon.data.weapon_id
	_force_weapon_ready(equipped_weapon_id)
	_show_diegetic_notice("EQUIPPED SLOT %d\n%s" % [slot_index + 1, weapon.data.weapon_name], 1.5)

func _replace_equipped_weapon_with_state(new_state: Dictionary, drop_old: bool) -> void:
	_ensure_weapon_inventory()
	_update_equipped_weapon_slot_state()
	if drop_old and weapon and weapon.data:
		_spawn_weapon_pickup_from_state(weapon.get_weapon_state(), global_position + -camera.global_transform.basis.z * 0.7 + Vector3.UP * 0.32)
	weapon.apply_weapon_state(new_state)
	equipped_weapon_id = weapon.data.weapon_id
	weapon_slots[equipped_weapon_slot] = weapon.get_weapon_state()
	_force_weapon_ready(equipped_weapon_id)

func _make_weapon_state(weapon_id: String) -> Dictionary:
	var weapon_data: WeaponData = WeaponData.create_weapon(weapon_id)
	return {
		"weapon_id": weapon_data.weapon_id,
		"current_ammo": weapon_data.magazine_size,
		"reserve_ammo": weapon_data.reserve_ammo,
		"chamber_loaded": true,
		"condition": 1.0,
		"attachments": {},
		"attachment_durability": {}
	}

func _weapon_state_label(state: Dictionary) -> String:
	if state.is_empty():
		return "EMPTY"
	var weapon_data: WeaponData = WeaponData.create_weapon(String(state.get("weapon_id", "m7_colony_pistol")))
	return "%s %d/%d" % [weapon_data.weapon_name, int(state.get("current_ammo", 0)), int(state.get("reserve_ammo", 0))]

func _get_carried_units() -> int:
	var total: int = 0
	for key in resources.keys():
		total += max(1, int(resources[key]))
	return total

func _sync_weapon_hand_state() -> void:
	if not weapon:
		return
	if not weapon.data:
		_force_weapon_ready(equipped_weapon_id)
		return
	if weapon_dropped:
		if weapon_pivot and weapon_pivot.visible and weapon.data:
			weapon_dropped = false
			dropped_weapon_pickup = null
			weapon.set_process(true)
		else:
			weapon.set_process(false)
			return
	if weapon.data:
		weapon.set_process(true)
		if weapon_pivot:
			weapon_pivot.visible = true

func _force_weapon_ready(fallback_weapon_id: String = "m7_colony_pistol") -> void:
	if not weapon:
		weapon = WeaponController.new()
		weapon.name = "WeaponController"
		add_child(weapon)
		weapon.setup(self, camera, muzzle_marker, health, mental)
		weapon.recoil_requested.connect(_on_weapon_recoil_requested)
		weapon.condition_changed.connect(_on_weapon_condition_changed)
	var resolved_weapon_id: String = fallback_weapon_id
	if resolved_weapon_id.is_empty():
		resolved_weapon_id = equipped_weapon_id
	if resolved_weapon_id.is_empty():
		resolved_weapon_id = "m7_colony_pistol"
	if not weapon.data:
		weapon.equip_weapon(resolved_weapon_id)
	equipped_weapon_id = weapon.data.weapon_id if weapon.data else resolved_weapon_id
	weapon_dropped = false
	dropped_weapon_pickup = null
	weapon.set_process(true)
	if weapon_pivot:
		weapon_pivot.visible = true
	_refresh_weapon_view_model()

func _has_weapon_in_hand() -> bool:
	if not weapon or not weapon.data:
		_force_weapon_ready(equipped_weapon_id)
	if weapon_dropped:
		_sync_weapon_hand_state()
	return weapon and weapon.data and not weapon_dropped

func _manual_ammo_check() -> void:
	if not _has_weapon_in_hand():
		_show_diegetic_notice("Your hands find no weapon.", 1.4)
		return
	var text = weapon.get_manual_ammo_check()
	if health.is_two_handed_compromised():
		text += "\nBad arm. The check is clumsy."
	_show_diegetic_notice(text, 1.8)

func _inspect_weapon() -> void:
	if not _has_weapon_in_hand():
		_show_diegetic_notice("Weapon is not in hand.", 1.4)
		return
	_show_diegetic_notice(weapon.get_inspection_text(), 2.6)

func can_operate_weapon() -> bool:
	return _has_weapon_in_hand() and not carried_object and health.can_hold_weapon()

func _on_damage_taken(part_name: String, amount: float, damage_type: String, result: Dictionary) -> void:
	if body_silhouette:
		body_silhouette.add_wound(part_name, amount, damage_type)
	_trigger_hit_bob(amount)
	_show_hit_notice(part_name, amount, damage_type)
	if part_name == PlayerHealthBodyParts.PART_HEAD and has_wearable_module("hud_glasses"):
		glasses_lens_damage = clamp(glasses_lens_damage + amount / 120.0, 0.0, 1.0)
		survivor_loadout["glasses_lens_damage"] = glasses_lens_damage
		_update_lens_material()
	if weapon_dropped or not [PlayerHealthBodyParts.PART_LEFT_ARM, PlayerHealthBodyParts.PART_RIGHT_ARM].has(part_name):
		return
	var drop_chance = 0.0
	if amount >= 24.0:
		drop_chance += 0.22
	if bool(result.get("fractured", false)):
		drop_chance += 0.18
	if bool(result.get("destroyed", false)):
		drop_chance += 0.5
	if weapon and weapon.has_attachment("retention_sling"):
		drop_chance *= 0.35
	if randf() < drop_chance:
		_drop_weapon("Impact shock tore the weapon loose.")
	_log_event("took %s damage to %s" % [str(int(amount)), part_name.replace("_", " ")])

func _trigger_hit_bob(amount: float) -> void:
	hit_bob_duration = 0.34
	hit_bob_timer = hit_bob_duration
	hit_bob_strength = clamp(amount / 38.0, 0.25, 1.0)
	hit_bob_side = -1.0 if randf() < 0.5 else 1.0

func _update_hit_bob(delta: float) -> void:
	if not camera:
		return
	if hit_bob_timer <= 0.0:
		camera.position = camera.position.lerp(Vector3.ZERO, clamp(delta * 12.0, 0.0, 1.0))
		if intro_lock_timer <= 0.0:
			camera.rotation.z = lerp(camera.rotation.z, 0.0, clamp(delta * 12.0, 0.0, 1.0))
		return
	hit_bob_timer = max(0.0, hit_bob_timer - delta)
	var progress: float = 1.0 - hit_bob_timer / max(0.01, hit_bob_duration)
	var wave: float = sin(progress * PI)
	camera.position = Vector3(hit_bob_side * 0.025 * hit_bob_strength * wave, -0.018 * hit_bob_strength * wave, 0.0)
	if intro_lock_timer <= 0.0:
		camera.rotation.z = hit_bob_side * deg_to_rad(3.4) * hit_bob_strength * wave

func _show_hit_notice(part_name: String, amount: float, damage_type: String) -> void:
	var text: String = "HIT: %s\n%s %.0f" % [part_name.replace("_", " ").to_upper(), damage_type.to_upper(), amount]
	if health.bleed_rate > 0.0:
		text += "   BLEED %.1f/s" % health.bleed_rate
	_show_diegetic_notice(text, 0.95)

func _drop_weapon(reason: String) -> void:
	if weapon_dropped or not weapon:
		return
	weapon.degrade_from_drop(0.04)
	var drop_state = weapon.get_weapon_state()
	dropped_weapon_pickup = _spawn_weapon_pickup_from_state(drop_state, global_position + -camera.global_transform.basis.z * 0.55 + Vector3.UP * 0.35)
	if dropped_weapon_pickup:
		var toss = -camera.global_transform.basis.z * 2.4 + Vector3.UP * 0.8
		dropped_weapon_pickup.apply_central_impulse(toss)
	_ensure_weapon_inventory()
	weapon_slots[equipped_weapon_slot] = {}
	weapon_dropped = true
	weapon.set_process(false)
	weapon_pivot.visible = false
	GameEvents.emit_player_noise(global_position, 12.0)
	_show_diegetic_notice("%s\nFind it on the floor." % reason, 2.4)

func _spawn_weapon_pickup_from_state(state: Dictionary, world_position: Vector3) -> EquipmentPickup3D:
	var scene = get_tree().current_scene
	if not scene:
		return null
	var pickup = EquipmentPickup3D.new()
	pickup.name = "DroppedWeapon_%s" % String(state.get("weapon_id", "weapon"))
	pickup.configure_weapon_state(state)
	scene.add_child(pickup)
	pickup.global_position = world_position
	return pickup

func _spawn_predecessor_ghost_route(packed_path: Array) -> void:
	var scene = get_tree().current_scene
	if not scene:
		return
	var step: int = max(1, int(packed_path.size() / 18))
	for index in range(0, packed_path.size(), step):
		var point_value = packed_path[index]
		if not (point_value is Array) or point_value.size() < 3:
			continue
		var marker = MeshInstance3D.new()
		marker.name = "PredecessorRouteMarker"
		var mesh = SphereMesh.new()
		mesh.radius = 0.055
		mesh.height = 0.11
		marker.mesh = mesh
		marker.material_override = EffectMaterialCache.get_material(Color(0.2, 0.9, 0.78), 0.8)
		scene.add_child(marker)
		marker.global_position = Vector3(float(point_value[0]), float(point_value[1]) + 0.08, float(point_value[2]))
		var tween = marker.create_tween()
		tween.tween_interval(45.0)
		tween.tween_property(marker, "scale", Vector3.ZERO, 0.6)
		tween.tween_callback(marker.queue_free)

func _start_carry_object(object: DynamicObject3D) -> void:
	if not object:
		return
	if object.mass > 8.0 and health.is_two_handed_compromised():
		_show_diegetic_notice("Both hands will not take the weight.", 1.5)
		return
	carried_object = object
	carried_object.begin_carry(self)
	if object.mass >= 8.0:
		object.add_to_group("heavy_pry_objects")
	_show_diegetic_notice("CARRYING\nF throws. E sets down.", 1.4)

func _update_carried_object() -> void:
	if not carried_object or not is_instance_valid(carried_object):
		carried_object = null
		return
	var target = camera.global_position + -camera.global_transform.basis.z * 1.75 + Vector3.DOWN * 0.28
	carried_object.update_carried(target)

func _drop_carried_object() -> void:
	if not carried_object:
		return
	carried_object.end_carry(Vector3.ZERO)
	carried_object = null
	GameEvents.request_sound("mag_drop", global_position, 0.45)

func _throw_carried_object() -> void:
	if not carried_object:
		return
	var throw_velocity = -camera.global_transform.basis.z * 9.0 + Vector3.UP * 1.2
	carried_object.end_carry(throw_velocity)
	GameEvents.emit_player_noise(global_position, 18.0)
	GameEvents.emit_environment_impulse(camera.global_position + -camera.global_transform.basis.z, 1.0, 4.0, self, "thrown_object")
	carried_object = null

func _show_diegetic_notice(text: String, duration: float) -> void:
	if not end_label or intro_message_active or run_finished:
		return
	end_label.text = text
	end_label.add_theme_color_override("font_color", Color(0.72, 1.0, 0.88))
	notice_timer = duration
	notice_active = true

func _update_notice(delta: float) -> void:
	if not notice_active or intro_message_active or run_finished:
		return
	notice_timer -= delta
	if notice_timer <= 0.0:
		end_label.text = ""
		notice_active = false

func _update_lens_material() -> void:
	if not glasses_lens_mesh:
		return
	var alpha: float = clamp(glasses_lens_damage * 0.42, 0.0, 0.48)
	var material = StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.18, 0.95, 0.88, alpha)
	material.emission_enabled = true
	material.emission = Color(0.08, 0.7, 0.7)
	material.emission_energy_multiplier = clamp(glasses_lens_damage * 0.9, 0.0, 0.9)
	material.roughness = 0.18 + glasses_lens_damage * 0.6
	glasses_lens_mesh.material_override = material

func _update_wearable_power(delta: float) -> void:
	glasses_power_load = 0.0
	if not has_wearable_module("hud_glasses"):
		glasses_power_empty = false
		return
	for module_id in wearable_modules.keys():
		glasses_power_load += StationSystemsCatalog.get_wearable_module_power(String(module_id))
	if glasses_power_load <= 3.0:
		glasses_power_empty = false
		return
	glasses_power_accumulator += delta * (glasses_power_load - 3.0)
	if glasses_power_accumulator < 22.0:
		return
	glasses_power_accumulator = 0.0
	if consume_resource("power_cell", 1):
		glasses_power_empty = false
		_show_diegetic_notice("GLASSES CELL SWAPPED\nModule frame still hot.", 1.4)
	else:
		glasses_power_empty = true
		_show_diegetic_notice("GLASSES POWER DEAD\nRemove modules or find a cell.", 1.8)

func _update_blood_tunnel() -> void:
	if not mental or not health:
		return
	var blood_loss: float = 1.0 - clamp(health.blood_volume / 100.0, 0.0, 1.0)
	mental.base_fov = 75.0 - blood_loss * 14.0

func _update_heartbeat(delta: float) -> void:
	if not health or not mental:
		return
	var arousal: float = clamp(health.pain / 120.0 + mental.corruption / 160.0 + (1.0 - health.blood_volume / 100.0), 0.0, 1.0)
	if arousal < 0.18:
		return
	heartbeat_timer -= delta
	if heartbeat_timer > 0.0:
		return
	heartbeat_timer = lerp(1.2, 0.38, arousal)
	GameEvents.request_sound("heartbeat", global_position, lerp(0.12, 0.75, arousal))

func _sample_survivor_path(delta: float) -> void:
	last_path_sample_timer -= delta
	if last_path_sample_timer > 0.0:
		return
	last_path_sample_timer = 1.0
	survivor_path.append(global_position)
	if survivor_path.size() > 120:
		survivor_path.remove_at(0)

func _log_event(text: String) -> void:
	event_log.append(text)
	if event_log.size() > 18:
		event_log.remove_at(0)

func build_last_note(death_reason: String) -> String:
	var weapon_name = weapon.data.weapon_name if weapon and weapon.data else "no weapon"
	var note = "%s died near %s with %s." % [
		String(survivor_loadout.get("background", "Survivor")),
		String(survivor_loadout.get("entry_reason", "unknown access")).replace("_", " "),
		weapon_name
	]
	if not event_log.is_empty():
		note += " Last useful memory: %s." % String(event_log[event_log.size() - 1])
	note += " Cause: %s." % death_reason
	return note

func get_last_path() -> Array[Vector3]:
	return survivor_path.duplicate()

func _apply_background_traits(background: String) -> void:
	treatment_speed_modifier = 1.0
	pain_spread_modifier = 1.0
	recoil_trait_modifier = 1.0
	var traits = StationSystemsCatalog.get_background_traits(background)
	if traits.has("treatment_speed"):
		treatment_speed_modifier = float(traits["treatment_speed"])
	if traits.has("pain_resistance"):
		pain_spread_modifier = float(traits["pain_resistance"])
	if traits.has("recoil_bonus"):
		recoil_trait_modifier = float(traits["recoil_bonus"])
	if traits.has("thermal_heat_ceiling"):
		survivor_loadout["thermal_heat_ceiling"] = float(traits["thermal_heat_ceiling"])
	if traits.has("resource_bonus"):
		var current_resources: Dictionary = {}
		var raw_current_resources: Variant = survivor_loadout.get("resources", {})
		if raw_current_resources is Dictionary:
			current_resources = raw_current_resources
		current_resources["tool_parts"] = int(current_resources.get("tool_parts", 0)) + int(traits["resource_bonus"])
		survivor_loadout["resources"] = current_resources

func _reinstall_known_cross_weapon_attachments() -> void:
	if not weapon:
		return
	for attachment_id in survivor_loadout.get("weapon_attachments", []):
		if String(attachment_id) == "ammo_telemetry_transmitter":
			weapon.install_attachment(String(attachment_id))

func _on_weapon_recoil_requested(pitch_radians: float, yaw_radians: float, rearward_kick: float) -> void:
	var pitch_kick = pitch_radians * recoil_trait_modifier
	var yaw_kick = yaw_radians * recoil_trait_modifier
	pitch = clamp(pitch + pitch_kick * 0.72, deg_to_rad(-82.0), deg_to_rad(82.0))
	yaw += yaw_kick * 0.35
	rotation.y = yaw
	head.rotation.x = pitch
	recoil_recovery_pitch_remaining += pitch_kick * 0.32
	recoil_recovery_yaw_remaining += yaw_kick * 0.18
	weapon_kick_offset += Vector3(0.0, rearward_kick * 0.1, rearward_kick)
	weapon_kick_rotation += Vector3(pitch_kick * 2.4, yaw_kick * 1.6, -yaw_kick * 1.2)

func _recover_recoil(delta: float) -> void:
	if recoil_recovery_pitch_remaining > 0.0001:
		var pitch_recovery: float = min(recoil_recovery_pitch_remaining, delta * 0.55)
		pitch = clamp(pitch - pitch_recovery, deg_to_rad(-82.0), deg_to_rad(82.0))
		head.rotation.x = pitch
		recoil_recovery_pitch_remaining -= pitch_recovery
	if abs(recoil_recovery_yaw_remaining) > 0.0001:
		var yaw_recovery: float = sign(recoil_recovery_yaw_remaining) * min(abs(recoil_recovery_yaw_remaining), delta * 0.28)
		yaw -= yaw_recovery
		rotation.y = yaw
		recoil_recovery_yaw_remaining -= yaw_recovery
	weapon_kick_offset = weapon_kick_offset.move_toward(Vector3.ZERO, delta * 0.45)
	weapon_kick_rotation = weapon_kick_rotation.move_toward(Vector3.ZERO, delta * 2.8)

func _on_weapon_condition_changed(condition: float) -> void:
	if not weapon_pivot:
		return
	var scar_amount: float = clamp((0.6 - condition) / 0.6, 0.0, 1.0)
	if scar_amount <= 0.0:
		return
	var material = EffectMaterialCache.get_material(Color(0.12, 0.13, 0.13).lerp(Color(0.38, 0.18, 0.12), scar_amount), scar_amount * 0.18)
	for child in weapon_pivot.get_children():
		if child is MeshInstance3D:
			(child as MeshInstance3D).material_override = material

func set_run_time(elapsed_seconds: float, exit_located: bool) -> void:
	if not timer_label:
		return
	var minutes = int(elapsed_seconds / 60.0)
	var seconds = int(elapsed_seconds) % 60
	var route_text = "EXIT LOCATED" if exit_located else "FIND A REAL EXIT"
	timer_label.text = "STATION TIME: %02d:%02d   %s   STAM %d" % [minutes, seconds, route_text, int(stamina)]

func show_end_state(success: bool, reason: String) -> void:
	run_finished = true
	allow_restart = true
	if weapon:
		weapon.set_process(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	end_label.text = ("%s\n%s\nPress R to restart" % ["FLOOR CLEARED" if success else "DEAD", reason])
	end_label.add_theme_color_override("font_color", Color(0.55, 1.0, 0.65) if success else Color(1.0, 0.25, 0.25))

func show_death_handoff(reason: String) -> void:
	run_finished = true
	allow_restart = false
	if weapon:
		weapon.set_process(false)
	end_label.text = "SURVIVOR LOST\n%s\nFacility state persists" % reason
	end_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25))

func play_spawn_intro(entry_text: String, intro_style: String = "door") -> void:
	run_finished = false
	allow_restart = false
	_configure_intro_style(intro_style)
	intro_lock_timer = intro_duration
	intro_message_active = true
	if head:
		head.position.y = intro_start_head_y
	if camera:
		camera.rotation.z = intro_start_roll
	if weapon_pivot:
		weapon_pivot.position = weapon_obstructed_position
		weapon_pivot.rotation = Vector3(deg_to_rad(-28.0), 0.0, 0.0)
	if weapon:
		weapon.set_process(true)
	if end_label:
		end_label.text = entry_text
		end_label.add_theme_color_override("font_color", Color(0.72, 1.0, 0.88))
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _configure_intro_style(intro_style: String) -> void:
	intro_duration = 1.05
	intro_start_head_y = 1.08
	intro_start_roll = 0.0
	if intro_style == "crawl":
		intro_duration = 1.25
		intro_start_head_y = 0.52
		intro_start_roll = deg_to_rad(-8.0)
	elif intro_style == "fall":
		intro_duration = 1.2
		intro_start_head_y = 3.05
		intro_start_roll = deg_to_rad(12.0)
	elif intro_style == "catwalk":
		intro_duration = 1.35
		intro_start_head_y = 2.65
		intro_start_roll = deg_to_rad(-20.0)
	elif intro_style == "shaft":
		intro_duration = 1.3
		intro_start_head_y = 2.45
		intro_start_roll = deg_to_rad(18.0)
	elif intro_style == "pod":
		intro_duration = 1.15
		intro_start_head_y = 1.0
		intro_start_roll = deg_to_rad(24.0)
	elif intro_style == "tumble":
		intro_duration = 1.4
		intro_start_head_y = 1.95
		intro_start_roll = deg_to_rad(-32.0)

func _on_health_died(reason: String) -> void:
	died.emit(reason)
