extends Node
class_name SectorPowerSystem

signal sector_power_changed(sector_id: String, powered: bool, method_id: String)

var sectors: Dictionary = {}

func register_sector(sector_id: String, display_name: String, starts_powered: bool = false) -> void:
	if sectors.has(sector_id):
		return
	var reasons := StationSystemsCatalog.get_light_failure_reasons()
	var reason: Dictionary = reasons[randi() % reasons.size()]
	sectors[sector_id] = {
		"display_name": display_name,
		"powered": starts_powered,
		"failure_reason": reason,
		"restore_history": []
	}

func restore_sector(sector_id: String, method_id: String) -> bool:
	if not sectors.has(sector_id):
		return false
	var sector: Dictionary = sectors[sector_id]
	sector["powered"] = true
	var history: Array = sector["restore_history"]
	history.append(method_id)
	sector["restore_history"] = history
	sectors[sector_id] = sector
	sector_power_changed.emit(sector_id, true, method_id)
	return true

func cut_sector_power(sector_id: String, reason_id: String = "unknown") -> void:
	if not sectors.has(sector_id):
		return
	var sector: Dictionary = sectors[sector_id]
	sector["powered"] = false
	sector["failure_reason"] = {"id": reason_id, "label": reason_id.replace("_", " ")}
	sectors[sector_id] = sector
	sector_power_changed.emit(sector_id, false, reason_id)

func is_powered(sector_id: String) -> bool:
	if not sectors.has(sector_id):
		return false
	return bool(sectors[sector_id]["powered"])

func get_failure_label(sector_id: String) -> String:
	if not sectors.has(sector_id):
		return "unknown outage"
	var reason: Dictionary = sectors[sector_id]["failure_reason"]
	return String(reason.get("label", "unknown outage"))

func get_restore_methods() -> Array[Dictionary]:
	return StationSystemsCatalog.get_light_restore_methods()
