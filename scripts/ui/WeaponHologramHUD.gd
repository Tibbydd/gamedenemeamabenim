extends Control
class_name WeaponHologramHUD

var weapon_name: String = ""
var ammo_current: int = 0
var ammo_reserve: int = 0
var weapon_condition: float = 1.0
var weapon_family: String = ""
var is_reloading: bool = false

var _font: Font

func _ready() -> void:
	# Positioned beside the weapon — center-right, vertically centered on weapon area
	set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	offset_left = -290.0
	offset_right = -18.0
	offset_top = 20.0
	offset_bottom = 110.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = ThemeDB.fallback_font
	queue_redraw()

func refresh(wname: String, cur: int, res: int, cond: float, family: String, reloading: bool) -> void:
	weapon_name = wname
	ammo_current = cur
	ammo_reserve = res
	weapon_condition = cond
	weapon_family = family
	is_reloading = reloading
	queue_redraw()

func _draw() -> void:
	if weapon_name.is_empty():
		return

	var teal := Color(0.42, 0.88, 0.72, 0.85)
	var dim := Color(0.32, 0.62, 0.52, 0.55)
	var bright := Color(0.88, 1.0, 0.94, 0.95)
	var w := size.x
	var lx := 10.0  # left-edge x for all elements

	# Vertical accent line on left edge
	draw_line(Vector2(lx, 4.0), Vector2(lx, 52.0), teal, 2.0)

	# Weapon name — small, dimmed, uppercase
	var name_display := weapon_name.to_upper()
	draw_string(_font, Vector2(lx + 8.0, 16.0), name_display,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, dim)

	# Ammo count — large and bright
	var ammo_str := str(ammo_current) if not is_reloading else "--"
	draw_string(_font, Vector2(lx + 8.0, 44.0), ammo_str,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 30, bright)

	# Reserve ammo — smaller, beside ammo count
	var cur_width := _font.get_string_size(ammo_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x
	draw_string(_font, Vector2(lx + 10.0 + cur_width, 40.0), "/ %d" % ammo_reserve,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, dim)

	# Condition bar — thin strip below, 60px wide
	var bar_y := 58.0
	var bar_w := 60.0
	var bar_h := 3.0
	draw_rect(Rect2(lx + 8.0, bar_y, bar_w, bar_h), Color(0.1, 0.15, 0.12, 0.5))
	var cond_color := Color(0.28, 0.88, 0.52).lerp(Color(0.88, 0.22, 0.12), 1.0 - weapon_condition)
	draw_rect(Rect2(lx + 8.0, bar_y, bar_w * weapon_condition, bar_h), cond_color)

	# Family tag — tiny, top-right corner
	draw_string(_font, Vector2(w - 4.0, 16.0), weapon_family.to_upper(),
		HORIZONTAL_ALIGNMENT_RIGHT, -1, 10, dim)

	# Horizontal connector lines (hologram mount feel)
	draw_line(Vector2(lx + 6.0, 22.0), Vector2(lx + 6.0 + 30.0, 22.0), dim, 0.8)
