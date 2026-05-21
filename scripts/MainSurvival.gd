extends Node3D

var player: PlayerControllerFPS
var facility_state: FacilityProgression
var dynamic_world: DynamicWorldSystem
var route_system: StationRouteSystem
var sector_power: SectorPowerSystem
var threat_director: ThreatDirector
var objective_system: ObjectiveSystem
var audio_router: Node
var briefing_screen: MissionBriefingScreen
var enemy_container: Node3D
var arena_root: Node3D
var navigation_region: NavigationRegion3D
var nav_blockers: Array[Dictionary] = []
var sector_lights: Dictionary = {}
var emergency_lights_by_sector: Dictionary = {}
var world_environment: WorldEnvironment
var spawn_points: Array[Node3D] = []
var entry_definitions: Array[Dictionary] = []
var entry_doors: Dictionary = {}
var entry_nodes: Dictionary = {}
var mission_doors_by_sector: Dictionary = {}
var run_finished: bool = false
var survivor_count: int = 0
var current_room_id: String = ""
var successor_spawn_in_progress: bool = false
var selected_role: String = "breacher"
var mission_deployed: bool = false
var ambient_event_timer: float = 0.0

func _ready() -> void:
	randomize()
	_build_facility_state()
	_build_station_route_system()
	_build_sector_power_system()
	_build_dynamic_world_system()
	_build_audio_router()
	_build_lighting()
	_build_arena()
	_spawn_player()
	_build_director()
	_build_objective_system()
	_build_mission_briefing()
	GameEvents.run_ended.connect(_on_run_ended)
	GameEvents.objective_triggered.connect(_on_objective_triggered_callout)
	GameEvents.objective_completed.connect(_on_mission_objective_completed)
	GameEvents.all_objectives_completed.connect(_on_all_objectives_completed_callout)
	GameEvents.extraction_available.connect(_on_extraction_available_callout)

func _process(delta: float) -> void:
	if player and threat_director and not run_finished:
		var exit_located: bool = false
		if objective_system:
			exit_located = objective_system.extraction_available
		player.set_run_time(threat_director.elapsed, exit_located)
	_update_ambient_events(delta)

func _unhandled_input(event: InputEvent) -> void:
	if run_finished and InputBus.wants_restart(event):
		get_tree().reload_current_scene()

func _update_ambient_events(delta: float) -> void:
	ambient_event_timer -= delta
	if ambient_event_timer > 0.0:
		return
	ambient_event_timer = randf_range(12.0, 22.0)
	var ambient_ids: Array[String] = ["ambient_drip", "ambient_clank", "ambient_electric"]
	var sound_id: String = ambient_ids[randi_range(0, ambient_ids.size() - 1)]
	var event_position: Vector3 = Vector3(randf_range(-18.0, 18.0), 2.5, randf_range(-18.0, 18.0))
	AudioRouter.play_3d(sound_id, event_position, 0.6)

func _build_facility_state() -> void:
	facility_state = FacilityProgression.new()
	facility_state.name = "FacilityProgression"
	add_child(facility_state)
	facility_state.door_state_changed.connect(_on_facility_door_state_changed)

func _build_station_route_system() -> void:
	route_system = StationRouteSystem.new()
	route_system.name = "StationRouteSystem"
	add_child(route_system)
	route_system.floor_changed.connect(_on_station_floor_changed)

func _build_sector_power_system() -> void:
	sector_power = SectorPowerSystem.new()
	sector_power.name = "SectorPowerSystem"
	add_child(sector_power)
	sector_power.sector_power_changed.connect(_apply_sector_light_state)

func _build_dynamic_world_system() -> void:
	dynamic_world = DynamicWorldSystem.new()
	dynamic_world.name = "DynamicWorldSystem"
	add_child(dynamic_world)

func _build_audio_router() -> void:
	audio_router = get_node_or_null("/root/AudioRouter")

func _build_lighting() -> void:
	world_environment = WorldEnvironment.new()
	var environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.015, 0.018, 0.024)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.06, 0.085, 0.095)
	environment.ambient_light_energy = 0.22
	environment.fog_enabled = true
	environment.fog_density = 0.038
	environment.fog_light_color = Color(0.12, 0.38, 0.44)
	environment.fog_aerial_perspective = 0.12
	world_environment.environment = environment
	world_environment.add_to_group("world_env")
	add_child(world_environment)
	var moon = DirectionalLight3D.new()
	moon.name = "ColdDirectionalLight"
	moon.rotation_degrees = Vector3(-55, -25, 0)
	moon.light_energy = 0.28
	moon.light_color = Color(0.48, 0.62, 0.82)
	moon.shadow_enabled = true
	moon.directional_shadow_max_distance = 80.0
	add_child(moon)

func _build_arena() -> void:
	arena_root = Node3D.new()
	arena_root.name = "GreyboxRuinedFacility"
	add_child(arena_root)
	enemy_container = Node3D.new()
	enemy_container.name = "Enemies"
	add_child(enemy_container)
	_create_box("Floor", Vector3(0, -0.1, 0), Vector3(72, 0.2, 72), Color(0.105, 0.115, 0.122), true, "deck")
	_create_box("StationCeiling", Vector3(0, 4.15, 0), Vector3(72, 0.24, 72), Color(0.08, 0.095, 0.105), true, "ceiling")
	_create_box("NorthOuterWall", Vector3(0, 2.12, -36), Vector3(72, 4.28, 0.7), Color(0.16, 0.18, 0.2), true, "bulkhead")
	_create_box("SouthOuterWall", Vector3(0, 2.12, 36), Vector3(72, 4.28, 0.7), Color(0.16, 0.18, 0.2), true, "bulkhead")
	_create_box("WestOuterWall", Vector3(-36, 2.12, 0), Vector3(0.7, 4.28, 72), Color(0.16, 0.18, 0.2), true, "bulkhead")
	_create_box("EastOuterWall", Vector3(36, 2.12, 0), Vector3(0.7, 4.28, 72), Color(0.16, 0.18, 0.2), true, "bulkhead")
	nav_blockers.clear()
	_build_room_shell_geometry()
	var cover_specs: Array[Dictionary] = [
		{"position": Vector3(-8, 0.75, -5), "size": Vector3(5, 1.5, 1.2)},
		{"position": Vector3(8, 0.75, 4), "size": Vector3(5, 1.5, 1.2)},
		{"position": Vector3(-3, 1.0, 9), "size": Vector3(1.4, 2.0, 5)},
		{"position": Vector3(4, 1.0, -10), "size": Vector3(1.4, 2.0, 5)},
		{"position": Vector3(-13, 0.6, 8), "size": Vector3(3, 1.2, 3)},
		{"position": Vector3(13, 0.6, -7), "size": Vector3(3, 1.2, 3)}
	]
	for spec in cover_specs:
		var cover_position: Vector3 = _dict_vector3(spec, "position", Vector3.ZERO)
		var cover_size: Vector3 = _dict_vector3(spec, "size", Vector3.ONE)
		_create_box("RuinCover", cover_position, cover_size, Color(0.22, 0.23, 0.24), true)
		_register_nav_blocker(cover_position, cover_size)
	_build_navigation_region()
	for point in [
		Vector3(-31, 0, -31),
		Vector3(31, 0, -31),
		Vector3(-31, 0, 31),
		Vector3(31, 0, 31),
		Vector3(0, 0, -32),
		Vector3(0, 0, 32),
		Vector3(-32, 0, 0),
		Vector3(32, 0, 0)
	]:
		var spawn = Node3D.new()
		spawn.name = "ThreatSpawn"
		spawn.position = point
		arena_root.add_child(spawn)
		spawn_points.append(spawn)
	_create_warning_lights()
	_build_survivor_entry_scenarios()
	_build_hidden_route_markers()
	_build_dynamic_environment_props()
	_build_interior_partitions()
	_build_vent_markers()
	_build_npc_survivors()
	ambient_event_timer = randf_range(6.0, 12.0)

func _register_nav_blocker(world_position: Vector3, size: Vector3) -> void:
	nav_blockers.append({
		"min_x": world_position.x - size.x * 0.5,
		"max_x": world_position.x + size.x * 0.5,
		"min_z": world_position.z - size.z * 0.5,
		"max_z": world_position.z + size.z * 0.5
	})

func _build_navigation_region() -> void:
	if navigation_region and is_instance_valid(navigation_region):
		navigation_region.queue_free()
	navigation_region = NavigationRegion3D.new()
	navigation_region.name = "ArenaNavigationRegion"
	var nav_mesh = NavigationMesh.new()
	var vertices: Array = []
	var vertex_lookup: Dictionary = {}
	var polygons: Array = []
	var cell_size = 2.0
	var min_coord = -34.0
	var cell_count = 34
	for x_index in range(cell_count):
		for z_index in range(cell_count):
			var min_x = min_coord + float(x_index) * cell_size
			var min_z = min_coord + float(z_index) * cell_size
			var max_x = min_x + cell_size
			var max_z = min_z + cell_size
			if _nav_cell_blocked(min_x, max_x, min_z, max_z):
				continue
			var polygon = PackedInt32Array([
				_get_nav_vertex(vertices, vertex_lookup, Vector3(min_x, 0.0, min_z)),
				_get_nav_vertex(vertices, vertex_lookup, Vector3(max_x, 0.0, min_z)),
				_get_nav_vertex(vertices, vertex_lookup, Vector3(max_x, 0.0, max_z)),
				_get_nav_vertex(vertices, vertex_lookup, Vector3(min_x, 0.0, max_z))
			])
			polygons.append(polygon)
	var packed_vertices = PackedVector3Array()
	for vertex in vertices:
		packed_vertices.append(vertex)
	nav_mesh.set_vertices(packed_vertices)
	for polygon in polygons:
		nav_mesh.add_polygon(polygon)
	navigation_region.navigation_mesh = nav_mesh
	arena_root.add_child(navigation_region)

func _on_facility_door_state_changed(_door_id: String, _state: String) -> void:
	if not arena_root:
		return
	if _state == FacilityProgression.DOOR_SEALED:
		_reveal_routes_near_sealed_room(_door_id)
	_build_navigation_region()

func _reveal_routes_near_sealed_room(door_id: String) -> void:
	if not facility_state.doors.has(door_id):
		return
	var room_id = String(facility_state.doors[door_id].get("room_id", ""))
	for route_id in facility_state.hidden_routes.keys():
		var route: Dictionary = facility_state.hidden_routes[route_id]
		if String(route.get("start_room_id", "")) == room_id or String(route.get("end_room_id", "")) == room_id:
			facility_state.mark_route_discovered(String(route_id))
			facility_state.unlock_flag("route_revealed_by_%s" % door_id)

func _get_nav_vertex(vertices: Array, vertex_lookup: Dictionary, point: Vector3) -> int:
	var key = "%d:%d" % [roundi(point.x * 10.0), roundi(point.z * 10.0)]
	if vertex_lookup.has(key):
		return int(vertex_lookup[key])
	var index = vertices.size()
	vertices.append(point)
	vertex_lookup[key] = index
	return index

func _nav_cell_blocked(min_x: float, max_x: float, min_z: float, max_z: float) -> bool:
	var clearance = 0.7
	for blocker in nav_blockers:
		var block_min_x = float(blocker["min_x"]) - clearance
		var block_max_x = float(blocker["max_x"]) + clearance
		var block_min_z = float(blocker["min_z"]) - clearance
		var block_max_z = float(blocker["max_z"]) + clearance
		if max_x <= block_min_x or min_x >= block_max_x:
			continue
		if max_z <= block_min_z or min_z >= block_max_z:
			continue
		return true
	return false

func _build_room_shell_geometry() -> void:
	var floor_color: Color = Color(0.09, 0.105, 0.112)
	var ceiling_color: Color = Color(0.062, 0.076, 0.084)
	var room_specs: Array[Dictionary] = [
		{"name": "CentralHub", "position": Vector3(0.0, 0.0, 0.0), "size": Vector2(12.0, 12.0), "floor_color": Color(0.105, 0.118, 0.126)},
		{"name": "NorthCorridor", "position": Vector3(0.0, 0.0, -14.0), "size": Vector2(4.0, 16.0), "floor_color": Color(0.08, 0.095, 0.105)},
		{"name": "SouthCorridor", "position": Vector3(0.0, 0.0, 14.0), "size": Vector2(4.0, 16.0), "floor_color": Color(0.08, 0.095, 0.105)},
		{"name": "EastConnector", "position": Vector3(11.5, 0.0, 0.0), "size": Vector2(11.0, 4.0), "floor_color": Color(0.08, 0.095, 0.105)},
		{"name": "WestConnector", "position": Vector3(-11.5, 0.0, 0.0), "size": Vector2(11.0, 4.0), "floor_color": Color(0.08, 0.095, 0.105)},
		{"name": "EastWing", "position": Vector3(22.0, 0.0, 0.0), "size": Vector2(10.0, 8.0), "floor_color": Color(0.085, 0.11, 0.12)},
		{"name": "WestWing", "position": Vector3(-22.0, 0.0, 0.0), "size": Vector2(10.0, 8.0), "floor_color": Color(0.075, 0.105, 0.115)},
		{"name": "NorthRoom", "position": Vector3(0.0, 0.0, -26.0), "size": Vector2(8.0, 8.0), "floor_color": Color(0.095, 0.105, 0.12)},
		{"name": "SouthRoom", "position": Vector3(0.0, 0.0, 26.0), "size": Vector2(8.0, 8.0), "floor_color": Color(0.105, 0.1, 0.082)}
	]
	for spec in room_specs:
		var room_name: String = String(spec.get("name", "Room"))
		var room_position: Vector3 = _dict_vector3(spec, "position", Vector3.ZERO)
		var room_size: Vector2 = Vector2(8.0, 8.0)
		var raw_size: Variant = spec.get("size", room_size)
		if raw_size is Vector2:
			room_size = raw_size
		var room_floor_color: Color = _dict_color(spec, "floor_color", floor_color)
		_create_box("%sFloorPlate" % room_name, room_position + Vector3(0.0, 0.016, 0.0), Vector3(room_size.x, 0.028, room_size.y), room_floor_color, false, "deck")
		_create_box("%sCeilingPanel" % room_name, room_position + Vector3(0.0, 3.1, 0.0), Vector3(room_size.x, 0.14, room_size.y), ceiling_color, true, "ceiling")
	_build_hub_boundary_walls()
	_build_corridor_boundary_walls()
	_build_wing_boundary_walls()
	_build_terminal_room_boundary_walls()

func _build_hub_boundary_walls() -> void:
	_create_structural_wall("HubNorthWallWest", Vector3(-4.5, 1.55, -6.0), Vector3(3.0, 3.1, 0.32))
	_create_structural_wall("HubNorthWallEast", Vector3(4.5, 1.55, -6.0), Vector3(3.0, 3.1, 0.32))
	_create_structural_wall("HubSouthWallWest", Vector3(-4.5, 1.55, 6.0), Vector3(3.0, 3.1, 0.32))
	_create_structural_wall("HubSouthWallEast", Vector3(4.5, 1.55, 6.0), Vector3(3.0, 3.1, 0.32))
	_create_structural_wall("HubWestWallNorth", Vector3(-6.0, 1.55, -4.5), Vector3(0.32, 3.1, 3.0))
	_create_structural_wall("HubWestWallSouth", Vector3(-6.0, 1.55, 4.5), Vector3(0.32, 3.1, 3.0))
	_create_structural_wall("HubEastWallNorth", Vector3(6.0, 1.55, -4.5), Vector3(0.32, 3.1, 3.0))
	_create_structural_wall("HubEastWallSouth", Vector3(6.0, 1.55, 4.5), Vector3(0.32, 3.1, 3.0))

func _build_corridor_boundary_walls() -> void:
	_create_structural_wall("NorthCorridorWestWall", Vector3(-2.0, 1.55, -14.0), Vector3(0.32, 3.1, 16.0))
	_create_structural_wall("NorthCorridorEastWall", Vector3(2.0, 1.55, -14.0), Vector3(0.32, 3.1, 16.0))
	_create_structural_wall("SouthCorridorWestWall", Vector3(-2.0, 1.55, 14.0), Vector3(0.32, 3.1, 16.0))
	_create_structural_wall("SouthCorridorEastWall", Vector3(2.0, 1.55, 14.0), Vector3(0.32, 3.1, 16.0))
	_create_structural_wall("EastConnectorNorthWall", Vector3(11.5, 1.55, -2.0), Vector3(11.0, 3.1, 0.32))
	_create_structural_wall("EastConnectorSouthWall", Vector3(11.5, 1.55, 2.0), Vector3(11.0, 3.1, 0.32))
	_create_structural_wall("WestConnectorNorthWall", Vector3(-11.5, 1.55, -2.0), Vector3(11.0, 3.1, 0.32))
	_create_structural_wall("WestConnectorSouthWall", Vector3(-11.5, 1.55, 2.0), Vector3(11.0, 3.1, 0.32))

func _build_wing_boundary_walls() -> void:
	_create_structural_wall("EastWingNorthWall", Vector3(22.0, 1.55, -4.0), Vector3(10.0, 3.1, 0.32))
	_create_structural_wall("EastWingSouthWall", Vector3(22.0, 1.55, 4.0), Vector3(10.0, 3.1, 0.32))
	_create_structural_wall("EastWingEastWall", Vector3(27.0, 1.55, 0.0), Vector3(0.32, 3.1, 8.0))
	_create_structural_wall("EastWingWestWallNorth", Vector3(17.0, 1.55, -3.0), Vector3(0.32, 3.1, 2.0))
	_create_structural_wall("EastWingWestWallSouth", Vector3(17.0, 1.55, 3.0), Vector3(0.32, 3.1, 2.0))
	_create_structural_wall("WestWingNorthWall", Vector3(-22.0, 1.55, -4.0), Vector3(10.0, 3.1, 0.32))
	_create_structural_wall("WestWingSouthWall", Vector3(-22.0, 1.55, 4.0), Vector3(10.0, 3.1, 0.32))
	_create_structural_wall("WestWingWestWall", Vector3(-27.0, 1.55, 0.0), Vector3(0.32, 3.1, 8.0))
	_create_structural_wall("WestWingEastWallNorth", Vector3(-17.0, 1.55, -3.0), Vector3(0.32, 3.1, 2.0))
	_create_structural_wall("WestWingEastWallSouth", Vector3(-17.0, 1.55, 3.0), Vector3(0.32, 3.1, 2.0))

func _build_terminal_room_boundary_walls() -> void:
	_create_structural_wall("NorthRoomNorthWall", Vector3(0.0, 1.55, -30.0), Vector3(8.0, 3.1, 0.32))
	_create_structural_wall("NorthRoomWestWall", Vector3(-4.0, 1.55, -26.0), Vector3(0.32, 3.1, 8.0))
	_create_structural_wall("NorthRoomEastWall", Vector3(4.0, 1.55, -26.0), Vector3(0.32, 3.1, 8.0))
	_create_structural_wall("NorthRoomSouthWallWest", Vector3(-3.0, 1.55, -22.0), Vector3(2.0, 3.1, 0.32))
	_create_structural_wall("NorthRoomSouthWallEast", Vector3(3.0, 1.55, -22.0), Vector3(2.0, 3.1, 0.32))
	_create_structural_wall("SouthRoomSouthWall", Vector3(0.0, 1.55, 30.0), Vector3(8.0, 3.1, 0.32))
	_create_structural_wall("SouthRoomWestWall", Vector3(-4.0, 1.55, 26.0), Vector3(0.32, 3.1, 8.0))
	_create_structural_wall("SouthRoomEastWall", Vector3(4.0, 1.55, 26.0), Vector3(0.32, 3.1, 8.0))
	_create_structural_wall("SouthRoomNorthWallWest", Vector3(-3.0, 1.55, 22.0), Vector3(2.0, 3.1, 0.32))
	_create_structural_wall("SouthRoomNorthWallEast", Vector3(3.0, 1.55, 22.0), Vector3(2.0, 3.1, 0.32))

func _create_structural_wall(wall_name: String, world_position: Vector3, size: Vector3) -> void:
	_create_box(wall_name, world_position, size, Color(0.12, 0.145, 0.158), true, "bulkhead")
	_register_nav_blocker(world_position, size)

func _dict_vector3(source: Dictionary, key: String, fallback: Vector3) -> Vector3:
	var raw_value: Variant = source.get(key, fallback)
	if raw_value is Vector3:
		return raw_value
	return fallback

func _dict_color(source: Dictionary, key: String, fallback: Color) -> Color:
	var raw_value: Variant = source.get(key, fallback)
	if raw_value is Color:
		return raw_value
	return fallback

func _create_warning_lights() -> void:
	sector_lights["arena"] = []
	for sector in _get_mission_sector_definitions():
		var sector_id: String = String(sector.get("sector_id", "arena"))
		if not sector_lights.has(sector_id):
			sector_lights[sector_id] = []
		if not emergency_lights_by_sector.has(sector_id):
			emergency_lights_by_sector[sector_id] = []
	var fixture_points: Array[Vector3] = [
		Vector3(0, 3.72, -28),
		Vector3(0, 3.72, -18),
		Vector3(0, 3.72, -8),
		Vector3(0, 3.72, 8),
		Vector3(0, 3.72, 18),
		Vector3(0, 3.72, 28),
		Vector3(-28, 3.72, 0),
		Vector3(-18, 3.72, 0),
		Vector3(-8, 3.72, 0),
		Vector3(8, 3.72, 0),
		Vector3(18, 3.72, 0),
		Vector3(28, 3.72, 0),
		Vector3(-24, 3.72, -24),
		Vector3(24, 3.72, 24),
		Vector3(24, 3.72, -24),
		Vector3(-24, 3.72, 24)
		]
	for index in range(fixture_points.size()):
		var point: Vector3 = fixture_points[index]
		var sector_id: String = _sector_id_for_world_position(point)
		_create_sector_ceiling_light(sector_id, "CeilingFixture%d" % index, point, 8.5)
	var sector_fixture_specs: Array[Dictionary] = [
		{"sector_id": "medical_bay", "name": "MedicalBayRoomFixture", "position": Vector3(-2.0, 3.72, -26.0)},
		{"sector_id": "reactor_control", "name": "ReactorControlRoomFixture", "position": Vector3(2.0, 3.72, -26.0)},
		{"sector_id": "cargo_processing", "name": "CargoProcessingRoomFixture", "position": Vector3(2.0, 3.72, 26.0)},
		{"sector_id": "hab_commons", "name": "HabCommonsRoomFixture", "position": Vector3(-2.0, 3.72, 26.0)},
		{"sector_id": "security_spine", "name": "SecuritySpineWingFixture", "position": Vector3(22.0, 3.72, -1.6)},
		{"sector_id": "comms_nook", "name": "CommsNookWingFixture", "position": Vector3(-22.0, 3.72, 1.6)}
	]
	for spec in sector_fixture_specs:
		_create_sector_ceiling_light(
			String(spec.get("sector_id", "arena")),
			String(spec.get("name", "SectorFixture")),
			_dict_vector3(spec, "position", Vector3.ZERO),
			7.0
		)
	for sector in _get_mission_sector_definitions():
		var sector_id: String = String(sector.get("sector_id", "arena"))
		var sector_position: Vector3 = _dict_vector3(sector, "position", Vector3.ZERO)
		_create_emergency_strip_light(sector_id, sector_position + Vector3(0.0, 3.35, 0.0))
	if sector_power:
		sector_power.register_sector("arena", "Prototype Combat Arena", true)
		_apply_sector_light_state("arena", true, "initial_power")

func _create_ceiling_fixture(fixture_name: String, world_position: Vector3) -> void:
	_create_box(fixture_name + "_Housing", world_position + Vector3(0.0, 0.16, 0.0), Vector3(1.55, 0.08, 0.34), Color(0.045, 0.055, 0.06), false)
	_create_box(fixture_name + "_GlowStrip", world_position + Vector3(0.0, 0.1, 0.0), Vector3(1.18, 0.035, 0.12), Color(0.28, 0.95, 0.86), false)

func _create_sector_ceiling_light(sector_id: String, fixture_name: String, world_position: Vector3, light_range: float) -> void:
	_create_ceiling_fixture(fixture_name, world_position)
	var light: OmniLight3D = OmniLight3D.new()
	light.light_color = Color(0.1, 0.9, 0.82)
	light.light_energy = 2.1
	light.omni_range = light_range
	light.shadow_enabled = true
	light.position = world_position
	arena_root.add_child(light)
	var lights: Array = []
	var raw_lights: Variant = sector_lights.get(sector_id, [])
	if raw_lights is Array:
		lights = raw_lights
	lights.append(light)
	sector_lights[sector_id] = lights

func _create_emergency_strip_light(sector_id: String, world_position: Vector3) -> void:
	_create_box("EmergencyStrip_%s_Housing" % sector_id, world_position + Vector3(0.0, 0.08, 0.0), Vector3(1.05, 0.06, 0.16), Color(0.08, 0.035, 0.035), false)
	var light: OmniLight3D = OmniLight3D.new()
	light.name = "EmergencyLight_%s" % sector_id
	light.light_color = Color(0.9, 0.06, 0.04)
	light.light_energy = 0.0
	light.omni_range = 4.0
	light.shadow_enabled = false
	light.position = world_position
	light.add_to_group("emergency_lights_%s" % sector_id)
	arena_root.add_child(light)
	var lights: Array = []
	var raw_lights: Variant = emergency_lights_by_sector.get(sector_id, [])
	if raw_lights is Array:
		lights = raw_lights
	lights.append(light)
	emergency_lights_by_sector[sector_id] = lights

func _sector_id_for_world_position(world_position: Vector3) -> String:
	var best_sector: String = "arena"
	var best_distance: float = 999999.0
	for sector in _get_mission_sector_definitions():
		var sector_id: String = String(sector.get("sector_id", "arena"))
		var sector_position: Vector3 = _dict_vector3(sector, "position", Vector3.ZERO)
		var distance: float = Vector2(world_position.x - sector_position.x, world_position.z - sector_position.z).length()
		if distance < best_distance:
			best_distance = distance
			best_sector = sector_id
	return best_sector

func _spawn_player() -> void:
	_spawn_survivor("initial")

func _spawn_survivor(entry_reason: String) -> void:
	var entry = facility_state.choose_successor_entry()
	if entry.is_empty():
		entry = {
			"room_id": "south_hab_pressure_door",
			"entry_position": Vector3(0, 0.05, 16.6),
			"explored": false,
			"visits": 0
		}
	current_room_id = String(entry["room_id"])
	var entry_position: Vector3 = _dict_vector3(entry, "entry_position", Vector3.ZERO)
	var was_explored = bool(entry["explored"])
	var entry_definition = _get_entry_definition(current_room_id)
	var access_state = _scar_entry_for_definition(entry_definition)
	facility_state.record_survivor_entry(current_room_id)
	survivor_count += 1
	player = PlayerControllerFPS.new()
	player.name = "Player"
	add_child(player)
	player.global_position = entry_position
	var look_target = Vector3.ZERO
	look_target.y = player.global_position.y
	if player.global_position.distance_to(look_target) > 0.1:
		player.look_at(look_target, Vector3.UP)
		player.yaw = player.rotation.y
	player.died.connect(_on_player_died)
	var intro_style = String(entry_definition.get("intro_style", "door"))
	player.play_spawn_intro(_make_spawn_text(current_room_id, entry_definition, access_state, was_explored, entry_reason), intro_style)
	player.apply_survivor_loadout(_generate_survivor_loadout(entry_reason))
	if player.comms and route_system:
		player.comms.set_floor_signal_distance(route_system.current_floor)
	_apply_background_entry_bonuses(player.survivor_loadout)
	if threat_director:
		threat_director.set_player(player)
	if objective_system:
		objective_system.set_player(player)
	if survivor_count > 1:
		_erode_existing_lost_kits()
		_spawn_successor_only_pickups(entry_position)
		_spawn_entry_pursuers(entry_position, entry_definition)

func _apply_background_entry_bonuses(loadout: Dictionary) -> void:
	if String(loadout.get("background", "")) != "Survey Tech":
		return
	for route_id in facility_state.hidden_routes.keys():
		var route: Dictionary = facility_state.hidden_routes[route_id]
		if bool(route.get("discovered", false)):
			continue
		facility_state.mark_route_discovered(String(route_id))
		if player and player.comms:
			player.comms.announce("Survey instinct found a route hint: %s." % String(route_id).replace("_", " "))
		break

func _erode_existing_lost_kits() -> void:
	for kit in get_tree().get_nodes_in_group("lost_survivor_kits"):
		if kit is LostSurvivorKit3D:
			(kit as LostSurvivorKit3D).erode_contents("successor_delay")

func _spawn_successor_only_pickups(entry_position: Vector3) -> void:
	if survivor_count != 2 or randf() > 0.65:
		return
	_create_resource_pickup("SuccessorAdminCredential", entry_position + Vector3(1.1, 0.35, 0.6), "access_credential", 1)

func _generate_survivor_loadout(entry_reason: String) -> Dictionary:
	var backgrounds = [
		"Security",
		"Engineer",
		"Medic",
		"Miner",
		"Courier",
		"Researcher",
		"Mechanic",
		"Prisoner",
		"Station Cook",
		"Survey Tech"
	]
	var flashlight_roll = randf()
	var flashlight_type = "none"
	if flashlight_roll < 0.18:
		flashlight_type = "none"
	elif flashlight_roll < 0.42:
		flashlight_type = "handheld"
	elif flashlight_roll < 0.66:
		flashlight_type = "vest"
	elif flashlight_roll < 0.86:
		flashlight_type = "helmet"
	else:
		flashlight_type = "weapon_mount"
	var starts_with_headset = survivor_count == 1
	var weapon_id = _pick_starting_weapon_id()
	var weapon_data = WeaponData.create_weapon(weapon_id)
	var loadout: Dictionary = {
		"background": backgrounds[randi() % backgrounds.size()],
		"role": selected_role,
		"weapon_id": weapon_id,
		"weapon_attachments": _roll_starting_weapon_attachments(),
		"wearable_modules": _roll_starting_wearable_modules(),
		"flashlight": flashlight_type,
		"has_headset": starts_with_headset,
		"extra_ammo": randi_range(0, 18),
		"recoverable_ammo": randi_range(8, 24),
		"recoverable_ammo_type": weapon_data.ammo_type,
		"recoverable_build_item": _pick_recoverable_build_item(),
		"recoverable_build_charge": randi_range(0, 1),
		"resources": _roll_starting_resources(),
		"entry_reason": entry_reason
	}
	if mission_deployed:
		_apply_role_to_loadout(loadout, selected_role)
	return loadout

func _pick_starting_weapon_id() -> String:
	var pool = [
		"m7_colony_pistol",
		"m3_holdout",
		"m9_security_revolver",
		"rattler_smg",
		"hushline_smg",
		"a12_service_rifle",
		"station_guard_carbine",
		"torch_lance"
	]
	return pool[randi() % pool.size()]

func _roll_starting_resources() -> Dictionary:
	var resources = {}
	var possible = ["fuse", "power_cell", "cable_spool", "tool_parts", "access_credential"]
	for resource_id in possible:
		if randf() < 0.22:
			resources[resource_id] = randi_range(1, 2)
	return resources

func _pick_recoverable_build_item() -> String:
	var pool = ["barricade_panel", "deployable_cover", "trip_mine", "noise_lure", "shock_pylon", "gap_brace", "glow_flare", "pressure_decoy"]
	return pool[randi() % pool.size()]

func _roll_starting_wearable_modules() -> Array[String]:
	var modules: Array[String] = []
	if randf() < 0.16:
		modules.append("hud_glasses")
		if randf() < 0.45:
			modules.append("compass_module")
		if randf() < 0.22:
			modules.append("brainwave_reader")
	return modules

func _roll_starting_weapon_attachments() -> Array[String]:
	var attachments: Array[String] = []
	var pool = ["compact_suppressor", "port_compensator", "reflex_sight", "foregrip", "quickpull_magwell", "retention_sling"]
	if randf() < 0.2:
		attachments.append(pool[randi() % pool.size()])
	return attachments

func _build_survivor_entry_scenarios() -> void:
	entry_definitions.clear()
	entry_definitions.append(_make_entry_definition("south_hab_pressure_door", "entry_south_hab_pressure_door", "pressure_door", "Hab pressure door", "door", Vector3(0, 0.05, 16.6), Vector3(0, 1.1, 20.62), Vector3(4.2, 2.2, 0.28), Color(0.16, 0.22, 0.24), true, 2, "door_south_hab"))
	entry_definitions.append(_make_entry_definition("north_service_airlock_tumble", "entry_north_service_airlock", "airlock", "Emergency airlock tumble", "tumble", Vector3(0, 0.05, -16.6), Vector3(0, 1.1, -20.62), Vector3(4.2, 2.2, 0.28), Color(0.13, 0.18, 0.24), true, 1, "door_north_service"))
	entry_definitions.append(_make_entry_definition("west_maintenance_crawl", "entry_west_maintenance_crawl", "crawlspace", "Maintenance crawlspace", "crawl", Vector3(-16.6, 0.05, 0), Vector3(-20.62, 0.62, 0), Vector3(0.18, 0.72, 2.3), Color(0.06, 0.09, 0.1), false, 1))
	entry_definitions.append(_make_entry_definition("east_ceiling_catwalk_fall", "entry_east_ceiling_catwalk", "catwalk", "Ceiling catwalk drop", "catwalk", Vector3(16.6, 0.05, 0), Vector3(13.0, 3.05, 0), Vector3(4.8, 0.18, 1.0), Color(0.12, 0.18, 0.18), false, 2))
	entry_definitions.append(_make_entry_definition("reactor_vent_drop", "entry_reactor_vent_drop", "vent_drop", "Broken reactor vent", "fall", Vector3(-15.5, 0.05, 14.2), Vector3(-15.5, 2.9, 14.2), Vector3(1.5, 0.16, 1.5), Color(0.04, 0.08, 0.08), false, 1))
	entry_definitions.append(_make_entry_definition("cargo_lift_crash", "entry_cargo_lift_crash", "cargo_lift", "Crashed cargo lift", "pod", Vector3(15.5, 0.05, -14.2), Vector3(18.9, 0.45, -14.2), Vector3(2.4, 0.9, 2.4), Color(0.19, 0.2, 0.18), false, 2))
	entry_definitions.append(_make_entry_definition("elevator_shaft_ladder", "entry_elevator_shaft_ladder", "elevator_shaft", "Elevator shaft ladder", "shaft", Vector3(-3.0, 0.05, -16.5), Vector3(-3.0, 2.0, -20.55), Vector3(1.4, 3.8, 0.18), Color(0.12, 0.12, 0.1), false, 1))
	entry_definitions.append(_make_entry_definition("floor_hatch_crawlout", "entry_floor_hatch_crawlout", "floor_hatch", "Buckled floor hatch", "crawl", Vector3(5.0, 0.05, 15.5), Vector3(5.0, 0.02, 18.7), Vector3(1.8, 0.08, 1.4), Color(0.05, 0.06, 0.06), false, 0))
	entry_definitions.append(_make_entry_definition("med_pod_eject", "entry_med_pod_eject", "med_pod", "Cracked med pod", "pod", Vector3(-12.0, 0.05, -13.0), Vector3(-14.0, 0.7, -14.8), Vector3(1.5, 1.1, 0.8), Color(0.18, 0.28, 0.3), false, 0))
	entry_definitions.append(_make_entry_definition("service_pipe_drop", "entry_service_pipe_drop", "service_pipe", "Overhead service pipe", "fall", Vector3(11.0, 0.05, 12.0), Vector3(11.0, 3.05, 12.0), Vector3(2.0, 0.2, 0.8), Color(0.08, 0.09, 0.1), false, 1))
	entry_definitions.append(_make_entry_definition("exterior_breach_tumble", "entry_exterior_breach_tumble", "exterior_breach", "Hull breach lock", "tumble", Vector3(17.0, 0.05, 7.0), Vector3(20.55, 1.4, 7.0), Vector3(0.2, 2.5, 2.1), Color(0.09, 0.13, 0.17), false, 2))
	entry_definitions.append(_make_entry_definition("waste_chute_spill", "entry_waste_chute_spill", "waste_chute", "Waste chute spill", "fall", Vector3(-10.0, 0.05, 3.0), Vector3(-10.0, 2.45, 3.0), Vector3(1.2, 0.24, 1.2), Color(0.11, 0.12, 0.08), false, 1))
	for definition in entry_definitions:
		var room_id = String(definition["room_id"])
		var access_id = String(definition["access_id"])
		var access_kind = String(definition["access_kind"])
		var room_entry: Vector3 = _dict_vector3(definition, "entry", Vector3.ZERO)
		var marker_position: Vector3 = _dict_vector3(definition, "marker_position", Vector3.ZERO)
		var marker_size: Vector3 = _dict_vector3(definition, "marker_size", Vector3.ONE)
		var marker_color: Color = _dict_color(definition, "marker_color", Color(0.14, 0.18, 0.18))
		var marker_collision = bool(definition["marker_collision"])
		facility_state.register_room(room_id, room_entry)
		facility_state.register_access_point(access_id, room_id, access_kind)
		if definition.has("door_id"):
			facility_state.register_door(String(definition["door_id"]), room_id, FacilityProgression.DOOR_LOCKED)
		var marker: Node3D
		if definition.has("door_id"):
			marker = _create_facility_door(
				String(definition["door_id"]),
				"Entry_" + room_id,
				marker_position,
				marker_size,
				marker_color
			)
		else:
			marker = _create_box(
				"Entry_" + room_id,
				marker_position,
				marker_size,
				marker_color,
				marker_collision
			)
		entry_nodes[access_id] = marker
		if definition.has("door_id"):
			entry_doors[String(definition["door_id"])] = marker
			if marker is FacilityDoor3D:
				(marker as FacilityDoor3D).set_state(facility_state.get_door_state(String(definition["door_id"])))
			else:
				_apply_access_state_visual(marker, facility_state.get_access_state(access_id))

func _make_entry_definition(room_id: String, access_id: String, access_kind: String, entry_label: String, intro_style: String, entry_position: Vector3, marker_position: Vector3, marker_size: Vector3, marker_color: Color, marker_collision: bool, pursuers: int, door_id: String = "") -> Dictionary:
	var definition: Dictionary = {}
	definition["room_id"] = room_id
	definition["access_id"] = access_id
	definition["access_kind"] = access_kind
	definition["entry_label"] = entry_label
	definition["intro_style"] = intro_style
	definition["entry"] = entry_position
	definition["marker_position"] = marker_position
	definition["marker_size"] = marker_size
	definition["marker_color"] = marker_color
	definition["marker_collision"] = marker_collision
	definition["pursuers"] = pursuers
	if not door_id.is_empty():
		definition["door_id"] = door_id
	return definition

func _build_hidden_route_markers() -> void:
	facility_state.register_hidden_route(
		"vent_hab_to_service",
		"vent",
		"south_hab_pressure_door",
		"north_service_airlock_tumble",
		"Low utility vent that can bypass a jammed hab door, with poor visibility and no room to reload cleanly."
	)
	facility_state.register_hidden_route(
		"crawl_reactor_to_cargo",
		"crawlspace",
		"reactor_vent_drop",
		"cargo_lift_crash",
		"Half-collapsed conduit that may dead-end, hide equipment, or surface behind locked industrial doors."
	)
	facility_state.register_hidden_route(
		"catwalk_service_loop",
		"catwalk",
		"east_ceiling_catwalk_fall",
		"west_maintenance_crawl",
		"Upper service path that favors observation and ambush risk over direct movement."
	)
	_create_box("HiddenVentGrateSouth", Vector3(-19.9, 0.65, 12.5), Vector3(0.12, 0.7, 1.4), Color(0.05, 0.08, 0.09), false)
	_create_box("HiddenVentGrateNorth", Vector3(19.9, 0.65, -12.5), Vector3(0.12, 0.7, 1.4), Color(0.05, 0.08, 0.09), false)
	_create_box("LowCrawlspaceMouth", Vector3(-6.0, 0.35, 19.85), Vector3(2.1, 0.7, 0.12), Color(0.04, 0.06, 0.065), false)
	_create_box("UpperCatwalkHint", Vector3(0, 2.8, -6.0), Vector3(12.0, 0.16, 1.2), Color(0.12, 0.18, 0.18), false, "grate")
	_create_hidden_route_trigger("VentRouteSouth", "vent_hab_to_service", "vent", Vector3(-19.75, 0.55, 12.5), Vector3(18.0, 0.2, -12.5))
	_create_hidden_route_trigger("CrawlRouteMouth", "crawl_reactor_to_cargo", "crawlspace", Vector3(-6.0, 0.35, 19.55), Vector3(15.0, 0.2, -13.0))
	_create_hidden_route_trigger("CatwalkRouteLoop", "catwalk_service_loop", "catwalk", Vector3(0, 2.9, -6.0), Vector3(-16.0, 0.2, 0.0))

func _build_dynamic_environment_props() -> void:
	_create_dynamic_prop("ThrowCrateA", Vector3(-6.0, 0.45, 4.0), Vector3(0.75, 0.75, 0.75), Color(0.28, 0.25, 0.2), 10.0)
	_create_dynamic_prop("ThrowCrateB", Vector3(6.0, 0.45, -3.0), Vector3(0.75, 0.75, 0.75), Color(0.24, 0.27, 0.28), 10.0)
	_create_dynamic_prop("LooseCanisterA", Vector3(-12.0, 0.35, -8.0), Vector3(0.38, 0.65, 0.38), Color(0.42, 0.18, 0.12), 5.0)
	_create_dynamic_prop("LooseCanisterB", Vector3(12.0, 0.35, 8.0), Vector3(0.38, 0.65, 0.38), Color(0.14, 0.34, 0.36), 5.0)
	_create_dynamic_button("NorthOverrideButton", Vector3(-2.3, 1.35, -20.26), Vector3(0, 0, 0))
	_create_dynamic_button("SouthOverrideButton", Vector3(2.3, 1.35, 20.26), Vector3(0, 180, 0))
	_create_dynamic_button("CatwalkLiftButton", Vector3(18.9, 1.35, 2.4), Vector3(0, -90, 0))
	_create_flashlight_pickup("FoundVestFlashlight", Vector3(-14.5, 0.35, 10.5), "vest")
	_create_flashlight_pickup("FoundHelmetLamp", Vector3(13.5, 0.35, -11.5), "helmet")
	_create_flashlight_pickup("FoundWeaponLight", Vector3(2.2, 0.35, -12.5), "weapon_mount")
	_create_weapon_pickup("FoundRattlerSMG", Vector3(-9.5, 0.45, -13.2), "rattler_smg", "Rattler SMG")
	_create_weapon_pickup("FoundServiceRifle", Vector3(9.2, 0.45, 12.5), "a12_service_rifle", "A-12 Service Rifle")
	_create_weapon_pickup("FoundDeckLMG", Vector3(14.0, 0.45, 2.0), "l6_deck_lmg", "L-6 Deck LMG")
	_create_weapon_pickup("FoundTorchLance", Vector3(-14.2, 0.45, -2.0), "torch_lance", "Torch Lance")
	_create_weapon_pickup("FoundSecurityRevolver", Vector3(0.5, 0.45, 13.5), "m9_security_revolver", "M-9 Security Revolver")
	_create_resource_pickup("FusePickup", Vector3(-3.5, 0.35, 12.5), "fuse", 1)
	_create_resource_pickup("PowerCellPickup", Vector3(11.5, 0.35, -2.8), "power_cell", 1)
	_create_resource_pickup("CableSpoolPickup", Vector3(-11.5, 0.35, 2.8), "cable_spool", 1)
	_create_resource_pickup("ToolPartsPickup", Vector3(3.5, 0.35, -12.5), "tool_parts", 2)
	_create_resource_pickup("AccessCredentialPickup", Vector3(-1.8, 0.35, -14.0), "access_credential", 1)
	_create_resource_pickup("CuttingChargePickup", Vector3(15.2, 0.35, 10.0), "cutting_charge", 1)
	_create_resource_pickup("MedStockPickup", Vector3(-15.2, 0.35, -10.0), "med_stock", 1)
	_create_wearable_module_pickup("DiagnosticGlassesPickup", Vector3(-11.5, 0.45, 11.2), "hud_glasses")
	_create_wearable_module_pickup("AmmoReceiverPickup", Vector3(5.4, 0.45, -9.2), "ammo_link_receiver")
	_create_wearable_module_pickup("BrainwaveReaderPickup", Vector3(-16.4, 0.45, -3.5), "brainwave_reader")
	_create_wearable_module_pickup("CompassModulePickup", Vector3(13.7, 0.45, 10.4), "compass_module")
	_create_wearable_module_pickup("RouteMapperPickup", Vector3(-2.8, 0.45, 17.1), "route_mapper")
	_create_wearable_module_pickup("CommsTranscriberPickup", Vector3(16.3, 0.45, -2.8), "comms_transcriber")
	_create_wearable_module_pickup("ReticleLensPickup", Vector3(-6.8, 0.45, -12.4), "reticle_lens")
	_create_wearable_module_pickup("SoundMeterPickup", Vector3(2.5, 0.45, 11.6), "sound_meter")
	_create_wearable_module_pickup("LowLightFilterPickup", Vector3(-14.4, 0.45, 6.4), "low_light_filter")
	_create_wearable_module_pickup("ThreatClassifierPickup", Vector3(11.4, 0.45, -15.2), "threat_classifier")
	_create_weapon_attachment_pickup("AmmoTelemetryPickup", Vector3(-4.5, 0.45, -15.4), "ammo_telemetry_transmitter")
	_create_weapon_attachment_pickup("SuppressorPickup", Vector3(8.6, 0.45, 13.4), "compact_suppressor")
	_create_weapon_attachment_pickup("CompensatorPickup", Vector3(-15.8, 0.45, -12.4), "port_compensator")
	_create_weapon_attachment_pickup("ReflexSightPickup", Vector3(14.4, 0.45, 2.5), "reflex_sight")
	_create_weapon_attachment_pickup("LaserPointerPickup", Vector3(-1.5, 0.45, -3.8), "laser_pointer")
	_create_weapon_attachment_pickup("ForegripPickup", Vector3(7.5, 0.45, -2.8), "foregrip")
	_create_weapon_attachment_pickup("ExtendedMagazinePickup", Vector3(-12.8, 0.45, 2.2), "extended_magazine")
	_create_weapon_attachment_pickup("QuickpullMagwellPickup", Vector3(3.2, 0.45, -16.6), "quickpull_magwell")
	_create_weapon_attachment_pickup("WeaponLightPickup", Vector3(16.1, 0.45, 15.0), "weapon_light")
	_create_weapon_attachment_pickup("RetentionSlingPickup", Vector3(-17.1, 0.45, 15.5), "retention_sling")
	_create_resource_pickup("SuitPatchPickup", Vector3(17.2, 0.35, 5.8), "suit_patch", 1)
	_create_resource_pickup("SplintRollPickup", Vector3(-13.5, 0.35, -8.6), "splint_roll", 1)
	_create_resource_pickup("CauterizerPickup", Vector3(9.2, 0.35, 8.4), "field_cauterizer_pen", 1)
	_create_resource_pickup("CoolantCanisterPickup", Vector3(6.3, 0.35, 6.2), "coolant_canister", 1)
	_create_resource_pickup("StaticChargePickup", Vector3(-4.0, 0.35, 5.7), "static_charge", 1)
	_create_resource_pickup("BootGripsPickup", Vector3(-8.5, 0.35, 15.0), "boot_grips", 1)
	_create_resource_pickup("EarpiecePatchPickup", Vector3(8.0, 0.35, -8.8), "earpiece_patch", 1)
	_create_resource_pickup("SuppressorWrapPickup", Vector3(-7.8, 0.35, 8.2), "suppressor_wrap", 1)
	_create_wearable_module_pickup("DeadTechGlassesOnCorpse", Vector3(0.0, 0.45, -6.5), "hud_glasses")
	_create_service_node("ArenaFuseSlot", Vector3(-18.9, 1.25, 12.0), Vector3(0, 90, 0), "sector_power", "arena", "replace_fuse", "fuse", 1)
	_create_service_node("ArenaBreakerReset", Vector3(18.9, 1.25, -12.0), Vector3(0, -90, 0), "sector_power", "arena", "reset_breaker")
	_create_service_node("ArenaCablePatch", Vector3(-6.0, 1.1, 20.25), Vector3(0, 180, 0), "sector_power", "arena", "patch_cable", "cable_spool", 1)
	_create_service_node("ArenaBatterySocket", Vector3(6.0, 1.1, -20.25), Vector3(0, 0, 0), "sector_power", "arena", "slot_power_cell", "power_cell", 1)
	_create_service_node("ArenaGeneratorBypass", Vector3(18.9, 1.25, 12.0), Vector3(0, -90, 0), "sector_power", "arena", "restart_generator", "tool_parts", 1)
	_create_service_node("NorthAccessCredentialPanel", Vector3(2.8, 1.35, -20.26), Vector3(0, 0, 0), "door_override", "door_north_service", "use_access_credential", "access_credential", 1)
	_create_service_node("SouthMaintenanceBypass", Vector3(-2.8, 1.35, 20.26), Vector3(0, 180, 0), "door_override", "door_south_hab", "maintenance_bypass", "tool_parts", 1)
	_create_service_node("NorthReverseMotor", Vector3(5.0, 1.35, -20.26), Vector3(0, 0, 0), "door_override", "door_north_service", "reverse_motor", "power_cell", 1)
	_create_service_node("SouthCutDebris", Vector3(-5.0, 1.35, 20.26), Vector3(0, 180, 0), "door_override", "door_south_hab", "cut_debris", "cutting_charge", 1)
	_create_service_node("FieldWorkbench", Vector3(0.0, 1.0, -12.0), Vector3(0, 0, 0), "workbench", "field_crafting", "assemble_crash_kit", "med_stock", 1)
	_create_service_node("ExecutiveLiftClue", Vector3(13.2, 1.2, 18.9), Vector3(0, 180, 0), "route_discovery", "executive_hidden_lift", "office_lift_note", "access_credential", 1)
	_create_service_node("MainStairwellRoute", Vector3(0.0, 1.35, 20.2), Vector3(0, 180, 0), "floor_route", "main_stairwell", "take_stairs")
	_create_service_node("ServiceElevatorRoute", Vector3(0.0, 1.35, -20.2), Vector3(0, 0, 0), "floor_route", "service_elevator", "call_lift", "power_cell", 1)
	_create_service_node("MaintenanceLadderRoute", Vector3(-18.9, 1.1, -2.0), Vector3(0, 90, 0), "floor_route", "maintenance_ladder_riser", "climb_ladder")
	_create_service_node("VentStackRoute", Vector3(-18.9, 0.75, 14.0), Vector3(0, 90, 0), "floor_route", "ventilation_stack", "fan_lockout", "fuse", 1)
	_create_service_node("CargoHoistRoute", Vector3(18.9, 1.1, -14.0), Vector3(0, -90, 0), "floor_route", "cargo_hoist_shaft", "release_hoist", "tool_parts", 1)
	_create_service_node("ExteriorCatwalkRoute", Vector3(18.9, 1.1, 7.0), Vector3(0, -90, 0), "floor_route", "exterior_catwalk", "cycle_airlock", "suit_patch", 1)
	_create_environment_hazard("VolatileTankHazard", Vector3(-5.0, 0.7, -14.0), "blast", Vector3(0.7, 1.1, 0.7), Color(0.55, 0.18, 0.1), 4.2, 92.0, 15.0, 4.0)
	_create_environment_hazard("ArcJunctionHazard", Vector3(14.8, 1.1, -5.0), "electric", Vector3(0.55, 1.0, 0.22), Color(0.08, 0.36, 0.64), 3.2, 54.0, 8.0, 8.0)
	_create_environment_hazard("SteamMainHazard", Vector3(-14.8, 1.1, 5.0), "steam", Vector3(0.55, 1.0, 0.22), Color(0.45, 0.48, 0.42), 3.5, 42.0, 6.0, 14.0)
	_create_environment_hazard("PressureDumpHazard", Vector3(18.6, 1.4, 7.0), "pressure_dump", Vector3(0.3, 1.8, 1.6), Color(0.12, 0.28, 0.34), 4.8, 24.0, 18.0, 18.0)
	_create_environment_hazard("CargoCrusherHazard", Vector3(0.0, 2.2, -7.0), "crusher", Vector3(2.0, 0.4, 2.0), Color(0.42, 0.1, 0.08), 2.2, 130.0, 6.0, 999.0)
	_create_environment_hazard("CoolantFloodHazard", Vector3(7.0, 0.7, 7.0), "coolant", Vector3(0.75, 1.0, 0.75), Color(0.16, 0.55, 0.5), 3.4, 36.0, 5.0, 24.0)

func _create_dynamic_prop(prop_name: String, world_position: Vector3, size: Vector3, color: Color, object_mass: float) -> DynamicObject3D:
	var prop = DynamicObject3D.new()
	prop.name = prop_name
	prop.configure(prop_name, size, color, object_mass)
	prop.penetration_loss = 24.0
	if object_mass <= 6.0:
		prop.penetration_loss = 12.0
	prop.surface_id = "metal"
	prop.position = world_position
	arena_root.add_child(prop)
	return prop

func _create_dynamic_button(button_id: String, world_position: Vector3, rotation_degrees_value: Vector3) -> DynamicButton3D:
	var button = DynamicButton3D.new()
	button.name = button_id
	button.configure(button_id)
	button.position = world_position
	button.rotation_degrees = rotation_degrees_value
	button.activated.connect(_on_dynamic_button_activated)
	arena_root.add_child(button)
	return button

func _create_flashlight_pickup(pickup_name: String, world_position: Vector3, mount_type: String) -> EquipmentPickup3D:
	var pickup = EquipmentPickup3D.new()
	pickup.name = pickup_name
	pickup.configure_flashlight(mount_type)
	arena_root.add_child(pickup)
	pickup.global_position = world_position
	return pickup

func _create_weapon_pickup(pickup_name: String, world_position: Vector3, weapon_id: String, label: String) -> EquipmentPickup3D:
	var pickup = EquipmentPickup3D.new()
	pickup.name = pickup_name
	pickup.configure_weapon(weapon_id, label)
	arena_root.add_child(pickup)
	pickup.global_position = world_position
	return pickup

func _create_resource_pickup(pickup_name: String, world_position: Vector3, resource_id: String, amount: int) -> EquipmentPickup3D:
	var pickup = EquipmentPickup3D.new()
	pickup.name = pickup_name
	pickup.configure_resource(resource_id, amount)
	arena_root.add_child(pickup)
	pickup.global_position = world_position
	return pickup

func _create_wearable_module_pickup(pickup_name: String, world_position: Vector3, module_id: String) -> EquipmentPickup3D:
	var pickup = EquipmentPickup3D.new()
	pickup.name = pickup_name
	pickup.configure_wearable_module(module_id)
	arena_root.add_child(pickup)
	pickup.global_position = world_position
	return pickup

func _create_weapon_attachment_pickup(pickup_name: String, world_position: Vector3, attachment_id: String) -> EquipmentPickup3D:
	var pickup = EquipmentPickup3D.new()
	pickup.name = pickup_name
	pickup.configure_weapon_attachment(attachment_id)
	arena_root.add_child(pickup)
	pickup.global_position = world_position
	return pickup

func _create_hidden_route_trigger(trigger_name: String, route_id: String, route_kind: String, world_position: Vector3, destination: Vector3) -> HiddenRouteTrigger3D:
	var trigger = HiddenRouteTrigger3D.new()
	trigger.name = trigger_name
	trigger.configure(route_id, route_kind, Vector3(1.0, 0.7, 1.0), Color(0.04, 0.09, 0.1), destination)
	trigger.position = world_position
	arena_root.add_child(trigger)
	return trigger

func _create_service_node(node_id: String, world_position: Vector3, rotation_degrees_value: Vector3, service_type: String, target_id: String, method_id: String, requirement_id: String = "", requirement_amount: int = 0) -> FacilityServiceNode3D:
	var node = FacilityServiceNode3D.new()
	node.name = node_id
	node.configure(node_id, service_type, target_id, method_id, requirement_id, requirement_amount)
	node.position = world_position
	node.rotation_degrees = rotation_degrees_value
	node.service_used.connect(_on_service_node_used)
	arena_root.add_child(node)
	return node

func _create_environment_hazard(hazard_name: String, world_position: Vector3, hazard_type: String, size: Vector3, color: Color, radius: float, damage: float, force: float, threshold: float) -> EnvironmentalHazard3D:
	var hazard = EnvironmentalHazard3D.new()
	hazard.name = hazard_name
	hazard.configure(hazard_name, hazard_type, size, color, radius, damage, force, threshold)
	arena_root.add_child(hazard)
	hazard.global_position = world_position
	return hazard

func _get_entry_definition(room_id: String) -> Dictionary:
	for definition in entry_definitions:
		if String(definition["room_id"]) == room_id:
			return definition
	return {}

func _scar_entry_for_definition(definition: Dictionary) -> String:
	if definition.is_empty():
		return FacilityProgression.ACCESS_SCARRED
	var access_id = String(definition["access_id"])
	var access_state = facility_state.scar_access_point(access_id)
	var door_id = ""
	if definition.has("door_id"):
		door_id = String(definition["door_id"])
		facility_state.jam_door(door_id)
	if entry_nodes.has(access_id):
		var node = entry_nodes[access_id] as Node3D
		if node and node is FacilityDoor3D:
			(node as FacilityDoor3D).set_state(facility_state.get_door_state(door_id))
		elif node:
			_apply_access_state_visual(node, access_state)
	return access_state

func _apply_access_state_visual(access_node: Node3D, state: String) -> void:
	var color = Color(0.14, 0.2, 0.21)
	var emission = 0.05
	if state == FacilityProgression.ACCESS_SCARRED:
		color = Color(0.35, 0.2, 0.12)
		emission = 0.25
	elif state == FacilityProgression.ACCESS_COMPROMISED:
		color = Color(0.44, 0.13, 0.1)
		emission = 0.45
	elif state == FacilityProgression.ACCESS_BLOCKED:
		color = Color(0.16, 0.06, 0.06)
		emission = 0.7
	for child in access_node.get_children():
		if child is MeshInstance3D:
			child.material_override = _make_material(color, emission)

func _make_spawn_text(room_id: String, definition: Dictionary, access_state: String, was_explored: bool, entry_reason: String) -> String:
	var familiarity = "known access" if was_explored else "unmapped access"
	var arrival = "NEW SURVIVOR" if survivor_count > 1 else "SURVIVOR"
	var pressure = "pursued breach" if entry_reason == "successor" else "cold start"
	var label = String(definition.get("entry_label", room_id.replace("_", " ")))
	var consequence = "access scarred behind you"
	if access_state == FacilityProgression.ACCESS_COMPROMISED:
		consequence = "return route compromised"
	elif access_state == FacilityProgression.ACCESS_BLOCKED:
		consequence = "return route probably blocked"
	return "%s\n%s / %s / %s\n%s" % [arrival, label.to_upper(), familiarity, pressure, consequence]

func _spawn_entry_pursuers(entry_position: Vector3, definition: Dictionary) -> void:
	if not threat_director:
		return
	var pursuer_count = int(definition.get("pursuers", 2))
	if pursuer_count <= 0:
		return
	var pursuer_chance = float(definition.get("pursuer_chance", clamp(0.14 + float(pursuer_count) * 0.12, 0.0, 0.55)))
	if randf() > pursuer_chance:
		return
	if randf() < 0.35:
		_unlock_followthrough_breach(definition)
	var to_center = Vector3.ZERO - entry_position
	to_center.y = 0.0
	if to_center.length() < 0.1:
		to_center = Vector3.FORWARD
	to_center = to_center.normalized()
	var behind = -to_center
	var side = Vector3(-to_center.z, 0.0, to_center.x)
	var offsets: Array[Vector3] = [
		behind * 1.6 + side * 0.8,
		behind * 2.1 - side * 0.8,
		behind * 2.6,
		behind * 3.0 + side * 1.2
	]
	for i in range(min(pursuer_count, offsets.size())):
		var offset: Vector3 = offsets[i]
		threat_director.spawn_enemy_at(entry_position + offset)

func _unlock_followthrough_breach(definition: Dictionary) -> void:
	var access_id = String(definition.get("access_id", "unknown_access"))
	var access_kind = String(definition.get("access_kind", "breach"))
	var flag_name = "followthrough_%s" % access_id
	facility_state.unlock_flag(flag_name)
	if definition.has("door_id"):
		var door_id = String(definition["door_id"])
		facility_state.set_door_state(door_id, FacilityProgression.DOOR_OPEN)
		if entry_doors.has(door_id):
			var door = entry_doors[door_id] as FacilityDoor3D
			if door:
				door.set_state(FacilityProgression.DOOR_OPEN)
	if player and player.comms:
		player.comms.announce("Something followed you through the %s. That route may be forced open now." % access_kind.replace("_", " "))

func _build_director() -> void:
	threat_director = ThreatDirector.new()
	threat_director.name = "ThreatDirector"
	add_child(threat_director)
	threat_director.setup(player, enemy_container, spawn_points)
	if route_system:
		threat_director.set_station_floor(route_system.current_floor)
	_spawn_demo_enemies()

func _build_objective_system() -> void:
	objective_system = ObjectiveSystem.new()
	objective_system.name = "ObjectiveSystem"
	add_child(objective_system)
	objective_system.setup(player, arena_root, sector_power, threat_director, _get_mission_sector_definitions())
	objective_system.prepare_run()

func _build_mission_briefing() -> void:
	briefing_screen = MissionBriefingScreen.new()
	briefing_screen.name = "MissionBriefingScreen"
	briefing_screen.configure(objective_system.get_objective_snapshot(), _get_role_definitions(), selected_role)
	briefing_screen.deploy_pressed.connect(_on_briefing_deploy_pressed)
	add_child(briefing_screen)

func _on_briefing_deploy_pressed(role_id: String) -> void:
	selected_role = role_id
	mission_deployed = true
	if player:
		var loadout: Dictionary = player.survivor_loadout.duplicate(true)
		_apply_role_to_loadout(loadout, selected_role)
		player.apply_survivor_loadout(loadout)
	if briefing_screen and is_instance_valid(briefing_screen):
		briefing_screen.queue_free()
		briefing_screen = null
	if objective_system:
		objective_system.start_run()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	GameEvents.reset_run()

func _get_role_definitions() -> Array[Dictionary]:
	return [
		{
			"id": "breacher",
			"label": "BREACHER",
			"weapon_id": "a12_service_rifle",
			"weapon_name": "A-12 Service Rifle",
			"description": "Fast reloads. Hits hard up close.",
			"summary": "Fast reloads\nMelee amplifier",
			"extra_ammo": 90,
			"resources": {"melee_amp": 1},
			"reload_speed_mult": 1.35
		},
		{
			"id": "medic",
			"label": "MEDIC",
			"weapon_id": "rattler_smg",
			"weapon_name": "Rattler SMG",
			"description": "Keeps the team breathing.",
			"summary": "Corpse revival\nExtra trauma supplies",
			"extra_ammo": 120,
			"resources": {"trauma_kit": 2, "bandage": 3},
			"can_revive_corpses": true
		},
		{
			"id": "heavy",
			"label": "HEAVY",
			"weapon_id": "l6_deck_lmg",
			"weapon_name": "L-6 Deck LMG",
			"description": "Suppression and thermal. Slow but unstoppable.",
			"summary": "Huge reserves\nSlower sprint",
			"extra_ammo": 200,
			"resources": {"thermal_canister": 2},
			"movement_penalty_mult": 0.82
		}
	]

func _apply_role_to_loadout(loadout: Dictionary, role_id: String) -> void:
	var role: Dictionary = _get_role_definition(role_id)
	loadout["role"] = String(role.get("id", "breacher"))
	loadout["weapon_id"] = String(role.get("weapon_id", "a12_service_rifle"))
	var role_weapon: WeaponData = WeaponData.create_weapon(String(loadout["weapon_id"]))
	loadout["recoverable_ammo_type"] = role_weapon.ammo_type
	loadout["extra_ammo"] = int(role.get("extra_ammo", 0))
	loadout["reload_speed_mult"] = float(role.get("reload_speed_mult", 1.0))
	loadout["movement_penalty_mult"] = float(role.get("movement_penalty_mult", 1.0))
	loadout["can_revive_corpses"] = bool(role.get("can_revive_corpses", false))
	loadout["role_description"] = String(role.get("description", ""))
	var resources: Dictionary = {}
	var raw_resources: Variant = loadout.get("resources", {})
	if raw_resources is Dictionary:
		resources = raw_resources.duplicate(true)
	var role_resources: Dictionary = {}
	var raw_role_resources: Variant = role.get("resources", {})
	if raw_role_resources is Dictionary:
		role_resources = raw_role_resources
	for key in role_resources.keys():
		var resource_id: String = String(key)
		resources[resource_id] = int(resources.get(resource_id, 0)) + int(role_resources[key])
	loadout["resources"] = resources

func _get_role_definition(role_id: String) -> Dictionary:
	for role in _get_role_definitions():
		if String(role.get("id", "")) == role_id:
			return role
	return _get_role_definitions()[0]

func _get_mission_sector_definitions() -> Array[Dictionary]:
	return [
		{"sector_id": "medical_bay", "label": "Medical Bay", "position": Vector3(0.0, 0.05, -26.0)},
		{"sector_id": "reactor_control", "label": "Reactor Control", "position": Vector3(0.0, 0.05, -26.0)},
		{"sector_id": "cargo_processing", "label": "Cargo Processing", "position": Vector3(0.0, 0.05, 26.0)},
		{"sector_id": "hab_commons", "label": "Hab Commons", "position": Vector3(0.0, 0.05, 26.0)},
		{"sector_id": "security_spine", "label": "Security Spine", "position": Vector3(22.0, 0.05, 0.0)},
		{"sector_id": "comms_nook", "label": "Comms Nook", "position": Vector3(-22.0, 0.05, 0.0)}
	]

func _build_interior_partitions() -> void:
	var wall_specs: Array[Dictionary] = [
		{"name": "NorthSpineWestWallA", "position": Vector3(-5.2, 1.85, -29.0), "size": Vector3(0.42, 3.45, 9.5)},
		{"name": "NorthSpineWestWallB", "position": Vector3(-5.2, 1.85, -14.0), "size": Vector3(0.42, 3.45, 6.0)},
		{"name": "SouthSpineWestWallA", "position": Vector3(-5.2, 1.85, 14.0), "size": Vector3(0.42, 3.45, 6.0)},
		{"name": "SouthSpineWestWallB", "position": Vector3(-5.2, 1.85, 29.0), "size": Vector3(0.42, 3.45, 9.5)},
		{"name": "NorthSpineEastWallA", "position": Vector3(5.2, 1.85, -29.0), "size": Vector3(0.42, 3.45, 9.5)},
		{"name": "NorthSpineEastWallB", "position": Vector3(5.2, 1.85, -14.0), "size": Vector3(0.42, 3.45, 6.0)},
		{"name": "SouthSpineEastWallA", "position": Vector3(5.2, 1.85, 14.0), "size": Vector3(0.42, 3.45, 6.0)},
		{"name": "SouthSpineEastWallB", "position": Vector3(5.2, 1.85, 29.0), "size": Vector3(0.42, 3.45, 9.5)},
		{"name": "WestCrossNorthWallA", "position": Vector3(-29.0, 1.85, -5.2), "size": Vector3(9.5, 3.45, 0.42)},
		{"name": "WestCrossNorthWallB", "position": Vector3(-14.0, 1.85, -5.2), "size": Vector3(6.0, 3.45, 0.42)},
		{"name": "EastCrossNorthWallA", "position": Vector3(14.0, 1.85, -5.2), "size": Vector3(6.0, 3.45, 0.42)},
		{"name": "EastCrossNorthWallB", "position": Vector3(29.0, 1.85, -5.2), "size": Vector3(9.5, 3.45, 0.42)},
		{"name": "WestCrossSouthWallA", "position": Vector3(-29.0, 1.85, 5.2), "size": Vector3(9.5, 3.45, 0.42)},
		{"name": "WestCrossSouthWallB", "position": Vector3(-14.0, 1.85, 5.2), "size": Vector3(6.0, 3.45, 0.42)},
		{"name": "EastCrossSouthWallA", "position": Vector3(14.0, 1.85, 5.2), "size": Vector3(6.0, 3.45, 0.42)},
		{"name": "EastCrossSouthWallB", "position": Vector3(29.0, 1.85, 5.2), "size": Vector3(9.5, 3.45, 0.42)},
		{"name": "MedBayPartition", "position": Vector3(-23.0, 1.55, -18.0), "size": Vector3(12.0, 3.0, 0.36)},
		{"name": "CargoPartition", "position": Vector3(23.0, 1.55, 18.0), "size": Vector3(12.0, 3.0, 0.36)},
		{"name": "ReactorPartition", "position": Vector3(18.0, 1.55, -23.0), "size": Vector3(0.36, 3.0, 12.0)},
		{"name": "HabPartition", "position": Vector3(-18.0, 1.55, 23.0), "size": Vector3(0.36, 3.0, 12.0)}
	]
	for spec in wall_specs:
		var partition_position: Vector3 = Vector3.ZERO
		var raw_partition_position: Variant = spec.get("position", Vector3.ZERO)
		if raw_partition_position is Vector3:
			partition_position = raw_partition_position
		var partition_size: Vector3 = Vector3.ONE
		var raw_partition_size: Variant = spec.get("size", Vector3.ONE)
		if raw_partition_size is Vector3:
			partition_size = raw_partition_size
		_create_box(String(spec["name"]), partition_position, partition_size, Color(0.135, 0.155, 0.17), true, "bulkhead")
		_register_nav_blocker(partition_position, partition_size)
	var door_specs: Array[Dictionary] = [
		{"name": "MedBayDoorWest", "position": Vector3(-5.22, 0.0, -22.0), "along_x": false, "color": Color(0.16, 0.35, 0.33)},
		{"name": "StorageDoorWest", "position": Vector3(-5.22, 0.0, 22.0), "along_x": false, "color": Color(0.32, 0.28, 0.16)},
		{"name": "ReactorDoorEast", "position": Vector3(5.22, 0.0, -22.0), "along_x": false, "color": Color(0.35, 0.18, 0.12)},
		{"name": "HabDoorEast", "position": Vector3(5.22, 0.0, 22.0), "along_x": false, "color": Color(0.18, 0.26, 0.36)},
		{"name": "SecurityDoorNorth", "position": Vector3(-22.0, 0.0, -5.22), "along_x": true, "color": Color(0.18, 0.28, 0.34)},
		{"name": "UtilityDoorNorth", "position": Vector3(22.0, 0.0, -5.22), "along_x": true, "color": Color(0.28, 0.2, 0.13)},
		{"name": "LabDoorSouth", "position": Vector3(-22.0, 0.0, 5.22), "along_x": true, "color": Color(0.14, 0.32, 0.34)},
		{"name": "CommonsDoorSouth", "position": Vector3(22.0, 0.0, 5.22), "along_x": true, "color": Color(0.2, 0.24, 0.16)}
	]
	for door_spec in door_specs:
		var doorway_position: Vector3 = Vector3.ZERO
		var raw_doorway_position: Variant = door_spec.get("position", Vector3.ZERO)
		if raw_doorway_position is Vector3:
			doorway_position = raw_doorway_position
		var doorway_color: Color = Color(0.18, 0.26, 0.28)
		var raw_doorway_color: Variant = door_spec.get("color", doorway_color)
		if raw_doorway_color is Color:
			doorway_color = raw_doorway_color
		_create_station_doorway(
			String(door_spec["name"]),
			doorway_position,
			bool(door_spec["along_x"]),
			doorway_color
		)
	_build_mission_doors()
	_create_box("CentralCeilingRibNorth", Vector3(0.0, 3.85, -16.0), Vector3(9.8, 0.18, 0.32), Color(0.045, 0.055, 0.062), false)
	_create_box("CentralCeilingRibSouth", Vector3(0.0, 3.85, 16.0), Vector3(9.8, 0.18, 0.32), Color(0.045, 0.055, 0.062), false)
	_create_box("CrossCeilingRibWest", Vector3(-16.0, 3.85, 0.0), Vector3(0.32, 0.18, 9.8), Color(0.045, 0.055, 0.062), false)
	_create_box("CrossCeilingRibEast", Vector3(16.0, 3.85, 0.0), Vector3(0.32, 0.18, 9.8), Color(0.045, 0.055, 0.062), false)
	_build_navigation_region()

func _create_station_doorway(doorway_name: String, floor_position: Vector3, along_x: bool, color: Color) -> void:
	var base_position: Vector3 = floor_position + Vector3(0.0, 1.25, 0.0)
	if along_x:
		_create_box(doorway_name + "_FrameLeft", base_position + Vector3(-1.35, 0.0, 0.0), Vector3(0.16, 2.55, 0.28), Color(0.055, 0.07, 0.075), false)
		_create_box(doorway_name + "_FrameRight", base_position + Vector3(1.35, 0.0, 0.0), Vector3(0.16, 2.55, 0.28), Color(0.055, 0.07, 0.075), false)
		_create_box(doorway_name + "_Header", base_position + Vector3(0.0, 1.25, 0.0), Vector3(2.85, 0.18, 0.32), Color(0.055, 0.07, 0.075), false)
		_create_box(doorway_name + "_OpenPanel", base_position + Vector3(1.95, -0.08, 0.0), Vector3(0.9, 2.22, 0.16), color, false)
	else:
		_create_box(doorway_name + "_FrameLeft", base_position + Vector3(0.0, 0.0, -1.35), Vector3(0.28, 2.55, 0.16), Color(0.055, 0.07, 0.075), false)
		_create_box(doorway_name + "_FrameRight", base_position + Vector3(0.0, 0.0, 1.35), Vector3(0.28, 2.55, 0.16), Color(0.055, 0.07, 0.075), false)
		_create_box(doorway_name + "_Header", base_position + Vector3(0.0, 1.25, 0.0), Vector3(0.32, 0.18, 2.85), Color(0.055, 0.07, 0.075), false)
		_create_box(doorway_name + "_OpenPanel", base_position + Vector3(0.0, -0.08, 1.95), Vector3(0.16, 2.22, 0.9), color, false)

func _build_mission_doors() -> void:
	mission_doors_by_sector.clear()
	var door_specs: Array[Dictionary] = [
		{"door_id": "door_medical_bay", "sector_id": "medical_bay", "name": "MissionDoorMedicalBay", "position": Vector3(-1.45, 1.22, -22.0), "size": Vector3(1.0, 2.45, 0.3), "glow_offset": Vector3(0.0, 0.0, 0.02), "glow_size": Vector3(1.15, 2.6, 0.04), "color": Color(0.14, 0.22, 0.25)},
		{"door_id": "door_reactor_control", "sector_id": "reactor_control", "name": "MissionDoorReactorControl", "position": Vector3(1.45, 1.22, -22.0), "size": Vector3(1.0, 2.45, 0.3), "glow_offset": Vector3(0.0, 0.0, 0.02), "glow_size": Vector3(1.15, 2.6, 0.04), "color": Color(0.2, 0.14, 0.11)},
		{"door_id": "door_cargo_processing", "sector_id": "cargo_processing", "name": "MissionDoorCargoProcessing", "position": Vector3(1.45, 1.22, 22.0), "size": Vector3(1.0, 2.45, 0.3), "glow_offset": Vector3(0.0, 0.0, -0.02), "glow_size": Vector3(1.15, 2.6, 0.04), "color": Color(0.2, 0.18, 0.12)},
		{"door_id": "door_hab_commons", "sector_id": "hab_commons", "name": "MissionDoorHabCommons", "position": Vector3(-1.45, 1.22, 22.0), "size": Vector3(1.0, 2.45, 0.3), "glow_offset": Vector3(0.0, 0.0, -0.02), "glow_size": Vector3(1.15, 2.6, 0.04), "color": Color(0.14, 0.18, 0.24)},
		{"door_id": "door_security_spine", "sector_id": "security_spine", "name": "MissionDoorSecuritySpine", "position": Vector3(17.0, 1.22, -1.45), "size": Vector3(0.3, 2.45, 1.0), "glow_offset": Vector3(-0.02, 0.0, 0.0), "glow_size": Vector3(0.04, 2.6, 1.15), "color": Color(0.12, 0.2, 0.25)},
		{"door_id": "door_comms_nook", "sector_id": "comms_nook", "name": "MissionDoorCommsNook", "position": Vector3(-17.0, 1.22, 1.45), "size": Vector3(0.3, 2.45, 1.0), "glow_offset": Vector3(0.02, 0.0, 0.0), "glow_size": Vector3(0.04, 2.6, 1.15), "color": Color(0.1, 0.22, 0.24)}
	]
	for spec in door_specs:
		var door_id: String = String(spec.get("door_id", "mission_door"))
		var sector_id: String = String(spec.get("sector_id", "arena"))
		var door_position: Vector3 = _dict_vector3(spec, "position", Vector3.ZERO)
		var door_size: Vector3 = _dict_vector3(spec, "size", Vector3.ONE)
		var glow_offset: Vector3 = _dict_vector3(spec, "glow_offset", Vector3.ZERO)
		var glow_size: Vector3 = _dict_vector3(spec, "glow_size", Vector3.ONE)
		var door_color: Color = _dict_color(spec, "color", Color(0.14, 0.2, 0.22))
		facility_state.register_door(door_id, sector_id, FacilityProgression.DOOR_LOCKED)
		var door: FacilityDoor3D = _create_facility_door(door_id, String(spec.get("name", door_id)), door_position, door_size, door_color)
		entry_doors[door_id] = door
		var mapped_doors: Array = []
		var raw_mapped_doors: Variant = mission_doors_by_sector.get(sector_id, [])
		if raw_mapped_doors is Array:
			mapped_doors = raw_mapped_doors
		mapped_doors.append(door_id)
		mission_doors_by_sector[sector_id] = mapped_doors
		var glow: Node3D = _create_box(door_id + "_EdgeGlow", door_position + glow_offset, glow_size, Color(0.12, 0.86, 0.78), false)
		for child in glow.get_children():
			if child is MeshInstance3D:
				(child as MeshInstance3D).material_override = EffectMaterialCache.get_material(Color(0.08, 0.72, 0.68), 0.18)

func _build_vent_markers() -> void:
	var vent_specs: Array[Dictionary] = [
		{"name": "SwarmerVentNorthWest", "position": Vector3(-12.0, 1.2, -35.62), "size": Vector3(0.72, 0.54, 0.12)},
		{"name": "SwarmerVentNorthEast", "position": Vector3(18.0, 1.2, -35.62), "size": Vector3(0.72, 0.54, 0.12)},
		{"name": "SwarmerVentSouthWest", "position": Vector3(-20.0, 1.2, 35.62), "size": Vector3(0.72, 0.54, 0.12)},
		{"name": "SwarmerVentSouthEast", "position": Vector3(12.0, 1.2, 35.62), "size": Vector3(0.72, 0.54, 0.12)},
		{"name": "SwarmerVentWestMid", "position": Vector3(-35.62, 1.2, -8.0), "size": Vector3(0.12, 0.54, 0.72)},
		{"name": "SwarmerVentEastMid", "position": Vector3(35.62, 1.2, 10.0), "size": Vector3(0.12, 0.54, 0.72)}
	]
	for spec in vent_specs:
		var vent_position: Vector3 = _dict_vector3(spec, "position", Vector3.ZERO)
		var vent_size: Vector3 = _dict_vector3(spec, "size", Vector3.ONE)
		var vent: Node3D = _create_box(String(spec.get("name", "SwarmerVent")), vent_position, vent_size, Color(0.08, 0.08, 0.1), false)
		vent.add_to_group("swarmer_vents")
		var slat_size: Vector3 = Vector3(vent_size.x * 0.72, vent_size.y * 0.12, vent_size.z * 1.12)
		_create_box(String(spec.get("name", "SwarmerVent")) + "_Slats", vent_position + Vector3(0.0, 0.0, -0.01), slat_size, Color(0.025, 0.03, 0.034), false)

func _build_npc_survivors() -> void:
	# Three placeholder humanoid NPCs derived from
	# ImmersiveSimDesign.get_npc_survivor_encounters(). Capsule + head sphere,
	# role-colored, with a billboarded role label so you can find them.
	var encounters = [
		{
			"encounter_id": "wounded_courier",
			"role_label": "Courier",
			"color": Color(0.4, 0.34, 0.14),
			"position": Vector3(-9.5, 0.0, 6.5)
		},
		{
			"encounter_id": "panicked_researcher",
			"role_label": "Researcher",
			"color": Color(0.2, 0.46, 0.5),
			"position": Vector3(8.5, 0.0, -6.5)
		},
		{
			"encounter_id": "trapped_engineer",
			"role_label": "Engineer",
			"color": Color(0.46, 0.28, 0.18),
			"position": Vector3(-9.0, 0.0, -8.0)
		},
	]
	for encounter in encounters:
		var npc = NpcSurvivor3D.new()
		var encounter_color: Color = _dict_color(encounter, "color", Color(0.35, 0.35, 0.32))
		var encounter_position: Vector3 = _dict_vector3(encounter, "position", Vector3.ZERO)
		npc.configure(
			String(encounter["encounter_id"]),
			String(encounter["role_label"]),
			encounter_color
		)
		arena_root.add_child(npc)
		npc.global_position = encounter_position

func _spawn_demo_enemies() -> void:
	# One of each main archetype, parked at known positions so the first launch
	# shows visual variety without waiting on the threat director ramp.
	# archetype_id must be set before add_child triggers _ready().
	if not threat_director or not enemy_container:
		return
	var demos = [
		{"id": "stalker_husk", "position": Vector3(-15.0, 0.0, -15.0)},
		{"id": "crawler_husk", "position": Vector3(15.0, 0.0, -15.0)},
		{"id": "bleeder", "position": Vector3(-15.0, 0.0, 15.0)},
		{"id": "carapace", "position": Vector3(15.0, 0.0, 15.0)},
	]
	for demo in demos:
		var enemy = EnemyBase3D.new()
		var demo_position: Vector3 = _dict_vector3(demo, "position", Vector3.ZERO)
		enemy.archetype_id = String(demo["id"])
		enemy.position = demo_position
		enemy_container.add_child(enemy)
		enemy.set_target(player)
		threat_director.active_enemies.append(enemy)

func _create_box(box_name: String, world_position: Vector3, size: Vector3, color: Color, collision: bool, surface_id: String = "metal") -> Node3D:
	var root: Node3D
	if collision:
		var static_body = ReactiveStaticBody3D.new()
		static_body.collision_layer = 1
		static_body.collision_mask = 0
		var is_structural: bool = surface_id == "deck" or surface_id == "ceiling" or surface_id == "bulkhead" or surface_id == "structural" or box_name.find("Wall") >= 0 or box_name.find("Ceiling") >= 0 or box_name.find("Partition") >= 0 or box_name.find("Frame") >= 0 or box_name == "Floor"
		var integrity: float = 120.0
		if is_structural:
			integrity = 99999.0
		static_body.configure_reactivity(surface_id, not is_structural, integrity, not is_structural)
		root = static_body
	else:
		root = Node3D.new()
	root.name = box_name
	root.position = world_position
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = size
	mesh_instance.mesh = box_mesh
	mesh_instance.material_override = _make_material(color, 0.0)
	root.add_child(mesh_instance)
	if collision:
		var collision_shape = CollisionShape3D.new()
		var box_shape = BoxShape3D.new()
		box_shape.size = size
		collision_shape.shape = box_shape
		root.add_child(collision_shape)
	arena_root.add_child(root)
	return root

func _create_facility_door(door_id: String, door_name: String, world_position: Vector3, size: Vector3, color: Color) -> FacilityDoor3D:
	var door = FacilityDoor3D.new()
	door.name = door_name
	door.position = world_position
	door.configure_door(door_id, facility_state.get_door_state(door_id), size, color)
	door.door_forced_open.connect(_on_facility_door_forced_open)
	arena_root.add_child(door)
	return door

func _make_material(color: Color, emission_energy: float) -> StandardMaterial3D:
	return EffectMaterialCache.get_material(color, emission_energy)

func _on_dynamic_button_activated(button_id: String) -> void:
	var button = arena_root.get_node_or_null(button_id)
	if button and button is Node3D:
		GameEvents.emit_player_noise(button.global_position, 10.0)
	var button_active = false
	if button is DynamicButton3D:
		button_active = (button as DynamicButton3D).active
	if button_id == "NorthOverrideButton":
		_set_door_from_button("door_north_service", button_active)
	elif button_id == "SouthOverrideButton":
		_set_door_from_button("door_south_hab", button_active)
	elif button_id == "CatwalkLiftButton":
		facility_state.unlock_flag("catwalk_service_powered")
		if player and player.comms:
			player.comms.announce("Catwalk lift circuit responded. Somewhere above you, a route changed.")

func _set_door_from_button(door_id: String, button_active: bool) -> void:
	if not entry_doors.has(door_id):
		return
	var door = entry_doors[door_id] as FacilityDoor3D
	if not door:
		return
	if door.state == FacilityProgression.DOOR_SEALED:
		if player and player.comms:
			player.comms.announce("That door is sealed. The override cannot move it.")
		return
	var new_state = FacilityProgression.DOOR_OPEN if button_active else FacilityProgression.DOOR_LOCKED
	facility_state.set_door_state(door_id, new_state)
	door.set_state(new_state)
	if player and player.comms:
		var message = "Override opened a pressure door." if button_active else "Override dropped. Door locked again."
		player.comms.announce(message)

func _on_facility_door_forced_open(door_id: String) -> void:
	facility_state.set_door_state(door_id, FacilityProgression.DOOR_OPEN)
	facility_state.unlock_flag("forced_%s" % door_id)
	if player and player.comms:
		player.comms.announce("Door forced. The station will remember that route.")

func _on_objective_triggered_callout(_objective_id: String, _objective_type: String, _sector_id: String, _position: Vector3) -> void:
	if player and player.comms:
		player.comms.announce("Objective triggered — breach incoming. Watch your six.")

func _on_mission_objective_completed(_objective_id: String, _objective_type: String, sector_id: String, position: Vector3) -> void:
	_unlock_mission_doors_for_sector(sector_id, position)
	if player and player.comms:
		player.comms.announce("Sector cleared. Door unlocked.")

func _unlock_mission_doors_for_sector(sector_id: String, trace_position: Vector3) -> void:
	if not mission_doors_by_sector.has(sector_id):
		return
	var raw_doors: Variant = mission_doors_by_sector.get(sector_id, [])
	if not (raw_doors is Array):
		return
	var opened_count: int = 0
	for door_id_value in raw_doors:
		var door_id: String = String(door_id_value)
		facility_state.set_door_state(door_id, FacilityProgression.DOOR_OPEN)
		if entry_doors.has(door_id):
			var door: FacilityDoor3D = entry_doors[door_id] as FacilityDoor3D
			if door:
				door.set_state(FacilityProgression.DOOR_OPEN)
				_leave_solver_trace("UnlockTrace_%s" % door_id, door.global_position + Vector3.UP * 0.2, Color(0.12, 0.85, 0.74))
				opened_count += 1
	if opened_count > 0 and player and player.comms:
		player.comms.announce("%s bulkhead released." % sector_id.replace("_", " "))
	GameEvents.emit_environment_impulse(trace_position, 1.0, 3.5, self, "sector_bulkhead_release")

func _on_all_objectives_completed_callout() -> void:
	if player and player.comms:
		player.comms.announce("All objectives complete. Find the extraction point. Move.")

func _on_extraction_available_callout(_position: Vector3) -> void:
	if player and player.comms:
		player.comms.announce("LZ is hot. Get to extraction now.")

func _on_service_node_used(_node_id: String, service_type: String, target_id: String, method_id: String, _actor: Node) -> void:
	if service_type == "sector_power":
		if sector_power and sector_power.restore_sector(target_id, method_id):
			if player and player.comms:
				player.comms.announce("Sector lighting restored via %s." % method_id.replace("_", " "))
	elif service_type == "door_override":
		_open_door_from_service(target_id, method_id)
	elif service_type == "route_discovery":
		if route_system:
			route_system.discover_route(target_id)
			facility_state.unlock_flag("route_%s_discovered" % target_id)
		if player and player.comms:
			player.comms.announce("Route clue logged: %s." % target_id.replace("_", " "))
	elif service_type == "floor_route":
		if route_system:
			route_system.discover_route(target_id)
			if route_system.use_route(target_id):
				_transition_floor_in_place(target_id)
	elif service_type == "workbench":
		_use_workbench(method_id, _actor)

func _use_workbench(method_id: String, actor: Node) -> void:
	if not actor or not actor.has_method("add_resource"):
		return
	if method_id == "assemble_crash_kit":
		if actor.has_method("consume_resource") and not actor.consume_resource("cable_spool", 1):
			if actor.has_method("notify_service_failure"):
				actor.notify_service_failure("Workbench needs a cable spool for the crash kit wrap.")
			return
		actor.add_resource("crash_kit", 1)
		_leave_solver_trace("WorkbenchCrashKitTrace", Vector3(0.0, 0.46, -12.0), Color(0.2, 0.6, 0.42))
	elif method_id == "build_splint_roll":
		actor.add_resource("splint_roll", 1)

func _transition_floor_in_place(route_id: String) -> void:
	if not player or not route_system:
		return
	if route_system.current_floor >= route_system.final_escape_floor:
		GameEvents.end_run(true, "escaped the station through %s" % route_id.replace("_", " "))
		return
	player.global_position = Vector3(0, 0.05, 0)
	player.play_spawn_intro("FLOOR %d\n%s" % [route_system.current_floor, route_id.replace("_", " ").to_upper()], "shaft" if route_id.find("ladder") >= 0 or route_id.find("vent") >= 0 else "door")
	_refresh_floor_content(route_system.current_floor)

func _refresh_floor_content(floor_index: int) -> void:
	if sector_power:
		sector_power.cut_sector_power("arena", "floor_%d_load_shed" % floor_index)
	if threat_director:
		threat_director.set_station_floor(floor_index)
	if floor_index >= 2:
		_create_resource_pickup("Floor%dPowerCell" % floor_index, Vector3(randf_range(-12.0, 12.0), 0.35, randf_range(-12.0, 12.0)), "power_cell", 1)
	if floor_index >= 3:
		_create_weapon_attachment_pickup("Floor%dTelemetry" % floor_index, Vector3(randf_range(-14.0, 14.0), 0.45, randf_range(-14.0, 14.0)), "ammo_telemetry_transmitter")

func _open_door_from_service(door_id: String, method_id: String) -> void:
	if not entry_doors.has(door_id):
		return
	var door = entry_doors[door_id] as FacilityDoor3D
	if not door:
		return
	if door.state == FacilityProgression.DOOR_SEALED and method_id != "cut_debris":
		if player and player.comms:
			player.comms.announce("Service node responded, but the door is sealed.")
		return
	if method_id == "reverse_motor" and door.state == FacilityProgression.DOOR_LOCKED:
		if player and player.comms:
			player.comms.announce("Motor reverses, but the lock still needs a credential or bypass.")
		return
	facility_state.set_door_state(door_id, FacilityProgression.DOOR_OPEN)
	facility_state.unlock_flag("service_opened_%s" % door_id)
	if method_id == "cut_debris":
		facility_state.unlock_flag("breachable_route_%s_opened" % door_id)
		for route_id in facility_state.hidden_routes.keys():
			facility_state.mark_route_discovered(String(route_id))
			break
	door.set_state(FacilityProgression.DOOR_OPEN)
	_leave_solver_trace("Trace_%s_%s" % [door_id, method_id], door.global_position + Vector3.UP * 0.2, Color(0.7, 0.42, 0.14) if method_id == "cut_debris" else Color(0.18, 0.6, 0.7))
	if player and player.comms:
		player.comms.announce("Door opened through %s." % method_id.replace("_", " "))
	if sector_power and sector_power.is_powered("arena"):
		sector_power.cut_sector_power("arena", "door_motor_brownout")
		await get_tree().create_timer(20.0).timeout
		if sector_power:
			sector_power.restore_sector("arena", "brownout_recovered")

func _apply_sector_light_state(sector_id: String, powered: bool, _method_id: String) -> void:
	var lights: Array = []
	var raw_lights: Variant = sector_lights.get(sector_id, [])
	if raw_lights is Array:
		lights = raw_lights
	for light in lights:
		if not is_instance_valid(light):
			continue
		var omni: OmniLight3D = light as OmniLight3D
		if not omni:
			continue
		omni.light_energy = 2.4 if powered else 0.0
		omni.light_color = Color(0.62, 0.88, 0.92) if powered else Color(0.04, 0.08, 0.1)
	var emergency_lights: Array = []
	var raw_emergency_lights: Variant = emergency_lights_by_sector.get(sector_id, [])
	if raw_emergency_lights is Array:
		emergency_lights = raw_emergency_lights
	for emergency_light in emergency_lights:
		if emergency_light is OmniLight3D and is_instance_valid(emergency_light):
			(emergency_light as OmniLight3D).light_energy = 0.0 if powered else 0.8
	_update_ambient_power_state()

func _update_ambient_power_state() -> void:
	if not world_environment or not world_environment.environment or not sector_power:
		return
	var any_dark: bool = false
	for sector_value in sector_power.sectors.values():
		if sector_value is Dictionary:
			var sector: Dictionary = sector_value
			if not bool(sector.get("powered", true)):
				any_dark = true
				break
	world_environment.environment.ambient_light_energy = 0.04 if any_dark else 0.22

func _leave_solver_trace(trace_name: String, world_position: Vector3, color: Color) -> void:
	if not arena_root:
		return
	var trace = _create_box(trace_name, world_position, Vector3(0.7, 0.05, 0.7), color, false)
	trace.name = trace_name
	facility_state.unlock_flag("trace_%s" % trace_name)

func _on_station_floor_changed(floor_index: int, route_id: String) -> void:
	facility_state.unlock_flag("reached_floor_%d" % floor_index)
	_save_facility_snapshot()
	if threat_director:
		threat_director.set_station_floor(floor_index)
	if player and player.comms:
		player.comms.announce("Floor transition logged through %s." % route_id.replace("_", " "))

func _on_player_died(reason: String) -> void:
	if successor_spawn_in_progress or run_finished:
		return
	successor_spawn_in_progress = true
	var dead_player = player
	if is_instance_valid(dead_player):
		dead_player.survivor_loadout["last_note"] = dead_player.build_last_note(reason)
		dead_player.survivor_loadout["last_path"] = _pack_vector_path(dead_player.get_last_path())
		if dead_player.weapon:
			dead_player.survivor_loadout["weapon_state"] = dead_player.weapon.get_weapon_state()
		dead_player.survivor_loadout["glasses_lens_damage"] = dead_player.glasses_lens_damage
		facility_state.record_lost_survivor(dead_player.global_position, current_room_id, survivor_count, reason)
		_drop_lost_survivor_kit(dead_player.global_position, dead_player.survivor_loadout, dead_player.had_headset_when_lost(), dead_player.health.bleed_rate > 0.0)
	if is_instance_valid(dead_player):
		dead_player.show_death_handoff(reason)
	_save_facility_snapshot()
	if threat_director:
		threat_director.set_player(null)
	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(dead_player):
		dead_player.queue_free()
	_spawn_survivor("successor")
	successor_spawn_in_progress = false

func _drop_lost_survivor_kit(world_position: Vector3, loadout: Dictionary, had_headset: bool, bleeding_death: bool) -> void:
	var kit = LostSurvivorKit3D.new()
	kit.name = "LostSurvivorKit_%d" % survivor_count
	kit.configure_lost_kit(survivor_count, loadout, had_headset, bleeding_death)
	arena_root.add_child(kit)
	kit.global_position = world_position + Vector3(0, 0.45, 0)

func _pack_vector_path(path: Array[Vector3]) -> Array:
	var packed = []
	for point in path:
		packed.append([point.x, point.y, point.z])
	return packed

func _save_facility_snapshot() -> void:
	if not facility_state:
		return
	var save_data = {
		"facility": facility_state.to_save_dict(),
		"survivor_count": survivor_count,
		"current_floor": route_system.current_floor if route_system else 0
	}
	var file = FileAccess.open("user://facility_snapshot.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))

func _load_facility_snapshot() -> bool:
	if not FileAccess.file_exists("user://facility_snapshot.json") or not facility_state:
		return false
	var file = FileAccess.open("user://facility_snapshot.json", FileAccess.READ)
	if not file:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		return false
	facility_state.load_save_dict(parsed.get("facility", {}))
	survivor_count = int(parsed.get("survivor_count", survivor_count))
	if route_system:
		route_system.current_floor = int(parsed.get("current_floor", route_system.current_floor))
	return true

func _on_run_ended(success: bool, reason: String) -> void:
	run_finished = true
	if player:
		player.show_end_state(success, reason)
