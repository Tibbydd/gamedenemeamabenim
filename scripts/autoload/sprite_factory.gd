extends Node

# Procedural pixel-art texture generator. Builds simple sprites at runtime
# and caches them so callers can request by key.

var _cache: Dictionary = {}

func get_texture(key: String) -> Texture2D:
	if _cache.has(key):
		return _cache[key]
	var img: Image
	match key:
		"player":
			img = _make_player()
		"corruptor":
			img = _make_corruptor()
		"fragment":
			img = _make_fragment()
		"exit":
			img = _make_exit()
		"wall":
			img = _make_wall()
		_:
			img = _make_placeholder()
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex

func _make_player() -> Image:
	var img := _blank(16, 16)
	_fill_circle(img, 8, 8, 6, Color(0.08, 0.55, 0.75))
	_fill_circle(img, 8, 8, 5, Color(0.25, 0.9, 1.0))
	_fill_circle(img, 8, 8, 3, Color(0.75, 1.0, 1.0))
	img.set_pixel(8, 8, Color(1, 1, 1))
	# A subtle cursor accent — pixel highlights toward upper-left.
	img.set_pixel(6, 6, Color(1, 1, 1))
	img.set_pixel(5, 7, Color(0.9, 1.0, 1.0))
	return img

func _make_corruptor() -> Image:
	var img := _blank(16, 16)
	_fill_circle(img, 8, 8, 6, Color(0.45, 0.05, 0.1))
	_fill_circle(img, 8, 8, 4, Color(0.85, 0.15, 0.25))
	# Jagged spikes
	for p in [Vector2i(8, 1), Vector2i(8, 14), Vector2i(1, 8), Vector2i(14, 8),
			Vector2i(2, 2), Vector2i(13, 2), Vector2i(2, 13), Vector2i(13, 13)]:
		_safe_set(img, p.x, p.y, Color(1.0, 0.35, 0.35))
	img.set_pixel(7, 7, Color(1, 1, 0.9))
	img.set_pixel(9, 9, Color(1, 1, 0.9))
	return img

func _make_fragment() -> Image:
	var img := _blank(12, 12)
	# Diamond shape
	for y in range(12):
		for x in range(12):
			var dx := absi(x - 6)
			var dy := absi(y - 6)
			var d := dx + dy
			if d <= 5:
				img.set_pixel(x, y, Color(0.9, 0.75, 0.2))
			if d <= 3:
				img.set_pixel(x, y, Color(1.0, 0.95, 0.5))
			if d <= 1:
				img.set_pixel(x, y, Color(1.0, 1.0, 0.85))
	return img

func _make_exit() -> Image:
	var img := _blank(24, 24)
	# Outlined rectangle
	for i in range(24):
		_safe_set(img, i, 0, Color(0.3, 1.0, 0.55))
		_safe_set(img, i, 23, Color(0.3, 1.0, 0.55))
		_safe_set(img, 0, i, Color(0.3, 1.0, 0.55))
		_safe_set(img, 23, i, Color(0.3, 1.0, 0.55))
	for i in range(2, 22):
		_safe_set(img, i, 1, Color(0.15, 0.6, 0.3))
		_safe_set(img, i, 22, Color(0.15, 0.6, 0.3))
		_safe_set(img, 1, i, Color(0.15, 0.6, 0.3))
		_safe_set(img, 22, i, Color(0.15, 0.6, 0.3))
	# Center glow
	_fill_circle(img, 12, 12, 4, Color(0.2, 0.8, 0.45, 0.6))
	return img

func _make_wall() -> Image:
	var img := _blank(16, 16)
	img.fill(Color(0.08, 0.10, 0.16))
	# Edge highlight on top + left for a faux-3D feel
	for i in range(16):
		img.set_pixel(i, 0, Color(0.20, 0.25, 0.35))
		img.set_pixel(0, i, Color(0.20, 0.25, 0.35))
		img.set_pixel(i, 15, Color(0.03, 0.04, 0.07))
		img.set_pixel(15, i, Color(0.03, 0.04, 0.07))
	# Circuit accents
	for p in [Vector2i(4, 4), Vector2i(11, 5), Vector2i(6, 10), Vector2i(12, 11)]:
		img.set_pixel(p.x, p.y, Color(0.3, 0.7, 0.9))
	return img

func _make_placeholder() -> Image:
	var img := _blank(8, 8)
	img.fill(Color.MAGENTA)
	return img

func _blank(w: int, h: int) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return img

func _fill_circle(img: Image, cx: int, cy: int, r: int, color: Color) -> void:
	var r_sq := r * r
	for y in range(cy - r, cy + r + 1):
		for x in range(cx - r, cx + r + 1):
			var dx := x - cx
			var dy := y - cy
			if dx * dx + dy * dy <= r_sq:
				_safe_set(img, x, y, color)

func _safe_set(img: Image, x: int, y: int, color: Color) -> void:
	if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
		return
	img.set_pixel(x, y, color)
