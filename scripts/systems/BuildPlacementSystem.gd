extends Node
class_name BuildPlacementSystem

var owner_body: PlayerControllerFPS
var camera: Camera3D
var selected_index: int = 0
var placeables: Array[Dictionary] = []

func setup(new_owner: PlayerControllerFPS, new_camera: Camera3D) -> void:
	owner_body = new_owner
	camera = new_camera
	_build_placeable_catalog()

func _build_placeable_catalog() -> void:
	placeables = [
		_make_placeable("barricade_panel", "Barricade Panel", "door block / hard cover", "cover", Vector3(1.8, 1.25, 0.24), Color(0.24, 0.31, 0.32), 3, 18.0, 70.0, 2.0, 5.0),
		_make_placeable("deployable_cover", "Deployable Cover", "low movable cover", "cover", Vector3(1.45, 0.85, 0.28), Color(0.18, 0.25, 0.28), 3, 12.0, 55.0, 2.0, 4.0),
		_make_placeable("trip_mine", "Trip Mine", "contact blast trap", "trip_mine", Vector3(0.55, 0.18, 0.55), Color(0.45, 0.16, 0.12), 2, 4.0, 20.0, 3.2, 14.0),
		_make_placeable("noise_lure", "Noise Lure", "draws enemies by sound", "noisemaker", Vector3(0.45, 0.3, 0.45), Color(0.16, 0.38, 0.42), 2, 3.0, 18.0, 5.5, 5.0),
		_make_placeable("shock_pylon", "Shock Pylon", "short stun pulse", "shock_pylon", Vector3(0.42, 0.9, 0.42), Color(0.08, 0.35, 0.68), 2, 7.0, 28.0, 2.6, 10.0),
		_make_placeable("gap_brace", "Gap Brace", "wedges gaps or slows pathing", "gap_brace", Vector3(1.1, 0.75, 0.55), Color(0.5, 0.58, 0.54), 3, 6.0, 40.0, 1.4, 3.0),
		_make_placeable("turret_frame", "Turret Frame", "future repairable defense", "turret_stub", Vector3(0.7, 0.82, 0.7), Color(0.28, 0.34, 0.36), 1, 14.0, 65.0, 2.0, 5.0),
		_make_placeable("motion_sensor", "Motion Sensor", "future route alarm", "sensor", Vector3(0.36, 0.52, 0.36), Color(0.08, 0.5, 0.75), 2, 3.0, 16.0, 4.0, 2.0),
		_make_placeable("glow_flare", "Glow Flare", "light and enemy attention", "flare", Vector3(0.24, 0.24, 0.62), Color(0.95, 0.34, 0.12), 4, 1.5, 12.0, 3.5, 2.0),
		_make_placeable("pressure_decoy", "Pressure Decoy", "weight for buttons/physics", "pressure_decoy", Vector3(0.5, 0.35, 0.5), Color(0.37, 0.34, 0.25), 3, 8.0, 30.0, 1.5, 4.0)
	]

func _make_placeable(id: String, label: String, description: String, behavior: String, size: Vector3, color: Color, charges: int, mass_value: float, durability: float, radius: float, impulse: float) -> Dictionary:
	return {
		"id": id,
		"label": label,
		"description": description,
		"behavior": behavior,
		"size": size,
		"color": color,
		"charges": charges,
		"mass": mass_value,
		"durability": durability,
		"radius": radius,
		"impulse": impulse
	}

func cycle_next() -> void:
	if placeables.is_empty():
		return
	selected_index = (selected_index + 1) % placeables.size()

func add_charge_to_selected(amount: int) -> void:
	if placeables.is_empty() or amount <= 0:
		return
	var definition := placeables[selected_index]
	definition["charges"] = int(definition["charges"]) + amount
	placeables[selected_index] = definition

func add_charge_to_item(item_id: String, amount: int) -> bool:
	if placeables.is_empty() or amount <= 0:
		return false
	for index in range(placeables.size()):
		var definition := placeables[index]
		if String(definition["id"]) != item_id:
			continue
		definition["charges"] = int(definition["charges"]) + amount
		placeables[index] = definition
		return true
	return false

func try_place() -> bool:
	if not camera or not owner_body or placeables.is_empty():
		return false
	var definition := placeables[selected_index]
	var charges := int(definition["charges"])
	if charges <= 0:
		return false
	var placement := _get_placement_transform()
	var device := PlaceableDevice3D.new()
	device.configure(definition)
	var scene := get_tree().current_scene
	if not scene:
		return false
	scene.add_child(device)
	device.global_transform = placement
	definition["charges"] = charges - 1
	placeables[selected_index] = definition
	GameEvents.emit_player_noise(device.global_position, 14.0)
	GameEvents.emit_environment_impulse(device.global_position, 0.8, 1.5, device, "place_device")
	return true

func _get_placement_transform() -> Transform3D:
	var forward := -camera.global_transform.basis.z
	var start := camera.global_position
	var end := start + forward * 3.0
	var position := start + forward * 1.8 + Vector3.DOWN * 0.65
	var query := PhysicsRayQueryParameters3D.create(start, end)
	query.exclude = [owner_body.get_rid()]
	query.collision_mask = 1
	query.collide_with_bodies = true
	query.collide_with_areas = false
	var hit := owner_body.get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var hit_position: Vector3 = hit.get("position")
		var hit_normal: Vector3 = hit.get("normal")
		position = hit_position + hit_normal * 0.18
	var basis := Basis(Vector3.UP, owner_body.rotation.y)
	return Transform3D(basis, position)

func get_selected_status() -> String:
	if placeables.is_empty():
		return "NO BUILD"
	var definition := placeables[selected_index]
	return "%s x%d" % [definition["label"], int(definition["charges"])]
