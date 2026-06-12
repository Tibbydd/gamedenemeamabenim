extends Node3D

var player: PlayerControllerFPS
var facility_state: FacilityProgression
var dynamic_world: DynamicWorldSystem
var route_system: StationRouteSystem
var sector_power: SectorPowerSystem
var threat_director: ThreatDirector
var objective_system: ObjectiveSystem
var run_modifier_system: RunModifierSystem
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
var _alarm_loop_player: AudioStreamPlayer = null

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
	_build_run_modifier_system()
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
	ambient_event_timer = randf_range(7.0, 16.0)
	_play_ambient_event()

func _play_ambient_event() -> void:
	var player_pos: Vector3 = Vector3.ZERO
	if player:
		player_pos = player.global_position
	var floor_y: float = player_pos.y
	# Roll the sound type weighted by context
	var roll := randf()
	var sound_id: String
	if roll < 0.22:
		sound_id = "ambient_pipe_groan"
	elif roll < 0.40:
		sound_id = "ambient_distant_impact"
	elif roll < 0.56:
		sound_id = "ambient_electric"
	elif roll < 0.72:
		sound_id = "ambient_clank"
	elif roll < 0.87:
		sound_id = "ambient_drip"
	else:
		sound_id = "ambient_hum"
	# Place the sound near the player but offset to a random direction
	var angle := randf() * TAU
	var dist := randf_range(6.0, 22.0)
	var height_offset := randf_range(-1.2, 3.5)
	var event_position := Vector3(
		player_pos.x + cos(angle) * dist,
		floor_y + height_offset,
		player_pos.z + sin(angle) * dist
	)
	# Pitch shifts slightly based on floor — higher floors sound more strained
	var floor_index: int = int(round(floor_y / 4.2))
	var base_pitch: float = 0.82 + float(floor_index) * 0.04
	AudioRouter.play_3d(sound_id, event_position, randf_range(base_pitch * 0.94, base_pitch * 1.06))

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
	var environment := Environment.new()
	# Mars-like procedural sky visible through windows and exterior gaps
	var proc_sky := ProceduralSkyMaterial.new()
	proc_sky.sky_top_color = Color(0.05, 0.025, 0.012)
	proc_sky.sky_horizon_color = Color(0.60, 0.26, 0.10)
	proc_sky.sky_curve = 0.20
	proc_sky.sky_energy_multiplier = 0.90
	proc_sky.ground_bottom_color = Color(0.20, 0.09, 0.04)
	proc_sky.ground_horizon_color = Color(0.48, 0.20, 0.09)
	proc_sky.ground_curve = 0.03
	proc_sky.sun_angle_max = 48.0
	proc_sky.sun_curve = 0.25
	var sky := Sky.new()
	sky.sky_material = proc_sky
	environment.sky = sky
	environment.background_mode = Environment.BG_SKY
	environment.background_energy_multiplier = 0.82
	# Warm dusty ambient from atmospheric scatter
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.11, 0.08, 0.06)
	environment.ambient_light_energy = 0.18
	# Atmospheric dust — keeps interior spooky, exterior shows distance haze
	environment.fog_enabled = true
	environment.fog_density = 0.038
	environment.fog_light_color = Color(0.50, 0.26, 0.12)
	environment.fog_aerial_perspective = 0.22
	world_environment.environment = environment
	world_environment.add_to_group("world_env")
	add_child(world_environment)
	# Mars sun — low angle, warm light
	var sun := DirectionalLight3D.new()
	sun.name = "MarsSun"
	sun.rotation_degrees = Vector3(-32, 68, 0)
	sun.light_energy = 0.70
	sun.light_color = Color(0.90, 0.76, 0.60)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 80.0
	add_child(sun)
	# Weak fill from opposite side — simulates atmospheric bounce
	var fill := DirectionalLight3D.new()
	fill.name = "MarsAmbientFill"
	fill.rotation_degrees = Vector3(-55, -112, 0)
	fill.light_energy = 0.10
	fill.light_color = Color(0.55, 0.38, 0.30)
	fill.shadow_enabled = false
	add_child(fill)

func _build_arena() -> void:
	arena_root = Node3D.new()
	arena_root.name = "GreyboxRuinedFacility"
	add_child(arena_root)
	enemy_container = Node3D.new()
	enemy_container.name = "Enemies"
	add_child(enemy_container)
	_build_exterior()
	_build_outer_hull()
	nav_blockers.clear()
	_build_room_shell_geometry()
	_build_room_props()
	_build_wall_detail_pass()
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
	for point in [
		# F0 — arrival / cargo / utilities / power (inside verified rooms)
		Vector3(  0.0, 0.05, -21.5),  # SecurityCheck
		Vector3(  0.0, 0.05, -10.0),  # ReceptionLobby
		Vector3( 16.0, 0.05,  -3.0),  # CargoHub
		Vector3( 25.0, 0.05,   6.0),  # ColdStorage
		Vector3(-15.0, 0.05,  -3.0),  # WaterTreatment
		Vector3(-29.0, 0.05,  -3.0),  # MaintWorkshop
		Vector3(  0.0, 0.05,  14.0),  # PowerHub
		Vector3(-11.0, 0.05,  21.0),  # GenRoom
		# F1 — quarters / medical / living
		Vector3(-18.0, 4.25, -16.0),  # BunkRoom
		Vector3( -4.0, 4.25, -16.0),  # MedBay
		Vector3( 10.0, 4.25,  -3.0),  # ESpine
		Vector3( 25.0, 4.25,   4.0),  # FoodStorage
		# F2 — labs / containment / research
		Vector3(-18.0, 8.45, -16.0),  # WetLab
		Vector3( -4.0, 8.45,  -3.0),  # MidSpine
		Vector3( 10.0, 8.45,  -9.0),  # ChemStorage
		Vector3( 25.0, 8.45,  -9.0),  # DryLab
		# F3 — command / comms / reactor
		Vector3( -4.0,12.65, -16.0),  # CommandBridge
		Vector3(-18.0,12.65,  -9.0),  # CommsCorr
		Vector3( 10.0,12.65, -16.0),  # ReactorControl
		Vector3( 25.0,12.65,  -3.0),  # ESpine2
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
	_build_steam_vents()
	_build_reverb_zones()
	_spawn_death_memorials()
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
	var min_coord = -46.0
	var cell_count = 46
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
	for spec in _get_station_room_specs():
		_create_station_room_shell(spec)
	_build_station_vertical_connections()

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
	if _blocker_intersects_ground_nav(world_position, size):
		_register_nav_blocker(world_position, size)

func _blocker_intersects_ground_nav(world_position: Vector3, size: Vector3) -> bool:
	var min_y: float = world_position.y - size.y * 0.5
	var max_y: float = world_position.y + size.y * 0.5
	return min_y <= 0.35 and max_y >= -0.35

func _get_station_room_specs() -> Array[Dictionary]:
	# Astra Relay Station K-17 — four floors, each 3.0m ceiling, 4.2m floor separation
	# All rooms placed edge-to-edge so adjacent walls share the same coordinate.
	var f0 := 0.0
	var f1 := 4.2
	var f2 := 8.4
	var f3 := 12.6
	return [
		# ═══════════════════════════════════════════════════════════════
		# FLOOR 0 — ARRIVAL / CARGO / UTILITIES / POWER
		# All F0 positions verified edge-to-edge:
		#   north wall z = center_z - size_z/2
		#   south wall z = center_z + size_z/2
		#   east  wall x = center_x + size_x/2
		#   west  wall x = center_x - size_x/2
		# ═══════════════════════════════════════════════════════════════
		# --- f0_arrival spine (x=0, marching south) ---
		# AirlockEntry  z[-36,-30]
		{"name":"F0_AirlockEntry",    "position":Vector3(  0,f0,-33.0), "size":Vector2( 6, 6), "sector_id":"f0_arrival",   "open_sides":["south"]},
		# ArrivalCorr   z[-30,-25]  north=-30=AirlockEntry.south
		{"name":"F0_ArrivalCorr",     "position":Vector3(  0,f0,-27.5), "size":Vector2( 4, 5), "sector_id":"f0_arrival",   "open_sides":["north","south"]},
		# SecurityCheck z[-25,-18]  north=-25=ArrivalCorr.south
		{"name":"F0_SecurityCheck",   "position":Vector3(  0,f0,-21.5), "size":Vector2(10, 7), "sector_id":"f0_arrival",   "open_sides":["north","south","east","west"]},
		# SecurityOffice  west=5=SecurityCheck.east  (same center_z → doors align)
		{"name":"F0_SecurityOffice",  "position":Vector3(  8,f0,-21.5), "size":Vector2( 6, 7), "sector_id":"f0_arrival",   "open_sides":["west"]},
		# HoldingCell     east=-5=SecurityCheck.west
		{"name":"F0_HoldingCell",     "position":Vector3( -8,f0,-21.5), "size":Vector2( 6, 7), "sector_id":"f0_arrival",   "open_sides":["east"]},
		# LobbyCorr     z[-18,-14]  north=-18=SecurityCheck.south
		{"name":"F0_LobbyCorr",       "position":Vector3(  0,f0,-16.0), "size":Vector2( 4, 4), "sector_id":"f0_arrival",   "open_sides":["north","south"]},
		# ReceptionLobby z[-14,-6]  north=-14=LobbyCorr.south
		{"name":"F0_ReceptionLobby",  "position":Vector3(  0,f0,-10.0), "size":Vector2(14, 8), "sector_id":"f0_arrival",   "open_sides":["north","south","east","west"]},
		# VisitorWaiting  east=-7=ReceptionLobby.west  (same center_z → doors align)
		{"name":"F0_VisitorWaiting",  "position":Vector3(-10,f0,-10.0), "size":Vector2( 6, 8), "sector_id":"f0_arrival",   "open_sides":["east"]},
		# AdminRecords    west=7=ReceptionLobby.east
		{"name":"F0_AdminRecords",    "position":Vector3( 10,f0,-10.0), "size":Vector2( 6, 8), "sector_id":"f0_arrival",   "open_sides":["west"]},
		# CentralJunct  z[-6,0]     north=-6=ReceptionLobby.south
		{"name":"F0_CentralJunct",    "position":Vector3(  0,f0, -3.0), "size":Vector2( 6, 6), "sector_id":"f0_arrival",   "open_sides":["north","south","east","west"]},

		# --- f0_cargo (east branch from CentralJunct) ---
		# CargoCorr     x[3,11]    west=3=CentralJunct.east
		{"name":"F0_CargoCorr",       "position":Vector3(  7,f0, -3.0), "size":Vector2( 8, 4), "sector_id":"f0_cargo",     "open_sides":["east","west"]},
		# CargoHub      x[11,21]   west=11=CargoCorr.east   z[-8,2]
		{"name":"F0_CargoHub",        "position":Vector3( 16,f0, -3.0), "size":Vector2(10,10), "sector_id":"f0_cargo",     "open_sides":["west","north","east","south"]},
		# CargoNCorr    z[-12,-8]  south=-8=CargoHub.north
		{"name":"F0_CargoNCorr",      "position":Vector3( 16,f0,-10.0), "size":Vector2( 4, 4), "sector_id":"f0_cargo",     "open_sides":["south"]},
		# CargoBay      x[21,29]   west=21=CargoHub.east    z[-8,2]
		{"name":"F0_CargoBay",        "position":Vector3( 25,f0, -3.0), "size":Vector2( 8,10), "sector_id":"f0_cargo",     "open_sides":["west","east","south"]},
		# LoadingDock   z[2,10]    north=2=CargoHub.south   x[11,21]
		{"name":"F0_LoadingDock",     "position":Vector3( 16,f0,  6.0), "size":Vector2(10, 8), "sector_id":"f0_cargo",     "open_sides":["north","east"]},
		# ColdStorage   x[21,29]   west=21=LoadingDock.east  north=2=CargoBay.south
		{"name":"F0_ColdStorage",     "position":Vector3( 25,f0,  6.0), "size":Vector2( 8, 8), "sector_id":"f0_cargo",     "open_sides":["north","west","south"]},
		# ForkliftCharge z[10,16]  north=10=ColdStorage.south
		{"name":"F0_ForkliftCharge",  "position":Vector3( 25,f0, 13.0), "size":Vector2( 7, 6), "sector_id":"f0_cargo",     "open_sides":["north"]},
		# EStairCorr    x[29,33]   west=29=CargoBay.east    z[-8,2]
		{"name":"F0_EStairCorr",      "position":Vector3( 31,f0, -3.0), "size":Vector2( 4,10), "sector_id":"f0_cargo",     "open_sides":["west","east"]},
		# EStairEntry   x[33,37]   west=33=EStairCorr.east
		{"name":"F0_EStairEntry",     "position":Vector3( 35,f0, -3.0), "size":Vector2( 4, 6), "sector_id":"f0_cargo",     "open_sides":["west"]},

		# --- f0_utilities (west branch from CentralJunct) ---
		# UtilCorr      x[-11,-3]  east=-3=CentralJunct.west
		{"name":"F0_UtilCorr",        "position":Vector3( -7,f0, -3.0), "size":Vector2( 8, 4), "sector_id":"f0_utilities", "open_sides":["east","west"]},
		# WaterTreatment x[-19,-11] east=-11=UtilCorr.west   z[-7,1]
		{"name":"F0_WaterTreatment",  "position":Vector3(-15,f0, -3.0), "size":Vector2( 8, 8), "sector_id":"f0_utilities", "open_sides":["east","south"]},
		# WasteProcessing z[1,9]   north=1=WaterTreatment.south
		{"name":"F0_WasteProcessing", "position":Vector3(-15,f0,  5.0), "size":Vector2( 8, 8), "sector_id":"f0_utilities", "open_sides":["north"]},
		# MaintCorr     x[-25,-19] east=-19=WaterTreatment.west
		{"name":"F0_MaintCorr",       "position":Vector3(-22,f0, -3.0), "size":Vector2( 6, 4), "sector_id":"f0_utilities", "open_sides":["east","west"]},
		# MaintWorkshop x[-33,-25] east=-25=MaintCorr.west   z[-7,1]
		{"name":"F0_MaintWorkshop",   "position":Vector3(-29,f0, -3.0), "size":Vector2( 8, 8), "sector_id":"f0_utilities", "open_sides":["east","south"]},
		# WStairEntry   z[1,9]     north=1=MaintWorkshop.south  (stairwell at x=-29)
		{"name":"F0_WStairEntry",     "position":Vector3(-29,f0,  5.0), "size":Vector2( 6, 8), "sector_id":"f0_utilities", "open_sides":["north"]},

		# --- f0_power (south branch from CentralJunct) ---
		# PowerJunct    z[0,6]     north=0=CentralJunct.south
		{"name":"F0_PowerJunct",      "position":Vector3(  0,f0,  3.0), "size":Vector2( 6, 6), "sector_id":"f0_power",     "open_sides":["north","south"]},
		# PowerCorr     z[6,11]    north=6=PowerJunct.south
		{"name":"F0_PowerCorr",       "position":Vector3(  0,f0,  8.5), "size":Vector2( 4, 5), "sector_id":"f0_power",     "open_sides":["north","south"]},
		# PowerHub      z[11,17]   north=11=PowerCorr.south   x[-6,6]
		{"name":"F0_PowerHub",        "position":Vector3(  0,f0, 14.0), "size":Vector2(12, 6), "sector_id":"f0_power",     "open_sides":["north","west","east","south"]},
		# GenControl    x[-14,-6]  east=-6=PowerHub.west   z[11,17]
		{"name":"F0_GenControl",      "position":Vector3(-10,f0, 14.0), "size":Vector2( 8, 6), "sector_id":"f0_power",     "open_sides":["east","south"]},
		# TransformerRoom x[6,14]  west=6=PowerHub.east    z[11,17]
		{"name":"F0_TransformerRoom", "position":Vector3( 10,f0, 14.0), "size":Vector2( 8, 6), "sector_id":"f0_power",     "open_sides":["west","south"]},
		# GenRoom       z[17,25]   north=17=GenControl.south  x[-16,-6]
		{"name":"F0_GenRoom",         "position":Vector3(-11,f0, 21.0), "size":Vector2(10, 8), "sector_id":"f0_power",     "open_sides":["north","east"]},
		# BatteryBackup x[-6,6]    west=-6=GenRoom.east  north=17=PowerHub.south  east=6=SpareParts.west
		{"name":"F0_BatteryBackup",   "position":Vector3(  0,f0, 21.0), "size":Vector2(12, 8), "sector_id":"f0_power",     "open_sides":["north","west","east"]},
		# SpareParts    x[6,14]    west=6=BatteryBackup.east  north=17=TransformerRoom.south
		{"name":"F0_SpareParts",      "position":Vector3( 10,f0, 21.0), "size":Vector2( 8, 8), "sector_id":"f0_power",     "open_sides":["north","west"]},

		# ═══════════════════════════════════════════════════════════════
		# FLOOR 1 — CREW QUARTERS / MEDICAL / LIVING
		# E-W spine at z=-3 connects both stairwells; branches hang N and S.
		# All branch rooms connect at z=-6 (spine.north) or z=0 (spine.south).
		# ═══════════════════════════════════════════════════════════════
		# --- F1 spine ---
		{"name":"F1_WStairLand",   "position":Vector3(-29,f1,-3.0), "size":Vector2( 8, 6), "sector_id":"f1_quarters", "open_sides":["east"],                       "floor_y":f1, "ceiling_y":f1+3.0},
		{"name":"F1_WSpine",       "position":Vector3(-18,f1,-3.0), "size":Vector2(14, 6), "sector_id":"f1_quarters", "open_sides":["west","east","north","south"], "floor_y":f1, "ceiling_y":f1+3.0},
		{"name":"F1_MidSpine",     "position":Vector3( -4,f1,-3.0), "size":Vector2(14, 6), "sector_id":"f1_medical",  "open_sides":["west","east","north","south"], "floor_y":f1, "ceiling_y":f1+3.0},
		{"name":"F1_ESpine",       "position":Vector3( 10,f1,-3.0), "size":Vector2(14, 6), "sector_id":"f1_medical",  "open_sides":["west","east","north","south"], "floor_y":f1, "ceiling_y":f1+3.0},
		{"name":"F1_ESpine2",      "position":Vector3( 25,f1,-3.0), "size":Vector2(16, 6), "sector_id":"f1_living",   "open_sides":["west","east","north","south"], "floor_y":f1, "ceiling_y":f1+3.0},
		{"name":"F1_EStairLand",   "position":Vector3( 35,f1,-3.0), "size":Vector2( 4, 6), "sector_id":"f1_living",   "open_sides":["west"],                       "floor_y":f1, "ceiling_y":f1+3.0},
		# --- F1 WSpine branches (center_x=-18) ---
		{"name":"F1_QuartersCorr", "position":Vector3(-18,f1,-9.0), "size":Vector2(10, 6), "sector_id":"f1_quarters", "open_sides":["south","north"],              "floor_y":f1, "ceiling_y":f1+3.0},
		{"name":"F1_BunkRoom",     "position":Vector3(-18,f1,-16.0),"size":Vector2(14, 8), "sector_id":"f1_quarters", "open_sides":["south"],                      "floor_y":f1, "ceiling_y":f1+3.0},
		{"name":"F1_MessHall",     "position":Vector3(-18,f1, 4.0), "size":Vector2(14, 8), "sector_id":"f1_living",   "open_sides":["north"],                      "floor_y":f1, "ceiling_y":f1+3.0},
		# --- F1 MidSpine branches (center_x=-4) ---
		{"name":"F1_MedCorr",      "position":Vector3( -4,f1,-9.0), "size":Vector2(10, 6), "sector_id":"f1_medical",  "open_sides":["south","north"],              "floor_y":f1, "ceiling_y":f1+3.0},
		{"name":"F1_MedBay",       "position":Vector3( -4,f1,-16.0),"size":Vector2(12, 8), "sector_id":"f1_medical",  "open_sides":["south"],                      "floor_y":f1, "ceiling_y":f1+3.0},
		{"name":"F1_RecRoom",      "position":Vector3( -4,f1, 4.0), "size":Vector2(12, 8), "sector_id":"f1_living",   "open_sides":["north"],                      "floor_y":f1, "ceiling_y":f1+3.0},
		# --- F1 ESpine branches (center_x=10) ---
		{"name":"F1_Pharmacy",     "position":Vector3( 10,f1,-9.0), "size":Vector2(10, 6), "sector_id":"f1_medical",  "open_sides":["south","north"],              "floor_y":f1, "ceiling_y":f1+3.0},
		{"name":"F1_ExamRoom",     "position":Vector3( 10,f1,-16.0),"size":Vector2(10, 8), "sector_id":"f1_medical",  "open_sides":["south"],                      "floor_y":f1, "ceiling_y":f1+3.0},
		{"name":"F1_Gym",          "position":Vector3( 10,f1, 5.0), "size":Vector2(12,10), "sector_id":"f1_living",   "open_sides":["north","south"],              "floor_y":f1, "ceiling_y":f1+3.0},
		{"name":"F1_Showers",      "position":Vector3( 10,f1,13.0), "size":Vector2(10, 6), "sector_id":"f1_living",   "open_sides":["north"],                      "floor_y":f1, "ceiling_y":f1+3.0},
		# --- F1 ESpine2 branches (center_x=25) ---
		{"name":"F1_Surgery",      "position":Vector3( 25,f1,-9.0), "size":Vector2(10, 6), "sector_id":"f1_medical",  "open_sides":["south","north"],              "floor_y":f1, "ceiling_y":f1+3.0},
		{"name":"F1_Morgue",       "position":Vector3( 25,f1,-16.0),"size":Vector2(10, 8), "sector_id":"f1_medical",  "open_sides":["south"],                      "floor_y":f1, "ceiling_y":f1+3.0},
		{"name":"F1_FoodStorage",  "position":Vector3( 25,f1, 4.0), "size":Vector2(12, 8), "sector_id":"f1_living",   "open_sides":["north"],                      "floor_y":f1, "ceiling_y":f1+3.0},

		# ═══════════════════════════════════════════════════════════════
		# FLOOR 2 — RESEARCH LABS / CONTAINMENT / R&D
		# Same E-W spine layout as F1; different room names.
		# ═══════════════════════════════════════════════════════════════
		{"name":"F2_WStairLand",   "position":Vector3(-29,f2,-3.0), "size":Vector2( 8, 6), "sector_id":"f2_labs",        "open_sides":["east"],                       "floor_y":f2, "ceiling_y":f2+3.0},
		{"name":"F2_WSpine",       "position":Vector3(-18,f2,-3.0), "size":Vector2(14, 6), "sector_id":"f2_labs",        "open_sides":["west","east","north","south"], "floor_y":f2, "ceiling_y":f2+3.0},
		{"name":"F2_MidSpine",     "position":Vector3( -4,f2,-3.0), "size":Vector2(14, 6), "sector_id":"f2_containment", "open_sides":["west","east","north","south"], "floor_y":f2, "ceiling_y":f2+3.0},
		{"name":"F2_ESpine",       "position":Vector3( 10,f2,-3.0), "size":Vector2(14, 6), "sector_id":"f2_research",    "open_sides":["west","east","north","south"], "floor_y":f2, "ceiling_y":f2+3.0},
		{"name":"F2_ESpine2",      "position":Vector3( 25,f2,-3.0), "size":Vector2(16, 6), "sector_id":"f2_research",    "open_sides":["west","east","north","south"], "floor_y":f2, "ceiling_y":f2+3.0},
		{"name":"F2_EStairLand",   "position":Vector3( 35,f2,-3.0), "size":Vector2( 4, 6), "sector_id":"f2_research",    "open_sides":["west"],                       "floor_y":f2, "ceiling_y":f2+3.0},
		# --- F2 WSpine branches ---
		{"name":"F2_DeconCorr",    "position":Vector3(-18,f2,-9.0), "size":Vector2(10, 6), "sector_id":"f2_labs",        "open_sides":["south","north"],              "floor_y":f2, "ceiling_y":f2+3.0},
		{"name":"F2_WetLab",       "position":Vector3(-18,f2,-16.0),"size":Vector2(12, 8), "sector_id":"f2_labs",        "open_sides":["south"],                      "floor_y":f2, "ceiling_y":f2+3.0},
		{"name":"F2_ContainmentA", "position":Vector3(-18,f2, 4.0), "size":Vector2(14, 8), "sector_id":"f2_containment", "open_sides":["north"],                      "floor_y":f2, "ceiling_y":f2+3.0},
		# --- F2 MidSpine branches ---
		{"name":"F2_ResearchHub",  "position":Vector3( -4,f2,-9.0), "size":Vector2(12, 6), "sector_id":"f2_containment", "open_sides":["south","north"],              "floor_y":f2, "ceiling_y":f2+3.0},
		{"name":"F2_SampleFreezer","position":Vector3( -4,f2,-16.0),"size":Vector2(10, 8), "sector_id":"f2_labs",        "open_sides":["south"],                      "floor_y":f2, "ceiling_y":f2+3.0},
		{"name":"F2_SpecimenPrep", "position":Vector3( -4,f2, 4.0), "size":Vector2(12, 8), "sector_id":"f2_containment", "open_sides":["north"],                      "floor_y":f2, "ceiling_y":f2+3.0},
		# --- F2 ESpine branches ---
		{"name":"F2_ChemStorage",  "position":Vector3( 10,f2,-9.0), "size":Vector2(10, 6), "sector_id":"f2_research",    "open_sides":["south","north"],              "floor_y":f2, "ceiling_y":f2+3.0},
		{"name":"F2_SecureArchive","position":Vector3( 10,f2,-16.0),"size":Vector2(10, 8), "sector_id":"f2_research",    "open_sides":["south"],                      "floor_y":f2, "ceiling_y":f2+3.0},
		{"name":"F2_RoboticsBay",  "position":Vector3( 10,f2, 5.0), "size":Vector2(12,10), "sector_id":"f2_research",    "open_sides":["north","south"],              "floor_y":f2, "ceiling_y":f2+3.0},
		{"name":"F2_ObservRoom",   "position":Vector3( 10,f2,13.0), "size":Vector2(10, 6), "sector_id":"f2_containment", "open_sides":["north"],                      "floor_y":f2, "ceiling_y":f2+3.0},
		# --- F2 ESpine2 branches ---
		{"name":"F2_DryLab",       "position":Vector3( 25,f2,-9.0), "size":Vector2(10, 6), "sector_id":"f2_research",    "open_sides":["south","north"],              "floor_y":f2, "ceiling_y":f2+3.0},
		{"name":"F2_ServerAnalysis","position":Vector3( 25,f2,-16.0),"size":Vector2(10, 8), "sector_id":"f2_research",    "open_sides":["south"],                      "floor_y":f2, "ceiling_y":f2+3.0},
		{"name":"F2_QuarantineCell","position":Vector3( 25,f2, 4.0), "size":Vector2(10, 8), "sector_id":"f2_containment", "open_sides":["north"],                      "floor_y":f2, "ceiling_y":f2+3.0},

		# ═══════════════════════════════════════════════════════════════
		# FLOOR 3 — COMMAND / COMMUNICATIONS / REACTOR
		# Same E-W spine layout as F1/F2; different room names.
		# ═══════════════════════════════════════════════════════════════
		{"name":"F3_WStairLand",      "position":Vector3(-29,f3,-3.0), "size":Vector2( 8, 6), "sector_id":"f3_comms",   "open_sides":["east"],                       "floor_y":f3, "ceiling_y":f3+3.0},
		{"name":"F3_WSpine",          "position":Vector3(-18,f3,-3.0), "size":Vector2(14, 6), "sector_id":"f3_comms",   "open_sides":["west","east","north","south"], "floor_y":f3, "ceiling_y":f3+3.0},
		{"name":"F3_MidSpine",        "position":Vector3( -4,f3,-3.0), "size":Vector2(14, 6), "sector_id":"f3_command", "open_sides":["west","east","north","south"], "floor_y":f3, "ceiling_y":f3+3.0},
		{"name":"F3_ESpine",          "position":Vector3( 10,f3,-3.0), "size":Vector2(14, 6), "sector_id":"f3_reactor", "open_sides":["west","east","north","south"], "floor_y":f3, "ceiling_y":f3+3.0},
		{"name":"F3_ESpine2",         "position":Vector3( 25,f3,-3.0), "size":Vector2(16, 6), "sector_id":"f3_reactor", "open_sides":["west","east","north","south"], "floor_y":f3, "ceiling_y":f3+3.0},
		{"name":"F3_EStairLand",      "position":Vector3( 35,f3,-3.0), "size":Vector2( 4, 6), "sector_id":"f3_reactor", "open_sides":["west"],                       "floor_y":f3, "ceiling_y":f3+3.0},
		# --- F3 WSpine branches (comms) ---
		{"name":"F3_CommsCorr",       "position":Vector3(-18,f3,-9.0), "size":Vector2(10, 6), "sector_id":"f3_comms",   "open_sides":["south","north"],              "floor_y":f3, "ceiling_y":f3+3.0},
		{"name":"F3_Communications",  "position":Vector3(-18,f3,-16.0),"size":Vector2(12, 8), "sector_id":"f3_comms",   "open_sides":["south"],                      "floor_y":f3, "ceiling_y":f3+3.0},
		{"name":"F3_NavigationRoom",  "position":Vector3(-18,f3, 4.0), "size":Vector2(12, 8), "sector_id":"f3_comms",   "open_sides":["north"],                      "floor_y":f3, "ceiling_y":f3+3.0},
		# --- F3 MidSpine branches (command) ---
		{"name":"F3_CmdCorr",         "position":Vector3( -4,f3,-9.0), "size":Vector2(10, 6), "sector_id":"f3_command", "open_sides":["south","north"],              "floor_y":f3, "ceiling_y":f3+3.0},
		{"name":"F3_CommandBridge",   "position":Vector3( -4,f3,-16.0),"size":Vector2(14, 8), "sector_id":"f3_command", "open_sides":["south"],                      "floor_y":f3, "ceiling_y":f3+3.0},
		{"name":"F3_SecurityCtrl",    "position":Vector3( -4,f3, 4.0), "size":Vector2(12, 8), "sector_id":"f3_command", "open_sides":["north"],                      "floor_y":f3, "ceiling_y":f3+3.0},
		# --- F3 ESpine branches (reactor) ---
		{"name":"F3_ReactorCorr",     "position":Vector3( 10,f3,-9.0), "size":Vector2(10, 6), "sector_id":"f3_reactor", "open_sides":["south","north"],              "floor_y":f3, "ceiling_y":f3+3.0},
		{"name":"F3_ReactorControl",  "position":Vector3( 10,f3,-16.0),"size":Vector2(12, 8), "sector_id":"f3_reactor", "open_sides":["south"],                      "floor_y":f3, "ceiling_y":f3+3.0},
		{"name":"F3_CoolantMonitor",  "position":Vector3( 10,f3, 5.0), "size":Vector2(10,10), "sector_id":"f3_reactor", "open_sides":["north","south"],              "floor_y":f3, "ceiling_y":f3+3.0},
		{"name":"F3_EmergPowerCtrl",  "position":Vector3( 10,f3,13.0), "size":Vector2(10, 6), "sector_id":"f3_reactor", "open_sides":["north"],                      "floor_y":f3, "ceiling_y":f3+3.0},
		# --- F3 ESpine2 branches (reactor/command) ---
		{"name":"F3_EscapePodAccess", "position":Vector3( 25,f3,-9.0), "size":Vector2(10, 6), "sector_id":"f3_reactor", "open_sides":["south","north"],              "floor_y":f3, "ceiling_y":f3+3.0},
		{"name":"F3_ReactorCore",     "position":Vector3( 25,f3,-16.0),"size":Vector2(14, 8), "sector_id":"f3_reactor", "open_sides":["south"],                      "floor_y":f3, "ceiling_y":f3+3.0},
		{"name":"F3_BriefingRoom",    "position":Vector3( 25,f3, 4.0), "size":Vector2(12, 8), "sector_id":"f3_command", "open_sides":["north"],                      "floor_y":f3, "ceiling_y":f3+3.0},
	]

func _create_station_room_shell(spec: Dictionary) -> void:
	var room_name: String = String(spec.get("name", "Room"))
	var center: Vector3 = _dict_vector3(spec, "position", Vector3.ZERO)
	var room_size: Vector2 = _dict_vector2(spec, "size", Vector2(8.0, 8.0))
	var floor_y: float = float(spec.get("floor_y", center.y))
	var ceiling_y: float = float(spec.get("ceiling_y", floor_y + 3.0))
	var open_sides: Array = _dict_array(spec, "open_sides")
	var railing_sides: Array = _dict_array(spec, "railing_sides")
	var floor_color: Color = Color(0.08, 0.095, 0.105)
	if floor_y < -1.0:
		floor_color = Color(0.075, 0.082, 0.078)
	elif floor_y > 2.0:
		floor_color = Color(0.085, 0.095, 0.112)
	_create_box("%sFloorPlate" % room_name, Vector3(center.x, floor_y + 0.015, center.z), Vector3(room_size.x, 0.03, room_size.y), floor_color, false, "deck")
	_create_box("%sCeilingSlab" % room_name, Vector3(center.x, ceiling_y - 0.015, center.z), Vector3(room_size.x, 0.03, room_size.y), Color(0.062, 0.076, 0.084), true, "ceiling")
	var wall_height: float = ceiling_y - floor_y
	var wall_y: float = floor_y + wall_height * 0.5
	var door_w: float = 2.4
	var door_h: float = min(2.2, wall_height - 0.2)
	var lintel_h: float = wall_height - door_h
	# North/South walls span room_size.x; openings cut along X axis
	for side in ["north", "south"]:
		var wall_z: float = center.z - room_size.y * 0.5 if side == "north" else center.z + room_size.y * 0.5
		if not open_sides.has(side):
			_create_structural_wall("%s%sWall" % [room_name, side.capitalize()], Vector3(center.x, wall_y, wall_z), Vector3(room_size.x, wall_height, 0.28))
		else:
			var half_door: float = door_w * 0.5
			var left_w: float = (room_size.x * 0.5) - half_door
			var right_w: float = left_w
			if left_w > 0.1:
				_create_structural_wall("%s%sWallL" % [room_name, side.capitalize()], Vector3(center.x - half_door - left_w * 0.5, wall_y, wall_z), Vector3(left_w, wall_height, 0.28))
				_create_structural_wall("%s%sWallR" % [room_name, side.capitalize()], Vector3(center.x + half_door + right_w * 0.5, wall_y, wall_z), Vector3(right_w, wall_height, 0.28))
			if lintel_h > 0.05:
				_create_structural_wall("%s%sLintel" % [room_name, side.capitalize()], Vector3(center.x, floor_y + door_h + lintel_h * 0.5, wall_z), Vector3(door_w, lintel_h, 0.28))
	# West/East walls span room_size.y; openings cut along Z axis
	for side in ["west", "east"]:
		var wall_x: float = center.x - room_size.x * 0.5 if side == "west" else center.x + room_size.x * 0.5
		if not open_sides.has(side):
			_create_structural_wall("%s%sWall" % [room_name, side.capitalize()], Vector3(wall_x, wall_y, center.z), Vector3(0.28, wall_height, room_size.y))
		else:
			var half_door: float = door_w * 0.5
			var front_w: float = (room_size.y * 0.5) - half_door
			var back_w: float = front_w
			if front_w > 0.1:
				_create_structural_wall("%s%sWallF" % [room_name, side.capitalize()], Vector3(wall_x, wall_y, center.z - half_door - front_w * 0.5), Vector3(0.28, wall_height, front_w))
				_create_structural_wall("%s%sWallB" % [room_name, side.capitalize()], Vector3(wall_x, wall_y, center.z + half_door + back_w * 0.5), Vector3(0.28, wall_height, back_w))
			if lintel_h > 0.05:
				_create_structural_wall("%s%sLintel" % [room_name, side.capitalize()], Vector3(wall_x, floor_y + door_h + lintel_h * 0.5, center.z), Vector3(0.28, lintel_h, door_w))
	for side_value in railing_sides:
		_create_station_railing("%sRailing_%s" % [room_name, String(side_value)], center, room_size, floor_y, String(side_value))

func _dict_vector2(source: Dictionary, key: String, fallback: Vector2) -> Vector2:
	var raw_value: Variant = source.get(key, fallback)
	if raw_value is Vector2:
		return raw_value
	return fallback

func _dict_array(source: Dictionary, key: String) -> Array:
	var raw_value: Variant = source.get(key, [])
	if raw_value is Array:
		return raw_value
	return []

func _create_station_railing(rail_name: String, center: Vector3, size: Vector2, floor_y: float, side: String) -> void:
	var count: int = max(2, int(size.x / 1.2)) if side == "north" or side == "south" else max(2, int(size.y / 1.2))
	for index in range(count + 1):
		var ratio: float = float(index) / float(max(1, count))
		var x: float = lerp(center.x - size.x * 0.5, center.x + size.x * 0.5, ratio)
		var z: float = lerp(center.z - size.y * 0.5, center.z + size.y * 0.5, ratio)
		var post_position: Vector3 = Vector3(x, floor_y + 0.5, center.z + size.y * 0.5)
		if side == "north":
			post_position = Vector3(x, floor_y + 0.5, center.z - size.y * 0.5)
		elif side == "east":
			post_position = Vector3(center.x + size.x * 0.5, floor_y + 0.5, z)
		elif side == "west":
			post_position = Vector3(center.x - size.x * 0.5, floor_y + 0.5, z)
		_create_box("%sPost%d" % [rail_name, index], post_position, Vector3(0.08, 1.0, 0.08), Color(0.22, 0.42, 0.43), true, "railing")

func _build_station_vertical_connections() -> void:
	# West (-38) and East (+38) zigzag stairwells connecting F0→F1→F2→F3
	# Each flight: 4.2m rise over 8m horizontal run (≈27.6° slope)
	var floor_h := 4.2
	var run := 8.0
	var ramp_len := sqrt(run * run + floor_h * floor_h)  # ≈9.04
	var ramp_angle := atan2(floor_h, run)                # ≈0.483 rad
	var grate_col := Color(0.16, 0.18, 0.18)
	var wall_col := Color(0.08, 0.10, 0.11)

	for stair_side_raw in [-1, 1]:
		var stair_side: int = int(stair_side_raw)
		var sx: float = 35.0 if stair_side > 0 else -29.0
		var prefix: String = "WStair" if stair_side < 0 else "EStair"
		# Shaft outer walls (east/west faces, full height)
		_create_structural_wall("%sWallOuter" % prefix, Vector3(sx + stair_side * 2.1, floor_h * 1.5, 4.0), Vector3(0.28, floor_h * 3.0 + 2.0, 22.0))
		for flight in range(3):  # F0→F1, F1→F2, F2→F3
			var y_base: float = flight * floor_h
			# Zigzag: even flights go south (z increases), odd flights go north
			var go_south: bool = (flight % 2 == 0)
			var z_from: float = 2.0 if go_south else 10.0
			var z_to: float   = 10.0 if go_south else 2.0
			var cx: float     = sx
			var cy: float     = y_base + floor_h * 0.5
			var cz: float     = (z_from + z_to) * 0.5   # = 6.0
			var angle: float  = -ramp_angle if go_south else ramp_angle
			var ramp: Node3D = _create_box(
				"%sRamp%d" % [prefix, flight],
				Vector3(cx, cy, cz),
				Vector3(3.2, 0.22, ramp_len),
				grate_col, true, "grate"
			)
			if ramp:
				ramp.rotation.x = angle
			# North/south shaft walls flanking this flight
			var z_min: float = minf(z_from, z_to) - 0.15
			var z_max: float = maxf(z_from, z_to) + 0.15
			_create_structural_wall("%sShaftN%d" % [prefix, flight],
				Vector3(cx, cy, z_min), Vector3(4.2, floor_h + 1.0, 0.28))
			_create_structural_wall("%sShaftS%d" % [prefix, flight],
				Vector3(cx, cy, z_max), Vector3(4.2, floor_h + 1.0, 0.28))

	# Maintenance ladder shaft — near-vertical steep ramp at x=0, z=-31
	# Connects F0 airlock level to upper floors via narrow passage
	var ladder_col := Color(0.14, 0.18, 0.16)
	for ladder_flight in range(3):
		var y_base: float = ladder_flight * floor_h
		var lean_z: float = 0.6
		var ladder: Node3D = _create_box(
			"MaintLadder%d" % ladder_flight,
			Vector3(0.0, y_base + floor_h * 0.5, -31.0),
			Vector3(1.4, 0.14, sqrt(lean_z * lean_z + floor_h * floor_h)),
			ladder_col, true, "grate"
		)
		if ladder:
			ladder.rotation.x = -atan2(floor_h, lean_z)
		_create_structural_wall("LadderShaftW%d" % ladder_flight, Vector3(-0.9, y_base + floor_h * 0.5, -31.0), Vector3(0.18, floor_h + 0.4, 2.0))
		_create_structural_wall("LadderShaftE%d" % ladder_flight, Vector3( 0.9, y_base + floor_h * 0.5, -31.0), Vector3(0.18, floor_h + 0.4, 2.0))

	# Elevator shaft — decorative (teleport interaction added separately)
	_create_structural_wall("ElevShaftN", Vector3(0.0, floor_h * 1.5,  2.2), Vector3(3.0, floor_h * 3.0 + 2.0, 0.18))
	_create_structural_wall("ElevShaftS", Vector3(0.0, floor_h * 1.5, -2.2), Vector3(3.0, floor_h * 3.0 + 2.0, 0.18))
	_create_structural_wall("ElevShaftW", Vector3(-1.6, floor_h * 1.5, 0.0), Vector3(0.18, floor_h * 3.0 + 2.0, 4.6))
	_create_structural_wall("ElevShaftE", Vector3( 1.6, floor_h * 1.5, 0.0), Vector3(0.18, floor_h * 3.0 + 2.0, 4.6))

func _build_room_props() -> void:
	var f0 := 0.0
	var f1 := 4.2
	var f2 := 8.4
	var f3 := 12.6
	# Build each room's props at the correct floor height
	_build_props_f0_arrival(f0)
	_build_props_f0_cargo(f0)
	_build_props_f0_power(f0)
	_build_props_f1_quarters(f1)
	_build_props_f1_medical(f1)
	_build_props_f1_living(f1)
	_build_props_f2_labs(f2)
	_build_props_f3_command(f3)

func _place_prop(prop_name: String, position: Vector3, size: Vector3, color: Color, surface: String = "metal") -> void:
	_create_box(prop_name, position, size, color, true, surface)
	if _blocker_intersects_ground_nav(position, size):
		_register_nav_blocker(position, size)

func _build_props_f0_arrival(fy: float) -> void:
	var y := fy + 0.001
	# SecurityCheck — barriers, scanner arch, security desk
	_place_prop("SecBarrierA",     Vector3(-3.0, y+0.5, -23.5), Vector3(0.28, 1.0, 2.2), Color(0.28, 0.32, 0.34))
	_place_prop("SecBarrierB",     Vector3( 3.0, y+0.5, -23.5), Vector3(0.28, 1.0, 2.2), Color(0.28, 0.32, 0.34))
	_place_prop("SecScannerArch",  Vector3( 0.0, y+1.2, -23.5), Vector3(6.5, 0.22, 0.28), Color(0.22, 0.28, 0.30))
	_place_prop("SecDesk",         Vector3(-3.5, y+0.45, -19.5), Vector3(2.8, 0.9, 0.6), Color(0.16, 0.20, 0.22))
	_place_prop("SecMonitor",      Vector3(-3.5, y+1.05, -19.5), Vector3(0.62, 0.42, 0.06), Color(0.04, 0.08, 0.10), "ceiling")
	_place_prop("SecLockerRow",    Vector3( 4.2, y+0.85, -20.0), Vector3(0.5, 1.7, 3.2), Color(0.18, 0.22, 0.25))
	# ReceptionLobby — reception desk, seating, info kiosk
	_place_prop("RecDesk",         Vector3( 2.0, y+0.5, -12.5), Vector3(4.5, 1.0, 0.7), Color(0.22, 0.26, 0.28))
	_place_prop("RecDeskScreen",   Vector3( 0.5, y+1.18, -12.5), Vector3(1.1, 0.55, 0.06), Color(0.04, 0.08, 0.10))
	_place_prop("WaitingChairA",   Vector3(-5.5, y+0.35, -11.0), Vector3(0.6, 0.7, 0.6), Color(0.32, 0.28, 0.22))
	_place_prop("WaitingChairB",   Vector3(-5.5, y+0.35, -9.5),  Vector3(0.6, 0.7, 0.6), Color(0.32, 0.28, 0.22))
	_place_prop("WaitingChairC",   Vector3(-5.5, y+0.35, -8.0),  Vector3(0.6, 0.7, 0.6), Color(0.32, 0.28, 0.22))
	_place_prop("InfoKiosk",       Vector3( 5.8, y+0.7, -10.5), Vector3(0.55, 1.4, 0.55), Color(0.08, 0.12, 0.16))
	_place_prop("InfoKioskScreen", Vector3( 5.8, y+1.5, -10.5), Vector3(0.42, 0.55, 0.05), Color(0.04, 0.08, 0.12))
	_place_prop("LobbyPillarA",    Vector3(-2.0, y+1.5, -10.0), Vector3(0.35, 3.0, 0.35), Color(0.18, 0.22, 0.24))
	_place_prop("LobbyPillarB",    Vector3( 4.0, y+1.5, -10.0), Vector3(0.35, 3.0, 0.35), Color(0.18, 0.22, 0.24))

func _build_props_f0_cargo(fy: float) -> void:
	var y := fy + 0.001
	# CargoHub — stacked containers, pallet jack, shelving
	_place_prop("ContainerStackA",  Vector3(13.0, y+0.85, -1.0), Vector3(2.2, 1.7, 2.4), Color(0.28, 0.22, 0.14))
	_place_prop("ContainerStackB",  Vector3(13.0, y+0.85,  2.5), Vector3(2.2, 1.7, 2.4), Color(0.18, 0.26, 0.18))
	_place_prop("ContainerStackC",  Vector3(19.5, y+0.85, -6.5), Vector3(2.2, 1.7, 2.4), Color(0.24, 0.22, 0.16))
	_place_prop("ContainerTopA",    Vector3(13.0, y+2.55, -1.0), Vector3(2.2, 1.7, 2.4), Color(0.22, 0.18, 0.12))
	_place_prop("PalletJack",       Vector3(17.5, y+0.22, -0.5), Vector3(1.6, 0.44, 3.2), Color(0.42, 0.38, 0.08))
	_place_prop("CargoShelfA",      Vector3(14.5, y+0.95, -5.5), Vector3(0.28, 1.9, 3.8), Color(0.22, 0.24, 0.26))
	_place_prop("CargoShelfB",      Vector3(17.5, y+0.95, -5.5), Vector3(0.28, 1.9, 3.8), Color(0.22, 0.24, 0.26))
	_place_prop("CargoBoxRow1",     Vector3(16.0, y+0.35, -5.0), Vector3(2.8, 0.7, 0.8), Color(0.19, 0.18, 0.14))
	# ColdStorage — freezer banks, grate floor panels
	_place_prop("FreezerBankA",     Vector3(22.0, y+0.85,  3.5), Vector3(0.5, 1.7, 3.8), Color(0.62, 0.72, 0.78))
	_place_prop("FreezerBankB",     Vector3(28.0, y+0.85,  3.5), Vector3(0.5, 1.7, 3.8), Color(0.62, 0.72, 0.78))
	_place_prop("FreezerBankC",     Vector3(25.0, y+0.85,  8.5), Vector3(5.8, 1.7, 0.5), Color(0.62, 0.72, 0.78))
	_place_prop("ColdMonitor",      Vector3(25.0, y+1.05,  1.5), Vector3(0.7, 0.42, 0.08), Color(0.04, 0.08, 0.12))
	# MaintWorkshop — workbench, tool racks, oil drum
	_place_prop("WorkbenchA",       Vector3(-26.0, y+0.5, -4.5), Vector3(4.5, 1.0, 0.7), Color(0.32, 0.26, 0.18))
	_place_prop("WorkbenchB",       Vector3(-26.0, y+0.5, -0.5), Vector3(4.5, 1.0, 0.7), Color(0.32, 0.26, 0.18))
	_place_prop("ToolRackA",        Vector3(-32.0, y+0.9, -4.0), Vector3(0.28, 1.8, 3.2), Color(0.22, 0.24, 0.26))
	_place_prop("OilDrumA",         Vector3(-30.5, y+0.5, -1.5), Vector3(0.6, 1.0, 0.6), Color(0.22, 0.20, 0.12))
	_place_prop("OilDrumB",         Vector3(-29.5, y+0.5, -1.5), Vector3(0.6, 1.0, 0.6), Color(0.18, 0.18, 0.10))
	_place_prop("WeldingStation",   Vector3(-28.5, y+0.65, -3.5), Vector3(0.9, 1.3, 0.9), Color(0.28, 0.24, 0.16))

func _build_props_f0_power(fy: float) -> void:
	var y := fy + 0.001
	# PowerHub — main control consoles, status boards
	_place_prop("PowerConsoleN",    Vector3(-3.0, y+0.6, 11.5), Vector3(5.0, 1.2, 0.5), Color(0.06, 0.10, 0.12))
	_place_prop("PowerConsoleS",    Vector3( 3.0, y+0.6, 16.5), Vector3(5.0, 1.2, 0.5), Color(0.06, 0.10, 0.12))
	_place_prop("PowerScreenA",     Vector3(-2.0, y+1.4, 11.5), Vector3(1.2, 0.65, 0.06), Color(0.04, 0.22, 0.18))
	_place_prop("PowerScreenB",     Vector3( 1.5, y+1.4, 11.5), Vector3(1.2, 0.65, 0.06), Color(0.04, 0.22, 0.18))
	_place_prop("CentralTower",     Vector3( 0.0, y+0.9, 14.0), Vector3(1.0, 1.8, 1.0), Color(0.12, 0.16, 0.18))
	# GenRoom — large generators
	_place_prop("Generator1",       Vector3(-14.0, y+0.8, 18.5), Vector3(2.8, 1.6, 2.2), Color(0.28, 0.26, 0.18))
	_place_prop("Generator2",       Vector3(-9.0,  y+0.8, 18.5), Vector3(2.8, 1.6, 2.2), Color(0.24, 0.24, 0.16))
	_place_prop("GenExhaustPipeA",  Vector3(-14.0, y+2.5, 18.5), Vector3(0.5, 1.9, 0.5), Color(0.32, 0.28, 0.20))
	_place_prop("GenExhaustPipeB",  Vector3(-9.0,  y+2.5, 18.5), Vector3(0.5, 1.9, 0.5), Color(0.32, 0.28, 0.20))
	_place_prop("GenFuelTankA",     Vector3(-13.0, y+0.55, 24.0), Vector3(1.2, 1.1, 1.2), Color(0.18, 0.16, 0.10))
	_place_prop("GenFuelTankB",     Vector3(-10.0, y+0.55, 24.0), Vector3(1.2, 1.1, 1.2), Color(0.18, 0.16, 0.10))
	# BatteryBackup — battery racks
	_place_prop("BattRackN",        Vector3(-2.0, y+0.9, 18.0), Vector3(6.0, 1.8, 0.38), Color(0.14, 0.18, 0.22))
	_place_prop("BattRackS",        Vector3( 2.0, y+0.9, 24.0), Vector3(6.0, 1.8, 0.38), Color(0.14, 0.18, 0.22))

func _build_props_f1_quarters(fy: float) -> void:
	var y := fy + 0.001
	# BunkRoom — bunk bed frames, lockers, small tables
	for bunk_i in range(3):
		var bx := -22.0 + float(bunk_i) * 4.5
		_place_prop("BunkFrameA%d" % bunk_i, Vector3(bx, y+0.6, -18.5), Vector3(0.9, 1.2, 2.0), Color(0.16, 0.20, 0.22))
		_place_prop("BunkMattA%d" % bunk_i,  Vector3(bx, y+1.2, -18.5), Vector3(0.85, 0.12, 1.95), Color(0.52, 0.46, 0.38))
		_place_prop("BunkFrameB%d" % bunk_i, Vector3(bx, y+0.6, -13.5), Vector3(0.9, 1.2, 2.0), Color(0.16, 0.20, 0.22))
		_place_prop("BunkMattB%d" % bunk_i,  Vector3(bx, y+1.2, -13.5), Vector3(0.85, 0.12, 1.95), Color(0.48, 0.42, 0.35))
	_place_prop("BunkLockerRow",    Vector3(-13.5, y+0.9, -19.5), Vector3(0.42, 1.8, 4.2), Color(0.22, 0.26, 0.28))
	_place_prop("BunkPersonalItemA",Vector3(-20.5, y+1.35, -18.5), Vector3(0.22, 0.18, 0.28), Color(0.55, 0.42, 0.28))
	_place_prop("BunkPersonalItemB",Vector3(-16.0, y+1.35, -13.5), Vector3(0.18, 0.14, 0.22), Color(0.38, 0.32, 0.25))

func _build_props_f1_medical(fy: float) -> void:
	var y := fy + 0.001
	# MedBay — examination beds, cabinets, lighting fixture bar
	_place_prop("MedBedA",          Vector3(-7.5, y+0.45, -18.5), Vector3(0.9, 0.9, 2.2), Color(0.78, 0.82, 0.82))
	_place_prop("MedBedB",          Vector3(-3.5, y+0.45, -18.5), Vector3(0.9, 0.9, 2.2), Color(0.78, 0.82, 0.82))
	_place_prop("MedBedC",          Vector3( 0.5, y+0.45, -18.5), Vector3(0.9, 0.9, 2.2), Color(0.78, 0.82, 0.82))
	_place_prop("MedCabinetRowA",   Vector3(-7.5, y+0.85, -13.5), Vector3(5.5, 1.7, 0.38), Color(0.22, 0.34, 0.36))
	_place_prop("MedIVPoleA",       Vector3(-6.5, y+1.0, -18.5), Vector3(0.06, 2.0, 0.06), Color(0.72, 0.75, 0.75))
	_place_prop("MedIVPoleB",       Vector3(-2.5, y+1.0, -18.5), Vector3(0.06, 2.0, 0.06), Color(0.72, 0.75, 0.75))
	_place_prop("MedSinkUnit",      Vector3( 1.2, y+0.55, -13.5), Vector3(1.5, 1.1, 0.45), Color(0.68, 0.72, 0.72))
	_place_prop("MedTrayCart",      Vector3(-4.5, y+0.55, -15.5), Vector3(0.55, 1.1, 1.0), Color(0.52, 0.56, 0.56))
	# Pharmacy
	_place_prop("PharmShelfA",      Vector3( 7.0, y+0.95, -11.5), Vector3(0.28, 1.9, 4.2), Color(0.22, 0.32, 0.34))
	_place_prop("PharmShelfB",      Vector3(13.0, y+0.95, -11.5), Vector3(0.28, 1.9, 4.2), Color(0.22, 0.32, 0.34))
	_place_prop("PharmCounter",     Vector3(10.0, y+0.55, -12.0), Vector3(5.0, 1.1, 0.55), Color(0.62, 0.66, 0.66))
	# Surgery
	_place_prop("OpTable",          Vector3(25.0, y+0.52, -11.5), Vector3(0.9, 1.04, 2.4), Color(0.72, 0.75, 0.72))
	_place_prop("SurgLight",        Vector3(25.0, y+2.85, -11.5), Vector3(0.9, 0.15, 0.9), Color(0.82, 0.88, 0.88))
	_place_prop("SurgCart",         Vector3(27.5, y+0.5, -11.5), Vector3(0.55, 1.0, 0.75), Color(0.52, 0.56, 0.56))
	# Morgue
	_place_prop("MorgueSlabA",      Vector3(22.0, y+0.55, -17.5), Vector3(0.7, 1.1, 2.2), Color(0.28, 0.32, 0.34))
	_place_prop("MorgueSlabB",      Vector3(25.0, y+0.55, -17.5), Vector3(0.7, 1.1, 2.2), Color(0.28, 0.32, 0.34))
	_place_prop("MorgueSlabC",      Vector3(28.0, y+0.55, -17.5), Vector3(0.7, 1.1, 2.2), Color(0.28, 0.32, 0.34))
	_place_prop("MorgueDrawerBank", Vector3(21.5, y+0.9, -13.5), Vector3(0.38, 1.8, 5.5), Color(0.22, 0.26, 0.28))

func _build_props_f1_living(fy: float) -> void:
	var y := fy + 0.001
	# MessHall — long dining tables, food service counter
	for row_i in range(3):
		_place_prop("DiningTable%d" % row_i, Vector3(-21.5 + float(row_i) * 4.8, y+0.44, 4.5), Vector3(1.4, 0.88, 3.5), Color(0.28, 0.24, 0.18))
	_place_prop("FoodCounter",      Vector3(-13.5, y+0.55, 6.5), Vector3(0.5, 1.1, 4.2), Color(0.32, 0.28, 0.22))
	_place_prop("CoffeeMachine",    Vector3(-13.5, y+1.18, 4.5), Vector3(0.38, 0.55, 0.38), Color(0.12, 0.14, 0.16))
	_place_prop("FridgeUnit",       Vector3(-13.5, y+0.85, 2.5), Vector3(0.55, 1.7, 0.62), Color(0.55, 0.58, 0.60))
	# RecRoom — recreational tables, display screen
	_place_prop("RecTableA",        Vector3(-6.0, y+0.44, 4.5), Vector3(1.6, 0.88, 3.0), Color(0.22, 0.24, 0.28))
	_place_prop("RecTableB",        Vector3(-1.5, y+0.44, 4.5), Vector3(1.6, 0.88, 3.0), Color(0.22, 0.24, 0.28))
	_place_prop("RecScreenWall",    Vector3(-4.0, y+1.5, 7.5), Vector3(4.5, 1.8, 0.08), Color(0.06, 0.08, 0.10))
	_place_prop("RecCouch",         Vector3(-4.0, y+0.35, 6.2), Vector3(3.5, 0.7, 0.9), Color(0.36, 0.30, 0.24))
	# Gym
	_place_prop("GymBenchA",        Vector3( 7.5, y+0.35, 2.5), Vector3(0.45, 0.7, 1.6), Color(0.22, 0.22, 0.20))
	_place_prop("GymBenchB",        Vector3(12.5, y+0.35, 2.5), Vector3(0.45, 0.7, 1.6), Color(0.22, 0.22, 0.20))
	_place_prop("GymRackA",         Vector3( 7.5, y+0.9, 8.5), Vector3(3.2, 1.8, 0.38), Color(0.24, 0.26, 0.28))
	_place_prop("GymRackB",         Vector3(13.5, y+0.9, 8.5), Vector3(3.2, 1.8, 0.38), Color(0.24, 0.26, 0.28))
	_place_prop("GymMachineA",      Vector3(10.0, y+0.7, 4.5), Vector3(1.2, 1.4, 1.2), Color(0.18, 0.20, 0.22))
	# FoodStorage — crate stacks, shelves
	_place_prop("FoodShelfA",       Vector3(22.0, y+0.95, 2.0), Vector3(0.28, 1.9, 4.5), Color(0.26, 0.22, 0.16))
	_place_prop("FoodShelfB",       Vector3(28.0, y+0.95, 2.0), Vector3(0.28, 1.9, 4.5), Color(0.26, 0.22, 0.16))
	_place_prop("FoodCrateStack",   Vector3(25.0, y+0.9, 6.5), Vector3(3.5, 1.8, 2.2), Color(0.28, 0.24, 0.16))

func _build_props_f2_labs(fy: float) -> void:
	var y := fy + 0.001
	# WetLab — lab benches, specimen tanks, fume hood
	_place_prop("WetLabBenchA",     Vector3(-21.5, y+0.55, -18.0), Vector3(5.0, 1.1, 0.7), Color(0.52, 0.56, 0.56))
	_place_prop("WetLabBenchB",     Vector3(-21.5, y+0.55, -13.5), Vector3(5.0, 1.1, 0.7), Color(0.52, 0.56, 0.56))
	_place_prop("SpecimenTankA",    Vector3(-20.5, y+0.75, -16.5), Vector3(0.55, 1.5, 0.55), Color(0.28, 0.52, 0.58))
	_place_prop("SpecimenTankB",    Vector3(-19.0, y+0.75, -16.5), Vector3(0.55, 1.5, 0.55), Color(0.32, 0.48, 0.52))
	_place_prop("FumeHood",         Vector3(-15.5, y+0.85, -18.5), Vector3(1.8, 1.7, 0.6), Color(0.62, 0.66, 0.66))
	_place_prop("CentrifugeUnit",   Vector3(-14.5, y+0.6, -15.5), Vector3(0.72, 1.2, 0.72), Color(0.48, 0.52, 0.54))
	# ContainmentA — containment cells with heavy frames
	_place_prop("ContainCellA",     Vector3(-22.0, y+1.0, 2.5), Vector3(3.5, 2.0, 3.0), Color(0.16, 0.18, 0.20))
	_place_prop("ContainCellB",     Vector3(-15.0, y+1.0, 6.5), Vector3(3.5, 2.0, 3.0), Color(0.16, 0.18, 0.20))
	_place_prop("ContainGlassA",    Vector3(-22.0, y+1.8, 2.5), Vector3(3.2, 0.06, 2.8), Color(0.28, 0.52, 0.58))
	_place_prop("ContainMonitor",   Vector3(-18.5, y+0.65, 7.5), Vector3(0.62, 1.3, 0.52), Color(0.08, 0.12, 0.14))
	# SampleFreezer — tall freezer units
	_place_prop("SFreezerA",        Vector3(-7.0, y+0.95, -18.5), Vector3(0.55, 1.9, 4.5), Color(0.55, 0.62, 0.70))
	_place_prop("SFreezerB",        Vector3(-1.0, y+0.95, -18.5), Vector3(0.55, 1.9, 4.5), Color(0.55, 0.62, 0.70))
	_place_prop("SFreezerCtrl",     Vector3(-4.0, y+0.65, -13.5), Vector3(3.5, 1.3, 0.48), Color(0.08, 0.12, 0.14))
	# RoboticsBay — robotic arm frames
	_place_prop("RoboFrameA",       Vector3( 7.5, y+1.2, 3.5), Vector3(0.9, 2.4, 0.9), Color(0.26, 0.28, 0.30))
	_place_prop("RoboArmA",         Vector3( 8.8, y+2.0, 3.5), Vector3(2.5, 0.22, 0.22), Color(0.28, 0.30, 0.32))
	_place_prop("RoboFrameB",       Vector3(12.5, y+1.2, 8.5), Vector3(0.9, 2.4, 0.9), Color(0.26, 0.28, 0.30))
	_place_prop("RoboArmB",         Vector3(13.8, y+2.0, 8.5), Vector3(2.5, 0.22, 0.22), Color(0.28, 0.30, 0.32))
	_place_prop("RoboPlatformA",    Vector3(10.0, y+0.18, 6.0), Vector3(4.5, 0.36, 4.5), Color(0.22, 0.24, 0.26))
	# ServerAnalysis — server racks
	_place_prop("ServerRackA",      Vector3(22.5, y+0.95, -18.5), Vector3(0.55, 1.9, 4.5), Color(0.12, 0.14, 0.16))
	_place_prop("ServerRackB",      Vector3(24.5, y+0.95, -18.5), Vector3(0.55, 1.9, 4.5), Color(0.12, 0.14, 0.16))
	_place_prop("ServerRackC",      Vector3(27.5, y+0.95, -18.5), Vector3(0.55, 1.9, 4.5), Color(0.12, 0.14, 0.16))
	_place_prop("ServerConsole",    Vector3(25.0, y+0.65, -13.5), Vector3(4.5, 1.3, 0.48), Color(0.06, 0.10, 0.12))

func _build_props_f3_command(fy: float) -> void:
	var y := fy + 0.001
	# CommandBridge — curved console array, captain's chair, overview screens
	_place_prop("CmdConsoleArc",    Vector3(-4.0, y+0.6, -18.5), Vector3(10.0, 1.2, 0.6), Color(0.06, 0.10, 0.14))
	_place_prop("CmdScreenL",       Vector3(-8.0, y+1.5, -18.5), Vector3(2.8, 1.4, 0.06), Color(0.04, 0.14, 0.18))
	_place_prop("CmdScreenC",       Vector3(-4.0, y+1.5, -18.5), Vector3(3.2, 1.4, 0.06), Color(0.04, 0.14, 0.18))
	_place_prop("CmdScreenR",       Vector3( 0.2, y+1.5, -18.5), Vector3(2.8, 1.4, 0.06), Color(0.04, 0.14, 0.18))
	_place_prop("CaptainChair",     Vector3(-4.0, y+0.52, -15.5), Vector3(0.8, 1.04, 0.8), Color(0.12, 0.14, 0.18))
	_place_prop("CmdPillarL",       Vector3(-9.5, y+1.5, -16.0), Vector3(0.35, 3.0, 0.35), Color(0.16, 0.20, 0.24))
	_place_prop("CmdPillarR",       Vector3( 1.5, y+1.5, -16.0), Vector3(0.35, 3.0, 0.35), Color(0.16, 0.20, 0.24))
	# SecurityCtrl — security stations
	_place_prop("SecCtrlBankA",     Vector3(-7.5, y+0.6,  5.5), Vector3(5.5, 1.2, 0.52), Color(0.08, 0.12, 0.14))
	_place_prop("SecCtrlBankB",     Vector3(-0.5, y+0.6,  5.5), Vector3(5.5, 1.2, 0.52), Color(0.08, 0.12, 0.14))
	_place_prop("SecCtrlScreenA",   Vector3(-7.0, y+1.4,  5.5), Vector3(1.2, 0.65, 0.06), Color(0.04, 0.16, 0.12))
	_place_prop("SecCtrlScreenB",   Vector3(-4.0, y+1.4,  5.5), Vector3(1.2, 0.65, 0.06), Color(0.04, 0.16, 0.12))
	# Communications room
	_place_prop("CommsArrayA",      Vector3(-21.5, y+0.7, -18.5), Vector3(5.5, 1.4, 0.55), Color(0.06, 0.10, 0.14))
	_place_prop("CommsParabolicA",  Vector3(-16.5, y+1.5, -17.5), Vector3(1.5, 1.5, 0.14), Color(0.32, 0.36, 0.38))
	_place_prop("CommsTransceiver", Vector3(-18.0, y+0.7, -14.5), Vector3(0.62, 1.4, 0.62), Color(0.18, 0.22, 0.24))
	_place_prop("CommsHeadsetRow",  Vector3(-20.0, y+1.18, -18.5), Vector3(3.2, 0.22, 0.28), Color(0.24, 0.28, 0.32))
	# ReactorControl
	_place_prop("ReactorConsole",   Vector3(10.0, y+0.6, -18.5), Vector3(8.0, 1.2, 0.55), Color(0.06, 0.10, 0.14))
	_place_prop("ReactorScreenA",   Vector3( 7.0, y+1.5, -18.5), Vector3(2.5, 1.4, 0.06), Color(0.12, 0.22, 0.08))
	_place_prop("ReactorScreenB",   Vector3(10.0, y+1.5, -18.5), Vector3(2.5, 1.4, 0.06), Color(0.12, 0.22, 0.08))
	_place_prop("ReactorScreenC",   Vector3(13.0, y+1.5, -18.5), Vector3(2.5, 1.4, 0.06), Color(0.08, 0.18, 0.06))
	_place_prop("SafetyOverride",   Vector3(15.0, y+0.7, -15.5), Vector3(0.55, 1.4, 0.55), Color(0.68, 0.14, 0.08))
	# ReactorCore — massive reactor housing
	_place_prop("ReactorHousing",   Vector3(25.0, y+1.5, -17.5), Vector3(6.5, 3.0, 5.0), Color(0.22, 0.28, 0.24))
	_place_prop("ReactorGlowCore",  Vector3(25.0, y+1.5, -17.5), Vector3(2.2, 2.2, 2.2), Color(0.18, 0.88, 0.52))
	_place_prop("ReactorPipeL",     Vector3(19.0, y+1.5, -17.5), Vector3(0.5, 3.0, 0.5), Color(0.36, 0.32, 0.22))
	_place_prop("ReactorPipeR",     Vector3(31.0, y+1.5, -17.5), Vector3(0.5, 3.0, 0.5), Color(0.36, 0.32, 0.22))
	_place_prop("ReactorCoolantA",  Vector3(20.0, y+0.65, -13.5), Vector3(1.8, 1.3, 1.8), Color(0.22, 0.48, 0.62))
	_place_prop("ReactorCoolantB",  Vector3(30.0, y+0.65, -13.5), Vector3(1.8, 1.3, 1.8), Color(0.22, 0.48, 0.62))
	# Add a reactor OmniLight for that eerie green glow
	_create_reactor_glow(Vector3(25.0, fy + 1.5, -17.5))

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
	for spec in _get_station_room_specs():
		var room_position: Vector3 = _dict_vector3(spec, "position", Vector3.ZERO)
		var floor_y: float = float(spec.get("floor_y", room_position.y))
		var ceiling_y: float = float(spec.get("ceiling_y", floor_y + 3.0))
		var room_sector: String = String(spec.get("sector_id", "arena"))
		_create_sector_ceiling_light(room_sector, "%sLightFixture" % String(spec.get("name", "Room")), Vector3(room_position.x, ceiling_y - 0.28, room_position.z), 7.5)
	for sector in _get_mission_sector_definitions():
		var sector_id_for_emergency: String = String(sector.get("sector_id", "arena"))
		var sector_position: Vector3 = _dict_vector3(sector, "position", Vector3.ZERO)
		var emergency_y: float = sector_position.y + 2.75
		if sector_position.y > 2.0:
			emergency_y = 6.25
		elif sector_position.y < -1.0:
			emergency_y = -1.25
		_create_emergency_strip_light(sector_id_for_emergency, Vector3(sector_position.x, emergency_y, sector_position.z))
	if sector_power:
		sector_power.register_sector("arena", "Prototype Combat Arena", true)
		_apply_sector_light_state("arena", true, "initial_power")
	return
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
	# Breakable shell — thin StaticBody3D around the bulb so bullets can shatter it
	var shell := StaticBody3D.new()
	shell.name = fixture_name + "Shell"
	shell.collision_layer = 1
	shell.collision_mask = 0
	var cs := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.28
	cs.shape = sphere
	shell.add_child(cs)
	shell.set_meta("breakable_light", true)
	shell.set_meta("light_node", light)
	shell.position = world_position
	arena_root.add_child(shell)
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
	if survivor_count == 0 and facility_state.rooms.has("entry_airlock"):
		var entry_room: Dictionary = facility_state.rooms["entry_airlock"]
		entry = {
			"room_id": "entry_airlock",
			"entry_position": entry_room.get("entry_position", Vector3(0.0, 0.05, -44.0)),
			"explored": entry_room.get("explored", false),
			"visits": entry_room.get("visits", 0)
		}
	if entry.is_empty():
		entry = {
			"room_id": "entry_airlock",
			"entry_position": Vector3(0, 0.05, -33.0),
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
	if run_modifier_system:
		run_modifier_system.set_player(player)
	# Wire audio occlusion raycast to this player
	if has_node("/root/AudioRouter"):
		get_node("/root/AudioRouter").set_player_ref(player)
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
	if mission_deployed and selected_role != "custom":
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
	entry_definitions.append(_make_entry_definition("entry_airlock", "entry_k17_airlock", "airlock", "K-17 entry airlock", "door", Vector3(0, 0.05, -33.0), Vector3(0, 1.1, -36.1), Vector3(3.6, 2.2, 0.28), Color(0.13, 0.18, 0.24), true, 0, "door_entry_airlock"))
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

func _build_run_modifier_system() -> void:
	run_modifier_system = RunModifierSystem.new()
	run_modifier_system.name = "RunModifierSystem"
	add_child(run_modifier_system)
	run_modifier_system.setup(player, sector_power, threat_director, arena_root)

func _build_mission_briefing() -> void:
	briefing_screen = MissionBriefingScreen.new()
	briefing_screen.name = "MissionBriefingScreen"
	briefing_screen.configure(objective_system.get_objective_snapshot(), _get_role_definitions(), selected_role)
	briefing_screen.deploy_pressed.connect(_on_briefing_deploy_pressed)
	add_child(briefing_screen)

func _on_briefing_deploy_pressed(weapon_id: String, equipment_id: String, passive_id: String) -> void:
	selected_role = "custom"
	mission_deployed = true
	if player:
		var loadout: Dictionary = player.survivor_loadout.duplicate(true)
		_apply_equipment_loadout(loadout, weapon_id, equipment_id, passive_id)
		player.apply_survivor_loadout(loadout)
	if briefing_screen and is_instance_valid(briefing_screen):
		briefing_screen.queue_free()
		briefing_screen = null
	if objective_system:
		objective_system.start_run()
	if run_modifier_system:
		run_modifier_system.start_run()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	GameEvents.reset_run()

func _apply_equipment_loadout(loadout: Dictionary, weapon_id: String, equipment_id: String, passive_id: String) -> void:
	loadout["weapon_id"] = weapon_id
	loadout["role"] = "custom"
	loadout.erase("reload_speed_mult")
	loadout.erase("can_revive_corpses")
	loadout.erase("movement_penalty_mult")
	loadout.erase("damage_resist")
	loadout.erase("noise_mult")
	loadout.erase("treatment_speed")
	var resources: Dictionary = {}
	var raw_resources: Variant = loadout.get("resources", {})
	if raw_resources is Dictionary:
		resources = raw_resources.duplicate(true)
	match equipment_id:
		"trauma_kit":
			resources["trauma_kit"] = int(resources.get("trauma_kit", 0)) + 2
		"stim_injector":
			resources["injector"] = int(resources.get("injector", 0)) + 2
		"ammo_cache":
			loadout["extra_ammo"] = int(loadout.get("extra_ammo", 0)) + 90
		"med_spray":
			resources["med_spray"] = int(resources.get("med_spray", 0)) + 3
	match passive_id:
		"heavy_armor":
			loadout["movement_penalty_mult"] = 0.82
			loadout["damage_resist"] = 0.25
		"stealth_liner":
			loadout["noise_mult"] = 0.45
		"medic_rig":
			loadout["treatment_speed"] = 2.2
		"ammo_harness":
			loadout["extra_ammo"] = int(loadout.get("extra_ammo", 0)) + 60
	loadout["resources"] = resources

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
		{"sector_id": "f0_arrival",    "label": "Arrival/Security",   "position": Vector3(  0.0,  0.05, -21.0)},
		{"sector_id": "f0_cargo",      "label": "Cargo Bay",           "position": Vector3( 22.0,  0.05,  -3.0)},
		{"sector_id": "f0_utilities",  "label": "Utilities",           "position": Vector3(-22.0,  0.05,  -3.0)},
		{"sector_id": "f0_power",      "label": "Power Systems",       "position": Vector3(-13.0,  0.05,  16.0)},
		{"sector_id": "f1_quarters",   "label": "Crew Quarters",       "position": Vector3(  0.0,  4.25, -13.0)},
		{"sector_id": "f1_medical",    "label": "Medical Bay",         "position": Vector3( 22.0,  4.25,  -6.0)},
		{"sector_id": "f1_living",     "label": "Living Quarters",     "position": Vector3(-22.0,  4.25,  -3.0)},
		{"sector_id": "f2_labs",       "label": "Research Labs",       "position": Vector3(  0.0,  8.45, -14.0)},
		{"sector_id": "f2_containment","label": "Containment",         "position": Vector3(  0.0,  8.45,   4.0)},
		{"sector_id": "f2_research",   "label": "R&D Wing",            "position": Vector3( 22.0,  8.45,  -6.0)},
		{"sector_id": "f3_command",    "label": "Command Bridge",      "position": Vector3(  0.0, 12.65, -15.0)},
		{"sector_id": "f3_comms",      "label": "Communications",      "position": Vector3(-22.0, 12.65,  -6.0)},
		{"sector_id": "f3_reactor",    "label": "Reactor Control",     "position": Vector3( 22.0, 12.65,  -6.0)},
	]

func _build_interior_partitions() -> void:
	_build_mission_doors()
	_build_navigation_region()
	return
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
		{"door_id": "door_medical_wing", "sector_id": "medical_wing", "name": "MissionDoorMedicalWing", "position": Vector3(-16.0, 1.22, -20.0), "size": Vector3(0.3, 2.45, 1.0), "glow_offset": Vector3(0.02, 0.0, 0.0), "glow_size": Vector3(0.04, 2.6, 1.15), "color": Color(0.14, 0.22, 0.25)},
		{"door_id": "door_armory", "sector_id": "armory", "name": "MissionDoorArmory", "position": Vector3(19.0, 1.22, -22.0), "size": Vector3(0.3, 2.45, 1.0), "glow_offset": Vector3(-0.02, 0.0, 0.0), "glow_size": Vector3(0.04, 2.6, 1.15), "color": Color(0.2, 0.14, 0.11)},
		{"door_id": "door_lab_alpha", "sector_id": "lab_alpha", "name": "MissionDoorLabAlpha", "position": Vector3(-16.0, 1.22, -2.0), "size": Vector3(0.3, 2.45, 1.0), "glow_offset": Vector3(0.02, 0.0, 0.0), "glow_size": Vector3(0.04, 2.6, 1.15), "color": Color(0.1, 0.22, 0.24)},
		{"door_id": "door_engineering", "sector_id": "engineering", "name": "MissionDoorEngineering", "position": Vector3(18.0, 1.22, 10.0), "size": Vector3(0.3, 2.45, 1.0), "glow_offset": Vector3(-0.02, 0.0, 0.0), "glow_size": Vector3(0.04, 2.6, 1.15), "color": Color(0.2, 0.18, 0.12)},
		{"door_id": "door_command", "sector_id": "command", "name": "MissionDoorCommand", "position": Vector3(20.55, 4.82, -14.0), "size": Vector3(0.3, 2.45, 1.0), "glow_offset": Vector3(-0.02, 0.0, 0.0), "glow_size": Vector3(0.04, 2.6, 1.15), "color": Color(0.12, 0.2, 0.25)},
		{"door_id": "door_archives", "sector_id": "archives", "name": "MissionDoorArchives", "position": Vector3(-8.5, 4.82, -20.0), "size": Vector3(0.3, 2.45, 1.0), "glow_offset": Vector3(0.02, 0.0, 0.0), "glow_size": Vector3(0.04, 2.6, 1.15), "color": Color(0.14, 0.18, 0.24)}
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
		{"name": "SwarmerVentNorthSpine", "position": Vector3(-1.9, 1.2, -28.0), "size": Vector3(0.12, 0.54, 0.72)},
		{"name": "SwarmerVentMedical", "position": Vector3(-16.2, 1.2, -20.0), "size": Vector3(0.12, 0.54, 0.72)},
		{"name": "SwarmerVentArmory", "position": Vector3(17.8, 1.2, -22.0), "size": Vector3(0.12, 0.54, 0.72)},
		{"name": "SwarmerVentLab", "position": Vector3(-16.2, 1.2, -2.0), "size": Vector3(0.12, 0.54, 0.72)},
		{"name": "SwarmerVentEngineeringSub", "position": Vector3(-2.0, -2.8, 15.8), "size": Vector3(0.72, 0.54, 0.12)},
		{"name": "SwarmerVentCommandUpper", "position": Vector3(2.0, 4.8, -15.2), "size": Vector3(0.72, 0.54, 0.12)}
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

func _create_reactor_glow(world_position: Vector3) -> void:
	var glow_node := OmniLight3D.new()
	glow_node.name = "ReactorGlowLight"
	glow_node.position = world_position
	glow_node.light_color = Color(0.14, 0.92, 0.48)
	glow_node.light_energy = 2.8
	glow_node.omni_range = 14.0
	glow_node.shadow_enabled = false
	arena_root.add_child(glow_node)

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
	_trigger_extraction_alarm()

func _trigger_extraction_alarm() -> void:
	# Looping danger alarm audio
	var alarm_stream: AudioStream = SoundSynthesizer.get_stream("danger_alarm")
	if alarm_stream and alarm_stream is AudioStreamWAV:
		var wav := alarm_stream as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = max(0, int(wav.data.size() / 2) - 1)
	if alarm_stream:
		_alarm_loop_player = AudioStreamPlayer.new()
		_alarm_loop_player.stream = alarm_stream
		_alarm_loop_player.volume_db = -6.0
		add_child(_alarm_loop_player)
		_alarm_loop_player.play()
	# Flood all emergency lights
	for sector_id in emergency_lights_by_sector.keys():
		var raw: Variant = emergency_lights_by_sector[sector_id]
		if not raw is Array:
			continue
		for light_node in (raw as Array):
			if light_node is OmniLight3D and is_instance_valid(light_node):
				var lt: OmniLight3D = light_node as OmniLight3D
				var tween := lt.create_tween()
				tween.tween_property(lt, "light_energy", 1.8, 0.4)
	# Dim normal sector lights to create oppressive red-lit atmosphere
	for sector_id in sector_lights.keys():
		var raw: Variant = sector_lights[sector_id]
		if not raw is Array:
			continue
		for light_node in (raw as Array):
			if light_node is OmniLight3D and is_instance_valid(light_node):
				var lt: OmniLight3D = light_node as OmniLight3D
				var tween := lt.create_tween()
				tween.tween_property(lt, "light_energy", lt.light_energy * 0.28, 1.2)
	# Shift sector light colors to threat red
	for sector_id in sector_lights.keys():
		var raw2: Variant = sector_lights[sector_id]
		if not raw2 is Array:
			continue
		for light_node in (raw2 as Array):
			if light_node is OmniLight3D and is_instance_valid(light_node):
				var lt: OmniLight3D = light_node as OmniLight3D
				var tween := lt.create_tween()
				tween.tween_property(lt, "light_color", Color(1.0, 0.06, 0.03), 1.4)\
					.set_trans(Tween.TRANS_SINE)
	# Emergency lights strobe like rotating alarm beacons
	for sector_id in emergency_lights_by_sector.keys():
		var raw3: Variant = emergency_lights_by_sector[sector_id]
		if not raw3 is Array:
			continue
		for light_node in (raw3 as Array):
			if not (light_node is OmniLight3D) or not is_instance_valid(light_node):
				continue
			var lt: OmniLight3D = light_node as OmniLight3D
			lt.light_color = Color(1.0, 0.04, 0.02)
			var tw := lt.create_tween()
			tw.set_loops()
			var spd := randf_range(0.14, 0.26)
			tw.tween_property(lt, "light_energy", 0.2, spd).set_trans(Tween.TRANS_SINE)
			tw.tween_property(lt, "light_energy", 2.6, spd).set_trans(Tween.TRANS_SINE)
	# Escalate threat if possible
	if threat_director and threat_director.has_method("escalate_threat"):
		threat_director.escalate_threat(0.8)

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
	if _alarm_loop_player and is_instance_valid(_alarm_loop_player):
		_alarm_loop_player.stop()
		_alarm_loop_player.queue_free()
		_alarm_loop_player = null
	if player:
		player.show_end_state(success, reason)

# ──────────────────────────────────────────────────────────────────────────────
#  OUTER HULL — sealed tight-fit shell that touches all room walls
# ──────────────────────────────────────────────────────────────────────────────
# Station footprint (derived from room specs):
#   X: -33.2 → +37.2   (70.4 m wide)
#   Z: -36.2 → +25.2   (61.4 m deep)
#   F0 north extension (airlock module): z -36.2 → -20.2, full F0 height only
#   Main body (all 4 floors):           z -20.2 → +25.2, y -0.3 → +15.9

func _build_outer_hull() -> void:
	var hc := Color(0.13, 0.15, 0.17)   # hull panel grey
	var rc := Color(0.09, 0.10, 0.11)   # darker recessed color
	# Ground plate — replaces old oversized Floor box
	_create_box("StationGround", Vector3(2.0, -0.1, -5.5), Vector3(70.6, 0.2, 61.6),
		Color(0.082, 0.092, 0.100), true, "deck")
	# ── F0 north extension (airlock module) ─────────────────────────────────
	# y: -0.3 to 4.2, z: -36.2 to -20.2
	_create_hull_wall_ns("HullNorthAirlock", -36.2, -33.2, 37.2, -0.3, 4.2, hc,
		[{"x_center": -1.1, "width": 1.1, "height": 0.85, "y_center": 2.55},
		 {"x_center":  1.1, "width": 1.1, "height": 0.85, "y_center": 2.55}])
	_create_hull_wall_ew("HullWestAirlock", -33.2, -36.2, -20.2, -0.3, 4.2, hc, [])
	_create_hull_wall_ew("HullEastAirlock",  37.2, -36.2, -20.2, -0.3, 4.2, hc, [])
	# Flat step-roof where F0 north extension meets F1-F3 body
	_create_box("HullExtRoof", Vector3(2.0, 4.32, -28.2), Vector3(70.6, 0.24, 16.0),
		rc, true, "ceiling")
	# ── Main body (all 4 floors) ─────────────────────────────────────────────
	# y: -0.3 to 15.9, z: -20.2 to +25.2
	# North wall — F3 command/comms windows (visible from inside command rooms)
	_create_hull_wall_ns("HullNorthMain", -20.2, -33.2, 37.2, -0.3, 15.9, hc,
		[{"x_center": -19.0, "width": 4.5, "height": 2.4, "y_center": 14.2},
		 {"x_center":  -5.5, "width": 4.5, "height": 2.4, "y_center": 14.2},
		 {"x_center":   9.0, "width": 4.5, "height": 2.4, "y_center": 14.2},
		 {"x_center":  24.0, "width": 4.5, "height": 2.4, "y_center": 14.2}])
	# South wall — plain (cargo/gen side)
	_create_hull_wall_ns("HullSouth",   25.2, -33.2, 37.2, -0.3, 15.9, hc, [])
	# West wall — maintenance viewport at F1 level
	_create_hull_wall_ew("HullWestMain", -33.2, -20.2, 25.2, -0.3, 15.9, hc,
		[{"z_center": -8.5, "width": 3.0, "height": 2.0, "y_center": 5.6}])
	# East wall — reactor viewport at F1 level
	_create_hull_wall_ew("HullEastMain",  37.2, -20.2, 25.2, -0.3, 15.9, hc,
		[{"z_center": -8.5, "width": 3.0, "height": 2.0, "y_center": 5.6}])
	# Station main roof
	_create_box("HullMainRoof", Vector3(2.0, 16.05, 2.5), Vector3(70.6, 0.3, 45.6),
		rc, true, "ceiling")
	# Structural ribbing on outer hull — thin horizontal bands for panel-line look
	var hull_rib_color := Color(0.10, 0.12, 0.135)
	for floor_y in [4.22, 8.44, 12.66]:
		_create_box("RibN%d" % int(floor_y), Vector3(2.0, floor_y, -20.2),
			Vector3(70.6, 0.18, 0.42), hull_rib_color, false, "")
		_create_box("RibS%d" % int(floor_y), Vector3(2.0, floor_y, 25.2),
			Vector3(70.6, 0.18, 0.42), hull_rib_color, false, "")
		_create_box("RibW%d" % int(floor_y), Vector3(-33.2, floor_y, 2.5),
			Vector3(0.42, 0.18, 45.6), hull_rib_color, false, "")
		_create_box("RibE%d" % int(floor_y), Vector3(37.2, floor_y, 2.5),
			Vector3(0.42, 0.18, 45.6), hull_rib_color, false, "")
	# Vertical corner pillars for structural realism
	var pillar_color := Color(0.18, 0.20, 0.22)
	var corner_xs := [-33.2, 37.2]
	var corner_zs := [-36.2, -20.2, 25.2]
	var pi_idx := 0
	for px in corner_xs:
		for pz in corner_zs:
			var ph := 4.2 if pz == -36.2 or pz == -20.2 else 16.2
			var pcy := ph * 0.5 - 0.3
			_create_box("Pillar%d" % pi_idx, Vector3(px, pcy, pz),
				Vector3(0.55, ph, 0.55), pillar_color, false, "")
			pi_idx += 1

# Creates a north/south facing hull wall (constant Z) with optional window cutouts.
# windows: Array of {x_center, width, height, y_center} dicts — all at same y_center.
func _create_hull_wall_ns(wall_name: String, wall_z: float, x_min: float, x_max: float,
		y_min: float, y_max: float, color: Color, windows: Array[Dictionary]) -> void:
	var full_w := x_max - x_min
	var full_h := y_max - y_min
	var cx := (x_min + x_max) * 0.5
	var cy := (y_min + y_max) * 0.5
	if windows.is_empty():
		_create_box(wall_name, Vector3(cx, cy, wall_z), Vector3(full_w, full_h, 0.38), color, true, "bulkhead")
		return
	var win_y_c := float(windows[0]["y_center"])
	var win_h := float(windows[0]["height"])
	var band_bot := win_y_c - win_h * 0.5
	var band_top := win_y_c + win_h * 0.5
	# Lower solid slab
	if band_bot > y_min + 0.05:
		var h := band_bot - y_min
		_create_box(wall_name + "_Lo", Vector3(cx, y_min + h * 0.5, wall_z),
			Vector3(full_w, h, 0.38), color, true, "bulkhead")
	# Upper solid slab
	if band_top < y_max - 0.05:
		var h := y_max - band_top
		_create_box(wall_name + "_Hi", Vector3(cx, band_top + h * 0.5, wall_z),
			Vector3(full_w, h, 0.38), color, true, "bulkhead")
	# Window band — solid segments between cutouts
	var sorted_wins := windows.duplicate()
	sorted_wins.sort_custom(func(a, b): return float(a["x_center"]) < float(b["x_center"]))
	var band_h := band_top - band_bot
	var band_cy := (band_bot + band_top) * 0.5
	var prev_x := x_min
	for i in range(sorted_wins.size()):
		var win: Dictionary = sorted_wins[i]
		var wx := float(win["x_center"])
		var ww := float(win["width"])
		var left_edge := wx - ww * 0.5
		var right_edge := wx + ww * 0.5
		if left_edge - prev_x > 0.05:
			var sw := left_edge - prev_x
			_create_box(wall_name + "_B%d" % i, Vector3(prev_x + sw * 0.5, band_cy, wall_z),
				Vector3(sw, band_h, 0.38), color, true, "bulkhead")
		_create_window_panel(wall_name + "_W%d" % i, Vector3(wx, band_cy, wall_z),
			Vector2(ww, band_h), true)
		prev_x = right_edge
	if x_max - prev_x > 0.05:
		var sw := x_max - prev_x
		_create_box(wall_name + "_BE", Vector3(prev_x + sw * 0.5, band_cy, wall_z),
			Vector3(sw, band_h, 0.38), color, true, "bulkhead")

# Creates an east/west facing hull wall (constant X) with optional window cutouts.
# windows: Array of {z_center, width, height, y_center} dicts.
func _create_hull_wall_ew(wall_name: String, wall_x: float, z_min: float, z_max: float,
		y_min: float, y_max: float, color: Color, windows: Array[Dictionary]) -> void:
	var full_d := z_max - z_min
	var full_h := y_max - y_min
	var cz := (z_min + z_max) * 0.5
	var cy := (y_min + y_max) * 0.5
	if windows.is_empty():
		_create_box(wall_name, Vector3(wall_x, cy, cz), Vector3(0.38, full_h, full_d), color, true, "bulkhead")
		return
	var win_y_c := float(windows[0]["y_center"])
	var win_h := float(windows[0]["height"])
	var band_bot := win_y_c - win_h * 0.5
	var band_top := win_y_c + win_h * 0.5
	if band_bot > y_min + 0.05:
		var h := band_bot - y_min
		_create_box(wall_name + "_Lo", Vector3(wall_x, y_min + h * 0.5, cz),
			Vector3(0.38, h, full_d), color, true, "bulkhead")
	if band_top < y_max - 0.05:
		var h := y_max - band_top
		_create_box(wall_name + "_Hi", Vector3(wall_x, band_top + h * 0.5, cz),
			Vector3(0.38, h, full_d), color, true, "bulkhead")
	var sorted_wins := windows.duplicate()
	sorted_wins.sort_custom(func(a, b): return float(a["z_center"]) < float(b["z_center"]))
	var band_h := band_top - band_bot
	var band_cy := (band_bot + band_top) * 0.5
	var prev_z := z_min
	for i in range(sorted_wins.size()):
		var win: Dictionary = sorted_wins[i]
		var wz := float(win["z_center"])
		var ww := float(win["width"])
		var left_edge := wz - ww * 0.5
		var right_edge := wz + ww * 0.5
		if left_edge - prev_z > 0.05:
			var sd := left_edge - prev_z
			_create_box(wall_name + "_B%d" % i, Vector3(wall_x, band_cy, prev_z + sd * 0.5),
				Vector3(0.38, band_h, sd), color, true, "bulkhead")
		_create_window_panel(wall_name + "_W%d" % i, Vector3(wall_x, band_cy, wz),
			Vector2(ww, band_h), false)
		prev_z = right_edge
	if z_max - prev_z > 0.05:
		var sd := z_max - prev_z
		_create_box(wall_name + "_BE", Vector3(wall_x, band_cy, prev_z + sd * 0.5),
			Vector3(0.38, band_h, sd), color, true, "bulkhead")

# Places a framed transparent window panel at the given center position.
# is_ns = true means the panel faces Z (north/south wall), false means X (east/west).
func _create_window_panel(win_name: String, center: Vector3, size: Vector2, is_ns: bool) -> void:
	var fc := Color(0.24, 0.28, 0.31)  # frame metal
	var ft := 0.13                      # frame thickness
	var fd := 0.38                      # frame depth (matches wall depth)
	# Top / bottom frames
	var top_s := Vector3(size.x + ft * 2.0, ft, fd) if is_ns else Vector3(fd, ft, size.x + ft * 2.0)
	_create_box(win_name + "FT", center + Vector3(0, size.y * 0.5 + ft * 0.5, 0), top_s, fc, true, "bulkhead")
	_create_box(win_name + "FB", center + Vector3(0, -(size.y * 0.5 + ft * 0.5), 0), top_s, fc, true, "bulkhead")
	# Left / right frames
	var side_s := Vector3(ft, size.y, fd) if is_ns else Vector3(fd, size.y, ft)
	var off_x := (size.x * 0.5 + ft * 0.5) if is_ns else 0.0
	var off_z := 0.0 if is_ns else (size.x * 0.5 + ft * 0.5)
	_create_box(win_name + "FL", center + Vector3(-off_x, 0, -off_z), side_s, fc, true, "bulkhead")
	_create_box(win_name + "FR", center + Vector3( off_x, 0,  off_z), side_s, fc, true, "bulkhead")
	# Transparent glass
	var glass := MeshInstance3D.new()
	glass.name = win_name + "Glass"
	var bm := BoxMesh.new()
	bm.size = Vector3(size.x, size.y, 0.05) if is_ns else Vector3(0.05, size.y, size.x)
	glass.mesh = bm
	glass.position = center
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.48, 0.78, 0.90, 0.06)
	mat.roughness = 0.04
	mat.metallic = 0.0
	mat.emission_enabled = true
	mat.emission = Color(0.32, 0.62, 0.85)
	mat.emission_energy_multiplier = 0.10
	glass.material_override = mat
	arena_root.add_child(glass)

# ──────────────────────────────────────────────────────────────────────────────
#  MARS EXTERIOR — terrain, rocks, craters, distant mesa
# ──────────────────────────────────────────────────────────────────────────────

func _build_exterior() -> void:
	# Vast Mars surface (low-poly, extends 600 m in every direction)
	_create_exterior_box("MarsSurface", Vector3(2.0, -0.92, -5.5), Vector3(650.0, 0.5, 650.0),
		Color(0.36, 0.17, 0.09))
	# Darker dust patches around the station foundation
	for i in range(8):
		var angle := i * TAU / 8.0
		var dist := randf_range(48.0, 80.0)
		var px := 2.0 + cos(angle) * dist
		var pz := -5.5 + sin(angle) * dist
		var pw := randf_range(14.0, 26.0)
		_create_exterior_box("DustPatch%d" % i, Vector3(px, -0.7, pz),
			Vector3(pw, 0.18, pw * 0.75), Color(0.26, 0.11, 0.06))
	# Mid-distance rocks (60–200 m out)
	var mid_rocks: Array[Dictionary] = [
		{"p": Vector3(-78.0, 1.8, -92.0), "s": Vector3(14.0, 4.8, 9.0)},
		{"p": Vector3( 94.0, 2.4, -82.0), "s": Vector3( 9.0, 6.2, 11.0)},
		{"p": Vector3(-98.0, 1.4, 52.0),  "s": Vector3(16.0, 3.8, 7.5)},
		{"p": Vector3(112.0, 1.9, 72.0),  "s": Vector3( 8.5, 5.0, 10.0)},
		{"p": Vector3(-122.0, 2.8, -22.0),"s": Vector3(11.5, 7.0, 9.0)},
		{"p": Vector3(132.0, 1.4, 13.0),  "s": Vector3(15.0, 3.8, 8.5)},
		{"p": Vector3(-68.0, 3.2, 112.0), "s": Vector3(10.5, 7.5, 12.0)},
		{"p": Vector3( 78.0, 1.9, -132.0),"s": Vector3(12.5, 4.8, 9.0)},
		{"p": Vector3(-142.0, 2.0, -88.0),"s": Vector3( 7.5, 5.0, 9.5)},
		{"p": Vector3(152.0, 2.6, -52.0), "s": Vector3( 9.5, 6.0, 13.5)},
		{"p": Vector3(-58.0, 1.7, -158.0),"s": Vector3(13.5, 3.8, 8.5)},
		{"p": Vector3( 68.0, 2.0, 152.0), "s": Vector3(11.5, 4.8, 7.5)},
		{"p": Vector3(-168.0, 1.4, 28.0), "s": Vector3( 8.5, 3.8, 10.0)},
		{"p": Vector3(178.0, 1.9, -28.0), "s": Vector3(10.5, 5.0, 8.5)},
		{"p": Vector3(  0.0, 2.0, -82.0), "s": Vector3( 9.0, 4.5, 7.5)},
		{"p": Vector3( 45.0, 1.5, 88.0),  "s": Vector3( 7.5, 3.2, 9.0)},
	]
	for i in range(mid_rocks.size()):
		var rp: Vector3 = mid_rocks[i]["p"]
		var rs: Vector3 = mid_rocks[i]["s"]
		var shade := sin(float(i) * 1.618) * 0.04
		_create_exterior_box("MidRock%d" % i, rp, rs, Color(0.30 + shade, 0.13 + shade * 0.6, 0.08))
	# Near rocks (45–70 m) — visible from windows
	var near_rocks: Array[Dictionary] = [
		{"p": Vector3(-52.0, 0.8, -52.0), "s": Vector3(5.0, 2.2, 4.0)},
		{"p": Vector3( 63.0, 0.7, -46.0), "s": Vector3(6.0, 1.8, 5.0)},
		{"p": Vector3(-60.0, 0.9, 36.0),  "s": Vector3(4.5, 2.4, 6.0)},
		{"p": Vector3( 70.0, 0.8, 30.0),  "s": Vector3(7.0, 2.0, 4.5)},
		{"p": Vector3(-50.0, 1.0, -72.0), "s": Vector3(4.0, 2.8, 5.0)},
		{"p": Vector3( 56.0, 0.9, 60.0),  "s": Vector3(5.5, 1.7, 4.5)},
		{"p": Vector3(-76.0, 0.8, 10.0),  "s": Vector3(6.0, 2.2, 5.5)},
		{"p": Vector3( 86.0, 0.9, -10.0), "s": Vector3(5.5, 2.4, 6.0)},
		{"p": Vector3(  2.0, 1.2, -62.0), "s": Vector3(7.0, 2.7, 5.5)},
		{"p": Vector3(  2.0, 0.9, 48.0),  "s": Vector3(6.5, 1.9, 7.0)},
	]
	for i in range(near_rocks.size()):
		var rp: Vector3 = near_rocks[i]["p"]
		var rs: Vector3 = near_rocks[i]["s"]
		_create_exterior_box("NearRock%d" % i, rp, rs, Color(0.34, 0.15, 0.08))
	# Distant ridges on the horizon (150–300 m out)
	var ridges: Array[Dictionary] = [
		{"p": Vector3(-85.0,  6.0, -255.0), "s": Vector3(185.0, 14.0, 58.0)},
		{"p": Vector3(125.0,  9.0, -275.0), "s": Vector3(145.0, 20.0, 52.0)},
		{"p": Vector3(-225.0, 13.0,  -78.0),"s": Vector3( 42.0, 30.0, 115.0)},
		{"p": Vector3( 262.0, 10.0,  -58.0),"s": Vector3( 38.0, 22.0, 135.0)},
		{"p": Vector3( -85.0,  8.0,  222.0),"s": Vector3(205.0, 17.0, 48.0)},
		{"p": Vector3( 142.0,  5.5,  242.0),"s": Vector3(165.0, 13.0, 42.0)},
		{"p": Vector3(-282.0,  6.5,   82.0),"s": Vector3( 32.0, 15.0, 165.0)},
		{"p": Vector3( 292.0,  9.0,   42.0),"s": Vector3( 36.0, 20.0, 145.0)},
	]
	for i in range(ridges.size()):
		var rp: Vector3 = ridges[i]["p"]
		var rs: Vector3 = ridges[i]["s"]
		var dark := float(i) * 0.008
		_create_exterior_box("Ridge%d" % i, rp, rs, Color(0.26 - dark, 0.11 - dark * 0.5, 0.06))
	# Crater depressions — flat dark cylinders
	var craters: Array[Dictionary] = [
		{"p": Vector3(-162.0, -0.84, -142.0), "r": 28.0},
		{"p": Vector3( 188.0, -0.84,  102.0), "r": 22.0},
		{"p": Vector3(-108.0, -0.84,  165.0), "r": 18.0},
		{"p": Vector3( 150.0, -0.84, -188.0), "r": 32.0},
		{"p": Vector3(-208.0, -0.84,   48.0), "r": 25.0},
		{"p": Vector3(  98.0, -0.84, -212.0), "r": 20.0},
	]
	for i in range(craters.size()):
		var cpos: Vector3 = craters[i]["p"]
		var crad: float = craters[i]["r"]
		var cyl := MeshInstance3D.new()
		cyl.name = "Crater%d" % i
		var cmesh := CylinderMesh.new()
		cmesh.top_radius = crad
		cmesh.bottom_radius = crad * 0.72
		cmesh.height = 0.48
		cmesh.radial_segments = 18
		cyl.mesh = cmesh
		var cmat := StandardMaterial3D.new()
		cmat.albedo_color = Color(0.15, 0.065, 0.032)
		cmat.roughness = 1.0
		cyl.material_override = cmat
		cyl.position = cpos
		arena_root.add_child(cyl)
	# Dramatic mesa landmark — visible from north-facing windows
	_create_exterior_box("MesaA",    Vector3(-305.0, 36.0, -198.0), Vector3(82.0, 76.0, 62.0), Color(0.30, 0.13, 0.07))
	_create_exterior_box("MesaATop", Vector3(-305.0, 76.5, -198.0), Vector3(58.0,  9.0, 46.0), Color(0.22, 0.09, 0.05))
	_create_exterior_box("MesaB",    Vector3( 325.0, 19.0, -182.0), Vector3(52.0, 42.0, 68.0), Color(0.27, 0.11, 0.06))
	_create_exterior_box("MesaBTop", Vector3( 325.0, 41.5, -182.0), Vector3(38.0,  6.0, 52.0), Color(0.20, 0.08, 0.04))

# ──────────────────────────────────────────────────────────────────────────────
#  WALL DETAIL PASS — panel-line strips, trims, ceiling lights, emissive screens
# ──────────────────────────────────────────────────────────────────────────────

func _build_wall_detail_pass() -> void:
	var trim_c := Color(0.20, 0.23, 0.26)
	var base_c := Color(0.08, 0.10, 0.12)
	var ceil_c := Color(0.75, 0.96, 1.00)
	for spec in _get_station_room_specs():
		var pos: Vector3 = spec["position"]
		var sz: Vector2 = spec["size"]
		var cx := pos.x;  var fy := pos.y;  var cz := pos.z
		var sx := sz.x;   var sd := sz.y   # sd = depth (z extent)
		var rn: String = spec["name"]
		# Floor baseboard — dark metallic border at floor level
		_add_detail_strip(rn+"BN", Vector3(cx, fy+0.06, cz-sd*0.5+0.04), Vector3(sx-0.06, 0.12, 0.06), base_c)
		_add_detail_strip(rn+"BS", Vector3(cx, fy+0.06, cz+sd*0.5-0.04), Vector3(sx-0.06, 0.12, 0.06), base_c)
		_add_detail_strip(rn+"BW", Vector3(cx-sx*0.5+0.04, fy+0.06, cz), Vector3(0.06, 0.12, sd-0.06), base_c)
		_add_detail_strip(rn+"BE", Vector3(cx+sx*0.5-0.04, fy+0.06, cz), Vector3(0.06, 0.12, sd-0.06), base_c)
		# Ceiling cornice — lighter trim at top of walls
		_add_detail_strip(rn+"CN", Vector3(cx, fy+2.90, cz-sd*0.5+0.04), Vector3(sx-0.06, 0.09, 0.06), trim_c)
		_add_detail_strip(rn+"CS", Vector3(cx, fy+2.90, cz+sd*0.5-0.04), Vector3(sx-0.06, 0.09, 0.06), trim_c)
		_add_detail_strip(rn+"CW", Vector3(cx-sx*0.5+0.04, fy+2.90, cz), Vector3(0.06, 0.09, sd-0.06), trim_c)
		_add_detail_strip(rn+"CE", Vector3(cx+sx*0.5-0.04, fy+2.90, cz), Vector3(0.06, 0.09, sd-0.06), trim_c)
		# Panel division line at chair-rail height (1.35 m)
		_add_detail_strip(rn+"PN", Vector3(cx, fy+1.35, cz-sd*0.5+0.02), Vector3(sx, 0.05, 0.04), trim_c.lightened(0.1))
		_add_detail_strip(rn+"PS", Vector3(cx, fy+1.35, cz+sd*0.5-0.02), Vector3(sx, 0.05, 0.04), trim_c.lightened(0.1))
		_add_detail_strip(rn+"PW", Vector3(cx-sx*0.5+0.02, fy+1.35, cz), Vector3(0.04, 0.05, sd), trim_c.lightened(0.1))
		_add_detail_strip(rn+"PE", Vector3(cx+sx*0.5-0.02, fy+1.35, cz), Vector3(0.04, 0.05, sd), trim_c.lightened(0.1))
		# Ceiling fluorescent strip running along longer axis
		var is_wide := sx >= sd
		var strip_l := (sx - 0.6) if is_wide else (sd - 0.6)
		var strip_s := Vector3(strip_l, 0.06, 0.14) if is_wide else Vector3(0.14, 0.06, strip_l)
		_add_emissive_strip(rn+"CL", Vector3(cx, fy+2.96, cz), strip_s, ceil_c, 1.15)
	# Key room emissive screen panels (placed 0.12 m off the wall face)
	# F3 north-face command windows — screens inside the rooms facing the window
	_add_screen_panel("ScrComm",  Vector3(-19.0, 13.85, -19.7), Vector2(3.2, 1.7), false, Color(0.12, 0.88, 0.62))
	_add_screen_panel("ScrCmd",   Vector3( -4.5, 13.85, -19.7), Vector2(3.2, 1.7), false, Color(0.12, 0.62, 0.98))
	_add_screen_panel("ScrReact", Vector3(  9.5, 13.85, -19.7), Vector2(3.2, 1.7), false, Color(0.98, 0.52, 0.12))
	_add_screen_panel("ScrRCore", Vector3( 24.0, 13.85, -19.7), Vector2(3.2, 1.7), false, Color(0.98, 0.22, 0.12))
	# F1 MedBay terminal and Security Check monitor
	_add_screen_panel("ScrMed",   Vector3( -4.0,  5.20, -19.7), Vector2(2.6, 1.3), false, Color(0.22, 0.96, 0.62))
	_add_screen_panel("ScrSec",   Vector3(  0.0,  1.40, -25.0), Vector2(2.2, 1.1), false, Color(0.95, 0.82, 0.12))

func _add_detail_strip(strip_name: String, pos: Vector3, size: Vector3, color: Color) -> void:
	var mi := MeshInstance3D.new()
	mi.name = strip_name
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.52
	mat.metallic = 0.55
	mi.material_override = mat
	mi.position = pos
	arena_root.add_child(mi)

func _add_emissive_strip(strip_name: String, pos: Vector3, size: Vector3, color: Color, energy: float) -> void:
	var mi := MeshInstance3D.new()
	mi.name = strip_name
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color.darkened(0.55)
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = energy
	mat.roughness = 1.0
	mi.material_override = mat
	mi.position = pos
	arena_root.add_child(mi)

func _add_screen_panel(panel_name: String, pos: Vector3, size: Vector2, is_ew: bool, color: Color) -> void:
	# Bezel frame
	var bezel := MeshInstance3D.new()
	bezel.name = panel_name + "Bez"
	var bbm := BoxMesh.new()
	bbm.size = Vector3(size.x + 0.12, size.y + 0.12, 0.05) if not is_ew else Vector3(0.05, size.y + 0.12, size.x + 0.12)
	bezel.mesh = bbm
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(0.055, 0.065, 0.075)
	bmat.roughness = 0.28
	bmat.metallic = 0.82
	bezel.material_override = bmat
	bezel.position = pos
	arena_root.add_child(bezel)
	# Emissive screen surface
	var screen := MeshInstance3D.new()
	screen.name = panel_name + "Scr"
	var sm := BoxMesh.new()
	sm.size = Vector3(size.x, size.y, 0.03) if not is_ew else Vector3(0.03, size.y, size.x)
	screen.mesh = sm
	var smat := StandardMaterial3D.new()
	smat.albedo_color = color.darkened(0.65)
	smat.emission_enabled = true
	smat.emission = color
	smat.emission_energy_multiplier = 0.60
	smat.roughness = 1.0
	screen.material_override = smat
	screen.position = pos + (Vector3(0, 0, 0.03) if not is_ew else Vector3(0.03, 0, 0))
	arena_root.add_child(screen)

# Lightweight exterior mesh — no collision needed for distant scenery.
func _create_exterior_box(box_name: String, world_position: Vector3, size: Vector3, color: Color) -> void:
	var mi := MeshInstance3D.new()
	mi.name = box_name
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.92
	mat.metallic = 0.0
	mi.material_override = mat
	mi.position = world_position
	arena_root.add_child(mi)

# ────────────────────────────────────────────────────────────────
# STEAM VENTS — atmospheric pipe-joint particle emitters
# ────────────────────────────────────────────────────────────────
func _build_steam_vents() -> void:
	var positions: Array[Vector3] = [
		Vector3(-8.0, 2.5, -4.0),
		Vector3(8.0, 2.5, -4.0),
		Vector3(0.0, 2.5, -18.0),
		Vector3(-12.0, 0.5, 8.0),
		Vector3(12.0, 0.5, 8.0),
		Vector3(-6.0, 2.5, 20.0),
		Vector3(6.0, 2.5, 20.0),
		Vector3(0.0, 5.5, -8.0),
		Vector3(-4.0, 0.5, 12.0),
		Vector3(4.0, 0.5, 12.0),
		Vector3(-10.0, 2.5, -12.0),
		Vector3(10.0, 2.5, -12.0),
	]
	for i in range(positions.size()):
		var pos := positions[i]
		# Small pipe stub visible marker
		var stub := MeshInstance3D.new()
		stub.name = "SteamPipeStub%d" % i
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.055
		cyl.bottom_radius = 0.055
		cyl.height = 0.18
		stub.mesh = cyl
		var smat := StandardMaterial3D.new()
		smat.albedo_color = Color(0.28, 0.30, 0.32)
		smat.metallic = 0.7
		smat.roughness = 0.4
		stub.material_override = smat
		stub.position = pos
		arena_root.add_child(stub)
		# Steam particle emitter
		var particles := GPUParticles3D.new()
		particles.name = "SteamVent%d" % i
		var pm := ParticleProcessMaterial.new()
		pm.direction = Vector3(0.0, 1.0, 0.0)
		pm.spread = 18.0
		pm.initial_velocity_min = 0.8
		pm.initial_velocity_max = 2.2
		pm.gravity = Vector3(0.0, 0.2, 0.0)
		pm.color = Color(0.85, 0.90, 0.95, 0.35)
		pm.scale_min = 0.08
		pm.scale_max = 0.18
		particles.process_material = pm
		var quad := QuadMesh.new()
		quad.size = Vector2(0.14, 0.14)
		particles.draw_pass_1 = quad
		particles.amount = 12
		particles.lifetime = 1.8
		particles.explosiveness = 0.0
		particles.one_shot = false
		particles.position = pos + Vector3(0.0, 0.12, 0.0)
		arena_root.add_child(particles)
		particles.emitting = true
		# Wet zone Area3D — footsteps use footstep_wet nearby
		var wet_area := Area3D.new()
		wet_area.name = "WetZone%d" % i
		wet_area.collision_layer = 0
		wet_area.collision_mask = 1  # detect player body
		var wa_cs := CollisionShape3D.new()
		var wa_box := BoxShape3D.new()
		wa_box.size = Vector3(3.0, 2.0, 3.0)
		wa_cs.shape = wa_box
		wet_area.add_child(wa_cs)
		wet_area.position = pos
		wet_area.add_to_group("wet_zone")
		arena_root.add_child(wet_area)

# ────────────────────────────────────────────────────────────────
# REVERB ZONES — per-room acoustic profile via Area3D
# ────────────────────────────────────────────────────────────────
func _build_reverb_zones() -> void:
	# [center, half_extents, room_size, damping, wet]
	var zones: Array[Dictionary] = [
		{"center": Vector3(0.0, 2.0, 14.0),   "ext": Vector3(10.0, 4.0, 8.0),  "rs": 0.92, "dam": 0.35, "wet": 0.52},  # Cargo
		{"center": Vector3(12.0, 2.0, 0.0),   "ext": Vector3(6.0, 3.0, 6.0),   "rs": 0.65, "dam": 0.55, "wet": 0.35},  # Control
		{"center": Vector3(-12.0, 2.0, -8.0), "ext": Vector3(6.0, 3.0, 5.0),   "rs": 0.28, "dam": 0.88, "wet": 0.12},  # Med bay
		{"center": Vector3(8.0, 2.0, -10.0),  "ext": Vector3(7.0, 3.0, 6.0),   "rs": 0.78, "dam": 0.42, "wet": 0.44},  # Industrial
		{"center": Vector3(-8.0, 2.0, -10.0), "ext": Vector3(5.0, 3.0, 5.0),   "rs": 0.18, "dam": 0.95, "wet": 0.08},  # Hab
		{"center": Vector3(0.0, 2.0, -4.0),   "ext": Vector3(7.0, 3.0, 6.0),   "rs": 0.48, "dam": 0.68, "wet": 0.25},  # Hub
		{"center": Vector3(0.0, 2.0, 22.0),   "ext": Vector3(5.0, 3.0, 7.0),   "rs": 0.82, "dam": 0.30, "wet": 0.48},  # Maintenance
	]
	for zd in zones:
		var area := Area3D.new()
		area.name = "ReverbZone_%s" % str(zd["center"])
		area.collision_layer = 0
		area.collision_mask = 1  # detect player (layer 1)
		var cs := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(zd["ext"]) * 2.0
		cs.shape = box
		area.add_child(cs)
		area.position = Vector3(zd["center"])
		area.monitorable = false
		arena_root.add_child(area)
		var rs: float = float(zd["rs"])
		var dam: float = float(zd["dam"])
		var wet: float = float(zd["wet"])
		area.body_entered.connect(func(body: Node3D) -> void:
			if body is PlayerControllerFPS:
				AudioRouter.set_room_reverb(rs, dam, wet)
		)
		area.body_exited.connect(func(body: Node3D) -> void:
			if body is PlayerControllerFPS:
				AudioRouter.set_room_reverb(0.3, 0.8, 0.0)
		)

func _spawn_death_memorials() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://death_records.cfg") != OK:
		return
	var raw: Variant = cfg.get_value("deaths", "positions", [])
	if not raw is Array:
		return
	for record in (raw as Array):
		if not record is Dictionary:
			continue
		var pos := Vector3(
			float((record as Dictionary).get("x", 0.0)),
			float((record as Dictionary).get("y", 0.0)),
			float((record as Dictionary).get("z", 0.0))
		)
		var mesh_inst := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.55
		cyl.bottom_radius = 0.55
		cyl.height = 0.003
		cyl.radial_segments = 24
		mesh_inst.mesh = cyl
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.25, 0.01, 0.01)
		mat.roughness = 0.95
		mat.metallic = 0.0
		mat.emission_enabled = true
		mat.emission = Color(0.15, 0.005, 0.005)
		mat.emission_energy_multiplier = 0.22
		mesh_inst.material_override = mat
		mesh_inst.global_position = pos + Vector3.UP * 0.04
		arena_root.add_child(mesh_inst)
