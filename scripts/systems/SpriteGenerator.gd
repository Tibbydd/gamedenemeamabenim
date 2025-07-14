extends Node
class_name SpriteGenerator

# Procedural sprite generation system for CURSOR: Fragments of the Forgotten
# Creates pixel art sprites dynamically

static func create_wall_sprite(emotion: String, corruption_level: float) -> ImageTexture:
	var size = 32
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	
	# Base colors based on emotion
	var base_color = get_emotion_wall_color(emotion)
	var accent_color = base_color.lightened(0.3)
	var shadow_color = base_color.darkened(0.5)
	
	# Create wall pattern
	for x in range(size):
		for y in range(size):
			var color = base_color
			
			# Add corruption glitches
			if randf() < corruption_level * 0.1:
				color = Color.RED.lerp(base_color, 0.7)
			
			# Create wall brick pattern
			if (x % 16 == 0 or x % 16 == 15) or (y % 8 == 0 or y % 8 == 7):
				color = shadow_color
			elif (x + y) % 16 < 2:
				color = accent_color
			
			# Add digital noise
			if randf() < 0.05:
				color = color.lerp(Color.CYAN, 0.3)
			
			image.set_pixel(x, y, color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

static func create_floor_sprite(emotion: String, corruption_level: float) -> ImageTexture:
	var size = 32
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	
	var base_color = get_emotion_floor_color(emotion)
	var grid_color = base_color.darkened(0.2)
	
	for x in range(size):
		for y in range(size):
			var color = base_color
			
			# Grid pattern
			if x % 8 == 0 or y % 8 == 0:
				color = grid_color
			
			# Add corruption effects
			if randf() < corruption_level * 0.05:
				color = color.lerp(Color.RED, 0.5)
			
			# Digital lines
			if randf() < 0.02:
				color = Color.CYAN
			
			image.set_pixel(x, y, color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

static func create_player_sprite() -> ImageTexture:
	var size = 24
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	
	# Create cursor-like player sprite
	var cursor_color = Color(0.3, 0.9, 1.0, 1.0)
	var glow_color = Color(0.6, 1.0, 1.0, 0.6)
	var core_color = Color.WHITE
	
	var center = size / 2
	
	for x in range(size):
		for y in range(size):
			var dx = x - center
			var dy = y - center
			var distance = sqrt(dx * dx + dy * dy)
			
			var color = Color.TRANSPARENT
			
			# Main cursor body
			if distance < 8:
				color = cursor_color
			elif distance < 10:
				color = glow_color
			
			# Core dot
			if distance < 3:
				color = core_color
			
			# Digital effects
			if abs(dx) < 1 and abs(dy) < 12:
				color = cursor_color.lerp(Color.WHITE, 0.5)
			if abs(dy) < 1 and abs(dx) < 12:
				color = cursor_color.lerp(Color.WHITE, 0.5)
			
			image.set_pixel(x, y, color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

static func create_memory_fragment_sprite(emotion: String, is_core: bool = false) -> ImageTexture:
	var size = 20
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	
	var base_color = GameManager.get_emotion_color(emotion)
	var glow_color = base_color.lightened(0.4)
	var center = size / 2
	
	for x in range(size):
		for y in range(size):
			var dx = x - center
			var dy = y - center
			var distance = sqrt(dx * dx + dy * dy)
			
			var color = Color.TRANSPARENT
			
			# Fragment core
			if distance < 6:
				color = base_color
				if is_core:
					color = color.lerp(Color.WHITE, 0.3)
			elif distance < 8:
				color = glow_color
			
			# Add sparkle effects
			if randf() < 0.1 and distance < 7:
				color = Color.WHITE
			
			# Fragment "data" pattern
			if int(x + y) % 3 == 0 and distance < 5:
				color = color.lightened(0.3)
			
			image.set_pixel(x, y, color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

static func create_enemy_sprite(enemy_type: String, emotion: String) -> ImageTexture:
	var size = 28
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	
	var base_color = get_enemy_color(enemy_type, emotion)
	var dark_color = base_color.darkened(0.4)
	var light_color = base_color.lightened(0.3)
	var center = size / 2
	
	match enemy_type:
		"Corruptor":
			create_corruptor_pattern(image, size, base_color, dark_color, light_color)
		"Looper":
			create_looper_pattern(image, size, base_color, dark_color, light_color)
		"PhantomMemory":
			create_phantom_pattern(image, size, base_color, dark_color, light_color)
		_:
			create_basic_enemy_pattern(image, size, base_color, dark_color, light_color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

static func create_corruptor_pattern(image: Image, size: int, base: Color, dark: Color, light: Color):
	var center = size / 2
	
	for x in range(size):
		for y in range(size):
			var dx = x - center
			var dy = y - center
			var distance = sqrt(dx * dx + dy * dy)
			
			var color = Color.TRANSPARENT
			
			# Jagged, corrupted shape
			var angle = atan2(dy, dx)
			var noise = sin(angle * 6) * 2
			
			if distance < 8 + noise:
				color = base
			elif distance < 10 + noise:
				color = dark
			
			# Corruption lines
			if int(x + y * 0.5) % 4 == 0 and distance < 8:
				color = Color.RED.lerp(base, 0.7)
			
			# Glitch pixels
			if randf() < 0.05:
				color = Color.RED
			
			image.set_pixel(x, y, color)

static func create_looper_pattern(image: Image, size: int, base: Color, dark: Color, light: Color):
	var center = size / 2
	
	for x in range(size):
		for y in range(size):
			var dx = x - center
			var dy = y - center
			var distance = sqrt(dx * dx + dy * dy)
			
			var color = Color.TRANSPARENT
			
			# Circular, repetitive pattern
			if distance < 8:
				var rings = int(distance * 2) % 3
				if rings == 0:
					color = base
				elif rings == 1:
					color = light
				else:
					color = dark
			
			# Rotating pattern
			var angle = atan2(dy, dx)
			if int(angle * 4) % 2 == 0 and distance < 6:
				color = color.lerp(Color.YELLOW, 0.3)
			
			image.set_pixel(x, y, color)

static func create_phantom_pattern(image: Image, size: int, base: Color, dark: Color, light: Color):
	var center = size / 2
	
	for x in range(size):
		for y in range(size):
			var dx = x - center
			var dy = y - center
			var distance = sqrt(dx * dx + dy * dy)
			
			var color = Color.TRANSPARENT
			
			# Ghostly, fading pattern
			if distance < 10:
				var alpha = 1.0 - (distance / 10.0)
				color = base
				color.a = alpha * 0.7
				
				# Ethereal waves
				var wave = sin(distance * 0.5) * 0.5 + 0.5
				color = color.lerp(light, wave * 0.3)
			
			# Memory fragments floating around
			if randf() < 0.02 and distance < 8:
				color = Color.WHITE
				color.a = 0.8
			
			image.set_pixel(x, y, color)

static func create_basic_enemy_pattern(image: Image, size: int, base: Color, dark: Color, light: Color):
	var center = size / 2
	
	for x in range(size):
		for y in range(size):
			var dx = x - center
			var dy = y - center
			var distance = sqrt(dx * dx + dy * dy)
			
			if distance < 8:
				image.set_pixel(x, y, base)
			elif distance < 10:
				image.set_pixel(x, y, dark)

static func get_emotion_wall_color(emotion: String) -> Color:
	match emotion:
		"regret": return Color(0.3, 0.2, 0.5)
		"anger": return Color(0.6, 0.2, 0.2)
		"melancholy": return Color(0.2, 0.3, 0.6)
		"fear": return Color(0.1, 0.1, 0.2)
		"joy": return Color(0.7, 0.6, 0.3)
		"trauma": return Color(0.4, 0.1, 0.1)
		_: return Color(0.3, 0.3, 0.4)

static func get_emotion_floor_color(emotion: String) -> Color:
	match emotion:
		"regret": return Color(0.4, 0.3, 0.6)
		"anger": return Color(0.7, 0.3, 0.3)
		"melancholy": return Color(0.3, 0.4, 0.7)
		"fear": return Color(0.2, 0.2, 0.3)
		"joy": return Color(0.8, 0.7, 0.4)
		"trauma": return Color(0.5, 0.2, 0.2)
		_: return Color(0.5, 0.5, 0.6)

static func get_enemy_color(enemy_type: String, emotion: String) -> Color:
	var base = GameManager.get_emotion_color(emotion)
	
	match enemy_type:
		"Corruptor": return base.lerp(Color.RED, 0.5)
		"Looper": return base.lerp(Color.YELLOW, 0.3)
		"PhantomMemory": return base.lerp(Color.WHITE, 0.4)
		_: return base

static func create_ui_button_texture(color: Color, size: Vector2i) -> ImageTexture:
	var image = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	
	for x in range(size.x):
		for y in range(size.y):
			var pixel_color = color
			
			# Border
			if x < 2 or x >= size.x - 2 or y < 2 or y >= size.y - 2:
				pixel_color = color.lightened(0.3)
			
			# Inner glow
			if x > 4 and x < size.x - 4 and y > 4 and y < size.y - 4:
				pixel_color = color.darkened(0.2)
			
			image.set_pixel(x, y, pixel_color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

static func create_particle_texture(color: Color, size: int = 4) -> ImageTexture:
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = size / 2
	
	for x in range(size):
		for y in range(size):
			var dx = x - center
			var dy = y - center
			var distance = sqrt(dx * dx + dy * dy)
			
			if distance < center:
				var alpha = 1.0 - (distance / center)
				var pixel_color = color
				pixel_color.a = alpha
				image.set_pixel(x, y, pixel_color)
			else:
				image.set_pixel(x, y, Color.TRANSPARENT)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture