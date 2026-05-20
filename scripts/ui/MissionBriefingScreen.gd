extends CanvasLayer
class_name MissionBriefingScreen

signal deploy_pressed(role_id: String)

var panel: BriefingPanel
var objectives: Array = []
var roles: Array[Dictionary] = []
var selected_role: String = "breacher"

func configure(objective_preview: Array, role_definitions: Array[Dictionary], default_role: String) -> void:
	objectives = objective_preview.duplicate(true)
	roles = role_definitions.duplicate(true)
	selected_role = default_role
	if panel:
		panel.configure(objectives, roles, selected_role)

func _ready() -> void:
	layer = 100
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	panel = BriefingPanel.new()
	panel.name = "BriefingPanel"
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.configure(objectives, roles, selected_role)
	panel.role_selected.connect(_on_panel_role_selected)
	panel.deploy_pressed.connect(_on_panel_deploy_pressed)
	add_child(panel)

func _on_panel_role_selected(role_id: String) -> void:
	selected_role = role_id

func _on_panel_deploy_pressed(role_id: String) -> void:
	deploy_pressed.emit(role_id)

class BriefingPanel:
	extends Control

	signal role_selected(role_id: String)
	signal deploy_pressed(role_id: String)

	var objectives: Array = []
	var roles: Array[Dictionary] = []
	var selected_role: String = "breacher"
	var deploy_rect: Rect2 = Rect2()
	var role_rects: Dictionary = {}

	func configure(objective_preview: Array, role_definitions: Array[Dictionary], default_role: String) -> void:
		objectives = objective_preview.duplicate(true)
		roles = role_definitions.duplicate(true)
		selected_role = default_role
		queue_redraw()

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _gui_input(event: InputEvent) -> void:
		if not (event is InputEventMouseButton):
			return
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
			return
		if deploy_rect.has_point(mouse_event.position):
			deploy_pressed.emit(selected_role)
			return
		for role_id in role_rects.keys():
			var raw_rect: Variant = role_rects[role_id]
			if not (raw_rect is Rect2):
				continue
			var rect: Rect2 = raw_rect
			if rect.has_point(mouse_event.position):
				selected_role = String(role_id)
				role_selected.emit(selected_role)
				queue_redraw()
				return

	func _draw() -> void:
		var viewport_size: Vector2 = get_viewport_rect().size
		var font: Font = get_theme_default_font()
		if not font:
			return
		draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(0.02, 0.04, 0.05, 0.96), true)
		var center_x: float = viewport_size.x * 0.5
		draw_string(font, Vector2(center_x - 118.0, 48.0), "STATION CLEANERS", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 22, Color(0.42, 1.0, 0.88, 0.96))
		draw_string(font, Vector2(center_x - 70.0, 72.0), "DEPLOYMENT BRIEF", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color(0.52, 0.72, 0.72, 0.82))
		_draw_roles(font, viewport_size)
		_draw_objectives(font, viewport_size)
		_draw_deploy_button(font, viewport_size)

	func _draw_roles(font: Font, viewport_size: Vector2) -> void:
		role_rects.clear()
		var start: Vector2 = Vector2(max(44.0, viewport_size.x * 0.08), 118.0)
		draw_string(font, start + Vector2(0.0, -22.0), "ROLE", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color(0.7, 1.0, 0.9, 0.9))
		for index in range(roles.size()):
			var role: Dictionary = roles[index]
			var role_id: String = String(role.get("id", "role"))
			var rect: Rect2 = Rect2(start + Vector2(0.0, float(index) * 118.0), Vector2(360.0, 96.0))
			role_rects[role_id] = rect
			var selected: bool = role_id == selected_role
			var fill_color: Color = Color(0.035, 0.075, 0.078, 0.82)
			var border_color: Color = Color(0.13, 0.42, 0.42, 0.7)
			if selected:
				fill_color = Color(0.04, 0.13, 0.125, 0.92)
				border_color = Color(0.32, 1.0, 0.82, 0.96)
			draw_rect(rect, fill_color, true)
			draw_rect(rect, border_color, false, 1.4)
			draw_string(font, rect.position + Vector2(16.0, 23.0), String(role.get("label", "ROLE")), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 17, Color(0.78, 1.0, 0.92, 0.96))
			draw_string(font, rect.position + Vector2(16.0, 45.0), String(role.get("weapon_name", "Unknown weapon")), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color(0.9, 0.82, 0.54, 0.92))
			var summary: String = String(role.get("summary", ""))
			var summary_lines: PackedStringArray = summary.split("\n")
			for line_index in range(min(summary_lines.size(), 2)):
				draw_string(font, rect.position + Vector2(16.0, 66.0 + float(line_index) * 15.0), String(summary_lines[line_index]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color(0.58, 0.78, 0.76, 0.92))

	func _draw_objectives(font: Font, viewport_size: Vector2) -> void:
		var panel_rect: Rect2 = Rect2(Vector2(viewport_size.x * 0.55, 118.0), Vector2(min(430.0, viewport_size.x * 0.36), 332.0))
		draw_rect(panel_rect, Color(0.025, 0.055, 0.06, 0.78), true)
		draw_rect(panel_rect, Color(0.13, 0.55, 0.54, 0.58), false, 1.2)
		draw_string(font, panel_rect.position + Vector2(18.0, 28.0), "OBJECTIVES", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, Color(0.7, 1.0, 0.9, 0.95))
		var y: float = panel_rect.position.y + 62.0
		for objective_value in objectives:
			if not (objective_value is Dictionary):
				continue
			var objective: Dictionary = objective_value
			var objective_type: String = String(objective.get("type", "purge_node"))
			var label: String = String(objective.get("label", objective_type.replace("_", " ")))
			var sector_label: String = String(objective.get("sector_label", "unknown sector"))
			_draw_objective_icon(panel_rect.position + Vector2(22.0, y - 8.0), objective_type)
			draw_string(font, panel_rect.position + Vector2(46.0, y), label.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color(0.84, 1.0, 0.9, 0.96))
			draw_string(font, panel_rect.position + Vector2(46.0, y + 17.0), sector_label.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color(0.5, 0.72, 0.7, 0.88))
			y += 58.0

	func _draw_objective_icon(center: Vector2, objective_type: String) -> void:
		var color: Color = Color(0.32, 1.0, 0.82, 0.92)
		if objective_type == "restore_power":
			var bolt: PackedVector2Array = PackedVector2Array([
				center + Vector2(2.0, -9.0),
				center + Vector2(-5.0, 1.0),
				center + Vector2(1.0, 1.0),
				center + Vector2(-2.0, 10.0),
				center + Vector2(8.0, -2.0),
				center + Vector2(2.0, -2.0)
			])
			draw_colored_polygon(bolt, Color(0.95, 0.68, 0.24, 0.95))
		elif objective_type == "uplink_terminal":
			draw_line(center + Vector2(0.0, 9.0), center + Vector2(0.0, -7.0), color, 2.0)
			draw_arc(center + Vector2(0.0, -4.0), 7.0, -2.5, -0.65, 12, color, 1.5)
			draw_arc(center + Vector2(0.0, -4.0), 7.0, -0.5, 2.5, 12, color, 1.5)
		else:
			draw_circle(center, 8.0, Color(0.8, 0.12, 0.1, 0.9))
			draw_arc(center, 9.0, 0.0, TAU, 20, Color(1.0, 0.45, 0.25, 0.95), 1.5)

	func _draw_deploy_button(font: Font, viewport_size: Vector2) -> void:
		deploy_rect = Rect2(Vector2(viewport_size.x * 0.5 - 86.0, viewport_size.y - 92.0), Vector2(172.0, 46.0))
		draw_rect(deploy_rect, Color(0.05, 0.26, 0.24, 0.96), true)
		draw_rect(deploy_rect, Color(0.34, 1.0, 0.82, 0.95), false, 1.5)
		draw_string(font, deploy_rect.position + Vector2(49.0, 29.0), "DEPLOY", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, Color(0.82, 1.0, 0.92, 0.98))
