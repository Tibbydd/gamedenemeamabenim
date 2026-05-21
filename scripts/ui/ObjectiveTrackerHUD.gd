extends Control
class_name ObjectiveTrackerHUD

var objectives: Array = []
var player_position: Vector3 = Vector3.ZERO
var extraction_active: bool = false
var extraction_position: Vector3 = Vector3.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(430.0, 116.0)

func set_objectives(new_objectives: Array) -> void:
	objectives = new_objectives.duplicate(true)
	queue_redraw()

func set_player_position(new_position: Vector3) -> void:
	player_position = new_position
	queue_redraw()

func set_extraction_available(world_position: Vector3) -> void:
	extraction_active = true
	extraction_position = world_position
	queue_redraw()

func get_objective_count() -> int:
	return objectives.size()

func get_done_count() -> int:
	var done_count: int = 0
	for objective_value in objectives:
		if objective_value is Dictionary:
			var objective: Dictionary = objective_value
			if String(objective.get("status", "pending")) == "done":
				done_count += 1
	return done_count

func _draw() -> void:
	var font: Font = get_theme_default_font()
	if not font:
		return
	var font_size: int = 13
	var height: float = 30.0 + float(objectives.size()) * 26.0
	if extraction_active:
		height += 22.0
	draw_rect(Rect2(Vector2.ZERO, Vector2(420.0, height)), Color(0.015, 0.028, 0.032, 0.62), true)
	draw_rect(Rect2(Vector2.ZERO, Vector2(420.0, height)), Color(0.12, 0.72, 0.68, 0.36), false, 1.0)
	draw_string(font, Vector2(14.0, 18.0), "MISSION", HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color(0.56, 1.0, 0.9, 0.92))
	var row_y: float = 39.0
	for objective_value in objectives:
		if not (objective_value is Dictionary):
			continue
		var objective: Dictionary = objective_value
		var objective_type: String = String(objective.get("type", "purge_node"))
		var status: String = String(objective.get("status", "pending"))
		var color: Color = _status_color(status)
		_draw_objective_icon(Vector2(16.0, row_y - 7.0), objective_type, color)
		var label: String = String(objective.get("label", "Objective"))
		var sector_label: String = String(objective.get("sector_label", "Sector"))
		var position: Vector3 = _dictionary_vector3(objective, "position", player_position)
		var distance: int = int(round(player_position.distance_to(position)))
		var status_text: String = status.to_upper()
		if status == "done":
			status_text = "DONE"
		elif status == "active":
			status_text = "ACTIVE"
		var line: String = "%s  %s / %dm / %s" % [label.to_upper(), sector_label.to_upper(), distance, status_text]
		draw_string(font, Vector2(34.0, row_y), line, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)
		if status == "active":
			var progress: float = clamp(float(objective.get("progress", 0.0)), 0.0, 1.0)
			var bar_rect: Rect2 = Rect2(Vector2(34.0, row_y + 6.0), Vector2(90.0, 3.0))
			draw_rect(bar_rect, Color(0.1, 0.16, 0.16, 0.9), true)
			draw_rect(Rect2(bar_rect.position, Vector2(bar_rect.size.x * progress, bar_rect.size.y)), color, true)
		row_y += 26.0
	if extraction_active:
		_draw_extraction_icon(Vector2(16.0, row_y - 7.0), Color(0.18, 0.92, 1.0, 0.95))
		var extraction_distance: int = int(round(player_position.distance_to(extraction_position)))
		draw_string(font, Vector2(34.0, row_y), "EXTRACTION  %dm / LIVE" % extraction_distance, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color(0.32, 0.95, 1.0, 0.95))

func _status_color(status: String) -> Color:
	if status == "done":
		return Color(0.35, 1.0, 0.58, 0.95)
	if status == "active":
		return Color(1.0, 0.76, 0.28, 0.95)
	return Color(0.68, 0.92, 0.92, 0.82)

func _draw_objective_icon(center: Vector2, objective_type: String, color: Color) -> void:
	if objective_type == "restore_power":
		var bolt: PackedVector2Array = PackedVector2Array([
			center + Vector2(2.0, -8.0),
			center + Vector2(-4.0, 1.0),
			center + Vector2(1.0, 1.0),
			center + Vector2(-2.0, 9.0),
			center + Vector2(7.0, -2.0),
			center + Vector2(1.0, -2.0)
		])
		draw_colored_polygon(bolt, color)
	elif objective_type == "uplink_terminal":
		draw_line(center + Vector2(0.0, 8.0), center + Vector2(0.0, -6.0), color, 2.0)
		draw_arc(center + Vector2(0.0, -3.0), 6.0, -2.5, -0.65, 12, color, 1.4)
		draw_arc(center + Vector2(0.0, -3.0), 6.0, -0.5, 2.5, 12, color, 1.4)
		draw_circle(center + Vector2(0.0, -7.0), 2.0, color)
	else:
		draw_circle(center, 8.0, color.darkened(0.35))
		draw_arc(center, 8.0, 0.0, TAU, 20, color, 1.5)
		draw_line(center + Vector2(-6.0, 0.0), center + Vector2(6.0, 0.0), color, 1.6)
		draw_line(center + Vector2(0.0, -6.0), center + Vector2(0.0, 6.0), color, 1.6)

func _draw_extraction_icon(center: Vector2, color: Color) -> void:
	var tri: PackedVector2Array = PackedVector2Array([
		center + Vector2(0.0, -9.0),
		center + Vector2(-8.0, 7.0),
		center + Vector2(8.0, 7.0),
		center + Vector2(0.0, -9.0)
	])
	draw_polyline(tri, color, 1.8, true)
	draw_circle(center, 3.0, color)

func _dictionary_vector3(source: Dictionary, key: String, fallback: Vector3) -> Vector3:
	var raw_value: Variant = source.get(key, fallback)
	if raw_value is Vector3:
		return raw_value
	return fallback
