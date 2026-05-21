extends Node
class_name ObjectiveSystem

signal objectives_changed(objectives: Array)
signal objective_triggered(objective_id: String, objective_type: String, sector_id: String, position: Vector3)
signal objective_completed(objective_id: String, objective_type: String, sector_id: String, position: Vector3)
signal all_objectives_completed

var player: PlayerControllerFPS
var arena_root: Node3D
var sector_power: SectorPowerSystem
var threat_director: ThreatDirector
var sectors: Array[Dictionary] = []
var objectives: Array[Dictionary] = []
var objective_nodes: Dictionary = {}
var extraction_zone: ExtractionZone3D
var extraction_available: bool = false
var prepared: bool = false

func setup(new_player: PlayerControllerFPS, new_arena_root: Node3D, new_sector_power: SectorPowerSystem, new_threat_director: ThreatDirector, sector_definitions: Array[Dictionary]) -> void:
	player = new_player
	arena_root = new_arena_root
	sector_power = new_sector_power
	threat_director = new_threat_director
	sectors = sector_definitions.duplicate(true)
	_register_objective_sectors()

func set_player(new_player: PlayerControllerFPS) -> void:
	player = new_player
	if not objectives.is_empty():
		GameEvents.report_objectives_updated(get_objective_snapshot())
	if extraction_available and extraction_zone and is_instance_valid(extraction_zone):
		GameEvents.report_extraction_available(extraction_zone.global_position)

func prepare_run() -> void:
	objectives.clear()
	_clear_objective_nodes()
	extraction_available = false
	if extraction_zone and is_instance_valid(extraction_zone):
		extraction_zone.queue_free()
		extraction_zone = null
	var objective_types: Array[String] = _choose_objective_types()
	var sector_pool: Array[Dictionary] = sectors.duplicate(true)
	sector_pool.shuffle()
	for index in range(objective_types.size()):
		if sector_pool.is_empty():
			break
		var raw_sector: Variant = sector_pool.pop_back()
		if not (raw_sector is Dictionary):
			continue
		var sector: Dictionary = raw_sector
		var objective_type: String = String(objective_types[index])
		var objective: Dictionary = _make_objective_definition(index, objective_type, sector)
		objectives.append(objective)
	prepared = true

func start_run() -> void:
	if not prepared or objectives.is_empty():
		prepare_run()
	_clear_objective_nodes()
	extraction_available = false
	if extraction_zone and is_instance_valid(extraction_zone):
		extraction_zone.queue_free()
		extraction_zone = null
	for objective in objectives:
		_activate_objective_side_effects(objective)
		_spawn_objective_node(objective)
	var snapshot: Array = get_objective_snapshot()
	objectives_changed.emit(snapshot)
	GameEvents.report_objectives_assigned(snapshot)

func get_objective_snapshot() -> Array:
	var snapshot: Array = []
	for objective in objectives:
		snapshot.append(objective.duplicate(true))
	return snapshot

func _register_objective_sectors() -> void:
	if not sector_power:
		return
	for sector in sectors:
		var sector_id: String = String(sector.get("sector_id", "arena"))
		var sector_label: String = String(sector.get("label", sector_id.replace("_", " ")))
		sector_power.register_sector(sector_id, sector_label, true)

func _choose_objective_types() -> Array[String]:
	var types: Array[String] = ["purge_node", "restore_power", "uplink_terminal"]
	types.shuffle()
	var count: int = randi_range(2, 3)
	var chosen: Array[String] = []
	for index in range(count):
		chosen.append(types[index])
	return chosen

func _make_objective_definition(index: int, objective_type: String, sector: Dictionary) -> Dictionary:
	var sector_id: String = String(sector.get("sector_id", "arena"))
	var sector_label: String = String(sector.get("label", sector_id.replace("_", " ")))
	var position: Vector3 = _dictionary_vector3(sector, "position", Vector3.ZERO)
	var objective_id: String = "%s_%s" % [objective_type, sector_id]
	var label: String = "Purge Node"
	var integrity: float = 130.0
	var hold_required: float = 0.0
	if objective_type == "restore_power":
		label = "Restore Power"
		integrity = 999.0
	elif objective_type == "uplink_terminal":
		label = "Uplink Terminal"
		integrity = 999.0
		hold_required = 3.0
	return {
		"id": "%s_%d" % [objective_id, index],
		"type": objective_type,
		"label": label,
		"sector_id": sector_id,
		"sector_label": sector_label,
		"position": position,
		"status": "pending",
		"progress": 0.0,
		"integrity": integrity,
		"hold_required": hold_required
	}

func _activate_objective_side_effects(objective: Dictionary) -> void:
	if not sector_power:
		return
	if String(objective.get("type", "")) == "restore_power":
		sector_power.cut_sector_power(String(objective.get("sector_id", "arena")), "objective_blackout")

func _spawn_objective_node(objective: Dictionary) -> void:
	if not arena_root:
		return
	var node: MissionObjectiveObject3D = MissionObjectiveObject3D.new()
	node.name = "Objective_%s" % String(objective.get("id", "objective"))
	node.configure(objective, sector_power)
	node.global_position = _dictionary_vector3(objective, "position", Vector3.ZERO)
	node.objective_triggered.connect(_on_objective_node_triggered)
	node.objective_completed.connect(_on_objective_node_completed)
	node.objective_progress_changed.connect(_on_objective_node_progress_changed)
	arena_root.add_child(node)
	objective_nodes[String(objective.get("id", ""))] = node

func _on_objective_node_triggered(objective_id: String, objective_type: String, sector_id: String, position: Vector3) -> void:
	_update_objective_state(objective_id, "active", 0.0)
	objective_triggered.emit(objective_id, objective_type, sector_id, position)
	GameEvents.report_objective_triggered(objective_id, objective_type, sector_id, position)

func _on_objective_node_completed(objective_id: String, objective_type: String, sector_id: String, position: Vector3) -> void:
	_update_objective_state(objective_id, "done", 1.0)
	objective_completed.emit(objective_id, objective_type, sector_id, position)
	GameEvents.report_objective_completed(objective_id, objective_type, sector_id, position)
	AudioRouter.play_ui("objective_complete")
	if _all_objectives_done():
		all_objectives_completed.emit()
		GameEvents.report_all_objectives_completed()
		_spawn_extraction_zone()

func _on_objective_node_progress_changed(objective_id: String, progress: float) -> void:
	_update_objective_progress(objective_id, progress)

func _update_objective_state(objective_id: String, new_status: String, progress: float) -> void:
	for index in range(objectives.size()):
		var objective: Dictionary = objectives[index]
		if String(objective.get("id", "")) != objective_id:
			continue
		objective["status"] = new_status
		objective["progress"] = progress
		objectives[index] = objective
		break
	var snapshot: Array = get_objective_snapshot()
	objectives_changed.emit(snapshot)
	GameEvents.report_objectives_updated(snapshot)

func _update_objective_progress(objective_id: String, progress: float) -> void:
	for index in range(objectives.size()):
		var objective: Dictionary = objectives[index]
		if String(objective.get("id", "")) != objective_id:
			continue
		objective["progress"] = clamp(progress, 0.0, 1.0)
		objectives[index] = objective
		break
	var snapshot: Array = get_objective_snapshot()
	objectives_changed.emit(snapshot)
	GameEvents.report_objectives_updated(snapshot)

func _clear_objective_nodes() -> void:
	for node_value in objective_nodes.values():
		if node_value is Node and is_instance_valid(node_value):
			(node_value as Node).queue_free()
	objective_nodes.clear()

func _all_objectives_done() -> bool:
	if objectives.is_empty():
		return false
	for objective in objectives:
		if String(objective.get("status", "pending")) != "done":
			return false
	return true

func _spawn_extraction_zone() -> void:
	if extraction_available or not arena_root:
		return
	extraction_available = true
	var extraction_position: Vector3 = _choose_extraction_position()
	extraction_zone = ExtractionZone3D.new()
	extraction_zone.name = "ExtractionZone"
	extraction_zone.configure(2.85)
	arena_root.add_child(extraction_zone)
	extraction_zone.global_position = extraction_position
	GameEvents.report_extraction_available(extraction_position)
	AudioRouter.play_3d("extraction_beacon", extraction_position, 1.0)
	GameEvents.request_sound("comms", extraction_position, 1.0)
	if player and player.comms:
		player.comms.announce("Objectives complete. Extraction beacon is live.")

func _choose_extraction_position() -> Vector3:
	var candidates: Array[Vector3] = [
		Vector3(0.0, 0.05, -26.0),
		Vector3(0.0, 0.05, 26.0),
		Vector3(22.0, 0.05, 0.0),
		Vector3(-22.0, 0.05, 0.0)
	]
	if not player:
		return candidates[0]
	var best_position: Vector3 = candidates[0]
	var best_distance: float = -1.0
	for candidate in candidates:
		var distance: float = candidate.distance_to(player.global_position)
		if distance > best_distance:
			best_distance = distance
			best_position = candidate
	return best_position

func _dictionary_vector3(source: Dictionary, key: String, fallback: Vector3) -> Vector3:
	var raw_value: Variant = source.get(key, fallback)
	if raw_value is Vector3:
		return raw_value
	return fallback
