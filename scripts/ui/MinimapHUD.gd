extends Control
class_name MinimapHUD

var player_pos: Vector3 = Vector3.ZERO
var player_yaw: float = 0.0
var objectives: Array = []
var extraction_pos: Vector3 = Vector3(9999.0, 0.0, 9999.0)
var player_floor: int = 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func update(pos: Vector3, yaw_value: float, objective_values: Array, extraction_position: Vector3) -> void:
	player_pos = pos
	player_yaw = yaw_value
	objectives = objective_values.duplicate(true)
	extraction_pos = extraction_position
	player_floor = -1 if pos.y < -1.5 else (1 if pos.y > 2.5 else 0)
	queue_redraw()

func _draw() -> void:
	var font: Font = get_theme_default_font()
	if not font:
		return
	var bounds: Rect2 = Rect2(Vector2.ZERO, size)
	draw_rect(bounds, Color(0.015, 0.028, 0.03, 0.78), true)
	draw_rect(bounds, Color(0.2, 0.92, 0.78, 0.75), false, 1.0)
	var floor_label: String = "GND"
	if player_floor < 0:
		floor_label = "SUB"
	elif player_floor > 0:
		floor_label = "UPR"
	draw_string(font, Vector2(6.0, 13.0), floor_label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 9, Color(0.48, 0.9, 0.82, 0.78))
	_draw_floor_rooms()
	_draw_objective_dots()
	_draw_player_triangle()

func _draw_floor_rooms() -> void:
	var room_color: Color = Color(0.2, 0.32, 0.3, 0.7)
	var rooms: Array[Dictionary] = []
	if player_floor == 0:
		rooms = [
			{"c": Vector2(0, -20), "s": Vector2(18, 14)},
			{"c": Vector2(-22, -20), "s": Vector2(10, 10)},
			{"c": Vector2(-22, -2), "s": Vector2(10, 10)},
			{"c": Vector2(22, -22), "s": Vector2(10, 8)},
			{"c": Vector2(0, -2), "s": Vector2(14, 10)},
			{"c": Vector2(22, 10), "s": Vector2(8, 8)}
		]
	elif player_floor < 0:
		rooms = [
			{"c": Vector2(-2, 8), "s": Vector2(22, 16)},
			{"c": Vector2(-18, 2), "s": Vector2(10, 8)},
			{"c": Vector2(14, -2), "s": Vector2(8, 10)}
		]
	else:
		rooms = [
			{"c": Vector2(2, -20), "s": Vector2(14, 10)},
			{"c": Vector2(2, -32), "s": Vector2(8, 8)},
			{"c": Vector2(-14, -20), "s": Vector2(10, 8)},
			{"c": Vector2(-14, -30), "s": Vector2(8, 6)}
		]
	for room in rooms:
		var raw_center: Variant = room.get("c", Vector2.ZERO)
		var center: Vector2 = raw_center if raw_center is Vector2 else Vector2.ZERO
		var raw_size: Variant = room.get("s", Vector2.ONE)
		var room_size: Vector2 = raw_size if raw_size is Vector2 else Vector2.ONE
		draw_rect(Rect2(_map_uv(center.x - room_size.x * 0.5, center.y - room_size.y * 0.5), room_size), room_color, false, 1.0)

func _draw_objective_dots() -> void:
	for objective_value in objectives:
		if not (objective_value is Dictionary):
			continue
		var objective: Dictionary = objective_value
		if String(objective.get("status", "pending")) == "done":
			continue
		var world_pos: Vector3 = _dictionary_vector3(objective, "position", Vector3.ZERO)
		draw_circle(_map_uv(world_pos.x, world_pos.z), 3.5, Color(1.0, 0.85, 0.25, 0.9))
	if extraction_pos.x < 9000.0:
		draw_circle(_map_uv(extraction_pos.x, extraction_pos.z), 5.0, Color(0.28, 1.0, 0.88, 1.0))

func _draw_player_triangle() -> void:
	var center: Vector2 = _map_uv(player_pos.x, player_pos.z)
	var points: PackedVector2Array = PackedVector2Array()
	for point in [Vector2(0, -5), Vector2(3, 4), Vector2(-3, 4)]:
		points.append(center + point.rotated(player_yaw))
	draw_colored_polygon(points, Color(1, 1, 1, 0.95))

func _map_uv(world_x: float, world_z: float) -> Vector2:
	return Vector2(50.0 + world_x, 50.0 + world_z)

func _dictionary_vector3(source: Dictionary, key: String, fallback: Vector3) -> Vector3:
	var raw_value: Variant = source.get(key, fallback)
	if raw_value is Vector3:
		return raw_value
	return fallback
