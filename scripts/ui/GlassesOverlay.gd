extends Control
class_name GlassesOverlay

var _scan_y: float = 0.0
var _scan_line: ColorRect

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scan_line = ColorRect.new()
	_scan_line.color = Color(0.48, 1.0, 0.82, 0.045)
	_scan_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_scan_line)

func _process(delta: float) -> void:
	var h := get_viewport_rect().size.y
	_scan_y = fmod(_scan_y + delta * 68.0, h)
	_scan_line.size = Vector2(get_viewport_rect().size.x, 1.0)
	_scan_line.position = Vector2(0.0, _scan_y)
	queue_redraw()

func _draw() -> void:
	var sz := get_viewport_rect().size
	var w := sz.x
	var h := sz.y

	# Vignette — 4 edge darkening rects with alpha gradient via multiple thin strips
	var v_steps := 12
	for i in range(v_steps):
		var t := float(i) / float(v_steps)
		var alpha := (1.0 - t) * 0.42
		var strip_h := 110.0 / float(v_steps)
		draw_rect(Rect2(0, i * strip_h, w, strip_h), Color(0.0, 0.0, 0.0, alpha))
		draw_rect(Rect2(0, h - (i + 1) * strip_h, w, strip_h), Color(0.0, 0.0, 0.0, alpha))
	var h_steps := 8
	for i in range(h_steps):
		var t := float(i) / float(h_steps)
		var alpha := (1.0 - t) * 0.28
		var strip_w := 72.0 / float(h_steps)
		draw_rect(Rect2(i * strip_w, 0, strip_w, h), Color(0.0, 0.0, 0.0, alpha))
		draw_rect(Rect2(w - (i + 1) * strip_w, 0, strip_w, h), Color(0.0, 0.0, 0.0, alpha))

	# Corner brackets — L-shaped teal lines at each corner
	var bracket_len := 28.0
	var bracket_w := 1.8
	var col := Color(0.32, 0.72, 0.62, 0.55)
	var inset := 18.0

	# Top-left
	draw_line(Vector2(inset, inset), Vector2(inset + bracket_len, inset), col, bracket_w)
	draw_line(Vector2(inset, inset), Vector2(inset, inset + bracket_len), col, bracket_w)
	# Top-right
	draw_line(Vector2(w - inset, inset), Vector2(w - inset - bracket_len, inset), col, bracket_w)
	draw_line(Vector2(w - inset, inset), Vector2(w - inset, inset + bracket_len), col, bracket_w)
	# Bottom-left
	draw_line(Vector2(inset, h - inset), Vector2(inset + bracket_len, h - inset), col, bracket_w)
	draw_line(Vector2(inset, h - inset), Vector2(inset, h - inset - bracket_len), col, bracket_w)
	# Bottom-right
	draw_line(Vector2(w - inset, h - inset), Vector2(w - inset - bracket_len, h - inset), col, bracket_w)
	draw_line(Vector2(w - inset, h - inset), Vector2(w - inset, h - inset - bracket_len), col, bracket_w)
