@tool
extends Node3D
class_name StationGeometryBuilder

# Attach to a Node3D named "StationGeometry" in PrototypeArena.tscn.
# In the editor Inspector, toggle "Rebuild" to generate geometry.
# Nodes will be saved in the .tscn so the map is visible and editable.

@export var rebuild: bool = false:
	set(v):
		if v and Engine.is_editor_hint():
			_build_editor()
		rebuild = false

var _csg_world: CSGCombiner3D

func _build_editor() -> void:
	for child in get_children():
		child.free()
	_csg_world = CSGCombiner3D.new()
	_csg_world.name = "CSGWorld"
	_csg_world.use_collision = true
	_csg_world.collision_layer = 1
	_csg_world.collision_mask = 0
	add_child(_csg_world)
	_csg_world.owner = get_tree().edited_scene_root
	_build_room_shells()
	_build_station_vertical_connections()
	_build_outer_hull()
	_build_wall_detail_pass()
	_build_exterior()
	_set_owners_recursive(self)

func get_csg_world() -> CSGCombiner3D:
	return _csg_world if _csg_world else get_node_or_null("CSGWorld") as CSGCombiner3D

func _set_owners_recursive(node: Node) -> void:
	var root := get_tree().edited_scene_root
	for child in node.get_children():
		child.owner = root
		_set_owners_recursive(child)

# All structural geometry → CSGBox3D inside _csg_world. Returns node for rotation etc.
func _csg_box(box_name: String, pos: Vector3, size: Vector3, color: Color) -> CSGBox3D:
	var box := CSGBox3D.new()
	box.name = box_name
	box.size = size
	box.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.65
	mat.metallic = 0.25
	box.material = mat
	_csg_world.add_child(box)
	return box

# ── Dict helpers ──────────────────────────────────────────────────────────────

func _dict_vector3(src: Dictionary, key: String, fb: Vector3) -> Vector3:
	var v: Variant = src.get(key, fb)
	return v if v is Vector3 else fb

func _dict_vector2(src: Dictionary, key: String, fb: Vector2) -> Vector2:
	var v: Variant = src.get(key, fb)
	return v if v is Vector2 else fb

func _dict_array(src: Dictionary, key: String) -> Array:
	var v: Variant = src.get(key, [])
	return v if v is Array else []

# ── Room specs ────────────────────────────────────────────────────────────────

func _get_station_room_specs() -> Array[Dictionary]:
	var f0 := 0.0
	var f1 := 4.2
	var f2 := 8.4
	var f3 := 12.6
	return [
		# FLOOR 0 — ARRIVAL / CARGO / UTILITIES / POWER
		{"name":"F0_AirlockEntry",    "position":Vector3(  0,f0,-33.0), "size":Vector2( 6, 6), "open_sides":["south"]},
		{"name":"F0_ArrivalCorr",     "position":Vector3(  0,f0,-27.5), "size":Vector2( 4, 5), "open_sides":["north","south"]},
		{"name":"F0_SecurityCheck",   "position":Vector3(  0,f0,-21.5), "size":Vector2(10, 7), "open_sides":["north","south","east","west"]},
		{"name":"F0_SecurityOffice",  "position":Vector3(  8,f0,-21.5), "size":Vector2( 6, 7), "open_sides":["west"]},
		{"name":"F0_HoldingCell",     "position":Vector3( -8,f0,-21.5), "size":Vector2( 6, 7), "open_sides":["east"]},
		{"name":"F0_LobbyCorr",       "position":Vector3(  0,f0,-16.0), "size":Vector2( 4, 4), "open_sides":["north","south"]},
		{"name":"F0_ReceptionLobby",  "position":Vector3(  0,f0,-10.0), "size":Vector2(14, 8), "open_sides":["north","south","east","west"]},
		{"name":"F0_VisitorWaiting",  "position":Vector3(-10,f0,-10.0), "size":Vector2( 6, 8), "open_sides":["east"]},
		{"name":"F0_AdminRecords",    "position":Vector3( 10,f0,-10.0), "size":Vector2( 6, 8), "open_sides":["west"]},
		{"name":"F0_CentralJunct",    "position":Vector3(  0,f0, -3.0), "size":Vector2( 6, 6), "open_sides":["north","south","east","west"]},
		{"name":"F0_CargoCorr",       "position":Vector3(  7,f0, -3.0), "size":Vector2( 8, 4), "open_sides":["east","west"]},
		{"name":"F0_CargoHub",        "position":Vector3( 16,f0, -3.0), "size":Vector2(10,10), "open_sides":["west","north","east","south"]},
		{"name":"F0_CargoNCorr",      "position":Vector3( 16,f0,-10.0), "size":Vector2( 4, 4), "open_sides":["south"]},
		{"name":"F0_CargoBay",        "position":Vector3( 25,f0, -3.0), "size":Vector2( 8,10), "open_sides":["west","east","south"]},
		{"name":"F0_LoadingDock",     "position":Vector3( 16,f0,  6.0), "size":Vector2(10, 8), "open_sides":["north","east"]},
		{"name":"F0_ColdStorage",     "position":Vector3( 25,f0,  6.0), "size":Vector2( 8, 8), "open_sides":["north","west","south"]},
		{"name":"F0_ForkliftCharge",  "position":Vector3( 25,f0, 13.0), "size":Vector2( 7, 6), "open_sides":["north"]},
		{"name":"F0_EStairCorr",      "position":Vector3( 31,f0, -3.0), "size":Vector2( 4,10), "open_sides":["west","east"]},
		{"name":"F0_EStairEntry",     "position":Vector3( 35,f0, -3.0), "size":Vector2( 4, 6), "open_sides":["west"]},
		{"name":"F0_UtilCorr",        "position":Vector3( -7,f0, -3.0), "size":Vector2( 8, 4), "open_sides":["east","west"]},
		{"name":"F0_WaterTreatment",  "position":Vector3(-15,f0, -3.0), "size":Vector2( 8, 8), "open_sides":["east","south"]},
		{"name":"F0_WasteProcessing", "position":Vector3(-15,f0,  5.0), "size":Vector2( 8, 8), "open_sides":["north"]},
		{"name":"F0_MaintCorr",       "position":Vector3(-22,f0, -3.0), "size":Vector2( 6, 4), "open_sides":["east","west"]},
		{"name":"F0_MaintWorkshop",   "position":Vector3(-29,f0, -3.0), "size":Vector2( 8, 8), "open_sides":["east","south"]},
		{"name":"F0_WStairEntry",     "position":Vector3(-29,f0,  5.0), "size":Vector2( 6, 8), "open_sides":["north"]},
		{"name":"F0_PowerJunct",      "position":Vector3(  0,f0,  3.0), "size":Vector2( 6, 6), "open_sides":["north","south"]},
		{"name":"F0_PowerCorr",       "position":Vector3(  0,f0,  8.5), "size":Vector2( 4, 5), "open_sides":["north","south"]},
		{"name":"F0_PowerHub",        "position":Vector3(  0,f0, 14.0), "size":Vector2(12, 6), "open_sides":["north","west","east","south"]},
		{"name":"F0_GenControl",      "position":Vector3(-10,f0, 14.0), "size":Vector2( 8, 6), "open_sides":["east","south"]},
		{"name":"F0_TransformerRoom", "position":Vector3( 10,f0, 14.0), "size":Vector2( 8, 6), "open_sides":["west","south"]},
		{"name":"F0_GenRoom",         "position":Vector3(-11,f0, 21.0), "size":Vector2(10, 8), "open_sides":["north","east"]},
		{"name":"F0_BatteryBackup",   "position":Vector3(  0,f0, 21.0), "size":Vector2(12, 8), "open_sides":["north","west","east"]},
		{"name":"F0_SpareParts",      "position":Vector3( 10,f0, 21.0), "size":Vector2( 8, 8), "open_sides":["north","west"]},
		# FLOOR 1 — CREW QUARTERS / MEDICAL / LIVING
		{"name":"F1_WStairLand",   "position":Vector3(-29,f1,-3.0), "size":Vector2( 8, 6), "open_sides":["east"],                       "floor_y":f1, "ceiling_y":f1+3.0},
		{"name":"F1_WSpine",       "position":Vector3(-18,f1,-3.0), "size":Vector2(14, 6), "open_sides":["west","east","north","south"], "floor_y":f1, "ceiling_y":f1+3.0},
		{"name":"F1_MidSpine",     "position":Vector3( -4,f1,-3.0), "size":Vector2(14, 6), "open_sides":["west","east","north","south"], "floor_y":f1, "ceiling_y":f1+3.0},
		{"name":"F1_ESpine",       "position":Vector3( 10,f1,-3.0), "size":Vector2(14, 6), "open_sides":["west","east","north","south"], "floor_y":f1, "ceiling_y":f1+3.0},
		{"name":"F1_ESpine2",      "position":Vector3( 25,f1,-3.0), "size":Vector2(16, 6), "open_sides":["west","east","north","south"], "floor_y":f1, "ceiling_y":f1+3.0},
		{"name":"F1_EStairLand",   "position":Vector3( 35,f1,-3.0), "size":Vector2( 4, 6), "open_sides":["west"],                       "floor_y":f1, "ceiling_y":f1+3.0},
		{"name":"F1_QuartersCorr", "position":Vector3(-18,f1,-9.0), "size":Vector2(10, 6), "open_sides":["south","north"],              "floor_y":f1, "ceiling_y":f1+3.0},
		{"name":"F1_BunkRoom",     "position":Vector3(-18,f1,-16.0),"size":Vector2(14, 8), "open_sides":["south"],                      "floor_y":f1, "ceiling_y":f1+3.0},
		{"name":"F1_MessHall",     "position":Vector3(-18,f1, 4.0), "size":Vector2(14, 8), "open_sides":["north"],                      "floor_y":f1, "ceiling_y":f1+3.0},
		{"name":"F1_MedCorr",      "position":Vector3( -4,f1,-9.0), "size":Vector2(10, 6), "open_sides":["south","north"],              "floor_y":f1, "ceiling_y":f1+3.0},
		{"name":"F1_MedBay",       "position":Vector3( -4,f1,-16.0),"size":Vector2(12, 8), "open_sides":["south"],                      "floor_y":f1, "ceiling_y":f1+3.0},
		{"name":"F1_RecRoom",      "position":Vector3( -4,f1, 4.0), "size":Vector2(12, 8), "open_sides":["north"],                      "floor_y":f1, "ceiling_y":f1+3.0},
		{"name":"F1_Pharmacy",     "position":Vector3( 10,f1,-9.0), "size":Vector2(10, 6), "open_sides":["south","north"],              "floor_y":f1, "ceiling_y":f1+3.0},
		{"name":"F1_ExamRoom",     "position":Vector3( 10,f1,-16.0),"size":Vector2(10, 8), "open_sides":["south"],                      "floor_y":f1, "ceiling_y":f1+3.0},
		{"name":"F1_Gym",          "position":Vector3( 10,f1, 5.0), "size":Vector2(12,10), "open_sides":["north","south"],              "floor_y":f1, "ceiling_y":f1+3.0},
		{"name":"F1_Showers",      "position":Vector3( 10,f1,13.0), "size":Vector2(10, 6), "open_sides":["north"],                      "floor_y":f1, "ceiling_y":f1+3.0},
		{"name":"F1_Surgery",      "position":Vector3( 25,f1,-9.0), "size":Vector2(10, 6), "open_sides":["south","north"],              "floor_y":f1, "ceiling_y":f1+3.0},
		{"name":"F1_Morgue",       "position":Vector3( 25,f1,-16.0),"size":Vector2(10, 8), "open_sides":["south"],                      "floor_y":f1, "ceiling_y":f1+3.0},
		{"name":"F1_FoodStorage",  "position":Vector3( 25,f1, 4.0), "size":Vector2(12, 8), "open_sides":["north"],                      "floor_y":f1, "ceiling_y":f1+3.0},
		# FLOOR 2 — RESEARCH LABS / CONTAINMENT / R&D
		{"name":"F2_WStairLand",    "position":Vector3(-29,f2,-3.0), "size":Vector2( 8, 6), "open_sides":["east"],                       "floor_y":f2, "ceiling_y":f2+3.0},
		{"name":"F2_WSpine",        "position":Vector3(-18,f2,-3.0), "size":Vector2(14, 6), "open_sides":["west","east","north","south"], "floor_y":f2, "ceiling_y":f2+3.0},
		{"name":"F2_MidSpine",      "position":Vector3( -4,f2,-3.0), "size":Vector2(14, 6), "open_sides":["west","east","north","south"], "floor_y":f2, "ceiling_y":f2+3.0},
		{"name":"F2_ESpine",        "position":Vector3( 10,f2,-3.0), "size":Vector2(14, 6), "open_sides":["west","east","north","south"], "floor_y":f2, "ceiling_y":f2+3.0},
		{"name":"F2_ESpine2",       "position":Vector3( 25,f2,-3.0), "size":Vector2(16, 6), "open_sides":["west","east","north","south"], "floor_y":f2, "ceiling_y":f2+3.0},
		{"name":"F2_EStairLand",    "position":Vector3( 35,f2,-3.0), "size":Vector2( 4, 6), "open_sides":["west"],                       "floor_y":f2, "ceiling_y":f2+3.0},
		{"name":"F2_DeconCorr",     "position":Vector3(-18,f2,-9.0), "size":Vector2(10, 6), "open_sides":["south","north"],              "floor_y":f2, "ceiling_y":f2+3.0},
		{"name":"F2_WetLab",        "position":Vector3(-18,f2,-16.0),"size":Vector2(12, 8), "open_sides":["south"],                      "floor_y":f2, "ceiling_y":f2+3.0},
		{"name":"F2_ContainmentA",  "position":Vector3(-18,f2, 4.0), "size":Vector2(14, 8), "open_sides":["north"],                      "floor_y":f2, "ceiling_y":f2+3.0},
		{"name":"F2_ResearchHub",   "position":Vector3( -4,f2,-9.0), "size":Vector2(12, 6), "open_sides":["south","north"],              "floor_y":f2, "ceiling_y":f2+3.0},
		{"name":"F2_SampleFreezer", "position":Vector3( -4,f2,-16.0),"size":Vector2(10, 8), "open_sides":["south"],                      "floor_y":f2, "ceiling_y":f2+3.0},
		{"name":"F2_SpecimenPrep",  "position":Vector3( -4,f2, 4.0), "size":Vector2(12, 8), "open_sides":["north"],                      "floor_y":f2, "ceiling_y":f2+3.0},
		{"name":"F2_ChemStorage",   "position":Vector3( 10,f2,-9.0), "size":Vector2(10, 6), "open_sides":["south","north"],              "floor_y":f2, "ceiling_y":f2+3.0},
		{"name":"F2_SecureArchive", "position":Vector3( 10,f2,-16.0),"size":Vector2(10, 8), "open_sides":["south"],                      "floor_y":f2, "ceiling_y":f2+3.0},
		{"name":"F2_RoboticsBay",   "position":Vector3( 10,f2, 5.0), "size":Vector2(12,10), "open_sides":["north","south"],              "floor_y":f2, "ceiling_y":f2+3.0},
		{"name":"F2_ObservRoom",    "position":Vector3( 10,f2,13.0), "size":Vector2(10, 6), "open_sides":["north"],                      "floor_y":f2, "ceiling_y":f2+3.0},
		{"name":"F2_DryLab",        "position":Vector3( 25,f2,-9.0), "size":Vector2(10, 6), "open_sides":["south","north"],              "floor_y":f2, "ceiling_y":f2+3.0},
		{"name":"F2_ServerAnalysis","position":Vector3( 25,f2,-16.0),"size":Vector2(10, 8), "open_sides":["south"],                      "floor_y":f2, "ceiling_y":f2+3.0},
		{"name":"F2_QuarantineCell","position":Vector3( 25,f2, 4.0), "size":Vector2(10, 8), "open_sides":["north"],                      "floor_y":f2, "ceiling_y":f2+3.0},
		# FLOOR 3 — COMMAND / COMMUNICATIONS / REACTOR
		{"name":"F3_WStairLand",      "position":Vector3(-29,f3,-3.0), "size":Vector2( 8, 6), "open_sides":["east"],                       "floor_y":f3, "ceiling_y":f3+3.0},
		{"name":"F3_WSpine",          "position":Vector3(-18,f3,-3.0), "size":Vector2(14, 6), "open_sides":["west","east","north","south"], "floor_y":f3, "ceiling_y":f3+3.0},
		{"name":"F3_MidSpine",        "position":Vector3( -4,f3,-3.0), "size":Vector2(14, 6), "open_sides":["west","east","north","south"], "floor_y":f3, "ceiling_y":f3+3.0},
		{"name":"F3_ESpine",          "position":Vector3( 10,f3,-3.0), "size":Vector2(14, 6), "open_sides":["west","east","north","south"], "floor_y":f3, "ceiling_y":f3+3.0},
		{"name":"F3_ESpine2",         "position":Vector3( 25,f3,-3.0), "size":Vector2(16, 6), "open_sides":["west","east","north","south"], "floor_y":f3, "ceiling_y":f3+3.0},
		{"name":"F3_EStairLand",      "position":Vector3( 35,f3,-3.0), "size":Vector2( 4, 6), "open_sides":["west"],                       "floor_y":f3, "ceiling_y":f3+3.0},
		{"name":"F3_CommsCorr",       "position":Vector3(-18,f3,-9.0), "size":Vector2(10, 6), "open_sides":["south","north"],              "floor_y":f3, "ceiling_y":f3+3.0},
		{"name":"F3_Communications",  "position":Vector3(-18,f3,-16.0),"size":Vector2(12, 8), "open_sides":["south"],                      "floor_y":f3, "ceiling_y":f3+3.0},
		{"name":"F3_NavigationRoom",  "position":Vector3(-18,f3, 4.0), "size":Vector2(12, 8), "open_sides":["north"],                      "floor_y":f3, "ceiling_y":f3+3.0},
		{"name":"F3_CmdCorr",         "position":Vector3( -4,f3,-9.0), "size":Vector2(10, 6), "open_sides":["south","north"],              "floor_y":f3, "ceiling_y":f3+3.0},
		{"name":"F3_CommandBridge",   "position":Vector3( -4,f3,-16.0),"size":Vector2(14, 8), "open_sides":["south"],                      "floor_y":f3, "ceiling_y":f3+3.0},
		{"name":"F3_SecurityCtrl",    "position":Vector3( -4,f3, 4.0), "size":Vector2(12, 8), "open_sides":["north"],                      "floor_y":f3, "ceiling_y":f3+3.0},
		{"name":"F3_ReactorCorr",     "position":Vector3( 10,f3,-9.0), "size":Vector2(10, 6), "open_sides":["south","north"],              "floor_y":f3, "ceiling_y":f3+3.0},
		{"name":"F3_ReactorControl",  "position":Vector3( 10,f3,-16.0),"size":Vector2(12, 8), "open_sides":["south"],                      "floor_y":f3, "ceiling_y":f3+3.0},
		{"name":"F3_CoolantMonitor",  "position":Vector3( 10,f3, 5.0), "size":Vector2(10,10), "open_sides":["north","south"],              "floor_y":f3, "ceiling_y":f3+3.0},
		{"name":"F3_EmergPowerCtrl",  "position":Vector3( 10,f3,13.0), "size":Vector2(10, 6), "open_sides":["north"],                      "floor_y":f3, "ceiling_y":f3+3.0},
		{"name":"F3_EscapePodAccess", "position":Vector3( 25,f3,-9.0), "size":Vector2(10, 6), "open_sides":["south","north"],              "floor_y":f3, "ceiling_y":f3+3.0},
		{"name":"F3_ReactorCore",     "position":Vector3( 25,f3,-16.0),"size":Vector2(14, 8), "open_sides":["south"],                      "floor_y":f3, "ceiling_y":f3+3.0},
		{"name":"F3_BriefingRoom",    "position":Vector3( 25,f3, 4.0), "size":Vector2(12, 8), "open_sides":["north"],                      "floor_y":f3, "ceiling_y":f3+3.0},
	]

# ── Room shells ───────────────────────────────────────────────────────────────

func _build_room_shells() -> void:
	for spec in _get_station_room_specs():
		_create_station_room_shell(spec)

func _create_station_room_shell(spec: Dictionary) -> void:
	var room_name: String = String(spec.get("name", "Room"))
	var center: Vector3  = _dict_vector3(spec, "position", Vector3.ZERO)
	var room_size: Vector2 = _dict_vector2(spec, "size", Vector2(8.0, 8.0))
	var floor_y: float   = float(spec.get("floor_y", center.y))
	var ceiling_y: float = float(spec.get("ceiling_y", floor_y + 3.0))
	var open_sides: Array = _dict_array(spec, "open_sides")
	var railing_sides: Array = _dict_array(spec, "railing_sides")
	var floor_color: Color = Color(0.08, 0.095, 0.105)
	if floor_y < -1.0:
		floor_color = Color(0.075, 0.082, 0.078)
	elif floor_y > 2.0:
		floor_color = Color(0.085, 0.095, 0.112)
	_csg_box("%sFloorPlate" % room_name, Vector3(center.x, floor_y + 0.015, center.z), Vector3(room_size.x, 0.03, room_size.y), floor_color)
	_csg_box("%sCeilingSlab" % room_name, Vector3(center.x, ceiling_y - 0.015, center.z), Vector3(room_size.x, 0.03, room_size.y), Color(0.062, 0.076, 0.084))
	var wall_height: float = ceiling_y - floor_y
	var wall_y: float = floor_y + wall_height * 0.5
	var door_w: float = 2.4
	var door_h: float = min(2.2, wall_height - 0.2)
	var lintel_h: float = wall_height - door_h
	for side in ["north", "south"]:
		var wall_z: float = center.z - room_size.y * 0.5 if side == "north" else center.z + room_size.y * 0.5
		if not open_sides.has(side):
			_create_structural_wall("%s%sWall" % [room_name, side.capitalize()], Vector3(center.x, wall_y, wall_z), Vector3(room_size.x, wall_height, 0.28))
		else:
			var half_door: float = door_w * 0.5
			var left_w: float = (room_size.x * 0.5) - half_door
			if left_w > 0.1:
				_create_structural_wall("%s%sWallL" % [room_name, side.capitalize()], Vector3(center.x - half_door - left_w * 0.5, wall_y, wall_z), Vector3(left_w, wall_height, 0.28))
				_create_structural_wall("%s%sWallR" % [room_name, side.capitalize()], Vector3(center.x + half_door + left_w * 0.5, wall_y, wall_z), Vector3(left_w, wall_height, 0.28))
			if lintel_h > 0.05:
				_create_structural_wall("%s%sLintel" % [room_name, side.capitalize()], Vector3(center.x, floor_y + door_h + lintel_h * 0.5, wall_z), Vector3(door_w, lintel_h, 0.28))
	for side in ["west", "east"]:
		var wall_x: float = center.x - room_size.x * 0.5 if side == "west" else center.x + room_size.x * 0.5
		if not open_sides.has(side):
			_create_structural_wall("%s%sWall" % [room_name, side.capitalize()], Vector3(wall_x, wall_y, center.z), Vector3(0.28, wall_height, room_size.y))
		else:
			var half_door: float = door_w * 0.5
			var front_w: float = (room_size.y * 0.5) - half_door
			if front_w > 0.1:
				_create_structural_wall("%s%sWallF" % [room_name, side.capitalize()], Vector3(wall_x, wall_y, center.z - half_door - front_w * 0.5), Vector3(0.28, wall_height, front_w))
				_create_structural_wall("%s%sWallB" % [room_name, side.capitalize()], Vector3(wall_x, wall_y, center.z + half_door + front_w * 0.5), Vector3(0.28, wall_height, front_w))
			if lintel_h > 0.05:
				_create_structural_wall("%s%sLintel" % [room_name, side.capitalize()], Vector3(wall_x, floor_y + door_h + lintel_h * 0.5, center.z), Vector3(0.28, lintel_h, door_w))
	for side_value in railing_sides:
		_create_station_railing("%sRailing_%s" % [room_name, String(side_value)], center, room_size, floor_y, String(side_value))

func _create_structural_wall(wall_name: String, world_position: Vector3, size: Vector3) -> void:
	_csg_box(wall_name, world_position, size, Color(0.12, 0.145, 0.158))

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
		_csg_box("%sPost%d" % [rail_name, index], post_position, Vector3(0.08, 1.0, 0.08), Color(0.22, 0.42, 0.43))

# ── Stairwells & vertical connections ────────────────────────────────────────

func _build_station_vertical_connections() -> void:
	var floor_h := 4.2
	var run := 8.0
	var ramp_len := sqrt(run * run + floor_h * floor_h)
	var ramp_angle := atan2(floor_h, run)
	var grate_col := Color(0.16, 0.18, 0.18)
	var wall_col := Color(0.08, 0.10, 0.11)
	for stair_side_raw in [-1, 1]:
		var stair_side: int = int(stair_side_raw)
		var sx: float = 35.0 if stair_side > 0 else -29.0
		var prefix: String = "WStair" if stair_side < 0 else "EStair"
		_csg_box("%sWallOuter" % prefix, Vector3(sx + stair_side * 2.1, floor_h * 1.5, 4.0), Vector3(0.28, floor_h * 3.0 + 2.0, 22.0), wall_col)
		for flight in range(3):
			var y_base: float = flight * floor_h
			var go_south: bool = (flight % 2 == 0)
			var z_from: float = 2.0 if go_south else 10.0
			var z_to: float   = 10.0 if go_south else 2.0
			var cx: float = sx
			var cy: float = y_base + floor_h * 0.5
			var cz: float = (z_from + z_to) * 0.5
			var angle: float = -ramp_angle if go_south else ramp_angle
			var ramp := _csg_box("%sRamp%d" % [prefix, flight], Vector3(cx, cy, cz), Vector3(3.2, 0.22, ramp_len), grate_col)
			ramp.rotation.x = angle
			var z_min: float = minf(z_from, z_to) - 0.15
			var z_max: float = maxf(z_from, z_to) + 0.15
			_create_structural_wall("%sShaftN%d" % [prefix, flight], Vector3(cx, cy, z_min), Vector3(4.2, floor_h + 1.0, 0.28))
			_create_structural_wall("%sShaftS%d" % [prefix, flight], Vector3(cx, cy, z_max), Vector3(4.2, floor_h + 1.0, 0.28))
	var ladder_col := Color(0.14, 0.18, 0.16)
	for ladder_flight in range(3):
		var y_base: float = ladder_flight * floor_h
		var lean_z: float = 0.6
		var ladder := _csg_box("MaintLadder%d" % ladder_flight,
			Vector3(0.0, y_base + floor_h * 0.5, -31.0),
			Vector3(1.4, 0.14, sqrt(lean_z * lean_z + floor_h * floor_h)), ladder_col)
		ladder.rotation.x = -atan2(floor_h, lean_z)
		_create_structural_wall("LadderShaftW%d" % ladder_flight, Vector3(-0.9, y_base + floor_h * 0.5, -31.0), Vector3(0.18, floor_h + 0.4, 2.0))
		_create_structural_wall("LadderShaftE%d" % ladder_flight, Vector3( 0.9, y_base + floor_h * 0.5, -31.0), Vector3(0.18, floor_h + 0.4, 2.0))
	_create_structural_wall("ElevShaftN", Vector3(0.0, floor_h * 1.5,  2.2), Vector3(3.0, floor_h * 3.0 + 2.0, 0.18))
	_create_structural_wall("ElevShaftS", Vector3(0.0, floor_h * 1.5, -2.2), Vector3(3.0, floor_h * 3.0 + 2.0, 0.18))
	_create_structural_wall("ElevShaftW", Vector3(-1.6, floor_h * 1.5, 0.0), Vector3(0.18, floor_h * 3.0 + 2.0, 4.6))
	_create_structural_wall("ElevShaftE", Vector3( 1.6, floor_h * 1.5, 0.0), Vector3(0.18, floor_h * 3.0 + 2.0, 4.6))

# ── Outer hull ────────────────────────────────────────────────────────────────

func _build_outer_hull() -> void:
	var hc := Color(0.13, 0.15, 0.17)
	var rc := Color(0.09, 0.10, 0.11)
	_csg_box("StationGround", Vector3(2.0, -0.1, -5.5), Vector3(70.6, 0.2, 61.6), Color(0.082, 0.092, 0.100))
	_create_hull_wall_ns("HullNorthAirlock", -36.2, -33.2, 37.2, -0.3, 4.2, hc,
		[{"x_center": -1.1, "width": 1.1, "height": 0.85, "y_center": 2.55},
		 {"x_center":  1.1, "width": 1.1, "height": 0.85, "y_center": 2.55}])
	_create_hull_wall_ew("HullWestAirlock", -33.2, -36.2, -20.2, -0.3, 4.2, hc, [])
	_create_hull_wall_ew("HullEastAirlock",  37.2, -36.2, -20.2, -0.3, 4.2, hc, [])
	_csg_box("HullExtRoof", Vector3(2.0, 4.32, -28.2), Vector3(70.6, 0.24, 16.0), rc)
	_create_hull_wall_ns("HullNorthMain", -20.2, -33.2, 37.2, -0.3, 15.9, hc,
		[{"x_center": -19.0, "width": 4.5, "height": 2.4, "y_center": 14.2},
		 {"x_center":  -5.5, "width": 4.5, "height": 2.4, "y_center": 14.2},
		 {"x_center":   9.0, "width": 4.5, "height": 2.4, "y_center": 14.2},
		 {"x_center":  24.0, "width": 4.5, "height": 2.4, "y_center": 14.2}])
	_create_hull_wall_ns("HullSouth",   25.2, -33.2, 37.2, -0.3, 15.9, hc, [])
	_create_hull_wall_ew("HullWestMain", -33.2, -20.2, 25.2, -0.3, 15.9, hc,
		[{"z_center": -8.5, "width": 3.0, "height": 2.0, "y_center": 5.6}])
	_create_hull_wall_ew("HullEastMain",  37.2, -20.2, 25.2, -0.3, 15.9, hc,
		[{"z_center": -8.5, "width": 3.0, "height": 2.0, "y_center": 5.6}])
	_csg_box("HullMainRoof", Vector3(2.0, 16.05, 2.5), Vector3(70.6, 0.3, 45.6), rc)
	var hull_rib_color := Color(0.10, 0.12, 0.135)
	for floor_y in [4.22, 8.44, 12.66]:
		_csg_box("RibN%d" % int(floor_y), Vector3(2.0, floor_y, -20.2), Vector3(70.6, 0.18, 0.42), hull_rib_color)
		_csg_box("RibS%d" % int(floor_y), Vector3(2.0, floor_y, 25.2), Vector3(70.6, 0.18, 0.42), hull_rib_color)
		_csg_box("RibW%d" % int(floor_y), Vector3(-33.2, floor_y, 2.5), Vector3(0.42, 0.18, 45.6), hull_rib_color)
		_csg_box("RibE%d" % int(floor_y), Vector3(37.2, floor_y, 2.5), Vector3(0.42, 0.18, 45.6), hull_rib_color)
	var pillar_color := Color(0.18, 0.20, 0.22)
	var corner_xs := [-33.2, 37.2]
	var corner_zs := [-36.2, -20.2, 25.2]
	var pi_idx := 0
	for px in corner_xs:
		for pz in corner_zs:
			var ph: float = 4.2 if pz == -36.2 or pz == -20.2 else 16.2
			var pcy := ph * 0.5 - 0.3
			_csg_box("Pillar%d" % pi_idx, Vector3(px, pcy, pz), Vector3(0.55, ph, 0.55), pillar_color)
			pi_idx += 1

func _create_hull_wall_ns(wall_name: String, wall_z: float, x_min: float, x_max: float,
		y_min: float, y_max: float, color: Color, windows: Array[Dictionary]) -> void:
	var full_w := x_max - x_min
	var full_h := y_max - y_min
	var cx := (x_min + x_max) * 0.5
	var cy := (y_min + y_max) * 0.5
	if windows.is_empty():
		_csg_box(wall_name, Vector3(cx, cy, wall_z), Vector3(full_w, full_h, 0.38), color)
		return
	var win_y_c := float(windows[0]["y_center"])
	var win_h := float(windows[0]["height"])
	var band_bot := win_y_c - win_h * 0.5
	var band_top := win_y_c + win_h * 0.5
	if band_bot > y_min + 0.05:
		var h := band_bot - y_min
		_csg_box(wall_name + "_Lo", Vector3(cx, y_min + h * 0.5, wall_z), Vector3(full_w, h, 0.38), color)
	if band_top < y_max - 0.05:
		var h := y_max - band_top
		_csg_box(wall_name + "_Hi", Vector3(cx, band_top + h * 0.5, wall_z), Vector3(full_w, h, 0.38), color)
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
			_csg_box(wall_name + "_B%d" % i, Vector3(prev_x + sw * 0.5, band_cy, wall_z), Vector3(sw, band_h, 0.38), color)
		_create_window_panel(wall_name + "_W%d" % i, Vector3(wx, band_cy, wall_z), Vector2(ww, band_h), true)
		prev_x = right_edge
	if x_max - prev_x > 0.05:
		var sw := x_max - prev_x
		_csg_box(wall_name + "_BE", Vector3(prev_x + sw * 0.5, band_cy, wall_z), Vector3(sw, band_h, 0.38), color)

func _create_hull_wall_ew(wall_name: String, wall_x: float, z_min: float, z_max: float,
		y_min: float, y_max: float, color: Color, windows: Array[Dictionary]) -> void:
	var full_d := z_max - z_min
	var full_h := y_max - y_min
	var cz := (z_min + z_max) * 0.5
	var cy := (y_min + y_max) * 0.5
	if windows.is_empty():
		_csg_box(wall_name, Vector3(wall_x, cy, cz), Vector3(0.38, full_h, full_d), color)
		return
	var win_y_c := float(windows[0]["y_center"])
	var win_h := float(windows[0]["height"])
	var band_bot := win_y_c - win_h * 0.5
	var band_top := win_y_c + win_h * 0.5
	if band_bot > y_min + 0.05:
		var h := band_bot - y_min
		_csg_box(wall_name + "_Lo", Vector3(wall_x, y_min + h * 0.5, cz), Vector3(0.38, h, full_d), color)
	if band_top < y_max - 0.05:
		var h := y_max - band_top
		_csg_box(wall_name + "_Hi", Vector3(wall_x, band_top + h * 0.5, cz), Vector3(0.38, h, full_d), color)
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
			_csg_box(wall_name + "_B%d" % i, Vector3(wall_x, band_cy, prev_z + sd * 0.5), Vector3(0.38, band_h, sd), color)
		_create_window_panel(wall_name + "_W%d" % i, Vector3(wall_x, band_cy, wz), Vector2(ww, band_h), false)
		prev_z = right_edge
	if z_max - prev_z > 0.05:
		var sd := z_max - prev_z
		_csg_box(wall_name + "_BE", Vector3(wall_x, band_cy, prev_z + sd * 0.5), Vector3(0.38, band_h, sd), color)

func _create_window_panel(win_name: String, center: Vector3, size: Vector2, is_ns: bool) -> void:
	var fc := Color(0.24, 0.28, 0.31)
	var ft := 0.13
	var fd := 0.38
	var top_s: Vector3 = Vector3(size.x + ft * 2.0, ft, fd) if is_ns else Vector3(fd, ft, size.x + ft * 2.0)
	_csg_box(win_name + "FT", center + Vector3(0, size.y * 0.5 + ft * 0.5, 0), top_s, fc)
	_csg_box(win_name + "FB", center + Vector3(0, -(size.y * 0.5 + ft * 0.5), 0), top_s, fc)
	var side_s: Vector3 = Vector3(ft, size.y, fd) if is_ns else Vector3(fd, size.y, ft)
	var off_x: float = (size.x * 0.5 + ft * 0.5) if is_ns else 0.0
	var off_z: float = 0.0 if is_ns else (size.x * 0.5 + ft * 0.5)
	_csg_box(win_name + "FL", center + Vector3(-off_x, 0, -off_z), side_s, fc)
	_csg_box(win_name + "FR", center + Vector3( off_x, 0,  off_z), side_s, fc)
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
	mat.emission_enabled = true
	mat.emission = Color(0.32, 0.62, 0.85)
	mat.emission_energy_multiplier = 0.10
	glass.material_override = mat
	add_child(glass)

# ── Wall detail pass ──────────────────────────────────────────────────────────

func _build_wall_detail_pass() -> void:
	var trim_c := Color(0.20, 0.23, 0.26)
	var base_c := Color(0.08, 0.10, 0.12)
	var ceil_c := Color(0.75, 0.96, 1.00)
	for spec in _get_station_room_specs():
		var pos: Vector3 = spec["position"]
		var sz: Vector2 = spec["size"]
		var cx := pos.x;  var fy := pos.y;  var cz := pos.z
		var sx := sz.x;   var sd := sz.y
		var rn: String = spec["name"]
		_add_detail_strip(rn+"BN", Vector3(cx, fy+0.06, cz-sd*0.5+0.04), Vector3(sx-0.06, 0.12, 0.06), base_c)
		_add_detail_strip(rn+"BS", Vector3(cx, fy+0.06, cz+sd*0.5-0.04), Vector3(sx-0.06, 0.12, 0.06), base_c)
		_add_detail_strip(rn+"BW", Vector3(cx-sx*0.5+0.04, fy+0.06, cz), Vector3(0.06, 0.12, sd-0.06), base_c)
		_add_detail_strip(rn+"BE", Vector3(cx+sx*0.5-0.04, fy+0.06, cz), Vector3(0.06, 0.12, sd-0.06), base_c)
		_add_detail_strip(rn+"CN", Vector3(cx, fy+2.90, cz-sd*0.5+0.04), Vector3(sx-0.06, 0.09, 0.06), trim_c)
		_add_detail_strip(rn+"CS", Vector3(cx, fy+2.90, cz+sd*0.5-0.04), Vector3(sx-0.06, 0.09, 0.06), trim_c)
		_add_detail_strip(rn+"CW", Vector3(cx-sx*0.5+0.04, fy+2.90, cz), Vector3(0.06, 0.09, sd-0.06), trim_c)
		_add_detail_strip(rn+"CE", Vector3(cx+sx*0.5-0.04, fy+2.90, cz), Vector3(0.06, 0.09, sd-0.06), trim_c)
		_add_detail_strip(rn+"PN", Vector3(cx, fy+1.35, cz-sd*0.5+0.02), Vector3(sx, 0.05, 0.04), trim_c.lightened(0.1))
		_add_detail_strip(rn+"PS", Vector3(cx, fy+1.35, cz+sd*0.5-0.02), Vector3(sx, 0.05, 0.04), trim_c.lightened(0.1))
		_add_detail_strip(rn+"PW", Vector3(cx-sx*0.5+0.02, fy+1.35, cz), Vector3(0.04, 0.05, sd), trim_c.lightened(0.1))
		_add_detail_strip(rn+"PE", Vector3(cx+sx*0.5-0.02, fy+1.35, cz), Vector3(0.04, 0.05, sd), trim_c.lightened(0.1))
		var is_wide := sx >= sd
		var strip_l: float = (sx - 0.6) if is_wide else (sd - 0.6)
		var strip_s: Vector3 = Vector3(strip_l, 0.06, 0.14) if is_wide else Vector3(0.14, 0.06, strip_l)
		_add_emissive_strip(rn+"CL", Vector3(cx, fy+2.96, cz), strip_s, ceil_c, 1.15)
	_add_screen_panel("ScrComm",  Vector3(-19.0, 13.85, -19.7), Vector2(3.2, 1.7), false, Color(0.12, 0.88, 0.62))
	_add_screen_panel("ScrCmd",   Vector3( -4.5, 13.85, -19.7), Vector2(3.2, 1.7), false, Color(0.12, 0.62, 0.98))
	_add_screen_panel("ScrReact", Vector3(  9.5, 13.85, -19.7), Vector2(3.2, 1.7), false, Color(0.98, 0.52, 0.12))
	_add_screen_panel("ScrRCore", Vector3( 24.0, 13.85, -19.7), Vector2(3.2, 1.7), false, Color(0.98, 0.22, 0.12))
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
	add_child(mi)

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
	add_child(mi)

func _add_screen_panel(panel_name: String, pos: Vector3, size: Vector2, is_ew: bool, color: Color) -> void:
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
	add_child(bezel)
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
	add_child(screen)

# ── Mars exterior ─────────────────────────────────────────────────────────────

func _build_exterior() -> void:
	_create_exterior_box("MarsSurface", Vector3(2.0, -0.92, -5.5), Vector3(650.0, 0.5, 650.0), Color(0.36, 0.17, 0.09))
	for i in range(8):
		var angle := i * TAU / 8.0
		var dist := randf_range(48.0, 80.0)
		var px := 2.0 + cos(angle) * dist
		var pz := -5.5 + sin(angle) * dist
		var pw := randf_range(14.0, 26.0)
		_create_exterior_box("DustPatch%d" % i, Vector3(px, -0.7, pz), Vector3(pw, 0.18, pw * 0.75), Color(0.26, 0.11, 0.06))
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
		add_child(cyl)
	_create_exterior_box("MesaA",    Vector3(-305.0, 36.0, -198.0), Vector3(82.0, 76.0, 62.0), Color(0.30, 0.13, 0.07))
	_create_exterior_box("MesaATop", Vector3(-305.0, 76.5, -198.0), Vector3(58.0,  9.0, 46.0), Color(0.22, 0.09, 0.05))
	_create_exterior_box("MesaB",    Vector3( 325.0, 19.0, -182.0), Vector3(52.0, 42.0, 68.0), Color(0.27, 0.11, 0.06))
	_create_exterior_box("MesaBTop", Vector3( 325.0, 41.5, -182.0), Vector3(38.0,  6.0, 52.0), Color(0.20, 0.08, 0.04))

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
	add_child(mi)
