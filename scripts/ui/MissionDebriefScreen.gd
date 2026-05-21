extends CanvasLayer
class_name MissionDebriefScreen

var panel: DebriefPanel
var summary: Dictionary = {}

func configure(run_summary: Dictionary) -> void:
	summary = run_summary.duplicate(true)
	if panel:
		panel.configure(summary)

func _ready() -> void:
	layer = 220
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	panel = DebriefPanel.new()
	panel.name = "DebriefPanel"
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.configure(summary)
	add_child(panel)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_R:
			get_tree().reload_current_scene()

class DebriefPanel:
	extends Control

	var summary: Dictionary = {}
	var redeploy_rect: Rect2 = Rect2()

	func configure(run_summary: Dictionary) -> void:
		summary = run_summary.duplicate(true)
		queue_redraw()

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton:
			var mouse_event: InputEventMouseButton = event as InputEventMouseButton
			if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT and redeploy_rect.has_point(mouse_event.position):
				get_tree().reload_current_scene()
		elif event is InputEventKey:
			var key_event: InputEventKey = event as InputEventKey
			if key_event.pressed and not key_event.echo and key_event.keycode == KEY_R:
				get_tree().reload_current_scene()

	func _draw() -> void:
		var viewport_size: Vector2 = get_viewport_rect().size
		var font: Font = get_theme_default_font()
		if not font:
			return
		var success: bool = bool(summary.get("success", false))
		var header: String = "MISSION COMPLETE" if success else "OPERATOR DOWN"
		var header_color: Color = Color(0.42, 1.0, 0.86, 0.96) if success else Color(0.9, 0.2, 0.1, 0.96)
		draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(0.02, 0.03, 0.04, 0.97), true)
		draw_string(font, Vector2(viewport_size.x * 0.5 - 155.0, 92.0), header, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 26, header_color)
		_draw_stats(font, viewport_size)
		_draw_rating(font, viewport_size, success)
		_draw_redeploy(font, viewport_size)

	func _draw_stats(font: Font, viewport_size: Vector2) -> void:
		var block_width: float = 420.0
		var origin: Vector2 = Vector2(viewport_size.x * 0.5 - block_width * 0.5, viewport_size.y * 0.5 - 118.0)
		var rows: Array[Dictionary] = [
			{"label": "ROLE", "value": String(summary.get("role", "breacher")).to_upper()},
			{"label": "TIME", "value": _format_time(float(summary.get("time_elapsed", 0.0)))},
			{"label": "KILLS", "value": str(int(summary.get("kills", 0)))},
			{"label": "OBJECTIVES", "value": "%d / %d" % [int(summary.get("objectives_done", 0)), int(summary.get("objectives_total", 0))]},
			{"label": "CONTAM CLR", "value": "%d%%" % int(round(float(summary.get("contamination_cleared", 0.0))))}
		]
		draw_rect(Rect2(origin + Vector2(-28.0, -38.0), Vector2(block_width + 56.0, 246.0)), Color(0.025, 0.055, 0.06, 0.78), true)
		draw_rect(Rect2(origin + Vector2(-28.0, -38.0), Vector2(block_width + 56.0, 246.0)), Color(0.12, 0.62, 0.58, 0.42), false, 1.3)
		for index in range(rows.size()):
			var row: Dictionary = rows[index]
			var y: float = origin.y + float(index) * 39.0
			draw_string(font, Vector2(origin.x, y), String(row.get("label", "")), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, Color(0.48, 0.72, 0.72, 0.88))
			draw_string(font, Vector2(origin.x + 190.0, y), String(row.get("value", "")), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color(0.82, 1.0, 0.92, 0.96))

	func _draw_rating(font: Font, viewport_size: Vector2, success: bool) -> void:
		var rating: String = _get_rating(success)
		var rating_color: Color = Color(0.42, 1.0, 0.86, 0.96)
		if rating in ["D", "F"]:
			rating_color = Color(0.95, 0.28, 0.18, 0.96)
		elif rating == "B" or rating == "C":
			rating_color = Color(0.95, 0.72, 0.24, 0.96)
		draw_string(font, Vector2(viewport_size.x - 132.0, 112.0), rating, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 48, rating_color)
		draw_string(font, Vector2(viewport_size.x - 148.0, 144.0), "RATING", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color(0.52, 0.72, 0.72, 0.82))

	func _draw_redeploy(font: Font, viewport_size: Vector2) -> void:
		redeploy_rect = Rect2(Vector2(viewport_size.x * 0.5 - 110.0, viewport_size.y - 96.0), Vector2(220.0, 42.0))
		draw_rect(redeploy_rect, Color(0.035, 0.13, 0.125, 0.86), true)
		draw_rect(redeploy_rect, Color(0.32, 1.0, 0.82, 0.82), false, 1.2)
		draw_string(font, redeploy_rect.position + Vector2(43.0, 27.0), "[R] REDEPLOY", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, Color(0.82, 1.0, 0.92, 0.96))

	func _get_rating(success: bool) -> String:
		var done: int = int(summary.get("objectives_done", 0))
		var total: int = max(0, int(summary.get("objectives_total", 0)))
		var elapsed: float = float(summary.get("time_elapsed", 0.0))
		if success and total > 0 and done >= total and elapsed < 240.0:
			return "S"
		if success and total > 0 and done >= total:
			return "A"
		if success and done > 0:
			return "B"
		if success:
			return "C"
		if done > 0:
			return "D"
		return "F"

	func _format_time(seconds_value: float) -> String:
		var total_seconds: int = max(0, int(round(seconds_value)))
		return "%02d:%02d" % [int(total_seconds / 60), total_seconds % 60]
