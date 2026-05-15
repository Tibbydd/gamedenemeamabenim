extends Node
class_name FacilityProgression

signal door_state_changed(door_id: String, state: String)

# Later system: permanent progression should alter the facility, not inflate survivor stats.
# Examples: restored armories, repaired elevators, partial lighting, cache access,
# security rooms, defense systems, and safer extraction routes.

const DOOR_OPEN := "open"
const DOOR_LOCKED := "locked"
const DOOR_JAMMED := "jammed"
const DOOR_SEALED := "sealed"
const ACCESS_FRESH := "fresh"
const ACCESS_SCARRED := "scarred"
const ACCESS_COMPROMISED := "compromised"
const ACCESS_BLOCKED := "blocked"

var unlocked_facility_flags: Dictionary = {}
var rooms: Dictionary = {}
var doors: Dictionary = {}
var access_points: Dictionary = {}
var hidden_routes: Dictionary = {}
var lost_survivor_sites: Array[Dictionary] = []
var survivor_entries: int = 0

func unlock_flag(flag_name: String) -> void:
	unlocked_facility_flags[flag_name] = true

func is_unlocked(flag_name: String) -> bool:
	return bool(unlocked_facility_flags.get(flag_name, false))

func register_room(room_id: String, entry_position: Vector3, unexplored_weight: float = 4.0, explored_weight: float = 0.8) -> void:
	if rooms.has(room_id):
		return
	rooms[room_id] = {
		"entry_position": entry_position,
		"explored": false,
		"visits": 0,
		"unexplored_weight": unexplored_weight,
		"explored_weight": explored_weight
	}

func mark_room_explored(room_id: String) -> void:
	if not rooms.has(room_id):
		return
	var room: Dictionary = rooms[room_id]
	room["explored"] = true
	room["visits"] = int(room["visits"]) + 1
	rooms[room_id] = room

func choose_successor_entry() -> Dictionary:
	var total_weight := 0.0
	for room_id in rooms.keys():
		if not _room_has_available_entry(String(room_id)):
			continue
		var room: Dictionary = rooms[room_id]
		total_weight += _room_weight(room)
	if total_weight <= 0.0:
		return _fallback_successor_entry()
	var roll := randf() * total_weight
	for room_id in rooms.keys():
		if not _room_has_available_entry(String(room_id)):
			continue
		var room: Dictionary = rooms[room_id]
		roll -= _room_weight(room)
		if roll <= 0.0:
			return {
				"room_id": room_id,
				"entry_position": room["entry_position"],
				"explored": room["explored"],
				"visits": room["visits"]
			}
	return {}

func _room_has_available_entry(room_id: String) -> bool:
	for access_id in access_points.keys():
		var access: Dictionary = access_points[access_id]
		if String(access["room_id"]) != room_id:
			continue
		if String(access["state"]) == ACCESS_BLOCKED:
			return false
	for door_id in doors.keys():
		var door: Dictionary = doors[door_id]
		if String(door["room_id"]) == room_id and String(door["state"]) == DOOR_SEALED:
			return false
	return true

func _fallback_successor_entry() -> Dictionary:
	for access_id in access_points.keys():
		var access: Dictionary = access_points[access_id]
		if String(access["kind"]) != "crawlspace":
			continue
		var room_id := String(access["room_id"])
		if rooms.has(room_id):
			var room: Dictionary = rooms[room_id]
			return {
				"room_id": room_id,
				"entry_position": room["entry_position"],
				"explored": room["explored"],
				"visits": room["visits"]
			}
	return {}

func _room_weight(room: Dictionary) -> float:
	var memory_progress := get_station_memory_progress()
	if bool(room["explored"]):
		return lerp(float(room["explored_weight"]), 2.4, memory_progress)
	return lerp(float(room["unexplored_weight"]), 2.0, memory_progress)

func get_station_memory_progress() -> float:
	var room_count := max(1, rooms.size())
	return clamp(float(survivor_entries) / float(room_count * 2), 0.0, 1.0)

func record_survivor_entry(room_id: String) -> void:
	survivor_entries += 1
	mark_room_explored(room_id)

func register_door(door_id: String, connected_room_id: String, state: String = DOOR_LOCKED) -> void:
	if doors.has(door_id):
		return
	doors[door_id] = {
		"room_id": connected_room_id,
		"state": state,
		"jam_count": 0
	}

func jam_door(door_id: String) -> String:
	if not doors.has(door_id):
		return DOOR_JAMMED
	var door: Dictionary = doors[door_id]
	var jam_count := int(door["jam_count"]) + 1
	door["jam_count"] = jam_count
	door["state"] = DOOR_SEALED if jam_count >= 2 else DOOR_JAMMED
	doors[door_id] = door
	door_state_changed.emit(door_id, String(door["state"]))
	return String(door["state"])

func get_door_state(door_id: String) -> String:
	if not doors.has(door_id):
		return DOOR_LOCKED
	return String(doors[door_id]["state"])

func set_door_state(door_id: String, state: String) -> void:
	if not doors.has(door_id):
		register_door(door_id, "", state)
		door_state_changed.emit(door_id, state)
		return
	var door: Dictionary = doors[door_id]
	door["state"] = state
	doors[door_id] = door
	door_state_changed.emit(door_id, state)

func register_access_point(access_id: String, connected_room_id: String, access_kind: String, state: String = ACCESS_FRESH) -> void:
	if access_points.has(access_id):
		return
	access_points[access_id] = {
		"room_id": connected_room_id,
		"kind": access_kind,
		"state": state,
		"use_count": 0
	}

func scar_access_point(access_id: String) -> String:
	if not access_points.has(access_id):
		return ACCESS_SCARRED
	var access: Dictionary = access_points[access_id]
	var use_count := int(access["use_count"]) + 1
	access["use_count"] = use_count
	if use_count >= 3:
		access["state"] = ACCESS_BLOCKED
	elif use_count == 2:
		access["state"] = ACCESS_COMPROMISED
	else:
		access["state"] = ACCESS_SCARRED
	access_points[access_id] = access
	return String(access["state"])

func get_access_state(access_id: String) -> String:
	if not access_points.has(access_id):
		return ACCESS_FRESH
	return String(access_points[access_id]["state"])

func record_lost_survivor(position: Vector3, room_id: String, survivor_index: int, reason: String) -> Dictionary:
	var record := {
		"id": "lost_survivor_%d" % survivor_index,
		"position": position,
		"room_id": room_id,
		"survivor_index": survivor_index,
		"reason": reason,
		"recovered": false,
		"known": get_station_memory_progress() > 0.7
	}
	lost_survivor_sites.append(record)
	return record

func register_hidden_route(route_id: String, route_kind: String, start_room_id: String, end_room_id: String, description: String) -> void:
	if hidden_routes.has(route_id):
		return
	hidden_routes[route_id] = {
		"kind": route_kind,
		"start_room_id": start_room_id,
		"end_room_id": end_room_id,
		"description": description,
		"discovered": false
	}

func mark_route_discovered(route_id: String) -> void:
	if not hidden_routes.has(route_id):
		return
	var route: Dictionary = hidden_routes[route_id]
	route["discovered"] = true
	hidden_routes[route_id] = route

func to_save_dict() -> Dictionary:
	return {
		"flags": unlocked_facility_flags.duplicate(true),
		"rooms": _pack_vector_dict(rooms, ["entry_position"]),
		"doors": doors.duplicate(true),
		"access_points": access_points.duplicate(true),
		"hidden_routes": hidden_routes.duplicate(true),
		"lost_survivor_sites": _pack_vector_array(lost_survivor_sites, ["position"]),
		"survivor_entries": survivor_entries
	}

func load_save_dict(data: Dictionary) -> void:
	unlocked_facility_flags = data.get("flags", {}).duplicate(true)
	rooms = _unpack_vector_dict(data.get("rooms", {}), ["entry_position"])
	doors = data.get("doors", {}).duplicate(true)
	access_points = data.get("access_points", {}).duplicate(true)
	hidden_routes = data.get("hidden_routes", {}).duplicate(true)
	lost_survivor_sites = _unpack_vector_array(data.get("lost_survivor_sites", []), ["position"])
	survivor_entries = int(data.get("survivor_entries", 0))

func _pack_vector_dict(source: Dictionary, vector_keys: Array[String]) -> Dictionary:
	var packed := {}
	for key in source.keys():
		var entry: Dictionary = source[key].duplicate(true)
		for vector_key in vector_keys:
			if entry.has(vector_key) and entry[vector_key] is Vector3:
				var point: Vector3 = entry[vector_key]
				entry[vector_key] = [point.x, point.y, point.z]
		packed[key] = entry
	return packed

func _unpack_vector_dict(source: Dictionary, vector_keys: Array[String]) -> Dictionary:
	var unpacked := {}
	for key in source.keys():
		var entry: Dictionary = source[key].duplicate(true)
		for vector_key in vector_keys:
			if entry.has(vector_key) and entry[vector_key] is Array:
				var array: Array = entry[vector_key]
				if array.size() >= 3:
					entry[vector_key] = Vector3(float(array[0]), float(array[1]), float(array[2]))
		unpacked[key] = entry
	return unpacked

func _pack_vector_array(source: Array[Dictionary], vector_keys: Array[String]) -> Array[Dictionary]:
	var packed: Array[Dictionary] = []
	for item in source:
		var entry := item.duplicate(true)
		for vector_key in vector_keys:
			if entry.has(vector_key) and entry[vector_key] is Vector3:
				var point: Vector3 = entry[vector_key]
				entry[vector_key] = [point.x, point.y, point.z]
		packed.append(entry)
	return packed

func _unpack_vector_array(source: Array, vector_keys: Array[String]) -> Array[Dictionary]:
	var unpacked: Array[Dictionary] = []
	for item in source:
		if not (item is Dictionary):
			continue
		var entry: Dictionary = item.duplicate(true)
		for vector_key in vector_keys:
			if entry.has(vector_key) and entry[vector_key] is Array:
				var array: Array = entry[vector_key]
				if array.size() >= 3:
					entry[vector_key] = Vector3(float(array[0]), float(array[1]), float(array[2]))
		unpacked.append(entry)
	return unpacked
