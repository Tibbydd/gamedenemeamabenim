extends Node
class_name StationRouteSystem

signal floor_changed(floor_index: int, route_id: String)

var current_floor: int = 0
var final_escape_floor: int = 6
var discovered_routes: Dictionary = {}
var route_catalog: Array[Dictionary] = []

func _ready() -> void:
	route_catalog = StationSystemsCatalog.get_floor_routes()

func discover_route(route_id: String) -> void:
	discovered_routes[route_id] = true

func can_use_route(route_id: String) -> bool:
	var public_routes := ["main_stairwell", "service_elevator"]
	return bool(discovered_routes.get(route_id, false)) or public_routes.has(route_id)

func use_route(route_id: String) -> bool:
	if not can_use_route(route_id):
		return false
	for route in route_catalog:
		if String(route["id"]) == route_id:
			current_floor = clamp(current_floor + int(route["delta_floor"]), 0, final_escape_floor)
			floor_changed.emit(current_floor, route_id)
			return true
	return false

func get_route_summary() -> Array[String]:
	var summary: Array[String] = []
	for route in route_catalog:
		summary.append("%s: %s floors / %s" % [route["label"], str(route["delta_floor"]), route["risk"]])
	return summary
