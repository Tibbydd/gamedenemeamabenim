extends Node3D

var player: PlayerControllerFPS
var facility_state: FacilityProgression
var dynamic_world: DynamicWorldSystem
var threat_director: ThreatDirector
var enemy_container: Node3D
var arena_root: Node3D
var spawn_points: Array[Node3D] = []
var entry_definitions: Array = []
var entry_doors: Dictionary = {}
var entry_nodes: Dictionary = {}
var extraction_area: Area3D
var extraction_mesh: MeshInstance3D
var extraction_active: bool = false
var run_finished: bool = false
var survivor_count: int = 0
var current_room_id: String = ""
var successor_spawn_in_progress: bool = false

func _ready() -> void:
	randomize()
	_build_facility_state()
	_build_dynamic_world_system()
	_build_lighting()
	_build_arena()
	_spawn_player()
	_build_extraction()
	_build_director()
	GameEvents.run_ended.connect(_on_run_ended)
	GameEvents.extraction_available.connect(_on_extraction_available)
	GameEvents.reset_run()

func _process(delta: float) -> void:
	if player and threat_director and not run_finished:
		player.set_run_time(threat_director.get_remaining_time(), extraction_active)

func _unhandled_input(event: InputEvent) -> void:
	if run_finished and InputBus.wants_restart(event):
		get_tree().reload_current_scene()

func _build_facility_state() -> void:
	facility_state = FacilityProgression.new()
	facility_state.name = "FacilityProgression"
	add_child(facility_state)

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
	for spec in cover_specs:
		_create_box("RuinCover", spec[0], spec[1], Color(0.22, 0.23, 0.24), true)
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

func _create_warning_lights() -> void:
	for point in [Vector3(-14, 3, -14), Vector3(14, 3, 14), Vector3(14, 3, -14), Vector3(-14, 3, 14)]:
		var light := OmniLight3D.new()
		light.light_color = Color(0.1, 0.9, 0.82)
		light.light_energy = 1.8
		light.omni_range = 9.0
		light.position = point
		arena_root.add_child(light)

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
	if threat_director:
		threat_director.set_player(player)
	if survivor_count > 1:
		_spawn_entry_pursuers(entry_position, entry_definition)

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
		var marker := _create_box(
			"Entry_" + room_id,
			marker_position,
			marker_size,
			marker_color,
			marker_collision
		)
		entry_nodes[access_id] = marker
		if definition.has("door_id"):
			entry_doors[String(definition["door_id"])] = marker
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
	if definition.has("door_id"):
		facility_state.jam_door(String(definition["door_id"]))
	if entry_nodes.has(access_id):
		var node := entry_nodes[access_id] as Node3D
		if node:
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

func _build_extraction() -> void:
	extraction_area = Area3D.new()
	extraction_area.name = "ExtractionBeacon"
	extraction_area.global_position = Vector3(0, 0.5, -18.5)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(4.5, 2.5, 4.5)
	collision.shape = shape
	extraction_area.add_child(collision)
	extraction_mesh = MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 2.0
	mesh.bottom_radius = 2.0
	mesh.height = 0.12
	extraction_mesh.mesh = mesh
	extraction_mesh.material_override = _make_material(Color(0.18, 0.24, 0.24, 0.45), 0.0)
	extraction_area.add_child(extraction_mesh)
	extraction_area.body_entered.connect(_on_extraction_body_entered)
	add_child(extraction_area)

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

func _make_material(color: Color, emission_energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission_energy
	return material

func _on_extraction_available() -> void:
	extraction_active = true
	extraction_mesh.material_override = _make_material(Color(0.1, 1.0, 0.65, 0.9), 1.2)

func _on_dynamic_button_activated(button_id: String) -> void:
	var button := arena_root.get_node_or_null(button_id)
	if button and button is Node3D:
		GameEvents.emit_player_noise(button.global_position, 10.0)

func _on_extraction_body_entered(body: Node3D) -> void:
	if extraction_active and body == player:
		GameEvents.end_run(true, "reached emergency extraction")

func _on_player_died(reason: String) -> void:
	if successor_spawn_in_progress or run_finished:
		return
	successor_spawn_in_progress = true
	var dead_player := player
	if is_instance_valid(dead_player):
		facility_state.record_lost_survivor(dead_player.global_position, current_room_id, survivor_count, reason)
		_drop_lost_survivor_kit(dead_player.global_position)
	if is_instance_valid(dead_player):
		dead_player.show_death_handoff(reason)
	if threat_director:
		threat_director.set_player(null)
	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(dead_player):
		dead_player.queue_free()
	_spawn_survivor("successor")
	successor_spawn_in_progress = false

func _drop_lost_survivor_kit(position: Vector3) -> void:
	var kit := DynamicObject3D.new()
	kit.name = "LostSurvivorKit_%d" % survivor_count
	kit.configure("Lost Survivor Kit", Vector3(0.75, 0.32, 0.52), Color(0.18, 0.32, 0.3), 9.0)
	kit.global_position = position + Vector3(0, 0.45, 0)
	arena_root.add_child(kit)

func _on_run_ended(success: bool, reason: String) -> void:
	run_finished = true
	if player:
		player.show_end_state(success, reason)
