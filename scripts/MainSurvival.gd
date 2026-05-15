extends Node3D

var player: PlayerControllerFPS
var facility_state: FacilityProgression
var dynamic_world: DynamicWorldSystem
var route_system: StationRouteSystem
var sector_power: SectorPowerSystem
var threat_director: ThreatDirector
var enemy_container: Node3D
var arena_root: Node3D
var navigation_region: NavigationRegion3D
var nav_blockers: Array[Dictionary] = []
var sector_lights: Dictionary = {}
var spawn_points: Array[Node3D] = []
var entry_definitions: Array = []
var entry_doors: Dictionary = {}
var entry_nodes: Dictionary = {}
var floor_route_area: Area3D
var floor_route_mesh: MeshInstance3D
var floor_route_active: bool = false
var run_finished: bool = false
var survivor_count: int = 0
var current_room_id: String = ""
var successor_spawn_in_progress: bool = false

func _ready() -> void:
	randomize()
	_build_facility_state()
	_build_station_route_system()
	_build_sector_power_system()
	_build_dynamic_world_system()
	_build_lighting()
	_build_arena()
	_spawn_player()
	_build_floor_route_beacon()
	_build_director()
	GameEvents.run_ended.connect(_on_run_ended)
	GameEvents.floor_route_available.connect(_on_floor_route_available)
	GameEvents.reset_run()

func _process(delta: float) -> void:
	if player and threat_director and not run_finished:
		player.set_run_time(threat_director.get_remaining_time(), floor_route_active)

func _unhandled_input(event: InputEvent) -> void:
	if run_finished and InputBus.wants_restart(event):
		get_tree().reload_current_scene()

func _build_facility_state() -> void:
	facility_state = FacilityProgression.new()
	facility_state.name = "FacilityProgression"
	add_child(facility_state)

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

func _build_lighting() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.015, 0.018, 0.024)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.08, 0.11, 0.13)
	environment.ambient_light_energy = 0.45
	environment.fog_enabled = true
	environment.fog_density = 0.025
	environment.fog_light_color = Color(0.2, 0.7, 0.75)
	world_environment.environment = environment
	add_child(world_environment)
	var moon := DirectionalLight3D.new()
	moon.name = "ColdDirectionalLight"
	moon.rotation_degrees = Vector3(-55, -25, 0)
	moon.light_energy = 0.65
	moon.light_color = Color(0.58, 0.78, 0.9)
	add_child(moon)

func _build_arena() -> void:
	arena_root = Node3D.new()
	arena_root.name = "GreyboxRuinedFacility"
	add_child(arena_root)
	enemy_container = Node3D.new()
	enemy_container.name = "Enemies"
	add_child(enemy_container)
	_create_box("Floor", Vector3(0, -0.1, 0), Vector3(42, 0.2, 42), Color(0.12, 0.13, 0.14), true)
	_create_box("NorthWall", Vector3(0, 2.0, -21), Vector3(42, 4.0, 0.6), Color(0.18, 0.2, 0.22), true)
	_create_box("SouthWall", Vector3(0, 2.0, 21), Vector3(42, 4.0, 0.6), Color(0.18, 0.2, 0.22), true)
	_create_box("WestWall", Vector3(-21, 2.0, 0), Vector3(0.6, 4.0, 42), Color(0.18, 0.2, 0.22), true)
	_create_box("EastWall", Vector3(21, 2.0, 0), Vector3(0.6, 4.0, 42), Color(0.18, 0.2, 0.22), true)
	var cover_specs := [
		[Vector3(-8, 0.75, -5), Vector3(5, 1.5, 1.2)],
		[Vector3(8, 0.75, 4), Vector3(5, 1.5, 1.2)],
		[Vector3(-3, 1.0, 9), Vector3(1.4, 2.0, 5)],
		[Vector3(4, 1.0, -10), Vector3(1.4, 2.0, 5)],
		[Vector3(-13, 0.6, 8), Vector3(3, 1.2, 3)],
		[Vector3(13, 0.6, -7), Vector3(3, 1.2, 3)]
	]
	nav_blockers.clear()
	for spec in cover_specs:
		var cover_position: Vector3 = spec[0]
		var cover_size: Vector3 = spec[1]
		_create_box("RuinCover", cover_position, cover_size, Color(0.22, 0.23, 0.24), true)
		_register_nav_blocker(cover_position, cover_size)
	_build_navigation_region()
	for point in [
		Vector3(-17, 0, -17),
		Vector3(17, 0, -17),
		Vector3(-17, 0, 17),
		Vector3(17, 0, 17),
		Vector3(0, 0, -18),
		Vector3(0, 0, 18)
	]:
		var spawn := Node3D.new()
		spawn.name = "ThreatSpawn"
		spawn.global_position = point
		arena_root.add_child(spawn)
		spawn_points.append(spawn)
	_create_warning_lights()
	_build_survivor_entry_scenarios()
	_build_hidden_route_markers()
	_build_dynamic_environment_props()

func _register_nav_blocker(position: Vector3, size: Vector3) -> void:
	nav_blockers.append({
		"min_x": position.x - size.x * 0.5,
		"max_x": position.x + size.x * 0.5,
		"min_z": position.z - size.z * 0.5,
		"max_z": position.z + size.z * 0.5
	})

func _build_navigation_region() -> void:
	navigation_region = NavigationRegion3D.new()
	navigation_region.name = "ArenaNavigationRegion"
	var nav_mesh := NavigationMesh.new()
	var vertices: Array = []
	var vertex_lookup: Dictionary = {}
	var polygons: Array = []
	var cell_size := 2.0
	var min_coord := -20.0
	var cell_count := 20
	for x_index in range(cell_count):
		for z_index in range(cell_count):
			var min_x := min_coord + float(x_index) * cell_size
			var min_z := min_coord + float(z_index) * cell_size
			var max_x := min_x + cell_size
			var max_z := min_z + cell_size
			if _nav_cell_blocked(min_x, max_x, min_z, max_z):
				continue
			var polygon := PackedInt32Array([
				_get_nav_vertex(vertices, vertex_lookup, Vector3(min_x, 0.0, min_z)),
				_get_nav_vertex(vertices, vertex_lookup, Vector3(max_x, 0.0, min_z)),
				_get_nav_vertex(vertices, vertex_lookup, Vector3(max_x, 0.0, max_z)),
				_get_nav_vertex(vertices, vertex_lookup, Vector3(min_x, 0.0, max_z))
			])
			polygons.append(polygon)
	var packed_vertices := PackedVector3Array()
	for vertex in vertices:
		packed_vertices.append(vertex)
	nav_mesh.set_vertices(packed_vertices)
	for polygon in polygons:
		nav_mesh.add_polygon(polygon)
	navigation_region.navigation_mesh = nav_mesh
	arena_root.add_child(navigation_region)

func _get_nav_vertex(vertices: Array, vertex_lookup: Dictionary, point: Vector3) -> int:
	var key := "%d:%d" % [roundi(point.x * 10.0), roundi(point.z * 10.0)]
	if vertex_lookup.has(key):
		return int(vertex_lookup[key])
	var index := vertices.size()
	vertices.append(point)
	vertex_lookup[key] = index
	return index

func _nav_cell_blocked(min_x: float, max_x: float, min_z: float, max_z: float) -> bool:
	var clearance := 0.7
	for blocker in nav_blockers:
		var block_min_x := float(blocker["min_x"]) - clearance
		var block_max_x := float(blocker["max_x"]) + clearance
		var block_min_z := float(blocker["min_z"]) - clearance
		var block_max_z := float(blocker["max_z"]) + clearance
		if max_x <= block_min_x or min_x >= block_max_x:
			continue
		if max_z <= block_min_z or min_z >= block_max_z:
			continue
		return true
	return false

func _create_warning_lights() -> void:
	sector_lights["arena"] = []
	for point in [Vector3(-14, 3, -14), Vector3(14, 3, 14), Vector3(14, 3, -14), Vector3(-14, 3, 14)]:
		var light := OmniLight3D.new()
		light.light_color = Color(0.1, 0.9, 0.82)
		light.light_energy = 1.8
		light.omni_range = 9.0
		light.position = point
		arena_root.add_child(light)
		var lights: Array = sector_lights["arena"]
		lights.append(light)
		sector_lights["arena"] = lights
	if sector_power:
		sector_power.register_sector("arena", "Prototype Combat Arena", false)
		_apply_sector_light_state("arena", false, "initial_outage")

func _spawn_player() -> void:
	_spawn_survivor("initial")

func _spawn_survivor(entry_reason: String) -> void:
	var entry := facility_state.choose_successor_entry()
	if entry.is_empty():
		entry = {
			"room_id": "south_hab_pressure_door",
			"entry_position": Vector3(0, 0.05, 16.6),
			"explored": false,
			"visits": 0
		}
	current_room_id = String(entry["room_id"])
	var entry_position: Vector3 = entry["entry_position"]
	var was_explored := bool(entry["explored"])
	var entry_definition := _get_entry_definition(current_room_id)
	var access_state := _scar_entry_for_definition(entry_definition)
	facility_state.record_survivor_entry(current_room_id)
	survivor_count += 1
	player = PlayerControllerFPS.new()
	player.name = "Player"
	add_child(player)
	player.global_position = entry_position
	var look_target := Vector3.ZERO
	look_target.y = player.global_position.y
	if player.global_position.distance_to(look_target) > 0.1:
		player.look_at(look_target, Vector3.UP)
		player.yaw = player.rotation.y
	player.died.connect(_on_player_died)
	var intro_style := String(entry_definition.get("intro_style", "door"))
	player.play_spawn_intro(_make_spawn_text(current_room_id, entry_definition, access_state, was_explored, entry_reason), intro_style)
	player.apply_survivor_loadout(_generate_survivor_loadout(entry_reason))
	if threat_director:
		threat_director.set_player(player)
	if survivor_count > 1:
		_spawn_entry_pursuers(entry_position, entry_definition)

func _generate_survivor_loadout(entry_reason: String) -> Dictionary:
	var backgrounds := [
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
	var flashlight_roll := randf()
	var flashlight_type := "none"
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
	var starts_with_headset := survivor_count == 1
	return {
		"background": backgrounds[randi() % backgrounds.size()],
		"weapon_id": _pick_starting_weapon_id(),
		"weapon_attachments": _roll_starting_weapon_attachments(),
		"wearable_modules": _roll_starting_wearable_modules(),
		"flashlight": flashlight_type,
		"has_headset": starts_with_headset,
		"extra_ammo": randi_range(0, 18),
		"recoverable_ammo": randi_range(8, 24),
		"recoverable_build_charge": randi_range(0, 1),
		"resources": _roll_starting_resources(),
		"entry_reason": entry_reason
	}

func _pick_starting_weapon_id() -> String:
	var pool := [
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
	var resources := {}
	var possible := ["fuse", "power_cell", "cable_spool", "tool_parts", "access_credential"]
	for resource_id in possible:
		if randf() < 0.22:
			resources[resource_id] = randi_range(1, 2)
	return resources

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
	var pool := ["compact_suppressor", "port_compensator", "reflex_sight", "foregrip", "quickpull_magwell", "retention_sling"]
	if randf() < 0.2:
		attachments.append(pool[randi() % pool.size()])
	return attachments

func _build_survivor_entry_scenarios() -> void:
	entry_definitions = [
		{
			"room_id": "south_hab_pressure_door",
			"access_id": "entry_south_hab_pressure_door",
			"access_kind": "pressure_door",
			"entry_label": "Hab pressure door",
			"door_id": "door_south_hab",
			"intro_style": "door",
			"entry": Vector3(0, 0.05, 16.6),
			"marker_position": Vector3(0, 1.1, 20.62),
			"marker_size": Vector3(4.2, 2.2, 0.28),
			"marker_color": Color(0.16, 0.22, 0.24),
			"marker_collision": true,
			"pursuers": 2
		},
		{
			"room_id": "north_service_airlock_tumble",
			"access_id": "entry_north_service_airlock",
			"access_kind": "airlock",
			"entry_label": "Emergency airlock tumble",
			"door_id": "door_north_service",
			"intro_style": "tumble",
			"entry": Vector3(0, 0.05, -16.6),
			"marker_position": Vector3(0, 1.1, -20.62),
			"marker_size": Vector3(4.2, 2.2, 0.28),
			"marker_color": Color(0.13, 0.18, 0.24),
			"marker_collision": true,
			"pursuers": 1
		},
		{
			"room_id": "west_maintenance_crawl",
			"access_id": "entry_west_maintenance_crawl",
			"access_kind": "crawlspace",
			"entry_label": "Maintenance crawlspace",
			"intro_style": "crawl",
			"entry": Vector3(-16.6, 0.05, 0),
			"marker_position": Vector3(-20.62, 0.62, 0),
			"marker_size": Vector3(0.18, 0.72, 2.3),
			"marker_color": Color(0.06, 0.09, 0.1),
			"marker_collision": false,
			"pursuers": 1
		},
		{
			"room_id": "east_ceiling_catwalk_fall",
			"access_id": "entry_east_ceiling_catwalk",
			"access_kind": "catwalk",
			"entry_label": "Ceiling catwalk drop",
			"intro_style": "catwalk",
			"entry": Vector3(16.6, 0.05, 0),
			"marker_position": Vector3(13.0, 3.05, 0),
			"marker_size": Vector3(4.8, 0.18, 1.0),
			"marker_color": Color(0.12, 0.18, 0.18),
			"marker_collision": false,
			"pursuers": 2
		},
		{
			"room_id": "reactor_vent_drop",
			"access_id": "entry_reactor_vent_drop",
			"access_kind": "vent_drop",
			"entry_label": "Broken reactor vent",
			"intro_style": "fall",
			"entry": Vector3(-15.5, 0.05, 14.2),
			"marker_position": Vector3(-15.5, 2.9, 14.2),
			"marker_size": Vector3(1.5, 0.16, 1.5),
			"marker_color": Color(0.04, 0.08, 0.08),
			"marker_collision": false,
			"pursuers": 1
		},
		{
			"room_id": "cargo_lift_crash",
			"access_id": "entry_cargo_lift_crash",
			"access_kind": "cargo_lift",
			"entry_label": "Crashed cargo lift",
			"intro_style": "pod",
			"entry": Vector3(15.5, 0.05, -14.2),
			"marker_position": Vector3(18.9, 0.45, -14.2),
			"marker_size": Vector3(2.4, 0.9, 2.4),
			"marker_color": Color(0.19, 0.2, 0.18),
			"marker_collision": false,
			"pursuers": 2
		},
		{
			"room_id": "elevator_shaft_ladder",
			"access_id": "entry_elevator_shaft_ladder",
			"access_kind": "elevator_shaft",
			"entry_label": "Elevator shaft ladder",
			"intro_style": "shaft",
			"entry": Vector3(-3.0, 0.05, -16.5),
			"marker_position": Vector3(-3.0, 2.0, -20.55),
			"marker_size": Vector3(1.4, 3.8, 0.18),
			"marker_color": Color(0.12, 0.12, 0.1),
			"marker_collision": false,
			"pursuers": 1
		},
		{
			"room_id": "floor_hatch_crawlout",
			"access_id": "entry_floor_hatch_crawlout",
			"access_kind": "floor_hatch",
			"entry_label": "Buckled floor hatch",
			"intro_style": "crawl",
			"entry": Vector3(5.0, 0.05, 15.5),
			"marker_position": Vector3(5.0, 0.02, 18.7),
			"marker_size": Vector3(1.8, 0.08, 1.4),
			"marker_color": Color(0.05, 0.06, 0.06),
			"marker_collision": false,
			"pursuers": 0
		},
		{
			"room_id": "med_pod_eject",
			"access_id": "entry_med_pod_eject",
			"access_kind": "med_pod",
			"entry_label": "Cracked med pod",
			"intro_style": "pod",
			"entry": Vector3(-12.0, 0.05, -13.0),
			"marker_position": Vector3(-14.0, 0.7, -14.8),
			"marker_size": Vector3(1.5, 1.1, 0.8),
			"marker_color": Color(0.18, 0.28, 0.3),
			"marker_collision": false,
			"pursuers": 0
		},
		{
			"room_id": "service_pipe_drop",
			"access_id": "entry_service_pipe_drop",
			"access_kind": "service_pipe",
			"entry_label": "Overhead service pipe",
			"intro_style": "fall",
			"entry": Vector3(11.0, 0.05, 12.0),
			"marker_position": Vector3(11.0, 3.05, 12.0),
			"marker_size": Vector3(2.0, 0.2, 0.8),
			"marker_color": Color(0.08, 0.09, 0.1),
			"marker_collision": false,
			"pursuers": 1
		},
		{
			"room_id": "exterior_breach_tumble",
			"access_id": "entry_exterior_breach_tumble",
			"access_kind": "exterior_breach",
			"entry_label": "Hull breach lock",
			"intro_style": "tumble",
			"entry": Vector3(17.0, 0.05, 7.0),
			"marker_position": Vector3(20.55, 1.4, 7.0),
			"marker_size": Vector3(0.2, 2.5, 2.1),
			"marker_color": Color(0.09, 0.13, 0.17),
			"marker_collision": false,
			"pursuers": 2
		},
		{
			"room_id": "waste_chute_spill",
			"access_id": "entry_waste_chute_spill",
			"access_kind": "waste_chute",
			"entry_label": "Waste chute spill",
			"intro_style": "fall",
			"entry": Vector3(-10.0, 0.05, 3.0),
			"marker_position": Vector3(-10.0, 2.45, 3.0),
			"marker_size": Vector3(1.2, 0.24, 1.2),
			"marker_color": Color(0.11, 0.12, 0.08),
			"marker_collision": false,
			"pursuers": 1
		}
	]
	for definition in entry_definitions:
		var room_id := String(definition["room_id"])
		var access_id := String(definition["access_id"])
		var access_kind := String(definition["access_kind"])
		var room_entry: Vector3 = definition["entry"]
		var marker_position: Vector3 = definition["marker_position"]
		var marker_size: Vector3 = definition["marker_size"]
		var marker_color: Color = definition["marker_color"]
		var marker_collision := bool(definition["marker_collision"])
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
	_create_box("UpperCatwalkHint", Vector3(0, 2.8, -6.0), Vector3(12.0, 0.16, 1.2), Color(0.12, 0.18, 0.18), false)

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
	_create_wearable_module_pickup("DiagnosticGlassesPickup", Vector3(-7.2, 0.45, 13.8), "hud_glasses")
	_create_wearable_module_pickup("AmmoReceiverPickup", Vector3(-8.2, 0.45, 13.8), "ammo_link_receiver")
	_create_wearable_module_pickup("BrainwaveReaderPickup", Vector3(-9.2, 0.45, 13.8), "brainwave_reader")
	_create_wearable_module_pickup("CompassModulePickup", Vector3(-10.2, 0.45, 13.8), "compass_module")
	_create_wearable_module_pickup("RouteMapperPickup", Vector3(-11.2, 0.45, 13.8), "route_mapper")
	_create_wearable_module_pickup("CommsTranscriberPickup", Vector3(-12.2, 0.45, 13.8), "comms_transcriber")
	_create_wearable_module_pickup("ReticleLensPickup", Vector3(-13.2, 0.45, 13.8), "reticle_lens")
	_create_wearable_module_pickup("SoundMeterPickup", Vector3(-14.2, 0.45, 13.8), "sound_meter")
	_create_wearable_module_pickup("LowLightFilterPickup", Vector3(-15.2, 0.45, 13.8), "low_light_filter")
	_create_wearable_module_pickup("ThreatClassifierPickup", Vector3(-16.2, 0.45, 13.8), "threat_classifier")
	_create_weapon_attachment_pickup("AmmoTelemetryPickup", Vector3(7.2, 0.45, -13.8), "ammo_telemetry_transmitter")
	_create_weapon_attachment_pickup("SuppressorPickup", Vector3(8.2, 0.45, -13.8), "compact_suppressor")
	_create_weapon_attachment_pickup("CompensatorPickup", Vector3(9.2, 0.45, -13.8), "port_compensator")
	_create_weapon_attachment_pickup("ReflexSightPickup", Vector3(10.2, 0.45, -13.8), "reflex_sight")
	_create_weapon_attachment_pickup("LaserPointerPickup", Vector3(11.2, 0.45, -13.8), "laser_pointer")
	_create_weapon_attachment_pickup("ForegripPickup", Vector3(12.2, 0.45, -13.8), "foregrip")
	_create_weapon_attachment_pickup("ExtendedMagazinePickup", Vector3(13.2, 0.45, -13.8), "extended_magazine")
	_create_weapon_attachment_pickup("QuickpullMagwellPickup", Vector3(14.2, 0.45, -13.8), "quickpull_magwell")
	_create_weapon_attachment_pickup("WeaponLightPickup", Vector3(15.2, 0.45, -13.8), "weapon_light")
	_create_weapon_attachment_pickup("RetentionSlingPickup", Vector3(16.2, 0.45, -13.8), "retention_sling")
	_create_service_node("ArenaFuseSlot", Vector3(-18.9, 1.25, 12.0), Vector3(0, 90, 0), "sector_power", "arena", "replace_fuse", "fuse", 1)
	_create_service_node("ArenaBreakerReset", Vector3(18.9, 1.25, -12.0), Vector3(0, -90, 0), "sector_power", "arena", "reset_breaker")
	_create_service_node("ArenaCablePatch", Vector3(-6.0, 1.1, 20.25), Vector3(0, 180, 0), "sector_power", "arena", "patch_cable", "cable_spool", 1)
	_create_service_node("ArenaBatterySocket", Vector3(6.0, 1.1, -20.25), Vector3(0, 0, 0), "sector_power", "arena", "slot_power_cell", "power_cell", 1)
	_create_service_node("ArenaGeneratorBypass", Vector3(18.9, 1.25, 12.0), Vector3(0, -90, 0), "sector_power", "arena", "restart_generator", "tool_parts", 1)
	_create_service_node("NorthAccessCredentialPanel", Vector3(2.8, 1.35, -20.26), Vector3(0, 0, 0), "door_override", "door_north_service", "use_access_credential", "access_credential", 1)
	_create_service_node("SouthMaintenanceBypass", Vector3(-2.8, 1.35, 20.26), Vector3(0, 180, 0), "door_override", "door_south_hab", "maintenance_bypass", "tool_parts", 1)
	_create_service_node("ExecutiveLiftClue", Vector3(13.2, 1.2, 18.9), Vector3(0, 180, 0), "route_discovery", "executive_hidden_lift", "office_lift_note", "access_credential", 1)
	_create_service_node("MainStairwellRoute", Vector3(0.0, 1.35, 20.2), Vector3(0, 180, 0), "floor_route", "main_stairwell", "take_stairs")
	_create_service_node("ServiceElevatorRoute", Vector3(0.0, 1.35, -20.2), Vector3(0, 0, 0), "floor_route", "service_elevator", "call_lift", "power_cell", 1)
	_create_service_node("MaintenanceLadderRoute", Vector3(-18.9, 1.1, -2.0), Vector3(0, 90, 0), "floor_route", "maintenance_ladder_riser", "climb_ladder")
	_create_service_node("VentStackRoute", Vector3(-18.9, 0.75, 14.0), Vector3(0, 90, 0), "floor_route", "ventilation_stack", "fan_lockout", "fuse", 1)
	_create_service_node("CargoHoistRoute", Vector3(18.9, 1.1, -14.0), Vector3(0, -90, 0), "floor_route", "cargo_hoist_shaft", "release_hoist", "tool_parts", 1)
	_create_service_node("ExteriorCatwalkRoute", Vector3(18.9, 1.1, 7.0), Vector3(0, -90, 0), "floor_route", "exterior_catwalk", "cycle_airlock", "cutting_charge", 1)
	_create_environment_hazard("VolatileTankHazard", Vector3(-5.0, 0.7, -14.0), "blast", Vector3(0.7, 1.1, 0.7), Color(0.55, 0.18, 0.1), 4.2, 92.0, 15.0)
	_create_environment_hazard("ArcJunctionHazard", Vector3(14.8, 1.1, -5.0), "electric", Vector3(0.55, 1.0, 0.22), Color(0.08, 0.36, 0.64), 3.2, 54.0, 8.0)
	_create_environment_hazard("SteamMainHazard", Vector3(-14.8, 1.1, 5.0), "steam", Vector3(0.55, 1.0, 0.22), Color(0.45, 0.48, 0.42), 3.5, 42.0, 6.0)
	_create_environment_hazard("PressureDumpHazard", Vector3(18.6, 1.4, 7.0), "pressure_dump", Vector3(0.3, 1.8, 1.6), Color(0.12, 0.28, 0.34), 4.8, 24.0, 18.0)
	_create_environment_hazard("CargoCrusherHazard", Vector3(0.0, 2.2, -7.0), "crusher", Vector3(2.0, 0.4, 2.0), Color(0.42, 0.1, 0.08), 2.2, 130.0, 6.0)
	_create_environment_hazard("CoolantFloodHazard", Vector3(7.0, 0.7, 7.0), "coolant", Vector3(0.75, 1.0, 0.75), Color(0.16, 0.55, 0.5), 3.4, 36.0, 5.0)

func _create_dynamic_prop(prop_name: String, position: Vector3, size: Vector3, color: Color, object_mass: float) -> DynamicObject3D:
	var prop := DynamicObject3D.new()
	prop.name = prop_name
	prop.configure(prop_name, size, color, object_mass)
	prop.global_position = position
	arena_root.add_child(prop)
	return prop

func _create_dynamic_button(button_id: String, position: Vector3, rotation_degrees_value: Vector3) -> DynamicButton3D:
	var button := DynamicButton3D.new()
	button.name = button_id
	button.configure(button_id)
	button.global_position = position
	button.rotation_degrees = rotation_degrees_value
	button.activated.connect(_on_dynamic_button_activated)
	arena_root.add_child(button)
	return button

func _create_flashlight_pickup(pickup_name: String, position: Vector3, mount_type: String) -> EquipmentPickup3D:
	var pickup := EquipmentPickup3D.new()
	pickup.name = pickup_name
	pickup.configure_flashlight(mount_type)
	arena_root.add_child(pickup)
	pickup.global_position = position
	return pickup

func _create_weapon_pickup(pickup_name: String, position: Vector3, weapon_id: String, label: String) -> EquipmentPickup3D:
	var pickup := EquipmentPickup3D.new()
	pickup.name = pickup_name
	pickup.configure_weapon(weapon_id, label)
	arena_root.add_child(pickup)
	pickup.global_position = position
	return pickup

func _create_resource_pickup(pickup_name: String, position: Vector3, resource_id: String, amount: int) -> EquipmentPickup3D:
	var pickup := EquipmentPickup3D.new()
	pickup.name = pickup_name
	pickup.configure_resource(resource_id, amount)
	arena_root.add_child(pickup)
	pickup.global_position = position
	return pickup

func _create_wearable_module_pickup(pickup_name: String, position: Vector3, module_id: String) -> EquipmentPickup3D:
	var pickup := EquipmentPickup3D.new()
	pickup.name = pickup_name
	pickup.configure_wearable_module(module_id)
	arena_root.add_child(pickup)
	pickup.global_position = position
	return pickup

func _create_weapon_attachment_pickup(pickup_name: String, position: Vector3, attachment_id: String) -> EquipmentPickup3D:
	var pickup := EquipmentPickup3D.new()
	pickup.name = pickup_name
	pickup.configure_weapon_attachment(attachment_id)
	arena_root.add_child(pickup)
	pickup.global_position = position
	return pickup

func _create_service_node(node_id: String, position: Vector3, rotation_degrees_value: Vector3, service_type: String, target_id: String, method_id: String, requirement_id: String = "", requirement_amount: int = 0) -> FacilityServiceNode3D:
	var node := FacilityServiceNode3D.new()
	node.name = node_id
	node.configure(node_id, service_type, target_id, method_id, requirement_id, requirement_amount)
	node.global_position = position
	node.rotation_degrees = rotation_degrees_value
	node.service_used.connect(_on_service_node_used)
	arena_root.add_child(node)
	return node

func _create_environment_hazard(hazard_name: String, position: Vector3, hazard_type: String, size: Vector3, color: Color, radius: float, damage: float, force: float) -> EnvironmentalHazard3D:
	var hazard := EnvironmentalHazard3D.new()
	hazard.name = hazard_name
	hazard.configure(hazard_name, hazard_type, size, color, radius, damage, force)
	arena_root.add_child(hazard)
	hazard.global_position = position
	return hazard

func _get_entry_definition(room_id: String) -> Dictionary:
	for definition in entry_definitions:
		if String(definition["room_id"]) == room_id:
			return definition
	return {}

func _scar_entry_for_definition(definition: Dictionary) -> String:
	if definition.is_empty():
		return FacilityProgression.ACCESS_SCARRED
	var access_id := String(definition["access_id"])
	var access_state := facility_state.scar_access_point(access_id)
	var door_id := ""
	if definition.has("door_id"):
		door_id = String(definition["door_id"])
		facility_state.jam_door(door_id)
	if entry_nodes.has(access_id):
		var node := entry_nodes[access_id] as Node3D
		if node and node is FacilityDoor3D:
			(node as FacilityDoor3D).set_state(facility_state.get_door_state(door_id))
		elif node:
			_apply_access_state_visual(node, access_state)
	return access_state

func _apply_access_state_visual(access_node: Node3D, state: String) -> void:
	var color := Color(0.14, 0.2, 0.21)
	var emission := 0.05
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
	var familiarity := "known access" if was_explored else "unmapped access"
	var arrival := "NEW SURVIVOR" if survivor_count > 1 else "SURVIVOR"
	var pressure := "pursued breach" if entry_reason == "successor" else "cold start"
	var label := String(definition.get("entry_label", room_id.replace("_", " ")))
	var consequence := "access scarred behind you"
	if access_state == FacilityProgression.ACCESS_COMPROMISED:
		consequence = "return route compromised"
	elif access_state == FacilityProgression.ACCESS_BLOCKED:
		consequence = "return route probably blocked"
	return "%s\n%s / %s / %s\n%s" % [arrival, label.to_upper(), familiarity, pressure, consequence]

func _spawn_entry_pursuers(entry_position: Vector3, definition: Dictionary) -> void:
	if not threat_director:
		return
	var pursuer_count := int(definition.get("pursuers", 2))
	if pursuer_count <= 0:
		return
	if randf() > 0.28:
		return
	if randf() < 0.35:
		_unlock_followthrough_breach(definition)
	var to_center := Vector3.ZERO - entry_position
	to_center.y = 0.0
	if to_center.length() < 0.1:
		to_center = Vector3.FORWARD
	to_center = to_center.normalized()
	var behind := -to_center
	var side := Vector3(-to_center.z, 0.0, to_center.x)
	var offsets := [
		behind * 1.6 + side * 0.8,
		behind * 2.1 - side * 0.8,
		behind * 2.6,
		behind * 3.0 + side * 1.2
	]
	for i in range(min(pursuer_count, offsets.size())):
		var offset: Vector3 = offsets[i]
		threat_director.spawn_enemy_at(entry_position + offset)

func _unlock_followthrough_breach(definition: Dictionary) -> void:
	var access_id := String(definition.get("access_id", "unknown_access"))
	var access_kind := String(definition.get("access_kind", "breach"))
	var flag_name := "followthrough_%s" % access_id
	facility_state.unlock_flag(flag_name)
	if definition.has("door_id"):
		var door_id := String(definition["door_id"])
		facility_state.set_door_state(door_id, FacilityProgression.DOOR_OPEN)
		if entry_doors.has(door_id):
			var door := entry_doors[door_id] as FacilityDoor3D
			if door:
				door.set_state(FacilityProgression.DOOR_OPEN)
	if player and player.comms:
		player.comms.announce("Something followed you through the %s. That route may be forced open now." % access_kind.replace("_", " "))

func _build_floor_route_beacon() -> void:
	floor_route_area = Area3D.new()
	floor_route_area.name = "FloorTransitionBeacon"
	floor_route_area.global_position = Vector3(0, 0.5, -18.5)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(4.5, 2.5, 4.5)
	collision.shape = shape
	floor_route_area.add_child(collision)
	floor_route_mesh = MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 2.0
	mesh.bottom_radius = 2.0
	mesh.height = 0.12
	floor_route_mesh.mesh = mesh
	floor_route_mesh.material_override = _make_material(Color(0.18, 0.24, 0.24, 0.45), 0.0)
	floor_route_area.add_child(floor_route_mesh)
	floor_route_area.body_entered.connect(_on_floor_route_body_entered)
	add_child(floor_route_area)

func _build_director() -> void:
	threat_director = ThreatDirector.new()
	threat_director.name = "ThreatDirector"
	add_child(threat_director)
	threat_director.setup(player, enemy_container, spawn_points)

func _create_box(box_name: String, position: Vector3, size: Vector3, color: Color, collision: bool) -> Node3D:
	var root: Node3D
	if collision:
		var static_body := ReactiveStaticBody3D.new()
		static_body.collision_layer = 1
		static_body.collision_mask = 0
		root = static_body
	else:
		root = Node3D.new()
	root.name = box_name
	root.position = position
	var mesh_instance := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	mesh_instance.mesh = box_mesh
	mesh_instance.material_override = _make_material(color, 0.0)
	root.add_child(mesh_instance)
	if collision:
		var collision_shape := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = size
		collision_shape.shape = box_shape
		root.add_child(collision_shape)
	arena_root.add_child(root)
	return root

func _create_facility_door(door_id: String, door_name: String, position: Vector3, size: Vector3, color: Color) -> FacilityDoor3D:
	var door := FacilityDoor3D.new()
	door.name = door_name
	door.position = position
	door.configure_door(door_id, facility_state.get_door_state(door_id), size, color)
	door.door_forced_open.connect(_on_facility_door_forced_open)
	arena_root.add_child(door)
	return door

func _make_material(color: Color, emission_energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission_energy
	return material

func _on_floor_route_available() -> void:
	floor_route_active = true
	floor_route_mesh.material_override = _make_material(Color(0.1, 1.0, 0.65, 0.9), 1.2)

func _on_dynamic_button_activated(button_id: String) -> void:
	var button := arena_root.get_node_or_null(button_id)
	if button and button is Node3D:
		GameEvents.emit_player_noise(button.global_position, 10.0)
	var button_active := false
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
	var door := entry_doors[door_id] as FacilityDoor3D
	if not door:
		return
	if door.state == FacilityProgression.DOOR_SEALED:
		if player and player.comms:
			player.comms.announce("That door is sealed. The override cannot move it.")
		return
	var new_state := FacilityProgression.DOOR_OPEN if button_active else FacilityProgression.DOOR_LOCKED
	facility_state.set_door_state(door_id, new_state)
	door.set_state(new_state)
	if player and player.comms:
		var message := "Override opened a pressure door." if button_active else "Override dropped. Door locked again."
		player.comms.announce(message)

func _on_facility_door_forced_open(door_id: String) -> void:
	facility_state.set_door_state(door_id, FacilityProgression.DOOR_OPEN)
	facility_state.unlock_flag("forced_%s" % door_id)
	if player and player.comms:
		player.comms.announce("Door forced. The station will remember that route.")

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
				GameEvents.end_run(true, "moved to floor %d through %s" % [route_system.current_floor, target_id.replace("_", " ")])

func _open_door_from_service(door_id: String, method_id: String) -> void:
	if not entry_doors.has(door_id):
		return
	var door := entry_doors[door_id] as FacilityDoor3D
	if not door:
		return
	if door.state == FacilityProgression.DOOR_SEALED and method_id != "cutting_charge":
		if player and player.comms:
			player.comms.announce("Service node responded, but the door is sealed.")
		return
	facility_state.set_door_state(door_id, FacilityProgression.DOOR_OPEN)
	facility_state.unlock_flag("service_opened_%s" % door_id)
	door.set_state(FacilityProgression.DOOR_OPEN)
	if player and player.comms:
		player.comms.announce("Door opened through %s." % method_id.replace("_", " "))

func _apply_sector_light_state(sector_id: String, powered: bool, _method_id: String) -> void:
	if not sector_lights.has(sector_id):
		return
	var lights: Array = sector_lights[sector_id]
	for light in lights:
		if not is_instance_valid(light):
			continue
		var omni := light as OmniLight3D
		if not omni:
			continue
		omni.light_energy = 1.8 if powered else 0.18
		omni.light_color = Color(0.1, 0.9, 0.82) if powered else Color(0.04, 0.13, 0.14)

func _on_station_floor_changed(floor_index: int, route_id: String) -> void:
	facility_state.unlock_flag("reached_floor_%d" % floor_index)
	if player and player.comms:
		player.comms.announce("Floor transition logged through %s." % route_id.replace("_", " "))

func _on_floor_route_body_entered(body: Node3D) -> void:
	if floor_route_active and body == player:
		GameEvents.end_run(true, "reached temporary floor transition")

func _on_player_died(reason: String) -> void:
	if successor_spawn_in_progress or run_finished:
		return
	successor_spawn_in_progress = true
	var dead_player := player
	if is_instance_valid(dead_player):
		facility_state.record_lost_survivor(dead_player.global_position, current_room_id, survivor_count, reason)
		_drop_lost_survivor_kit(dead_player.global_position, dead_player.survivor_loadout, dead_player.had_headset_when_lost())
	if is_instance_valid(dead_player):
		dead_player.show_death_handoff(reason)
	if threat_director:
		threat_director.set_player(null)
	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(dead_player):
		dead_player.queue_free()
	_spawn_survivor("successor")
	successor_spawn_in_progress = false

func _drop_lost_survivor_kit(position: Vector3, loadout: Dictionary, had_headset: bool) -> void:
	var kit := LostSurvivorKit3D.new()
	kit.name = "LostSurvivorKit_%d" % survivor_count
	kit.configure_lost_kit(survivor_count, loadout, had_headset)
	arena_root.add_child(kit)
	kit.global_position = position + Vector3(0, 0.45, 0)

func _on_run_ended(success: bool, reason: String) -> void:
	run_finished = true
	if player:
		player.show_end_state(success, reason)
