extends Control
class_name WeaponHologramHUD

var weapon_name: String = ""
var ammo_current: int = 0
var ammo_reserve: int = 0
var magazine_size: int = 30
var weapon_condition: float = 1.0
var weapon_family: String = ""
var is_reloading: bool = false

var _font: Font

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	offset_left = -290.0
	offset_right = -18.0
	offset_top = 20.0
	offset_bottom = 120.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = ThemeDB.fallback_font
	queue_redraw()

func refresh(wname: String, cur: int, res: int, mag_sz: int, cond: float, family: String, reloading: bool) -> void:
	weapon_name = wname
	ammo_current = cur
	ammo_reserve = res
	magazine_size = max(1, mag_sz)
	weapon_condition = cond
	weapon_family = family
	is_reloading = reloading
	queue_redraw()

func _draw() -> void:
	if weapon_name.is_empty():
		return

	var teal: Color = Color(0.42, 0.88, 0.72, 0.85)
	var dim: Color  = Color(0.32, 0.62, 0.52, 0.55)
	var w: float    = size.x
	var lx: float   = 10.0

	# Vertical accent line
	draw_line(Vector2(lx, 4.0), Vector2(lx, 62.0), teal, 2.0)

	# Weapon name
	draw_string(_font, Vector2(lx + 8.0, 16.0), weapon_name.to_upper(),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, dim)

	# Magazine icon
	var fill_ratio: float = 1.0
	if not is_reloading and magazine_size > 0:
		fill_ratio = clampf(float(ammo_current) / float(magazine_size), 0.0, 1.0)
	_draw_magazine_icon(Vector2(lx + 8.0, 22.0), fill_ratio)

	# Reserve as mag count — "×3"
	var mag_count: int = int(ammo_reserve) / int(magazine_size) if magazine_size > 0 else 0
	var res_str: String = "RELOADING" if is_reloading else "x%d" % mag_count
	draw_string(_font, Vector2(lx + 32.0, 52.0), res_str,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, dim)

	# Condition bar
	var bar_y: float = 64.0
	var bar_w: float = 60.0
	var bar_h: float = 3.0
	draw_rect(Rect2(lx + 8.0, bar_y, bar_w, bar_h), Color(0.1, 0.15, 0.12, 0.5))
	var cond_color: Color = Color(0.28, 0.88, 0.52).lerp(Color(0.88, 0.22, 0.12), 1.0 - weapon_condition)
	draw_rect(Rect2(lx + 8.0, bar_y, bar_w * weapon_condition, bar_h), cond_color)

	# Family tag
	draw_string(_font, Vector2(w - 4.0, 16.0), weapon_family.to_upper(),
		HORIZONTAL_ALIGNMENT_RIGHT, -1, 10, dim)

	# Connector line
	draw_line(Vector2(lx + 6.0, 22.0), Vector2(lx + 6.0 + 30.0, 22.0), dim, 0.8)

func _draw_magazine_icon(top_left: Vector2, fill_ratio: float) -> void:
	var bw: float = 14.0
	var bh: float = 28.0
	var lip_h: float = 4.0
	var lip_w: float = 8.0
	var bx: float = top_left.x
	var by: float = top_left.y

	# Feed lip (narrow top)
	draw_rect(Rect2(bx + (bw - lip_w) * 0.5, by, lip_w, lip_h), Color(0.18, 0.28, 0.24, 0.7))

	# Body outline
	draw_rect(Rect2(bx, by + lip_h, bw, bh), Color(0.06, 0.10, 0.09, 0.85))
	draw_rect(Rect2(bx, by + lip_h, bw, bh), Color(0.22, 0.42, 0.38, 0.6), false, 1.0)

	# Fill — grows from bottom up
	var fill_h: float = bh * clampf(fill_ratio, 0.0, 1.0)
	var fill_y: float = by + lip_h + (bh - fill_h)
	var fill_color: Color
	if fill_ratio > 0.65:
		fill_color = Color(0.22, 0.82, 0.58, 0.88)
	elif fill_ratio > 0.35:
		fill_color = Color(0.85, 0.78, 0.18, 0.88)
	elif fill_ratio > 0.15:
		fill_color = Color(0.92, 0.42, 0.12, 0.88)
	else:
		fill_color = Color(0.88, 0.12, 0.08, 0.90)
	if fill_h > 0.5:
		draw_rect(Rect2(bx + 1.0, fill_y, bw - 2.0, fill_h - 1.0), fill_color)

	# Tick marks — 4 horizontal lines dividing the body into quarters
	for i in range(1, 4):
		var tick_y: float = by + lip_h + bh * (float(i) * 0.25)
		draw_line(Vector2(bx + 2.0, tick_y), Vector2(bx + bw - 2.0, tick_y),
			Color(0.0, 0.0, 0.0, 0.35), 0.8)
