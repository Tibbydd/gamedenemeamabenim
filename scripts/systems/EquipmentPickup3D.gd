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
