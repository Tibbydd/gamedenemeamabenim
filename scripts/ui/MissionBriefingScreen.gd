extends CanvasLayer
class_name MissionBriefingScreen

signal deploy_pressed(weapon_id: String, equipment_id: String, passive_id: String)

var panel: BriefingPanel
var objectives: Array = []
var weapons: Array[Dictionary] = []
var equipment: Array[Dictionary] = []
var passives: Array[Dictionary] = []
var selected_weapon_id: String = "a12_service_rifle"
var selected_equipment_id: String = "trauma_kit"
var selected_passive_id: String = "none"

func configure(objective_preview: Array, _role_definitions: Array[Dictionary], _default_role: String) -> void:
	objectives = objective_preview.duplicate(true)
	weapons = _get_weapon_options()
	equipment = _get_equipment_options()
	passives = _get_passive_options()
	if panel:
		panel.configure(objectives, weapons, equipment, passives, selected_weapon_id, selected_equipment_id, selected_passive_id)

func _ready() -> void:
	layer = 100
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if weapons.is_empty():
		weapons = _get_weapon_options()
	if equipment.is_empty():
		equipment = _get_equipment_options()
	if passives.is_empty():
		passives = _get_passive_options()
	panel = BriefingPanel.new()
	panel.name = "BriefingPanel"
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.configure(objectives, weapons, equipment, passives, selected_weapon_id, selected_equipment_id, selected_passive_id)
	panel.selection_changed.connect(_on_panel_selection_changed)
	panel.deploy_pressed.connect(_on_panel_deploy_pressed)
	add_child(panel)

func _on_panel_selection_changed(weapon_id: String, equipment_id: String, passive_id: String) -> void:
	selected_weapon_id = weapon_id
	selected_equipment_id = equipment_id
	selected_passive_id = passive_id

func _on_panel_deploy_pressed(weapon_id: String, equipment_id: String, passive_id: String) -> void:
	deploy_pressed.emit(weapon_id, equipment_id, passive_id)

func _get_weapon_options() -> Array[Dictionary]:
	return [
		{"id": "m7_colony_pistol", "label": "M-7 Colony Pistol"},
		{"id": "m9_security_revolver", "label": "M-9 Security Revolver"},
		{"id": "rattler_smg", "label": "Rattler SMG"},
		{"id": "station_guard_carbine", "label": "Station Guard Carbine"},
		{"id": "a12_service_rifle", "label": "A-12 Service Rifle"},
		{"id": "hullbreaker_ar", "label": "Hullbreaker AR"},
		{"id": "l6_deck_lmg", "label": "L-6 Deck LMG"}
	]

func _get_equipment_options() -> Array[Dictionary]:
	return [
		{"id": "trauma_kit", "label": "Trauma Kit", "detail": "Bleed and fracture care"},
		{"id": "stim_injector", "label": "Stim Injector", "detail": "Pain and speed burst"},
		{"id": "incendiary", "label": "Incendiary", "detail": "UNAVAILABLE", "disabled": true},
		{"id": "ammo_cache", "label": "Ammo Cache", "detail": "+90 reserve ammo"},
		{"id": "med_spray", "label": "Med Spray", "detail": "Emergency wound foam"}
	]

func _get_passive_options() -> Array[Dictionary]:
	return [
		{"id": "heavy_armor", "label": "Heavy Armor", "detail": "Move slower, resist damage"},
		{"id": "stealth_liner", "label": "Stealth Liner", "detail": "Quiet movement"},
		{"id": "medic_rig", "label": "Medic Rig", "detail": "Fast treatment"},
		{"id": "ammo_harness", "label": "Ammo Harness", "detail": "More reserve ammo"},
		{"id": "none", "label": "No Module", "detail": "No passive changes"}
	]

class BriefingPanel:
	extends Control

	signal selection_changed(weapon_id: String, equipment_id: String, passive_id: String)
	signal deploy_pressed(weapon_id: String, equipment_id: String, passive_id: String)

	var objectives: Array = []
	var weapons: Array[Dictionary] = []
	var equipment: Array[Dictionary] = []
	var passives: Array[Dictionary] = []
	var selected_weapon_id: String = "a12_service_rifle"
	var selected_equipment_id: String = "trauma_kit"
	var selected_passive_id: String = "none"
	var deploy_rect: Rect2 = Rect2()
	var weapon_rects: Dictionary = {}
	var equipment_rects: Dictionary = {}
	var passive_rects: Dictionary = {}

	func configure(objective_preview: Array, weapon_options: Array[Dictionary], equipment_options: Array[Dictionary], passive_options: Array[Dictionary], weapon_id: String, equipment_id: String, passive_id: String) -> void:
		objectives = objective_preview.duplicate(true)
		weapons = weapon_options.duplicate(true)
		equipment = equipment_options.duplicate(true)
		passives = passive_options.duplicate(true)
		selected_weapon_id = weapon_id
		selected_equipment_id = equipment_id
		selected_passive_id = passive_id
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
			deploy_pressed.emit(selected_weapon_id, selected_equipment_id, selected_passive_id)
			return
		if _apply_selection(mouse_event.position, weapon_rects, "weapon"):
			return
		if _apply_selection(mouse_event.position, equipment_rects, "equipment"):
			return
		_apply_selection(mouse_event.position, passive_rects, "passive")

	func _apply_selection(mouse_position: Vector2, rects: Dictionary, selector_type: String) -> bool:
		for option_id in rects.keys():
			var raw_rect: Variant = rects[option_id]
			if not (raw_rect is Rect2):
				continue
			var rect: Rect2 = raw_rect
			if not rect.has_point(mouse_position):
				continue
			var id_value: String = String(option_id)
			if selector_type == "equipment" and _equipment_disabled(id_value):
				return true
			if selector_type == "weapon":
				selected_weapon_id = id_value
			elif selector_type == "equipment":
				selected_equipment_id = id_value
			else:
				selected_passive_id = id_value
			selection_changed.emit(selected_weapon_id, selected_equipment_id, selected_passive_id)
			queue_redraw()
			return true
		return false

	func _equipment_disabled(option_id: String) -> bool:
		for option in equipment:
			if String(option.get("id", "")) == option_id:
				return bool(option.get("disabled", false))
		return false

	func _draw() -> void:
		var viewport_size: Vector2 = get_viewport_rect().size
		var font: Font = get_theme_default_font()
		if not font:
			return
		draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(0.02, 0.04, 0.05, 0.96), true)
		var center_x: float = viewport_size.x * 0.5
		draw_string(font, Vector2(center_x - 118.0, 48.0), "STATION CLEANERS", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 22, Color(0.42, 1.0, 0.88, 0.96))
		draw_string(font, Vector2(center_x - 86.0, 72.0), "EQUIPMENT BRIEF", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color(0.52, 0.72, 0.72, 0.82))
		var start_x: float = max(34.0, viewport_size.x * 0.055)
		var top_y: float = 116.0
		_draw_selector(font, "PRIMARY", weapons, selected_weapon_id, Rect2(Vector2(start_x, top_y), Vector2(220.0, 304.0)), weapon_rects)
		_draw_selector(font, "EQUIPMENT", equipment, selected_equipment_id, Rect2(Vector2(start_x + 240.0, top_y), Vector2(180.0, 246.0)), equipment_rects)
		_draw_selector(font, "MODULE", passives, selected_passive_id, Rect2(Vector2(start_x + 438.0, top_y), Vector2(180.0, 246.0)), passive_rects)
		_draw_objectives(font, Rect2(Vector2(min(viewport_size.x - 380.0, start_x + 642.0), top_y), Vector2(340.0, 304.0)))
		_draw_deploy_button(font, viewport_size)

	func _draw_selector(font: Font, title: String, options: Array[Dictionary], selected_id: String, rect: Rect2, rects: Dictionary) -> void:
		rects.clear()
		draw_rect(rect, Color(0.025, 0.055, 0.06, 0.78), true)
		draw_rect(rect, Color(0.13, 0.55, 0.54, 0.58), false, 1.2)
		draw_string(font, rect.position + Vector2(14.0, 24.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color(0.7, 1.0, 0.9, 0.95))
		var y: float = rect.position.y + 42.0
		for option in options:
			var option_id: String = String(option.get("id", ""))
			var row: Rect2 = Rect2(Vector2(rect.position.x + 10.0, y), Vector2(rect.size.x - 20.0, 28.0))
			rects[option_id] = row
			var disabled: bool = bool(option.get("disabled", false))
			var selected: bool = option_id == selected_id
			var fill: Color = Color(0.032, 0.07, 0.072, 0.72)
			var border: Color = Color(0.12, 0.33, 0.33, 0.5)
			var text_col: Color = Color(0.72, 0.9, 0.84, 0.92)
			if selected:
				fill = Color(0.04, 0.13, 0.125, 0.92)
				border = Color(0.32, 1.0, 0.82, 0.96)
			if disabled:
				text_col = Color(0.36, 0.42, 0.42, 0.8)
			draw_rect(row, fill, true)
			draw_rect(row, border, false, 1.0)
			draw_string(font, row.position + Vector2(8.0, 18.0), String(option.get("label", option_id)), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, text_col)
			if option.has("detail"):
				var detail_color: Color = Color(text_col.r * 0.75, text_col.g * 0.8, text_col.b * 0.8, text_col.a * 0.8)
				draw_string(font, row.position + Vector2(8.0, 31.0), String(option.get("detail", "")), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 9, detail_color)
			y += 34.0

	func _draw_objectives(font: Font, panel_rect: Rect2) -> void:
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
			var bolt: PackedVector2Array = PackedVector2Array([center + Vector2(2.0, -9.0), center + Vector2(-5.0, 1.0), center + Vector2(1.0, 1.0), center + Vector2(-2.0, 10.0), center + Vector2(8.0, -2.0), center + Vector2(2.0, -2.0)])
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
