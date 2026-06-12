extends Control
class_name CrosshairControl

var spread_px: float = 14.0
var bloom_px: float = 0.0     # extra spread spike immediately after firing, decays fast
var barrel_offset: Vector2 = Vector2.ZERO
var fired_flash: float = 0.0
var role_cooldown: float = 0.0
var role_cooldown_max: float = 1.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	fired_flash = max(0.0, fired_flash - delta * 5.0)
	bloom_px = move_toward(bloom_px, 0.0, delta * 68.0)
	queue_redraw()

func notify_fired() -> void:
	fired_flash = 1.0
	bloom_px = 24.0

func _draw() -> void:
	var screen_center := get_viewport_rect().size * 0.5
	# Crosshair tracks barrel direction — entire reticle moves with weapon kick
	var center := screen_center + barrel_offset

	var base_col := Color(0.78, 1.0, 0.88, 0.82)
	var fire_col := Color(1.0, 0.72, 0.28, 0.92)
	var col := base_col.lerp(fire_col, fired_flash)

	# Ghost dot at true screen center so player can tell how far off they've drifted
	if barrel_offset.length() > 4.0:
		draw_circle(screen_center, 1.4, Color(0.5, 0.7, 0.6, 0.35))

	var line_len := 9.0
	var line_w := 1.6

	var total_spread := spread_px + bloom_px
	draw_line(center + Vector2(0.0, -total_spread), center + Vector2(0.0, -(total_spread + line_len)), col, line_w)
	draw_line(center + Vector2(0.0,  total_spread), center + Vector2(0.0,  (total_spread + line_len)), col, line_w)
	draw_line(center + Vector2(-total_spread, 0.0), center + Vector2(-(total_spread + line_len), 0.0), col, line_w)
	draw_line(center + Vector2( total_spread, 0.0), center + Vector2( (total_spread + line_len), 0.0), col, line_w)

	draw_circle(center, 1.8, col)

	if role_cooldown > 0.0 and role_cooldown_max > 0.0:
		var ratio: float = clamp(role_cooldown / role_cooldown_max, 0.0, 1.0)
		draw_arc(screen_center + Vector2(0.0, 22.0), 6.0, -PI * 0.5, -PI * 0.5 + TAU * (1.0 - ratio), 20, Color(0.35, 1.0, 0.86, 0.9), 1.4)
