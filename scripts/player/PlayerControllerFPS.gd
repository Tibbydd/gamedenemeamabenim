extends CharacterBody3D
class_name PlayerControllerFPS

signal died(reason: String)

const MinimapHUDScene := preload("res://scripts/ui/MinimapHUD.gd")

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
var selected_role: String = "breacher"
var reload_speed_mult: float = 1.0
var movement_penalty_mult: float = 1.0
var footstep_noise_mult: float = 1.0
var damage_resist_mult: float = 0.0
var can_revive_corpses: bool = false
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
var recoil_hold_timer: float = 0.0
var weapon_kick_offset: Vector3 = Vector3.ZERO
var weapon_kick_rotation: Vector3 = Vector3.ZERO
var camera_shake: float = 0.0
var laser_dot: OmniLight3D = null
var current_weapon_visual_id: String = ""
var hit_bob_timer: float = 0.0
var hit_bob_duration: float = 0.0
var hit_bob_strength: float = 0.0
var hit_bob_side: float = 0.0
var head_bob_t: float = 0.0
var move_bob_offset: Vector3 = Vector3.ZERO
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
var run_kills: int = 0
var run_objectives_done: int = 0
var run_time_elapsed: float = 0.0
var debrief_screen: MissionDebriefScreen
var ambient_hum_player: AudioStreamPlayer

# --- Game feel: horror atmosphere ---
var _fear_level: float = 0.0
var _breath_timer: float = 0.0
var _heartbeat_pulse: float = 0.0
var _limp_t: float = 0.0
var flashlight_battery: float = 100.0
var _fl_flicker_timer: float = 0.0

# --- Game feel: camera/shake ---
var shake_noise: Vector3 = Vector3.ZERO
var shake_z_tilt: float = 0.0
var _recoil_tween: Tween = null

# --- Game feel: locomotion ---
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var _was_on_floor: bool = true
var _fall_peak_y: float = 0.0
var _landing_speed_penalty: float = 0.0
var _floor_wetness: float = 0.0

# --- Game feel: weapon sway ---
var _prev_yaw: float = 0.0
var _prev_pitch: float = 0.0
var _weapon_sway: Vector3 = Vector3.ZERO

# --- Game feel: extraction ---
var _extraction_available: bool = false
var _beacon_pulse_timer: float = 0.0

# --- Game feel: Sprint 3 ---
var _adrenaline_phase: int = 0
var _adrenaline_timer: float = 0.0
var _prev_nearest_enemy: float = 999.0
var _lissajous_t: float = 0.0
var _wristband_mesh: MeshInstance3D = null
var _wristband_mat: StandardMaterial3D = null
var _last_reload_press_time: float = -99.0

# --- Game feel: proximity indicator ---
var _proximity_rects: Array[ColorRect] = []

var damage_flash_timer: float = 0.0
var damage_flash_max: float = 0.0
var damage_flash_rect: ColorRect
var low_health_pulse_timer: float = 0.0

var jump_velocity: float = 5.4
var wants_jump_this_frame: bool = false
var is_prone: bool = false
var prone_iframes: float = 0.0
var prone_held_timer: float = 0.0
var prone_key_active: bool = false
var inventory_open: bool = false

var hud_layer: CanvasLayer
var status_label: Label
var comms_label: Label
var timer_label: Label
var interact_prompt_label: Label
var inventory_detail_label: Label
var end_label: Label
var debug_label: Label
var crosshair_label: Label
var body_silhouette: BodySilhouetteHUD
var corruption_overlay: ColorRect
var weapon_hologram: WeaponHologramHUD
var status_icons: StatusIconsHUD
var crosshair_ctrl: CrosshairControl
var glasses_overlay: GlassesOverlay
var objective_tracker: ObjectiveTrackerHUD
var minimap: Control
var objectives_cache: Array = []
var extraction_pos_cache: Vector3 = Vector3(9999.0, 0.0, 9999.0)
var blood_bar: ColorRect
var stamina_bar: ColorRect
var debug_overlay_visible: bool = true

func _ready() -> void:
	add_to_group("player")
	gravity = ProjectSettings.get_setting("physics/3d/default_gravity", gravity)
	_build_collision()
	_build_camera()
	_build_systems()
	_build_hud()
	_build_ambient_hum_player()
	_connect_run_accounting_events()
	GameEvents.extraction_available.connect(func(_pos: Vector3) -> void:
		_extraction_available = true
		_beacon_pulse_timer = 0.0
	)
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
	_build_wristband_vitals()

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
	weapon.shot_fired.connect(_on_shot_fired)
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

	# Corruption vignette overlay
	corruption_overlay = ColorRect.new()
	corruption_overlay.color = Color(0.1, 0.8, 0.9, 0.0)
	corruption_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	corruption_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud_layer.add_child(corruption_overlay)

	# Full-screen damage flash — red vignette that fades after taking a hit
	damage_flash_rect = ColorRect.new()
	damage_flash_rect.name = "DamageFlash"
	damage_flash_rect.color = Color(0.72, 0.0, 0.02, 0.0)
	damage_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	damage_flash_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud_layer.add_child(damage_flash_rect)

	# Glasses lens effect (vignette + corner brackets + scanline)
	glasses_overlay = GlassesOverlay.new()
	glasses_overlay.name = "GlassesOverlay"
	hud_layer.add_child(glasses_overlay)

	# Dynamic crosshair
	crosshair_ctrl = CrosshairControl.new()
	crosshair_ctrl.name = "CrosshairControl"
	hud_layer.add_child(crosshair_ctrl)
	crosshair_label = Label.new()  # dummy kept so external code has a Label ref

	# Interact prompt — center, below crosshair
	interact_prompt_label = Label.new()
	interact_prompt_label.text = ""
	interact_prompt_label.add_theme_font_size_override("font_size", 17)
	interact_prompt_label.add_theme_color_override("font_color", Color(0.85, 1.0, 0.9, 0.9))
	interact_prompt_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
	interact_prompt_label.add_theme_constant_override("shadow_offset_x", 1)
	interact_prompt_label.add_theme_constant_override("shadow_offset_y", 1)
	interact_prompt_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	interact_prompt_label.offset_top = 38.0
	interact_prompt_label.offset_bottom = 70.0
	interact_prompt_label.offset_left = -220.0
	interact_prompt_label.offset_right = 220.0
	interact_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_layer.add_child(interact_prompt_label)

	# TAB inventory panel — right side
	inventory_detail_label = Label.new()
	inventory_detail_label.text = ""
	inventory_detail_label.add_theme_font_size_override("font_size", 16)
	inventory_detail_label.add_theme_color_override("font_color", Color(0.78, 1.0, 0.88, 0.92))
	inventory_detail_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	inventory_detail_label.add_theme_constant_override("shadow_offset_x", 1)
	inventory_detail_label.add_theme_constant_override("shadow_offset_y", 1)
	inventory_detail_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	inventory_detail_label.offset_left = -440.0
	inventory_detail_label.offset_right = -20.0
	inventory_detail_label.offset_top = -300.0
	inventory_detail_label.offset_bottom = 300.0
	inventory_detail_label.visible = false
	hud_layer.add_child(inventory_detail_label)

	# Weapon hologram — beside weapon, center-right
	weapon_hologram = WeaponHologramHUD.new()
	weapon_hologram.name = "WeaponHologram"
	hud_layer.add_child(weapon_hologram)
	weapon.ammo_changed.connect(_on_weapon_ammo_changed)
	weapon.condition_changed.connect(_on_weapon_condition_changed_hud)

	# Status icons — bottom-center
	status_icons = StatusIconsHUD.new()
	status_icons.name = "StatusIconsHUD"
	hud_layer.add_child(status_icons)

	# Body silhouette — bottom-left, small Tarkov-style
	body_silhouette = BodySilhouetteHUD.new()
	body_silhouette.name = "BodySilhouetteHUD"
	body_silhouette.custom_minimum_size = Vector2(90.0, 135.0)
	body_silhouette.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	body_silhouette.offset_left = 16.0
	body_silhouette.offset_right = 106.0
	body_silhouette.offset_top = -151.0
	body_silhouette.offset_bottom = -16.0
	hud_layer.add_child(body_silhouette)

	# Thin vertical vitals bars beside the silhouette
	blood_bar = ColorRect.new()
	blood_bar.color = Color(0.82, 0.08, 0.08, 0.78)
	blood_bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	blood_bar.offset_left = 112.0
	blood_bar.offset_right = 116.0
	blood_bar.offset_bottom = -16.0
	blood_bar.offset_top = -96.0
	hud_layer.add_child(blood_bar)
	stamina_bar = ColorRect.new()
	stamina_bar.color = Color(0.72, 0.88, 0.22, 0.72)
	stamina_bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	stamina_bar.offset_left = 120.0
	stamina_bar.offset_right = 124.0
	stamina_bar.offset_bottom = -16.0
	stamina_bar.offset_top = -96.0
	hud_layer.add_child(stamina_bar)

	# Status text — top-left (minimal: contamination status + time)
	status_label = _make_hud_label("")
	status_label.add_theme_font_size_override("font_size", 13)
	status_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	status_label.offset_left = 22.0
	status_label.offset_top = 18.0
	status_label.offset_right = 480.0
	status_label.offset_bottom = 38.0
	hud_layer.add_child(status_label)

	timer_label = _make_hud_label("")
	timer_label.add_theme_font_size_override("font_size", 13)
	timer_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	timer_label.offset_left = 22.0
	timer_label.offset_top = 34.0
	timer_label.offset_right = 340.0
	timer_label.offset_bottom = 54.0
	hud_layer.add_child(timer_label)

	objective_tracker = ObjectiveTrackerHUD.new()
	objective_tracker.name = "ObjectiveTrackerHUD"
	objective_tracker.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	objective_tracker.offset_left = 22.0
	objective_tracker.offset_top = 58.0
	objective_tracker.offset_right = 452.0
	objective_tracker.offset_bottom = 178.0
	hud_layer.add_child(objective_tracker)

	minimap = MinimapHUDScene.new()
	minimap.name = "MinimapHUD"
	minimap.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	minimap.offset_left = -112.0
	minimap.offset_right = -12.0
	minimap.offset_top = -112.0
	minimap.offset_bottom = -12.0
	hud_layer.add_child(minimap)
	_connect_objective_events()

	comms_label = _make_hud_label("")
	comms_label.add_theme_font_size_override("font_size", 13)
	comms_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	comms_label.offset_left = -380.0
	comms_label.offset_top = 18.0
	comms_label.offset_right = -20.0
	comms_label.offset_bottom = 54.0
	comms_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hud_layer.add_child(comms_label)

	# Debug overlay — top-left below status
	debug_label = _make_hud_label("")
	debug_label.add_theme_font_size_override("font_size", 13)
	debug_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	debug_label.offset_left = 22.0
	debug_label.offset_top = 184.0
	debug_label.offset_right = 760.0
	debug_label.offset_bottom = 400.0
	debug_label.visible = false
	hud_layer.add_child(debug_label)

	# End state label — screen center
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

	# Proximity danger indicator — 4 screen-edge strips that pulse red when
	# an enemy is very close but not in FOV (threat compass)
	var prox_anchors := [
		[Control.PRESET_TOP_WIDE, 0.0, 0.0, 0.0, 10.0],
		[Control.PRESET_BOTTOM_WIDE, 0.0, -10.0, 0.0, 0.0],
		[Control.PRESET_LEFT_WIDE, 0.0, 0.0, 10.0, 0.0],
		[Control.PRESET_RIGHT_WIDE, -10.0, 0.0, 0.0, 0.0],
	]
	for cfg in prox_anchors:
		var r := ColorRect.new()
		r.color = Color(0.85, 0.08, 0.05, 0.0)
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		r.set_anchors_and_offsets_preset(int(cfg[0]))
		r.offset_left = float(cfg[1])
		r.offset_top = float(cfg[2])
		r.offset_right = float(cfg[3])
		r.offset_bottom = float(cfg[4])
		hud_layer.add_child(r)
		_proximity_rects.append(r)

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

func _build_ambient_hum_player() -> void:
	var stream: AudioStream = SoundSynthesizer.get_stream("ambient_hum")
	if not (stream is AudioStreamWAV):
		return
	var hum_stream: AudioStreamWAV = stream as AudioStreamWAV
	hum_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	hum_stream.loop_begin = 0
	hum_stream.loop_end = max(0, int(hum_stream.data.size() / 2) - 1)
	ambient_hum_player = AudioStreamPlayer.new()
	ambient_hum_player.name = "AmbientHumPlayer"
	ambient_hum_player.stream = hum_stream
	ambient_hum_player.volume_db = linear_to_db(0.18)
	if hud_layer:
		hud_layer.add_child(ambient_hum_player)
	else:
		add_child(ambient_hum_player)
	ambient_hum_player.play()

func _connect_objective_events() -> void:
	var assigned_callable: Callable = Callable(self, "_on_objectives_assigned")
	if not GameEvents.objectives_assigned.is_connected(assigned_callable):
		GameEvents.objectives_assigned.connect(assigned_callable)
	var updated_callable: Callable = Callable(self, "_on_objectives_updated")
	if not GameEvents.objectives_updated.is_connected(updated_callable):
		GameEvents.objectives_updated.connect(updated_callable)
	var extraction_callable: Callable = Callable(self, "_on_extraction_available")
	if not GameEvents.extraction_available.is_connected(extraction_callable):
		GameEvents.extraction_available.connect(extraction_callable)

func _connect_run_accounting_events() -> void:
	var enemy_callable: Callable = Callable(self, "_on_enemy_killed_for_debrief")
	if not GameEvents.enemy_killed.is_connected(enemy_callable):
		GameEvents.enemy_killed.connect(enemy_callable)
	var objective_callable: Callable = Callable(self, "_on_objective_completed_for_debrief")
	if not GameEvents.objective_completed.is_connected(objective_callable):
		GameEvents.objective_completed.connect(objective_callable)
	var run_callable: Callable = Callable(self, "_on_run_ended_for_debrief")
	if not GameEvents.run_ended.is_connected(run_callable):
		GameEvents.run_ended.connect(run_callable)

func _on_enemy_killed_for_debrief(_enemy: Node, _cause: String) -> void:
	if not run_finished:
		run_kills += 1

func _on_objective_completed_for_debrief(_objective_id: String, _objective_type: String, _sector_id: String, _position: Vector3) -> void:
	if not run_finished:
		run_objectives_done += 1

func _on_run_ended_for_debrief(success: bool, reason: String) -> void:
	_show_mission_debrief(success, reason)

func _play_reload_dip() -> void:
	if not weapon_pivot or not weapon or not weapon.is_reloading:
		return
	var start_y: float = weapon_pivot.position.y
	var tween: Tween = weapon_pivot.create_tween()
	tween.tween_property(weapon_pivot, "position:y", start_y - 0.08, 0.12).set_ease(Tween.EASE_IN)
	tween.tween_property(weapon_pivot, "position:y", start_y, 0.22).set_ease(Tween.EASE_OUT)

func _on_objectives_assigned(objectives: Array) -> void:
	objectives_cache = objectives.duplicate(true)
	if objective_tracker:
		objective_tracker.set_objectives(objectives)

func _on_objectives_updated(objectives: Array) -> void:
	objectives_cache = objectives.duplicate(true)
	if objective_tracker:
		objective_tracker.set_objectives(objectives)

func _on_extraction_available(world_position: Vector3) -> void:
	extraction_pos_cache = world_position
	if objective_tracker:
		objective_tracker.set_extraction_available(world_position)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and not run_finished:
		yaw -= event.relative.x * InputBus.mouse_sensitivity
		var y_sign = -1.0 if InputBus.invert_y else 1.0
		pitch -= event.relative.y * InputBus.mouse_sensitivity * y_sign
		pitch = clamp(pitch, deg_to_rad(-82.0), deg_to_rad(82.0))
		rotation.y = yaw
		head.rotation.x = pitch
	if event is InputEventKey and event.keycode == KEY_Z and not run_finished and intro_lock_timer <= 0.0:
		if event.pressed and not event.echo:
			prone_key_active = true
			if is_prone:
				is_prone = false
				prone_held_timer = 0.0
		elif not event.pressed:
			prone_key_active = false
			prone_held_timer = 0.0
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE and not run_finished and intro_lock_timer <= 0.0:
		jump_buffer_timer = 0.15  # buffered jump — fires within 0.15s of landing
		wants_jump_this_frame = true
		return
	if InputBus.wants_inventory(event) and not run_finished:
		inventory_open = not inventory_open
		if inventory_detail_label:
			inventory_detail_label.visible = inventory_open
			if inventory_open:
				inventory_detail_label.text = _build_inventory_text()
		return
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
		elif event.keycode == KEY_G and not run_finished and intro_lock_timer <= 0.0:
			if flashlight:
				flashlight.visible = not flashlight.visible
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
			var now_sec := Time.get_ticks_msec() / 1000.0
			var is_double_tap := (now_sec - _last_reload_press_time) < 0.28
			_last_reload_press_time = now_sec
			if is_double_tap and weapon.current_ammo > 0 and not weapon.is_reloading:
				if weapon.panic_reload():
					AudioRouter.play_ui("reload_click")
					_play_reload_dip()
			elif not weapon.is_reloading:
				if weapon.start_reload():
					AudioRouter.play_ui("reload_click")
					_play_reload_dip()
		elif not run_finished and intro_lock_timer <= 0.0 and InputBus.wants_quick_bandage(event):
			_try_quick_bleed_control()
		elif not run_finished and intro_lock_timer <= 0.0 and InputBus.wants_trauma_kit(event):
			_try_trauma_or_splint()
		elif not run_finished and intro_lock_timer <= 0.0 and InputBus.wants_injector(event):
			health.use_injector()
		elif not run_finished and intro_lock_timer <= 0.0 and InputBus.wants_role_ability(event):
			_use_role_ability()
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
	if not is_prone:
		is_crouching = InputBus.wants_crouch()
	stealth_focus = InputBus.wants_stealth_walk()
	if prone_iframes > 0.0:
		prone_iframes = max(0.0, prone_iframes - delta)
	if prone_key_active and not is_prone and is_on_floor():
		prone_held_timer += delta
		if prone_held_timer >= 0.22:
			_start_prone_dive()
	elif not prone_key_active:
		prone_held_timer = 0.0
	var wish_dir = (global_transform.basis * Vector3(move_input.x, 0.0, move_input.y)).normalized()
	var speed = _get_target_speed(move_input)
	if carried_object:
		speed *= 0.6
	var control = acceleration if is_on_floor() else air_control
	var target_velocity = wish_dir * speed
	velocity.x = lerp(velocity.x, target_velocity.x, clamp(control * delta, 0.0, 1.0))
	velocity.z = lerp(velocity.z, target_velocity.z, clamp(control * delta, 0.0, 1.0))
	# Coyote time — allow jumping briefly after stepping off a ledge
	coyote_timer = 0.10 if is_on_floor() else max(0.0, coyote_timer - delta)
	jump_buffer_timer = max(0.0, jump_buffer_timer - delta)
	if not is_on_floor():
		# Apex gravity halving — floaty peak that lets players clear obstacles
		var at_apex: bool = abs(velocity.y) < 1.8
		velocity.y -= gravity * (0.48 if at_apex else 1.0) * delta
	else:
		if jump_buffer_timer > 0.0 and not is_crouching and not is_prone:
			velocity.y = jump_velocity
			coyote_timer = 0.0
			jump_buffer_timer = 0.0
		else:
			velocity.y = -0.05
	wants_jump_this_frame = false
	move_and_slide()
	_update_fall_tracking()
	_update_stamina(move_input, delta)
	_update_crouch(delta)
	_update_weapon_obstruction(delta)
	_update_carried_object()
	shove_cooldown = max(0.0, shove_cooldown - delta)
	_update_role_ability_timers(delta)
	_emit_movement_noise(delta, move_input, speed)

func _process(delta: float) -> void:
	if not run_finished and health and not health.is_dead:
		_sync_weapon_hand_state()
	_update_cognitive_anchor(delta)
	_update_blood_tunnel()
	_update_wearable_power(delta)
	_update_heartbeat(delta)
	_update_fear_emitter(delta)
	_update_flashlight_feel(delta)
	_update_sprint_fov(delta)
	_update_floor_wetness(delta)
	_update_weapon_sway(delta)
	_update_extraction_beacon(delta)
	_update_adrenaline(delta)
	_update_wristband(delta)
	_update_shepard_tension()
	_landing_speed_penalty = move_toward(_landing_speed_penalty, 0.0, delta * 1.8)
	_sample_survivor_path(delta)
	_update_hud()
	_update_debug_overlay()
	_update_notice(delta)
	_recover_recoil(delta)
	_update_move_bob(delta)
	_update_hit_bob(delta)
	_update_velocity_lean(delta)
	_update_proximity_indicators(delta)
	_update_barrel_crosshair()
	_update_interact_prompt()
	_update_damage_flash(delta)
	_update_low_health_pulse(delta)

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
	var land_mult := 1.0 - _landing_speed_penalty
	if is_prone:
		return 1.1 * movement_penalty * land_mult
	if is_crouching:
		return crouch_speed * movement_penalty * land_mult
	if stealth_focus:
		return walk_speed * 0.48 * movement_penalty * land_mult
	if InputBus.wants_sprint() and stamina > 1.0 and move_input.length() > 0.1:
		return sprint_speed * movement_penalty * movement_penalty_mult * land_mult
	return walk_speed * movement_penalty * land_mult

func _update_stamina(move_input: Vector2, delta: float) -> void:
	var sprinting = InputBus.wants_sprint() and move_input.length() > 0.1 and not is_crouching
	if sprinting:
		stamina = max(0.0, stamina - sprint_stamina_cost * delta)
	else:
		stamina = min(max_stamina, stamina + stamina_recovery * health.get_stamina_modifier() * delta)

func _update_crouch(delta: float) -> void:
	var target_head_y: float
	var target_height: float
	var target_col_y: float
	if is_prone:
		target_head_y = 0.28
		target_height = 0.45
		target_col_y = 0.28
	elif is_crouching:
		target_head_y = 1.08
		target_height = 1.05
		target_col_y = 0.62
	else:
		target_head_y = 1.58
		target_height = 1.55
		target_col_y = 0.86
	head.position.y = lerp(head.position.y, target_head_y, delta * 10.0)
	capsule_shape.height = lerp(capsule_shape.height, target_height, delta * 10.0)
	collision_shape.position.y = lerp(collision_shape.position.y, target_col_y, delta * 10.0)

func _emit_movement_noise(delta: float, move_input: Vector2, speed: float) -> void:
	noise_timer -= delta
	if move_input.length() <= 0.1 or noise_timer > 0.0:
		return
	var surface_id: String = _get_surface_id_underfoot()
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
	if int(resources.get("boot_grips", 0)) > 0 and surface_id in ["metal", "grate", "deck"]:
		loudness *= 0.5
	loudness *= footstep_noise_mult
	GameEvents.emit_player_noise(global_position, loudness)
	noise_timer = 0.62 if stealth_focus else (0.45 if is_crouching else 0.28)
	# Play the audible footstep — pitch varies by surface and gait
	if not is_on_floor():
		return
	var step_sound: String = "footstep_soft"
	if surface_id in ["metal", "grate", "deck", "bulkhead"]:
		step_sound = "footstep_metal"
	elif surface_id in ["ceiling", "railing"]:
		step_sound = "footstep_hard"
	# Steam vents and wet zones override footstep sound
	if _floor_wetness > 0.45:
		step_sound = "footstep_wet"
	var step_pitch: float = 1.0
	if speed > walk_speed:
		step_pitch = 1.08
	elif is_crouching or stealth_focus:
		step_pitch = 0.88
	AudioRouter.play_3d(step_sound, global_position, step_pitch)

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
	if not status_label:
		return
	if glasses_lens_mesh:
		glasses_lens_mesh.visible = glasses_lens_damage > 0.04
	if body_silhouette:
		body_silhouette.update_status(health, stamina, health.get_weapon_handling_state())
	if status_icons:
		status_icons.update_status(health, mental.corruption if mental else 0.0)
	if objective_tracker:
		objective_tracker.set_player_position(global_position)
	if minimap:
		minimap.update(global_position, yaw, objectives_cache, extraction_pos_cache)
	if glasses_overlay:
		var corr: float = mental.corruption if mental else 0.0
		var blood: float = clamp(health.blood_volume / 100.0, 0.0, 1.0) if health else 1.0
		glasses_overlay.update_effects(corr, blood)
	_update_contamination_fog()
	if not weapon or not weapon.data:
		_force_weapon_ready(equipped_weapon_id)
	_refresh_weapon_hologram()
	# Vitals bars — scale height proportional to blood/stamina
	var bar_full_h := 80.0
	if blood_bar:
		var blood_ratio: float = clamp(health.blood_volume / 100.0, 0.0, 1.0)
		blood_bar.offset_top = blood_bar.offset_bottom - bar_full_h * blood_ratio
	if stamina_bar:
		var stam_ratio: float = clamp(stamina / max_stamina, 0.0, 1.0)
		stamina_bar.offset_top = stamina_bar.offset_bottom - bar_full_h * stam_ratio
	_update_crosshair_spread()

func _get_diegetic_ammo_display() -> String:
	if not mental or mental.corruption < 70.0:
		return weapon.get_ammo_display()
	if randf() < 0.35:
		var false_count: int = max(0, weapon.current_ammo + randi_range(-3, 3))
		return "%d / %d" % [false_count, weapon.reserve_ammo]
	return weapon.get_ammo_display()

func _update_contamination_fog() -> void:
	if not mental:
		return
	var world_env_node: Node = get_tree().get_first_node_in_group("world_env")
	if not (world_env_node is WorldEnvironment):
		return
	var world_environment: WorldEnvironment = world_env_node as WorldEnvironment
	if not world_environment.environment:
		return
	var base_fog: float = 0.038
	world_environment.environment.fog_density = base_fog + (mental.corruption / 100.0) * 0.06

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
	debug_label.text = "DEBUG\nCONTAM %.0f  BLEED %.1f  ENEMIES %d\nWPN %s\n%s" % [
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
	var melee_multiplier: float = _get_melee_multiplier()
	GameEvents.emit_environment_impulse(camera.global_position + forward * 1.0, 1.55, 9.0 * melee_multiplier, self, "player_shove")
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
			enemy.apply_shove(global_position, 7.5 * melee_multiplier, 0.55)
			shoved = true
	if shoved:
		weapon_pivot.position += Vector3(0.0, 0.06, 0.08)

func _use_role_ability() -> void:
	var cooldown_key: String = "role_ability_cooldown"
	if float(resources.get(cooldown_key, 0.0)) > 0.0:
		return
	match selected_role:
		"breacher":
			var forward: Vector3 = -global_transform.basis.z
			velocity += forward * 7.0 + Vector3.UP * 0.4
			resources[cooldown_key] = 12.0
			AudioRouter.play_ui("interact")
			_show_diegetic_notice("BREACH KICK\nMomentum committed.", 1.0)
		"medic":
			health.use_injector()
			health.pain = max(0.0, health.pain - 35.0)
			resources[cooldown_key] = 28.0
			AudioRouter.play_ui("reload_click")
			_show_diegetic_notice("EMERGENCY STIM\nPain response dampened.", 1.0)
		"heavy":
			resources["suppression_active"] = 8.0
			resources[cooldown_key] = 22.0
			AudioRouter.play_ui("enemy_alert")
			_show_diegetic_notice("SUPPRESSION STANCE\nWeapon braced.", 1.0)
		_:
			resources[cooldown_key] = 12.0
			AudioRouter.play_ui("interact")

func _update_role_ability_timers(delta: float) -> void:
	if float(resources.get("role_ability_cooldown", 0.0)) > 0.0:
		resources["role_ability_cooldown"] = max(0.0, float(resources["role_ability_cooldown"]) - delta)
	if float(resources.get("suppression_active", 0.0)) > 0.0:
		resources["suppression_active"] = max(0.0, float(resources["suppression_active"]) - delta)

func _get_role_ability_cooldown_duration() -> float:
	match selected_role:
		"medic":
			return 28.0
		"heavy":
			return 22.0
		_:
			return 12.0

func _get_melee_multiplier() -> float:
	if int(resources.get("melee_amp", 0)) > 0:
		return 1.4
	return 1.0

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
	if _try_revive_corpse(collider):
		return
	if collider and collider.has_method("use"):
		collider.use(self)
		GameEvents.request_sound("interact", hit_position, 0.65)
	else:
		GameEvents.emit_environment_impulse(hit_position, 0.8, 2.5, self, "use_push")

func _try_revive_corpse(collider: Variant) -> bool:
	if not can_revive_corpses or not collider or not (collider is EnemyBase3D):
		return false
	var enemy: EnemyBase3D = collider as EnemyBase3D
	if not enemy.dead or not enemy.has_meta("display_name"):
		return false
	var display_value: String = String(enemy.get_meta("display_name"))
	if display_value.find("CORPSE") < 0:
		return false
	if not enemy.has_method("revive_from_corpse"):
		return false
	if int(resources.get("trauma_kit", 0)) > 0:
		consume_resource("trauma_kit", 1)
	enemy.revive_from_corpse()
	GameEvents.request_sound("interact", enemy.global_position, 0.9)
	_show_diegetic_notice("REVIVE SHOCK\nCorpse is moving again.", 1.6)
	return true

func apply_survivor_loadout(loadout: Dictionary) -> void:
	survivor_loadout = loadout.duplicate(true)
	selected_role = String(survivor_loadout.get("role", selected_role))
	reload_speed_mult = float(survivor_loadout.get("reload_speed_mult", 1.0))
	movement_penalty_mult = float(survivor_loadout.get("movement_penalty_mult", 1.0))
	footstep_noise_mult = float(survivor_loadout.get("noise_mult", 1.0))
	damage_resist_mult = float(survivor_loadout.get("damage_resist", 0.0))
	if health:
		health.damage_resist = damage_resist_mult
	can_revive_corpses = bool(survivor_loadout.get("can_revive_corpses", false))
	has_headset = bool(survivor_loadout.get("has_headset", false))
	flashlight_type = String(survivor_loadout.get("flashlight", "handheld"))
	wearable_modules.clear()
	wearable_slots.clear()
	glasses_power_empty = false
	glasses_lens_damage = float(survivor_loadout.get("glasses_lens_damage", 0.0))
	_apply_background_traits(String(survivor_loadout.get("background", "Survivor")))
	treatment_speed_modifier *= float(survivor_loadout.get("treatment_speed", 1.0))
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

func _slot_index_for_weapon_id(weapon_id: String) -> int:
	var wd := WeaponData.create_weapon(weapon_id)
	return _slot_index_for_family(wd.weapon_family if wd else "sidearm")

func _slot_index_for_family(family: String) -> int:
	if family == "ar" or family == "lmg":
		return 0
	if family == "sidearm" or family == "smg":
		return 1
	return 2  # thermal / support

func equip_found_weapon(weapon_id: String) -> void:
	if not weapon:
		return
	_ensure_weapon_inventory()
	var target_slot: int = _slot_index_for_weapon_id(weapon_id)
	var old_state: Dictionary = weapon_slots[target_slot].duplicate(true)
	var new_state := _make_weapon_state(weapon_id)
	# Drop whatever was in that slot (if occupied and different)
	if not old_state.is_empty() and String(old_state.get("weapon_id", "")) != weapon_id:
		var drop_pos := global_position + Vector3.UP * 0.4
		if camera:
			drop_pos = global_position + -camera.global_transform.basis.z * 0.6 + Vector3.UP * 0.32
		_spawn_weapon_pickup_from_state(old_state, drop_pos)
	weapon_slots[target_slot] = new_state
	_update_equipped_weapon_slot_state()
	equipped_weapon_slot = target_slot
	weapon.apply_weapon_state(new_state)
	equipped_weapon_id = weapon.data.weapon_id
	_reinstall_known_cross_weapon_attachments()
	_force_weapon_ready(equipped_weapon_id)
	survivor_loadout["weapon_id"] = equipped_weapon_id
	survivor_loadout.erase("weapon_state")
	var slot_name: String = ["PRIMARY", "SECONDARY", "SUPPORT"][target_slot]
	if comms:
		comms.announce("%s: %s" % [slot_name, weapon.data.weapon_name])

func equip_found_weapon_state(state: Dictionary) -> void:
	if not weapon:
		return
	_ensure_weapon_inventory()
	var fam: String = ""
	var wd_id: String = String(state.get("weapon_id", ""))
	if not wd_id.is_empty():
		var wd := WeaponData.create_weapon(wd_id)
		if wd:
			fam = wd.weapon_family
	var target_slot: int = _slot_index_for_family(fam)
	var old_state: Dictionary = weapon_slots[target_slot].duplicate(true)
	if not old_state.is_empty() and String(old_state.get("weapon_id", "")) != wd_id:
		var drop_pos := global_position + Vector3.UP * 0.4
		if camera:
			drop_pos = global_position + -camera.global_transform.basis.z * 0.6 + Vector3.UP * 0.32
		_spawn_weapon_pickup_from_state(old_state, drop_pos)
	weapon_slots[target_slot] = state.duplicate(true)
	_update_equipped_weapon_slot_state()
	equipped_weapon_slot = target_slot
	weapon.apply_weapon_state(state)
	equipped_weapon_id = weapon.data.weapon_id
	dropped_weapon_pickup = null
	survivor_loadout["weapon_id"] = weapon.data.weapon_id
	survivor_loadout["weapon_state"] = weapon.get_weapon_state()
	if comms:
		comms.announce("Recovered: %s" % weapon.data.weapon_name)

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
	flashlight.shadow_enabled = true
	if new_type == "handheld":
		# Left shoulder / offhand — well clear of the gun body on the right
		flashlight.position = Vector3(-0.32, 0.04, -0.10)
		flashlight.rotation_degrees = Vector3(-1.0, 8.0, 0.0)
		camera.add_child(flashlight)
	elif new_type == "vest":
		# Chest-center, wide flood
		flashlight.position = Vector3(0.0, -0.28, -0.12)
		flashlight.spot_angle = 44.0
		flashlight.light_energy = 1.6
		camera.add_child(flashlight)
	elif new_type == "helmet":
		# Left side of helmet — clear of gun shadow
		flashlight.position = Vector3(-0.28, 0.10, -0.12)
		flashlight.spot_angle = 34.0
		flashlight.light_energy = 2.5
		flashlight.rotation_degrees = Vector3(0.0, 6.0, 0.0)
		camera.add_child(flashlight)
	elif new_type == "weapon_mount":
		# Under barrel, forward of handguard so it clears the gun body
		flashlight.position = Vector3(0.0, -0.10, -0.72)
		flashlight.spot_range = 15.0
		flashlight.spot_angle = 22.0
		weapon_pivot.add_child(flashlight)
	else:
		flashlight.position = Vector3(-0.30, 0.04, -0.10)
		camera.add_child(flashlight)

func _get_inventory_summary() -> String:
	var background = String(survivor_loadout.get("background", "Survivor"))
	var light_text = flashlight_type.replace("_", " ").to_upper()
	var comms_text = "EARPIECE" if has_headset else "NO COMMS"
	var weapon_text = weapon.data.weapon_family.to_upper() if weapon and weapon.data else "NO WEAPON"
	var resource_count: int = _get_carried_units()
	var route_noise = ""
	if mental and mental.corruption >= 70.0 and randf() < 0.08:
		route_noise = " / DOOR STATE: OPEN?"
	_ensure_weapon_inventory()
	var slot_labels: Array[String] = ["PRI", "SEC", "SUP"]
	var weapon_slots_text: Array[String] = []
	for index in range(weapon_slots.size()):
		var slot_prefix: String = ">" if index == equipped_weapon_slot else " "
		var label: String = slot_labels[index] if index < slot_labels.size() else str(index + 1)
		weapon_slots_text.append("%s%s %s" % [slot_prefix, label, _weapon_state_label(weapon_slots[index])])
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
	var slot_name: String = (["PRIMARY", "SECONDARY", "SUPPORT"])[slot_index] if slot_index < 3 else "SLOT %d" % (slot_index + 1)
	_show_diegetic_notice("%s\n%s" % [slot_name, weapon.data.weapon_name], 1.5)

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
		if _is_internal_resource_key(String(key)):
			continue
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
	_trigger_kinetic_stagger(amount, part_name)
	_show_hit_notice(part_name, amount, damage_type)
	# Screen flash — intensity scales with damage severity
	var flash_alpha: float = clamp(amount / 55.0, 0.12, 0.72)
	damage_flash_timer = 0.0
	damage_flash_max = 0.45 + flash_alpha * 0.3
	if damage_flash_rect:
		damage_flash_rect.color = Color(0.72, 0.0, 0.02, flash_alpha)
	GameEvents.request_sound("bone_fracture", global_position, clamp(amount / 40.0, 0.5, 1.2))
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
	# Upgrade: noise-based shake with exponential decay instead of sine waves
	shake_noise = shake_noise.lerp(
		Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), 0.0) * camera_shake * 0.04,
		delta * 24.0)
	shake_noise *= pow(0.08, delta)
	shake_z_tilt = lerp(shake_z_tilt, 0.0, delta * 14.0)
	# Heartbeat micro-pulse (vertical nudge, decays fast)
	_heartbeat_pulse = move_toward(_heartbeat_pulse, 0.0, delta * 18.0)
	var shake_offset := shake_noise + Vector3(0.0, _heartbeat_pulse, 0.0)
	if hit_bob_timer <= 0.0:
		var base_pos := camera.position - shake_offset
		base_pos = base_pos.lerp(move_bob_offset, clamp(delta * 12.0, 0.0, 1.0))
		camera.position = base_pos + shake_offset
		return
	hit_bob_timer = max(0.0, hit_bob_timer - delta)
	var progress: float = 1.0 - hit_bob_timer / max(0.01, hit_bob_duration)
	var wave: float = sin(progress * PI)
	camera.position = Vector3(hit_bob_side * 0.025 * hit_bob_strength * wave, -0.018 * hit_bob_strength * wave, 0.0) + shake_offset
	if intro_lock_timer <= 0.0:
		camera.rotation.z = hit_bob_side * deg_to_rad(3.4) * hit_bob_strength * wave

func _update_move_bob(delta: float) -> void:
	if not camera:
		return
	var h_vel := Vector2(velocity.x, velocity.z).length()
	if not is_on_floor() or h_vel < 0.5 or is_prone:
		if h_vel < 0.1 and is_on_floor() and not is_prone:
			head_bob_t = 0.0
			_lissajous_t += delta * 0.75
			var idle_x := sin(_lissajous_t) * 0.00065
			var idle_y := sin(_lissajous_t * 1.618033) * 0.00038
			move_bob_offset = move_bob_offset.lerp(Vector3(idle_x, idle_y, 0.0), delta * 1.2)
		else:
			move_bob_offset = move_bob_offset.lerp(Vector3.ZERO, delta * 9.0)
			if h_vel < 0.1:
				head_bob_t = 0.0
		return
	var is_sprinting := h_vel > sprint_speed * 0.72
	var bob_freq: float = 2.6 if is_sprinting else 1.8
	var bob_amp: float = 0.020 if is_sprinting else 0.012
	var sway_amp: float = 0.009 if is_sprinting else 0.005
	head_bob_t += delta * bob_freq * TAU
	var vert := sin(head_bob_t) * bob_amp
	var horiz := sin(head_bob_t * 0.5) * sway_amp
	var bob_target := Vector3(horiz, vert, 0.0)
	# Low-health limp: irregular rolling sway when near death
	var health_ratio: float = health.total_health_ratio() if health else 1.0
	if health_ratio < 0.30 and is_on_floor():
		_limp_t += delta * 1.4
		var limp_sway := sin(_limp_t * 2.3) * (0.030 - health_ratio * 0.10)
		var limp_tilt := sin(_limp_t * 1.1) * (0.022 - health_ratio * 0.07)
		bob_target += Vector3(limp_sway, abs(sin(_limp_t * 2.3)) * 0.008, 0.0)
		if intro_lock_timer <= 0.0 and hit_bob_timer <= 0.0:
			camera.rotation.z = lerp(camera.rotation.z, limp_tilt, delta * 3.0)
	move_bob_offset = move_bob_offset.lerp(bob_target, delta * 18.0)

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

func _update_damage_flash(delta: float) -> void:
	if not damage_flash_rect:
		return
	if damage_flash_timer < damage_flash_max:
		damage_flash_timer += delta
	var progress: float = clamp(damage_flash_timer / max(0.01, damage_flash_max), 0.0, 1.0)
	var current_alpha: float = damage_flash_rect.color.a
	var target_alpha: float = lerp(current_alpha, 0.0, clamp(progress * progress * delta * 6.0, 0.0, 1.0))
	damage_flash_rect.color.a = target_alpha

func _update_low_health_pulse(delta: float) -> void:
	if not damage_flash_rect or not health:
		return
	var blood_ratio: float = clamp(health.blood_volume / 100.0, 0.0, 1.0)
	if blood_ratio > 0.38:
		return
	low_health_pulse_timer += delta * lerp(3.8, 1.2, blood_ratio / 0.38)
	var pulse: float = (sin(low_health_pulse_timer) * 0.5 + 0.5) * (1.0 - blood_ratio / 0.38) * 0.28
	if damage_flash_rect.color.a < pulse:
		damage_flash_rect.color = Color(0.55, 0.0, 0.0, pulse)

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
	_heartbeat_pulse = arousal * 0.012  # micro camera nudge synced to the beat

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
	var pitch_kick := pitch_radians * recoil_trait_modifier
	var yaw_kick := yaw_radians * recoil_trait_modifier
	recoil_hold_timer = 0.16
	weapon_kick_offset += Vector3(0.0, rearward_kick * 0.35, rearward_kick * 2.4)
	# Tween-driven recoil: EXPO snap up, SINE recovery to 20% residual during burst
	if _recoil_tween:
		_recoil_tween.kill()
	_recoil_tween = create_tween()
	var kick_x := weapon_kick_rotation.x + pitch_kick * 9.5
	var kick_y := weapon_kick_rotation.y + yaw_kick * 5.0
	var kick_z := weapon_kick_rotation.z - yaw_kick * 3.8
	_recoil_tween.tween_property(self, "weapon_kick_rotation",
		Vector3(kick_x, kick_y, kick_z), 0.05)\
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	var recover_target := Vector3(kick_x * 0.20, kick_y * 0.20, kick_z * 0.20)
	_recoil_tween.tween_property(self, "weapon_kick_rotation", recover_target, 0.25)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# Z-axis gun kick (push into screen, spring back)
	if weapon_pivot:
		_recoil_tween.parallel().tween_property(weapon_pivot, "position:z",
			weapon_default_position.z + rearward_kick * 2.2, 0.04)\
			.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		_recoil_tween.tween_property(weapon_pivot, "position:z",
			weapon_default_position.z, 0.22)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Noise-based screen shake contribution
	var rand_dir := Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), 0.0).normalized()
	shake_noise += rand_dir * (abs(pitch_kick) * 0.10 + abs(yaw_kick) * 0.05)
	shake_noise = shake_noise.limit_length(0.10)
	shake_z_tilt += randf_range(-0.8, 0.8) * abs(yaw_kick) * 0.06
	shake_z_tilt = clamp(shake_z_tilt, -0.055, 0.055)
	camera_shake = min(camera_shake + abs(pitch_kick) * 0.72 + abs(yaw_kick) * 0.28, 0.082)
	_trigger_muzzle_flash_light(rearward_kick)

func _recover_recoil(delta: float) -> void:
	recoil_hold_timer = max(0.0, recoil_hold_timer - delta)
	var kick_recovery_speed: float = 0.55 if recoil_hold_timer > 0.0 else 2.2
	weapon_kick_offset = weapon_kick_offset.move_toward(Vector3.ZERO, delta * kick_recovery_speed * 0.5)
	weapon_kick_rotation = weapon_kick_rotation.move_toward(Vector3.ZERO, delta * kick_recovery_speed * 4.0)
	camera_shake = move_toward(camera_shake, 0.0, delta * 0.14)

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
	run_time_elapsed = elapsed_seconds
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

func _show_mission_debrief(success: bool, _reason: String) -> void:
	if debrief_screen and is_instance_valid(debrief_screen):
		return
	run_finished = true
	allow_restart = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	var objectives_total: int = 3
	var objectives_done: int = run_objectives_done
	if objective_tracker:
		objectives_total = max(1, objective_tracker.get_objective_count())
		objectives_done = max(objectives_done, objective_tracker.get_done_count())
	var final_corruption: float = mental.corruption if mental else 0.0
	var summary: Dictionary = {
		"success": success,
		"time_elapsed": run_time_elapsed,
		"kills": run_kills,
		"objectives_done": objectives_done,
		"objectives_total": objectives_total,
		"contamination_cleared": clamp(100.0 - final_corruption, 0.0, 100.0),
		"role": selected_role
	}
	debrief_screen = MissionDebriefScreen.new()
	debrief_screen.name = "MissionDebriefScreen"
	debrief_screen.configure(summary)
	if hud_layer:
		hud_layer.add_child(debrief_screen)
	else:
		add_child(debrief_screen)
	run_kills = 0
	run_objectives_done = 0
	run_time_elapsed = 0.0

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
	_save_death_location()
	died.emit(reason)

func _start_prone_dive() -> void:
	is_prone = true
	prone_iframes = 0.55
	prone_held_timer = 0.0
	var forward = -global_transform.basis.z
	velocity = forward * 5.2 + Vector3.UP * 0.7

func _on_shot_fired(_projectile: BallisticProjectile) -> void:
	_create_muzzle_flash()
	_create_gunshot_smoke()
	if crosshair_ctrl:
		crosshair_ctrl.notify_fired()
		crosshair_ctrl.spread_px = min(crosshair_ctrl.spread_px + 18.0, 62.0)
	var muzzle_pos: Vector3 = muzzle_marker.global_position if muzzle_marker else global_position
	var family: String = weapon.data.weapon_family if weapon and weapon.data else ""
	var shot_id: String = "gunshot_thermal" if family == "thermal" else ("gunshot_heavy" if family in ["lmg", "launcher"] else "gunshot_light")
	AudioRouter.play_3d(shot_id, muzzle_pos)

func _trigger_muzzle_flash_light(rearward_kick: float) -> void:
	# Scale flash intensity with caliber — heavier kicks = brighter, longer flash
	var flash_scale: float = clamp(rearward_kick / 0.18, 0.6, 2.2)
	_create_muzzle_flash(flash_scale)

func _create_muzzle_flash(scale: float = 1.0) -> void:
	if not muzzle_marker or not is_instance_valid(muzzle_marker):
		return
	var flash = OmniLight3D.new()
	flash.light_color = Color(1.0, 0.82 + scale * 0.06, 0.42 + scale * 0.08)
	flash.light_energy = 0.0
	flash.omni_range = 2.8 + scale * 1.8
	muzzle_marker.add_child(flash)
	var tw = flash.create_tween()
	tw.tween_property(flash, "light_energy", 3.2 * scale, 0.018)
	tw.tween_property(flash, "light_energy", 0.0, 0.045 + scale * 0.022)
	tw.tween_callback(flash.queue_free)

func _create_gunshot_smoke() -> void:
	if not muzzle_marker or not is_instance_valid(muzzle_marker):
		return
	for i in range(3):
		var puff = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = randf_range(0.028, 0.055)
		sphere.height = sphere.radius * 2.0
		puff.mesh = sphere
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.72, 0.68, 0.62, 0.38)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		puff.material_override = mat
		puff.position = Vector3(randf_range(-0.04, 0.04), randf_range(-0.02, 0.02), randf_range(-0.05, 0.0))
		muzzle_marker.add_child(puff)
		var drift = Vector3(randf_range(-0.04, 0.04), randf_range(0.06, 0.12), randf_range(-0.08, 0.0))
		var tw = puff.create_tween()
		tw.set_parallel(true)
		tw.tween_property(puff, "position", puff.position + drift, 0.36)
		tw.tween_property(mat, "albedo_color:a", 0.0, 0.36)
		tw.tween_callback(puff.queue_free).set_delay(0.36)

func _update_barrel_crosshair() -> void:
	if not crosshair_ctrl or not camera or not muzzle_marker:
		return
	var muzzle_world := muzzle_marker.global_position
	# Use weapon's actual forward so the crosshair follows recoil kick
	var weapon_forward := -muzzle_marker.global_transform.basis.z
	var barrel_far := muzzle_world + weapon_forward * 50.0
	var screen_pos := camera.unproject_position(barrel_far)
	var screen_center := get_viewport().get_visible_rect().size * 0.5
	crosshair_ctrl.barrel_offset = screen_pos - screen_center
	_update_laser_dot(muzzle_world, weapon_forward)

func _update_laser_dot(muzzle_world: Vector3, weapon_forward: Vector3) -> void:
	var has_laser: bool = weapon != null and weapon.has_attachment("laser_pointer")
	if not has_laser:
		if laser_dot and is_instance_valid(laser_dot):
			laser_dot.visible = false
		return
	if not laser_dot or not is_instance_valid(laser_dot):
		laser_dot = OmniLight3D.new()
		laser_dot.name = "LaserDot"
		laser_dot.light_color = Color(1.0, 0.08, 0.04)
		laser_dot.omni_range = 0.28
		laser_dot.light_energy = 3.8
		laser_dot.shadow_enabled = false
		add_child(laser_dot)
	var query := PhysicsRayQueryParameters3D.create(muzzle_world, muzzle_world + weapon_forward * 40.0)
	query.exclude = [get_rid()]
	query.collision_mask = 1 | 2
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		laser_dot.visible = false
	else:
		laser_dot.visible = true
		laser_dot.global_position = hit["position"] + hit["normal"] * 0.02

func _update_interact_prompt() -> void:
	if not interact_prompt_label or not camera:
		return
	var from = camera.global_position
	var to = from + (-camera.global_transform.basis.z) * 2.6
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [get_rid()]
	query.collision_mask = 1 | 2
	var hit = get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		interact_prompt_label.text = ""
		return
	var collider = hit.get("collider")
	if collider and collider.has_method("get_display_name"):
		interact_prompt_label.text = "[E]  " + collider.get_display_name()
	elif collider and "display_name" in collider and not str(collider.display_name).is_empty():
		interact_prompt_label.text = "[E]  " + str(collider.display_name)
	elif collider and collider.has_meta("display_name"):
		interact_prompt_label.text = "[E]  " + str(collider.get_meta("display_name"))
	else:
		interact_prompt_label.text = ""

func _build_inventory_text() -> String:
	var lines: Array[String] = []
	lines.append("── INVENTORY ──")
	if weapon and weapon.data:
		lines.append("WEAPON  %s  %s" % [weapon.data.weapon_name, _get_diegetic_ammo_display()])
	else:
		lines.append("WEAPON  none")
	for slot in weapon_slots:
		if slot.get("weapon_id", "") != "":
			lines.append("  SLOT  %s" % slot.get("weapon_id", ""))
	if resources.is_empty():
		lines.append("SUPPLIES  empty")
	else:
		for key in resources:
			if _is_internal_resource_key(String(key)):
				continue
			lines.append("  %s  x%d" % [String(key).to_upper(), int(resources[key])])
	if wearable_modules.is_empty():
		lines.append("MODULES  none")
	else:
		for key in wearable_modules:
			lines.append("  %s" % key.to_upper())
	return "\n".join(lines)

func _is_internal_resource_key(resource_id: String) -> bool:
	return resource_id in ["role_ability_cooldown", "suppression_active"]

func _on_weapon_ammo_changed(_current: int, _reserve: int) -> void:
	_refresh_weapon_hologram()

func _on_weapon_condition_changed_hud(_condition: float) -> void:
	_refresh_weapon_hologram()

func _refresh_weapon_hologram() -> void:
	if not weapon_hologram:
		return
	if weapon and weapon.data:
		weapon_hologram.refresh(
			weapon.data.weapon_name,
			weapon.current_ammo,
			weapon.reserve_ammo,
			weapon.data.magazine_size,
			weapon.weapon_condition,
			weapon.data.weapon_family,
			weapon.is_reloading
		)
	else:
		weapon_hologram.refresh("", 0, 0, 0, 1.0, "", false)

func _update_crosshair_spread() -> void:
	if not crosshair_ctrl:
		return
	var base_spread := 0.0
	if weapon and weapon.data:
		base_spread = weapon.data.spread_degrees * 22.0
	var vel_xz := Vector2(velocity.x, velocity.z).length()
	var max_speed: float = sprint_speed if sprint_speed > 0.0 else 8.0
	var speed_spread: float = (vel_xz / max_speed) * 32.0
	var air_spread: float = 42.0 if not is_on_floor() else 0.0
	var stance_reduction: float = 10.0 if is_prone else (6.0 if is_crouching else 0.0)
	if float(resources.get("suppression_active", 0.0)) > 0.0:
		stance_reduction += 14.0
	# Panic inaccuracy — grows with shot_heat during sustained fire
	var panic_spread := 0.0
	if weapon and weapon.has_method("get") and "shot_heat" in weapon:
		panic_spread = weapon.shot_heat * 28.0
	var target := base_spread + speed_spread + air_spread + panic_spread - stance_reduction
	crosshair_ctrl.spread_px = lerp(crosshair_ctrl.spread_px, max(10.0, target), get_process_delta_time() * 4.0)
	crosshair_ctrl.role_cooldown = float(resources.get("role_ability_cooldown", 0.0))
	crosshair_ctrl.role_cooldown_max = _get_role_ability_cooldown_duration()

# ────────────────────────────────────────────────────────────────
# HORROR ATMOSPHERE SYSTEMS
# ────────────────────────────────────────────────────────────────

func _update_fear_emitter(delta: float) -> void:
	var nearest_dist := 999.0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		var d := global_position.distance_to(enemy.global_position)
		if d < nearest_dist:
			nearest_dist = d
	var fear_target: float = clamp(1.0 - (nearest_dist - 4.0) / 12.0, 0.0, 1.0)
	_fear_level = lerp(_fear_level, fear_target, delta * 1.8)
	# Duck ambient hum as fear rises
	if ambient_hum_player:
		ambient_hum_player.volume_db = lerp(-14.0, -60.0, _fear_level)
	# Breathing audio at high fear or low health
	var pain_level: float = health.pain / 120.0 if health else 0.0
	if _fear_level > 0.35 or pain_level > 0.20:
		_breath_timer -= delta
		if _breath_timer <= 0.0:
			_breath_timer = lerp(3.2, 1.2, max(_fear_level, pain_level))
			AudioRouter.play_ui("breath_exhale",
				lerp(0.3, 0.85, max(_fear_level, pain_level)))

func _update_flashlight_feel(delta: float) -> void:
	if not flashlight:
		return
	# Lag: flashlight rotation trails camera direction
	var cam_basis := camera.global_transform.basis
	var lag_basis := flashlight.global_transform.basis.slerp(cam_basis, delta * 7.0)
	flashlight.global_transform.basis = lag_basis
	# Battery drain while flashlight is on
	if flashlight.visible:
		flashlight_battery = max(0.0, flashlight_battery - delta * 1.4)
	else:
		flashlight_battery = min(100.0, flashlight_battery + delta * 4.0)
	# Flicker and fail at low battery
	if flashlight_battery <= 0.0:
		flashlight.light_energy = 0.0
	elif flashlight_battery < 15.0:
		_fl_flicker_timer -= delta
		if _fl_flicker_timer <= 0.0:
			_fl_flicker_timer = randf_range(0.04, 0.22)
			flashlight.light_energy = randf_range(0.0, 2.5) * (flashlight_battery / 15.0)
	else:
		flashlight.light_energy = lerp(flashlight.light_energy,
			2.2 * (flashlight_battery / 100.0 * 0.4 + 0.6), delta * 12.0)

func _update_sprint_fov(delta: float) -> void:
	if not camera:
		return
	var h_vel := Vector2(velocity.x, velocity.z).length()
	var sprint_ratio: float = clamp((h_vel - walk_speed) / max(0.1, sprint_speed - walk_speed), 0.0, 1.0)
	var base: float = mental.base_fov if mental else 75.0
	camera.fov = lerp(camera.fov, base + sprint_ratio * 8.0, delta * 5.0)

func _update_velocity_lean(delta: float) -> void:
	if not camera or hit_bob_timer > 0.0 or intro_lock_timer > 0.0:
		return
	var local_lat := (global_transform.basis.inverse() * Vector3(velocity.x, 0.0, velocity.z)).x
	var lean := clamp(local_lat * 0.013, -0.048, 0.048)
	camera.rotation.z = lerp(camera.rotation.z, lean + shake_z_tilt, delta * 5.0)

func _update_proximity_indicators(delta: float) -> void:
	if _proximity_rects.is_empty():
		return
	# Find strongest nearby threat that is not currently visible to us
	var max_closeness := 0.0
	var cam_forward := -camera.global_transform.basis.z
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		var to_e := enemy.global_position - global_position
		var dist := to_e.length()
		if dist > 8.0:
			continue
		# Skip if squarely in front of us (player can see it)
		var dot := cam_forward.dot(to_e.normalized())
		if dot > 0.5:
			continue
		max_closeness = max(max_closeness, 1.0 - dist / 8.0)
	# Pulse alpha
	var pulse: float = abs(sin(Time.get_ticks_msec() * 0.001 * 0.8 * TAU)) * max_closeness * 0.38
	for r in _proximity_rects:
		r.color.a = lerp(r.color.a, pulse, delta * 8.0)

# ────────────────────────────────────────────────────────────────
# SPRINT 2 SYSTEMS
# ────────────────────────────────────────────────────────────────

func _update_floor_wetness(delta: float) -> void:
	var near_wet := false
	for zone in get_tree().get_nodes_in_group("wet_zone"):
		if zone is Area3D and (zone as Area3D).overlaps_body(self):
			near_wet = true
			break
	_floor_wetness = lerp(_floor_wetness, 1.0 if near_wet else 0.0, delta * 2.0)

func _update_weapon_sway(delta: float) -> void:
	if not weapon_pivot or run_finished:
		_prev_yaw = yaw
		_prev_pitch = pitch
		return
	var dyaw := yaw - _prev_yaw
	var dpitch := pitch - _prev_pitch
	_prev_yaw = yaw
	_prev_pitch = pitch
	var sway_x := clamp(-dyaw * 0.18, -0.06, 0.06)
	var sway_y := clamp(-dpitch * 0.10, -0.04, 0.04)
	_weapon_sway = _weapon_sway.lerp(Vector3(sway_x, sway_y, 0.0), delta * 8.0)
	weapon_pivot.rotation.y = lerp(weapon_pivot.rotation.y, _weapon_sway.x, delta * 12.0)
	weapon_pivot.rotation.x = lerp(weapon_pivot.rotation.x,
		_weapon_sway.y + weapon_kick_rotation.x * 0.018, delta * 12.0)

func _update_fall_tracking() -> void:
	var on_floor_now := is_on_floor()
	if not on_floor_now:
		_fall_peak_y = max(_fall_peak_y, global_position.y)
	elif not _was_on_floor:
		var fall_dist := _fall_peak_y - global_position.y
		if fall_dist > 1.8:
			_trigger_landing_impact(fall_dist)
		_fall_peak_y = global_position.y
	_was_on_floor = on_floor_now

func _trigger_landing_impact(fall_dist: float) -> void:
	var severity := clamp((fall_dist - 1.8) / 4.0, 0.0, 1.0)
	hit_bob_timer = 0.28
	hit_bob_duration = 0.28
	hit_bob_strength = clamp(severity * 1.4, 0.3, 1.0)
	hit_bob_side = 0.0
	_landing_speed_penalty = lerp(0.0, 0.6, severity)
	camera_shake = min(camera_shake + severity * 0.06, 0.12)
	GameEvents.request_sound("footstep_metal", global_position, lerp(0.7, 1.5, severity))
	if severity > 0.5 and health:
		stamina = max(0.0, stamina - severity * 18.0)

func _update_extraction_beacon(delta: float) -> void:
	if not _extraction_available or run_finished:
		return
	_beacon_pulse_timer -= delta
	if _beacon_pulse_timer <= 0.0:
		_beacon_pulse_timer = 2.8
		AudioRouter.play_ui("extraction_beacon", 0.6)

func _build_wristband_vitals() -> void:
	var wristband := Node3D.new()
	wristband.name = "WristbandVitals"
	wristband.position = Vector3(-0.26, -0.35, -0.52)
	wristband.rotation_degrees = Vector3(35.0, -18.0, -8.0)
	camera.add_child(wristband)
	_wristband_mesh = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.024
	cyl.bottom_radius = 0.024
	cyl.height = 0.009
	cyl.radial_segments = 20
	_wristband_mesh.mesh = cyl
	_wristband_mat = StandardMaterial3D.new()
	_wristband_mat.albedo_color = Color(0.05, 0.75, 0.15)
	_wristband_mat.emission_enabled = true
	_wristband_mat.emission = Color(0.05, 0.75, 0.15)
	_wristband_mat.emission_energy_multiplier = 0.6
	_wristband_mesh.material_override = _wristband_mat
	wristband.add_child(_wristband_mesh)

func _update_wristband(delta: float) -> void:
	if not _wristband_mat or not health:
		return
	var hp := health.total_health_ratio()
	var target_color: Color
	if hp > 0.6:
		target_color = Color(0.05, 0.75, 0.15)
	elif hp > 0.3:
		target_color = Color(0.82, 0.68, 0.05)
	else:
		target_color = Color(0.85, 0.06, 0.06)
	_wristband_mat.albedo_color = _wristband_mat.albedo_color.lerp(target_color, delta * 3.0)
	_wristband_mat.emission = _wristband_mat.albedo_color
	_wristband_mat.emission_energy_multiplier = lerp(
		_wristband_mat.emission_energy_multiplier,
		0.4 + _heartbeat_pulse * 20.0, delta * 12.0)

func _update_adrenaline(delta: float) -> void:
	if not health or run_finished:
		_adrenaline_phase = 0
		return
	var nearest := 999.0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		var d := global_position.distance_to(enemy.global_position)
		if d < nearest:
			nearest = d
	if _adrenaline_phase == 0 and _prev_nearest_enemy > 8.0 and nearest < 5.0:
		_adrenaline_phase = 1
		_adrenaline_timer = 6.0
	_prev_nearest_enemy = nearest
	match _adrenaline_phase:
		1:
			_adrenaline_timer -= delta
			_weapon_sway = _weapon_sway.lerp(Vector3.ZERO, delta * 14.0)
			if _adrenaline_timer <= 0.0:
				_adrenaline_phase = 2
				_adrenaline_timer = 8.0
		2:
			_adrenaline_timer -= delta
			shake_noise += Vector3(
				randf_range(-1.0, 1.0),
				randf_range(-1.0, 1.0), 0.0) * 0.0022
			if _adrenaline_timer <= 0.0:
				_adrenaline_phase = 0

func _update_shepard_tension() -> void:
	var nearest := _prev_nearest_enemy
	var tension := clamp(1.0 - (nearest - 3.0) / 11.0, 0.0, 1.0)
	var target_db := lerp(-80.0, -14.0, tension)
	AudioRouter.set_shepard_volume(target_db)

func _trigger_kinetic_stagger(amount: float, part_name: String) -> void:
	var severity := clamp(amount / 45.0, 0.0, 1.0)
	if severity < 0.18:
		return
	var side := 1.0 if (part_name == PlayerHealthBodyParts.PART_RIGHT_ARM or
		part_name == PlayerHealthBodyParts.PART_RIGHT_LEG) else -1.0
	yaw += side * severity * 0.038 * randf_range(0.6, 1.4)
	pitch = clamp(pitch - severity * 0.025, deg_to_rad(-82.0), deg_to_rad(82.0))
	rotation.y = yaw
	head.rotation.x = pitch

func _save_death_location() -> void:
	var cfg := ConfigFile.new()
	cfg.load("user://death_records.cfg")
	var records: Array = []
	var raw: Variant = cfg.get_value("deaths", "positions", [])
	if raw is Array:
		records = raw
	records.append({"x": global_position.x, "y": global_position.y, "z": global_position.z})
	if records.size() > 5:
		records = records.slice(records.size() - 5)
	cfg.set_value("deaths", "positions", records)
	cfg.save("user://death_records.cfg")
