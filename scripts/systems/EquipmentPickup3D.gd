extends DynamicObject3D
class_name EquipmentPickup3D

var equipment_type: String = "flashlight"
var flashlight_mount: String = "handheld"
var weapon_id: String = ""
var ammo_type: String = ""
var module_id: String = ""
var attachment_id: String = ""
var resource_id: String = ""
var resource_amount: int = 0
var picked_up: bool = false
var stored_weapon_state: Dictionary = {}

func configure_flashlight(mount_type: String) -> void:
	equipment_type = "flashlight"
	flashlight_mount = mount_type
	var label := "%s flashlight" % mount_type.replace("_", " ")
	configure(label.capitalize(), Vector3(0.38, 0.18, 0.18), Color(0.74, 0.82, 0.72), 2.0, true)
	_add_pickup_light()

func configure_weapon(new_weapon_id: String, label: String) -> void:
	equipment_type = "weapon"
	weapon_id = new_weapon_id
	stored_weapon_state = {}
	configure(label, Vector3(0.85, 0.22, 0.28), Color(0.26, 0.3, 0.32), 5.0, true)
	_add_pickup_light()

func configure_weapon_state(state: Dictionary) -> void:
	equipment_type = "weapon_state"
	stored_weapon_state = state.duplicate(true)
	weapon_id = String(stored_weapon_state.get("weapon_id", "m7_colony_pistol"))
	var weapon_data := WeaponData.create_weapon(weapon_id)
	configure("%s (dropped)" % weapon_data.weapon_name, Vector3(0.85, 0.22, 0.28), Color(0.2, 0.23, 0.25), 5.0, true)
	add_to_group("dropped_weapons")
	_add_pickup_light()

func configure_ammo(new_ammo_type: String, amount: int) -> void:
	equipment_type = "ammo"
	ammo_type = new_ammo_type
	resource_amount = amount
	configure("%s x%d" % [ammo_type.replace("_", " ").capitalize(), amount], Vector3(0.34, 0.18, 0.24), Color(0.23, 0.24, 0.18), 1.4, true)
	_add_pickup_light()

func configure_resource(new_resource_id: String, amount: int) -> void:
	equipment_type = "resource"
	resource_id = new_resource_id
	resource_amount = amount
	configure("%s x%d" % [resource_id.replace("_", " ").capitalize(), amount], Vector3(0.34, 0.26, 0.34), Color(0.36, 0.32, 0.18), 2.0, true)
	_add_pickup_light()

func configure_wearable_module(new_module_id: String) -> void:
	equipment_type = "wearable_module"
	module_id = new_module_id
	configure(StationSystemsCatalog.get_wearable_module_label(module_id), Vector3(0.36, 0.16, 0.28), Color(0.18, 0.38, 0.42), 1.5, true)
	_add_pickup_light()

func configure_weapon_attachment(new_attachment_id: String) -> void:
	equipment_type = "weapon_attachment"
	attachment_id = new_attachment_id
	configure(StationSystemsCatalog.get_weapon_attachment_label(attachment_id), Vector3(0.32, 0.18, 0.32), Color(0.28, 0.28, 0.34), 1.5, true)
	_add_pickup_light()

func _build_visual(size: Vector3, color: Color) -> void:
	if equipment_type == "weapon" or equipment_type == "weapon_state":
		_build_weapon_pickup_visual(color)
	elif equipment_type == "ammo":
		_build_ammo_visual(color)
	elif equipment_type == "flashlight":
		_build_flashlight_visual(color)
	elif equipment_type == "wearable_module":
		_build_wearable_visual(color)
	elif equipment_type == "weapon_attachment":
		_build_attachment_visual(color)
	else:
		_build_resource_visual(size, color)

func _build_weapon_pickup_visual(color: Color) -> void:
	var weapon_data := WeaponData.create_weapon(weapon_id)
	var family := weapon_data.weapon_family
	var long_gun := false
	if family == "smg" or family == "ar" or family == "lmg" or family == "thermal":
		long_gun = true
	var length := 0.78
	if long_gun:
		length = 1.15
	var receiver_width := 0.2
	if long_gun:
		receiver_width = 0.18
	var receiver_size := Vector3(receiver_width, 0.18, length * 0.46)
	mesh_instance = _add_box_mesh("PickupWeaponReceiver", receiver_size, Vector3(0.0, 0.02, -length * 0.12), color, 0.0)
	var barrel_radius := 0.028
	if long_gun:
		barrel_radius = 0.035
	_add_cylinder_mesh("PickupWeaponBarrel", barrel_radius, length * 0.52, Vector3(0.0, 0.04, -length * 0.48), color.lightened(0.35), 0.18, Vector3(90.0, 0.0, 0.0))
	_add_box_mesh("PickupWeaponGrip", Vector3(0.14, 0.32, 0.13), Vector3(0.0, -0.21, length * 0.08), Color(0.05, 0.055, 0.06), 0.0, Vector3(-14.0, 0.0, 0.0))
	var magazine_height := 0.22
	if long_gun:
		magazine_height = 0.32
	_add_box_mesh("PickupWeaponMagazine", Vector3(0.14, magazine_height, 0.12), Vector3(0.0, -0.22, -length * 0.12), Color(0.04, 0.045, 0.05), 0.0, Vector3(8.0, 0.0, 0.0))
	_add_box_mesh("PickupWeaponSight", Vector3(0.12, 0.045, 0.06), Vector3(0.0, 0.16, -length * 0.22), Color(0.02, 0.025, 0.025), 0.04)
	if long_gun:
		_add_box_mesh("PickupWeaponStock", Vector3(0.2, 0.2, 0.32), Vector3(0.0, 0.02, length * 0.36), Color(0.06, 0.07, 0.075), 0.0)
		_add_box_mesh("PickupWeaponForeEnd", Vector3(0.16, 0.16, length * 0.28), Vector3(0.0, -0.03, -length * 0.34), color.darkened(0.18), 0.0)

func _build_ammo_visual(color: Color) -> void:
	mesh_instance = _add_box_mesh("AmmoMagazine", Vector3(0.18, 0.24, 0.28), Vector3(0.0, -0.02, 0.0), color.darkened(0.15), 0.0, Vector3(0.0, 0.0, -8.0))
	for index in range(4):
		var x := -0.075 + float(index) * 0.05
		_add_cylinder_mesh("VisibleRound%d" % index, 0.018, 0.2, Vector3(x, 0.13, -0.02), Color(0.86, 0.63, 0.28), 0.05, Vector3(90.0, 0.0, 0.0))

func _build_flashlight_visual(color: Color) -> void:
	mesh_instance = _add_cylinder_mesh("FlashlightBody", 0.08, 0.46, Vector3(0.0, 0.0, 0.0), color, 0.0, Vector3(90.0, 0.0, 0.0))
	_add_cylinder_mesh("FlashlightLens", 0.095, 0.045, Vector3(0.0, 0.0, -0.25), Color(0.72, 0.95, 1.0), 0.45, Vector3(90.0, 0.0, 0.0))
	_add_box_mesh("FlashlightClip", Vector3(0.035, 0.04, 0.25), Vector3(0.0, 0.095, 0.04), Color(0.08, 0.1, 0.1), 0.0)

func _build_resource_visual(size: Vector3, color: Color) -> void:
	mesh_instance = _add_box_mesh("SupplyPouch", Vector3(size.x, size.y * 0.7, size.z), Vector3.ZERO, color, 0.0)
	_add_box_mesh("SupplyStrapA", Vector3(size.x * 1.05, size.y * 0.12, size.z * 0.18), Vector3(0.0, size.y * 0.18, -size.z * 0.18), color.darkened(0.45), 0.0)
	_add_box_mesh("SupplyStrapB", Vector3(size.x * 0.18, size.y * 0.12, size.z * 1.05), Vector3(-size.x * 0.18, size.y * 0.18, 0.0), color.darkened(0.45), 0.0)
	_add_box_mesh("SupplyLabelPlate", Vector3(size.x * 0.5, size.y * 0.22, size.z * 0.08), Vector3(0.0, size.y * 0.04, -size.z * 0.54), Color(0.78, 0.76, 0.58), 0.08)

func _build_wearable_visual(color: Color) -> void:
	mesh_instance = _add_box_mesh("WearableModuleCore", Vector3(0.24, 0.08, 0.18), Vector3(0.0, 0.0, 0.0), color, 0.18)
	_add_cylinder_mesh("WearableLensLeft", 0.055, 0.018, Vector3(-0.09, 0.0, -0.11), Color(0.45, 0.95, 1.0), 0.45, Vector3(90.0, 0.0, 0.0))
	_add_cylinder_mesh("WearableLensRight", 0.055, 0.018, Vector3(0.09, 0.0, -0.11), Color(0.45, 0.95, 1.0), 0.45, Vector3(90.0, 0.0, 0.0))
	_add_box_mesh("WearableBridge", Vector3(0.08, 0.025, 0.025), Vector3(0.0, 0.0, -0.12), color.lightened(0.18), 0.0)

func _build_attachment_visual(color: Color) -> void:
	if attachment_id == "compact_suppressor":
		mesh_instance = _add_cylinder_mesh("SuppressorTube", 0.055, 0.36, Vector3(0.0, 0.0, 0.0), Color(0.08, 0.09, 0.09), 0.0, Vector3(90.0, 0.0, 0.0))
	elif attachment_id == "port_compensator":
		mesh_instance = _add_box_mesh("CompensatorBlock", Vector3(0.16, 0.12, 0.2), Vector3.ZERO, color, 0.0)
		_add_box_mesh("CompensatorPortA", Vector3(0.13, 0.025, 0.035), Vector3(0.0, 0.07, -0.04), Color(0.02, 0.02, 0.02), 0.0)
		_add_box_mesh("CompensatorPortB", Vector3(0.13, 0.025, 0.035), Vector3(0.0, 0.07, 0.04), Color(0.02, 0.02, 0.02), 0.0)
	elif attachment_id == "reflex_sight":
		mesh_instance = _add_box_mesh("ReflexSightBase", Vector3(0.22, 0.05, 0.16), Vector3(0.0, -0.035, 0.0), color, 0.0)
		_add_box_mesh("ReflexGlass", Vector3(0.16, 0.12, 0.018), Vector3(0.0, 0.06, -0.02), Color(0.35, 0.95, 1.0), 0.42)
	elif attachment_id == "laser_pointer" or attachment_id == "weapon_light":
		mesh_instance = _add_cylinder_mesh("AttachmentTube", 0.045, 0.24, Vector3.ZERO, color, 0.15, Vector3(90.0, 0.0, 0.0))
		_add_cylinder_mesh("AttachmentLens", 0.048, 0.025, Vector3(0.0, 0.0, -0.135), Color(0.1, 0.9, 0.75), 0.55, Vector3(90.0, 0.0, 0.0))
	elif attachment_id == "foregrip":
		mesh_instance = _add_box_mesh("ForegripStem", Vector3(0.11, 0.32, 0.11), Vector3(0.0, -0.04, 0.0), color.darkened(0.1), 0.0, Vector3(6.0, 0.0, 0.0))
	else:
		mesh_instance = _add_box_mesh("AttachmentPack", Vector3(0.22, 0.12, 0.22), Vector3.ZERO, color, 0.08)
		_add_box_mesh("AttachmentDetail", Vector3(0.12, 0.035, 0.24), Vector3(0.0, 0.075, 0.0), color.lightened(0.18), 0.06)

func use(actor: Node) -> void:
	if picked_up:
		return
	picked_up = true
	if equipment_type == "flashlight" and actor and actor.has_method("equip_found_flashlight"):
		actor.equip_found_flashlight(flashlight_mount)
	elif equipment_type == "weapon" and actor and actor.has_method("equip_found_weapon"):
		actor.equip_found_weapon(weapon_id)
	elif equipment_type == "weapon_state" and actor and actor.has_method("equip_found_weapon_state"):
		actor.equip_found_weapon_state(stored_weapon_state)
	elif equipment_type == "ammo" and actor and actor.has_method("add_ammo_by_type"):
		actor.add_ammo_by_type(ammo_type, resource_amount)
	elif equipment_type == "resource" and actor and actor.has_method("add_resource"):
		actor.add_resource(resource_id, resource_amount)
	elif equipment_type == "wearable_module" and actor and actor.has_method("install_wearable_module"):
		actor.install_wearable_module(module_id)
	elif equipment_type == "weapon_attachment" and actor and actor.has_method("install_weapon_attachment"):
		actor.install_weapon_attachment(attachment_id)
	GameEvents.emit_environment_impulse(global_position, 0.7, 0.8, self, "equipment_pickup")
	GameEvents.request_sound("pickup", global_position, 0.8)
	queue_free()

func _add_pickup_light() -> void:
	var light := OmniLight3D.new()
	light.name = "PickupGlow"
	light.light_color = Color(0.7, 0.95, 0.86)
	light.light_energy = 0.5
	light.omni_range = 2.2
	add_child(light)
