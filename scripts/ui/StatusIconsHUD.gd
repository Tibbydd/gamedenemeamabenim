extends Control
class_name StatusIconsHUD

# Set each frame by PlayerControllerFPS
var bleed_rate: float = 0.0
var burn_time: float = 0.0
var stim_time: float = 0.0
var has_fracture: bool = false
var has_infection: bool = false
var corruption: float = 0.0

var _font: Font

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_CENTER)
	offset_left = -140.0
	offset_right = 140.0
	offset_top = -52.0
	offset_bottom = -10.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = ThemeDB.fallback_font

func update_status(health: PlayerHealthBodyParts, mental_corruption: float) -> void:
	bleed_rate = health.bleed_rate
	burn_time = health.burn_time
	stim_time = health.stimulant_time
	corruption = mental_corruption
	has_fracture = false
	has_infection = false
	for part_name in health.parts:
		var p: Dictionary = health.parts[part_name]
		if bool(p.get("fractured", false)):
			has_fracture = true
		if bool(p.get("infected", false)):
			has_infection = true
	queue_redraw()

func _draw() -> void:
	var icons: Array[Dictionary] = []
	if bleed_rate > 0.0:
		icons.append({"type": "bleed", "severity": clamp(bleed_rate / 8.0, 0.0, 1.0)})
	if burn_time > 0.0:
		icons.append({"type": "burn", "severity": clamp(burn_time / 12.0, 0.0, 1.0)})
	if stim_time > 0.0:
		icons.append({"type": "stim", "severity": clamp(stim_time / 18.0, 0.0, 1.0)})
	if has_fracture:
		icons.append({"type": "fracture", "severity": 1.0})
	if has_infection:
		icons.append({"type": "infected", "severity": 1.0})
	if corruption > 35.0:
		icons.append({"type": "corruption", "severity": clamp(corruption / 100.0, 0.0, 1.0)})

	if icons.is_empty():
		return

	var icon_size := 22.0
	var spacing := 28.0
	var total_w := icons.size() * spacing - (spacing - icon_size)
	var start_x := (size.x - total_w) * 0.5

	for i in range(icons.size()):
		var icon: Dictionary = icons[i]
		var cx := start_x + i * spacing + icon_size * 0.5
		var cy := icon_size * 0.5
		var center := Vector2(cx, cy)
		_draw_icon(icon["type"], center, icon_size * 0.5, float(icon["severity"]))

func _draw_icon(icon_type: String, center: Vector2, r: float, severity: float) -> void:
	match icon_type:
		"bleed":
			var col := Color(0.9, 0.12, 0.12, 0.88)
			draw_circle(center + Vector2(0.0, -r * 0.35), r * 0.55, col)
			var pts := PackedVector2Array([
				center + Vector2(-r * 0.45, -r * 0.0),
				center + Vector2(r * 0.45, -r * 0.0),
				center + Vector2(0.0, r * 0.85)
			])
			draw_colored_polygon(pts, col)
			# Severity arc
			draw_arc(center, r, -PI * 0.5, -PI * 0.5 + TAU * severity, 20,
				Color(1.0, 0.3, 0.3, 0.55), 1.2)

		"burn":
			var col := Color(1.0, 0.52, 0.08, 0.88)
			# Flame: 3 upward lobes
			for lobe in range(3):
				var ox := (lobe - 1) * r * 0.42
				draw_circle(center + Vector2(ox, -r * 0.22), r * 0.28, col)
			draw_circle(center + Vector2(0.0, r * 0.18), r * 0.45, col)
			draw_arc(center, r, -PI * 0.5, -PI * 0.5 + TAU * severity, 20,
				Color(1.0, 0.72, 0.2, 0.55), 1.2)

		"stim":
			var col := Color(0.28, 0.92, 0.88, 0.88)
			# Lightning bolt shape
			var pts := PackedVector2Array([
				center + Vector2(r * 0.25, -r),
				center + Vector2(-r * 0.05, -r * 0.1),
				center + Vector2(r * 0.28, -r * 0.1),
				center + Vector2(-r * 0.25, r),
				center + Vector2(r * 0.05, r * 0.1),
				center + Vector2(-r * 0.28, r * 0.1)
			])
			draw_colored_polygon(pts, col)
			draw_arc(center, r, -PI * 0.5, -PI * 0.5 + TAU * severity, 20,
				Color(0.4, 1.0, 0.9, 0.55), 1.2)

		"fracture":
			var col := Color(0.96, 0.84, 0.22, 0.88)
			# Two angled lines (broken bone)
			draw_line(center + Vector2(-r * 0.5, -r * 0.7),
				center + Vector2(r * 0.2, r * 0.1), col, 2.0)
			draw_line(center + Vector2(-r * 0.2, -r * 0.1),
				center + Vector2(r * 0.5, r * 0.7), col, 2.0)
			draw_line(center + Vector2(-r * 0.2, -r * 0.1),
				center + Vector2(r * 0.2, r * 0.1), col, 1.2)

		"infected":
			var col := Color(0.62, 0.22, 0.88, 0.88)
			# Diamond + 4 spokes
			var pts := PackedVector2Array([
				center + Vector2(0.0, -r * 0.6),
				center + Vector2(r * 0.6, 0.0),
				center + Vector2(0.0, r * 0.6),
				center + Vector2(-r * 0.6, 0.0)
			])
			draw_colored_polygon(pts, col)
			for angle in [0.0, PI * 0.5, PI, PI * 1.5]:
				var dir := Vector2(cos(angle), sin(angle))
				draw_line(center + dir * r * 0.62, center + dir * r * 0.95, col, 1.4)

		"corruption":
			var col := Color(0.28, 0.88, 0.72, severity * 0.9)
			# Eye outline
			draw_arc(center, r * 0.7, 0.0, TAU, 32, col, 1.4)
			draw_circle(center, r * 0.28, col)
			draw_line(center + Vector2(-r, 0.0), center + Vector2(r, 0.0),
				Color(col.r, col.g, col.b, col.a * 0.5), 1.0)
