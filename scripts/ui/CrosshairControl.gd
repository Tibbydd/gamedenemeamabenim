extends Control
class_name CrosshairControl

var spread_px: float = 14.0
var barrel_offset: Vector2 = Vector2.ZERO
var fired_flash: float = 0.0  # countdown after shot, tints lines briefly
var role_cooldown: float = 0.0
var role_cooldown_max: float = 1.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	fired_flash = max(0.0, fired_flash - delta * 5.0)
	queue_redraw()

func notify_fired() -> void:
	fired_flash = 1.0

func _draw() -> void:
	var center := get_viewport_rect().size * 0.5

	# Color shifts toward orange briefly after firing
	var base_col := Color(0.78, 1.0, 0.88, 0.82)
	var fire_col := Color(1.0, 0.72, 0.28, 0.92)
	var col := base_col.lerp(fire_col, fired_flash)

	var line_len := 9.0
	var line_w := 1.6

	# 4 spread lines radiating from center
	# Top
	draw_line(
		center + Vector2(0.0, -(spread_px)),
		center + Vector2(0.0, -(spread_px + line_len)),
		col, line_w
	)
	# Bottom
	draw_line(
		center + Vector2(0.0, spread_px),
		center + Vector2(0.0, spread_px + line_len),
		col, line_w
	)
	# Left
	draw_line(
		center + Vector2(-(spread_px), 0.0),
		center + Vector2(-(spread_px + line_len), 0.0),
		col, line_w
	)
	# Right
	draw_line(
		center + Vector2(spread_px, 0.0),
		center + Vector2(spread_px + line_len, 0.0),
		col, line_w
	)

	# Center dot
	draw_circle(center, 1.8, col)
	if role_cooldown > 0.0 and role_cooldown_max > 0.0:
		var ratio: float = clamp(role_cooldown / role_cooldown_max, 0.0, 1.0)
		var arc_center: Vector2 = center + Vector2(0.0, 22.0)
		draw_arc(arc_center, 6.0, -PI * 0.5, -PI * 0.5 + TAU * (1.0 - ratio), 20, Color(0.35, 1.0, 0.86, 0.9), 1.4)

	# Barrel ring — only drawn when barrel has significant offset from center
	if barrel_offset.length() > 5.0:
		var ring_center := center + barrel_offset
		var ring_col := Color(1.0, 0.82, 0.38, 0.65)
		draw_arc(ring_center, 10.0, 0.0, TAU, 32, ring_col, 1.2)
