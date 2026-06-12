extends Control
class_name GlassesOverlay

var _scan_y: float = 0.0
var _scan_line: ColorRect
var _grain_timer: float = 0.0
var _grain_seed: int = 0
var corruption: float = 0.0
var blood_level: float = 1.0

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
	_grain_timer += delta
	if _grain_timer >= 0.045:
		_grain_timer = 0.0
		_grain_seed = randi()
		queue_redraw()
	else:
		queue_redraw()

func update_effects(new_corruption: float, new_blood: float) -> void:
	corruption = new_corruption
	blood_level = new_blood

func _draw() -> void:
	var sz := get_viewport_rect().size
	var w := sz.x
	var h := sz.y

	# ── Vignette — deepens with corruption and blood loss ──────────────────
	var vignette_strength: float = 0.42 + (corruption / 100.0) * 0.28 + (1.0 - blood_level) * 0.18
	var v_steps := 14
	for i in range(v_steps):
		var t := float(i) / float(v_steps)
		var alpha := (1.0 - t) * vignette_strength
		var strip_h := 120.0 / float(v_steps)
		draw_rect(Rect2(0, i * strip_h, w, strip_h), Color(0.0, 0.0, 0.0, alpha))
		draw_rect(Rect2(0, h - (i + 1) * strip_h, w, strip_h), Color(0.0, 0.0, 0.0, alpha))
	var h_steps := 10
	for i in range(h_steps):
		var t := float(i) / float(h_steps)
		var alpha := (1.0 - t) * (vignette_strength * 0.65)
		var strip_w := 88.0 / float(h_steps)
		draw_rect(Rect2(i * strip_w, 0, strip_w, h), Color(0.0, 0.0, 0.0, alpha))
		draw_rect(Rect2(w - (i + 1) * strip_w, 0, strip_w, h), Color(0.0, 0.0, 0.0, alpha))

	# ── Chromatic aberration fringe — only visible at high corruption ───────
	var aberration: float = clamp((corruption - 45.0) / 55.0, 0.0, 1.0)
	if aberration > 0.02:
		var shift: float = aberration * 3.2
		var fringe_alpha: float = aberration * 0.22
		# Red fringe on the right edge
		draw_rect(Rect2(w * 0.88 - shift, 0, shift * 2.0, h), Color(1.0, 0.0, 0.0, fringe_alpha * 0.5))
		# Cyan fringe on the left edge
		draw_rect(Rect2(w * 0.12 - shift, 0, shift * 2.0, h), Color(0.0, 0.85, 1.0, fringe_alpha * 0.5))

	# ── Film grain — random dot field, refreshes at ~22 fps ─────────────────
	var grain_intensity: float = 0.055 + (corruption / 100.0) * 0.045 + (1.0 - blood_level) * 0.025
	if grain_intensity > 0.01:
		var seed := _grain_seed
		var grain_count: int = int(w * h * grain_intensity * 0.0018)
		for _i in range(grain_count):
			seed = (seed * 1664525 + 1013904223) & 0x7FFFFFFF
			var gx: float = float(seed % int(w))
			seed = (seed * 1664525 + 1013904223) & 0x7FFFFFFF
			var gy: float = float(seed % int(h))
			seed = (seed * 1664525 + 1013904223) & 0x7FFFFFFF
			var brightness: float = float(seed & 0xFF) / 255.0
			var grain_alpha: float = grain_intensity * (0.6 + brightness * 0.4)
			var grain_col := Color(brightness * 0.8, brightness, brightness * 0.9, grain_alpha)
			draw_rect(Rect2(gx, gy, 1.5, 1.5), grain_col)

	# ── Corruption hallucination tint — deep green wash at extreme corruption ─
	if corruption > 72.0:
		var haunt_alpha: float = (corruption - 72.0) / 28.0 * 0.12
		draw_rect(Rect2(0, 0, w, h), Color(0.0, 0.18, 0.12, haunt_alpha))

	# ── Low-blood desaturation tint ───────────────────────────────────────────
	if blood_level < 0.42:
		var desat_alpha: float = (1.0 - blood_level / 0.42) * 0.18
		draw_rect(Rect2(0, 0, w, h), Color(0.42, 0.42, 0.42, desat_alpha))

	# ── Corner brackets ────────────────────────────────────────────────────────
	var bracket_len := 28.0
	var bracket_w := 1.8
	var col := Color(0.32, 0.72, 0.62, 0.55)
	var inset := 18.0
	draw_line(Vector2(inset, inset), Vector2(inset + bracket_len, inset), col, bracket_w)
	draw_line(Vector2(inset, inset), Vector2(inset, inset + bracket_len), col, bracket_w)
	draw_line(Vector2(w - inset, inset), Vector2(w - inset - bracket_len, inset), col, bracket_w)
	draw_line(Vector2(w - inset, inset), Vector2(w - inset, inset + bracket_len), col, bracket_w)
	draw_line(Vector2(inset, h - inset), Vector2(inset + bracket_len, h - inset), col, bracket_w)
	draw_line(Vector2(inset, h - inset), Vector2(inset, h - inset - bracket_len), col, bracket_w)
	draw_line(Vector2(w - inset, h - inset), Vector2(w - inset - bracket_len, h - inset), col, bracket_w)
	draw_line(Vector2(w - inset, h - inset), Vector2(w - inset, h - inset - bracket_len), col, bracket_w)
