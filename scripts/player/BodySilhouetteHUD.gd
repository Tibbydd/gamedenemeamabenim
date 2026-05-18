extends Control
class_name BodySilhouetteHUD

const WOUND_LIMIT: int = 22

var health: PlayerHealthBodyParts = null
var stamina_value: float = 100.0
var handling_state: String = ""
var wounds: Array[Dictionary] = []
var draw_origin: Vector2 = Vector2.ZERO
var draw_scale: float = 1.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)

func _process(delta: float) -> void:
	for index in range(wounds.size() - 1, -1, -1):
		var wound: Dictionary = wounds[index]
		wound["time"] = float(wound.get("time", 0.0)) - delta
		if float(wound["time"]) <= 0.0:
			wounds.remove_at(index)
		else:
			wounds[index] = wound
	queue_redraw()

func update_status(new_health: PlayerHealthBodyParts, new_stamina: float, new_handling_state: String) -> void:
	health = new_health
	stamina_value = new_stamina
	handling_state = new_handling_state
	queue_redraw()

func add_wound(part_name: String, amount: float, damage_type: String) -> void:
	var wound: Dictionary = {
		"part": part_name,
		"amount": amount,
		"type": damage_type,
		"time": 18.0,
		"offset": Vector2(randf_range(-5.0, 5.0), randf_range(-4.0, 4.0))
	}
	wounds.append(wound)
	while wounds.size() > WOUND_LIMIT:
		wounds.remove_at(0)
	queue_redraw()

func _draw() -> void:
	if size.x <= 8.0 or size.y <= 8.0:
		return
	draw_scale = min(size.x / 150.0, (size.y - 22.0) / 232.0)
	draw_origin = Vector2(size.x * 0.5 - 75.0 * draw_scale, 4.0)
	_draw_panel_backing()
	_draw_silhouette()
	_draw_wounds()
	_draw_status_icons()
	_draw_readout_line()

func _draw_panel_backing() -> void:
	var background: Color = Color(0.02, 0.035, 0.04, 0.62)
	var border: Color = Color(0.17, 0.42, 0.39, 0.72)
	draw_rect(Rect2(Vector2.ZERO, size), background, true)
	draw_rect(Rect2(Vector2.ZERO, size), border, false, 1.0)

func _draw_silhouette() -> void:
	var head_color: Color = _part_color(PlayerHealthBodyParts.PART_HEAD)
	var chest_color: Color = _part_color(PlayerHealthBodyParts.PART_CHEST)
	var stomach_color: Color = _part_color(PlayerHealthBodyParts.PART_STOMACH)
	var left_arm_color: Color = _part_color(PlayerHealthBodyParts.PART_LEFT_ARM)
	var right_arm_color: Color = _part_color(PlayerHealthBodyParts.PART_RIGHT_ARM)
	var left_leg_color: Color = _part_color(PlayerHealthBodyParts.PART_LEFT_LEG)
	var right_leg_color: Color = _part_color(PlayerHealthBodyParts.PART_RIGHT_LEG)
	var shadow: Color = Color(0.0, 0.0, 0.0, 0.42)
	draw_circle(_p(75.0, 29.0), 18.0 * draw_scale, shadow)
	draw_circle(_p(75.0, 28.0), 16.0 * draw_scale, head_color)
	draw_rect(Rect2(_p(67.0, 43.0), Vector2(16.0, 14.0) * draw_scale), chest_color, true)
	_draw_polygon([
		_p(51.0, 58.0),
		_p(99.0, 58.0),
		_p(107.0, 111.0),
		_p(90.0, 139.0),
		_p(60.0, 139.0),
		_p(43.0, 111.0)
	], chest_color)
	_draw_polygon([
		_p(58.0, 137.0),
		_p(92.0, 137.0),
		_p(96.0, 169.0),
		_p(82.0, 181.0),
		_p(68.0, 181.0),
		_p(54.0, 169.0)
	], stomach_color)
	_draw_limb(_p(51.0, 67.0), _p(31.0, 106.0), left_arm_color, 12.0)
	_draw_limb(_p(31.0, 106.0), _p(25.0, 151.0), left_arm_color, 10.0)
	_draw_limb(_p(99.0, 67.0), _p(119.0, 106.0), right_arm_color, 12.0)
	_draw_limb(_p(119.0, 106.0), _p(125.0, 151.0), right_arm_color, 10.0)
	_draw_limb(_p(66.0, 177.0), _p(57.0, 222.0), left_leg_color, 14.0)
	_draw_limb(_p(57.0, 222.0), _p(52.0, 245.0), left_leg_color, 12.0)
	_draw_limb(_p(84.0, 177.0), _p(93.0, 222.0), right_leg_color, 14.0)
	_draw_limb(_p(93.0, 222.0), _p(98.0, 245.0), right_leg_color, 12.0)

func _draw_wounds() -> void:
	for wound in wounds:
		var part_name: String = String(wound.get("part", ""))
		var damage_type: String = String(wound.get("type", "trauma")).to_lower()
		var amount: float = float(wound.get("amount", 1.0))
		var offset: Vector2 = Vector2.ZERO
		var raw_offset: Variant = wound.get("offset", Vector2.ZERO)
		if raw_offset is Vector2:
			offset = raw_offset
		var alpha: float = clamp(float(wound.get("time", 0.0)) / 18.0, 0.25, 1.0)
		var center: Vector2 = _wound_anchor(part_name) + offset * draw_scale
		var severity: float = clamp(amount / 32.0, 0.35, 1.4)
		if damage_type.find("burn") >= 0 or damage_type.find("fire") >= 0 or damage_type.find("steam") >= 0:
			_draw_burn_mark(center, severity, alpha)
		elif damage_type.find("laceration") >= 0 or damage_type.find("slash") >= 0:
			_draw_slash_mark(center, severity, alpha)
		elif damage_type.find("bleed") >= 0 or damage_type.find("stab") >= 0 or damage_type.find("puncture") >= 0:
			draw_circle(center, 3.8 * severity * draw_scale, Color(0.9, 0.03, 0.02, alpha))
		else:
			draw_circle(center, 4.4 * severity * draw_scale, Color(0.85, 0.18, 0.06, alpha))
			draw_arc(center, 7.0 * severity * draw_scale, 0.0, TAU, 18, Color(1.0, 0.55, 0.15, alpha), 1.4)

func _draw_status_icons() -> void:
	if not health:
		return
	var icon_x: float = 14.0
	var icon_y: float = size.y - 38.0
	if health.bleed_rate > 0.0:
		_draw_bleed_icon(Vector2(icon_x, icon_y))
		icon_x += 28.0
	if health.burn_time > 0.0:
		_draw_burn_icon(Vector2(icon_x, icon_y))
		icon_x += 28.0
	if health.stimulant_time > 0.0:
		_draw_bolt_icon(Vector2(icon_x, icon_y))

func _draw_readout_line() -> void:
	var font: Font = get_theme_default_font()
	var font_size: int = 12
	var grip: String = handling_state
	if grip.length() > 18:
		grip = grip.substr(0, 18)
	var text: String = "STAM %d  BLOOD %d  %s" % [int(stamina_value), int(health.blood_volume) if health else 100, grip]
	draw_string(font, Vector2(8.0, size.y - 8.0), text, HORIZONTAL_ALIGNMENT_LEFT, size.x - 16.0, font_size, Color(0.74, 1.0, 0.92))

func _draw_limb(start: Vector2, end: Vector2, color: Color, width: float) -> void:
	draw_line(start + Vector2(1.5, 1.5) * draw_scale, end + Vector2(1.5, 1.5) * draw_scale, Color(0.0, 0.0, 0.0, 0.35), width * draw_scale + 2.0, true)
	draw_line(start, end, color, width * draw_scale, true)

func _draw_polygon(points: Array[Vector2], color: Color) -> void:
	var packed_points: PackedVector2Array = PackedVector2Array()
	var packed_colors: PackedColorArray = PackedColorArray()
	for point in points:
		packed_points.append(point)
		packed_colors.append(color)
	draw_polygon(packed_points, packed_colors)

func _draw_slash_mark(center: Vector2, severity: float, alpha: float) -> void:
	var length: float = 12.0 * severity * draw_scale
	var width: float = max(1.8, 2.8 * severity) * draw_scale
	draw_line(center + Vector2(-length, -length * 0.25), center + Vector2(length, length * 0.25), Color(1.0, 0.07, 0.03, alpha), width, true)

func _draw_burn_mark(center: Vector2, severity: float, alpha: float) -> void:
	draw_circle(center, 7.5 * severity * draw_scale, Color(1.0, 0.34, 0.04, alpha * 0.72))
	draw_circle(center + Vector2(2.0, -2.0) * draw_scale, 3.2 * severity * draw_scale, Color(1.0, 0.9, 0.18, alpha * 0.66))

func _draw_bleed_icon(center: Vector2) -> void:
	var points: Array[Vector2] = [
		center + Vector2(0.0, -10.0),
		center + Vector2(7.0, 1.0),
		center + Vector2(4.0, 9.0),
		center + Vector2(-4.0, 9.0),
		center + Vector2(-7.0, 1.0)
	]
	_draw_polygon(points, Color(0.9, 0.02, 0.04, 0.95))

func _draw_burn_icon(center: Vector2) -> void:
	var flame: Array[Vector2] = [
		center + Vector2(0.0, -11.0),
		center + Vector2(8.0, -1.0),
		center + Vector2(4.0, 10.0),
		center + Vector2(-5.0, 10.0),
		center + Vector2(-8.0, -1.0)
	]
	_draw_polygon(flame, Color(1.0, 0.42, 0.05, 0.95))
	draw_circle(center + Vector2(0.0, 3.0), 4.0, Color(1.0, 0.88, 0.16, 0.9))

func _draw_bolt_icon(center: Vector2) -> void:
	var bolt: Array[Vector2] = [
		center + Vector2(2.0, -11.0),
		center + Vector2(-5.0, 2.0),
		center + Vector2(0.0, 2.0),
		center + Vector2(-2.0, 11.0),
		center + Vector2(7.0, -2.0),
		center + Vector2(1.0, -2.0)
	]
	_draw_polygon(bolt, Color(0.28, 0.9, 1.0, 0.95))

func _part_color(part_name: String) -> Color:
	if not health:
		return Color(0.16, 0.74, 0.68, 0.9)
	var ratio: float = health.get_part_ratio(part_name)
	var color: Color = Color(0.14, 0.82, 0.68, 0.96).lerp(Color(1.0, 0.72, 0.12, 0.96), clamp((1.0 - ratio) * 1.35, 0.0, 1.0))
	if ratio < 0.36:
		color = color.lerp(Color(0.95, 0.05, 0.04, 0.98), clamp((0.36 - ratio) / 0.36, 0.0, 1.0))
	if health.is_part_destroyed(part_name):
		color = Color(0.24, 0.0, 0.0, 0.98)
	return color

func _wound_anchor(part_name: String) -> Vector2:
	if part_name == PlayerHealthBodyParts.PART_HEAD:
		return _p(75.0, 28.0)
	if part_name == PlayerHealthBodyParts.PART_CHEST:
		return _p(75.0, 91.0)
	if part_name == PlayerHealthBodyParts.PART_STOMACH:
		return _p(75.0, 153.0)
	if part_name == PlayerHealthBodyParts.PART_LEFT_ARM:
		return _p(32.0, 119.0)
	if part_name == PlayerHealthBodyParts.PART_RIGHT_ARM:
		return _p(118.0, 119.0)
	if part_name == PlayerHealthBodyParts.PART_LEFT_LEG:
		return _p(58.0, 213.0)
	if part_name == PlayerHealthBodyParts.PART_RIGHT_LEG:
		return _p(92.0, 213.0)
	return _p(75.0, 120.0)

func _p(x: float, y: float) -> Vector2:
	return draw_origin + Vector2(x, y) * draw_scale
